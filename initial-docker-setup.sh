#!/bin/sh

sudo apt update && sudo apt-get upgrade -y
sudo apt remove docker docker-engine -y
sudo apt install linux-image-extra-virtual -y
sudo apt install lsof curl vim strace less mtr htop build-essentials git
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce -y
sudo systemctl status docker
sudo systemctl enable docker.service
sudo mkdir -p /usr/local/bin
sudo curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod 755 /usr/local/bin/docker-compose
