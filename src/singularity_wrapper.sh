#!/bin/bash -e

initialize(){
    source "${VDT_ROOT}/utils/common.sh"
}

set_env(){
    module purge > /dev/null  2>&1
    module load Python Singularity/3.6.1 -q 
    module unload XALT/NeSI -q
    module load CUDA
    if [[ -n $clean ]];then
        "${VDT_ROOT}/vdt_clean"
    fi

    if [[ -n $secure ]];then
        # If environment setup for desktop flavor.
        echo "Generating security certificate."
        if [[ ! -f "${VDT_HOME}/self.pem" ]];then
            openssl req -new -x509 -days 365 -nodes -subj "/C=NZ/ST=Wellington/L=Wellington/O=NeSI/CN=$(hostname)" -out "${VDT_HOME}/self.pem" -keyout "${VDT_HOME}/self.pem"
        fi    
        VDT_WEBSOCKOPTS="$VDT_WEBSOCKOPTS --cert=${VDT_HOME}/self.pem"
    fi

    set_display "$_display_port"
    export SINGULARITY_BINDPATH="\
$HOME:/home/$USER,\
$VDT_ROOT,\
$EB_ROOT_CUDA,\
/run,\
/etc/machine-id,\
/opt/nesi,\
/nesi/project,\
/nesi/nobackup,\
/dev/dri/card0,\
/usr/bin/ssh-agent,\
/usr/bin/gpg-agent,\
/usr/bin/lsb_release,\
/usr/share/lmod/lmod,\
/usr/include,\
/etc/opt/slurm,\
/opt/slurm,\
/usr/lib64/libmunge.so,\
/usr/lib64/libmunge.so.2,\
/usr/lib64/libmunge.so.2.0.0,\
/cm/local/apps/cuda"

    debug "Singularity bindpath is $(echo "${SINGULARITY_BINDPATH}" | tr , '\n')"

    
    # If environment setup for desktop flavor.
    if [[ -f "${VDT_TEMPLATES}/${VDT_BASE}/pre.sh" ]];then
        source "${VDT_TEMPLATES}/${VDT_BASE}/pre.sh" 
    fi

    # Set websockify options.
    VDT_WEBSOCKOPTS=" --log-file=$VDT_LOGFILE --heartbeat=30 $VDT_WEBSOCKOPTS"
    # # Additional verboseness for remoteness.
    # if [[ -n $persistent || -n $remote ]];then
    #     VDT_WEBSOCKOPTS=" --verbose ${VDT_WEBSOCKOPTS}"
    # fi    


    # Export all variables starting with 'VDT' to singularity.
    for ev in $(compgen -A variable | grep ^VDT );do
        export "SINGULARITYENV_$ev"="${!ev}"
        debug "SINGULARITYENV_$ev=${!ev}"
    done
    
    # Murder any ports that were missed.
    while [[ "$(fuser "$VDT_SOCKET_PORT"/tcp 2>/dev/null | wc -w)" -gt 0 ]];do
        echo "Port '$VDT_SOCKET_PORT' in use. Killing $VDT_SOCKET_PORT"
        kill -9 $(fuser "$VDT_SOCKET_PORT"/tcp 2>/dev/null | awk '{ print $1 }')
    done
    
    lockfile="${VDT_LOCKFILES}/${VDT_INSTANCE_NAME}.${remote:-$(hostname)}:${VDT_SOCKET_PORT}"

}

create_vnc(){   
    # Set instance name
    if [[ ! -x  "$(readlink -f "$VDT_TEMPLATES/$VDT_BASE/image")" ]];then echo "'$VDT_TEMPLATES/$VDT_BASE/image' doesn't exist!";exit 1;fi

    img_path=$(readlink -f "$VDT_TEMPLATES/$VDT_BASE/image")
    #touch "${lockfile}"
    if [[ -n ${VDT_TUNNEL_HOST} ]];then 
        lennut
    fi
    #"${timeout}" s
    echo $$ > ${lockfile}

    if [[ -n $shell ]];then

        cmd="singularity ${verbose} shell --nv ${nohome} ${img_path}"

    else 

        cmd="singularity ${verbose} run  --nv ${nohome} ${img_path}"
        
    fi
    # (
    #     flock 200
    # ) 200>$lockfile
    ${cmd} # 2> /dev/null #debug #2>&1
    #cleanup_nice
}

set_display (){
    #Finds a free display port. If passed an argument, will test that then return.
    max_i=4;
    for (( i=0; i<max_i; i++ )); do
        VDT_DISPLAY_PORT=${1:-$(shuf -i 1100-2000 -n 1)}
        if [[ ! -e "/tmp/.X11-unix/X{$VDT_DISPLAY_PORT}" ]];then return 0;fi
        if [[ $# -gt 0 ]];then echo "Selected display port ${1} not suitable."; return 2;fi
    done
    echo "Could not find a suitable display port after $max_i attempts."; exit 1
}
cleanup() {
    #vncserver
    #singularity $verbose exec "$img_path" "vncserver -kill ":$VDT_DISPLAY_PORT"" 1> ${VDT_LOGFILE} 2>&1 || true
    #rm -f $verbose /tmp/.X11-unix/.X*
    #rm -f $verbose "$HOME"/.vnc/*"${VDT_INSTANCE_NAME}".pid
    echo "Trapped $?"
    turbo_kill $lockfile &
    #if [[ -n "${VDT_LOGFILE}" ]]; then rm -f $verbose "${VDT_LOGFILE}";fi
    #if [[ -n "${lockfile}" ]]; then rm -f $verbose "${lockfile}";fi
    # Unset all VDT variables.
    for ev in $(compgen -A variable | grep ^VDT );do
        unset "$ev"
    done
        
    rm -fvr "/tmp/.X$display_port-lock"
    rm -fvr "/tmp/.ICE$display_port-lock"

    while [[ "$(fuser $VDT_SOCKET_PORT/tcp 2>/dev/null | wc -w)" -gt 0 ]];do
        kill -9 "$(fuser $VDT_SOCKET_PORT/tcp 2>/dev/null | awk '{ print $1 }')"
    done
    pkill --signal 9 -P $$ > /dev/null 2>&1 
    exit 0

}
cleanup_nice() {
    cleanup || return 0
}

lennut(){
    # Todo: Allow multiple attempts.
    echo "Opening reverse tunnel to '${VDT_TUNNEL_HOST}'"
    ssh -vfNT -o ExitOnForwardFailure=yes -R ${VDT_SOCKET_PORT}:localhost:${VDT_SOCKET_PORT} ${VDT_TUNNEL_HOST}
    tunnel_pid="$!"
    sleep 5
    # if [[ "$(ps -o s -h -p $tunnel_pid)"! = [SR] ]];then
    #     echo "Failed to open tunnel from $(hostname)"
    #     exit 1
    # fi   
}

main(){
    initialize
    set_env
    create_vnc
    
    return 0
}
trap cleanup INT ERR SIGINT SIGTERM

main "$@"