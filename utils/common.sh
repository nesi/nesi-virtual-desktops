#!/bin/bash -e

VDT_HOME=${VDT_HOME:-"$HOME/.vdt"}
VDT_LOCKFILES=${VDT_LOCKFILES:-"$VDT_ROOT/lockfiles"} 
VDT_TEMPLATES=${VDT_TEMPLATES:-"$VDT_ROOT/templates"}

#Delete files older than 2 days.
oldlogs(){
    find ${VDT_HOME}/* -mtime +2 -exec rm {} \; || return 0
}

vecho() {
    if [ "$#" -gt 0 ];then #If passed text, tty only if verbose.
        piput="$*"
    else
        read -r piput
    fi
#${BASH_SOURCE[*]}-
    piput="${FUNCNAME[-1]}:${BASH_LINENO[-1]} $piput"
    
    if [[ -n "${verbose}" ]]; then
        echo $piput #>> "/dev/tty"
    fi
    echo $piput >> ${VDT_LOGFILE:-"/dev/null"} 
}

vex () {
    # For verbose execute.
    if [[ -n "${verbose}" ]]; then
        echo "$LINENO:$*"
    fi
    echo "$LINENO:$*" >> "$VDT_LOGFILE"
    eval "$@"
}

# check this on any command
#oldlogs
vecho "Common files sourced."
vecho "${BASH_SOURCE[*]}"