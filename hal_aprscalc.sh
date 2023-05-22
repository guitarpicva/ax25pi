#!/bin/bash
#############################################################
# qracalc script
# Mitch Winkle, AB4MW 
# 2015-06-20


#############################################################
################################################################################
# Script Name : aprscalc
# Author : Mitch Winkle, AB4MW
# Version : 1.0
# Date : 20 June 2015
# License : Gnu GPL v3.0
# Description : Calculate deg and decimal min from decimal deg coordinates
# for APRS position reports
#
# First parameter is Latitude as signed float
# Second parameter is Longitude as signed float
#
# Ex: qracalc 32.1234 -77.3456
#
# Output : Properly formatted APRS position : =3207.40N/07720.73W
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
lat=${1}
# are we North or South?
sign=`echo $lat|cut -c '1'`
if [[ ${sign} == '-' ]]; then
	latdir='S'
	# slice off the minus sign if South
	lat=`echo ${lat}| cut -c '2-'`
else 
	latdir='N'
fi
lon=${2}
# are we East or West?
sign=`echo $lon|cut -c '1'`
if [[ $sign == '-' ]]; then
	londir='W'
	# slice off the minus sign if West
	lon=`echo ${lon}| cut -c '2-'`
else 
	londir='E'
fi
# degrees will not change so grab them
latdeg=`echo ${lat}|cut -f 1 -d '.'`
if [[ ${#latdeg} -lt 2 ]]; then
	latdeg="0${latdeg}" 
fi
londeg=`echo ${lon}|cut -f 1 -d '.'`
case ${#londeg} in
	1) londeg="00${londeg}" ;;
	2) londeg="0${londeg}" ;;
	*);;
esac
# get the remainder of the decimal points
# and trim to 4 places.  multiply that by 60
# to represent decimal minutes and trim to 
# 2 decimal places
latmin=`echo ${lat}|cut -f 2 -d '.'|cut -c '-4'`
lonmin=`echo ${lon}|cut -f 2 -d '.'|cut -c '-4'`
latmin=`echo ".$latmin * 60"|bc -l|rev|cut -c '3-'|rev`
if [[ ${#latmin} -lt 5 ]]; then
	latmin="0${latmin}"
fi
lonmin=`echo ".$lonmin * 60"|bc -l|rev|cut -c '3-'|rev`
if [[ ${#lonmin} -lt 5 ]]; then
	lonmin="0${lonmin}"
fi
# format the output along with the N, S, E, W indicator
echo "=$latdeg$latmin$latdir/$londeg$lonmin$londir"
exit 0
