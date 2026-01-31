#!/bin/bash

echo "Hello OS - Darwin"
echo "Settings..."
if [ ! -d ~/.kube/config ]; then
    mkdir -p ~/.kube/config
fi
cat <<EOF | sudo tee ~/.kube/config/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl -w net.inet.ip.forwarding=1
if [ "$(sysctl -n net.inet.ip.forwarding)" -eq 1 ]; then
    echo "Successfully settings!"
    exit 0
else
    exit 1
fi