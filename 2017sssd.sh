# Enable sudo access for users in AD group development, which will allow sudo access
sudo bash -c 'echo "%development ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/development'
sudo bash -c 'echo "%GG-TSI-AD-IT-M ALL=(ALL) ALL" >> /etc/sudoers.d/development'

# Append text to end of config files
echo 'allow-guest=false 
greeter-show-manual-login=true' >> /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.

## Add Users as Admins when they login to GUI
printf "Enter new users account name to be added to Sudoeres to make them an Admin: "
read ADUSER
adduser $ADUSER sudo

# Pause script press <enter> to continue
read -p $'The AD user account will now be a full Admin when they login.\nPress enter to continue.....\n'
