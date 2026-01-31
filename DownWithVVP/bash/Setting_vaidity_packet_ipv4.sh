#!/bin/bash

if [ ! -d /etc/sysctl.d ]; then
    sudo mkdir -p /etc/sysctl.d
fi
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

if [ "$(sysctl -n net.ipv4.ip_forward)" -eq 1 ]; then
    echo "Successfully settings!"
    exit 0
else
    exit 1
fiгтфуь