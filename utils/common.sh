#!/bin/bash -e

VDT_HOME=${VDT_HOME:-"$HOME/.vdt"}
VDT_LOCKFILES=${VDT_LOCKFILES:-"$VDT_ROOT/lockfiles"} 
VDT_TEMPLATES=${VDT_TEMPLATES:-"$VDT_ROOT/templates"}
VDT_LOGFILE=${VDT_LOGFILE:-"/dev/null"}

export support_docs="https://support.nesi.org.nz/hc/en-gb/articles/360001600235-Connecting-to-a-Virtual-Desktop"

# Log levels.
# Fix this later.

debug(){
    if [[ -n ${verbose} ]];then
        echo "${FUNCNAME[1]}::${BASH_LINENO[-1]} $*"
    fi
    echo "$*" >> "${VDT_LOGFILE}"
}

info(){
    echo -e "$*" | tee "${VDT_LOGFILE}"
}

warning(){
    echo -e "\e[93mWarning:\e[39m $(info "$*")"
}

error(){
    echo -e "\e[91mError:${FUNCNAME[1]}::${BASH_LINENO[-1]}:\e[39m $*" | tee ${VDT_LOGFILE} >&2
    exit 1
}
# GROSS. Fix this plz.
vecho() {
    debug "$*"
    echo "replaceme '${FUNCNAME[*]}::${BASH_LINENO[-1]}'"
    
}

vex () {
    # For verbose execute.
    if [[ -n "${verbose}" ]]; then
        echo "$LINENO:$*"
    fi
    echo "$LINENO:$*" >> "$VDT_LOGFILE"
    eval "$@"
}

assert_lennut(){
    # Inputs:
    #$VDT_SOCKET_PORT 
    if [[ $# -lt 1 ]];then echo "Not enough inputs to funtion.";fi
    read_lockfile $1
    max_test_lennut=4
    
    sleep_for=${2:-"5"}
    max_test=${3:-"3"}

    for (( i=1; i<=${max_test}; i++ )); do
        sleep "${sleep_for}"
        tunnel_pid=$(netstat -tpln 2>/dev/null| grep -oP "^tcp\s*\d*\s*\d*\s*127.0.0.1:$_port\s+\S+\s+\S+\s+\K\d+(?=.*$)" 2>/dev/null)
        if [[ -n ${tunnel_pid} ]];then
            debug "PID of tunnel is '$tunnel_pid'"
            return 0
        fi
        debug "Could not find tunnel. Attempt ($i/$max_test_lennut)"
    done 
    echerr "Error: Could not find tunnel after $max_test_lennut attempts"
    return 1
}
#######################################
# Checks that all listed tasks exist.
# Globals:
#   VDT_LOGFILE
# Arguments:
#   sleep time
#   max attempts
#######################################
assert_pid(){
    sleep_for=${1:-"5"}
    max_test=${2:-"5"}

    for (( i=0; i<$max_test; i++ )); do
        sleep $sleep_for
        testfor "Singularity runtime parent" >${VDT_LOGFILE} 2>&1 || continue
        testfor "opt/TurboVNC/bin/Xvnc" >${VDT_LOGFILE} 2>&1 || continue
        testfor "/usr/bin/xfce4-session" >${VDT_LOGFILE} 2>&1  || continue
        testfor "python -m websockify" >${VDT_LOGFILE} 2>&1 || continue
        return 0
    done 
    debug "Could not find all processes after $i attempts."
    return 1
}

unsert_pid(){
    # Takes lockfile, tries to kill job.
    return 0
    VDT_LOGFILE=${VDT_LOGFILE:-"/dev/null"} 

    sleep_for=2
    max_test=6
    echo "PID is $(cat $1)"

    #lastpid="$(cat $1)"
    for (( i=0; i<$max_test; i++ )); do
        sleep $sleep_for
        #pkill -9 -F $1
        if pids=$(testfor "Singularity runtime parent");then kill -s 9 "$pids"; continue; else true;fi
        if pids=$(testfor "opt/TurboVNC/bin/Xvnc");then kill -s 9 "$pids"; continue; else true;fi
        if pids=$(testfor "/usr/bin/xfce4-session");then kill -s 9 "$pids"; continue; else true;fi
        if pids=$(testfor "python -m websockify");then kill -s 9 "$pids"; continue; else true;fi
        if pids=$(testfor "tail -f /tmp");then kill -s 9 "$pids"; continue; else true;fi

        # if pids=$(testfor "Singularity runtime parent");then     echo $pids
        #     kill -s9 $pids && continue       
        # fi
        # testfor "Singularity runtime parent" | { xargs kill -s 9 ; continue; } || true
        # testfor "opt/TurboVNC/bin/Xvnc" || true && { xargs kill -9 ; continue; }
        # testfor "/usr/bin/xfce4-session" || true && { xargs kill -9 ;  continue; }
        # testfor "python -m websockify" || true && { xargs kill -9 ; continue; }
        # testfor "tail -f /tmp" || true && { xargs kill -9 ; continue; }
        #testfor "Singularity runtime parent" || true && { xargs kill -9 && ((i=i+1)) && continue; }
        #if pkill -u "${USER}" -f "opt/TurboVNC/bin/Xvnc"  || ! testfor "opt/TurboVNC/bin/Xvnc"; then true; else continue; fi
        #if pkill -u "${USER}" -f "/usr/bin/xfce4-session" || ! testfor "/usr/bin/xfce4-session"; then true; else continue; fi
        #if pkill -u "${USER}" -f "python -m websockify"  || ! testfor "python -m websockify" ; then true; else continue; fi
        debug "No listed proccesses remain"
        return 0
    done 
    echo "Could not kill all processes after $i attempts."
    exit 1
}

testfor(){
    #Return array of PIDs matching name. False if empty.
    pgrep -u "${USER}" -f "$@" 2>"${VDT_LOGFILE}" | tr -s "\n" " " 
    return $?
}

read_lockfile(){
    if [[ ! -w "${1}" ]];then echo "Could not read lockfile at $1." && exit 1;fi
    _filename="$(basename $1)"
    _name="$(echo "$_filename" | cut -d "." -f1)"
    _pid="$(cat $1)"
    _host="$(echo "$1" | cut -d "." -f2 | cut -d ":" -f1)"
    _port="$(echo "$1" | cut -d ":" -f2)"
}
# test_liveness(){
#     # Returns true if proccess running.
#     if  assert_lennut $_host $_port && assert_pid ;then
#         return 0
#     else
#         rm $1 && printf "Session '${_name}' not found on '${_host}'. Lockfile removed."
#     fi
# }
# sshd: cwal219@notty
# bash -c export VDT_BASE=eng_dev VDT_HOME=/
# /bin/bash -e /scale_wlg_persistent/fileset
# /bin/bash -e /scale_wlg_persistent/fileset
# Singularity runtime parent
# /bin/sh /.singularity.d/runscript
# /opt/TurboVNC/bin/Xvnc :1806 
# python -m websockify
# /usr/bin/xfce4-session
# check this on any command
#oldlogs
debug "Common files sourced."
debug "${BASH_SOURCE[*]}"