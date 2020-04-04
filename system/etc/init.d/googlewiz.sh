BB="/system/xbin/busybox"
TB="/system/bin/toybox"
TEE="$TB tee -a"
CMD=/system/bin/cmd
SETPROP="$TB setprop"
# note that getprop is going from toolbox, not toybox !!!
GETPROP="/system/bin/toolbox getprop"
RESETPROP="/sbin/resetprop"
DUMPSYS="/system/bin/dumpsys"
PM=/system/bin/pm
SETTINGSPUT="$CMD settings put"
XARGS="$TB xargs"
RM=/system/bin/rm
FIND=/system/xbin/find
SQLITE3=/system/xbin/sqlite3
MAGISKHIDE=/sbin/magiskhide

waitforsdcard () {
    local CNT=0
    while [ ! -d /sdcard/Android ]; do
        CNT=$(( $CNT + 1 ))
        sleep 1
        if [ "$CNT" -eq 20 ]; then
            echo "** weird, slept for > $CNT seconds waiting for /sdcard/Android" | $TEE $1
        fi
    done
    echo "-- slept for $CNT seconds waiting for /sdcard/Android" | $TEE $1
}

SHORT=true
[ -e /data/.noshortlog ] && SHORT=false
sysset () {
    if [ -e "$2" ]; then
        OLDVAL=$(cat $2)
        echo "$1" > "$2"
        if [ $? -ne 0 ]; then
            echo "** sysset $1 $2 [FAILED, non-zero return status]" | $TEE $LOGFILE
        else
            NEWVAL=$(cat $2)
            if [ "$SHORT" = true ]; then
                echo "   $2 [$OLDVAL => $NEWVAL]" | $TEE $LOGFILE
            else
                echo "-- cat $2 => " $OLDVAL | $TEE $LOGFILE
                echo "   echo $1 > $2" | $TEE $LOGFILE
                echo "   (new) cat $2 => " $NEWVAL | $TEE $LOGFILE
            fi
        fi
    else
        echo "** $2 does not exist (script: $0)" | $TEE $LOGFILE
    fi
}

set_debug () {
    echo "   setting $2 in /sys/ to $1" | $TEE $LOGFILE
    for i in $(find /sys/ -name $2 -type f 2>/dev/null | grep -v L2TP); do
        sysset "$1" "$i"
    done
}
