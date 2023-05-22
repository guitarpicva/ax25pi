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
# Use Debian package manager apt to install required packages.
#apt-get update
apt-get install libasound2 libasound2-dev socat libncurses5 \
libncurses5-dev libax25 ax25-apps ax25-tools xinetd zlib1g telnet \
dialog procmail lynx postfix hexedit bc zlib1g-dev libax25-dev
# when postfix asks, answer LOCAL MAIL ONLY
# Now use dpkg to install Direwolf, uronode, axmail, and FBB debs
cd /root/src
dpkg -i haldirewolf_20150622-1_armhf.RPi1.deb
dpkg -i haluronode_20150614-1_armhf.RPi2.deb
dpkg -i halaxmail_20150614-1_armhf.RPi2.deb
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
			rm -f ./hal*.deb
			rm -fr ./HALfbb/*
			rmdir HALfbb
			break;;
		*)      break;;
	esac
done
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
