#!/bin/bash
################################################################################
# Script Name : hal_uronode.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 29 June 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# Uronode software.
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
# FUNCTIONS 
source /etc/hal/env/functions.env
# read current environment
source /etc/hal/env/setup.env
source /etc/hal/env/station.env
SETUPENV=/etc/hal/work/setup.env.hal
cp /etc/hal/env/setup.env $SETUPENV
# Production config files copied to working files for adjustment
cp -f /etc/ax25/uronode.conf /etc/hal/work/uronode.conf.hal
UROCONF=/etc/hal/work/uronode.conf.hal
AX25D=/etc/hal/work/ax25d.conf.hal
# First determine if Uronode is already configured
if [[ $URONODE_REQUIRED -eq 1 ]]; then
	
	dialog --backtitle "$BTITLE" --title "Uronode Already Configured" --exit-label "Continue" --msgbox \
	"The system has already been configured for Uronode. \
	HAL will now show you the configuration and you may choose whether or \
	not to make changes." 8 70
	
	dialog --backtitle "$BTITLE" --title "Change Uronode Configuration" --yesno \
	"Would you like to make changes to Uronode on this system?" 6 70 
	if [[ $? -eq 0 ]]; then
		idle=`cat /etc/ax25/uronode.conf|grep '^IdleTimeout'|tr -s '\t' ' '| cut -f 2 -d ' '`
		conn=`cat /etc/ax25/uronode.conf|grep '^ConnTimeout'|tr -s '\t' ' '|cut -f 2 -d ' '`
		host=`cat /etc/ax25/uronode.conf|grep '^HostName'|tr -s '\t' ' '|cut -f 2 -d ' '`
		email=`cat /etc/ax25/uronode.conf|grep '^Email'|tr -s '\t' ' '|cut -f 2 -d ' '`
		localnet=`cat /etc/ax25/uronode.conf|grep '^LocalNet'|tr -s '\t' ' '|cut -f 2 -d ' '`
		hidden=`cat /etc/ax25/uronode.conf|grep '^HiddenPorts'|tr -s '\t' ' '|cut -f 2 -d ' '`
		nodeid=`cat /etc/ax25/uronode.conf|grep '^NodeId'|tr -s '\t' ' '|cut -f 2 -d ' '`
		flexid=`cat /etc/ax25/uronode.conf|grep '^FlexId'| tr -s '\t' ' '|cut -f 2 -d ' '`
		roseid=`cat /etc/ax25/uronode.conf|grep '^RoseId'|tr -s '\t' ' '|cut -f 2 -d ' '`
		nrport=`cat /etc/ax25/uronode.conf|grep '^NrPort'|tr -s '\t' ' '|cut -f 2 -d ' '`
		loglevel=`cat /etc/ax25/uronode.conf|grep '^LogLevel'|tr -s '\t' ' '|cut -f 2 -d ' '`
		escapechar=`cat /etc/ax25/uronode.conf|grep '^EscapeChar'|tr -s '\t' ' '|cut -f 2 -d ' '`				
		# open fd
		exec 3>&1
		 
		# Store data to $VALUES variable
		VALUES=$(dialog --ok-label "Submit" \
			  --backtitle "$DTITILE" \
			  --title "Uronode Configuration" \
			  --form "Edit the Uronode Listener Configuration.\n\n \
Values for NodeId (Net/ROM), FlexId (AX25), RoseId (Rose) \
and NrPort (Net/ROM) are changed in their (indicated) \
HAL configuration scripts. Current values are shown below." 25 60 0 \
			"IdleTimeout :"	1 1	"${idle}" 	1 25 5 0 \
			"ConnTimeout :" 2 1	"${conn}" 	2 25 5 0 \
			"HostName :" 	3 1	"${host}" 	3 25 40 0 \
			"Email :"     	4 1	"${email}" 	4 25 40 0 \
			"LocalNet :" 	5 1	"${localnet}" 	5 25 18 0 \
			"HiddenPorts :" 6 1	"${hidden:-none}" 	6 25 16 0 \
			"NodeId :" 	7 1	"${nodeid}" 	7 25 0 0 \
			"FlexId :"     	8 1	"${flexid}" 	8 25 0 0 \
			"RoseId :" 	9 1	"${roseid}" 	9 25 0 0 \
			"NrPort :"     	10 1	"${nrport}" 	10 25 0 0 \
			"LogLevel (0 for none) :" 	11 1	"${loglevel}" 	11 25 1 0 \
			"EscapeChar :"  12 1	"${escapechar}" 12 25 2 0 \
		2>&1 1>&3)
		 
		# close fd
		exec 3>&-
		VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
		read nidle nconn nhost nemail nlocalnet nhidden nloglevel nescapechar <<<$VALUES
		echo "VALUES: $nidle $nconn $nhost $nemail $nlocalnet $nhidden $nloglevel $nescapechar"
		sed -i -r "s/^IdleTimeout[[:blank:]]*${idle}$/IdleTimeout\t${nidle}/" $UROCONF
		sed -i -r "s/^ConnTimeout[[:blank:]]*${conn}$/ConnTimeout\t${nconn}/" $UROCONF
		sed -i -r "s/^HostName[[:blank:]]*${host}$/HostName\t${nhost}/" $UROCONF
		sed -i -r "s/^Email[[:blank:]]*${email}$/Email\t${nemail}/" $UROCONF
		sed -i -r "s|^LocalNet[[:blank:]]*${localnet}$|LocalNet\t${nlocalnet}|" $UROCONF
		if [[ $nhidden != "" && $nhidden != "none" ]]; then
			sed -i -r "s/^HiddenPorts[[:blank:]]*${idle}$/HiddenPorts\t${nhidden}/" $UROCONF
		fi
		sed -i -r "s/^LogLevel[[:blank:]]*${loglevel}$/LogLevel\t${nloglevel}/" $UROCONF
		sed -i -r "s/^EscapeChar[[:blank:]]*${escapechar}$/EscapeChar\t${nescapechar}/" $UROCONF
		sed -i '/^URO_LOCALNET/d' $UROCONF
		if [[ $URO_LOCALNET == "" ]]; then
			echo "URO_LOCALNET=44.128.0.1/32" >> $SETUPENV
		else					
			echo "URO_LOCALNET=${URO_LOCALNET}" >> $SETUPENV
		fi
	else
		dialog --backtitle "$BTITLE" --title "Notice" --exit-label "Finished" \
	--msgbox "The system has **** NOT **** been changed." 8 70
	exit 0
	fi
else	
	:	
fi # end of top if
################################################################################
# Now it's time to make the changes permanent.
dialog --backtitle "$BTITLE" --title "Enable Uronode Changes?" --yesno \
	"HAL has finished making the changes to the work files.\n\n \
	Select \"Yes\" to make the changes or \"No\" abandon them." 9 70
if [[ $? -eq 0 && $URONODE_REQUIRED -eq 1 ]]; then
	cp -f $UROCONF /etc/ax25/uronode.conf
	cp -f $AX25D /etc/ax25/ax25d.conf
	sed -i -r '/^URONODE_REQUIRED/d' $SETUPENV
	echo "URONODE_REQUIRED=1" >> $SETUPENV
	cp -f /etc/hal/work/setup.env.hal /etc/hal/env/setup.env
	dialog --backtitle "$BTITLE" --title "Notice" --exit-label "Finished" \
	--msgbox "The system has been updated to your specifications." 8 70
else
	dialog --backtitle "$BTITLE" --title "Notice" --exit-label "Finished" \
	--msgbox "The system has **** NOT **** been updated." 8 70
fi

# Tidy up
[[ -f answer ]] && rm -f answer
#rm -f /etc/hal/work/*
exit 0