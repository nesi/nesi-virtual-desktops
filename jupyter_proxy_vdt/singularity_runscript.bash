#!/bin/bash -e
set -ev -o pipefail

################################################################################
# Help:                                                                      
#     Runscript, identical in purpose to %runscript inside container.
#     Starts VNC server pointing to noVNC. Port redirected with websockify.
#
# Usage:
#     ./singularity_runscript.bash  socketport  localhost
# Arguments:
#     socketport: Local port that Websockify will forward to.
# Global:
#     PATH
#     CPATH
#     LD_LIBRARY_PATH
#         Paths to be appended.
#     EBROOTCUDA = ""
#         If set indicated CUDA loaded by LMOD, will add required CUDA paths.
#     XDG_DATA_HOME = ${HOME}/.local/share
#         Data files, following XDG specification.
#     XDG_CONFIG_HOME = ${HOME}/.config
#         Data files, following XDG specification.
#     VDT_WEBSOCKOPTS = "-wm xfce4-session -autokill -securitytypes TLSNone,X509None,None"
#         Additional options to pass to websockify.
#         See https://linux.die.net/man/1/websockify
#     VDT_VNCOPTS = ""
#         Additional options to pass to vncserver.
#         See https://linux.die.net/man/1/vncserver
# Config:
#     If there is a bash script located at "${XDG_CONFIG_HOME}/vdt/post.bash", this will be sourced.
#     This is to allow control over environment even if user cannot change command execution.
#################################################################################

if (($# < 1)); then
    echo "Not enough inputs." && exit 1
fi

env

if [ -f "${XDG_CONFIG_HOME:=$HOME/.conf}/vdt/post.bash" ]; then
    # Fix permissions if required.
    if [ ! -x "${XDG_CONFIG_HOME:=$HOME/.conf}/vdt/post.bash" ]; then
        chmod 700 "${XDG_CONFIG_HOME:=$HOME/.conf}/vdt/post.bash"
    fi
    source "${XDG_CONFIG_HOME:=$HOME/.conf}/vdt/post.bash"
fi

# Append Paths
export PATH="$PATH:/opt/slurm/bin" #:/opt/nesi/vdt/bin"
export CPATH="$CPATH:/opt/slurm/include"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/slurm/lib64:/opt/slurm/lib64/slurm"

# Set defaults for globals
export VDT_WEBSOCKOPTS=${VDT_WEBSOCKOPTS:-"--web /opt/noVNC"}
export VDT_VNCOPTS=${VDT_VNCOPTS:-"-wm xfce4-session -autokill -securitytypes TLSNone,X509None,None"}

# CUDA specific.
if [[ -n ${EBROOTCUDA} ]]; then
    export LD_LIBRARY_PATH="/cm/local/apps/cuda/libs/current/lib64:$EBROOTCUDA/lib64:$EBROOTCUDA/extras/CUPTI/lib64:$EBROOTCUDA/nvvm/lib64:$LD_LIBRARY_PATH"
    export PATH="$EBROOTCUDA:$EBROOTCUDA/nvvm/bin:$EBROOTCUDA/bin:/cm/local/apps/cuda/libs/current/bin:/cm/local/apps/cuda/libs/current/lib64:$PATH"
fi

# Find free port.
vdt_display_port="$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')"

# Start websockify and vncserver.
/opt/websockify/run ${VDT_WEBSOCKOPTS} localhost:${1} :$((vdt_display_port + 5900)) &
/opt/TurboVNC/bin/vncserver ${VDT_VNCOPTS} :${vdt_display_port}

# TODO: Proccess suicide pact
wait
