#!/bin/bash
################################################################################
# Script Name : hal_axdigi.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 2 Jul 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# axdigi application which is part of Uronode.
################################################################################
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
#    You should have received a copy of the GNU General Public License along
#    with HAL (COPYING text file).  If not, see <http://www.gnu.org/licenses/>.
################################################################################
SETUPENV=/etc/hal/env/setup.env
BTITLE="HAL axdigi Configuration"
source $SETUPENV
# If more than one radio, check if the user wants AXDIGI
if [[ $NUM_RADIOS -eq 2 ]]; then
	# Query if AXDIGI_REQUIRED for ax25-up/ax25-down
	dialog --backtitle "$BTITLE" --title "Enable Axdigi?" --yesno \
	"Do you wish to enable the axdigi program?  This is a companion program to \
Uronode which allows your users to cross-port digipeat \
using the AX.25 port's callsign-SSID.\n\nSee \"man axdigi\" for more intformation." 10 70
	if [[ $? -eq 0 ]]; then
		# setting this env var will enable the axdigi program
		# when ax25-up runs during init
		sed -i -r '/^AXDIGI_REQUIRED/d' $SETUPENV
		echo "AXDIGI_REQUIRED=1" >> $SETUPENV
		# just in case
		killall axdigi
		sleep 1
		# start axdigi immediately
		/usr/sbin/axdigi &
		pidofaxdigi=`pidof axdigi`
		dialog --backtitle "$BTITLE" --title "axdigi Enabled" --msgbox \
		"axdigi has been enabled in the AX.25 startup process and has been \
		started now. pidof axdigi [$pidofaxdigi]" 12 70
	else 
		sed -i -r '/^AXDIGI_REQUIRED/d' $SETUPENV
		echo "AXDIGI_REQUIRED=0" >> $SETUPENV
		killall axdigi
		dialog --backtitle "$BTITLE" --title "axdigi Disabled" --msgbox \
		"axdigi has been disabled in the AX.25 startup process and has been \
		stopped now." 7 70
	fi	
else
	dialog --backtitle "$BTITLE" --title "axdigi Not Available" --msgbox \
	"You only seem to have one radio port defined.  axdigi requires two \
	radio ports for it's cross-port functionality.  Sorry.\n\nIf you wish to \
	have a cross-port digipeater, install another radio, go through the ax25 \
	and ax25d menu items, and come back to this script." 11 70
	
fi
exit 0