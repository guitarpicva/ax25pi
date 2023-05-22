#!/bin/bash
################################################################################
# Script Name : hal_kissparam.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 7 July 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# KISS modem parameters.
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
# Make the text lines for ax25d.conf to listen for netrom connects and spawn 
# Uronode as a NET/ROM connection.  Otherwise let user edit nrports values only.
################################################################################
# FUNCTIONS 
source /etc/hal/env/functions.env
# read current environment
source /etc/hal/env/setup.env
source /etc/hal/env/station.env
SETUPENV=/etc/hal/work/setup.env.hal
cp /etc/hal/env/setup.env $SETUPENV
# Production config files copied to working files for adjustment
cp -f /etc/ax25/axports /etc/hal/work/axports.hal
cp -f /etc/ax25/ax25d.conf /etc/hal/work/ax25d.conf.hal
cp -f /etc/ax25/nrports /etc/hal/work/nrports.hal
cp -f /etc/ax25/nrbroadcast /etc/hal/work/nrbroadcast.hal
AXPORTS=/etc/hal/work/axports.hal
AX25D=/etc/hal/work/ax25d.conf.hal
NRPORTS=/etc/hal/work/nrports.hal
NRBROADCAST=/etc/hal/work/nrbroadcast.hal
# First determine if Net/ROM is already configured
if [[ $NETROM_REQUIRED -eq 1 ]]; then
	dialog --backtitle "$BTITLE" --title "Net/ROM Already Configured" --exit-label "Continue" --msgbox \
	"The system has already been configured for Net/ROM. \
	HAL will now show you the configuration and you may choose whether or \
	not to make changes." 8 70
	echo "nrports" > answer
	cat /etc/ax25/nrports >> answer
	printf "\nnrbroadcast\n" >> answer
	cat /etc/ax25/nrbroadcast >> answer
	dialog --backtitle "$BTITLE" --title "Current Net/ROM Configuration" --exit-label "Continue" --textbox \
	answer 22 70
	dialog --backtitle "$BTITLE" --title "Change Net/ROM Port Configuration" --yesno \
	"Would you like to make changes to Net/ROM on this system?" 6 70 
	if [[ $? -eq 0 ]]; then
		# Get rid of empty lines
		sed -i '/^[[:blank:]]*$/d' /etc/ax25/nrports
		# Count the number of ax.25 ports shown in the nrbroadcast file
		count=`grep -v ^# /etc/ax25/nrports |wc -l`
		num=1
		while [[ $num -le $count ]] 
		do
			line=`cat /etc/ax25/nrports|grep -v ^#| head -n $num| tail -n 1|tr -s '\t' ' '`
			read name ssid alias paclen descr <<<$line
			ssid=`echo $ssid|cut -f 2 -d '-'`
			# open fd
			exec 3>&1
			 
			# Store data to $VALUES variable
			VALUES=$(dialog --ok-label "Submit" \
			--backtitle "$DTITILE" \
			--title "Net/ROM Configuration" \
			--form "Edit the Net/ROM Port <$name>.  \
			Current values are shown below." 12 60 0 \
			"SSID used for <$name>: ${STATION_CALL}-"	1 1	"${ssid}"  1 31 2 0 \
			"Net/ROM Alias:"	    	2 1	"${alias}"  	2 31 6 0 \
			"Max Packet Length:"    	3 1	"${paclen}" 	3 31 3 0 \
			"Description:"     		4 1	"${descr}" 	4 31 40 0 \
			2>&1 1>&3)
			 
			# close fd
			exec 3>&-
			VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
			read ssid alias paclen descr <<<$VALUES
			# remove the old line from the nrports file
			sed -i -r "/^${name}/d" $NRPORTS
			# write the modified line to the nrports file
			printf "$name\t${STATION_CALL}-${ssid}\t\t${alias}\t${paclen}\t${descr}\n" >> $NRPORTS
			case $name in
			netrom)
				sed -i -r '/^NETROM_ALIAS/d' $SETUPENV
				alias=`echo ${alias}|awk '{print toupper ($0)}'`
				echo "NETROM_ALIAS=${alias}" >> $SETUPENV
				sed -i -r '/^NETROM_SSID/d' $SETUPENV		
				echo "NETROM_SSID=${ssid}" >> $SETUPENV
				;;
			netbbs) sed -i -r '/^FBB_ALIAS/d' $SETUPENV
				alias=`echo ${alias}|awk '{print toupper ($0)}'`
				echo "FBB_ALIAS=${alias}" >> $SETUPENV				
				sed -i -r '/^FBB_SSID/d' $SETUPENV		
				echo "FBB_SSID=${ssid}" >> $SETUPENV
				;;
			esac
			let num=num+1
		done
		# Now edit the contents of the nrbroadcast file
		# Get rid of empty lines
		sed -i '/^[[:blank:]]*$/d' /etc/ax25/nrbroadcast
		# Count the number of ax.25 ports shown in the nrbroadcast file
		count=`grep -v ^# /etc/ax25/nrbroadcast |wc -l`
		num=1
		while [[ $num -le $count ]] 
		do
			axport=`cat /etc/ax25/nrbroadcast|grep -v ^#| head -n $num| tail -n 1|cut -f 1`
			
			line=`cat /etc/ax25/nrbroadcast|grep ^${axport}|sed 's/\t/ /g'`
			read axport min_obs def_qual worst_qual verbose <<<$line
			#min_obs=`echo $line|cut -f 2 -d ' '`			
			#def_qual=`cat /etc/ax25/nrbroadcast|grep '^${axport}'|sed 's/\t/ /g'|cut -f 3 -d ' '`
			#worst_qual=`cat /etc/ax25/nrbroadcast|grep '^${axport}'|sed 's/\t/ /g'|cut -f 4 -d ' '`
			#verbose=`cat /etc/ax25/nrbroadcast|grep '^${axport}'|sed 's/\t/ /g'|cut -f 5 -d ' '`
			# open fd
			exec 3>&1
			 
			# Store data to $VALUES variable
			VALUES=$(dialog --ok-label "Submit" \
				  --backtitle "$DTITILE" \
				  --title "Net/ROM Configuration" \
				  --form "Edit the nrbroadcast Entries.  \
				Current values are shown below." 12 60 0 \
				"AX.25 port"			1 1	"${axport}"  	1 25 15 0 \
				"Minimum Observed Value:"    	2 1	"${min_obs}"  	2 25 2 0 \
				"Default Quality Value:"    	3 1	"${def_qual}" 	3 25 3 0 \
				"Worst Quality Allowed:" 	4 1	"${worst_qual}"	4 25 3 0 \
				"Broadcast learned routes?:" 	5 1	"${verbose}"	5 25 1 0 \
			2>&1 1>&3)
			 
			# close fd
			exec 3>&-
			VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
			#    axport  min_obs def_qual worst_qual verbose
			read newaxport min_obs def_qual worst_qual verbose <<<$VALUES
			# delete the old line
			sed -i -r "/^${axport}/d" $NRBROADCAST
			# add the new line
			printf "${newaxport}\t${min_obs}\t${def_qual}\t${worst_qual}\t${verbose}\n" >>  $NRBROADCAST
			let num=num+1
		done
	else
		dialog --backtitle "$BTITLE" --title "Notice" --exit-label "Finished" \
	--msgbox "The system has **** NOT **** been changed." 8 70
	exit 0
	fi
else
	# what to do here about Uronode as the handler for Net/ROM connects
	# (unless it's only wanted for FBB)
	# Create a NET/ROM listener?
	dialog --backtitle "$BTITLE" --title "Net/ROM Configuration" --exit-label "Continue" --msgbox \
	"Net/ROM is a networking layer that rides on AX.25 connections.  It \
	provides a more robust \"Virtual Circuit\" between nodes than piecing \
	together a string of AX.25 connections.  This comes at the cost of a bit \
	more networking overhead.\n\nNet/ROM is \
	widely used in some regions and completely unused in others.  You should \
	find out if your region appreciates Net/ROM broadcasts or not and if so \
	what their frequency is.  The default is one NODES broadcast every 30 \
	minutes.  This is typically the norm.\n\nIf you are unsure, HAL recommends \
	that you say NO to the next question and do some local research before \
	proceeding.  This process will also enable the use of the Uronode node \
	handler program.\n\nThis also means that you will have to go through the \
	Uronode setup process as well.  Uronode will be called to service any \
	connection for a Net/ROM circuit request." 25 70
	dialog --backtitle "$BTITLE" --title "Create a NET/ROM Listener" --yesno \
	"Shall we create a NET/ROM listener?  If you are unsure, answer NO" 6 70
	if [[ "$?" == "0" ]]; then
		NETROM_REQUIRED=1
		[[ $DEBUG_ON -eq 1 ]] && debug "User chose to create Net/ROM listener <netrom>" $DEBUG_FILE
		dialog --backtitle "$BTITLE" --title "Net/ROM Alias" --inputbox \
		"Input your 6 character or less Net/ROM alias and press <Enter>" 9 60 "REGNND" 2>answer
		NETROM_ALIAS=`cat answer| awk '{print toupper($0)}'`
		[[ $DEBUG_ON -eq 1 ]] && debug "Net/ROM alias=${NETROM_ALIAS}" $DEBUG_FILE
		dialog --backtitle "$BTITLE" --title "Net/ROM SSID" --inputbox \
		"Input the UNIQUE SSID to use for Net/ROM and press <Enter>" 9 60 "2" 2>answer
		NETROM_SSID=`cat answer|awk '{print toupper ($0)}'`
		echo "NETROM_SSID=${NETROM_SSID}" >> $SETUPENV
		[[ $DEBUG_ON -eq 1 ]] && debug "Net/ROM SSID=${NETROM_SSID}" $DEBUG_FILE
		printf "# NET/ROM Definition\n<netrom>\nparameters 1    10  *  *  *   *   *\nNOCALL * * * * * * L\nN0CALL * * * * * * L\ndefault * * * * * * 0 root /usr/sbin/uronode uronode\n" >> $AX25D
		content="`cat $AX25D`"
		dialog --backtitle "$BTITLE" --title "NET/ROM Listener Created" --textbox $AX25D 22 70
		#####################################################################
		# Create the nrports file for the NET/ROM interface to SSID-2
		#####################################################################
		# Create the /etc/hal/work/nrports.hal file from scratch
		printf "# Created by HAL\n#NAME\tCALLSIGN\tALIAS\tPACLEN\tDESCR\n" > $NRPORTS
		printf "netrom\t${STATION_CALL}-${NETROM_SSID}\t\t${NETROM_ALIAS}\t236\tNET/ROM Port\n" >> $NRPORTS
		printf "# Created by HAL\n#axport\tmin\tdef\tworst\tverbose\n" > $NRBROADCAST
		printf "${PORT_ONE}\t5\t203\t\t141\t\t0\n" >> $NRBROADCAST
		if [ ${NUM_RADIOS} -gt 1 ]; then
			printf "${PORT_TWO}\t1\t203\t\t141\t\t0\n">> $NRBROADCAST
		fi
		#####################################################################
		# Inform the user of how the base Net/ROM configuration has been done
		# and that it is only broadasting local services.
		#####################################################################
		dialog --backtitle "$BTITLE" --title "Notice" --exit-label "Continue" --msgbox "The system has \
		been configured for NET/ROM on one or both ports.  The system is set to \
		only broadcast local services on the configured ports. If you \
		wish to change this, run this script again to edit the values.  If you \
		require a Net/ROM listener for FBB, enable that from the FBB \
		configuration script." 10 70
	fi # end of new netrom config
fi # end of top if
################################################################################
# Now it's time to make the changes permanent.
dialog --backtitle "$BTITLE" --title "Enable Net/ROM Changes?" --yesno \
	"HAL has finished making the changes to the work files.\n\n \
	Select \"Yes\" to make the changes or \"No\" abandon them." 9 70
if [[ $? -eq 0 && $NETROM_REQUIRED -eq 1 ]]; then
	cp -f $NRPORTS /etc/ax25/nrports
	sed -i '/^[[:blank:]]*$/d' /etc/ax25/nrports
	if [[ -f $NRBROADCAST ]]; then
		cp -f $NRBROADCAST /etc/ax25/nrbroadcast
		# remove any null lines
		sed -i '/^[[:blank:]]*$/d' /etc/ax25/nrbroadcast
	fi
	cp -f $AX25D /etc/ax25/ax25d.conf
	sed -i -r '/^NETROM_REQUIRED/d' $SETUPENV
	echo "NETROM_REQUIRED=1" >> $SETUPENV
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