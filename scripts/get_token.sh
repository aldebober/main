#!/bin/sh

Env=$1
NONCE=$2
VAULT_TOKEN=$(/usr/bin/curl -s -X POST https://access.tech.com/v1/auth/aws-ec2/login -d '{"role": "'${Env}'-role", "nonce": "'${NONCE}'", "pkcs7":"'"$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d \\n)"'"}' )
echo $VAULT_TOKEN | /usr/bin/jq .auth.client_token | tr -d \"
#echo $VAULT_TOKEN
