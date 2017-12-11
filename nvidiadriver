if [[ $(lspci -k | grep 'VGA') = *NVIDIA* ]]; then 
	sudo add-apt-repository ppa:graphics-drivers
	sudo apt-get update
	sudo apt-get install nvidia-387
	sudo apt-mark hold nvidia-387
	sudo reboot
else
	echo "This computer does not have a nVidia Graphics card installed so the nVidia Driver will not be installed."
fi
