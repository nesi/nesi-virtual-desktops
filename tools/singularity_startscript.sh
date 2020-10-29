#!/bin/bash -e

main (){
    # Check for required env variables.
    if [[ -z $VDT_DISPLAY_PORT ]]; then echo "'VDT_DISPLAY_PORT' not set, did you launch this container correctly?";exit 1;fi    
    if [[ -z $VDT_SOCKET_PORT ]]; then echo "'VDT_SOCKET_PORT' not set, did you launch this container correctly?";exit 1;fi    
    if [[ -z $VDT_LOGFILE ]]; then echo "'VDT_LOGFILE' not set, did you launch this container correctly?";exit 1;fi    

    # If started on node other than host, create remote tunnel.
    if [[ -n ${VDT_TUNNEL_HOST} ]];then 
        echo "Remote tunnel will be setup"
        ssh -vfNT -o ExitOnForwardFailure=yes -R ${VDT_SOCKET_PORT}:localhost:${VDT_SOCKET_PORT} ${VDT_TUNNEL_HOST}
        tunnel_pid="$!"
        sleep 5
        if [[ "$(ps -o s -h -p $tunnel_pid)"! = [SR] ]];then
            echo "Failed to open tunnel from $(hostname)"
        exit 1
    fi
    echo "Tunnel alive after 5 seconds."
    else
        echo "Instance is local. No forwarding required."
    fi

    # Source setup scripts.
    if [[ -x "$VDT_SETUP" ]]; then source "${VDT_SETUP}";fi #Should only be set if 'first time'
    if [[ -x "$VDT_POST" ]]; then source "${VDT_POST}";fi

    export ISPER="true" # Is persistant (for websockify messages)
    assert_vnc
    /opt/websockify/run ${VDT_WEBSOCKOPTS} --web /opt/noVNC localhost:${VDT_SOCKET_PORT} :$((5900 + ${VDT_DISPLAY_PORT})) 
}

assert_vnc() {
    i=0; max_i=4
    for (( i=0; i<max_i; i++ )); do
        case $(vncserver ${VDT_VNCOPTS} -log "${VDT_LOGFILE}" -wm xfce4-session -autokill -securitytypes TLSNone,X509None,None :${VDT_DISPLAY_PORT} >${VDT_LOGFILE} 2>&1) in
            98) return 0;; # Server exists and is readable.
            29) echo "Port ${VDT_DISPLAY_PORT} is in use by someone else."; return 1;; 
            *) echo "Server couldn't start, error code $?"
        esac
        i=$((i+=1)); sleep 3
    done
    echo "Could not start server after $max_i attempts. Try another port."; return 1
}

main 