#! /bin/sh
### BEGIN INIT INFO
# Provides: F6FBB  Start-up
# Required-Start: $remote_fs $syslog $network
# Required-Stop: $remote_fs $syslog $network
# Default-Start:  2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: FBB start up
# Description: This script provides the start/stopcontrol for the FBB BBS Packet Radio BBS.

### END INIT INFO

export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin

base=${0##*/}
link=${base#*[SK][0-9][0-9]}

test $link = $base && START_FBB=yes
test "$START_FBB" = yes || exit 0
test -x /usr/sbin/fbb || exit 0

return="Done"
case "$1" in
start)
	echo "Starting FBB daemon "
	if [ -f /etc/ax25/fbb/fbb.conf ] ; then
		/usr/sbin/fbb -s -l /var/log/fbb.log || return=$rc_failed
	else
		echo  "/etc/ax25/fbb/fbb.conf file not found"  
		return="Failed"
	fi
	echo  " $1 $return"
	;;
stop)
	echo "Shutting down FBB script"
	killall -KILL fbb || return="Failed"
	echo "Shutting down FBB daemon"
	killall -KILL xfbbd || return="Failed"
	sleep 4
	echo  " $1 $return"
	;;
restart|reload)
	$0 stop && $0 start
	;;
status)
	echo -n "Checking for FBB daemon : "
	PID=`/bin/pidof -x xfbbd`
	if [ -n "$PID" ]; then
		echo  "FBB is up" 
         else
		echo "No FBB daemon"
	fi
	;;


*)
	echo "Usage: $0 {start|stop|status|restart}"
	exit 1
esac

exit 0
