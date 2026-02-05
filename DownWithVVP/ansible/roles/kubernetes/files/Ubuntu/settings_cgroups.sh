#!/bin/bash

# Проверяем тип файловой системы cgroup
stat -fc %T /sys/fs/cgroup

# Создаем конфигурационный файл containerd
sudo tee /etc/containerd/config.toml > /dev/null <<'EOF'
version = 2

root = "/var/lib/containerd"
state = "/run/containerd"
oom_score = 0
imports = ["/etc/containerd/runtime_*.toml", "./debug.toml"]

[grpc]
  address = "/run/containerd/containerd.sock"
  uid = 0
  gid = 0

[debug]
  address = "/run/containerd/debug.sock"
  uid = 0
  gid = 0
  level = "info"

[metrics]
  address = ""
  grpc_histogram = false

[cgroup]
  path = ""

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
EOF

sudo systemctl restart containerd