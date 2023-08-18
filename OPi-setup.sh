#!/bin/bash

if [ "$(whoami)" != "root" ]; then
	echo "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi

export USERHOME=$(sudo -u $SUDO_USER -H bash -c 'echo $HOME')

sudo apt -y remove unattended-upgrades
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade

echo "Installing Synaptic"
sudo apt -y install synaptic software-properties-common
sudo apt -y install xfce4-goodies indicator-multiload

#########################################################
#############  SAMBA file sharing

echo "Setting up File Sharing"
sudo apt -y install samba samba-common-bin

if [ ! -f /etc/samba/smb.conf ]
then
	sudo mkdir -p /etc/samba/
##################
sudo --preserve-env bash -c 'cat > /etc/samba/smb.conf' <<- EOF
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   server role = standalone server
   obey pam restrictions = yes
   unix password sync = yes
   log file = /var/log/samba/log.%m
   max log size = 50
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
   map to guest = bad user
   usershare allow guests = yes
   fruit:copyfile = yes
[$SUDO_USER]
   comment = $SUDO_USER Home
   path = /home/$SUDO_USER
   browseable = yes
   writeable = yes
   read only = no
   valid users = $SUDO_USER
EOF
##################
fi

if [ -z "$(sudo pdbedit -L | grep $SUDO_USER)" ]
then
	sudo smbpasswd -a $SUDO_USER
	sudo adduser $SUDO_USER sambashare
fi

#########################################################
#############  x11VNC

sudo apt -y install x11vnc
x11vnc -storepasswd /etc/x11vnc.pass

######################
sudo --preserve-env bash -c 'cat > /lib/systemd/system/x11vnc.service' << EOF
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target
[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -avahi -forever -loop -noxdamage -repeat -rfbauth /etc/x11vnc.pass -rfbport 5900 -shared
[Install]
WantedBy=multi-user.target
EOF
######################

sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
sudo systemctl start x11vnc.service

sudo usermod -a -G dialout $SUDO_USER
sudo apt -y remove brltty
sudo apt -y remove modemmanager

echo "Installing iPhone USB Tethering"
sudo apt -y install ipheth-utils usbmuxd libimobiledevice-dev libimobiledevice-utils

#########################################################
#############  KStars INDI PHD2 Python3 INDIweb SIRIL

echo "Installing INDI and KStars"
sudo apt-add-repository ppa:mutlaqja/ppa -y
sudo apt update
sudo apt -y install indi-full kstars-bleeding

echo "Installing GSC"
sudo apt -y install gsc

echo "Installing PHD2"
sudo apt-add-repository ppa:pch/phd2 -y
sudo apt update
sudo apt -y install phd2

echo "Installing python3"
sudo apt -y install python3-pip
sudo apt -y install python3-dev
sudo apt -y install python3-setuptools
sudo -H -u $SUDO_USER pip3 install setuptools --upgrade
sudo -H -u $SUDO_USER pip3 install wheel

echo "Installing INDIweb"
sudo -H -u $SUDO_USER pip3 install indiweb

echo "Installing Siril"
sudo add-apt-repository ppa:lock042/siril -y
sudo apt update
sudo apt -y install siril
