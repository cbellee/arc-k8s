#!/bin/bash

while getopts d:i: flag
do
    case "${flag}" in
        d) PUBLIC_DNS=${OPTARG};;
        i) PUBLIC_IP=${OPTARG};;
    esac
done

echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo "Configuring Docker..."

sudo cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Installing Kubernetes components..."

sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add 
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

## Initiate the kubernetes cluster. Update the placeholders for fqdns and public IP
## Make a note of the Kube Join command from the output if we wish to add nodes later
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans $PUBLIC_DNS,$PUBLIC_IP

## Copy the kubeconfig file to .kube folder for kubectl access on the VM
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

## Install the network plugin
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

## remove the master taint as we are currently using a single node cluster
kubectl taint nodes --all node-role.kubernetes.io/master-

cat $HOME/.kube/config

## Copy the contents from the cat above to be used next (using mouse right click)