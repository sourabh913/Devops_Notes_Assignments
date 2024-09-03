#!/bin/bash

#JENKINS INSTALLATION

# Update and Upgrade Packages of Ubuntu OS
sudo apt update -y && sudo apt upgrade -y

#Install Java SDK 17
sudo apt install openjdk-17-jdk -y

# Check Java version
java -version

# Add Jenkins repository key
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Add Jenkins repository to sources list
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package lists
sudo apt-get update

# Install Jenkins
sudo apt-get install jenkins -y

#Start Jenkins
sudo systemctl start jenkins

# Enable Jenkins to run on Boot
sudo systemctl enable jenkins

#JENKINS ADMIN USER CREATION

# Install python3-pip
sudo apt install python3-pip -y

# Install Dev Packages of Python
sudo apt install -y build-essential libssl-dev libffi-dev python3-dev

url=<Jenkins url>
password=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# NEW ADMIN CREDENTIALS URL ENCODED USING PYTHON
username=$(python3 -c "import urllib.parse;print (urllib.parse.quote(input(), safe=''))" <<< "user")
new_password=$(python3 -c "import urllib.parse;print (urllib.parse.quote(input(), safe=''))" <<< "password")
fullname=$(python3 -c "import urllib.parse;print (urllib.parse.quote(input(), safe=''))" <<< "full name")
email=$(python3 -c "import urllib.parse;print (urllib.parse.quote(input(), safe=''))" <<< "hello@world.com")

# GET THE CRUMB AND COOKIE
cookie_jar="$(mktemp)"
full_crumb=$(curl -u "admin:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${full_crumb//:/ })
only_crumb=$(echo ${arr_crumb[1]})

# MAKE THE REQUEST TO CREATE AN ADMIN USER
curl -X POST -u "admin:$password" $url/setupWizard/createAdminUser \
        -H "Connection: keep-alive" \
        -H "Accept: application/json, text/javascript" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "$full_crumb" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --cookie $cookie_jar \
        --data-raw "username=$username&password1=$new_password&password2=$new_password&fullname=$fullname&email=$email&Jenkins-Crumb=$only_crumb&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D&core%3Aapply=&Submit=Save&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D"


#INSTALLATION OF RECOMMENDED PLUGINS IN JENKINS
url=<Jenkins url>

user=user
password=password

cookie_jar="$(mktemp)"
full_crumb=$(curl -u "$user:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${full_crumb//:/ })
only_crumb=$(echo ${arr_crumb[1]})

# MAKE THE REQUEST TO DOWNLOAD AND INSTALL REQUIRED MODULES
 curl -X POST -u "$user:$password" $url/pluginManager/installPlugins \
   -H 'Connection: keep-alive' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
       -H 'X-Requested-With: XMLHttpRequest' \
         -H "$full_crumb" \
           -H 'Content-Type: application/json' \
             -H 'Accept-Language: en,en-US;q=0.9,it;q=0.8' \
               --cookie $cookie_jar \
                --data-raw "{'dynamicLoad':true,'plugins':['cloudbees-folder','antisamy-markup-formatter','build-timeout','credentials-binding','timestamper','ws-cleanup','ant','gradle','workflow-aggregator','github-branch-source','pipeline-github-lib','pipeline-stage-view','git','ssh-slaves','matrix-auth','pam-auth','ldap','email-ext','mailer'],'Jenkins-Crumb':'$only_crumb'}"

#CONFIRMING JENKINS URL
url=<your_jenkins_url>

user=user
password=password
url_urlEncoded=$(python3 -c "import urllib.parse;print (urllib.parse.quote(input(), safe=''))" <<< "$url")

cookie_jar="$(mktemp)"
full_crumb=$(curl -u "$user:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${full_crumb//:/ })
only_crumb=$(echo ${arr_crumb[1]})

curl -X POST -u "$user:$password" $url/setupWizard/configureInstance \
  -H 'Connection: keep-alive' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H "$full_crumb" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept-Language: en,en-US;q=0.9,it;q=0.8' \
  --cookie $cookie_jar \
  --data-raw "rootUrl=$url_urlEncoded%2F&Jenkins-Crumb=$only_crumb&json=%7B%22rootUrl%22%3A%20%22$url_urlEncoded%2F%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D&core%3Aapply=&Submit=Save&json=%7B%22rootUrl%22%3A%20%22$url_urlEncoded%2F%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D"
