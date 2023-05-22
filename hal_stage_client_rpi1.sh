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
# SCRIPT NAME : hal_stage_client.sh FOR THE Raspberry Pi v 2
# AUTHOR : Mitch Winkle, AB4MW
# LICENSE : Gnu GPL v3.0
# DATE : 2015-05-26
# DESCRIPTION : Takes a newly minted Debian based system and arranges
# diretories, copies original distro config files, and installs a 
# current HAL script system.  Also installs all necessary packages for a
# HAL client system. 
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# RUN THIS SCRIPT AS ROOT    RUN THIS SCRIPT AS ROOT 
# !!!!!!!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# FOR AUTHOR USE ONLY AND SHOULD NEVER BE RUN ON A FUNCTIONAL SYSTEM
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
########################################################################
#
startdate=`date`
# Get the HALcurrent.tgz file from the web server which makes all 
# required directories and populates .env files and scripts.
cd /root/src
# Use Debian package manager apt to install required packages.
#apt-get update
apt-get install libasound2 libasound2-dev socat libncurses5 \
libncurses5-dev libax25 ax25-apps ax25-tools xinetd zlib1g telnet \
dialog lynx bc zlib1g-dev libax25-dev libtool \
libltdl-dev autoconf automake autotools-dev m4 perl perl-base perl-modules
# Install Direwolf, Linpac, ax25spyd and ax25mail-utils
cd /root/src
dpkg -i ax25spyd_0.23-8_armhf.deb
dpkg -i halax25mail-utils_0.12-1_armhf.RPi2.deb
dpkg -i hallinpac_0.21-1_armhf.RPi2.deb
dpkg -i haldirewolf_1.2-1_armhf.RPi1.deb
# allow regular users to start Linpac
touch /var/lock/LinPac.0
chmod 666 /var/lock/LinPac.0
# link up the ax25 startup script to /usr/sbin for ease of use
chmod 2755 /etc/init.d/ax25
ln -s /etc/init.d/ax25 /usr/sbin/ax25
# get ax25 into SysV init
update-rc.d ax25 defaults
# add aliases to it's easy to run HAL -- courteous nod to K6BPS
echo "alias HAL=/usr/local/bin/hal_config.sh" >> /root/.bashrc
echo "alias HAL='sudo /usr/local/bin/hal_config.sh'" >> /home/pi/.bashrc
# tar.gz up all of the config files for a just in case scenario and 
# copy to /etc/hal/dist
tar cvzf /etc/hal/dist/AX25.Dist.tar.gz /etc/ax25/*
# Special Case fix for RaspberryPi to function properly with nrattach.
# Probably not needed for client build, but if the user changes to server
# applications later it will be done....this is a sensible change anyway.
if grep 'BCM270[89]$' /proc/cpuinfo
then sed -i -r 's/^HOTPLUG_INTERFACES=\"all\"$/HOTPLUG_INTERFACES=\"eth0 wlan0\"/' /etc/default/ifplugd
fi
# Now run Linpac as the root user to create template config files in /root
linpac
# now run Linpac as the pi user to create template config files in /home/pi
sudo -u pi linpac
# erase mail directories created in ~/LinPac/mail
rm -f /root/LinPac/mail/*
rm -f /home/pi/LinPac/mail/*
# Clean up tarballs and unpacked source code
echo "Should HAL erase all tarballs and source trees?"
select yn in Yes No
do
	case $yn in 
		Yes) 
			cd /root/src;
			rm -fR ./*
			break;;
		*)      break;;
	esac
done
echo "Began staging this image at "$startdate
echo "Finished staging this image at "`date`
exit 0
