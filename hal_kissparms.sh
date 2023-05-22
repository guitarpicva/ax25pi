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
################################################################################
# Script Name : kissusb_config.sh
# Author : Mitch Winkle, AB4MW
# Date : 7 July 2015
# License : Gnu GPL v3.0
# Description : Guide the user through a controlled configuration of the
# TNC-X style USB KISS TNC, namely making a symlink to it in /root directory.
################################################################################
# Load environment variables
source /etc/hal/env/station.env
source /etc/hal/env/setup.env
SETUPENV=/etc/hal/env/setup.env
# dialog constants
BTITLE="HAL KISS Parameters Tuning"
# Which radio port are we configuring?
RADIO_PORT=$1
RADIO_PORT_NAME=''
if [[ ${NUM_RADIOS} -eq 1 ]]; then
	RADIO_PORT_NAME=$PORT_ONE
	RADIO_PORT=1
	sed -i '/^PORT_ONE_RF_BAUD/d' $SETUPENV
else
	case $RADIO_PORT in
		1)	RADIO_PORT_NAME=$PORT_ONE
			;;
		2)	RADIO_PORT_NAME=$PORT_TWO
			;;
		*)   	dialog --title "Which Port?" --backtitle "$BTITLE" --menu \
			"Select which radio port for which you will be configuring KISSPARMS." 10 50 3 \
			 1 "$PORT_ONE" 2 "$PORT_TWO" \
			2>answer
			RADIO_PORT=`cat answer`
			if [[ $RADIO_PORT -eq 1 ]]; then
				RADIO_PORT_NAME=$PORT_ONE
			else
				RADIO_PORT_NAME=$PORT_TWO
			fi
			;;
	esac
fi
# open fd
exec 3>&1
if [[ $RADIO_PORT == "1" ]]; then			
	txdelay=${KISS_TXDELAY_ONE:-250}
	txtail=${KISS_TXTSIL_ONE:-20}
	persist=${KISS_PERSIST_ONE:-128}
	slottime=${KISS_SLOTTIME_ONE:-10}
else
	txdelay=${KISS_TXDELAY_TWO:-250}
	txtail=${KISS_TXTSIL_TWO:-20}
	persist=${KISS_PERSIST_TWO:-128}
	slottime=${KISS_SLOTTIME_TWO:-10}	
fi
# Store data to $VALUES variable
VALUES=$(dialog --ok-label "Submit" \
--backtitle "$BTITILE" \
--title "KISS Parameters Tuning" \
--form "Edit the KISS Parameters for port <$RADIO_PORT_NAME>.  \
Current values are shown below." 12 60 0 \
"TXDELAY:"	1 1	"${txdelay}"  	1 31 4 0 \
"TXTAIL:"	2 1	"${txtail}"  	2 31 4 0 \
"Persist:"    	3 1	"${persist}" 		3 31 4 0 \
"Slot Time:"   	4 1	"${slottime}" 		4 31 4 0 \
2>&1 1>&3)
 
# close fd
exec 3>&-
VALUES=`echo ${VALUES}|sed s/'\n'/' '/g`
read ntxdelay ntxtail npersist nslottime <<<$VALUES
#echo "$ntxdelay:$ntxtail:$npersist:$nslottime"
if [[ $RADIO_PORT == "1" ]]; then
	sed -i '/^KISS_TXDELAY_ONE/d' $SETUPENV
	sed -i '/^KISS_TXTAIL_ONE/d' $SETUPENV
	sed -i '/^KISS_PERSIST_ONE/d' $SETUPENV
	sed -i '/^KISS_SLOTTIME_ONE/d' $SETUPENV
	echo "KISS_TXDELAY_ONE=$ntxdelay" >> $SETUPENV
	echo "KISS_TXTAIL_ONE=$ntxtail" >> $SETUPENV
	echo "KISS_PERSIST_ONE=$npersist" >> $SETUPENV
	echo "KISS_SLOTTIME_ONE=$nslottime" >> $SETUPENV
else
	sed -i '/^KISS_TXDELAY_TWO/d' $SETUPENV
	sed -i '/^KISS_TXTAIL_TWO/d' $SETUPENV
	sed -i '/^KISS_PERSIST_TWO/d' $SETUPENV
	sed -i '/^KISS_SLOTTIME_TWO/d' $SETUPENV
	echo "KISS_TXDELAY_TWO=$ntxdelay" >> $SETUPENV
	echo "KISS_TXTAIL_TWO=$ntxtail" >> $SETUPENV
	echo "KISS_PERSIST_TWO=$npersist" >> $SETUPENV
	echo "KISS_SLOTTIME_TWO=$nslottime" >> $SETUPENV
fi
kissparms -p $RADIO_PORT_NAME -t ${ntxdelay} -l ${ntxtail} -s ${nslottime} -r ${npersist}
dialog --backtitle "$BTITLE" --title "KISS Parameter Tuning Complete" --msgbox \
	"KISS parameters have been updated for port $RADIO_PORT_NAME.\n\n \
	They have been udpated on the system and will be used when restarting \
	AX.25." 10 70
# Clean up 
[[ -f answer ]] && rm -f answer
