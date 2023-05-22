#!/bin/sh
# Send APRS position report to ISS on 145.825
#
MYCALL=$1
INT=$2
if [ -z $INT ]; then
        echo "Oops! UISS <CALL> <int_name>. Interface name required, use INT command for$
        exit 0
fi
POSITION=`lynx -dump http://levinecentral.com/ham/ab4mw_grid.php?Call=${MYCALL}`
#echo $POSITION
Alat=`echo $POSITION|cut -f 2 -d ' '`
Alon=`echo $POSITION|cut -f 3 -d ' '`
#echo $Alat $Alon
MSG="=$Alat/$Alon-73 from '$MYCALL' via Satellite {URONode}"
#echo $MSG
beacon -c $MYCALL -d 'CQ VIA RS0ISS' -s $INT "$MSG"
