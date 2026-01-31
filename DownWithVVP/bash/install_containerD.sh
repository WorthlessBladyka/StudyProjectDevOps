#!/bin/bash

apt-get remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)

# Add Docker's official GPG key:
apt-get update
apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install
apt-get update
yes | apt-get install containerd.io

# Проверка запущен ли Docker
if systemctl is-active --quiet containerd.service; then
    echo "✓ Docker работает"
    echo "Статус: $(systemctl is-active containerd.service)"
    exit 0
else
    echo "✗ Docker не работает"
    sudo systemctl daemon-reload
    sudo systemctl start containerd.service
    if systemctl is-active --quiet containerd.service; then
        echo "✓ Docker работает"
        echo "Статус: $(systemctl is-active containerd.service)"
        exit 0
    else
        echo "✗ Docker не работает"
        echo "Статус: $(systemctl is-active containerd.service)"
        exit 1
    fi
fi
