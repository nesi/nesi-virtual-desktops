#!/bin/bash -e

main(){
    VDT_LOGFILE=${VDT_LOGFILE:-"/dev/null"} 

    sleep_for=5
    max_test=5

    for (( i=0; i<$max_test; i++ )); do
        sleep $sleep_for
        testfor "Singularity runtime parent" || continue
        testfor "opt/TurboVNC/bin/Xvnc" || continue
        testfor "/usr/bin/xfce4-session" || continue
        testfor "python -m websockify" || continue
        return 0
    done 
    echo "Could not find all processes after $i attempts."
    exit 1
}

testfor(){
    if pgrep -f "$@";then #> /dev/null; then 
        echo "Found '$*'" >> $VDT_LOGFILE
        return 0
    else
        echo "Couldn't find '$*', will try again in ${sleep_for}s" >> $VDT_LOGFILE
        return 1
    fi
}

main
# sshd: cwal219@notty
# bash -c export VDT_BASE=eng_dev VDT_HOME=/
# /bin/bash -e /scale_wlg_persistent/fileset
# /bin/bash -e /scale_wlg_persistent/fileset
# Singularity runtime parent
# /bin/sh /.singularity.d/runscript
# /opt/TurboVNC/bin/Xvnc :1806 
# python -m websockify
# /usr/bin/xfce4-session