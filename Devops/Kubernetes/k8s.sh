#!/bin/bash

#Set hostname
===================

sudo hostnamectl set-hostname k8M

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

cd /home/test

# Update and Upgrade OS
============================
apt update -y && apt upgrade -y

#Password less SSH
=====================

echo "test" > tempUserName.txt

echo "3.89.33.118" > ipaddr

echo "54.208.5.154" >> ipaddr

ipAddFile="./ipaddr"
echo -e "\n" | ssh-keygen -N "" &> /dev/null
echo "$ipAddFile"

for IP in `cat $ipAddFile`; do
          if [[ $IP == *"["* ]]; then
          	echo "$IP"|cut -d "[" -f2 | cut -d "]" -f1>tempUserName.txt
          else
                  user=$(cat tempUserName.txt)
                  ssh-copy-id $user@$IP
                  echo "Key copied to $IP"
fi
done
rm -rf tempUserName.txt

# Extract the ip address of Worker 1 from ipaddr
===========================================
sed -n -e 1p /home/test/ipaddr > /home/test/ipaddr1

# Extract the ip address of Worker 2 from ipaddr
===========================================
sed -n -e 2p /home/test/ipaddr > /home/test/ipaddr2

# Now execute the container ID and kubectl steps on Worker 1
===========================================================

for server in $(cat /home/test/ipaddr1)
do
  
	scp /home/test/k8w1.sh  test@${server}:/home/test/
        ssh test@${server} -t `sudo bash k8w1.sh`

done

# Now execute the container ID and kubectl steps on Worker 2
===========================================================

for server in $(cat /home/test/ipaddr2)
do
  
	scp /home/test/k8w2.sh  test@${server}:/home/test/
        ssh test@${server} -t `sudo bash k8w2.sh`

done

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

# Install Kubernetes Steps before K8s initilzation
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

# Initialize Kubernetes and copy the output to text file
========================================================

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 > /home/test/output.txt

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

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
  
	    scp /home/test/final.sh  test@${server}:/home/test/
        ssh test@${server} -t `sudo bash final.sh`

done