#!/bin/bash
####################################################################
#This file is part of Ham Arch Linux (HAL).
# Copyright 2015 Mitch Winkle
#
#    HAL is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    HAL is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with HAL (COPYING text file).  If not, see <http://www.gnu.org/licenses/>.
########################################################################
# SCRIPT NAME : hal_stage.sh
# AUTHOR : Mitch Winkle, AB4MW
# LICENSE : Gnu GPL
# DATE : 2015-05-26
# DESCRIPTION : Takes a newly minted Debian based system and arranges
# diretories, copies original distro config files, and installs a 
# current HAL script system.  Also installs all necessary packages for a
# HAL system. 
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# RUN THIS SCRIPT AS ROOT    RUN THIS SCRIPT AS ROOT 
# !!!!!!!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# FOR AUTHOR USE ONLY AND SHOULD NEVER BE RUN ON A FUNCTIONAL SYSTEM
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
########################################################################
#
startdate=`date`
cd /root/src
# If an ARM based board, we're likely using an SD card so make sure logging
# is limited to a tmp file system so the card lasts longer.  Also turn off
# the swapfile and remove it, and disallow it on boot.
# ensure /var/log is on a tmpfs
echo "none            /var/log            tmpfs   size=1M,noatime             0   0" >> /etc/fstab
# stop swap, remove swap file and ensure it does not get re-started on reboot
dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove
# Use Debian package manager apt to install required packages.
#apt-get update
apt-get install libasound2 libasound2-dev socat libncurses5 \
libncurses5-dev libax25 ax25-apps ax25-tools xinetd zlib1g zlib1g-dev \
dialog procmail lynx postfix hexedit bc telnet libax25-dev libtool \
libltdl-dev autoconf automake autotools-dev m4 perl perl-base perl-modules
# when postfix asks, answer LOCAL MAIL ONLY
# Now use dpkg to install Direwolf, uronode, axmail, and FBB debs
cd /root/src
dpkg -i ax25spyd_0.23-8_armhf.deb
dpkg -i halax25mail-utils_0.12-1_armhf.RPi2.deb
dpkg -i hallinpac_0.21-1_armhf.RPi2.deb
dpkg -i haldirewolf_1.2-1_armhf.RPi2.deb
dpkg -i haluronode_20150614-1_armhf.RPi2.deb
dpkg -i halaxmail2.5_20150708-1_armhf.RPi2.deb
tar xzf HALfbb.tar.gz
cd /root/src/HALfbb
make install && make installconf
# enable the startup script for FBB
if [[ -d /etc/ax25/fbb ]]; then
	cp -f /etc/hal/template/fbb.conf.hal /etc/ax25/fbb/fbb.conf
else
	echo "ERROR: AX.25 and/or FBB not installed...exiting...Check \
	for the /ec/ax25 directory and the /etc/ax25/fbb directory."
	exit 1	
fi
cp /usr/share/doc/fbb/fbb.sh /usr/local/bin
chmod +x /usr/local/bin/fbb.sh
chmod 666 /var/ax25/node/loggedin
chmod 644 /etc/ax25/flexd.conf
# enable uronode from the local shell
echo "uronode		3694/tcp			# uronode" >> /etc/services
# restart xinetd so uronode will work right away
/etc/init.d/xinetd restart
# for axmail
groupadd ax25
# link up the ax25 startup script to /usr/sbin for ease of use
chmod 2755 /etc/init.d/ax25
ln -s /etc/init.d/ax25 /usr/sbin/ax25
# get ax25 into SysV init
update-rc.d ax25 defaults
# tar.gz up all of the config files for a just in case scenario and 
# copy to /etc/hal/dist
tar cvzf /etc/hal/dist/AX25.Dist.tar.gz /etc/ax25/*
# Special Case fix for RaspberryPi to function properly with nrattach
if grep 'BCM270[89]$' /proc/cpuinfo
then sed -i -r 's/^HOTPLUG_INTERFACES=\"all\"$/HOTPLUG_INTERFACES=\"eth0 wlan0\"/' /etc/default/ifplugd
fi
# Clean up tarballs and unpacked source code
echo "Should HAL erase all tarballs and source trees?"
select yn in Yes No
do
	case $yn in 
		Yes) 
			cd /root/src;
			rm -f ./*.deb
			rm -fr ./HALfbb/*
			rmdir HALfbb
			rm -f ./HALfbb.tar.gz
			break;;
		*)      break;;
	esac
done
echo "HAL will now launch LinPac ** TWICE** so that it will create it's remaining \
configuration files for the \"root\" user as well as the \"pi\" user.  Your entries \
are not important, but just that the script finishes.  Hit any key to continue."
read dummy
# allow regular users to start Linpac
touch /var/lock/LinPac.0
chmod 666 /var/lock/LinPac.0
# Now run Linpac as the root user to create template config files in /root
linpac
# now run Linpac as the pi user to create template config files in /home/pi
sudo -u pi linpac
# erase mail directories created in ~/LinPac/mail
rm -f /root/LinPac/mail/*
rm -f /home/pi/LinPac/mail/*
# Now run the initial "fbb" script to create the rest of the files FBB requires
# and only it's script can create.
echo "HAL will now launch the fbb script so that it will create it's remaining \
configuration files and it should successfully launch FBB once it finishes. \
You should answer \"Y\" to ALL questions.  Hit any key to continue."
read dummy
/usr/sbin/fbb
sleep 2
echo "Began staging this image at $startdate"
echo "Finished staging this image at "`date`
exit 0
