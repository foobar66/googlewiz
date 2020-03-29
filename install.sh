# Config Flags

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false
# Set to true if you need to load system.prop
PROPFILE=true
# Set to true if you need post-fs-data script
POSTFSDATA=false
# Set to true if you need late_start service script
LATESTARTSERVICE=true
# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this
REPLACE="
"

# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context

print_modname() {
    MODNAME=$(grep "name=" $TMPDIR/module.prop | sed 's|.*=||' | sed 's|-.*||')
    MODVER=$(grep "version=" $TMPDIR/module.prop | sed 's/version=//g')
    ui_print "- Magisk module: \"$MODNAME\" (module version: $MODVER)"
}

on_install() {
    # The following is the default implementation: extract $ZIPFILE/system to $MODPATH
    MODNAME=$(grep "name=" $TMPDIR/module.prop | sed 's|.*=||' | sed 's|-.*||')
    MODID=$(grep "id=" $TMPDIR/module.prop | sed 's|.*=||' | sed 's|-.*||')
    ui_print "- Extracting module files for \"$MODNAME\""
    ui_print "- MODPATH = $MODPATH"
    ui_print "- Extracting system/*"
    unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
    ui_print "- Extracting extra/*"
    unzip -o "$ZIPFILE" 'extra/*' -d $MODPATH >&2
    if [ -d $MODPATH/vendor/app ]; then
        ui_print "- moving vendor/app to system/vendor"
        mv $MODPATH/vendor/app $MODPATH/system/vendor
    fi
    # extract files at the top of the module
    ui_print "- Extracting file bind-mounts-product-etc"
    unzip -o "$ZIPFILE" 'bind-mounts-product-etc' -d $MODPATH >&2
    ui_print "- Extracting file bind-mounts-extra"
    unzip -o "$ZIPFILE" 'bind-mounts-extra' -d $MODPATH >&2
    ui_print "- Extracting file .expandapps"
    unzip -o "$ZIPFILE" '.expandapps' -d $MODPATH >&2
    ui_print "- Extracting file post-fs-data.sh"
    unzip -o "$ZIPFILE" 'post-fs-data.sh' -d $MODPATH >&2
    ui_print "- Extracting file service.sh"
    unzip -o "$ZIPFILE" 'service.sh' -d $MODPATH >&2
    ui_print "- Extracting file scriptwrapper"
    unzip -o "$ZIPFILE" 'scriptwrapper' -d $MODPATH >&2
    ui_print "- Extracting file system.prop"
    unzip -o "$ZIPFILE" 'system.prop' -d $MODPATH >&2
    ui_print "- Extracting file googlewiz"
    unzip -o "$ZIPFILE" 'googlewiz' -d $MODPATH >&2
    ui_print "- creating symlinks in /system/bin"
    # there are a few files in /system/bin where we make a link (overwrite) to /system/xbin
    # we make the symlinks here (making them in the module itself did not work, magisk?)
    for i in cmp fdisk find unzip; do
        ln -s /system/xbin/$i $MODPATH/system/bin/$i
    done
    # expand apps from /sdcard/modappsq.tar (if apps were not part of the module zip file itself)
    if [ -f $MODPATH/.expandapps ]; then
        ui_print "- APKs are not part of the module, using /sdcard/modappsq.tar"
        if [ -f /sdcard/modappsq.tar ]; then
            # note that below is the *real* path of the module for updates
            tar xf /sdcard/modappsq.tar -C /data/adb/modules_update/$MODID
            ui_print "- modappsq.tar expanded to /data/adb/modules_update/$MODID"
            if [ -d $MODPATH/vendor/app ]; then
                ui_print "- Moving $MODPATH/vendor/app/*"
                ui_print "- to $MODPATH/system/vendor/app/"
                mv $MODPATH/vendor/app/* $MODPATH/system/vendor/app/
                # and delete the vendor directory at the module level
                rm -rf $MODPATH/vendor
            else
                ui_print "- $MODPATH/vendor/app not found"
            fi
        else
            ui_print "- Error: could not find /sdcard/modappsq.tar (this is bad !!!)"
        fi
    else
        ui_print "- Apps are already part of module (no need to expand)"
    fi
}

# This function will be called after on_install is done
# The default permissions should be good enough for most cases

set_permissions() {
    # The following is the default rule, DO NOT remove
    set_perm_recursive $MODPATH 0 0 0755 0644
    # top level files
    set_perm $MODPATH/post-fs-data.sh 0 0 0755
    set_perm $MODPATH/service.sh 0 0 0755
    set_perm $MODPATH/scriptwrapper 0 0 0755
    # init.d and services.d scripts (must be executable)
    set_perm_recursive $MODPATH/system/etc/init.d/ 0 0 0755 0755
    set_perm_recursive $MODPATH/system/etc/services.d/ 0 0 0755 0755
    # xbin (must be executable)
    for i in androidauto apackages appc bash busybox cmp compall copyflash diff doperm dovl dss fdisk find freeze ftsc gdisk gset hl hm hs idiff ipk ksettings lcpu lz4 mkappsq oena parted pps rb rmovl rsync sqlite3 strace sysro sysrw unzip vacuum wellbeing xmlstarlet zip zipalign; do
        set_perm $MODPATH/system/xbin/$i 0 0 0755
    done
    # bash
    set_perm $MODPATH/system/etc/mkshrc 0 0 0755
    set_perm $MODPATH/system/xbin/bash 0 0 0755
    # extra apps
    if [ -d $MODPATH/extra ]; then
        set_perm_recursive $MODPATH/extra 0 0 0755 0644
    fi
    # Here are some examples:
    # set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
    # set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
    # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
    # set_perm  $MODPATH/system/lib/libart.so       0     0       0644
}
