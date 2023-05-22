#!/bin/bash
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
####################################################################
# Script Name : direwolf_config.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# Direwolf sound card modem for APRS and Packet radio.
################################################################################
# Load environment variables and functions
source /etc/hal/env/functions.env
source /etc/hal/env/station.env
source /etc/hal/env/setup.env
# We'll write some new vars, so get the filenames into the environment
STATIONENV=/etc/hal/env/station.env
SETUPENV=/etc/hal/env/setup.env
# dialog constants
BTITLE="HAL Direwolf Setup"
dialog --backtitle "$BTITLE" --title "Sound Card Selection List" \
--yesno "The Direwolf TNC configuration overwrites the direwolf[1/2].conf file with \
a newly configured version.  If you have made changes to your direwolf1.conf or \
direwolf2.conf file for PTT or any other reason, answer \"No\" here and first \
make a backup copy so you can recreate your work.\n\nShall we continue?" 11 70
if [[ "$?" != "0" ]]; then
	echo "ANSWER:${?}"
	exit 0
fi
# Which radio port are we configuring?
RADIO_PORT=$1
RADIO_PORT_NAME=''
if [[ ${NUM_RADIOS} -eq 1 ]]; then
	RADIO_PORT_NAME=$PORT_ONE
	RADIO_PORT=1
else 
	case $RADIO_PORT in
		1)	RADIO_PORT=1
			RADIO_PORT_NAME=$PORT_ONE
			;;
		2)	RADIO_PORT=2
			RADIO_PORT_NAME=$PORT_TWO
			;;
		*)   	dialog --title "Which Radio Port?" --backtitle "$BTITLE" \
			--menu "Select which radio port you will be configuring." 10 50 3 \
			1 $PORT_ONE \
			2 $PORT_TWO \
			2>answer
			RADIO_PORT=`cat answer`
			if [[ "${RADIO_PORT}" == "1" ]]; then
				RADIO_PORT_NAME=$PORT_ONE
			else
				RADIO_PORT_NAME=$PORT_TWO
			fi
			;;
	esac
fi
if [[ $RADIO_PORT_NAME == "" ]]; then
	echo "Missing or incorrect input parameter of radio port, either 1 or 2....exiting"
	exit 1	
fi

# select which direwolf config file to modify
if [[ $RADIO_PORT -eq 1 ]]; then 
	cp /etc/hal/template/direwolf.conf.hal /root/direwolf1.conf
	DIRE_CONF=/root/direwolf1.conf
else	
	cp /etc/hal/template/direwolf.conf.hal /root/direwolf2.conf
	DIRE_CONF=/root/direwolf2.conf
fi

# Confirm existence of Direwolf
if [ ! -x /usr/bin/direwolf ]; then
	dialog --backtitle "$BTITLE" --title "!!! ERROR !!!" --msgbox \
	"!! ERROR: Direwolf does not appear to be installed at /usr/bin/direwolf. \
	Setup cannot continue." 11 75
	exit 1
fi
cd /root
CARD_LIST=`arecord -l | grep card`
CARD0=`arecord -l | grep 'card 0:'`
CARD1=`arecord -l | grep 'card 1:'`
CARD2=`arecord -l | grep 'card 2:'`
CARD3=`arecord -l | grep 'card 3:'`
menulist=''
if [ "$CARD0" != "" ]; then
menulist='0 'Card0''
fi
if [ "$CARD1" != "" ]; then
	menulist=$menulist' 1 'Card1''
fi
if [ "$CARD2" != "" ]; then
	menulist=$menulist' 2 'Card2''
fi
if [ "$CARD3" != "" ]; then
	menulist=$menulist' 3 'Card3''
fi
dialog --backtitle "$BTITLE" --title "Sound Card Selection List" --msgbox \
"A list of sound capture devices will be displayed.  You will want to record the \
card number information for selection purposes.  You will be assigning a sound \
card to a radio port.  The radio port name will be shown for you." 9 70
dialog --backtitle "$BTITLE" --title "Sound Card Selection List" --msgbox "$CARD_LIST" 9 78
dialog --title "Select Audio Card for Radio" --backtitle "$BTITLE" --menu \
"Select the audio card to use for Radio Port - $RADIO_PORT_NAME." 10 79 2 $menulist 2>answer
CARD=`cat answer`
CARD="plughw:$CARD,0"
if [[ $RADIO_PORT -eq 1 ]]; then
	sed -i '/^ACARD_RADIO_ONE/d' $SETUPENV
	echo "ACARD_RADIO_ONE=$CARD">>$SETUPENV
else 
	sed -i '/^ACARD_RADIO_TWO/d' $SETUPENV
	echo "ACARD_RADIO_TWO=$CARD">>$SETUPENV
fi
# Set audio device to chosen USB sound card 
sed -i "s/^# ADEVICE  plughw:1,0$/ADEVICE ${CARD}/" $DIRE_CONF
# Set call sign to STATION_CALL
sed -i "s/MYCALL N0CALL/MYCALL ${STATION_CALL}/" $DIRE_CONF

# If 1200 baud, this is the default, so leave alone otherwise need to set
# modem line in config file.
dialog --backtitle "$BTITLE" --title "Select Modem Speed" \
--menu "Select the modem speed for Radio Port One - $RADIO_PORT_NAME" 12 70 9 \
1200 '1200 Baud AFSK' \
9600 '9600 Baud FSK' \
300 '300 Baud AFSK HF packet, 1600/1800' 2>answer
PORT_BAUD=`cat answer`
if [[ $RADIO_PORT -eq 1 ]]; then
	sed -i '/^PORT_ONE_TYPE/d' $SETUPENV
	echo "PORT_ONE_TYPE=0" >> $SETUPENV
	sed -i '/^PORT_ONE_RF_BAUD/d' $SETUPENV
	echo "PORT_ONE_RF_BAUD=${PORT_BAUD}" >> $SETUPENV
else 
	sed -i '/^PORT_TWO_TYPE/d' $SETUPENV
	echo "PORT_TWO_TYPE=0" >> $SETUPENV
	sed -i '/^PORT_TWO_RF_BAUD/d' $SETUPENV
	echo "PORT_TWO_RF_BAUD=${PORT_BAUD}" >> $SETUPENV
fi
case "$PORT_BAUD" in
	1200)	sed -i -r 's/^MODEM 1200$/MODEM 1200 E+ \/3/' $DIRE_CONF
		;;
	9600) 	sed -i -r 's/^MODEM 1200$/#MODEM 1200/' $DIRE_CONF
		sed -i -r 's/^#MODEM 9600$/MODEM 9600/' $DIRE_CONF
		;;
	300)	sed -i -r 's/^MODEM 1200$/#MODEM 1200/' $DIRE_CONF
		sed -i -r 's/^#MODEM 300 1600:1800 7@30 \/4$/MODEM 300 1600:1800 3@30 \/4/' $DIRE_CONF
		;;
esac
dialog --backtitle "$BTITLE" --title "Direwolf Modem Configuration Complete" --msgbox \
"Direwolf is configured on $RADIO_PORT_NAME and it will start automatically when \
AX.25 starts.\n\nIf you need to make adjustments to the Direwolf configuration for \
other things like PTT, edit the /root/direwolf${RADIO_PORT}.conf file." 10 70
# Clean up 
[[ -f answer ]] && rm -f answer
exit 0
