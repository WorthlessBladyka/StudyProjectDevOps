#!/bin/bash
set -x
function remove_docker {
    if systemctl is-active -queit docker.service; then
        echo "Remove docker"
        sudo apt remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd
        sudo rm /etc/apt/sources.list.d/docker.sources
        sudo rm /etc/apt/keyrings/docker.asc
        install_containerd
        check_containerd_installed
    fi
}

function check_containerd {
    if systemctl is-active --quiet containerd.service; then
        echo "✓ Containderd работает"
        exit 0
    else
        sudo rm -r /etc/apt/sources.list.d/docker.sources
        sudo rm -r /etc/apt/keyrings/docker.asc
        sudo apt remove -y containerd.io
    fi
}

function check_containerd_installed {
    if systemctl is-active --quiet containerd.service; then
        echo "✓ Containderd работает"
        exit 0
    else
        echo "Containderd не работает"
        exit 1
    fi
}

function install_containerd {
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    # Install
    sudo apt-get update
    sudo apt-get install -y containerd.io
    sudo containerd config default | sudo tee /etc/containerd/config.toml
    sudo systemctl enable containerd.service
    sudo systemctl start containerd.service
}

remove_docker
check_containerd
install_containerd
check_containerd_installed