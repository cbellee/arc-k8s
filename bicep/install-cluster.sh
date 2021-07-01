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
mkdir -p /home/localadmin/.kube
sudo cp /etc/kubernetes/admin.conf /home/localadmin/.kube/config
sudo chown $(id -u localadmin):$(id -g localadmin) /home/localadmin/.kube/config

## Install the network plugin
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

## remove the master taint as we are currently using a single node cluster
kubectl taint nodes --all node-role.kubernetes.io/master-
