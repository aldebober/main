#!/bin/bash
function add_group_keys() {
  users=( `aws iam get-group --group-name $2 --query 'Users[*].UserName' --output text | tr '\t' ' '` )
  for i in $${users[@]}
  do
    if ! getent passwd $i > /dev/null 2>&1; then
      echo "Adding new user $i"
      useradd $i -m -s /bin/bash -G $1
    fi
    add_user_key $i
  done
}

function add_user_key() {
  key_id=$(aws iam list-ssh-public-keys --user-name $1 --query "SSHPublicKeys[?Status=='Active'].[SSHPublicKeyId][0]" --output text)
  if [ ! -z $${key_id} ] && [ $key_id != "None" ]
  then
    key=$(aws iam get-ssh-public-key --user-name $1 --ssh-public-key-id $key_id --encoding SSH --query 'SSHPublicKey.SSHPublicKeyBody' --output text)

    if [ ! -d "/home/$1/.ssh" ]
    then
      mkdir /home/$1/.ssh
    fi

    echo "Changing key for $1"
    echo $key > /home/$1/.ssh/authorized_keys
  fi
}

add_group_keys admins Admins
service ssh restart || true
service sshd restart || true

echo "Finished"