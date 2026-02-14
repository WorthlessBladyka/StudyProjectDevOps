#!/bin/bash

#vars
ARCH=" "
VERSION="v1.35.0"

function preparing_for_installation {
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

    if ! [[ -d /etc/apt/keyrings ]]; then
        sudo mkdir -p -m 755 /etc/apt/keyrings
    fi

    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg 

    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list  
}

function download_and_installation {
    sudo apt-get update
    if ! sudo apt-get install kubectl &>/dev/null; then
        echo -e "Ошибка скачивания пакета!!!\nНачинаю скачивание через curl.."
        if [[ "$(uname -m)" == "aarch64" ]] || [[ "$(uname -m)" == "arm64" ]]; then
            ARCH="arm64" 
        else
            ARCH="amd64" 
        fi
        curl -LO "https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCH}/kubectl"
        curl -LO "https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCH}/kubectl.sha256"
        checksum
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    fi
}

function checksum {
    if "$(cat kubectl.sha256)  kubectl" | sha256sum --check; then
        return 0
    else
        echo "Несоответствие с контрольной суммой!"
        return 1
    fi
}

function check_download_start {
    if kubectl &>/dev/null; then
        echo "kubectl is installed!!!"
        exit 0
    else
        echo "kubectl is not installed!"
        preparing_for_installation
        download_and_installation
        check_download
        exit 1
    fi
}

function check_download {
    if kubectl &>/dev/null; then
        echo "kubectl is installed!!!"
        exit 0
    else
        echo "kubectl is not installed!"
        return 1
    fi
}

check_download_start