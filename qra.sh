#!/bin/bash
##########################################################
# Lookup grid square and two types of Lat/Long
# values from call sign.  A great big thank you to 
# K2DSL Davide Levine for creating the php web service
##########################################################
call=${1}
#echo ${call}
if [[ ${call} == "" ]]; then
	echo "Oops!  No call sign means no output! Try again."
	exit 1
fi
result=`lynx -dump http://levinecentral.com/ham/ab4mw_grid.php?Call=${call}`
#echo ${result}
read -r grid aprslat aprslon lat lon <<< ${result}
#echo $lat $lon $grid $aprslat $aprslon
if [[ $aprslon == "found" ]]; then
	echo "Record not found for this call sign."
	exit 1
fi
echo "Your Grid Square : $grid"
APRS_string=`/usr/local/bin/qracalc $lat $lon`
echo "Your APRS location : ${APRS_string}"
echo "Your coordinates : $lat $lon"
exit 0
