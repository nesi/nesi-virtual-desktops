#!/bin/bash -e
set +o posix

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
	export PATH="$PATH:/opt/slurm/bin"
	export CPATH="$CPATH:/opt/slurm/include"
	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/slurm/lib64:/opt/slurm/lib64/slurm"

    # No check for now. Just do.
    first_time_setup

    # Check if vdt_setup.conf
    if [ ! -e "${VDT_SETUP:="${VDT_HOME}/vdt_setup.conf"}" ];then
        mkdir -p "$(dirname "${VDT_SETUP}")"
        cp "${VDT_ROOT}/util/vdt_setup.conf" "${VDT_SETUP}"
        debug "Copying default setup from '${VDT_ROOT}/util/vdt_setup.conf' to '$VDT_SETUP'"
    fi
    export VDT_SETUP
    debug "Using '${VDT_SETUP}'"
    debug "Using '$SHELL' as SHELL"
    set +e

    # Read each line of vdt_setup.conf
    while read -r line;do
        [[ ${line} =~ ^\#.* ]] && continue
        mapfile -t linearray < <(xargs -n1 <<<"${line}")

        #Load module if applicable
        if [ -n "${linearray[0]}" ];then
            module load ${linearray[0]}
        fi
        name=${linearray[1]}

        # Path to desktop entry
        de_name="$HOME/Desktop/${name//[^a-zA-Z0-9]/}.desktop"

        [ -e "$de_name" ] && continue
        # If icon doesn't already exist. Write one.
cat << EOF > ${de_name}
[Desktop Entry]
Type=Application
Exec=${linearray[2]}
Icon=${linearray[3]}
Name=${name}
EOF
    chmod 760 "${de_name}"
    done  < ${VDT_SETUP}
    set -e

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

create_directory_links(){
    # Create links to projects. (max 8)
    read -ra pj <<<$(find "/nesi/project/" -maxdepth 1 -mindepth 1 -iname "*[0-9]" -writable -type d)
    read -ra nb <<<$(find "/nesi/nobackup/" -maxdepth 1 -mindepth 1 -iname "*[0-9]" -writable -type d)

    if [[ $(echo "${pj[@]}" | wc -w) -gt 8 ]];then
        pjd="/_projects"
        mkdir "${XDG_DESKTOP_DIR}${pjd}"
    fi
    if [[ $(echo "${nb[@]}" | wc -w) -gt 8 ]];then
        nbd="/_nobackup"
        mkdir "${XDG_DESKTOP_DIR}${nbd}"
    fi
    for proj in "${pj[@]}";do
        ln -sv "$proj" "${XDG_DESKTOP_DIR}${pjd}/project_$(basename $proj)" 2>/dev/null
    done
    for proj in "${nb[@]}";do
        ln -sv "$proj" "${XDG_DESKTOP_DIR}${nbd}/nobackup_$(basename $proj)" 2>/dev/null
    done
}

first_time_setup(){
    # Check destop directory exists.
    mkdir -vp "${XDG_DESKTOP_DIR:=$HOME/Desktop}"
    create_directory_links
}


cleanup(){
    unset DISPLAY
    xfce4-session-logout --halt > /dev/null 2>&1
}

trap cleanup INT ERR SIGINT SIGTERM

main 
