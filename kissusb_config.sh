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
# Script Name : kissusb_config.sh
# Author : Mitch Winkle, AB4MW
# Date : 3 July 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# TNC-X style USB KISS TNC, namely making a symlink to it in /root directory.
################################################################################
# Load environment variables
source /etc/hal/env/station.env
source /etc/hal/env/setup.env
SETUPENV=/etc/hal/env/setup.env
# dialog constants
BTITLE="HAL KISS USB TNC Setup"
# Which radio port are we configuring?
RADIO_PORT=$1
RADIO_PORT_NAME=''
if [[ ${NUM_RADIOS} -eq 1 ]]; then
	RADIO_PORT_NAME=$PORT_ONE
	RADIO_PORT=1
	sed -i '/^PORT_ONE_TYPE/d' $SETUPENV
	sed -i '/^PORT_ONE_RF_BAUD/d' $SETUPENV
	echo "PORT_ONE_TYPE=1" >> $SETUPENV
else
	case $RADIO_PORT in
		1)	RADIO_PORT_NAME=$PORT_ONE
			sed -i '/^PORT_ONE_TYPE/d' $SETUPENV
			sed -i '/^PORT_ONE_RF_BAUD/d' $SETUPENV
			echo "PORT_ONE_TYPE=1" >> $SETUPENV
			;;
		2)	RADIO_PORT_NAME=$PORT_TWO
			sed -i '/^PORT_TWO_TYPE/d' $SETUPENV
			sed -i '/^PORT_TWO_RF_BAUD/d' $SETUPENV
			echo "PORT_TWO_TYPE=1" >> $SETUPENV
			;;
		*)   	dialog --title "Which Port?" --backtitle "$BTITLE" --menu \
			"Select which radio port you will be configuring." 10 50 3 \
			 1 "$PORT_ONE" 2 "$PORT_TWO" \
			2>answer
			RADIO_PORT=`cat answer`
			if [[ $RADIO_PORT -eq 1 ]]; then
				RADIO_PORT_NAME=$PORT_ONE
				sed -i '/^PORT_ONE_TYPE/d' $SETUPENV
				sed -i '/^PORT_ONE_RF_BAUD/d' $SETUPENV
				echo "PORT_ONE_TYPE=1" >> $SETUPENV
			else
				RADIO_PORT_NAME=$PORT_TWO
				sed -i '/^PORT_TWO_TYPE/d' $SETUPENV
				sed -i '/^PORT_TWO_RF_BAUD/d' $SETUPENV
				echo "PORT_TWO_TYPE=1" >> $SETUPENV
			fi
			;;
	esac
fi
# check and reset serial port speed if necessary
currspeed=`cat /etc/ax25/axports|grep $RADIO_PORT_NAME|xargs|cut -f 3 -d ' '`
dialog --backtitle "$BTITLE" --title "Serial Speed Check" --inputbox \
"If this serial port speed is incorrect, adjust it now." 8 70 "$currspeed" 2>answer
serialspeed=`cat answer`
if [[ "$serialspeed" != "$currspeed" ]]; then
	# fix the axports serial speed for this port
	currline=`cat /etc/ax25/axports|grep ^$RADIO_PORT_NAME`
	NEWLINE=`cat /etc/ax25/axports|grep ^$RADIO_PORT_NAME|sed "s/${currspeed}/${serialspeed}/"`
	sed -i -r "s/${currline}/${NEWLINE}/" /etc/ax25/axports
	# In the case of just reconfiguring TNC-Pi, fix up FBB's port.sys file also
	if [[ $FBB_REQUIRED == "1" ]]; then
		# now fix port.sys
		currline=`cat /etc/ax25/fbb/port.sys|grep ${currspeed}$|grep ^${RADIO_PORT}`
		NEWLINE=`cat /etc/ax25/fbb/port.sys|grep ${currspeed}$|grep ^${RADIO_PORT}|sed "s/${currspeed}/${serialspeed}/"`
		sed -i -r "s/${currline}/${NEWLINE}/" /etc/ax25/fbb/port.sys
	fi
fi
cd /dev/serial/by-id
SERIAL_LIST=`ls -l * |grep 'ttyUSB'|cut -f 11,13 -d ' '`
USBDEV=`ls /dev/serial/by-id`
USBTTY=`echo $SERIAL_LIST|cut -f 2 -d ' '|cut -f 3 -d '/'`
USBTTY="/dev/${USBTTY}"
#echo $USB0TTY $USB0
menulist="$USBTTY --> $USBDEV"
SERIAL_COUNT=`ls -l * |grep 'ttyUSB'|wc -l`
if [[ $SERIAL_COUNT -gt 1 ]]; then
	# tell user too many devices plugged in and ??
	dialog --backtitle "$BTITLE" --title "USB KISS TNC Configuration" --msgbox \
"HAL noticed that you have more than one USB serial device plugged into this \
computer.  Please remove ALL USB serial devices other than the ONE USB KISS TNC \
you wish to configure for this radio port - $RADIO_PORT_NAME.  Once that is complete, select OK to continue." 9 70
fi
success=0
counter=0
while [[ $success == "0" ]]; do
	dialog --backtitle "$BTITLE" --title "USB KISS TNC Configuration" --msgbox \
	"First, remove ALL serial USB devices (not WiFi dongles or keyboard/mouse) \
	from the computer.  Then plug in ONLY the USB KISS TNC that you are trying to \
	configure.\n\nThe next screen will display the device you plugged in.  If you see \
	more than one line on the screen, there are other serial devices plugged in.  \
	If there is more than one line shown, you MUST \
	anser NO to the next screen and start again after removing the other serial device. \
	\n\nYou will be assigning a USB serial device to a radio port.  The radio port \
	name will be shown for you." 19 70
	dialog --backtitle "$BTITLE" --title "Use this USB Serial Device For Radio Port $RADIO_PORT_NAME ?" --yesno "$menulist" 7 78
	if [[ $? -eq 0 ]]; then
		# we have a good device, so make the symlink
		rm -f /root/kisstnc$RADIO_PORT
		ln -s /dev/serial/by-id/${USBDEV} /root/kisstnc$RADIO_PORT
		success=1
	fi
	let "counter += 1"
	if [[ $counter -gt 4 ]]; then
		dialog --backtitle "$BTITLE" --title "You seem to be having difficulties..." --msgbox \
		"Maybe there is a system problem or you didn't read the instructions as \
		well as you thought, so perhaps start from scratch and try again. \
		If that doesn't help, be sure to ask for help at http://haldigital.sf.net." 8 70
		exit 1
	fi
done
SERIAL_LIST=`ls -l /root/kisstnc*`
dialog --backtitle "$BTITLE" --title "USB KISS TNC Linked" --msgbox "$SERIAL_LIST" 7 70 

# Clean up 
[[ -f answer ]] && rm -f answer
