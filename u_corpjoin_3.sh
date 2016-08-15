#!/bin/bash

# Update System & Software packages
apt-get -y update
apt-get -y upgrade
apt-get -y autoclean

# Install puppet
echo "Download and install puppetslabs for Trusty"
curl -O https://apt.puppetlabs.com/puppetlabs-release-trusty.deb && sudo dpkg -i puppetlabs-release-trusty.deb

echo "Clean"
apt-get clean

echo "Apt-get install Puppet"
apt-get -y install puppet

echo "Curl puppet.conf"
curl -O /etc/puppet/puppet.conf http://puppetshare.tsi.lan/puppet/Linux/ubuntu.conf

echo "Enabling Puppet Agent"
puppet agent --enable

echo "Starting Puppet Agent"
service puppet restart


# Enable sudo access for users in AD group development, which will allow sudo access
# after AD stuff is set up. This should probably go in kickstart when we have that going.
sudo bash -c 'echo "%development ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/development'
sudo bash -c 'echo "%GG-TSI-AD-IT-M ALL=(ALL) ALL" >> /etc/sudoers.d/development'

## Adding Computer to the Domain w/ PDIS ##

# Install PBIS repo file

# Download and run package for PBIS
curl -O http://download.beyondtrust.com/PBISO/8.3/pbis-open-8.3.0.3287.linux.x86_64.deb.sh

# Change to executable
chmod a+x pbis-open-8.3.0.3287.linux.x86_64.deb.sh #make executable file

# Install openssh server
apt-get -y install openssh-server

# move and rename file to home directory
mv pbis-open-8.3.0.3287.linux.x86_64.deb.sh ~/pbis-open.deb.sh 

cd ~ #go to home directory

bash pbis-open.deb.sh #run script

apt-get -y install libglade2-0

cd /opt/likewise/bin

/opt/pbis/bin/domainjoin-gui

echo "Configuring Default login shell as /bin/bash"
/opt/pbis/bin/config LoginShellTemplate /bin/bash >/dev/null 2>&1

echo "Updating DNS and setting as daily cron job"
echo $'#!/bin/bash\nsudo /opt/pbis/bin/update-dns' > /etc/cron.daily/dns
chmod 755 /etc/cron.daily/dns
/opt/pbis/bin/update-dns

# Append text to end of config files
echo 'allow-guest=false 
greeter-show-manual-login=true' >> /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf

# Download and move krb5 config file
sudo curl -O https://gitlab.com/dthomas_tableau/Linux/raw/master/Ubuntu/krb5.conf | mv krb5.conf /etc/krb5.conf

## Add Users as Admins when they login to GUI ##

printf "Enter new users account name to be added to Sudoeres to make them an Admin: "
read ADUSER
adduser $ADUSER sudo

# Pause script press <enter> to continue
read -p $'The AD user account will now be a full Admin when they login.\nPress enter to continue.....\n'

## Install additional Application ##
# Install VIM
sudo apt-get -y install vim
echo "Installed VIM"

# Install GUI for VIM
sudo apt-get -y install vim-x11
echo "Installed VIM with GUI"

# Install Screen
sudo apt-get -y install screen
echo "Installed Screen"

# Install TMUX
sudo apt-get -y install tmux
echo "Installed TMUX"

# Install XRDP
sudo apt-get -y install xrdp
echo "Installed XRDP"

# Turn off WiFi
nmcli r wifi off

# Install Dconf Tools
sudo apt-get -y install dconf-tools
dconf write /org/gnome/desktop/remote-access/require-encryption false   /usr/lib/vino/vino-server --sm-disable start
vino-preferences

# Pause script press <enter> to continue
read -p $'\n\n\n\nTick "Allow other users to view your desktop" and set a password.\nUntick "You must confirm each access to this machine".\n\nOnce you have made the changes come back to this screen and press enter to continue......\n'
echo "Installed Dconf Editor and enabled Screen Sharing"

## REBOOT WHEN COMPLETE
clear
echo ""
echo "==================================================================="
echo " DOMAIN JOIN COMPLETE. "
echo " TIME FOR A REBOOT! You must now reboot your system: 'sudo reboot' "
echo "==================================================================="
echo ""
# Don't actually reboot system in case things went wrong and user wants to debug
#reboot
