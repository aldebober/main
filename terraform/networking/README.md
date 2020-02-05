# Networking
Creates VPC, NAT and OpenVPN resources

# Prerequisites
1. Create Systems Manager Parameter `openvpn_password` with OpenVPN Admin PW

# OpenVPN Management
## Adding new clients
1. `ssh YOUR_USERNAME@OPENVPN_EIP`
2. Generate cert
```
# without pw
/etc/openvpn-ca/clients/new_client.sh USERNAME

# with pw
/etc/openvpn-ca/clients/new_client.sh USERNAME 1
```
3. Get `ovpn` profile from `/etc/openvpn-ca/clients/USERNAME.ovpn`

## Revoking clients
1. `ssh YOUR_USERNAME@OPENVPN_EIP`
2. `/etc/openvpn-ca/clients/revoke_client.sh USERNAME`
