#!/bin/bash

sudo apt-get install gparted -y

printf "\n\nDo you want to format and partiton DATA drive? *WARNING THIS WILL DELETE ALL DATA*\n"
PS3='Select an option: '
options=("Yes" "Mount the drive" "Change Ownership" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "you chose choice 1"

		hdd="/dev/sdb"
		for i in $hdd;do
		echo "n
		p
		
		
		
		w
		"|fdisk $i;mkfs.ext4 $i;done 
		sudo mkdir /media/DATA
		sudo mount /dev/sdb /media/DATA

		sudo e2label /dev/sdb DATA
            ;;
"Mount the drive")
sudo su -c "echo '/dev/sdb /media/DATA ext4 rw,data=ordered 0 0' >> /etc/fstab"
;;

"Change Ownership")
printf "Type name of the user you want to change drive permissions to:  "
read ADUSER
sudo chown $ADUSER /media/DATA
;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done
