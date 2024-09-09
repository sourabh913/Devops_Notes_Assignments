#!/bin/bash

# Create a user and give him root level access
===========================================
useradd -p abc123 -m test

sed -i '/PasswordAuthentication yes/s/^#//g' /etc/ssh/sshd_config

echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

echo -e "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/60-cloudimg-settings.conf


echo "test    ALL=(ALL:ALL) ALL" > a.txt

sed -i '47r a.txt' /etc/sudoers

systemctl restart ssh

cd /home/test/

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


# Initialize Docker Swarm and copy the output to text file
=========================
docker swarm init > /home/test/output.txt


# Extract the token line required to join worker node
===========================================
sed -n -e 5p /home/test/output.txt > /home/test/out.txt


# Add the bin bash to the line so that it acts as a shell script
===============================================================
sed '1 i\ #!/bin/bash' /home/test/out.txt > /home/test/final.sh



# Now execute the final shell script on the worker nodes
===========================================================

for server in $(cat /home/test/ipaddr)
do
  
	ssh test@${server} 'bash -s' < /home/test/final.sh

done

sudo usermod -a -G docker test   (The issue here is that the user you’re running the command as is not a member of the docker group. In order to add it to the docker group, run)

docker node ls