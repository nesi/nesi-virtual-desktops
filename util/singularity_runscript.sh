#!/bin/bash -e
set +o posix

# singularity_runscript.sh
# Should be called when container is 'run' 
# e.g. this script needs to be called from inside the container.

initialize(){
    chekenv "VDT_SOCKET_PORT" "VDT_DISPLAY_PORT" "VDT_LOGFILE" "VDT_ROOT"
    source "${VDT_ROOT}/util/common.sh"
}

main (){
    initialize
    
    # # Source setup scripts
    # if [[ -x "$VDT_SETUP" ]]; then source "${VDT_SETUP}";fi # Should only be set if 'first time'
    # if [[ -x "$VDT_POST" ]]; then source "${VDT_POST}";fi

    modify_env

    /opt/websockify/run ${VDT_WEBSOCKOPTS} --web /opt/noVNC localhost:$VDT_SOCKET_PORT :$((VDT_DISPLAY_PORT+5900)) &
    assert_vnc # This command will continue running unless server can no longer be found 
    wait
    pkill -P $$
    
}
modify_env() {
    # Set paths
	export PATH="$PATH:/opt/slurm/bin:/opt/nesi/vdt/bin"
	export CPATH="$CPATH:/opt/slurm/include"
	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/slurm/lib64:/opt/slurm/lib64/slurm"

    debug "Using '$SHELL' as SHELL"
    
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

    # VDT_POST is a script that is run before starting XFCE.
    if [ -x "${VDT_POST:=${VDT_HOME}/vdtrc.sh}" ];then
        source ${VDT_POST}
    fi    
}

assert_vnc() {
    max_failures=4; failures=0
    heartbeat=15
    # tmplog="$(mktemp)"
    # tail -f $tmplog > debug &
    while (( failures < max_failures )); do
        #vncserver ${VDT_VNCOPTS} -log "$VNC_LOG" -wm xfce4-session -autokill -securitytypes TLSNone,X509None,None :${VDT_DISPLAY_PORT}
        cmd="vncserver ${VDT_VNCOPTS} -wm xfce4-session -autokill -securitytypes TLSNone,X509None,None :${VDT_DISPLAY_PORT}"
        debug "Running command '${cmd}'"
        ${cmd}
        exc="$?"
        debug "returned exit code '${exc}"
            case $exc in
                98) debug "Server exists and is readable."; sleep $heartbeat;; # 
                0) debug "Server started." && break;; 
                29) error "Port ${VDT_DISPLAY_PORT} is in use by someone else."; (( failures++ ));; 
                *) error "Server couldn't start, error code $exc"; (( failures++ ))
            esac
            sleep 5
    done
    if (( failures >= max_failures )); then
        error "Could not start server after $max_i attempts. Try another port."
        exit 1
    fi
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
