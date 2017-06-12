#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Test if hostname is > 15 characters, and if so, exit
RED='\033[0;31m'
NC='\033[0m'
HOST=$(hostname -s)
if [ ${#HOST} -gt 15 ]; then
   echo -e "${RED}WARNING${NC}: This instance was created with a name longer than 15 characters"
   echo -e "${RED}WARNING${NC}: Please delete this instance and create one with a name of 15 characters or less"
   exit 1
fi

# Set DOMAIN var
if [ $# -eq 0 ]; then
    echo "No arguments provided, defaulting to TSI"
    DOMAIN='TSI'
else
	# Check to ensure DOMAIN matches expected values
	if ! [[ "$1" =~ ^(TSI|DEV.TSI)$ ]]; then
  		echo "Unsupported argument. Use 'TSI or 'DEV.TSI'."
  		exit 1
	fi
	DOMAIN=$1
fi

# Setup system variables and install software
swver=$(lsb_release -d | awk '{print $2}')

if [ $swver = "CentOS" ]; then

/usr/bin/yum -y install curl realmd sssd oddjob oddjob-mkhomedir adcli samba-common ntpdate ntp krb5-workstation sssd-tools redhat-lsb-core

/usr/sbin/authconfig --enablesssd --enablesssdauth --enablemkhomedir --update
fi

if [ $swver = "Ubuntu" ]; then
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq curl krb5-user samba sssd ntp sssd-tools oddjob oddjob-mkhomedir
sudo bash -c 'cat >> /etc/pam.d/common-session <<EOF
session    required    pam_mkhomedir.so skel=/etc/skel/ umask=0022
EOF'
fi

# London is 10.242.0.0/18. Therefore first 3 octets should be between 10.242.0 - 10.242.63 inclusive. If not, host is not in London
# get default NIC
NIC=$(ip route ls | grep default | awk '{print $5}')

# get default NIC IP
IP=$(ip addr show dev $NIC | grep -Po 'inet \K[\d.]+')

# get 2nd octet
BASE2=$(echo $IP | cut -d"." -f2)

# get 3rd octet
BASE3=$(echo $IP | cut -d"." -f3)

if [ "$BASE2" -eq 242 ] && [ "$BASE3" -ge 0 -a "$BASE3" -le 63 ]; then
   ADSITE="TSI-EMEADataCenter"
else
   ADSITE="TSI-NADataCenter"
fi

# Create config files
if [ $DOMAIN = "TSI" ]; then

cat > /etc/samba/smb.conf <<EOF
[global]

workgroup = TSI
client signing = yes
client use spnego = yes
kerberos method = secrets and keytab
realm = TSI.LAN
security = ads
EOF

cat > /etc/sssd/sssd.conf <<EOF
[sssd]
domains = tsi.lan
config_file_version = 2
services = nss, pam

[domain/tsi.lan]
ad_domain = tsi.lan
krb5_realm = TSI.LAN
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/tsi/%u
auth_provider = ad
access_provider = ad
ad_site = TSI-NADataCenter
ad_gpo_access_control = permissive
ad_gpo_map_remote_interactive = +sshd
dyndns_update = True
dyndns_iface = $NIC
dyndns_refresh_interval = 86400
dyndns_update_ptr = True
EOF

cat > /etc/krb5.conf <<EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_realm = true
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_realm = TSI.LAN
EOF

# Download domain join keytab
curl -o /etc/domainjoin.keytab http://puppetshare.dev.tsi.lan/scripts/krb5.keytab.svc_domainjoin_devit
JOIN_ACCOUNT="svc_domainjoin_devit"
JOIN_OU="TSI_DevIT/Build"

fi

if [ $DOMAIN = "DEV.TSI" ]; then

cat > /etc/samba/smb.conf <<EOF
[global]

workgroup = DEV
client signing = yes
client use spnego = yes
kerberos method = secrets and keytab
realm = DEV.TSI.LAN
security = ads
EOF

cat > /etc/sssd/sssd.conf <<EOF
[sssd]
domains = dev.tsi.lan
config_file_version = 2
services = nss, pam

[domain/dev.tsi.lan]
ad_domain = dev.tsi.lan
krb5_realm = DEV.TSI.LAN
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/dev/%u
auth_provider = ad
access_provider = ad
ad_site = Default-First-Site-Name
ad_gpo_access_control = permissive
ad_gpo_map_remote_interactive = +sshd
dyndns_update = True
dyndns_iface = $NIC
dyndns_refresh_interval = 86400
dyndns_update_ptr = True
EOF

cat > /etc/krb5.conf <<EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_realm = true
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_realm = DEV.TSI.LAN
EOF

# Download domain join keytab
curl -o /etc/domainjoin.keytab http://puppetshare.dev.tsi.lan/scripts/krb5.keytab.svc_domainjoin
JOIN_ACCOUNT="svc_domainjoin"
JOIN_OU="Dev_Computers/Build"

fi

chown root:root /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf

sed -i 's/.*KerberosAuthentication.*/KerberosAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/.*KerberosOrLocalPasswd.*/KerberosOrLocalPasswd yes/' /etc/ssh/sshd_config
sed -i 's/.*KerberosTicketCleanup.*/KerberosTicketCleanup yes/' /etc/ssh/sshd_config

sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config

sed -i 's/.*GSSAPIAuthentication.*/GSSAPIAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/.*GSSAPICleanupCredentials.*/GSSAPICleanupCredentials yes/' /etc/ssh/sshd_config
sed -i 's/.*GSSAPIStrictAcceptorCheck.*/GSSAPIStrictAcceptorCheck no/' /etc/ssh/sshd_config
sed -i 's/.*GSSAPIEnablek5users.*/GSSAPIEnablek5users yes/' /etc/ssh/sshd_config
sed -i 's/.*UseDNS.*/UseDNS no/' /etc/ssh/sshd_config

if [[ ${HOSTNAME} != *"tsi.lan"* ]]; then
   DOMAIN_LOWER=$(echo $DOMAIN | tr '[:upper:]' '[:lower:]')
   hostnamectl set-hostname $HOSTNAME.$DOMAIN_LOWER.lan
   HOSTNAME=$(hostname)
fi

SHORTNAME=$(echo $HOSTNAME | cut -d'.' -f1)
# OSVER=$(lsb_release -r | awk '{print $2}')
# OSNAME=$(lsb_release -i | awk '{print $3}')

if [ $swver = "CentOS" ]; then
sed -i "s/^127.0.0.1.*/127.0.0.1   $HOSTNAME $SHORTNAME localhost localhost.localdomain localhost4 localhost4.localdomain4/" /etc/hosts
sed -i "s/^::1.*/::1   $HOSTNAME $SHORTNAME localhost localhost.localdomain localhost6 localhost6.localdomain6/" /etc/hosts
fi

if [ $swver = "Ubuntu" ]; then
sed -i "s/^127.0.0.1.*/127.0.0.1   $HOSTNAME $SHORTNAME localhost/" /etc/hosts
sed -i "s/^::1.*/::1   $HOSTNAME $SHORTNAME ip6-localhost ip6-loopback/" /etc/hosts
fi

kinit $JOIN_ACCOUNT -k -t /etc/domainjoin.keytab
# net ads -k join createcomputer=$JOIN_OU osName=$OSNAME osVer=$OSVER
net ads -k join createcomputer="$JOIN_OU"

# Create tsi homedir first since oddjob_mkhomedir will not honor umask on multiple subdirectories
if [ ! -d /home/tsi ]; then
  mkdir /home/tsi
fi
chmod 755 /home/tsi
chown root:root /home/tsi

systemctl enable sssd.service
systemctl enable oddjobd.service
systemctl restart sssd.service
systemctl restart oddjobd.service
if [ "$swver" = "CentOS" ]; then
   systemctl enable sshd.service
   systemctl restart sshd.service
elif [ "$swver" = "Ubuntu" ]; then
   systemctl enable ssh.service
   systemctl restart ssh.service
else
   #nothing
   echo "Unsupported system"
fi

printf "Enter new users account name to be added to Sudoeres to make them an Admin: "
read ADUSER
adduser $ADUSER sudo

# Pause script press <enter> to continue
read -p $'The AD user account will now be a full Admin when they login.\nPress enter to continue.....\n'

# Enable sudo access for users in AD group development, which will allow sudo access
sudo bash -c 'echo "%development ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/development'
sudo bash -c 'echo "%GG-TSI-AD-IT-M ALL=(ALL) ALL" >> /etc/sudoers.d/development'

# Append text to end of config files
echo 'allow-guest=false 
greeter-show-manual-login=true' >> /usr/share/lightdm/lightdm.conf.d/50-unity-greeter


# Install GParted
sudo apt-get -y gparted
echo "Installed GParted"

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
# Pause script press <enter> to continue
read -p $'\n\n\n\n\nThe Desktop Sharing Preferences box will appear after you press enter, please make the changes below:\n\nTick "Allow other users to view your desktop" and set a password.\nUntick "You must confirm each access to this machine".\n\nPress enter to continue......\n'
vino-preferences

# Pause script press <enter> to continue
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
