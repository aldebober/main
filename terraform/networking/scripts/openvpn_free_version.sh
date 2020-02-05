#!/bin/bash
export AWS_DEFAULT_REGION="eu-west-1"
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
zone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Installing prerequisites
apt-get update -yq
apt-get install -yq python unzip htop vim software-properties-common curl openvpn easy-rsa
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
aws configure set s3.signature_version s3v4

# AWS Agent
curl https://amazon-ssm-eu-west-1.s3.amazonaws.com/latest/debian_amd64/amazon-ssm-agent.deb -o amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
start amazon-ssm-agent

make-cadir /etc/openvpn-ca && cd /etc/openvpn-ca

# Prepare vars file
sed -i 's/export KEY_COUNTRY=.*/export KEY_COUNTRY="EE"/g' /etc/openvpn-ca/vars
sed -i 's/export KEY_PROVINCE=.*/export KEY_PROVINCE="HARJUMAA"/g' /etc/openvpn-ca/vars
sed -i 's/export KEY_CITY=.*/export KEY_CITY="Tallinn"/g' /etc/openvpn-ca/vars
sed -i 's/export KEY_ORG=.*/export KEY_ORG="Arcanebet"/g' /etc/openvpn-ca/vars
sed -i 's/export KEY_EMAIL=.*/export KEY_EMAIL="admin@arcanebet.com"/g' /etc/openvpn-ca/vars
sed -i 's/export KEY_OU=.*/export KEY_OU="IT"/g' /etc/openvpn-ca/vars
sed -i 's/export KEY_NAME=.*/export KEY_NAME="server"/g' /etc/openvpn-ca/vars

# Install Certs
source vars
./clean-all
sed -i 's/--interact//g' build-ca && ./build-ca
./build-dh
sed -i 's/--interact//g' build-key-server && ./build-key-server server
cd keys && openvpn --genkey --secret statictlssecret.key
cp ca.crt server.crt server.key statictlssecret.key dh2048.pem /etc/openvpn && cd ..
sed -i 's/--interact//g' build-key
sed -i 's/--interact//g' build-key-pass

# Install server
cat <<EOF > /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
server 172.16.0.0 255.255.252.0
ifconfig-pool-persist ipp.txt
keepalive 10 120
tls-auth /etc/openvpn-ca/keys/statictlssecret.key 0
cipher AES-256-CBC
auth SHA512
comp-lzo
persist-key
persist-tun
status openvpn-status.log
verb 3
user nobody
group nogroup
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222"
push "dhcp-option DNS 208.67.220.220"
crl-verify crl.pem
EOF
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
interface=$(ip route list | grep default | grep -E  'dev (\w+)' -o | awk '{print $2}')
iptables -t nat -A POSTROUTING -s 172.16.0.0/22 -o $interface -j MASQUERADE

# Install client base config
mkdir -p /etc/openvpn-ca/clients
cat <<EOF > /etc/openvpn-ca/clients/base.conf
client
dev tun
proto udp
remote ${eip} 1194
resolv-retry infinite
nobind
cipher AES-256-CBC
auth SHA512
key-direction 1
user nobody
group nogroup
persist-key
persist-tun
remote-cert-tls server
comp-lzo
verb 3
EOF

cat <<EOF > /etc/openvpn-ca/clients/new_client.sh
#!/bin/bash
# First argument: Client identifier
# Second argument: pw or cert-only
KEY_DIR=/etc/openvpn-ca/keys
OUTPUT_DIR=/etc/openvpn-ca/clients
BASE_CONFIG=/etc/openvpn-ca/clients/base.conf
if [ "\$#" -eq 2 ]; then
    cd /etc/openvpn-ca/ && source vars && ./build-key-pass \$1
else
    cd /etc/openvpn-ca/ && source vars && ./build-key \$1
fi
cat \$${BASE_CONFIG} \
    <(echo -e '<ca>') \
    \$${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    \$${KEY_DIR}/\$${1}.crt \
    <(echo -e '</cert>\n<key>') \
    \$${KEY_DIR}/\$${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    \$${KEY_DIR}/statictlssecret.key \
    <(echo -e '</tls-auth>') \
    > \$${OUTPUT_DIR}/\$${1}.ovpn
echo "------- start --------"
cat \$${OUTPUT_DIR}/\$${1}.ovpn
echo "------- end --------"
EOF
chmod +x /etc/openvpn-ca/clients/new_client.sh

cat <<EOF > /etc/openvpn-ca/clients/revoke_client.sh
#!/bin/bash
# First argument: Client identifier
cd /etc/openvpn-ca
source vars;./revoke-full \$1
cp keys/crl.pem /etc/openvpn
systemctl restart openvpn@server
EOF
chmod +x /etc/openvpn-ca/clients/revoke_client.sh

# We need to generate and revoke 1 dummy cert in order for CRL to work
/etc/openvpn-ca/clients/new_client.sh dummy
/etc/openvpn-ca/clients/revoke_client.sh dummy

# Start openvpn
systemctl start openvpn@server
systemctl enable openvpn@server

# Add groups and allow them to sudo w/o password
groupadd developers
groupadd admins
echo "%admins ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)

# Adding a tag to instance as last step
aws ec2 create-tags --resources $${instance_id} --tags Key=UserData,Value=finished
