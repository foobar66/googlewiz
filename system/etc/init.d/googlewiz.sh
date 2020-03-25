
waitforsdcard () {
    local CNT=0
    while [ ! -d /sdcard/Android ]; do
        CNT=$(( $CNT + 1 ))
        sleep 1
        if [ "$CNT" -eq 20 ]; then
            echo "** weird, slept for > $CNT seconds waiting for /sdcard/Android" | tee -a $1
        fi
    done
    echo "-- slept for $CNT seconds waiting for /sdcard/Android" | tee -a $1
}

SHORT=true
[ -e /data/.noshortlog ] && SHORT=false
sysset () {
    if [ -e "$2" ]; then
        OLDVAL=$(cat $2)
        echo "$1" > "$2"
        if [ $? -ne 0 ]; then
            echo "** sysset $1 $2 [FAILED, non-zero return status]" | tee -a $LOGFILE
        else
            NEWVAL=$(cat $2)
            if [ "$SHORT" = true ]; then
                echo "   $2 [$OLDVAL => $NEWVAL]" | tee -a $LOGFILE
            else
                echo "-- cat $2 => " $OLDVAL | tee -a $LOGFILE
                echo "   echo $1 > $2" | tee -a $LOGFILE
                echo "   (new) cat $2 => " $NEWVAL | tee -a $LOGFILE
            fi
        fi
    else
        echo "** $2 does not exist (script: $0)" | tee -a $LOGFILE
    fi
}

set_debug () {
    echo "   setting $2 in /sys/ to $1" | tee -a $LOGFILE
    for i in $(find /sys/ -name $2 -type f 2>/dev/null | grep -v L2TP); do
        sysset "$1" "$i"
    done
}
