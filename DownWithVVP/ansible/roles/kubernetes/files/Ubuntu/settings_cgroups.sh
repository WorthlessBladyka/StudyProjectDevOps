#!/bin/bash

# Проверяем тип файловой системы cgroup
function check_cgroup {
  if [[ "$(stat -fc %T /sys/fs/cgroup)" == "cgroup2fs" ]]; then
    conf_containerd
    exit 0
  else
    echo 'cgroup != cgroup2fs'
    exit 1
  fi
}

# Создаем конфигурационный файл containerd
function conf_containerd {
  sudo tee /etc/containerd/config.toml > /dev/null <<'EOF'
  version = 3
  root = '/var/lib/containerd'
  state = '/run/containerd'
  temp = ''
  disabled_plugins = []
  required_plugins = []
  oom_score = 0
  imports = ['/etc/containerd/conf.d/*.toml']

  [grpc]
    address = '/run/containerd/containerd.sock'
    tcp_address = ''
    tcp_tls_ca = ''
    tcp_tls_cert = ''
    tcp_tls_key = ''
    uid = 0
    gid = 0
    max_recv_message_size = 16777216
    max_send_message_size = 16777216
    tcp_tls_common_name = ''

  [ttrpc]
    address = ''
    uid = 0
    gid = 0

  [debug]
    address = ''
    uid = 0
    gid = 0
    level = ''
    format = ''

  [metrics]
    address = ''
    grpc_histogram = false

  [plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
  [cgroup]
    path = ''

  [timeouts]
    'io.containerd.timeout.bolt.open' = '0s'
    'io.containerd.timeout.cri.defercleanup' = '1m0s'
    'io.containerd.timeout.metrics.shimstats' = '2s'
    'io.containerd.timeout.shim.cleanup' = '5s'
    'io.containerd.timeout.shim.load' = '5s'
    'io.containerd.timeout.shim.shutdown' = '3s'
    'io.containerd.timeout.task.state' = '2s'

  [stream_processors]
    [stream_processors.'io.containerd.ocicrypt.decoder.v1.tar']
      accepts = ['application/vnd.oci.image.layer.v1.tar+encrypted']
      returns = 'application/vnd.oci.image.layer.v1.tar'
      path = 'ctd-decoder'
      args = ['--decryption-keys-path', '/etc/containerd/ocicrypt/keys']
      env = ['OCICRYPT_KEYPROVIDER_CONFIG=/etc/containerd/ocicrypt/ocicrypt_keyprovider.conf']

    [stream_processors.'io.containerd.ocicrypt.decoder.v1.tar.gzip']
      accepts = ['application/vnd.oci.image.layer.v1.tar+gzip+encrypted']
      returns = 'application/vnd.oci.image.layer.v1.tar+gzip'
      path = 'ctd-decoder'
      args = ['--decryption-keys-path', '/etc/containerd/ocicrypt/keys']
      env = ['OCICRYPT_KEYPROVIDER_CONFIG=/etc/containerd/ocicrypt/ocicrypt_keyprovider.conf']
EOF
  sudo systemctl restart containerd
}

check_cgroup


#   sudo tee /etc/containerd/config.toml > /dev/null <<'EOF'
# version = 2

# root = "/var/lib/containerd"
# state = "/run/containerd"
# oom_score = 0
# imports = ["/etc/containerd/runtime_*.toml", "./debug.toml"]

# [grpc]
#   address = "/run/containerd/containerd.sock"
#   uid = 0
#   gid = 0

# [debug]
#   address = "/run/containerd/debug.sock"
#   uid = 0
#   gid = 0
#   level = "info"

# [metrics]
#   address = ""
#   grpc_histogram = false

# [cgroup]
#   path = ""

# [plugins]
#   [plugins."io.containerd.grpc.v1.cri"]
#     [plugins."io.containerd.grpc.v1.cri".containerd]
#       [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
#         [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
#           runtime_type = "io.containerd.runc.v2"
#           [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#             SystemdCgroup = true
# EOF





