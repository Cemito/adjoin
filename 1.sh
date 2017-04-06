#!/bin/bash
sudo apt-get install git
git clone https://github.com/Cemito/adjoin.git
sleep 20
cd adjoin/
chmod +x u_corpjoin datadrive.sh
./u_corpjoin
