#!/bin/bash

#Set hostname
===================

sudo hostnamectl set-hostname k8W1

# Create a user and give him root level access
===========================================
useradd -m -s /bin/bash test

echo "test:abc123" | chpasswd

sed -i '/PasswordAuthentication yes/s/^#//g' /etc/ssh/sshd_config

echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

echo -e "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

echo "test    ALL=(ALL:ALL) ALL" > a.txt

sed -i '47r a.txt' /etc/sudoers

systemctl restart ssh

# Update and Upgrade OS
============================
apt update -y && apt upgrade -y

# Install Containerd Steps
=============================

swapoff -a

apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y

apt update

apt install -y containerd.io

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1

sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

systemctl restart containerd

# Install Kubernetes Steps for Worker 1
==================================================

apt-get update

apt-get install -y apt-transport-https ca-certificates curl gpg 

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

apt-get install -y kubelet kubeadm kubectl

apt-mark hold kubelet kubeadm kubectl

systemctl enable --now kubelet

tee /etc/modules-load.d/containerd.conf <<EOF
br_netfilter
EOF

modprobe br_netfilter

tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system