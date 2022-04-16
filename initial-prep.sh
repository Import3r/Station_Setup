#! /bin/bash

install_bitwarden () {
	echo -e "\n# Installing Bitwarden...\n"
	wget "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb" -O /tmp/DROPZONE/bitwarden.deb && sudo apt install /tmp/DROPZONE/bitwarden.deb -y
}

install_discord () {
	echo -e "\n# Installing Discord...\n"
	wget "https://discord.com/api/download?platform=linux&format=deb" -O /tmp/DROPZONE/discord.deb && sudo apt install /tmp/DROPZONE/discord.deb -y  # Discord
}

install_burpsuite () {
	echo -e "\n# Installing Burpsuite...\n"
	wget "https://portswigger.net/burp/releases/download?product=community&version=2020.12.1&type=Linux" -O /tmp/DROPZONE/burpsuite.sh && chmod 755 /tmp/DROPZONE/burpsuite.sh && sudo /tmp/DROPZONE/burpsuite.sh  # BurpSuite
}

install_zoom () {
	echo -e "\n# Installing Zoom...\n"
	wget "https://zoom.us/client/latest/zoom_amd64.deb" -O /tmp/DROPZONE/zoom.deb && sudo apt install /tmp/DROPZONE/zoom.deb -y  # Zoom
}

install_docker () {
	echo -e "\n# Installing Docker...\n"
	sudo apt-get remove -y docker* && sudo apt install docker.io -y && sudo systemctl start docker && sudo systemctl enable docker  # Docker
}

install_vivaldi_ppa () {
	echo -e "\n# Installing Vivaldi browser...\n"
	wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor > packages.vivaldi.gpg
	sudo install -o root -g root -m 644 packages.vivaldi.gpg /etc/apt/trusted.gpg.d
	sudo sh -c 'echo "deb [arch=amd64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.vivaldi.gpg] https://repo.vivaldi.com/archive/deb stable main" > /etc/apt/sources.list.d/vivaldi.list' 
	rm -f packages.vivaldi.gpg
	sudo apt update && sudo apt install vivaldi-stable -y
}

install_vscode_ppa () {
	echo -e "\n# Installing VSCode browser...\n"
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
	sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
	sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
	rm -f packages.microsoft.gpg
	sudo apt update && sudo apt install code -y
}

sudo echo  # prompt for sudo-password

# check if running as root
if [ "$EUID" -eq 0 ]; then
	echo "You are running as root (not recommended), the setup will be configured for the user 'root' only, are you sure you want to continue?"
	echo "[y/n?]"
	read -r choice
	if [[ "${choice,,}" == "y" ]]; then
		echo "proceeding"
	elif [[ "${choice,,}" == "n" ]]; then
		echo "Run again with desired user."
		exit
	else
		echo "Not what I asked for. I dont have time for this shit :)"
		exit
	fi
fi

if [ ! -f "packages.txt" ]; then
	echo -e "'packages.txt' is missing, please create it before running again.\n\nYou can add the packages you wish to install through 'apt' to the 'packages.txt' file, as shown:\n"
	echo -e "package1_name\npackage2_name\n.\n.\n.\n"	
fi

base_dir=$(pwd)'/'

mkdir -p /tmp/DROPZONE/install_results &&

{
echo -e "\n# Updating repos...\n"
# perform updates before starting
sudo add-apt-repository universe
sudo add-apt-repository multiverse
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y;

# install desired apt packages 
sudo xargs -r -a packages.txt apt-get install -y

# install desired .deb packages
install_bitwarden
install_discord
install_burpsuite
install_zoom
install_docker

# add and install ppa repositories
install_vivaldi_ppa
install_vscode_ppa

# undervolting CPU and GPU
sudo pip3 install undervolt
sudo cp "${base_dir}"undervolt.service /etc/systemd/system/undervolt.service
sudo systemctl daemon-reload && sudo systemctl enable undervolt.service && sudo systemctl start undervolt.service

# disabling Intel turbo boost
sudo cp "${base_dir}"turbo-boost.sh /root && sudo chown root /root/turbo-boost.sh && sudo chmod u+x /root/turbo-boost.sh

# install asus-fan-control and prequisites (gitpack)
wget -qO- https://raw.githubusercontent.com/dominiksalvet/gitpack/master/.install/initg.sh | sudo sh  # install GitPack
sudo gitpack install github.com/dominiksalvet/asus-fan-control
sudo systemctl enable afc.service
sudo asus-fan-control set-temps 51 55 65 68 71 74 77 80

# install themes
sudo tar xvf  "${base_dir}"theme_files/icons/candy-icons.tar.xz -C /usr/share/icons
sudo tar xvzf  "${base_dir}"theme_files/icons/oreo_spark_purple_cursors.tar.gz -C /usr/share/icons
sudo tar xvf  "${base_dir}"theme_files/themes/Sweet-Dark.tar.xz -C /usr/share/themes

# clean up and adjust system settings
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt autoremove -y
sudo updatedb
cat "${base_dir}"add_to_bashrc.txt >> ~/.bashrc  # modify .bashrc as pleased
cp "${base_dir}"switch-mode.sh ~/Desktop/switch.sh && chmod 755 ~/Desktop/switch.sh  # switch-mode script installation

# Fix undetected headphone jack microphone (NOTE: Found Solution here: https://superuser.com/questions/1312970/headset-microphone-not-detected-by-pulse-und-alsa)
if { which "modprobe" > /dev/null; } && { sudo cat /proc/asound/card*/codec* | grep Codec | grep "ALC23" > /dev/null; }; then
	sudo bash -c 'echo "options snd-hda-intel model=dell-headset-multi" >> /etc/modprobe.d/alsa-base.conf'
	mic_fix_state="modprobe installed and correct card identified. Fix was attempted. The following is the tail of 'alsa-base.conf' file:\n\n";
	mic_fix_state+=$(tail /etc/modprobe.d/alsa-base.conf)
else 
	mic_fix_state="ERROR: either modprobe was not found or the device has incompatible sound card. Fix was not applied.";
fi

echo; } 2>> /tmp/DROPZONE/install_results/errors

echo -e "\n\n\n***** ERRORS ENCOUNTERED *****\n\n\n"
cat /tmp/DROPZONE/install_results/errors

echo -e "\n\n\n***** UNDERVOLTING STATUS *****\n\n\n"
sudo undervolt --read

echo -e "\n\n\n***** HEADPHONE JACK MICROPHONE FIX *****\n\n\n"
echo -e "${mic_fix_state}\n\n"
