#!/bin/bash
export AWS_DEFAULT_REGION="eu-west-1"
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
zone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

if [ $zone = '${region}a' ]
then
  route_table=${route_table_a}
  elastic_id=${eip_a}
else
  route_table=${route_table_b}
  elastic_id=${eip_b}
fi

# Installing prerequisites
apt-get update -yq
apt-get install -yq unzip htop vim software-properties-common curl
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
aws configure set s3.signature_version s3v4

# AWS Agent
curl https://amazon-ssm-eu-west-1.s3.amazonaws.com/latest/debian_amd64/amazon-ssm-agent.deb -o amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
start amazon-ssm-agent

# Time Sync and Automatic Security Updates
## Chrony
apt-get remove ntp*
apt-get install -yq chrony
sed -i '1iserver 169.254.169.123 prefer iburst' /etc/chrony/chrony.conf
/etc/init.d/chrony restart

## Automatic Security Updates
cat > /etc/apt/apt.conf.d/10periodic << EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOL

# AWS Changes
## App route-tables
aws ec2 create-route --route-table-id $${route_table} --destination-cidr-block 0.0.0.0/0 --instance-id $${instance_id}
aws ec2 replace-route --route-table-id $${route_table} --destination-cidr-block 0.0.0.0/0 --instance-id $${instance_id}
aws ec2 associate-address --instance-id $${instance_id} --allocation-id $${elastic_id} --allow-reassociation
aws ec2 modify-instance-attribute --instance-id $${instance_id} --no-source-dest-check

# Become a NAT
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward

# Add groups and allow them to sudo w/o password
groupadd developers
groupadd admins
echo "%admins ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)

# Adding a tag to instance as last step
aws ec2 create-tags --resources $${instance_id} --tags Key=UserData,Value=finished
