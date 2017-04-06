#!/bin/bash
sudo apt-get install git
git clone https://github.com/Cemito/adjoin.git
sleep 3
alias changedir="cd adjoin"
changedir
chmod +x u_corpjoin datadrive.sh
./u_corpjoin
