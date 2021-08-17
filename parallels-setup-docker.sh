#!/bin/bash

echo "Please enter your macOS username (you can get this by typing whoami in the macOS terminal):"
read username

echo "Please enter your projects folder name in macOS (case matters):"
read projects_dir

localpath=/media/psf/$projects_dir

if [ ! -d "$localpath" ]
then
  echo "You must add $projects_dir to your custom folders in Parallels sharing settings before you can continue"
  exit 1
fi

mkdir -p /Users/$username
ln -s $localpath /Users/$username/$projects_dir

hostname docker
echo 'docker' > /etc/hostname

apt update -y
apt upgrade -y
apt install -y docker htop iotop jq

sed -i 's/^ExecStart.*$/ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ -H tcp:\/\/0.0.0.0 --containerd=\/run\/containerd\/containerd.sock/' /lib/systemd/system/docker.service

while true; do
    read -p "Do you wish to disable the desktop to make more memory available to Docker?" yn
    case $yn in
        [Yy]* )
          systemctl disable wpa_supplicant ModemManager
          systemctl set-default multi-user.target
          break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "All set!"
echo "In order to use this virtual machine for docker from macOS, you will need to add to your shell profile:"
echo "  export DOCKER_HOST=tcp://docker.local:2375"
echo "You should reboot the virtual machine now!"
