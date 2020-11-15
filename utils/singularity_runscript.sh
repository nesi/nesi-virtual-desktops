#!/bin/bash -e
initialize(){
    export VDT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    source "${VDT_ROOT}/utils/common.sh"
}
main (){
#     if [[ -z $VDT_DISPLAY_PORT ]]; then echo "'VDT_DISPLAY_PORT' not set, did you launch this container correctly?";exit 1;fi    
#     if [[ -z $VDT_SOCKET_PORT ]]; then echo "'VDT_SOCKET_PORT' not set, did you launch this container correctly?";exit 1;fi    
#     if [[ -z $VDT_LOGFILE ]]; then echo "'VDT_LOGFILE' not set, did you launch this container correctly?";exit 1;fi  
    # Return error if any non optional envs not set.
    chekenv "VDT_SOCKET_PORT" "VDT_LOGFILE" #"VDT_DISPLAY_PORT" 

    # Source setup scri
    if [[ -x "$VDT_SETUP" ]]; then source "${VDT_SETUP}";fi # Should only be set if 'first time'
    if [[ -x "$VDT_POST" ]]; then source "${VDT_POST}";fi

    # Method 1: 
    #/opt/websockify/run ${VDT_WEBSOCKOPTS} --web /opt/noVNC localhost:${VDT_SOCKET_PORT} -- vncserver ${VDT_VNCOPTS} -log ${VDT_LOGFILE} -wm xfce4-session -autokill -fg -securitytypes TLSNone,X509None,None #:$((VDT_DISPLAY_PORT+5900))
    
    # Method 2: Working but bad.
    #vncserver ${VDT_VNCOPTS} -log ${VDT_LOGFILE} -wm xfce4-session -autokill -securitytypes TLSNone,X509None,None :$VDT_DISPLAY_PORT && /opt/websockify/run ${VDT_WEBSOCKOPTS} --web /opt/noVNC localhost:$VDT_SOCKET_PORT :$((VDT_DISPLAY_PORT+5900)) 
    
    # Method 3: Currently Working.
    assert_vnc # Starts a server, then tests its existence.
    /opt/websockify/run ${VDT_WEBSOCKOPTS} --web /opt/noVNC localhost:$VDT_SOCKET_PORT :$((VDT_DISPLAY_PORT+5900)) 
}

assert_vnc() {
    i=0; max_i=4
    tmplog="$(mktemp)"
    tail -f $tmplog > vecho &
    for (( i=0; i<max_i; i++ )); do
    vncserver ${VDT_VNCOPTS} -log "$tmplog" -wm xfce4-session -autokill -securitytypes TLSNone,X509None,None :${VDT_DISPLAY_PORT} > vecho 2>&1
    exc="$?"
    #echo $exc
        case $exc in
            98) return 0;; # Server exists and is readable.
            0) echo "Server started";; 
            29) echo "Port ${VDT_DISPLAY_PORT} is in use by someone else."; return 1;; 
            *) echo "Server couldn't start, error code $exc"
        esac
        sleep 5
    done
    echo "Could not start server after $max_i attempts. Try another port."; return 1
}

chekenv(){
    for var in "$@"; do
        if [[ -z ${!var} ]]; then echo "'\$${var}' not set, did you launch this container correctly?";exit 1;fi 
    done
}


cleanup(){
    unset DISPLAY
    xfce4-session-logout --halt > /dev/null 2>&1
    
}

trap cleanup INT ERR SIGINT SIGTERM

main 