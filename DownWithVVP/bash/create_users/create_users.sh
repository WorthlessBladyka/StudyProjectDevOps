#!/bin/bash

#command_line
name_user=$1
name_group=$2

set -x

function create_user {
    local user=$name_user
    for i in $user; do
        echo $i
        uuid=$(date +%s | sha256sum | base64 | head -c 12)
        echo $uuid
        # sudo useradd -m -p $uuid $i
    done
}

function add_user_to_group {
    local user=$name_user
    local group=$name_group
    for k in $group; do
        if ! grep -q "^$k" /etc/group ; then
            groupadd $k
            echo "create group $k"
        fi
    done
    
    for j in $user; do
        for k in $group; do
            usermod -aG $k $j
            echo "user - $j успешно добавлен в группу: $k"
        done
    done
}

function user_ssh_key {
    local user=$name_user
    
    for s in $user; do
        ssh-keygen -t rsa \
        -n $s \
        -f /home/$s/.ssh/new_key

        chmod 600 /home/$s/.ssh/new_key
        chmod 644 /home/$s/.ssh/new_key.pub
    done 

}

create_user $name_user 
add_user_to_group $name_user $name_group
user_ssh_key $name_user