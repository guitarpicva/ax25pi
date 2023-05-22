#!/bin/bash
################################################################################
# Script Name : hal_axmail.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 24 June 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the HAL
# implementation of the AxMailFax program.
################################################################################
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
UROCONF=/etc/ax25/uronode.conf
source /etc/hal/env/functions.env
hal_copy welcome.txt
hal_copy axmail.conf
AXMAIL=/etc/hal/work/axmail.conf.hal
BTITLE="HAL AxMailFax Configuration"
dialog --backtitle "$BTITLE" --title "Enable/Disable AxMail?" --yesno \
	"Do you wish to enable AxMailFax?  This is a companion program to \
	Uronode which allows your users to create a mailbox on your Linux \
	machine and send and retrieve regular emails to one another \
	via Uronode.  Answering \"No\" will immediately DISABLE AxMailFax on this system. \
	Answering \"Yes\" will immediately enable AxMailFax on this system.\n\n \
	NOTE: If you do NOT run Uronode, users will not be able to use AxMailFax." 14 70 
if [[ $? -eq 0 ]]; then
	#####################################################################
	# axmail configuration
	#ExtCmd          MAil    1       root    /usr/sbin/axmail axmail %u
	#
	# Simply update /etc/hal/work/axmail.conf with the correct contact email
	# and add the ExtCmd line to uronode.conf to launch axMail from the
	# Uronode prompt.  Also change the welcome.txt file
	#####################################################################
	sed -i -r '/^AXMAIL_REQUIRED/d' $SETUPENV
	echo "AXMAIL_REQUIRED=1" >> $SETUPENV
	sed -i "s/<your>.ampr.org/${HOSTNAME}/g" $AXMAIL
	sed -i "s/root/${lcall}@${HOSTNAME}/g" /etc/hal/work/welcome.txt.hal
	# if the uronode.conf file does NOT already contain an
	# ExtCmd line for axmail, then add one
	if [[ `grep -c "axmail axmail" $UROCONF` -eq 0 ]]; then
		echo "ExtCmd          MAil    1       root    /usr/sbin/axmail axmail %u" >> $UROCONF
	fi
	cp -f $AXMAIL /etc/ax25/axmail.conf
else 	
	# adjust setup.env to indicate that AxMailFax is not required.
	sed -i -r '/^AXMAIL_REQUIRED/d' $SETUPENV
	echo "AXMAIL_REQUIRED=0" >> $SETUPENV
	# remove the connector line from uronode.conf which disables AxMailFax
	sed -i -r '/axmail axmail/d' $UROCONF
fi