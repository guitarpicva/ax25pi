#!/bin/bash
################################################################################
# Script Name : hal_ax25.sh 
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 25 June 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# AX.25 ports.
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
# FUNCTIONS 
source /etc/hal/env/functions.env
# Working config files
hal_copy "axports"
AXPORTS="/etc/hal/work/axports.hal"
# Environment variable files
cp -f /etc/hal/env/setup.env /etc/hal/work/setup.env.hal
cp -f /etc/hal/env/station.env /etc/hal/work/station.env.hal
STATIONENV=/etc/hal/work/station.env.hal
SETUPENV=/etc/hal/work/setup.env.hal
DEBUG_FILE="/var/log/hal_ax25.debug"
if [[ $1 == "-d" ]]; then
	DEBUG_ON=1
	echo "" > $DEBUG_FILE
else
	DEBUG_ON=0
fi
[[ $DEBUG_ON -eq 1 ]] && debug "Begin hal_mkclient.sh run" $DEBUG_FILE
# Vars to use in dialog calls
BTITLE="HAL End User Client Setup"
####################################################################
dialog --backtitle "$BTITLE" --title "HAL A.25 Port Configuration" --msgbox \
"Welcome to the HAL AX.25 Config Script.\n \
Author : Mitch Winkle AB4MW\n \
Script Name : hal_ax25.sh\n \
Version : ALPHA A2\n \
Created : 25 June 2015\n \
Input Parameters: -d if debug statements required\n\n \
This script will assist you in setting up the Ham Arch Linux (HAL) \
AX.25 ports with a minimum of time and hassle...at least that is the goal." 14 75
dialog --backtitle "$BTITLE" --title "!!! WARNING !!!" --yesno \
"!! WARNING: THIS SCRIPT OVERWRITES THE PRODUCTION CONFIG FILES !!\n\nThe \
user is warned to make backups if necessary on an already configured system.\n\n \
Shall we continue?." 11 75
if [ $? -eq 1 ]; then
	[[ $DEBUG_ON -eq 1 ]] && debug "User exited program before call sign." $DEBUG_FILE
	premature_end
fi
dialog --backtitle "$BTITLE" --title "Getting Started" --msgbox \
"OK, glad you are ready. Defaults are loaded for you in the form. \
\n\nValid keystrokes for navigation are arrow keys and <Tab>.  \
The select key is <Space Bar> and the <Enter> key sends the selections to \
the program.\n\nYou may edit values in forms to change them.  Simply navigate \
to the field and change its value to whatever you desire.\n\nLet us Begin!" 16 70
source /etc/hal/env/station.env
source /etc/hal/env/setup.env
# point the vars to working copies
# Station call sign
dialog --backtitle "$BTITLE" --title "Station Call Sign" --inputbox \
"Input your station call sign and press <Enter>" 8 60 "${STATION_CALL}" 2>answer
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
# remove old value and replace with new value
sed -i -r '/^STATION_CALL/d' $STATIONENV
echo "STATION_CALL=${STATION_CALL}" >> $STATIONENV
# Show the results to the user just in case something is horribly wrong!
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
	Current values are displayed below, so change values if needed. If \
	you will use a TNC-Pi, be sure to set the Serial Port Speed to 19200" 16 60 0 \
	"Port Name:" 			1 1	"${PORT_ONE}" 			1 25 10 0 \
	"Unique Call sign:"		2 1	"${PORT_ONE_CALL}"  	2 25 15 0 \
	"Serial Port Speed:"    	3 1	"${PORT_ONE_SPEED}"  		3 25 8 0 \
	"Max Packet Length:"    	4 1	"${PORT_ONE_PACLEN}" 			4 25 40 0 \
	"Max Outstanding Frames:"     	5 1	"${PORT_ONE_WINDOW}" 			5 25 40 0 \
	"Description:"     		6 1	"${PORT_ONE_DESCR}" 		6 25 40 0 \
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
	# open fd
	exec 3>&1
	 
	# Store data to $VALUES variable
	VALUES=$(dialog --ok-label "Submit" \
		  --backtitle "$BTITLE" \
		  --title "Second Port Creation" \
		  --form "Create a SECOND AX.25 Port. Use the sensible defaults below, or choose values for yourself.\n\n" \
	15 60 0 \
		"Port Name:" 			1 1	"${PORT_TWO}" 			1 25 10 0 \
		"Unique Call sign:"    		2 1	"${PORT_TWO_CALL}"  	2 25 15 0 \
		"Serial Port Speed:"    	3 1	"${PORT_TWO_SPEED}"		  	3 25 8 0 \
		"Max Packet Length:"     	4 1	"${PORT_TWO_PACLEN}"		 	4 25 40 0 \
		"Max Outstanding Frames:"     	5 1	"${PORT_TWO_WINDOW}"		 	5 25 40 0 \
		"Description:"     		6 1	"${PORT_TWO_DESCR}"	 	6 25 40 0 \
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

dialog --backtitle "$BTITLE" --title "Notice" --yesno \
"The /etc/hal/work/axports.hal file has been created.  It is displayed on \
the next screen.  Please check for accuracy and if it is not as you \
desire, re-run this program to start over.\n\nShall we continue?" 11 70
if [[ $? -gt 0 ]]; then
	[[ $DEBUG_ON -eq 1 ]] && debug "User chose to exit." $DEBUG_FILE
fi
content=`cat $AXPORTS`
dialog --backtitle "$BTITLE" --title "Contents of axports.hal" \
--no-collapse --msgbox "$content" 7 70
#####################################################################
# Prompt the user that we are ready to overwrite the production config files
# with HAL created config files and let them opt out.
if [[ $? -eq 0 ]]; then
	# deleting existing values with sed first
	sed -i -r '/^PORT_ONE=/d' $SETUPENV
	sed -i -r '/^PORT_ONE_CALL/d' $SETUPENV
	sed -i -r '/^PORT_ONE_SPEED/d' $SETUPENV
	sed -i -r '/^PORT_ONE_PACLEN/d' $SETUPENV
	sed -i -r '/^PORT_ONE_WINDOW/d' $SETUPENV
	sed -i -r '/^PORT_ONE_DESCR/d' $SETUPENV
	# write new values
	echo "PORT_ONE=${PORT_ONE}" >> $SETUPENV
	echo "PORT_ONE_CALL=$PORT_ONE_CALL" >> $SETUPENV
	echo "PORT_ONE_SPEED=$PORT_ONE_SPEED" >> $SETUPENV
	echo "PORT_ONE_PACLEN=$PORT_ONE_PACLEN" >> $SETUPENV
	echo "PORT_ONE_WINDOW=$PORT_ONE_WINDOW" >> $SETUPENV
	echo "PORT_ONE_DESCR='$PORT_ONE_DESCR'" >> $SETUPENV
	if [[ $NUMRADIOS -eq 2 ]]; then
		# deleting existing values with sed first
	sed -i -r '/^PORT_TWO=/d' $SETUPENV
	sed -i -r '/^PORT_TWO_CALL/d' $SETUPENV
	sed -i -r '/^PORT_TWO_SPEED/d' $SETUPENV
	sed -i -r '/^PORT_TWO_PACLEN/d' $SETUPENV
	sed -i -r '/^PORT_TWO_WINDOW/d' $SETUPENV
	sed -i -r '/^PORT_TWO_DESCR/d' $SETUPENV
	# write new values
	echo "PORT_TWO=${PORT_TWO}" >> $SETUPENV
	echo "PORT_TWO_CALL=$PORT_TWO_CALL" >> $SETUPENV
	echo "PORT_TWO_SPEED=$PORT_TWO_SPEED" >> $SETUPENV
	echo "PORT_TWO_PACLEN=$PORT_TWO_PACLEN" >> $SETUPENV
	echo "PORT_TWO_WINDOW=$PORT_TWO_WINDOW" >> $SETUPENV
	echo "PORT_TWO_DESCR='$PORT_TWO_DESCR'" >> $SETUPENV	
	fi
	dialog --backtitle "$BTITLE" --title "Enable System Configs?" --defaultno --yesno \
"HAL has now completed the gathering of the necessary information \
to configure or update your system.  It is now time to overwrite the required production \
config files with your new values.  If you choose to continue, answer \"Yes\" \
, otherwise, if you wish to evaluate the config file /etc/hal/work/setupn.env \
first you may do so, BUT you will have to start this script from the \
beginning if you answer \"No\" in order to put it into production." 13 70
	cp -f $SETUPENV /etc/hal/env/setup.env
	cp -f $STATIONENV /etc/hal/env/station.env
	cp -f $AXPORTS /etc/ax25/axports
else 
	[[ $DEBUG_ON -eq 1 ]] && debug "User chose to exit before writing config files." $DEBUG_FILE
	premature_end
fi