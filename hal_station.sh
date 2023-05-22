#!/bin/bash
################################################################################
# Script Name : hal_first_run.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 17 June 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# AX.25 system and a base set of applications.
################################################################################
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
#####################################################################
# WARNING: THIS SCRIPT OVERWRITES THE PRODUCTION CONFIG FILES!!@@!!@@
# The user is warned to NEVER...EVER run this script on a customized
# system.  It is meant for a HAL imaged system ONLY.!!!!!
#
# A note about SSID's.  In order to simplify the installation method
# HAL will create defaults for SSID's that user can accept or change.
# It is vital to understand that FBB should use a unique SSID (default
# is -1), and each AX.25 port should use unique SSID's as well.  
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
#
# Other assumptions: This is designed to be run on a Debian based 
# build with it's fairly stable file structure as follows:
# 1. AX.25 config files in /etc/ax25 or are symlinked to /etc/ax25
# 2. FBB config files are found in /etc/ax25/fbb/... or symlinked
# 3. All required packages have been installed by the package manager.
# 4. All other required programs have been compiled and installed.
# 5. Distribution copies of configuration files have been backed up.
#####################################################################
# make a copy of the existing file to work on
cp -f /etc/hal/env/station.env /etc/hal/work/station.env.hal
# change the reference to point to our working copy
STATIONENV=/etc/hal/work/station.env.hal
# FUNCTIONS 
source /etc/hal/env/functions.env
# load the existing information since we are doing a modification
source /etc/hal/env/station.env
source /etc/hal/env/setup.env
# where shall we put the trace log?
DEBUG_FILE="/var/log/hal_station.debug"
if [[ $1 == "-d" ]]; then
	DEBUG_ON=1
	echo "" > $DEBUG_FILE
else
	DEBUG_ON=0
fi
[[ $DEBUG_ON -eq 1 ]] && debug "Begin hal_station.sh" $DEBUG_FILE
# Vars to use in dialog calls
BTITLE="HAL Station Information Setup"
####################################################################
####################################################################
dialog --backtitle "$BTITLE" --title "HAL First Run" --msgbox \
"Welcome to the HAL Station Configuration script.\n \
Author : Mitch Winkle AB4MW\n \
Script Name : hal_station.sh\n \
Version : ALPHA 2\n \
Created : 25 June 2015\n \
Input Parameters: -d if debug statements required\n\n \
This script will assist you in setting the station information for a Ham Arch \
Linux (HAL) system." 14 75
dialog --backtitle "$BTITLE" --title "!!! WARNING !!!" --msgbox \
"!! WARNING: THIS SCRIPT CHANGES THE PRODUCTION CONFIG FILES !!\n\nThe \
user is warned to make backups if necessary on an already configured system.\n\n \
You will be given the opportunity to exit on the next screen." 11 75
dialog --backtitle "$BTITLE" --title "Continue or Stop?" --yesno \
"Shall we continue?" 7 75
if [ $? -eq 1 ]; then
	[[ $DEBUG_ON -eq 1 ]] && debug "User exited program before call sign." $DEBUG_FILE
	premature_end
fi
dialog --backtitle "$BTITLE" --title "Getting Started" --msgbox \
"OK, glad you are ready. Defaults may be shown for you in the form. \
\n\nValid keystrokes for navigation are arrow keys and <Tab>.  \
The select key is <Space Bar> and the <Enter> key sends the selections to \
the program.\n\nYou may edit values in forms to change them.  Simply navigate \
to the field and change its value to whatever you desire.\n\nLet us Begin!" 16 70
currval=${STATION_CALL}
# Station call sign
dialog --backtitle "$BTITLE" --title "Station Call Sign" --inputbox \
"Input your station call sign and press <Enter>" 8 60 "$currval" 2>answer
# TODO need logic here to check format of call signs, etc.
STATION_CALL=`cat answer| awk '{print toupper($0)}'`
[[ $DEBUG == "1" ]] && debug "New Station Call = ${STATION_CALL}" $DEBUG_FILE
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

# look up the call info courtesy of David Levine K2DSL
result=`lynx -dump http://levinecentral.com/ham/ab4mw_grid.php?Call=${STATION_CALL}`
read -r GRID_SQUARE alat alon lat lon <<<$result
[[ $DEBUG_ON -eq 1 ]] && debug "Station Values for $STATION_CALL: $GRID_SQUARE $alat $alon $lat $lon" $DEBUG_FILE
######################################################################
# Show the user what we have gotten from K2DSL lookup and allow them to edit it.
# open fd
exec 3>&1

# Store data to $VALUES variable
VALUES=$(dialog --ok-label 'Submit' \
	  --backtitle '$BTITILE' \
	  --title 'Station Information' \
	  --form 'Use the values below, or choose edit them for yourself.' 16 60 0 \
	'Station Call Sign:'	1 1	"${STATION_CALL}"	1 25 10 0 \
	'Grid Square:'		2 1	"${GRID_SQUARE}" 	2 25 15 0 \
	'Decimal Latitude:'    	3 1	"${DEC_LAT}"  		3 25 8 0 \
	'Decimal Longitude:'   	4 1	"${DEC_LON}" 		4 25 40 0 \
	'APRS Latitude:'     	5 1	"${APRS_LAT}" 		5 25 40 0 \
	'APRS Longitude:'     	6 1	"${APRS_LON}" 		6 25 40 0 \
2>&1 1>&3)
 
# close fd
exec 3>&-
VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
[[ $DEBUG_ON -eq 1 ]] && debug "Station Values=${VALUES}" $DEBUG_FILE
read STATION_CALL GRID_SQUARE DEC_LAT DEC_LON APRS_LAT APRS_LON <<<$VALUES
echo "currval=$currval $STATION_CALL $GRID_SQUARE $DEC_LAT $DEC_LON $APRS_LAT $APRS_LON"

# Prompt the user that we are ready to overwrite the production config files
# with HAL created config files and let them opt out.
dialog --backtitle "$BTITLE" --title "Enable System Configs?" --defaultno --yesno \
"HAL has now completed the creation of the necessary station information \
to configure or update your system.  It is now time to overwrite the required production \
config files with your new values.  If you choose to continue, answer \"Yes\" \
, otherwise, if you wish to evaluate the config file /etc/hal/work/station.env \
first you may do so, BUT you will have to start this script from the \
beginning if you answer \"No\" in order to put it into production." 13 70
if [[ $? -eq 0 ]]; then
	# deleting existing values with sed first
	sed -i -r '/^STATION_CALL/d' $STATIONENV
	sed -i -r '/^GRID_SQUARE/d' $STATIONENV
	sed -i -r '/^DEC_LAT/d' $STATIONENV
	sed -i -r '/^DEC_LON/d' $STATIONENV
	sed -i -r '/^APRS_LAT/d' $STATIONENV
	sed -i -r '/^APRS_LON/d' $STATIONENV
	# write new values
	echo "STATION_CALL=${STATION_CALL}" >> $STATIONENV
	echo "GRID_SQUARE=${GRID_SQUARE}" >> $STATIONENV
	echo "APRS_LAT=${alat}" >> $STATIONENV
	echo "APRS_LON=${alon}" >> $STATIONENV
	echo "DEC_LAT=${lat}" >> $STATIONENV
	echo "DEC_LON=${lon}" >> $STATIONENV
	# finally, copy working file over production file
	cp -f $STATIONENV /etc/hal/env/station.env
else 
	[[ $DEBUG_ON -eq 1 ]] && debug "User chose to exit before writing config files." $DEBUG_FILE
	premature_end
fi
#############################################################################
# Tidy up
#############################################################################
[[ -f answer ]] && rm -f answer
rm -f /etc/hal/work/*.hal
[[ $DEBUG_ON -eq 1 ]] && debug "End hal_first_run.sh configuration script." $DEBUG_FILE
exit 0
