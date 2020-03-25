#!/system/bin/sh

LOGPATH=/data/googlewiz
mkdir -p $LOGPATH
# create a tempfs to hold our log file
#mount -t tmpfs -o size=1m,noatime,nodiratime tmpfs $LOGPATH
LOGFILE="$LOGPATH/googlewiz.log"
rm -rf $LOGFILE
touch $LOGFILE

VERBOSE=1
[ -f /data/.noverbose ] && VERBOSE=0

# this points to /data/adb/modules/googlewiz
MODULE=$(dirname $0)

echo ">> Starting $0 at $( date +"%Y%m%d - %H:%M:%S" )" | tee -a $LOGFILE

#================================================================================
# bind mounts to "hide" the APKs inside

# OK, finally found some issue
# create a directory here, it appears in the log but somehow magisk deletes or hides it (because it is empty?)
# putting a .ignore file inside, then magisk keeps it

EMPTY=/data/empty
rm -rf "$EMPTY"
IGNOREFILE=".ignore"
mkdir -p $EMPTY
touch $EMPTY/$IGNOREFILE

# stolen from https://zackptg5.com/android.php#overlay
# fix for magisk modules not working properly due to overlay mounts (prevelant with /product)
echo "-- umount overlays mounted after magisk mount" | tee -a $LOGFILE
for i in $(cat /proc/mounts | tac | sed -n '\|/sbin/.magisk/block|q;p' | tac | grep "^overlay " | awk '{print $2}'); do
    # Unmount existing overlay
    [ $VERBOSE = 1 ] && (echo "   ummount -l $i" | tee -a $LOGFILE)
    umount -l $i
done

MOUNT="busybox mount -r -o bind,noatime,nodiratime,norelatime"
bindmounts () {
    CNT=0
    TARGET="$1"
    echo "-- bind mounts for $TARGET (empty directories)" | tee -a $LOGFILE
    # the list of dirs is passed as a string; we need to echo it to expand it for the for loop
    for i in $(echo "$2"); do
        if [ -d "$TARGET/$i" ]; then
            # *** well for some weird reason the next umount does not work
            # *** apps which are supposed to be hidden reappear in the drawer
            # umount -l $MT/$i
            [ $VERBOSE = 1 ] && (echo "   $MOUNT $EMPTY $TARGET/$i" | tee -a $LOGFILE)
            $MOUNT $EMPTY $TARGET/$i
            CNT=$(( $CNT + 1 ))
            [ $? -neq 0 ] && (echo "   mount failed!!!" | tee -a $LOGFILE)
        else
            echo "   directory $TARGET/$i does not exist (no need to bind mount $EMPTY)" | tee -a $LOGFILE
        fi
    done
    echo "   check: found $CNT empty directories in $TARGET" | tee -a $LOGFILE
}

reportemptyapks () {
    NUMFILES=$(toybox find $1 -type f -name '*.apk' -empty | wc -l)
    echo "-- counting $NUMFILES empty APKs in $1" | tee -a $LOGFILE
}

#================================================================================
# APKs in below directories are created when the module is generated (empty .apk files)

reportemptyapks /system/app
reportemptyapks /system/priv-app
reportemptyapks /product/app
reportemptyapks /product/priv-app
reportemptyapks /vendor/app

#================================================================================
# overlays cannot be created via empty .apk files
# so we overlay an empty directory over these overlay directories

MT=/vendor/overlay
array="CmccMmsTheme CmccSettingsTheme CmccSystemUITheme CtFrameworksTheme CtMmsUITheme CtSettingsTheme CtSystemUITheme oneplus_aodnotification_gold oneplus_aodnotification_purple oneplus_aodnotification_red oneplus_basiccolor_black_calculator oneplus_basiccolor_black_cellbroadcastreceiver oneplus_basiccolor_black_cloud oneplus_basiccolor_black_contacts oneplus_basiccolor_black_deskclock oneplus_basiccolor_black_dialer oneplus_basiccolor_black_emergency oneplus_basiccolor_black_OneplusAccount oneplus_basiccolor_black_OPBackup oneplus_basiccolor_black_OPCalendar oneplus_basiccolor_black_OPCardpackage oneplus_basiccolor_black_OPFilemanager oneplus_basiccolor_black_OPGamingSpace oneplus_basiccolor_black_OPLauncher oneplus_basiccolor_black_OPMms oneplus_basiccolor_black_OPNote oneplus_basiccolor_black_OPScreenRecord oneplus_basiccolor_black_OPSoundRecorder oneplus_basiccolor_black_OPSports oneplus_basiccolor_black_OPWeather oneplus_basiccolor_black_simcontacts oneplus_basiccolor_black_sound_tuner oneplus_basiccolor_white_cellbroadcastreceiver oneplus_basiccolor_white_cloud oneplus_basiccolor_white_contacts oneplus_basiccolor_white_deskclock oneplus_basiccolor_white_dialer oneplus_basiccolor_white_emergency oneplus_basiccolor_white_OneplusAccount oneplus_basiccolor_white_OPBackup oneplus_basiccolor_white_OPCalendar oneplus_basiccolor_white_OPCardpackage oneplus_basiccolor_white_OPFilemanager oneplus_basiccolor_white_OPGamingSpace oneplus_basiccolor_white_OPLauncher oneplus_basiccolor_white_OPMms oneplus_basiccolor_white_OPNote oneplus_basiccolor_white_OPScreenRecord oneplus_basiccolor_white_OPSoundRecorder oneplus_basiccolor_white_OPSports oneplus_basiccolor_white_OPWeather oneplus_basiccolor_white_simcontacts oneplus_basiccolor_white_sound_tuner oneplus_shape_circle oneplus_shape_roundedrect oneplus_shape_square oneplus_shape_squircle oneplus_shape_teardrop OptInAppOverlay oneplus_basiccolor_white_phone oneplus_basiccolor_white_telecom oneplus_basiccolor_white_settings oneplus_basiccolor_white_settings_intelligence oneplus_basiccolor_white_aod oneplus_basiccolor_white_OPSafe oneplus_basiccolor_white_wifiapsettings oneplus_basiccolor_black_opwlb oneplus_basiccolor_white_opwlb"
if [ ! -e $MODULE/googlewiz ]; then
    bindmounts "$MT" "$array"
fi

MT=/product/overlay
array="FontNotoSerifSource AccentColorBlack AccentColorCinnamon AccentColorGreen AccentColorOcean AccentColorOrchid AccentColorPurple AccentColorSpace DisplayCutoutEmulationCorner DisplayCutoutEmulationDouble DisplayCutoutEmulationTall IconPackFilledAndroid IconPackFilledLauncher IconPackFilledSettings IconPackFilledSystemUI IconPackFilledThemePicker IconPackRoundedAndroid IconPackRoundedLauncher IconPackRoundedSettings IconPackRoundedSystemUI IconPackCircularAndroid IconPackCircularLauncher IconPackCircularSettings IconPackCircularSystemUI IconPackCircularThemePicker IconShapeRoundedRect IconShapeSquare IconShapeSquircle IconShapeTeardrop NavigationBarMode2Button NavigationBarMode3Button NavigationBarModeGesturalExtraWideBack NavigationBarModeGesturalNarrowBack NavigationBarModeGesturalWideBack"
if [ ! -e $MODULE/googlewiz ]; then
    bindmounts "$MT" "$array"
fi

# hide /system/etc/apps by making it empty
echo "-- bind mounts for /system/etc/apps (to hide contents)" | tee -a $LOGFILE
MT=/system/etc/apps
if [ -d "$MT" ]; then
    [ $VERBOSE = 1 ] && (echo "   mount --bind $EMPTY $MT" | tee -a $LOGFILE)
    $MOUNT $EMPTY $MT
    [ $? -neq 0 ] && (echo "   mount failed!!!" | tee -a $LOGFILE)
else
    echo "   directory $MT does not exist (no need to bind mount $EMPTY)" | tee -a $LOGFILE
fi

# for some reason, magisk did not want to take my copies of below files in product/etc
# therefore we bind mount each file manually, the files were generated from the zipmagiskmodules
# script and are stored in $MODULE/bind-mounts-product-etc
# now do own bind mounts (note that we assume that bind-mounts-product-etc file exists
# (that was checked when the module was built)
MT=/product/etc
DEST=$MODULE/system/product/etc
FROMFILE=bind-mounts-product-etc
echo "-- bind mounts for $MT (files) using file $MODULE/$FROMFILE" | tee -a $LOGFILE
CNT=0
for i in $(cat $MODULE/$FROMFILE | grep -v ^# | sed '/^$/d'); do
    # only do something if the directory actually exists (sometimes OnePlus moves stuff around)
    if [ -f "$MT/$i" ]; then
        # if anything is already mounted there (by magisk) we unmount it first
        umount $MT/$i
        #[ $VERBOSE = 1 ] && (echo "   $MOUNT $DEST/$i $MT/$i" | tee -a $LOGFILE)
        [ $VERBOSE = 1 ] && (echo "   $MOUNT $DEST/$i ---" | tee -a $LOGFILE)
        $MOUNT $DEST/$i $MT/$i
        CNT=$(( $CNT + 1 ))
        [ $? -neq 0 ] && (echo "   mount failed!!!" | tee -a $LOGFILE)
    else
        echo "   file $MT/$i does not exist (no need to bind mount over it)" | tee -a $LOGFILE
    fi
done
echo "   check: bind mount $CNT files from $MODULE/$FROMFILE" | tee -a $LOGFILE

# APKs which we are going to overwrite ...
# note: I think the bind mounts here cause SafetyNet to fail
# it seems to confuse APK versions
# if BINDEXTRA=true we bind mount
# if BINDEXTRA=false we install the APKs through the package manager via an LS99 script
echo "-- bind mounts for $MODULE/extra" | tee -a $LOGFILE
BINDEXTRA=false
FROMFILE=bind-mounts-extra
if [ $BINDEXTRA = "true" ]; then
    CNT=0
    echo "   doing real bind mounts (overwrites) since BINDEXTRA=true" | tee -a $LOGFILE
    for i in $(cat $MODULE/$FROMFILE | grep -v ^# | sed '/^$/d'); do
        # each element if of the form <pkg>:<dir-in-extra>
        DIR=$(echo "$i" | sed 's/.*://g')
        PKGNAME=$(echo "$i" | sed 's/:.*//g')
        # just to make sure ... umount target first (there should be no mount there)
        umount /$DIR | tee -a $LOGFILE
        $MOUNT $MODULE/extra/$DIR /$DIR
        CNT=$(( $CNT + 1 ))
        [ $VERBOSE = 1 ] && (echo "   $MOUNT $MODULE/extra/$DIR /$DIR" | tee -a $LOGFILE)
    done
    echo "   check: bind mount $CNT files from $MODULE/$FROMFILE" | tee -a $LOGFILE
else
    echo "   no bind mounts for $MODULE/extra since BINDEXTRA=false, APKs will be installed via LS99 script" | tee -a $LOGFILE
fi

#================================================================================
# init.d

WRAPPER="$MODULE/scriptwrapper"
# just to make sure that the wrapper is executable
chown 0.0 $WRAPPER
chmod 755 $WRAPPER

echo "-- starting init.d: removing all log files /data/LS00*" | tee -a $LOGFILE
rm -rf /data/LS00*

if [ ! -f /data/noinitrd ]; then
    if [ -d /system/etc/init.d/ ]; then
        # directory /system/etc/init.d/ exists, find out if there are any files
        SCRIPTS=$(toybox find /system/etc/init.d/ -type f | grep 'LS00')
        NUMSCRIPTS=$(echo "$SCRIPTS" | wc -l)
        echo "-- $NUMSCRIPTS scripts found in /system/etc/init.d/" | tee -a $LOGFILE
        if [ $NUMSCRIPTS -ne 0 ]; then
            for script in $(echo "$SCRIPTS"); do
                [ $VERBOSE = 1 ] && (echo "   executing script: $script" | tee -a $LOGFILE)
                # execute the script in a subshell
                $WRAPPER $script &
            done
        else
            echo "-- directory /system/etc/init.d/ does exist (but no scripts inside)" | tee -a $LOGFILE
        fi
    else
        echo "-- directory /system/etc/init.d/ does not exist (not running any scripts)" | tee -a $LOGFILE
    fi
else
    echo "-- /data/noinitrd exists => not running /system/etc/init.d/ scripts" | tee -a $LOGFILE
fi

#================================================================================
# services.d

echo "-- starting services.d: removing all log files /data/LS99*" | tee -a $LOGFILE
rm -rf /data/LS99*

if [ ! -f /data/noinitrd ]; then
    # if LS99execonce exists, then run it first !
    if [ -f /system/etc/services.d/LS99execonce ]; then
        # we only need to run it if /data/.googlewiz.touch does not exist
        if [ ! -f /data/.googlewiz.touch ]; then
            [ $VERBOSE = 1 ] && (echo "   executing (execonce) script: /system/etc/services.d/LS99execonce" | tee -a $LOGFILE)
            # execute the script but wait until finished
            $WRAPPER /system/etc/services.d/LS99execonce
        fi
    fi
    if [ -d /system/etc/services.d/ ]; then
        # directory /system/etc/services.d/ exists, find out if there are any files (filter LS99execonce)
        SCRIPTS=$(toybox find /system/etc/services.d/ -type f | grep -v LS99execonce | grep LS99)
        NUMSCRIPTS=$(echo "$SCRIPTS" | wc -l)
        echo "-- $NUMSCRIPTS scripts found in /system/etc/services.d/" | tee -a $LOGFILE
        if [ $NUMSCRIPTS -ne 0 ]; then
            for script in $(echo "$SCRIPTS"); do
                [ $VERBOSE = 1 ] && (echo "   executing script: $script" | tee -a $LOGFILE)
                # execute the script in a subshell
                $WRAPPER $script &
            done
        else
            echo "-- directory /system/etc/services.d/ does exist (but no scripts inside)" | tee -a $LOGFILE
        fi
    else
        echo "-- directory /system/etc/services.d/ does not exist (not running any scripts)" | tee -a $LOGFILE
    fi
else
    echo "-- /data/noinitrd exists => not running /system/etc/services.d/ scripts" | tee -a $LOGFILE
fi

echo "<< Ending $0 at $( date +"%Y%m%d - %H:%M:%S" )" | tee -a $LOGFILE
