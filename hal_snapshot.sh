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
########################################################
# Script Name : /usr/local/bin/hal_snapshot.sh
# Author : Mitch Winkle, AB4MW
# Date : 12 June 2015
# Description : A script to take a diagnostic snapshot 
# of a HAL configures AX.25 packet system for 
# the purposes of debugging and assisting end users.
########################################################
# input paramter is output filename
outfile=/tmp/halsnapshot.txt
datestamp=`date '+%Y%m%d-%H:%M'`
printf "Contents of /etc/hal/env/station.env : \n" > $outfile
cat /etc/hal/env/station.env >> $outfile
printf "\nContents of /etc/hal/env/setup.env : \n" >> $outfile
cat /etc/hal/env/setup.env >> $outfile
printf "\nContents of /proc/cpuinfo : \n" >> $outfile
cat /proc/cpuinfo >> $outfile
printf "\nContents of /etc/ax25/axports : \n" >> $outfile
cat /etc/ax25/axports >> $outfile
printf "\nContents of /etc/ax25/ax25d.conf : \n" >> $outfile
cat /etc/ax25/ax25d.conf >> $outfile
printf "\nContents of /etc/ax25/nrports : \n" >> $outfile
cat /etc/ax25/nrports >> $outfile
printf "\nContents of /etc/ax25/nrbroadcast : \n" >> $outfile
cat /etc/ax25/nrbroadcast >> $outfile
printf "\nList of symlinks in /root directory for TNC's : \n" >> $outfile
ls -l /root | grep '^lrwx*' >> $outfile
tar cvzf /root/HALsnapshot-${datestamp}.tar.gz \
/root/LinPac/* /home/pi/LinPac/* /etc/ax25/* /etc/hal/* /var/ax25/* $outfile
[[ -f /tmp/halsnapshot.txt ]] && rm -f /tmp/halsnapshot.txt
echo "Created : /root/HALsnapshot-${datestamp}.tar.gz"
exit 0
