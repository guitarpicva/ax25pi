#!/bin/bash
################################################################################
# Script Name : hal_mkclient.sh Raspberry Pi v2
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 19 June 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# AX.25 system and a base set of applications.
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
# WARNING: THIS SCRIPT OVERWRITES THE PRODUCTION CONFIG FILES!!@@!!@@
# The user is warned to NEVER...EVER run this script on a customized
# system.  It is meant for a HAL imaged system ONLY.!!!!!
#
#
# Other assumptions: This is designed to be run on a Debian based 
# build with it's fairly stable file structure as follows:
# 1. AX.25 config files in /etc/ax25 or are symlinked to /etc/ax25
# 2. FBB config files are found in /etc/ax25/fbb/... or symlinked
# 3. All required packages have been installed by the package manager.
# 4. All other required programs have been compiled and installed.
# 5. Distribution copies of configuration files have been backed up.
#####################################################################
# FUNCTIONS 
source /etc/hal/env/functions.env
# put the sytem back to a reasonable baseline state before proceeding (quietly)
######################################
baseline > /dev/null 2>&1
######################################
# Working config files
hal_copy "axports"
hal_copy "info.mac"
hal_copy "init.mac"
AXPORTS=/etc/hal/work/axports.hal
INFOMAC=/etc/hal/work/info.mac.hal
INITMAC=/etc/hal/work/init.mac.hal
# Environment variable files
STATIONENV=/etc/hal/env/station.env
SETUPENV=/etc/hal/env/setup.env
DEBUG_FILE=/var/log/hal_mkclient.debug
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
# Establish the HAL version in the brand new setup.env file
echo "HAL_VERSION=1" > $SETUPENV
####################################################################
dialog --backtitle "$BTITLE" --title "HAL First Run" --msgbox \
"Welcome to the HAL End User Client script.\n \
Author : Mitch Winkle AB4MW\n \
Script Name : hal_mkclient.sh\n \
Version : ALPHA A2\n \
Created : 2015-06-19\n \
Input Parameters: -d if debug statements required\n\n \
This script will assist you in setting up a Ham Arch Linux (HAL) \
system with a minimum of time and hassle...at least that is the goal." 14 75
dialog --backtitle "$BTITLE" --title "!!! WARNING !!!" --msgbox \
"!! WARNING: THIS SCRIPT OVERWRITES THE PRODUCTION CONFIG FILES !!\n\nThe \
user is warned to make backups if necessary on an already configured system.\n\n \
You will be given the opportunity to exit in two more screens." 11 75
dialog --backtitle "$BTITLE" --title "Other Assumptions" --yesno \
"Assumptions: This script is designed to be run on a Debian based \
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
fine for you.\n\nValid keystrokes for navigation are arrow keys and <Tab>.  \
The select key is <Space Bar> and the <Enter> key sends the selections to \
the program.\n\nYou may edit values in forms to change them.  Simply navigate \
to the field and change its value to whatever you desire.\n\nLet us Begin!" 16 70
STATION_CALL=''
# Station call sign
dialog --backtitle "$BTITLE" --title "Station Call Sign" --inputbox \
"Input your station call sign and press <Enter>" 8 60 "$STATION_CALL" 2>answer
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
# Show the results to the user just in case something is horribly wrong!
dialog --backtitle "$BTITLE" --title "Station Information" --msgbox \
"HAL has done a lookup of your station location based on the call sign \
provided.  If this information is incorrect, you may edit it via the \
hal_config.sh tool later.\n\nStation Call : ${STATION_CALL}\nGrid : ${GRID_SQUARE} \
\nAPRS Latitude : ${alat}\nAPRS Longitude : ${alon}\nLatitude : ${lat} \
\nLongitude : ${lon}" 16 70 
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
		Use the sensible defaults below, or choose values for yourself.\n\n" \
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
if [ $NUM_RADIOS -eq 2 ]; then
	echo "PORT_TWO=${PORT_TWO}" >> $SETUPENV
	echo "PORT_TWO_CALL=$PORT_TWO_CALL" >> $SETUPENV
	echo "PORT_TWO_SPEED=$PORT_TWO_SPEED" >> $SETUPENV
	echo "PORT_TWO_PACLEN=$PORT_TWO_PACLEN" >> $SETUPENV
	echo "PORT_TWO_WINDOW=$PORT_TWO_WINDOW" >> $SETUPENV
	echo "PORT_TWO_DESCR='$PORT_TWO_DESCR'" >> $SETUPENV
fi
################################################################################
# Interrogate for creation of the linpac config file.(s)
# open fd
exec 3>&1
	 
# Store data to $VALUES variable
VALUES=$(dialog --ok-label "Submit" \
	  --backtitle "$BTITLE" \
	  --title "BBS and Frequency Configuration" \
	  --form "Additional Information Needed.  \
	Please provide case senstitive answers ror the following values.  Only \
	the City Name field may contain spaces." \
	15 70 0 \
		"AX.25 Port to use for Home BBS:"     	1 1	"${PORT_ONE}"		1 44 10 0 \
		"Home BBS Call sign (with SSID if required):" 2 1	""  	        2 44 8 0 \
		"Frequency of Home BBS (Mhz):"		3 1	"145.730"	  	3 44 10 0 \
		"Hierarchical Packet Address:"  	4 1	"#REGN.ST.USA.NOAM"     4 44 20 0 \
		"City Name:"			  	5 1	"My City, VA"     		5 44 20 0 \
2>&1 1>&3)
# close fd
exec 3>&-
VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
read HOME_BBS_PORT HOME_BBS_CALL HOME_BBS_FREQ  HIER_ADDR LP_CITY <<<$VALUES
HOME_BBS_CALL=`echo $HOME_BBS_CALL | awk '{print toupper($0)}'`
bbs_base=`echo $HOME_BBS_CALL|cut -f 1 -d '-'| awk '{print toupper($0)}'`
printf "LP_HOME_BBS_PORT=${HOME_BBS_PORT}\nLP_HOME_BBS_CALL=${HOME_BBS_CALL} \
\nLP_HOME_BBS_FREQ=${HOME_BBS_FREQ}\nLP_HIER_ADDR=${HIER_ADDR}\nLP_CITY=\'${LP_CITY}\'\n" >> $SETUPENV
[[ $DEBUG_ON -eq 1 ]] && debug "Home BBS Information=${VALUES}" $DEBUG_FILE	
################################################################################
# Configure Linpac for the user to the greatest extent possible.
# Use the first AX.25 port as the default port
################################################################################
sed -i -r "s/^port #PORT#$/port ${PORT_ONE}/" $INITMAC
sed -i -r "s/^mycall@1 #CALL#$/mycall@1 ${STATION_CALL}/" $INITMAC
sed -i -r "s/^mycall@2 #CALL#$/mycall@2 ${STATION_CALL}/" $INITMAC
sed -i -r "s/^mycall@3 #CALL#$/mycall@3 ${STATION_CALL}/" $INITMAC
sed -i -r "s/^mycall@4 #CALL#$/mycall@4 ${STATION_CALL}/" $INITMAC
sed -i -r "s/^mycall@5 #CALL#$/mycall@5 ${STATION_CALL}/" $INITMAC
sed -i -r "s/^mycall@6 #CALL#$/mycall@6 ${STATION_CALL}/" $INITMAC
sed -i -r "s/^mycall@7 #CALL#$/mycall@7 ${STATION_CALL}/" $INITMAC
sed -i -r "s/^mycall@8 #CALL#$/mycall@8 ${STATION_CALL}/" $INITMAC
sed -i -r "s/^unsrc LINPAC$/unsrc ${STATION_CALL}/" $INITMAC
sed -i "s/144.8125/${HOME_BBS_FREQ}/" $INITMAC
sed -i "s/#BBS#/${HOME_BBS_PORT}:${HOME_BBS_CALL}/" $INITMAC
sed -i "s/#ADDR#/$bbs_base.${HIER_ADDR}/" $INITMAC
sed -i -r "s/^ QTH       :  Brno, JN89HF/ QTH       :  ${LP_CITY}, ${GRID_SQUARE}/" $INFOMAC
################################################################################
# Now configure the modem or modems and create symlinks to the USB devices
# if USB KISS TNC(s)
dialog --backtitle "$BTITLE" --title "TNC Configuration Per Radio Port" \
--menu "Select which TNC type you will be attaching to Radio One - $PORT_ONE. \
\n\nNOTE: If you choose Direwolf, your sound card must be available. \
If you choose a USB KISS TNC it must be available in order to complete this \
configuration.  If you choose TNC-Pi it must be installed and configured." 15 70 3 \
0 'Direwolf Sound Modem' \
1 'USB attached KISS Modem (TNC-X or MFJ-1270X, etc.)' \
2 'TNC-Pi on ttyAMA0 Serial Port' 2>answer
PORT_ONE_TYPE=`cat answer`
case $PORT_ONE_TYPE in 
	0) echo "PORT_ONE_TYPE=0">> $SETUPENV
	   /usr/local/bin/direwolf_config.sh 1
	;;
	1) echo "PORT_ONE_TYPE=1">> $SETUPENV
	   /usr/local/bin/kissusb_config.sh 1
	;;
	2) echo "PORT_ONE_TYPE=2">> $SETUPENV
	   /usr/local/bin/tncpi_config.sh 1
	;;
esac
[[ $DEBUG_ON -eq 1 ]] && debug "User chose to set up a TNC type of $PORT_ONE_TYPE for port one." $DEBUG_FILE
# just in case....
[[ -f answer ]] && rm -f answer
if [[ $NUM_RADIOS -eq 2 ]]; then
	dialog --backtitle "$BTITLE" --title "TNC Configuration Per Radio Port" \
	--menu "Select which TNC type you will be attaching to Radio Two - $PORT_TWO \
	\n\nNOTE: If you choose a USB KISS TNC it must be available in order to complete this \
	configuration.  If you choose Direwolf, your sound card must be available." 13 70 3 \
	0 'Direwolf Sound Modem' \
	1 'USB attached KISS Modem (TNC-X or MFJ-1270X, etc.)' 2>answer
	PORT_TWO_TYPE=`cat answer`
	echo "$PORT_TWO_TYPE"
	case $PORT_TWO_TYPE in 
		0) echo "PORT_TWO_TYPE=0">> $SETUPENV
		   /usr/local/bin/direwolf_config.sh 2
		;;
		1) echo "PORT_TWO_TYPE=1">> $SETUPENV
		   /usr/local/bin/kissusb_config.sh 2
		;;
		2) echo "PORT_TWO_TYPE=2">> $SETUPENV
		   /usr/local/bin/tncpi_config.sh 2
		;;
	esac
	[[ $DEBUG_ON -eq 1 ]] && debug "User chose to set up a TNC type of $PORT_ONE_TYPE for port one." $DEBUG_FILE	
fi
dialog --backtitle "$BTITLE" --title "Enable Configuration?" --defaultno --yesno \
"HAL has now completed the creation of all of the configuration files necessary \
to create your system.  It is now time to overwrite the required production \
config files with your new values.  If you choose to continue, answer \"Yes\" \
, otherwise, if you wish to evaluate the config files in the /etc/hal/work \
directory first you may do so, BUT you will have to start this script from the \
beginning if you answer \"No\"." 13 70
if [[ $? -eq 0 ]]; then
	cp -f $AXPORTS /etc/ax25/axports
	# create mail dirs for the specified Home BBS
	if [[ ! -d /root/LinPac/mail/${bbs_base} ]]; then
		mkdir /root/LinPac/mail/${bbs_base}
	fi
	if [[ ! -d /home/pi/LinPac/mail/${bbs_base} ]]; then
		mkdir /home/pi/LinPac/mail/${bbs_base}
	fi
	# write the updated info.mac and init.mac files
	cp -f $INFOMAC /root/LinPac/macro/info.mac
	cp -f $INFOMAC /home/pi/LinPac/macro/info.mac
	cp -f $INITMAC /root/LinPac/macro/init.mac
	cp -f $INITMAC /home/pi/LinPac/macro/init.mac
	# no need for mheardd or beacon with a client build
	echo "MHEARDD_REQUIRED=0" >> $SETUPENV
	echo "BEACON1_REQUIRED=0" >> $SETUPENV
	if [[ $NUM_RADIOS -eq 2 ]]; then
		echo "BEACON2_REQUIRED=0" >> $SETUPENV
	fi
else 
	[[ $DEBUG_ON -eq 1 ]] && debug "User chose to exit before writing config files." $DEBUG_FILE
	premature_end
fi
# update the station.data file
bbs_entry="[$LP_HOME_BBS_CALL]\nNAME=Home BBS\n"
echo "${bbs_entry}" > /root/LinPac/station.data
echo "${bbs_entry}" > /home/pi/LinPac/station.data
#############################################################################
# Tidy up
#############################################################################
[[ -f answer ]] && rm -f answer
[[ $DEBUG_ON -eq 1 ]] && debug "End hal_mkclient.sh configuration script." $DEBUG_FILE
exit 0
