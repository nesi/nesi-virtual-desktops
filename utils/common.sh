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
        echo "DEBUG: ${FUNCNAME[1]}::${BASH_LINENO[-1]} $*"
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
    echo -e "\e[91mError:${FUNCNAME[1]}::${BASH_LINENO[-1]}:\e[39m $*" | tee ${VDT_LOGFILE} >&2 ##
    return 1
    ##exit 1
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
    
    sleep_for=${2:-"5"}
    max_test=${3:-"3"}

    for (( i=1; i<=${max_test}; i++ )); do
        sleep "${sleep_for}"
        tunnel_pid=$(netstat -tpln 2>/dev/null| grep -oP "^tcp\s*\d*\s*\d*\s*127.0.0.1:$_port\s+\S+\s+\S+\s+\K\d+(?=.*$)" 2>/dev/null)
        if [[ -n ${tunnel_pid} ]];then
            debug "PID of tunnel is '$tunnel_pid'"
            return 0
        fi
        debug "Could not find tunnel on $HOSTNAME:$_port. Attempt ($i/$max_test)"
    done 
    error "Error: Could not find tunnel on $HOSTNAME:$_port"
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
    max_test=${2:-"3"}

    _test(){
        for (( i=0; i<${max_test:-"3"}; i++ )); do
            if pgrep -u "${USER}" "${@:2}" -f "$1" > /dev/null; then
                debug "Process \`$1' is running"
                return 0
            else
                debug "Process \`$1' is not running"
            fi
            sleep "${sleep_for}"
        done
        debug "Could not find $1 processes after $i attempts."
        return 1
    }        
    debug "Testing for proccesses:"

    check_process=( \
    "Singularity runtime parent" \
    "opt/TurboVNC/bin/Xvnc" \
    "/usr/bin/xfce4-session" \
    "python -m websockify" \
    "/usr/bin/ssh-agent -s" \
    "/usr/bin/gpg-agent "
    )

    debug "Testing for proccesses:"

    for p in "${check_process[@]}"; do
        _test "${p}"  || return 1
    done
}

unsert_pid(){
    sleep_for=${1:-"5"}
    max_test=${2:-"3"}
    _kil(){
        for (( i=0; i<${max_test:-"3"}; i++ )); do
            pkill -u "${USER}" --signal 9 -f "$1"
            case $? in
                0)
                    debug "'$1' could not be killed."
                ;;
                1)
                    debug "'$1' not running."
                    return 0
                ;;
                *)
                    debug "pkill returned $?"
                ;;
            esac
            #echo "${BASH_SOURCE[*]}"
            sleep "1"
        done
        debug "Could not kill $1 after $i attempts."
        return 0
    }  

    debug "Killing proccesses"

    check_process=( \
        "Singularity runtime parent" \
        "opt/TurboVNC/bin/Xvnc" \
        "/usr/bin/xfce4-session" \
        "python -m websockify" \
        "/usr/bin/ssh-agent -s" \
        "tail -f /tmp" \
        "/usr/bin/gpg-agent "
    )
    
    for p in "${check_process[@]}"; do
        _kil "${p}" || return 1
    done  
}

read_lockfile(){
    debug "Reading lockfile $1"
    if [[ ! -w "${1}" ]];then error "Could not read lockfile at $1.";fi
    _filename="$(basename $1)"
    _name="$(echo "$_filename" | cut -d "." -f1)"
    _pid="$(cat $1)"
    _host="$(echo "$1" | cut -d "." -f2 | cut -d ":" -f1)"
    _port="$(echo "$1" | cut -d ":" -f2)"
}

turbo_kill(){

    read_lockfile $1
    debug "Testing deadness"

    if [[ ! "${_host}" == "${HOSTNAME}" ]];then
        ssh ${verbose} ${_host} "source ${VDT_ROOT}/utils/common.sh && unsert_pid 3 2" #>${VDT_LOGFILE} 2>&1 || return 1
    else
        unsert_pid 3 3 #>${VDT_LOGFILE} #2>&1 || return 1
    fi
    
    pkill -s $(cat $1)
    rm -f ${verbose} ${1}
}

test_liveness(){  
    _main(){
        if [[ ! "${_host}" == "${HOSTNAME}" ]];then
            assert_lennut "${1}" || return 1 
            ssh ${verbose} ${_host} "source ${VDT_ROOT}/utils/common.sh && assert_pid 3 2" >${VDT_LOGFILE} 2>&1
        else
            assert_pid 3 2 >${VDT_LOGFILE}
        fi
    }

    read_lockfile $1
    debug "Testing liveness"

    if _main $1 ;then
        printf "%27s %-20s %-22s %-18s %-27s\n" "$_name" " $_pid" "$_host" " $_port" "http://localhost:$_port"
        return 0
    else
        rm ${verbose} ${1}
        return 1
    fi
}

debug "Common files sourced."
debug "${BASH_SOURCE[*]}"