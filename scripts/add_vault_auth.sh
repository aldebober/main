#!/bin/sh

VAULT_ADDR=""
VAULT_TOKEN=$(cat ./root_token)
# List of current auth roles
echo "list of current roles:"
curl -s -X LIST -H "x-vault-token:$VAULT_TOKEN" $VAULT_ADDR/v1/auth/token/roles | jq .data.keys

if [ $# -eq 0 ]
      then
      echo "Usage: ./add_vault_auth.sh env_name" && exit
fi

ENV=$1
#curl -X POST -H "x-vault-token:$VAULT_TOKEN" $VAULT_ADDR/v1/sys/auth/aws-ec2 -d '{"type":"aws-ec2"}'

echo "Adding new auth role and policies for $ENV"
# Roles for Nomad cluster. allowed_policies is needed
curl -s -X POST -H "x-vault-token:$VAULT_TOKEN" $VAULT_ADDR/v1/auth/token/roles/$ENV-nomad-cluster -d '{ "allowed_policies": "'$ENV'", "name": "'$ENV'-nomad-cluster", "period": 800000 }'

# Policy for Nomad to get new token
curl -s -X POST -H "X-Vault-Token:$VAULT_TOKEN" --data '{"rules":"path \"auth/aws-ec2/login\" {\n  policy = \"write\"\n}\npath \"auth/token/create/'$ENV'-nomad-cluster\" {\n  capabilities = [\"update\"]\n}\n\npath \"auth/token/roles/'$ENV'-nomad-cluster\" {\n  capabilities = [\"read\"]\n}\n\npath \"auth/token/lookup-self\" {\n  capabilities = [\"read\"]\n}\n\npath \"auth/token/lookup\" {\n  capabilities = [\"update\"]\n}\n\npath \"auth/token/revoke-accessor\" {\n  capabilities = [\"update\"]\n}\n\npath \"sys/capabilities-self\" {\n  capabilities = [\"update\"]\n}\n\npath \"auth/token/renew-self\" {\n  capabilities = [\"update\"]\n}\n"}' $VAULT_ADDR/v1/sys/policy/$ENV-nomad-server
# Policy which will be used by nomad templating
curl -s -X POST -H "X-Vault-Token:$VAULT_TOKEN" --data '{"rules":"path \"secret\/'$ENV'/*\" { capabilities = [\"read\"] }"}'  $VAULT_ADDR/v1/sys/policy/$ENV

# Creating new auth role with tag name $ENV-vault. It must consist of $ENV and $ENV-nomad-server policies.
curl -s -X POST -H "x-vault-token:$VAULT_TOKEN" $VAULT_ADDR/v1/auth/aws-ec2/role/$ENV-role -d '{"bound_account_id":"528733774338","policies":"'$ENV'-nomad-server,'$ENV'","role_tag":"'$ENV'-vault","disallow_reauthentication": false}'

# Getting tags for new env. It should be described in terraform variable
curl -s -X POST -H "x-vault-token:$VAULT_TOKEN" $VAULT_ADDR/v1/auth/aws-ec2/role/$ENV-role/tag -d '{"policies":"'$ENV'-nomad-server,'$ENV'"}' | jq ."data"

# Edit payloads and put in local directory
curl -s -X POST -H "x-vault-token:$VAULT_TOKEN" $VAULT_ADDR/v1/secret/$ENV/simplinic-pub -d @simplinic-pub.payload
curl -s -X POST -H "x-vault-token:$VAULT_TOKEN" $VAULT_ADDR/v1/secret/$ENV/simplinic-sub -d @simplinic-sub.payload

# DEBUGGING
## check policies of token:
#curl -s  -H "x-vault-token:$VAULT_TOKEN" $VAULT_ADDR/v1/auth/token/lookup -d '{"token": "NOMAD_TOKEN"}' | jq .
## You must be able to get your role with this token (export VAULT_TOKEN=NOMAD_TOKEN) on instance with Nomad:
#curl -s  -H "x-vault-token:$VAULT_TOKEN" $VAULT_ADDR/v1/auth/token/roles/nomad-cluster | jq .
