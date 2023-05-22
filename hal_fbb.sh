#!/bin/bash
################################################################################
# Script Name : hal_fbb.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 2 July 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# FBB BBS system.
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
# Get current working environment values
source /etc/hal/env/setup.env
source /etc/hal/env/station.env
# Working config files
NRPORTS="/etc/hal/work/nrports.hal"
UROCONF="/etc/hal/work/uronode.conf.hal"
PORTSYS="/etc/hal/work/port.sys.hal"
FBBCONF="/etc/hal/work/fbb.conf.hal"
ENGLISH_INF="/etc/hal/work/english.inf.hal"
# Environment variable files
STATIONENV="/etc/hal/work/station.env.hal"
SETUPENV="/etc/hal/work/setup.env.hal"
# Copy current environment to working files
cp -f /etc/hal/env/station.env $STATIONENV
cp -f /etc/hal/env/setup.env $SETUPENV
DEBUG_FILE="/var/log/hal_fbb.debug"
if [[ $1 == "-d" ]]; then
	DEBUG_ON=1
	echo "" > $DEBUG_FILE
else
	DEBUG_ON=0
fi
[[ $DEBUG_ON -eq 1 ]] && debug "Begin hal_fbb run" $DEBUG_FILE
# Vars to use in dialog calls
BTITLE="HAL FBB BBS Configuration"
FBB_REQUIRED=0
####################################################################
dialog --backtitle "$BTITLE" --title "Getting Started" --yesno \
"Welcome to the HAL FBB BBS configuration script.  It will guide you through the \
creation or adjustment of an FBB BBS system.\n\nExisting values or defaults are input for you in the form. \
\n\nValid keystrokes for navigation are arrow keys and <Tab>.  \
The select key is <Space Bar> and the <Enter> key sends the selections to \
the program.\n\nYou may edit values in forms to change them.  Simply navigate \
to the field and change its value to whatever you desire. \
\n\nYou will be asked a number of station related questions in order to complete the \
FBB configuration for your system and put it into production. \
\n\nDo you wish to configure the FBB BBS software?" 23 70
if [[ "$?" == "0" ]]; then
	FBB_REQUIRED=1
	sed -i '/^FBB_REQUIRED/d' $SETUPENV
	echo "FBB_REQUIRED=1" >> $SETUPENV
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
	"HAL will now \
ask you for FBB related information.\n\nTo enter your hierarchical route, you will need to use \
at a miniumum, your 2 letter state, \"USA\" and \"NOAM\" in the United States.\n\n \
Example : AB4MW is in the Richmond, VA area so I use,\n\n#RICH.VA.USA.NOAM OR VA.USA.NOAM. \
	" 15 70 

	# Store data to $VALUES variable
	VALUES=$(dialog --ok-label "Submit" \
		  --backtitle "$BTITLE" \
		  --title "FBB Customization" \
		  --form "FBB User and Station Information. Please enter correct data for ALL values.  \
		  Each field contains except City Name contains ONE WORLD ONLY with no spaces allowed." 15 60 0 \
		"SSID for FBB must be UNIQUE"   1 1	"${FBB_SSID:-1}"			1 30 4 0 \
		"Hierarchical Route:" 		2 1	"${HIER_ROUTE:-#REGN.ST.USA.NOAM}"	2 30 17 0 \
		"Grid Square:"			3 1	"${GRID_SQUARE}"  	3 30 6 0 \
		"Sysop First Name (ONE WORD):"	4 1	"${MYNAME:-MYNAME}" 		4 30 15 0 \
		"Sysop Call Sign:" 	    	5 1	"${FBB_SYSOP:-${STATION_CALL}}" 	5 30 8 0 \
		"Time Diff to UTC:"    		6 1	"${UTC_DIFF:--5}" 			6 30 20 0 \
		"City Name :"    		7 1	"${MYCITY:-MYCITY, ST USA}"  		7 30 18 0 \
	2>&1 1>&3)

	# close fd
	exec 3>&-

	# gather values just entered
	VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
	read FBB_SSID HIER_ROUTE QRALOC MYNAME FBB_SYSOP UTC_DIFF MYCITY <<<$VALUES
	# Adjust/write the values to the environment file for the station
	sed -i '/^FBB_SSID/d' $STATIONENV
	echo "FBB_SSID=${FBB_SSID}" >> $STATIONENV
	sed -i '/^HIER_ROUTE/d' $STATIONENV
	echo "HIER_ROUTE=${HIER_ROUTE}" >> $STATIONENV
	sed -i '/^QRALOC/d' $STATIONENV
	echo "QRALOC=${QRALOC}" >> $STATIONENV
	sed -i '/^MYNAME/d' $STATIONENV
	echo "MYNAME=${MYNAME}" >> $STATIONENV
	sed -i '/^FBB_SYSOP/d' $STATIONENV
	echo "FBB_SYSOP=${FBB_SYSOP}" >> $STATIONENV
	sed -i '/^UTC_DIFF/d' $STATIONENV
	echo "UTC_DIFF=${UTC_DIFF}" >> $STATIONENV
	sed -i '/^MYCITY/d' $STATIONENV
	echo "MYCITY='${MYCITY}'" >> $STATIONENV
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
	if [[ $portnum -le $NUM_RADIOS ]]; then
		printf "${portnum}\t9\t\t0\t\t$PORT_TWO_SPEED\n" >> $PORTSYS
	fi
	# print the header line and file fwd line
	echo "#TNC NbCh Com MultCh Pacln Maxfr NbFwd MxBloc M/P-Fwd Mode  Freq" >> $PORTSYS
	echo "0   0    0   0      0     0     0     0      00/01   ----   File-fwd." >> $PORTSYS
	# print the one or two TNC lines
	# port.sys only allows 8 character descriptions so trim it
	descr=`echo $PORT_ONE_DESCR|cut -c -8`
	echo "1   8    1   ${PORT_ONE}    236   4     1    10      10/30   UXYW   ${descr}" >> $PORTSYS
	portnum=2
	if [[ $portnum -eq $NUM_RADIOS ]]; then
		descr=`echo $PORT_TWO_DESCR|cut -c -8`
		echo "2   8    2  ${PORT_TWO}   236   4     1    10      10/30   UXYW   ${descr}" >> $PORTSYS
		portnum=3
	fi
	if [[ $NETROM_REQUIRED -eq 1 ]]; then
		if [[ $FBB_ALIAS == "" ]]; then
			FBB_ALIAS=`echo $NETROM_ALIAS|rev|cut -c 3-|rev`
			FBB_ALIAS="${FBB_ALIAS}BB"
		fi
		dialog --backtitle "$BTITLE" --title "FBB Net/ROM Alias" --inputbox \
	"Input a Net/ROM alias for your FBB BBS.  Six (6) characters or less, and press <Enter>" 7 70 \
	"$FBB_ALIAS" 2>answer
		FBB_ALIAS=`cat answer|awk '{print toupper ($0)}'`
		sed -i '/^FBB_ALIAS/d' $STATIONENV
		echo "FBB_ALIAS=${FBB_ALIAS}" >> $STATIONENV
		echo "$portnum   8    2  netbbs   236   4     1    10      00/60   UXYW   netbbs" >> $PORTSYS
		# also add a new nrport named netbbs to the nrports file to create
		# the linkage between AX.25 stack and FBB
		sed -i '/^netbbs/d' $NRPORTS
		printf "netbbs\t${STATION_CALL}-${FBB_SSID}\t\t${FBB_ALIAS}\t236\tFBB BBS\n" >> $NRPORTS
		# now fix uronode.conf
		sed -i '/^Alias[[:blank:]]*BBS/d' $UROCONF
		echo "$FBB_ALIAS"
		echo "Alias		BBS	\"connect $FBB_ALIAS s\"" >> $UROCONF
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
	dialog --backtitle "$BTITLE" --title "FBB SYSOP Password" --inputbox \
	"Input an FBB SYSOP password and press <Enter>" 5 60 "somEthingsecrEt" 2>answer
	SYSOP_PWD=`cat answer`
	echo "${SYSOP_PWD}">/etc/hal/work/passwd.sys.hal
else
	[[ $DEBUG_ON -eq 1 ]] && debug "User exited program at beginning." $DEBUG_FILE
	sed -i '/^FBB_REQUIRED/d' $SETUPENV
	echo "FBB_REQUIRED=0" >> $SETUPENV
	premature_end
	exit 0
fi
# Prompt the user that we are ready to overwrite the production config files
# with HAL created config files and let them opt out.
dialog --backtitle "$BTITLE" --title "Enable System Configs?" --defaultno --yesno \
"HAL has now completed the updates to all of the configuration files necessary \
to create your FBB BBS system.  It is now time to overwrite the required production \
config files with your new values.  If you choose to continue, answer \"Yes\", \
otherwise, if you wish to evaluate the config files in the /etc/hal/work \
directory first you may do so, BUT you will have to start this script from the \
beginning if you answer \"No\"." 13 70
if [[ $? -eq 0 ]]; then
	if [[ ${FBB_REQUIRED} -eq  1 ]]; then
		sed -i '/^FBB_REQUIRED/d' $SETUPENV
		echo "FBB_REQUIRED=1" >> $SETUPENV
		if [[ $NETROM_REQUIRED == "1" ]]; then
			sed -i '/^NETROM_REQUIRED/d' $SETUPENV
			echo "NETROM_REQUIRED=1" >> $SETUPENV
		fi
		cp -f $UROCONF /etc/ax25/uronode.conf
		cp -f $SETUPENV /etc/hal/env/setup.env
		cp -f $STATIONENV /etc/hal/env/station.env
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
		if [[ $? -eq 0 ]]; then
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
# Tidy up
#############################################################################
[[ -f answer ]] && rm -f answer
#rm -f /etc/hal/work/*hal
[[ $DEBUG_ON -eq 1 ]] && debug "End hal_fbb.sh configuration script." $DEBUG_FILE
exit 0