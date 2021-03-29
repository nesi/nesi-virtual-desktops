#!/bin/bash -e

# singularity_runscript.sh
# Should be called when container is 'run' 
# e.g. this script needs to be called from inside the container.

initialize(){
    chekenv "VDT_SOCKET_PORT" "VDT_LOGFILE" "VDT_ROOT"
    source "${VDT_ROOT}/util/common.sh"
}

main (){
#     if [[ -z $VDT_DISPLAY_PORT ]]; then echo "'VDT_DISPLAY_PORT' not set, did you launch this container correctly?";exit 1;fi    
#     if [[ -z $VDT_SOCKET_PORT ]]; then echo "'VDT_SOCKET_PORT' not set, did you launch this container correctly?";exit 1;fi    
#     if [[ -z $VDT_LOGFILE ]]; then echo "'VDT_LOGFILE' not set, did you launch this container correctly?";exit 1;fi  
    # Return error if any non optional envs not set.
    initialize
    
    # Source setup scri
    if [[ -x "$VDT_SETUP" ]]; then source "${VDT_SETUP}";fi # Should only be set if 'first time'
    if [[ -x "$VDT_POST" ]]; then source "${VDT_POST}";fi

    modify_env

    # Method 1: 
    #/opt/websockify/run ${VDT_WEBSOCKOPTS} --web /opt/noVNC localhost:${VDT_SOCKET_PORT} -- vncserver ${VDT_VNCOPTS} -log ${VDT_LOGFILE} -wm xfce4-session -autokill -fg -securitytypes TLSNone,X509None,None #:$((VDT_DISPLAY_PORT+5900))
    
    # Method 2: Working but bad.
    #vncserver ${VDT_VNCOPTS} -log ${VDT_LOGFILE} -wm xfce4-session -autokill -securitytypes TLSNone,X509None,None :$VDT_DISPLAY_PORT && /opt/websockify/run ${VDT_WEBSOCKOPTS} --web /opt/noVNC localhost:$VDT_SOCKET_PORT :$((VDT_DISPLAY_PORT+5900)) 
    
    # Method 3: Currently Working.
    assert_vnc || exit 1 # Starts a server, then tests its existence.    
    /opt/websockify/run ${VDT_WEBSOCKOPTS} --web /opt/noVNC localhost:$VDT_SOCKET_PORT :$((VDT_DISPLAY_PORT+5900)) 
}
modify_env() {
    # Set paths
	export PATH="$PATH:/opt/slurm/sbin"
	export CPATH="$CPATH:/opt/slurm/include"
	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/slurm/lib64:/opt/slurm/lib64/slurm"

    
    if [ -r ${VDT_SETUP:="${VDT_HOME}/vdt_setup.conf"} ]

    file="myfile"
    while read -r line
    do
        [[ $line = \#* ]] && continue
        "address=\$line\127.0.0.1"
    done < "${}"

        # CUDA specific.
    if [[ -n ${EBROOTCUDA} ]];then
        debug "exporting additional CUDA paths"
        #export CMAKE_LIBRARY_PATH="$CMAKE_LIBRARY_PATH:${EBROOTCUDA}/lib64"
        #export CMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH:$EBROOTCUDA"
        #export CPATH="$CPATH:$EBROOTCUDA/include:$EBROOTCUDA/extras/CUPTI/include:$EBROOTCUDA/nvvm/include"
        export LD_LIBRARY_PATH="/cm/local/apps/cuda/libs/current/lib64:$EBROOTCUDA/lib64:$EBROOTCUDA/extras/CUPTI/lib64:$EBROOTCUDA/nvvm/lib64:$LD_LIBRARY_PATH"
        #export LIBRARY_PATH="$EBROOTCUDA/lib64:$EBROOTCUDA/lib64/stubs:/cm/local/apps/cuda/libs/current/lib64:$LIBRARY_PATH"
        export PATH="$EBROOTCUDA:$EBROOTCUDA/nvvm/bin:$EBROOTCUDA/bin:/cm/local/apps/cuda/libs/current/bin:/cm/local/apps/cuda/libs/current/lib64:$PATH"
        #export XDG_DATA_DIRS="$XDG_DATA_DIRS:$EBROOTCUDA/share"
    fi
}
assert_vnc() {
    i=0; max_i=4
    # tmplog="$(mktemp)"
    # tail -f $tmplog > debug &
    for (( i=0; i<max_i; i++ )); do
    #vncserver ${VDT_VNCOPTS} -log "$tmplog" -wm xfce4-session -autokill -securitytypes TLSNone,X509None,None :${VDT_DISPLAY_PORT} > debug 2>&1
#-vgl
    vncserver ${VDT_VNCOPTS} -log "$VNC_LOG" -wm xfce4-session -autokill -securitytypes TLSNone,X509None,None :${VDT_DISPLAY_PORT} > debug 2>&1
    exc="$?"
    #echo $exc
        case $exc in
            98) debug "Server exists and is readable."; return 0;; # 
            0) debug "Server started. Testing...";; 
            29) error "Port ${VDT_DISPLAY_PORT} is in use by someone else."; return 1;; 
            *) error "Server couldn't start, error code $exc"
        esac
        sleep 5
    done
    error "Could not start server after $max_i attempts. Try another port."
}

chekenv(){
    for var in "$@"; do
        if [[ -z ${!var} ]]; then error "'\$${var}' not set, did you launch this container correctly?";fi 
    done
}


cleanup(){
    unset DISPLAY
    xfce4-session-logout --halt > /dev/null 2>&1
}

trap cleanup INT ERR SIGINT SIGTERM

main 
