#!/bin/bash
################################################################################
# Script Name : hal_mkserver.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 25 June 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# AX.25 system and a base set of applications.
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
#
# A note about SSID's.  In order to simplify the installation method
# HAL will create defaults for SSID's that user can accept or change.
# It is vital to understand that FBB should use a unique SSID, and each AX.25 
# port should use unique SSID's as well.
#
# The NET/ROM SSID and the Uronode SSIDs may be shared across radio ports 
# given the way HAL is configured.
#
# For more information, please read the AX.25 How-To located at :
# http://tldp.org/HOWTO/AX25-HOWTO/
#
# Defaults are as follows:
# -1 FBB BBS
# -2 NET/ROM listener
# -7 Uronode listener(s)
# -8 First AX.25 radio port (axports)
# -9 Second AX.25 radio port (axports)
#####################################################################
# FUNCTIONS 
source /etc/hal/env/functions.env
# put the sytem back to a reasonable baseline state before proceeding (quietly)
baseline > /dev/null 2>&1
# copy some clean distro files to .hal working files
hal_copy "uronode.conf"
hal_copy "axmail.conf"
hal_copy "welcome.txt"
# Working config files
AXPORTS="/etc/hal/work/axports.hal"
AX25D="/etc/hal/work/ax25d.conf.hal"
NRPORTS="/etc/hal/work/nrports.hal"
NRBROADCAST="/etc/hal/work/nrbroadcast.hal"
UROCONF="/etc/hal/work/uronode.conf.hal"
AXMAIL="/etc/hal/work/axmail.conf.hal"
PORTSYS="/etc/hal/work/port.sys.hal"
FBBCONF="/etc/hal/work/fbb.conf.hal"
ENGLISH_INF="/etc/hal/work/english.inf.hal"
# Environment variable files
STATIONENV="/etc/hal/env/station.env"
SETUPENV="/etc/hal/env/setup.env"
DEBUG_FILE="/var/log/hal_mkserver.debug"
if [[ $1 == "-d" ]]; then
	DEBUG_ON=1
	echo "" > $DEBUG_FILE
else
	DEBUG_ON=0
fi
[[ $DEBUG_ON -eq 1 ]] && debug "Begin hal_mkserver run" $DEBUG_FILE
# Vars to use in dialog calls
BTITLE="HAL Make Server Setup"
####################################################################
# Establish the HAL version in the brand new setup.env file
echo "HAL_VERSION=1" > $SETUPENV
####################################################################
dialog --backtitle "$BTITLE" --title "HAL Make Server" --msgbox \
"Welcome to the HAL First Run script.\n \
Author : Mitch Winkle AB4MW\n \
Script Name : hal_first_run.sh\n \
Version : ALPHA\n \
Created : 2015-06-18\n \
Input Parameters: -d if debug statements required\n\n \
This script will assist you in setting up a Ham Arch Linux (HAL) \
system with a minimum of time and hassle...at least that is the goal." 14 75
dialog --backtitle "$BTITLE" --title "!!! WARNING !!!" --msgbox \
"!! WARNING: THIS SCRIPT OVERWRITES THE PRODUCTION CONFIG FILES !!\n\nThe \
user is warned to make backups if necessary on an already configured system.\n\n \
You will be given the opportunity to exit in two more screens." 11 75
dialog --backtitle "$BTITLE" --title "About AX.25 SSIDs" --msgbox \
"A note about AX.25 SSID's.  It is \
vital to understand that FBB should use a unique SSID, \
and each AX.25 port should use a unique SSID as well.  \
The NET/ROM SSID and the Uronode SSID may be shared across radio ports \
given the way HAL is configured.\n\n For more information, \
please read the AX.25 How-To located at :\n\n \
http://tldp.org/HOWTO/AX25-HOWTO \n\n
SSID defaults are as follows: \n \
 -1 FBB BBS \n \
 -2 NET/ROM listener \n \
 -7 Uronode listener(s) \n \
 -8 First AX.25 radio port \n \
 -9 Second AX.25 radio port" 20 75

dialog --backtitle "$BTITLE" --title "Other Assumptions" --yesno \
"Other assumptions: This script is designed to be run on a Debian based \
build with it's fairly stable file structure as follows: \n\n \
1. AX.25 config files in /etc/ax25 or are symlinked to /etc/ax25 \n \
2. FBB config files are found in /etc/ax25/fbb/... or symlinked \n \
3. All required packages have been installed by the package manager. \n \
4. All other required programs have been compiled and installed. \n \
5. Distribution copies of configuration files have been backed up \
\n\nShall we continue?" 17 75
if [ $? -eq 1 ]; then
	[[ $DEBUG_ON -eq 1 ]] && debug "User exited program before call sign." $DEBUG_FILE
	premature_end
fi
dialog --backtitle "$BTITLE" --title "Getting Started" --msgbox \
"OK, glad you are ready. Defaults are input for you in many of the forms, \
so if you are unsure, just hit <Enter>.  The defaults will likely work just \
fine for you (except for the FBB values).\n\nValid keystrokes for navigation are arrow keys and <Tab>.  \
The select key is <Space Bar> and the <Enter> key sends the selections to \
the program.\n\nYou may edit values in forms to change them.  Simply navigate \
to the field and change its value to whatever you desire.\n\nLet us Begin!" 16 70
STATION_CALL=''
# Station call sign
dialog --backtitle "$BTITLE" --title "Station Call Sign" --no-cancel --inputbox \
"Input your station call sign and press <Ok>" 8 60 "$STATION_CALL" 2>answer
# TODO need logic here to check format of call signs, etc.
STATION_CALL=`cat answer| awk '{print toupper($0)}'`
[[ $DEBUG == "1" ]] && debug "Station Call = ${STATION_CALL}" $DEBUG_FILE
# If empty or wrong format call shenanigans.  Format check is US and most
# typical formats for calls signs, but the user may
# choose to use a call sign outside that format or for a 
# special event station, so they are allowed to keep whatever
# they typed in after a warning and visual review.
#This expression is weak but covers the common USA errors...it's a start.
# ^[AKWN][A-Z]?[0-9][A-Z]{1,3}$
if [[ $STATION_CALL =~ ^[AKWN][A-Z]?[0-9][A-Z]{1,3}$ ]]; then
	:
else
	dialog --backtitle "$BTITLE" --title "Station Call Sign" --yesno \
	"The station call sign ${STATION_CALL} may not be valid.  HAL only checks \
for US style call signs and poorly, so don't fret.  Use this call \
sign anyway?" 7 60
	if [ $? -eq 1 ]; then
		[[ $DEBUG_ON -eq 1 ]] && debug "User exit when testing for valid call sign." $DEBUG_FILE
		premature_end
	fi
fi
echo "STATION_CALL="$STATION_CALL > $STATIONENV
result=`lynx -dump http://levinecentral.com/ham/ab4mw_grid.php?Call=${STATION_CALL}`
read -r GRID_SQUARE alat alon lat lon <<<$result
[[ $DEBUG_ON -eq 1 ]] && debug "Station Values for $STATION_CALL: $GRID_SQUARE $alat $alon $lat $lon" $DEBUG_FILE
echo "GRID_SQUARE=${GRID_SQUARE}" >> $STATIONENV
echo "APRS_LAT=${alat}" >> $STATIONENV
echo "APRS_LON=${alon}" >> $STATIONENV
echo "DEC_LAT=${lat}" >> $STATIONENV
echo "DEC_LON=${lon}" >> $STATIONENV
# Depending on the call length, we adjust our tabs in the output file so it's tidy
CALL_LEN=${#STATION_CALL}
if [ $CALL_LEN == 6 ]; then
	LTABS="\t\t"
	TABS="\t"
else	LTABS="\t"
	TABS=$LTABS
fi
# How many radios?
dialog --title "How Many Radios?" --backtitle "$BTITLE" --menu \
"Select how many radios you will be using." 10 50 3 \
1 'One Radio' \
2 'Two radios' 2>answer
NUM_RADIOS=`cat answer`
[[ $DEBUG_ON -eq 1 ]] && debug "NUM_RADIOS=${NUM_RADIOS}" $DEBUG_FILE
# check for the <Cancel> button which in this widget appears to be
# an empty string.
if [ ${NUM_RADIOS} == '' ]; then
	# the user cancelled, and can still exit the program safely
	[[ $DEBUG_ON -eq 1 ]] && debug "User hit cancel or esc at NUM_RADIOS" $DEBUG_FILE
	premature_end
fi
echo "NUM_RADIOS=${NUM_RADIOS}" >> $SETUPENV
#####################################################################
# Create the first AX.25 radio port
#####################################################################
# open fd
exec 3>&1
 
# Store data to $VALUES variable
VALUES=$(dialog --ok-label "Submit" \
	  --backtitle "$DTITILE" \
	  --title "First Port Creation" \
	  --form "Create the FIRST AX.25 Port.  \
	Use the sensible defaults below, or choose values for yourself. If \
	you will use a TNC-Pi, be sure to set the Serial Port Speed to 19200" 16 60 0 \
	"Port Name:" 			1 1	"vhf" 			1 25 10 0 \
	"Unique Call sign:"		2 1	"${STATION_CALL}-8"  	2 25 15 0 \
	"Serial Port Speed:"    	3 1	"9600"  		3 25 8 0 \
	"Max Packet Length:"    	4 1	"236" 			4 25 40 0 \
	"Max Outstanding Frames:"     	5 1	"4" 			5 25 40 0 \
	"Description:"     		6 1	"vhf port one" 		6 25 40 0 \
2>&1 1>&3)
 
# close fd
exec 3>&-
VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
[[ $DEBUG_ON -eq 1 ]] && debug "Port One Values=${VALUES}" $DEBUG_FILE
read PORT_ONE PORT_ONE_CALL PORT_ONE_SPEED PORT_ONE_PACLEN PORT_ONE_WINDOW PORT_ONE_DESCR <<<$VALUES
#####################################################################
# Confirm first port created and notify that we will create second 
# port if needed.
#####################################################################
if [ $NUM_RADIOS -lt 2 ]; then
	dialog --backtitle "$BTITLE" --title "Port One Created" \
	--msgbox 'OK, Port One has been created.' 6 70 ;
else 
	dialog --backtitle "$BTITLE" --title "Port One Created" \
	--msgbox 'OK, Port One has been created.  We will now create Port Two' 6 70 ;
fi
########################################################################
# If the user indicated a second radio, collect that information also
########################################################################
if [ $NUM_RADIOS -eq 2 ]; then 
	echo "PORT_TWO_REQUIRED=1" >> $STATIONENV
	# open fd
	exec 3>&1
	 
	# Store data to $VALUES variable
	VALUES=$(dialog --ok-label "Submit" \
		  --backtitle "$BTITLE" \
		  --title "Second Port Creation" \
		  --form "Create a SECOND AX.25 Port.  \
		Use the sensible defaults below, or choose values for yourself." \
	15 60 0 \
		"Port Name:" 			1 1	"uhf" 			1 25 10 0 \
		"Unique Call sign:"    		2 1	"${STATION_CALL}-9"  	2 25 15 0 \
		"Serial Port Speed:"    	3 1	"9600"		  	3 25 8 0 \
		"Max Packet Length:"     	4 1	"236"		 	4 25 40 0 \
		"Max Outstanding Frames:"     	5 1	"4"		 	5 25 40 0 \
		"Description:"     		6 1	"uhf port two"	 	6 25 40 0 \
	2>&1 1>&3)
	 
	# close fd
	exec 3>&-
	# gather values
	VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
	read PORT_TWO PORT_TWO_CALL PORT_TWO_SPEED PORT_TWO_PACLEN \
	PORT_TWO_WINDOW PORT_TWO_DESCR <<<$VALUES
	[[ $DEBUG_ON -eq 1 ]] && debug "Port Two Values=${VALUES}" $DEBUG_FILE
fi
#####################################################################
# Write the /etc/hal/work/axports.hal file
# First, depending on the call length, we adjust our tabs in the 
# output file so it's tidy.
#####################################################################
CALL_LEN=${#STATION_CALL}
if [ $CALL_LEN -lt 6 ]; then
	LTABS="\t\t"
fi
# write the axports data to the HAL staging file
printf "#NAME\tCALLSIGN\tSPEED\tPACLEN\tWINDOW\tDESCRIPTION\n" > $AXPORTS
printf "$PORT_ONE\t$PORT_ONE_CALL${LTABS}$PORT_ONE_SPEED\t$PORT_ONE_PACLEN\t$PORT_ONE_WINDOW\t$PORT_ONE_DESCR\n" >> $AXPORTS
if [ $NUM_RADIOS == 2 ]; then
	printf "$PORT_TWO\t$PORT_TWO_CALL${LTABS}$PORT_TWO_SPEED\t$PORT_TWO_PACLEN\t$PORT_TWO_WINDOW\t$PORT_TWO_DESCR\n" >> $AXPORTS
fi

dialog --backtitle "$BTITLE" --title "Notice" --msgbox \
"The /etc/hal/work/axports.hal file has been created.  It is displayed on \
the next screen.  Please check for accuracy and if it is not as you \
desire, re-run this program to start over.\n\nShall we continue?" 11 70
dialog --backtitle "$BTITLE" --title "Contents of axports.hal" --exit-label "Continue" --textbox "/etc/hal/work/axports.hal" 7 70
#####################################################################
# Write the values to the setup.env file NOTE: The original write to 
# this file was above where the NUM_RADIOS value was recorded and 
# this cleared the contents of the file. Subsequent writes are of 
# course appends.
#####################################################################
printf "# Created by HAL\n#PORT_ONE\nPORT_ONE=${PORT_ONE}\n" >> $SETUPENV
echo "PORT_ONE_CALL=$PORT_ONE_CALL" >> $SETUPENV
echo "PORT_ONE_SPEED=$PORT_ONE_SPEED" >> $SETUPENV
echo "PORT_ONE_PACLEN=$PORT_ONE_PACLEN" >> $SETUPENV
echo "PORT_ONE_WINDOW=$PORT_ONE_WINDOW" >> $SETUPENV
echo "PORT_ONE_DESCR='$PORT_ONE_DESCR'" >> $SETUPENV
echo "BEACON1_REQUIRED=1" >> $SETUPENV
echo "MHEARDD_REQUIRED=1" >> $SETUPENV
if [ $NUM_RADIOS -eq 2 ]; then
	echo "PORT_TWO=${PORT_TWO}" >> $SETUPENV
	echo "PORT_TWO_CALL=$PORT_TWO_CALL" >> $SETUPENV
	echo "PORT_TWO_SPEED=$PORT_TWO_SPEED" >> $SETUPENV
	echo "PORT_TWO_PACLEN=$PORT_TWO_PACLEN" >> $SETUPENV
	echo "PORT_TWO_WINDOW=$PORT_TWO_WINDOW" >> $SETUPENV
	echo "PORT_TWO_DESCR='$PORT_TWO_DESCR'" >> $SETUPENV
	echo "BEACON2_REQUIRED=1" >> $SETUPENV
fi
#####################################################################
# Interrogate for creation of the ax25d.conf file.
#####################################################################
# Make the text lines for ax25d.conf to listen on -7 and connect to 
# Uronode.  Same for Net/ROM at the users choice.
#####################################################################
AX25D_REQUIRED=0
URONODE_REQUIRED=0
AXMAIL_REQUIRED=0
dialog --backtitle "$BTITLE" --title "Getting Started" --yesno \
"Next is the configuration of optional Uronode listeners.  Uronode \
creates a \"landing spot\" for incoming AX.25 and Net/ROM connections \
so users my make use of a wide array of applications.  If you only \
intend to use this sytem as an APRS digi or iGate, etc., you \
probably don't need Uronode and Net/ROM.  If that is the case \
simply answer \"No\" here.\n\n Shall we continue with Uronode and \
Net/ROM configuration?" 13 70 
if [ "$?" == "0" ]; then
	AX25D_REQUIRED=1
	echo "# Created by HAL" > $AX25D
	# Create a Uronode listener for the first port?
	dialog --backtitle "$BTITLE" --title \
	"Create a Uronode Listener" --yesno "Shall we create a listener for Uronode on port one?" 6 70
	if [ "$?" == "0" ]; then
		[[ $DEBUG_ON -eq 1 ]] && debug "User chose Uronode port one" $DEBUG_FILE
		URONODE_REQUIRED=1
		dialog --backtitle "$BTITLE" --title "Select Uronode SSID" --inputbox \
		"Input the SSID to use with Uronode and press <Enter>" 6 60 "7" 2>answer
		URO_SSID=`cat answer`
		echo "URO_SSID=${URO_SSID}" >> $SETUPENV
		dialog --backtitle "$BTITLE" --title "Set Uronode LocalNet block" --inputbox \
		"Input the ampr.org (44.x.x.x/nn) local network block and press <Enter>\n\n \
		If you do NOT know what this means, leave the field blank." 12 60 "" 2>answer
		URO_LOCALNET=`cat answer`
		echo "URO_LOCALNET=${URO_LOCALNET}" >> $SETUPENV
		printf "#$PORT_ONE Uronode Definition\n[${STATION_CALL}-${URO_SSID} via ${PORT_ONE} ]\nNOCALL * * * * * * L\nN0CALL * * * * * * L\ndefault * * * * * * 0 root /usr/sbin/uronode uronode\n" >> $AX25D
		content="`cat $AX25D`"
		dialog --backtitle "$BTITLE" --title "Contents of ax25d.conf.hal" --exit-label "Continue" --textbox "/etc/hal/work/ax25d.conf.hal" 12 70
	fi	
	# Offer to create the same for the second port
	if [ $NUM_RADIOS == 2 ]; then
		dialog --backtitle "$BTITLE" --title \
		"Create Uronode Listener?" \
		--yesno "Shall we create a listener for Uronode on port two?" 12 70
		if [ "$?" == "0" ]; then	
			[[ $DEBUG_ON -eq 1 ]] && debug "User chose Uronode port two" $DEBUG_FILE
			URONODE_REQUIRED=1
			if [[ $URO_SSID == "" ]]; then
				dialog --backtitle "$BTITLE" --title "Select Uronode SSID" --inputbox \
			"Input the SSID to use with Uronode and press <Enter>" 5 60 "${URO_SSID:-7}" 2>answer
				URO_SSID=`cat answer`
				echo "URO_SSID=${URO_SSID}" >> $SETUPENV
			fi
			if [[ $URO_LOCALNET == "" ]]; then
				dialog --backtitle "$BTITLE" --title "Set Uronode LocalNet block" --inputbox \
				"Input the ampr.org (44.x.x.x/nn) local network block and press <Enter>\n\n \
				If you do NOT know what this means, leave the field blank." 12 60 "" 2>answer
				URO_LOCALNET=`cat answer`
				if [[ $URO_LOCALNET == "" ]]; then
					echo "URO_LOCALNET=44.128.0.1/32" >> $SETUPENV
				else					
					echo "URO_LOCALNET=${URO_LOCALNET}" >> $SETUPENV
				fi
			fi
			printf "#$PORT_TWO Uronode Definition\n[${STATION_CALL}-${URO_SSID} via ${PORT_TWO} ]\nNOCALL * * * * * * L\nN0CALL * * * * * * L\ndefault * * * * * * 0 root /usr/sbin/uronode uronode\n" >> $AX25D
			content="`cat $AX25D`"
			dialog --backtitle "$BTITLE" --title "Contents of ax25d.conf.hal" --exit-label "Continue" --textbox "/etc/hal/work/ax25d.conf.hal" 21 70
		fi
	fi
	
	# some convenience variables for the Uronode and Net/ROM configurations
	lcall=`echo ${STATION_CALL}| awk '{print tolower($0)}'`
	suffix=`echo ${STATION_CALL}|rev|cut -c -4|rev`	
	#####################################################################
	# Make the text lines for ax25d.conf to listen on -2 and connect to 
	# Uronode as a NET/ROM connection.
	#####################################################################
	# Create a NET/ROM listener?
	
	dialog --backtitle "$BTITLE" --title "Create a NET/ROM Listener" --yesno "Shall we create a NET/ROM listener?  If you are unsure, answer NO" 6 70
	if [ "$?" == "0" ]; then
		NETROM_REQUIRED=1
		echo "NETROM_REQUIRED=1" >> $SETUPENV
		[[ $DEBUG_ON -eq 1 ]] && debug "User chose to create Net/ROM listener <netrom>" $DEBUG_FILE
		dialog --backtitle "$BTITLE" --title "Net/ROM Alias" --inputbox \
		"Input your 6 character or less Net/ROM alias and press <Enter>" 9 60 "${suffix}ND" 2>answer
		NETROM_ALIAS=`cat answer| awk '{print toupper($0)}'`
		echo "NETROM_ALIAS=$NETROM_ALIAS" >> $SETUPENV
		[[ $DEBUG_ON -eq 1 ]] && debug "Net/ROM alias=${NETROM_ALIAS}" $DEBUG_FILE
		dialog --backtitle "$BTITLE" --title "Net/ROM SSID" --inputbox \
		"Input the UNIQUE SSID to use for Net/ROM and press <Enter>" 9 60 "2" 2>answer
		NETROM_SSID=`cat answer|awk '{print toupper($0)}'`
		echo "NETROM_SSID=${NETROM_SSID}" >> $SETUPENV
		[[ $DEBUG_ON -eq 1 ]] && debug "Net/ROM SSID=${NETROM_SSID}" $DEBUG_FILE
		printf "# NET/ROM Definition\n<netrom>\nparameters 1    10  *  *  *   *   *\nNOCALL * * * * * * L\nN0CALL * * * * * * L\ndefault * * * * * * 0 root /usr/sbin/uronode uronode\n" >> $AX25D
		content="`cat $AX25D`"
		dialog --backtitle "$BTITLE" --title "NET/ROM Listener Created" --textbox $AX25D 22 70
		#####################################################################
		# Create the nrports file for the NET/ROM interface to SSID-2
		#####################################################################
		# Create the /etc/hal/work/nrports.hal file from scratch
		printf "# Created by HAL\n#NAME\tCALL\tALIAS\tPACLEN\tDESCR\n" > $NRPORTS
		printf "netrom\t${STATION_CALL}-${NETROM_SSID}\t${NETROM_ALIAS}\t236\tNET/ROM Port\n" >> $NRPORTS
		printf "# Created by HAL\n#axport\tmin_obs\tdef\tworst\tverbose\n" > $NRBROADCAST
		printf "${PORT_ONE}\t5\t203\t141\t\t0\n" >> $NRBROADCAST
		if [ ${NUM_RADIOS} -gt 1 ]; then
			printf "${PORT_TWO}\t1\t203\t141\t\t0\n">> $NRBROADCAST
		fi
		#####################################################################
		# Inform the user of how the base Net/ROM configuration has been done
		# and that it is only broadasting local services.
		#####################################################################
		dialog --backtitle "$BTITLE" --title "Notice" --exit-label "Continue" --msgbox "The system has \
		been configured for NET/ROM on one or both ports.  The system is set to \
		only broadcast local services on the configured ports.  Changes may be \
		made using the configuration program, hal_config.sh." 8 70
	else 
		NETROM_REQUIRED=0
		echo "NETROM_REQUIRED=0">> $SETUPENV
	fi
	#####################################################################
	# Uronode setup
	#####################################################################
	# Find and replace distro values with new values.
	sed -i "s/xx#xx.ampr.org/${HOSTNAME}/g" $UROCONF
	sed -i "s/your@email.ampr.org/${lcall}@${HOSTNAME}/g" $UROCONF
	sed -i "s/44.0.0.0\/32/${URO_LOCALNET:-44.128.0.1\/32}/g" $UROCONF
	sed -i "s/XXXXXX:XX#XX-#/${NETROM_ALIAS}:${STATION_CALL}-${NETROM_SSID}/g" $UROCONF
	sed -i "s/XX#XX-#@####,######/none/g" $UROCONF
	sed -i "s/XX#XX-#/${STATION_CALL}-${URO_SSID}/g" $UROCONF
	sed -i "s/nr0/netrom/g" $UROCONF
	#sed -i 's/^LogLevel[ \t]*3$/LogLevel	0/' $UROCONF
	echo "Uronode system at ARS ${STATION_CALL}" > /etc/hal/work/uronode.info.hal
	dialog --backtitle "$BTITLE" --title "Enable AxMail?" --yesno \
	"Do you wish to install AxMailFax?  This is a companion program to \
	Uronode which allows your users to create a mailbox on your Linux \
	machine and send and retrieve regular emails to one another \
	via Uronode." 8 70 
	if [ "$?" -eq 0 ]; then
		#####################################################################
		# axmail configuration
		#ExtCmd          MAil    1       root    /usr/sbin/axmail axmail %u
		#
		# Simply update /etc/hal/work/axmail.conf with the correct contact email
		# and add the ExtCmd line to uronode.conf to launch axMail from the
		# Uronode prompt.
		#####################################################################
		AXMAIL_REQUIRED=1
		sed -i "s/<your>.ampr.org/${HOSTNAME}/g" $AXMAIL
		sed -i "s/root/${lcall}@${HOSTNAME}/g" /etc/hal/work/welcome.txt.hal
		# if the uronode.conf file does NOT already contain an
		# ExtCmd line for axmail, then add one
		if [ `grep -c "axmail axmail" $UROCONF` -eq 0 ]; then
			echo "ExtCmd          MAil    1       root    /usr/sbin/axmail axmail %u" >> $UROCONF
		fi
	fi
	# If more than one radio, check if the user wants AXDIGI
	AXDIGI_REQUIRED=0
	if [[ $NUM_RADIOS -eq 2 ]]; then
		# Query if AXDIGI_REQUIRED for ax25-up/ax25-down
		dialog --backtitle "$BTITLE" --title "Enable Axdigi?" --yesno \
		"Do you wish to enable the axdigi program?  This is a companion program to \
Uronode which allows your users to cross-port digipeat \
using the AX.25 port's callsign-SSID." 7 70
		if [ $? -eq 0 ]; then
			# setting this env var will enable the axdigi program
			# when ax25-up runs during init
			AXDIGI_REQUIRED=1
		fi
	fi
fi # end of AX25D Uronode, Net/ROM, AxMail setup section
####################################################################
# write the environment vars that detail what services must be
# started/stopped in the ax25-up/ax25-down scripts
echo "AX25D_REQUIRED=${AX25D_REQUIRED}" >> $SETUPENV
echo "URONODE_REQUIRED=${URONODE_REQUIRED}" >> $SETUPENV
echo "AXDIGI_REQUIRED=${AXDIGI_REQUIRED}" >> $SETUPENV
echo "AXMAIL_REQUIRED=${AXMAIL_REQUIRED}" >> $SETUPENV
#####################################################################
# The HAL configuration assumes Direwolf sound modems will be used
# on all radio ports and that each radio will be defined as one TNC.
# This means a single port TNC on each configured "serial" port and 
# no telnet port defined in FBB.  Changeable in hal_config.sh. The
# local user should use the FBB console program for SYSOP duties.
# /usr/local/sbin/xfbbC -r -c -i AB4MW -w super-secret_sysop_pwd
# An alias called "fbbc" is created to do this for the root user.
# The sysop password is set in passwd.sys and a port.sys file is
# created from scratch using sensible defaults. Image uses -1 as the 
# FBB SSID by default.  User may change using hal_config.sh script.
#####################################################################
#####################################################################
FBB_REQUIRED=0
dialog --backtitle "$BTITLE" --title "Enable FBB BBS?" --yesno \
"Do you wish to configure the FBB BBS software?  You may install \
it and configure it later via hal_config.sh. FBB may run standalone \
without AX25D services such as Uronode, Net/ROM and AxMail. You will \
be asked a number of station related questions in order to finish the \
FBB configuration for your system." 10 70 
if [ "$?" -eq 0 ]; then
	FBB_REQUIRED=1
	echo "FBB_REQUIRED=1" >> $SETUPENV
	dialog --backtitle "$BTITLE" --title "FBB SYSOP Password" --inputbox \
	"Input an FBB SYSOP password and press <Enter>" 5 60 "somEthingsecrEt" 2>answer
	SYSOP_PWD=`cat answer`
	echo "${SYSOP_PWD}">/etc/hal/work/passwd.sys.hal
	#####################################################################
	# Now a few minor edits of english.inf and fbb.conf with
	# station information.
	#####################################################################
	# Query the information needed by FBB for the fbb.conf file and 
	# also customize english.inf to sensible defaults.
	#####################################################################
	# open fd
	exec 3>&1
	dialog --backtitle "$BTITLE" --title "Time to Configure FBB" --exit-label "Continue" --msgbox \
	"OK, the base FBB setup is complete, but some of the configuration values are missing.\n\nHAL will now \
	ask you for these values.\n\nTo enter your hierarchical route, you will need to use \
	at a miniumum, your 2 letter state, \"USA\" and \"NOAM\" in the United States.\n\n \
	Example : AB4MW is in the Richmond, VA area so I use,\n\n#RICH.VA.USA.NOAM OR VA.USA.NOAM. \
	" 20 70 

	# Store data to $VALUES variable
	VALUES=$(dialog --ok-label "Submit" \
		  --backtitle "$BTITLE" \
		  --title "FBB Customization" \
		  --form "FBB User and Station Information. Please enter correct data for ALL values.  \
		  Each field contains except City Name contains ONE WORLD ONLY with no spaces allowed." 15 60 0 \
		"SSID for FBB must be UNIQUE"   1 1	"1"			1 30 4 0 \
		"Hierarchical Route:" 		2 1	"#REGN.ST.USA.NOAM"	2 30 17 0 \
		"Grid Square:"			3 1	"${GRID_SQUARE}"  	3 30 6 0 \
		"Sysop First Name (ONE WORD):"	4 1	"MYNAME" 		4 30 15 0 \
		"Sysop Call Sign:" 	    	5 1	"${STATION_CALL}" 	5 30 8 0 \
		"Time Diff to UTC:"    		6 1	"-5" 			6 30 20 0 \
		"City Name :"    		7 1	"MYCITY, ST USA"  		7 30 18 0 \
	2>&1 1>&3)

	# close fd
	exec 3>&-

	# gather values just entered
	VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
	read FBB_SSID HIER_ROUTE QRALOC MYNAME FBB_SYSOP UTC_DIFF MYCITY <<<$VALUES
	# Write the values to the environment file for the station
	printf "FBB_SSID=${FBB_SSID}\nHIER_ROUTE=${HIER_ROUTE}\nQRALOC=${QRALOC}\nMYCITY='${MYCITY}'\nMYNAME=${MYNAME}\nFBB_SYSOP=${FBB_SYSOP}\nUTC_DIFF=${UTC_DIFF}\n" >> $STATIONENV
	# Now create the port.sys file from scratch.	
	printf "# Created by HAL\n# port.sys\n#Ports TNCs\n${NUM_RADIOS}\t" > $PORTSYS
	if [[ $NETROM_REQUIRED -eq 1 ]]; then
		tnccount=${NUM_RADIOS}
		let "tnccount += 1"
		printf "${tnccount}\n#Com\tInterface\tAddress\t\tBaud\n" >> $PORTSYS
	else 
		printf "${NUM_RADIOS}\n#Com\tInterface\tAddress\t\tBaud\n" >> $PORTSYS
	fi
	portnum=1
	printf "${portnum}\t9\t\t0\t\t${PORT_ONE_SPEED}\n" >> $PORTSYS	
	portnum=2
	if [ $portnum -le $NUM_RADIOS ]; then
		printf "${portnum}\t9\t\t0\t\t${PORT_TWO_SPEED}\n" >> $PORTSYS
	fi
	# print the header line and file fwd line
	echo "#TNC NbCh Com MultCh Pacln Maxfr NbFwd MxBloc M/P-Fwd Mode  Freq" >> $PORTSYS
	echo "0   0    0   0      0     0     0     0      00/01   ----   File-fwd." >> $PORTSYS
	# print the one or two TNC lines
	# port.sys only allows 8 character descriptions so trim it
	descr=`echo $PORT_ONE_DESCR|cut -c -8`
	echo "1   8    1   ${PORT_ONE}    236   4     1    10      10/30   UXYW   ${descr}" >> $PORTSYS
	portnum=2
	if [ $portnum -eq $NUM_RADIOS ]; then
		descr=`echo $PORT_TWO_DESCR|cut -c -8`
		echo "2   8    2  ${PORT_TWO}   236   4     1    10      10/30   UXYW   ${descr}" >> $PORTSYS
		portnum=3
	fi
	if [[ $NETROM_REQUIRED -eq 1 ]]; then
		FBB_ALIAS=`echo $NETROM_ALIAS|rev|cut -c 3-|rev`
		FBB_ALIAS="${FBB_ALIAS}BB"
		dialog --backtitle "$BTITLE" --title "FBB Net/ROM Alias" --inputbox \
	"Input a Net/ROM alias for your FBB BBS.  Six (6) characters or less, and press <Enter>" 7 70 \
	"$FBB_ALIAS" 2>answer
		FBB_ALIAS=`cat answer|awk '{print toupper ($0)}'`
		echo "FBB_ALIAS=${FBB_ALIAS}" >> $SETUPENV
		echo "$portnum   8    2  netbbs   236   4     1    10      00/60   UXYW   netbbs" >> $PORTSYS
		# also add a new nrport named netbbs to the nrports file to create
		# the linkage between AX.25 stack and FBB
		printf "netbbs\t${STATION_CALL}-${FBB_SSID}\t\t${FBB_ALIAS}\t236\tFBB BBS\n" >> $NRPORTS
		# now fix uronode.conf
		echo "Alias		BBS	\"connect ${FBB_ALIAS} s\"" >> $UROCONF
	fi
	#####################################################################
	# The fbb.conf file is a manually tooled version created by HAL for
	# this use specifically. If it has been changed, chaos will ensue.
	#####################################################################
	hal_copy "fbb.conf"
	sed -i "s/ssid = 1/ssid = $FBB_SSID/g" $FBBCONF
	sed -i "s/MYCALL.#REGN.ST.USA.NOAM/${STATION_CALL}.${HIER_ROUTE}/g" $FBBCONF
	sed -i	"s/MYGRID/${QRALOC}/g" $FBBCONF
	sed -i	"s/MYCITY/${MYCITY}/g" $FBBCONF
	sed -i	"s/MYNAME/${MYNAME}/g" $FBBCONF
	sed -i	"s/MYSYSOP/${FBB_SYSOP}/g" $FBBCONF
	sed -i	"s/MYUTC/${UTC_DIFF}/g" $FBBCONF
	#####################################################################
	# Create english.inf to print relevant station information for "I"
	# command in FBB
	printf "BBS ${STATION_CALL} - \$\?\nUSER:\n\$%%\n" > $ENGLISH_INF
else
	FBB_REQUIRED=0
	echo "FBB_REQUIRED=0" >> $SETUPENV
fi
# Prompt the user that we are ready to overwrite the production config files
# with HAL created config files and let them opt out.
dialog --backtitle "$BTITLE" --title "Enable System Configs?" --defaultno --yesno \
"HAL has now completed the creation of all of the configuration files necessary \
to create your system.  It is now time to overwrite the required production \
config files with your new values.  If you choose to continue, answer \"Yes\" \
, otherwise, if you wish to evaluate the config files in the /etc/hal/work \
directory first you may do so, BUT you will have to start this script from the \
beginning if you answer \"No\"." 13 70
if [[ $? -eq 0 ]]; then
	cp -f $AXPORTS /etc/ax25/axports
	if [ ${AX25D_REQUIRED} -eq 1 ]; then
		cp -f $AX25D /etc/ax25/ax25d.conf
	fi
	if [[ ${NETROM_REQUIRED} -eq 1 ]]; then
		cp -f $NRPORTS /etc/ax25/nrports
		cp -f $NRBROADCAST /etc/ax25/nrbroadcast
	fi
	if [ ${URONODE_REQUIRED} -eq 1 ]; then
		cp -f $UROCONF /etc/ax25/uronode.conf
		cp -f /etc/hal/work/uronode.info.hal /etc/ax25/uronode.info
		cp -f /etc/hal/template/uronode.motd.hal /etc/ax25/uronode.motd
		cp -f /etc/hal/template/uronode.perms.hal /etc/ax25/uronode.perms
		cp -f /etc/hal/template/uronode.routes.hal /etc/ax25/uronode.routes
		cp -f /etc/hal/template/uronode.users.hal /etc/ax25/uronode.users
	fi
	if [ ${AXMAIL_REQUIRED} -eq 1 ]; then
		cp -f $AXMAIL /etc/ax25/axmail.conf
	fi
	if [[ ${FBB_REQUIRED} -eq  1 ]]; then
		cp -f $PORTSYS /etc/ax25/fbb/port.sys
		cp -f /etc/hal/work/passwd.sys.hal /etc/ax25/fbb/passwd.sys
		cp -f $FBBCONF /etc/ax25/fbb/fbb.conf
		cp -f $ENGLISH_INF /etc/ax25/fbb/lang/english.inf
		dialog --backtitle "$BTITLE" --title "Enable FBB BBS Alias?" --defaultno --yesno \
"Do you wish to configure a Bash (shell) alias called \"fbbc\" that will \
allow you quick access to the FBB SYSOP console?  What this means is that \
the Sysop password you just created will be found in /root/.bashrc in plain \
text.  Any user who has sudo or root access to this computer will be able to \
see the FBB Sysop password if they know where to look.  If you are the only \
person who logs into this computer this may be acceptable to you.\n\nIf you are \
unsure, please just answer \"No\"." 13 70
		if [ $? -eq 0 ]; then
			# Adds an alias to the root user's .bashrc file to start the FBB
			# console program as a SYSOP (delete old alias if already defined)
			sed -i -r '/^alias fbbc/d' /root/.bashrc
			echo "alias fbbc='/usr/sbin/xfbbC -r -c -i ${STATION_CALL} -w ${SYSOP_PWD}'" >> /root/.bashrc
		fi
	fi
else 
	[[ $DEBUG_ON -eq 1 ]] && debug "User chose to exit before writing config files." $DEBUG_FILE
	premature_end
fi
#############################################################################
# Now configure the modem or modems and create symlinks to the USB devices
# if USB KISS TNC(s)
dialog --backtitle "$BTITLE" --title "TNC Configuration Per Radio Port" \
--menu "Select which TNC type you will be attaching to Radio One - $PORT_ONE. \
\n\nNOTE: If you choose Direwolf, your sound card must be available. \
If you choose a USB KISS TNC it must be available in order to complete this \
configuration.  If you choose TNC-Pi it must be installed and configured." 15 70 3 \
0 'Direwolf Sound Modem' \
1 'USB attached KISS Modem (TNC-X or MFJ-1270X, etc.)' \
2 'TNC-Pi on /dev/ttyAMA0 Serial Port' 2>answer
PORT_ONE_TYPE=`cat answer`
case $PORT_ONE_TYPE in 
	0) 	/usr/local/bin/direwolf_config.sh 1
		;;
	1) 	/usr/local/bin/kissusb_config.sh 1
		;;
	2) 	/usr/local/bin/tncpi_config.sh 1
		;;
esac
[[ $DEBUG_ON -eq 1 ]] && debug "User chose to set up a TNC type of $PORT_ONE_TYPE for port one." $DEBUG_FILE
# just in case....
[[ -f answer ]] && rm -f answer
if [[ $NUM_RADIOS -eq 2 ]]; then
	dialog --backtitle "$BTITLE" --title "TNC Configuration Per Radio Port" \
	--menu "Select which TNC type you will be attaching to Radio Two - $PORT_TWO \
	\n\nNOTE: If you choose a USB KISS TNC it must be available in order to complete this \
	configuration.  If you choose Direwolf, your sound card must be available." 15 70 3 \
	0 'Direwolf Sound Modem' \
	1 'USB attached KISS Modem (TNC-X or MFJ-1270X, etc.)' \
	2 'TNC-Pi on /dev/ttyAMA0 Serial Port' 2>answer
	PORT_TWO_TYPE=`cat answer`
	case $PORT_TWO_TYPE in 
		0) 	/usr/local/bin/direwolf_config.sh 2
			;;
		1) 	/usr/local/bin/kissusb_config.sh 2
			;;
		2) 	/usr/local/bin/tncpi_config.sh 2
			;;
	esac
	[[ $DEBUG_ON -eq 1 ]] && debug "User chose to set up a TNC type of $PORT_ONE_TYPE for port one." $DEBUG_FILE	
fi
#############################################################################
# Tidy up
#############################################################################
[[ -f answer ]] && rm -f answer
[[ $DEBUG_ON -eq 1 ]] && debug "End hal_mkserver.sh configuration script." $DEBUG_FILE
exit 0
