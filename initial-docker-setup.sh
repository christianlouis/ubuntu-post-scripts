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