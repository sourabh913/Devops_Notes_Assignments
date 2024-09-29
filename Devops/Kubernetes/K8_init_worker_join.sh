#!/bin/bash

# Initialize Kubernetes and copy the output to text file
========================================================

kubeadm init --pod-network-cidr=10.244.0.0/16 > /home/test/output.txt

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

systemctl restart containerd

# Extract the token line required to join worker node
===========================================
sed -n -e 74p -e 75p /home/test/output.txt > /home/test/out.txt

# Add the bin bash to the line so that it acts as a shell script
===============================================================
sed '1 i\ #!/bin/bash' /home/test/out.txt > /home/test/final.sh

# Now execute the final shell script on the worker nodes
===========================================================

for server in $(cat /home/test/ipaddr)
do
  
	ssh test@${server} 'bash -s' < /home/test/final.sh

done