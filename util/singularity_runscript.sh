#!/bin/bash -e
set -eo pipefail

# Set paths
export PATH="$PATH:/opt/slurm/bin:/opt/nesi/vdt/bin"
export CPATH="$CPATH:/opt/slurm/include"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/slurm/lib64:/opt/slurm/lib64/slurm"

# CUDA specific.
if [[ -n ${EBROOTCUDA} ]];then
    export LD_LIBRARY_PATH="/cm/local/apps/cuda/libs/current/lib64:$EBROOTCUDA/lib64:$EBROOTCUDA/extras/CUPTI/lib64:$EBROOTCUDA/nvvm/lib64:$LD_LIBRARY_PATH"
    export PATH="$EBROOTCUDA:$EBROOTCUDA/nvvm/bin:$EBROOTCUDA/bin:/cm/local/apps/cuda/libs/current/bin:/cm/local/apps/cuda/libs/current/lib64:$PATH"
fi

# Find free port.
VDT_DISPLAY_PORT="$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')"
/opt/websockify/run ${VDT_WEBSOCKOPTS} --web /opt/noVNC localhost:$VDT_SOCKET_PORT :$((VDT_DISPLAY_PORT+5900)) &

/opt/TurboVNC/bin/vncserver ${VDT_VNCOPTS} -wm xfce4-session -autokill -securitytypes TLSNone,X509None,None ":${VDT_DISPLAY_PORT}"    
wait
#export XDG_DATA_DIRS="$XDG_DATA_DIRS:$EBROOTCUDA/share"




