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
################################################################################
# Script Name : tncpi_config.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date: 3 July 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# TNC-Pi connetion to the AX.25 system, namely a symlink in the /root directory.
################################################################################
# Load environment variables
source /etc/hal/env/station.env
source /etc/hal/env/setup.env
SETUPENV=/etc/hal/env/setup.env
# dialog constants
BTITLE="HAL TNC-Pi TNC Setup"
# Which radio port are we configuring?
RADIO_PORT=$1
RADIO_PORT_NAME=''
if [[ ${NUM_RADIOS} -eq 1 ]]; then
	RADIO_PORT_NAME=$PORT_ONE
	sed -i '/PORT_ONE_SPEED/d' $SETUPENV
	echo "PORT_ONE_SPEED=19200" >> $SETUPENV
	sed -i '/^PORT_ONE_TYPE/d' $SETUPENV
	echo "PORT_ONE_TYPE=2" >> $SETUPENV
	sed -i '/^PORT_ONE_RF_BAUD/d' $SETUPENV
	echo "PORT_ONE_RF_BAUD=1200" >> $SETUPENV
	RADIO_PORT=1
else	
	case $RADIO_PORT in
		1)	RADIO_PORT_NAME=$PORT_ONE
			sed -i '/PORT_ONE_SPEED/d' $SETUPENV
			echo "PORT_ONE_SPEED=19200" >> $SETUPENV
			sed -i '/^PORT_ONE_TYPE/d' $SETUPENV
			echo "PORT_ONE_TYPE=2" >> $SETUPENV
			sed -i '/^PORT_ONE_RF_BAUD/d' $SETUPENV
			echo "PORT_ONE_RF_BAUD=1200" >> $SETUPENV
			;;
		2)	RADIO_PORT_NAME=$PORT_TWO
			sed -i '/PORT_TWO_SPEED/d' $SETUPENV
			echo "PORT_TWO_SPEED=19200" >> $SETUPENV
			sed -i '/^PORT_TWO_TYPE/d' $SETUPENV
			echo "PORT_TWO_TYPE=2" >> $SETUPENV
			sed -i '/^PORT_TWO_RF_BAUD/d' $SETUPENV
			echo "PORT_TWO_RF_BAUD=1200" >> $SETUPENV
			;;
		*)   	dialog --title "Which Port?" --backtitle "$BTITLE" --menu \
			"Select which radio port you will be configuring." 10 50 3 \
			1 $PORT_ONE 2 $PORT_TWO  \
			2>answer
			RADIO_PORT=`cat answer`
			if [[ ${RADIO_PORT} -eq 1 ]]; then
				RADIO_PORT_NAME=$PORT_ONE
				sed -i '/PORT_ONE_SPEED/d' $SETUPENV
				echo "PORT_ONE_SPEED=19200" >> $SETUPENV
				sed -i '/^PORT_ONE_TYPE/d' $SETUPENV
				echo "PORT_ONE_TYPE=2" >> $SETUPENV
				sed -i '/^PORT_ONE_RF_BAUD/d' $SETUPENV
				echo "PORT_ONE_RF_BAUD=1200" >> $SETUPENV
			else
				RADIO_PORT_NAME=$PORT_TWO
				sed -i '/PORT_TWO_SPEED/d' $SETUPENV
				echo "PORT_TWO_SPEED=19200" >> $SETUPENV
				sed -i '/^PORT_TWO_TYPE/d' $SETUPENV
				echo "PORT_TWO_TYPE=2" >> $SETUPENV
				sed -i '/^PORT_TWO_RF_BAUD/d' $SETUPENV
				echo "PORT_TWO_RF_BAUD=1200" >> $SETUPENV
			fi
			;;
	esac
fi
if [[ $RADIO_PORT_NAME == "" ]]; then
	echo "Missing or incorrect input parameter of radio port, either 1 or 2....exiting"
	exit 1	
fi
serialspeed=`cat /etc/ax25/axports|grep $RADIO_PORT_NAME|xargs|cut -f 3 -d ' '`
echo "SERIALSPEED:$serialspeed" > /root/sspeed
if [[ "$serialspeed" != "19200" ]]; then
	echo "GOT INTO serialspeed loop" >> /root/sspeed
	# fix the axports serial speed for this port
	currline=`cat /etc/ax25/axports|grep ^$RADIO_PORT_NAME`
	NEWLINE=`cat /etc/ax25/axports|grep ^$RADIO_PORT_NAME|sed "s/${serialspeed}/19200/"`
	sed -i -r "s/${currline}/${NEWLINE}/" /etc/ax25/axports
	echo "$NEWLINE" >> /root/sspeed
	# In the case of just reconfiguring TNC-Pi, fix up FBB's port.sys file also
	if [[ $FBB_REQUIRED == "1" ]]; then
		# now fix port.sys
		currline=`cat /etc/ax25/fbb/port.sys|grep ${serialspeed}$|grep ^${RADIO_PORT}`
		NEWLINE=`cat /etc/ax25/fbb/port.sys|grep ${serialspeed}$|grep ^${RADIO_PORT}|sed "s/${serialspeed}/19200/"`
		sed -i -r "s/${currline}/${NEWLINE}/" /etc/ax25/fbb/port.sys
	fi
fi
# Test to see if the console parameters are in /boot/cmdline.txt
if grep ^console=ttyAMA0,115200 /boot/cmdline.txt
then
	dialog --backtitle "$BTITLE" --title "TNC-Pi Configuration" --msgbox \
		"Please note that in order for the TNCPi to work properly, HAL must \
	change a line in the /boot/cmdline.txt file.  HAL will remove the text, \
	\" console=ttyAMA0,115200 \" from that file afer making a backup copy called, \
	/boot/cmdline.txt.orig.hal" 9 70
	# Special case for the TNCPi that uses the Serial Console port on the RPi
	if [[ ! -f /boot/cmdline.txt.orig.hal ]]; then 
		cp -f /boot/cmdline.txt /boot/cmdline.txt.orig.hal
	fi
	sed -i 's/ console=ttyAMA0,115200 / /' /boot/cmdline.txt
fi
# Comment out the respawn of the serial console device since we are using a TNC-Pi
if grep 'ttyAMA0' /etc/inittab
then
	dialog --backtitle "$BTITLE" --title "TNC-Pi Configuration" --msgbox \
	"Please note that in order for the TNCPi to work properly, HAL must \
	comment out a line in the /etc/inittab file.  HAL will comment out the line \
	that respawns the console on /dev/ttyAMA0." 8 70
	sed -i 's|T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100|#T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100|g' /etc/inittab
fi

dialog --backtitle "$BTITLE" --title "TNC-Pi Linked" \
--msgbox "HAL has created the necessary configuration to start the TNC-Pi on \
/dev/ttyAMA0 as the TNC for port \"$RADIO_PORT_NAME\" upon startup of AX.25.\n\n \
!!! YOU MUST REZBOOT THE Raspberry Pi before AX.25 will work. !!!" \
10 70
# Tidy up
[[ -f answer ]] && rm -f answer
