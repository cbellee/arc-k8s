#!/bin/bash

while getopts d:i: flag
do
    case "${flag}" in
        d) PUBLIC_DNS=${OPTARG};;
        i) PUBLIC_IP=${OPTARG};;
    esac
done

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

# cat $HOME/.kube/config
cat /etc/kubernetes/admin.conf

## Copy the contents from the cat above to be used next (using mouse right click)