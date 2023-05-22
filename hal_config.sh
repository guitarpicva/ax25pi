#!/bin/bash
################################################################################
# Script Name : hal_config.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 7 July 2015
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
#########################################################################
# The configure script will present the user with menus to ask questions
# and input forms to gather the answers in order to write HAL standard
# configuration files for each included software product.
#########################################################################
# Make a menu of components to allow the user to choose which component to 
# modify or configure for the first time.
BTITLE="HAL Configuration Utility Menu"
dialog --title "Welcome to the HAL Configuration Utility" --backtitle "$BTITLE" \
--msgbox "The HAL Configuration Utility is your entry point to configure \
different devices and applications associated with the HAL system.\n\n
The following screen will present you with a list of items that can be \
configured.  Use the arrow keys or the highlighted letter or number to select \
the item and press <Enter> to continue.\n\nPlease note: Server, Client, and AX25D \
selections overwrite all configuration files for their sets of applications.\n\n
Server configures AX.25 port(s), Uronode, AxMailFax, Net/ROM, axdigi the FBB BBS \
and TNCs.\n\nClient configures AX.25 port(s) and the LinPac packet client application and \
TNCs.\n\nThe numbered items on the list are components that you may change or enable \
or disable on your system.  The EXIT item leaves the HAL Configuration Utility.\n\n \
!!!! WARNING: DO NOT TRY TO USE THE INDIVIDUAL CONFIGURATIONS UNTIL YOU HAVE USED \
EITHER Sever or Client CONFIGURATION OPTIONS FIRST !!!!" 28 70

while true
do
dialog --title "What would you like to do?" --backtitle "$BTITLE" --menu \
"Select the application or device you wish to configure." 29 70 22 \
Server 'Full Server Configuration (OVERWRITES config)' \
Client 'Full Client Configuration (OVERWRITES config)' \
AX25D 'AX25D Re-configuration (OVERWRITES config)' \
ALSA 'Adjust Sound Card Mixer Controls (For Direwolf)' \
0 'Re-configure AX.25 ports' \
1 'Update Station Information' \
2 'Re-configure Uronode (mostly implemented)' \
3 'Re-configure AxMailFax' \
4 'Enable/Disable axdigi' \
5 'Re-configure FBB BBS (mostly implemented)' \
6 'Re-configure Net/ROM' \
7 'Re-configure LinPac' \
Direwolf 'Direwolf Sound Modem (OVERWRITES config)' \
USB-KISS 'USB connected KISS TNC' \
TNC-Pi 'TNC-Pi configuration' \
KISSPARMS 'Update the kissparms for a port' \
Update 'Update HAL Scripts' \
Restart-AX25 'Restart the AX.25 Sub-system' \
Stop-AX25 'Stop the AX.25 Sub-system' \
Start-AX25 'Start the AX.25 Sub-system' \
Status-AX25 'Status of the AX.25 Sub-system' \
EXIT 'Exit The HAL Configuration Utility' 2>answer
val=`cat answer`
case $val in
	Server) /usr/local/bin/hal_mkserver.sh
		;;
	Client) /usr/local/bin/hal_mkclient.sh
		;;
	AX25D) /usr/local/bin/hal_ax25d.sh
		;;
	ALSA) dialog --title "How to Use alsamixer" --backtitle "$BTITLE" \
--msgbox "The ALSA configuration tool, alsamixer, is how you will set the audio levels for use with \
the Direwolf sound modem.  When it starts, it will select the default sound card \
device on your system.  You should choose F6 to select the appropriate sound card \
that will be used with Direwolf.  If you are using a USB sound card dongle or a Signalink, the card \
number will likely be \"1\" and the description will ususlly have \"USB\" in the text. \
\n\nIf you are having trouble choosing the correct sound card, remove ALL sound card \
devices from their ports and run this script again.  Select F6 in alsamixer and note \
what sound card devices are listed.  Press <Esc> to quit and add ONE sound card device. \
Then run this script again and use F6 to see what new device has appeared.  This is \
your sound card device.\n\nAfter selecting the sound card, choose F5 to \
show ALL mixer controls.  Set your capture level rather high, at 80-100%.  Set your \
playback level to around 70-75%.  If there is a control for AGC or Auto Gain Control \
turn it off by using the \"M\" key.  There is a help screen within the program if \
you need more assistance.\n\nOnce these levels are set, HAL will write them to disk \
for you so the next time you start the system, they will come back to the same settings.\n\n \
When you are done adjusting the audio levels, press the <Esc> key to leave alsamixer." 32 70
		alsamixer
		alsactl store
		;;
	0) /usr/local/bin/hal_ax25.sh
		;;
	1) /usr/local/bin/hal_station.sh
		;;
	2) /usr/local/bin/hal_uronode.sh
		;;	
	3) /usr/local/bin/hal_axmail.sh
		;;
	4) /usr/local/bin/hal_axdigi.sh
		;;
	5) /usr/local/bin/hal_fbb.sh
		;;
	6) /usr/local/bin/hal_netrom.sh
		;;
	7) /usr/local/bin/hal_linpac.sh
		;;
	Direwolf) /usr/local/bin/direwolf_config.sh
		;;
	USB-KISS) /usr/local/bin/kissusb_config.sh
		;;
	TNC-Pi) /usr/local/bin/tncpi_config.sh
		;;
	KISSPARMS) /usr/local/bin/hal_kissparms.sh
		;;
	Update) /usr/local/bin/hal_update.sh
		;;
	Restart-AX25) /etc/init.d/ax25 restart
		;;
	Stop-AX25) /etc/init.d/ax25 stop
		;;
	Start-AX25) /etc/init.d/ax25 start
		;;
	Status-AX25) /etc/init.d/ax25 status
		echo "Press any key to continue..."
		read dummy
		;;
	EXIT) break;;
	*);;	
esac
done
exit 0
