#!/bin/bash
################################################################################
# Script Name : hal_linpac.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 25 June 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# LinPac packet client application.
# Options : -d to create a debug trace file /var/log/hal_linpac.debug
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
source /etc/hal/env/functions.env
hal_copy info.mac
hal_copy init.mac
INFOMAC=/etc/hal/work/info.mac.hal
INITMAC=/etc/hal/work/init.mac.hal
# Environment variable files
STATIONENV=/etc/hal/env/station.env
SETUPENV=/etc/hal/env/setup.env
source $STATIONENV
source $SETUPENV
DEBUG_FILE=/var/log/hal_linpac.debug
if [[ $1 == "-d" ]]; then
	DEBUG_ON=1
	echo "" > $DEBUG_FILE
else
	DEBUG_ON=0
fi
[[ $DEBUG_ON -eq 1 ]] && debug "Begin hal_mkclient.sh run" $DEBUG_FILE
# Vars to use in dialog calls
BTITLE="HAL End User Client Setup"
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
the City Name field may contain spaces.\n\nThe BBS callsign should include \
the SSID used to connect to the BBS to look at your messages.  Linpac \
has a facility to automate this for you within the client." \
18 70 0 \
		"AX.25 Port to use for Home BBS:"     	1 1	"${PORT_ONE}"		1 44 10 0 \
		"BBS Callsign Where You Rec'v Mail:"    2 1	"${LP_HOME_BBS_CALL}"  	                2 44 8 0 \
		"Frequency of Home BBS (Mhz):"		3 1	"${LP_HOME_BBS_FREQ}"	  	3 44 10 0 \
		"Hierarchical Packet Address:"  	4 1	"${LP_HIER_ADDR}"     4 44 20 0 \
		"City Name:"			  	5 1	"${LP_CITY}"     	5 44 20 0 \
2>&1 1>&3)
# close fd
exec 3>&-
VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
read HOME_BBS_PORT HOME_BBS_CALL HOME_BBS_FREQ  HIER_ADDR LP_CITY <<<$VALUES
HOME_BBS_CALL=`echo $HOME_BBS_CALL | awk '{print toupper($0)}'`
bbs_base=`echo $HOME_BBS_CALL|cut -f 1 -d '-'| awk '{print toupper($0)}'`
sed -i -r '/^LP_HOME_BBS_PORT/d' $SETUPENV
sed -i -r '/^LP_HOME_BBS_CALL/d' $SETUPENV
sed -i -r '/^LP_HOME_BBS_FREQ/d' $SETUPENV
sed -i -r '/^LP_HIER_ADDR/d' $SETUPENV
sed -i -r '/^LP_CITY/d' $SETUPENV
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
dialog --backtitle "$BTITLE" --title "Enable Configuration?" --msgbox \
"HAL has now completed the creation of all of the configuration files necessary \
to create your system.  It will now overwrite the required production \
config files with your new values.\n\nExiting..." 10 70
# create mail dirs for the specified Home BBS
# if not already there
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
[[ $DEBUG_ON -eq 1 ]] && debug "End hal_mkclient.sh configuration script." $DEBUG_FILE
exit 0