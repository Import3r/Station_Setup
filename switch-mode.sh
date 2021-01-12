#! /bin/bash

if [ $1 != 'game' ] && [ $1 != 'normal' ]; then
	echo "Command: $0 game|normal"
	exit

elif [ $1 = 'game' ]; then
	sudo prime-select nvidia
	echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo -e "\ngame mode on.\n\nNvidia card activated.\nIntel processor in performance mode."

elif [ $1 = 'normal' ]; then
	sudo prime-select on-demand
	echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo -e "\ngame mode off.\n\nGPU is set to auto.\nIntel processor in power saving mode."
fi
