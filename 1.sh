#!/bin/bash
sudo apt-get install git
git clone https://github.com/Cemito/adjoin.git

runscipt(){
    cd adjoin
    chmod +x u_corpjoin.sh datadrive.sh
    ./datadrive.sh
    ./u_corpjoin
}
runscript
