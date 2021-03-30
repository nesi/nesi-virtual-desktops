#!/bin/bash -e

# Log levels.
# Fix this later.


VDT_HOME=${VDT_HOME:-"$HOME/.vdt"}
VDT_LOCKFILES=${VDT_LOCKFILES:-"$VDT_ROOT/lockfiles"} 
#VDT_TEMPLATES=${VDT_TEMPLATES:-"$VDT_ROOT/templates"}
VDT_LOGFILE=${VDT_LOGFILE:-"/dev/null"}

debug(){
    if [[ -n ${verbose} || $LOGLEVEL = "DEBUG" ]];then
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
    echo -e "\e[91mError:${FUNCNAME[1]}::${BASH_LINENO[-1]}:\e[39m $*" | tee ${VDT_LOGFILE} >&2 
    return 1
    ##exit 1
}

vex () {
    # For verbose execute.
    if [[ -n "${verbose}" ]]; then
        echo "$LINENO:$*"
    fi
    echo "$LINENO:$*" >> "$VDT_LOGFILE"
    eval "$@"
}

export () {
    debug "$@"
    command export "$@"
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
check(){
    # General purpose function for checking state of multiple proccesses.
    # Inputs
    check_type=$1 
    onPass="$2"
    onFail="$3"
    shift; shift; shift
    list=( "$@" )
    # "AND" # All tests must pass.
    # "NAND" # All tests must fail.
    # ""
    _test(){
        p_name="$1"
        for (( i=0; i<${max_test:-"3"}; i++ )); do
            if pgrep -u "${USER}" -f "$p_name" > /dev/null; then
                debug "Process \"$p_name\" is running"
                $onPass
                pass=0
            else
                debug "Process \"$p_name\" is not running"
                $onFail
                pass=1
            fi
            case $check_type in
                "AND")
                    if ((pass==0));then 
                        return 0
                    fi
                    ;;
                "NAND")
                    if ((pass==1));then 
                        return 0;                           
                    fi
                    ;;
            esac

            sleep "${sleep_for:-"5"}"
        done
        return 1
    }

    for p in "${list[@]}"; do
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
    _main(){
        if [[ ! "${_host}" == "${HOSTNAME}" ]];then
            debug "Testing deadness of remote node"
            assert_lennut "${1}" || return 1 
            ssh ${verbose} ${_host} "source ${VDT_ROOT}/src/common.sh && check "NAND" "pkill -u "${USER}" --signal 9 -f \"$p_name\"" ":" \
                "Singularity runtime parent" \
                "opt/TurboVNC/bin/Xvnc" \
                "/usr/bin/xfce4-session" \
                "python3 -m websockify" \
                "/usr/bin/ssh-agent -s" \
                "tail -f /tmp" \
                "/usr/bin/gpg-agent ""
            #ssh ${verbose} ${_host} "source ${VDT_ROOT}/src/common.sh && assert_pid 3 2" >${VDT_LOGFILE} 2>&1
        else
            debug "Testing deadness of local node"
            check "NAND" "pkill -u "${USER}" --signal 9 -f \"$p_name\"" ":" \
                "Singularity runtime parent" \
                "opt/TurboVNC/bin/Xvnc" \
                "/usr/bin/xfce4-session" \
                "python3 -m websockify" \
                "/usr/bin/ssh-agent -s" \
                "tail -f /tmp" \
                "/usr/bin/gpg-agent "
        fi
    }

    read_lockfile $1

    if [[ ! "${_host}" == "${HOSTNAME}" ]];then
        ssh ${verbose} ${_host} "source ${VDT_ROOT}/src/common.sh && unsert_pid 3 2" #>${VDT_LOGFILE} 2>&1 || return 1
    else
        unsert_pid 3 3 #>${VDT_LOGFILE} #2>&1 || return 1
    fi
    
    pkill -s $(cat $1)
    rm -f ${verbose} ${1}
}

test_liveness(){  
    _main(){
        if [[ ! "${_host}" == "${HOSTNAME}" ]];then
            debug "Testing liveness of remote node"
            assert_lennut "${1}" || return 1 
            ssh ${verbose} ${_host} "source ${VDT_ROOT}/src/common.sh && check "AND" ":" ":" \
                "Singularity runtime parent" \
                "opt/TurboVNC/bin/Xvnc" \
                "/usr/bin/xfce4-session" \
                "python3 -m websockify" \
                "/usr/bin/ssh-agent -s" \
                "/usr/bin/gpg-agent ""
            #ssh ${verbose} ${_host} "source ${VDT_ROOT}/src/common.sh && assert_pid 3 2" >${VDT_LOGFILE} 2>&1
        else
            debug "Testing liveness of local node"
            check "AND" ":" ":" \
                "Singularity runtime parent" \
                "opt/TurboVNC/bin/Xvnc" \
                "/usr/bin/xfce4-session" \
                "python3 -m websockify" \
                "/usr/bin/ssh-agent -s" \
                "/usr/bin/gpg-agent "
        fi
    }

    read_lockfile $1

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
export support_docs="https://support.nesi.org.nz/hc/en-gb/articles/360001600235-Connecting-to-a-Virtual-Desktop"