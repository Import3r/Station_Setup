#!/bin/bash

# check if running as root
if [ "$EUID" -ne 0 ]; then
	echo "please run as root"
	exit
elif [ ! -f "packages.txt" ]; then
	echo -e "'packages.txt' is missing, please create it before running again.\n\nYou can add the packages you wish to install through 'apt' to the 'packages.txt' file, as shown:\n"
	echo -e "package1_name\npackage2_name\n.\n.\n.\n"	
fi

base_dir=$(pwd)'/'

mkdir -p /tmp/DROPZONE/install_results &&

{
echo "# Updating repos..."
# perform updates before starting
add-apt-repository universe
add-apt-repository multiverse
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y;

# add PPA repositories
wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | apt-key add -
add-apt-repository "deb https://repo.vivaldi.com/archive/deb/ stable main"
apt update -y

# perform installation of desired software 
echo "# Installing atom..."
xargs -r -a packages.txt apt-get install -y
wget "https://atom.io/download/deb" -O /tmp/DROPZONE/atom.deb && apt install /tmp/DROPZONE/atom.deb && sudo -u $USER atom  # Atom Text Editor
echo "# Installing Discord..."
wget "https://discord.com/api/download?platform=linux&format=deb" -O /tmp/DROPZONE/discord.deb && apt install /tmp/DROPZONE/discord.deb -y  # Discord
echo "# Installing Burpsuite..."
wget "https://portswigger.net/burp/releases/download?product=community&version=2020.12.1&type=Linux" -O /tmp/DROPZONE/burpsuite.sh && chmod 744 /tmp/DROPZONE/burpsuite.sh && /tmp/DROPZONE/burpsuite.sh  # BurpSuite
echo "# Installing Bitwarden..."
wget "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb" -O /tmp/DROPZONE/bitwarden.deb && apt install /tmp/DROPZONE/bitwarden.deb  # Bitwarden
echo "# Installing Docker..."
apt-get remove -y docker* && apt install docker.io -y && systemctl start docker && systemctl enable docker  # Docker

echo "# Installing Vivaldi browser..."
# install vivaldi browser
apt install vivaldi-stable -y
tar xvzf ${base_dir}My-Vivaldi-settings.tar.gz -C ~

# virtualization preparation
systemctl start libvirtd && systemctl enable libvirtd

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
systemctl start undervolt && systemctl enable undervolt

# install asus-fan-control and prequisites (gitpack)
wget -qO- https://raw.githubusercontent.com/dominiksalvet/gitpack/master/.install/initg.sh | sh  # install GitPack
gitpack install github.com/dominiksalvet/asus-fan-control
systemctl enable asus-fan-control
asus-fan-control set-temps 51 55 65 68 71 74 77 80

# install themes
tar xvzf  ${base_dir}theme_files/icons/candy-icons.tar.xz -C /usr/share/icons
tar xvzf  ${base_dir}theme_files/icons/oreo_spark_dark_cursors.tar.gz -C /usr/share/icons
tar xvzf  ${base_dir}theme_files/themes/Sweet-Dark.tar.xz -C /usr/share/themes

# clean up and adjust system settings
localectl set-locale en_US.UTF-8
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y;
apt autoremove -y
updatedb
cat ${base_dir}add_to_bashrc.txt >> ~/.bashrc
ln switch-mode.sh ~/switch
mkdir -p ~/random
mkdir -p ~/git_repos/public_tools
cp ${base_dir}atom-config-files/* ~/.atom/

# Fix undetected headphone jack microphone (NOTE: Found Solution here: https://superuser.com/questions/1312970/headset-microphone-not-detected-by-pulse-und-alsa)
if { which "modprobe" > /dev/null; } && { cat /proc/asound/card*/codec* | grep Codec | grep "ALC23" > /dev/null; }; then
	echo "options snd-hda-intel model=dell-headset-multi" >> /etc/modprobe.d/alsa-base.conf
	mic_fix_state="modprobe installed and correct card identified. Fix was attempted. The following is the tail of 'alsa-base.conf' file:\n\n";
	mic_fix_state+=$(tail /etc/modprobe.d/alsa-base.conf;)
else 
	mic_fix_state="ERROR: either modprobe was not found or the device has incompatible sound card. Fix was not applied.";
fi

echo; } 2>> /tmp/DROPZONE/install_results/errors

echo -e "\n\n\n***** ERRORS ENCOUNTERED *****\n\n\n"
cat /tmp/DROPZONE/install_results/errors

echo -e "\n\n\n***** UNDERVOLTING STATUS *****\n\n\n"
undervolt --read

echo -e "\n\n\n***** HEADPHONE JACK MICROPHONE FIX *****\n\n\n"
echo -e "${mic_fix_state}\n\n"
