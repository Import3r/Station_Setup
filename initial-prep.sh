#!/bin/bash

# check if running as root
if [ "$EUID" -ne 0 ]
	then echo "please run as root"
	exit
fi

mkdir -p /tmp/DROPZONE/install_results

{

# perform updates before starting
add-apt-repository universe
add-apt-repository multiverse
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y;

# add PPA repositories
sudo add-apt-repository ppa:phoerious/keepassxc  # keepassxc repo
add-apt-repository "deb https://repo.vivaldi.com/archive/deb/ stable main" && apt update -y

# perform desired installs of used software 
apt-get install vim curl git mlocate python3-pip virtualbox qemu qemu-kvm libvirt-daemon bridge-utils virt-manager virtinst keepassxc net-tools gnupg2 xorg xsensors -y;

# install vivaldi
wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | apt-key add -
apt install vivaldi-stable -y

# virtualization preparation
systemctl start libvirtd
systemctl enable libvirtd

: '
# install katoolin3
git clone https://github.com/s-h-3-l-l/katoolin3 /tmp/katoolin3 &&
	cd /tmp/katoolin3 &&
	bash /tmp/katoolin3/install.sh &&
	katoolin3 &&
	apt-get purge faraday* -y
	
'

# undervolting CPU and GPU
pip3 install undervolt

echo '[Unit]
Description=undervolt
After=suspend.target
After=hibernate.target
After=hybrid-sleep.target

[Service]
Type=oneshot
# If you have installed undervolt globally (via sudo pip install):
ExecStart=/usr/local/bin/undervolt -v --core -100 --cache -100 --gpu -70
# If you want to run from source:
# ExecStart=/path/to/undervolt.py -v --core -100 --cache -100 --gpu -70

[Install]
WantedBy=multi-user.target
WantedBy=suspend.target
WantedBy=hibernate.target
WantedBy=hybrid-sleep.target' > /etc/systemd/system/undervolt.service

systemctl start undervolt
systemctl enable undervolt

# install asus-fan-control and prequisites (gitpack)
mkdir -p /tmp/gitpack/ && cd /tmp/gitpack/ && # prepare a temporary directory
git clone https://github.com/dominiksalvet/gitpack.git ./ && # clone repository
git checkout "$(git describe --tags --abbrev=0)" && # use latest version
src/gitpack install github.com/dominiksalvet/gitpack # install GitPack

gitpack install github.com/dominiksalvet/asus-fan-control
systemctl enable asus-fan-control
asus-fan-control set-temps 51 55 65 68 71 74 77 80

# clean up and system settings
localectl set-locale en_US.UTF-8
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y;
apt autoremove -y
updatedb

echo; } 2>> /tmp/DROPZONE/install_results/errors

echo -e "\n\n\n***** ERRORS ENCOUNTERED *****\n\n\n"
cat /tmp/DROPZONE/install_results/errors

echo -e "\n\n\n***** UNDERVOLTING STATUS *****\n\n\n"
undervolt --read

