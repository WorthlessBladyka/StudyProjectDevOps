#!/bin/bash
set -x
set -eo

sudo systemctl stop kubelet
sudo fuser -k 10248/tcp 10255/tcp 10250/tcp
sudo systemctl daemon-reload

sudo kubeadm join 192.168.1.39:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<полученный_хеш>

