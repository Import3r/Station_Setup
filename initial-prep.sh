#! /bin/bash

sudo echo
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

# add PPA repositories
wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | sudo apt-key add -
sudo add-apt-repository "deb https://repo.vivaldi.com/archive/deb/ stable main"
sudo apt update -y

# perform installation of desired software 
echo -e "\n# Installing Bitwarden...\n"
wget "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb" -O /tmp/DROPZONE/bitwarden.deb && sudo apt install /tmp/DROPZONE/bitwarden.deb -y  # Bitwarden
sudo xargs -r -a packages.txt apt-get install -y
echo -e "\n# Installing Discord...\n"
wget "https://discord.com/api/download?platform=linux&format=deb" -O /tmp/DROPZONE/discord.deb && sudo apt install /tmp/DROPZONE/discord.deb -y  # Discord
echo -e "\n# Installing Burpsuite...\n"
wget "https://portswigger.net/burp/releases/download?product=community&version=2020.12.1&type=Linux" -O /tmp/DROPZONE/burpsuite.sh && chmod 755 /tmp/DROPZONE/burpsuite.sh && sudo /tmp/DROPZONE/burpsuite.sh  # BurpSuite
echo -e "\n# Installing Zoom...\n"
wget "https://zoom.us/client/latest/zoom_amd64.deb" -O /tmp/DROPZONE/zoom.deb && sudo apt install /tmp/DROPZONE/zoom.deb -y  # Zoom
echo -e "\n# Installing Docker...\n"
sudo apt-get remove -y docker* && sudo apt install docker.io -y && sudo systemctl start docker && sudo systemctl enable docker  # Docker

echo -e "\n# Installing Vivaldi browser...\n"
# install vivaldi browser
sudo apt install vivaldi-stable -y
'''tar xvzf "${base_dir}"My-Vivaldi-settings.tar.gz -C ~'''

# undervolting CPU and GPU
sudo pip3 install undervolt
sudo bash -c "echo '[Unit]
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
WantedBy=hybrid-sleep.target' > /etc/systemd/system/undervolt.service"
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
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y;
sudo apt autoremove -y
sudo updatedb
cat "${base_dir}"add_to_bashrc.txt >> ~/.bashrc  # modify .bashrc as pleased
cp "${base_dir}"switch-mode.sh ~/switch.sh && chmod 755 ~/switch.sh  # switch-mode script installation
mkdir -p ~/EXTRACTION

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
