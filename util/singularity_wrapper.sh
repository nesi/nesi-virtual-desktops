#!/bin/bash

set -eo pipefail

################################################################################
# Help                                                                         #
################################################################################
usage() {
  echo "usage: $0 [socket-port] [bind-path] []"
  echo "  socket-port must be between 1024 and 65525"
  exit 1
  echo
}
#######################################
# Wrapper script, excecutes arguments in singularity image with some standard NeSI bind paths.
#
# Arguments:
#   C
# Inputs Varia Required:
#   SIFPATH: Path to singularity image file. Should be built image of '.def contained int the 'conf' directory.
#            Needs to be absolute path, and bound path
# Env Variables Optional:
#   LOGLEVEL: [DEBUG]
#   SINGULARITY_BINDPATH: Singularity bind path.
#######################################

export VDT_ROOT="${VDT_ROOT:-"$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)")"}"
export VDT_SOCKET_PORT=${1}
export VDT_BASE_IMAGE="${VDT_BASE_IMAGE:-"${VDT_ROOT}/sif"}"

export VDT_RUNSCRIPT="$VDT_ROOT/util/singularity_runscript.sh"

if (( $# < 2 )); then
  usage
fi

if (( $1 < 1024 || $1 > 65535 ));then
  echo "  socket-port must be between 1024 and 65525. (Not '$1')"
  exit 1
fi

# Create Conf and data dirs.
VDT_DATA="${XDG_DATA_HOME:=$HOME/.local/share}/vdt"
VDT_CONF="${XDG_DATA_HOME:=$HOME/.conf}/vdt"

mkdir -vp ${VDT_DATA}
mkdir -vp ${VDT_CONF}

if [ -x "${VDT_CONF}/pre.bash" ]; then
 source "${VDT_CONF}/pre.bash"
fi

if [[ $LOGLEVEL = "DEBUG" ]]; then
  echo "Debug is set! This will significantly slow launch."
fi

# Load / unload required modules.
module purge # > /dev/null  2>&1
module unload XALT -q
module load Python Singularity/3.8.5 -q

# Should check if GPU avail first
module load CUDA

# If pointing to directory, use sif in there.
# TODO only works for dirs with 1 sif
if [ -d ${VDT_BASE_IMAGE} ]; then
  echo "VDT_BASE_IMAGE is directory, looking for .sif"
  VDT_BASE_IMAGE="${VDT_BASE_IMAGE}/*.sif"
fi
# Check sif is valid
if [ ! -x ${VDT_BASE_IMAGE} ]; then
  echo "'${VDT_BASE_IMAGE}' is not a valid container"
  exit 1
fi

# Bind minimal paths
SINGULARITY_BIND='/home'
while read D; do
  if [[ -d $D ]]; then
    SINGULARITY_BIND=$SINGULARITY_BIND,$D
  else
    echo "$D not found."
  fi
done <<EOF
/etc/hosts
/etc/opt/slurm
/var/run/munge
/opt/slurm
/opt/nesi
/scale_wlg_persistent
/scale_wlg_nobackup
/nesi
/cm
/var/lib/sss/mc
/opt/nesi
/nesi/project
/scale_wlg_persistent/filesets/project
/nesi/nobackup
/scale_wlg_nobackup/filesets/nobackup
${VDT_ROOT}"
EOF


export SINGULARITY_BIND
export SINGULARITYENV_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
export SINGULARITYENV_PATH="$PATH"
unset SLURM_EXPORT_ENV

# If environment setup for desktop flavor.
# if [[ -f "${VDT_TEMPLATES}/${VDT_BASE}/pre.sh" ]]; then
#   source "${VDT_TEMPLATES}/${VDT_BASE}/pre.sh"
# fi

if [[ $LOGLEVEL = "DEBUG" ]]; then
  cmd="singularity --debug shell"
else
  cmd="singularity exec"
fi

# Try set up overlay
OVERLAY="FALSE"

if [[ ${OVERLAY} == "TRUE" ]]; then

  export OVERLAY_FILE="$VDT_DATA/image_overlay"

  if [ ! -f "$OVERLAY_FILE" ];then
    export COUNT="10000"
    export BS="1M"

    # Run mkfs command within container
    singularity exec $VDT_BASE_IMAGE bash -c " \
        mkdir -p overlay_tmp/upper overlay_tmp/work && \
        dd if=/dev/zero of=$OVERLAY_FILE count=$COUNT bs=$BS && \
        mkfs.ext3 -d overlay_tmp $OVERLAY_FILE && \
        rm -rf overlay_tmp \
        "
  fi
  cmd="$cmd --overlay $OVERLAY_FILE"
fi


cmd="$cmd $VDT_BASE_IMAGE $VDT_RUNSCRIPT"


#"VDT_SOCKET_PORT" "VDT_DISPLAY_PORT"

echo "$cmd"
${cmd}




# chekenv(){
#     for var in "$@"; do
#         if [[ -z ${!var} ]]; then error "'\$${var}' not set, did you launch this container correctly?";fi 
#     done
# }