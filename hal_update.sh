#!/bin/bash
################################################################################
# Script Name : hal_update.sh
# Author : Mitch Winkle, AB4MW
# Version : Alpha 2
# Date : 3 July 2015
# License : Gnu GPL v3.0
# Description : Update all HAL files and scripts to most recent copies.
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
source /etc/hal/env/functions.env
dialog --title "Shall We Continue?" --backtitle "HAL Update Utility" \
--yesno "The HAL Configuration Utility will download and install all the \
latest HAL scripts, HAL environment templates, /etc/ax25/ax25-up and \
/etc/ax25/ax25-down files.\n\nShall We Continue?" 10 70
if [[ $? != "0" ]]; then
	premature_end
	exit 0
fi
# get the latest scripts and environment files tarball from sf.net
cd /root
# get rid of the last copy before the download
[[ -f /root/HALupdate.tar.gz ]] && rm -f /root/HALupdate.tar.gz
wget https://sourceforge.net/projects/haldigital/files/Alpha/A2/HALupdate.tar.gz
if [[ $? == "0" ]]; then
	rm -f /usr/local/bin/hal*.sh
else	
	dialog --title "Failed to Download Update File" --backtitle "HAL Update Utility" \
--msgbox "The HAL Configuration Utility was unable to download HALupdate.tar.gz. \
\n\nPlease check your internet connection and try again." 9 70	
	exit 1
fi
# untar the new files over the old ones
tar xvzf HALupdate.tar.gz -C /
# clean it up
[[ -f /root/HALupdate.tar.gz ]] && rm -f /root/HALupdate.tar.gz
dialog --title "HAL Files Updated Successfully" --backtitle "HAL Update Utility" \
--msgbox "The HAL Configuration Utility has installed the latest set of HAL \
environment files, ax25-up, ax25-down and HAL script files.  If you have made \
changes to any of these files they are now destroyed unless you made backups." 9 70
exit 0
