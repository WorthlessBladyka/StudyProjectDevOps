SHOW_IP="10.244.0.0/24"
CRI_SOCKET="/var/run/containerd/containerd.sock"
API_SERVER="192.168.1.39"

sudo kubeadm init --pod-network-cidr=$SHOW_IP --cri-socket=$CRI_SOCKET --apiserver-advertise-address=$API_SERVER

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#Add network addon
kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.29/net.yaml


kubeadm token create --print-join-command