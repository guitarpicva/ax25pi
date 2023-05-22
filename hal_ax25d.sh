#!/bin/bash
################################################################################
# Script Name : hal_ax25d.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 1 July 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# AX.25 daemon (ax25d).
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
# WARNING: THIS SCRIPT OVERWRITES THE PRODUCTION CONFIG FILES!!@@!!@@
# The user is warned to NEVER...EVER run this script on a customized
# system.  It is meant for a HAL imaged system ONLY.!!!!!
################################################################################
# FUNCTIONS 
source /etc/hal/env/functions.env
source /etc/hal/env/setup.env
source /etc/hal/env/station.env
# Working config files
AX25D="/etc/hal/work/ax25d.conf.hal"
NRPORTS="/etc/hal/work/nrports.hal"
NRBROADCAST="/etc/hal/work/nrbroadcast.hal"
# Environment variable files
STATIONENV="/etc/hal/work/station.env.hal"
SETUPENV="/etc/hal/work/setup.env.hal"
DEBUG_FILE="/var/log/hal_ax25d.debug"
if [[ $1 == "-d" ]]; then
	DEBUG_ON=1
	echo "" > $DEBUG_FILE
else
	DEBUG_ON=0
fi
[[ $DEBUG_ON -eq 1 ]] && debug "Begin hal_ax25d run" $DEBUG_FILE
# Vars to use in dialog calls
BTITLE="HAL ax25d Configuration"
################################################################################
# Establish the HAL version in the brand new setup.env file
echo "HAL_VERSION=1" > $SETUPENV
################################################################################
# Interrogate for creation of the ax25d.conf file.
################################################################################
# Make the text lines for ax25d.conf to listen for ax.25 connects and connect  
# them to Uronode.  Then do the same for Net/ROM.
################################################################################
AX25D_REQUIRED=0
URONODE_REQUIRED=0
AXMAIL_REQUIRED=0
dialog --backtitle "$BTITLE" --title "Getting Started" --yesno \
"Configuration of optional Uronode and Net/ROM listeners.  This may only \
be used when AX.25 ports are already defined.\n\nUronode \
provides a \"landing spot\" for incoming AX.25 and Net/ROM connections \
so users my make use of a wide array of applications.  If you only \
intend to use this sytem as an APRS digi or iGate, etc., you \
probably do not need Uronode and Net/ROM.  If that is the case \
simply answer \"No\" here.\n\nThis configuration script will configure the \
ax25d daemon (ax25d) completely, including Net/ROM (nrports and nrbroadcast). \
It will NOT allow you to make minor adjustments to \
an existing configuration.\n\nIf you create a Uronode listener, you MUST then \
use the #2 Uronode script from the main menu to configure it.\n\nIf you create a Net/ROM \
listener, you MAY then use the #6 Net/ROM script from the main menu to make \
adjustments to it.\n\n Shall we continue with Uronode and \
Net/ROM configuration?" 24 70 
if [[ "$?" == "0" ]]; then
	AX25D_REQUIRED=1
	sed -i '/^AX25D_REQUIRED/d' $SETUPENV
	echo "AX25D_REQUIRED=1" >> $SETUPENV
	echo "# Created by HAL" > $AX25D
	# Create a Uronode listener for the first port?
	dialog --backtitle "$BTITLE" --title \
	"Create a Uronode Listener" --yesno "Shall we create a listener for Uronode on port \"${PORT_ONE}\"?" 6 70
	if [[ "$?" == "0" ]]; then
		[[ $DEBUG_ON -eq 1 ]] && debug "User chose Uronode port one" $DEBUG_FILE
		URONODE_REQUIRED=1
		sed -i '/^URONODE_REQUIRED/d' $SETUPENV
		echo "URONODE_REQUIRED=1" >> $SETUPENV
		dialog --backtitle "$BTITLE" --title "Select Uronode SSID" --inputbox \
		"Input the SSID (1-9) to use with Uronode and press <Enter>" 6 60 "${URO_SSID:-7}" 2>answer
		URO_SSID=`cat answer`
		sed -i '/^URO_SSID/d' $SETUPENV
		echo "URO_SSID=${URO_SSID}" >> $SETUPENV
		printf "#$PORT_ONE Uronode Definition\n[${STATION_CALL}-${URO_SSID} via ${PORT_ONE} ]\nNOCALL * * * * * * L\nN0CALL * * * * * * L\ndefault * * * * * * 0 root /usr/sbin/uronode uronode\n" >> $AX25D
		content=`cat $AX25D`
		dialog --backtitle "$BTITLE" --title "First Uronode Listener Created" --msgbox "$content" 12 70
	else
		sed -i '/^URONODE_REQUIRED/d' $SETUPENV
		echo "URONODE_REQUIRED=0" >> $SETUPENV
	fi	
	# Offer to create the same for the second port
	if [[ $NUM_RADIOS == 2 ]]; then
		dialog --backtitle "$BTITLE" --title "Create Uronode Listener?" \
		--yesno "Shall we create a listener for Uronode on port two?" 12 70
		if [[ "$?" == "0" ]]; then	
			[[ $DEBUG_ON -eq 1 ]] && debug "User chose Uronode port two" $DEBUG_FILE
			URONODE_REQUIRED=1
			sed -i '/^URONODE_REQUIRED/d' $SETUPENV
			echo "URONODE_REQUIRED=1" >> $SETUPENV
			if [[ $URO_SSID == "" ]]; then
				dialog --backtitle "$BTITLE" --title "Select Uronode SSID" --inputbox \
			"Input the SSID (1-9) to use with Uronode and press <Enter>" 5 60 "${URO_SSID:-7}" 2>answer
				URO_SSID=`cat answer`
				sed -i '/^URO_SSID/d' $SETUPENV
				echo "URO_SSID=${URO_SSID}" >> $SETUPENV
			fi
			printf "#$PORT_TWO Uronode Definition\n[${STATION_CALL}-${URO_SSID} via ${PORT_TWO} ]\nNOCALL * * * * * * L\nN0CALL * * * * * * L\ndefault * * * * * * 0 root /usr/sbin/uronode uronode\n" >> $AX25D
			content="`cat $AX25D`"
			dialog --backtitle "$BTITLE" --title "Second Uronode Listener Created" --msgbox "$content" 20 70
		else
			sed -i '/^URONODE_REQUIRED/d' $SETUPENV
			echo "URONODE_REQUIRED=0" >> $SETUPENV
		fi
	fi
	
	# a convenience variables for the Net/ROM configuration
	suffix=`echo ${STATION_CALL}|rev|cut -c -4|rev`	
	########################################################################
	# Make the text lines for ax25d.conf to listen for netrom and connect to 
	# Uronode as it's handler.
	########################################################################
	# Create a NET/ROM listener?
	
	dialog --backtitle "$BTITLE" --title "Create a NET/ROM Listener" --yesno "Shall we create a NET/ROM listener?  If you are unsure, answer NO" 6 70
	if [[ "$?" == "0" ]]; then
		NETROM_REQUIRED=1
		sed -i '/^NETROM_REQUIRED/d' $SETUPENV
		echo "NETROM_REQUIRED=1" >> $SETUPENV
		[[ $DEBUG_ON -eq 1 ]] && debug "User chose to create Net/ROM listener <netrom>" $DEBUG_FILE
		dialog --backtitle "$BTITLE" --title "Net/ROM Alias" --inputbox \
		"Input your 6 character or less Net/ROM alias and press <Enter>" 9 60 "${NETROM_ALIAS:-${suffix}ND}" 2>answer
		NETROM_ALIAS=`cat answer| awk '{print toupper($0)}'`
		sed -i '/^NETROM_ALIAS/d' $SETUPENV
		echo "NETROM_ALIAS=${NETROM_ALIAS}" >> $SETUPENV
		[[ $DEBUG_ON -eq 1 ]] && debug "Net/ROM alias=${NETROM_ALIAS}" $DEBUG_FILE
		dialog --backtitle "$BTITLE" --title "Net/ROM SSID" --inputbox \
		"Input the UNIQUE SSID (1-9) to use for Net/ROM and press <Enter>" 9 60 "${NETROM_SSID:-2}" 2>answer
		NETROM_SSID=`cat answer`
		sed -i '/^NETROM_SSID/d' $SETUPENV
		echo "NETROM_SSID=${NETROM_SSID}" >> $SETUPENV
		[[ $DEBUG_ON -eq 1 ]] && debug "Net/ROM SSID=${NETROM_SSID}" $DEBUG_FILE
		printf "# NET/ROM Definition\n<netrom>\nparameters 1    10  *  *  *   *   *\nNOCALL * * * * * * L\nN0CALL * * * * * * L\ndefault * * * * * * 0 root /usr/sbin/uronode uronode\n" >> $AX25D
		dialog --backtitle "$BTITLE" --title "NET/ROM Listener Created" --textbox $AX25D 22 70
		#####################################################################
		# Create the nrports file for the NET/ROM interface to SSID-2
		#####################################################################
		# Create the /etc/hal/work/nrports.hal file from scratch
		printf "# Created by HAL\n#NAME\tCALL\tALIAS\tPACLEN\tDESCR\n" > $NRPORTS
		printf "netrom\t${STATION_CALL}-${NETROM_SSID}\t${NETROM_ALIAS}\t236\tNET/ROM Port\n" >> $NRPORTS
		printf "# Created by HAL\n#axport\tmin_obs\tdef\tworst\tverbose\n" > $NRBROADCAST
		printf "${PORT_ONE}\t5\t203\t141\t\t0\n" >> $NRBROADCAST
		if [[ ${NUM_RADIOS} -gt 1 ]]; then
			printf "${PORT_TWO}\t5\t203\t141\t\t0\n">> $NRBROADCAST
		fi
		#####################################################################
		# Inform the user of how the base Net/ROM configuration has been done
		# and that it is only broadasting local services.
		#####################################################################
		dialog --backtitle "$BTITLE" --title "Notice" --msgbox "The system has \
		been configured for NET/ROM on one or both ports.  The system is set to \
		only broadcast local services on the configured ports.  Changes may be \
		made using the \"Net/ROM\" menu item in configuration script (hal_config.sh)." 8 70
	else 
		NETROM_REQUIRED=0
		sed -i '/^NETROM_REQUIRED/d' $SETUPENV
		echo "NETROM_REQUIRED=0">> $SETUPENV
	fi
else
	[[ $DEBUG_ON -eq 1 ]] && debug "User chose not to configure ax25d." $DEBUG_FILE
	premature_end	
fi # end of AX25D Uronode, Net/ROM
####################################################################
# Prompt the user that we are ready to overwrite the production config files
# with HAL created config files and let them opt out.
dialog --backtitle "$BTITLE" --title "Enable System Configs?" --defaultno --yesno \
"HAL has now completed the creation of all of the configuration files necessary \
to update your system.  It is now time to overwrite the required production \
config files with your new values.  If you choose to continue, answer \"Yes\" \
, otherwise, if you wish to evaluate the config files in the /etc/hal/work \
directory first you may do so, BUT you will have to start this script from the \
beginning if you answer \"No\"." 13 70
if [[ $? -eq 0 ]]; then
	if [[ ${AX25D_REQUIRED} -eq 1 ]]; then
		cp -f $AX25D /etc/ax25/ax25d.conf
	fi
	if [[ ${NETROM_REQUIRED} -eq 1 ]]; then
		cp -f $NRPORTS /etc/ax25/nrports
		cp -f $NRBROADCAST /etc/ax25/nrbroadcast
	fi
	if [[ ${URONODE_REQUIRED} -eq 1 ]]; then
		cp -f $UROCONF /etc/ax25/uronode.conf
	fi
	# finally copy over the setup.env file
	cp -f $SETUPENV /etc/hal/env/setup.env
else 
	[[ $DEBUG_ON -eq 1 ]] && debug "User chose to exit before writing config files." $DEBUG_FILE
	premature_end
fi

#############################################################################
# Tidy up
#############################################################################
[[ -f answer ]] && rm -f answer
rm -f /etc/hal/work/*.hal
[[ $DEBUG_ON -eq 1 ]] && debug "End hal_mkserver.sh configuration script." $DEBUG_FILE
exit 0
