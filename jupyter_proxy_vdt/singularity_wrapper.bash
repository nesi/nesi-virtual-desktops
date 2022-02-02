#!/usr/bin/env bash
set -eu -o pipefail


usage(){
	cat <<EOF
Help                                                                         #
    Runscript, identical in purpose to %runscript inside container.
    Starts VNC server pointing to noVNC. Port redirected with websockify.
Usage
   ./singularity_wrapper.bash [-h] [--help] socketport
Arguments
   socketport: Local port that Websockify will forward to.
Global:
   VDT_ROOT                        script directory.
   VDT_BASE_IMAGE                  ${VDT_ROOT}/sif
   VDT_RUNSCRIPT                   ${VDT_ROOT}/util/singularity_runscript.bash
   VDT_GPU                         ""
   VDT_OVERLAY                     "FALSE"
   VDT_OVERLAY_FILE                ${XDG_DATA_HOME}/vdt/image_overlay
   VDT_OVERLAY_COUNT               10000
   VDT_OVERLAY_BS                  1M
   LOGLEVEL                        "INFO"
   SINGULARITY_BIND                ""
   SINGULARITYENV_LD_LIBRARY_PATH  $LD_LIBRARY_PATH
   SINGULARITYENV_PATH             $PATH
Global(Inherited by runscript):
   VDT_WEBSOCKOPTS                 ""
   VDT_VNCOPTS                     ""
Config:
    If there is a bash script located at "${XDG_CONFIG_HOME}/vdt/post.bash", this will be sourced.
    This is to allow control over environment even if user cannot change command execution.
EOF
}

if [ -x "${XDG_CONFIG_HOME:=$HOME/.conf}/vdt/pre.bash" ]; then
    source "${XDG_CONFIG_HOME:=$HOME/.conf}/vdt/pre.bash"
fi

# Parse flags
# TODO: Maybe have other paramters flaggable.
params=""
while (("$#")); do
    case "$1" in
    -h | --help)
        usage && exit 0
        shift
        ;;
    *)
        params="$params $1"
        shift
        ;;
    esac
done
eval set -- "$params"

if [[ $# -le 0 ]]; then
    echo "Not enough inputs." && usage && exit 1
fi

if (($1 < 1024 || $1 > 65535)); then
    echo "  socket-port must be between 1024 and 65525. (Not '$1')" && usage && exit 1
    exit 1
fi

# Load / unload required modules.
module purge # > /dev/null  2>&1
module unload XALT -q
module load Python Singularity/3.8.5 -q

# Set default env variables.
VDT_ROOT="${VDT_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"}"
echo VDT_ROOT
#VDT_BASE_IMAGE="${VDT_BASE_IMAGE:-"${VDT_ROOT}/sif"}"
VDT_BASE_IMAGE="/opt/nesi/containers/vdt_base/dev_vdt_base.sif"
VDT_RUNSCRIPT="${VDT_RUNSCRIPT:-"${VDT_ROOT}/singularity_runscript.bash"}"
VDT_OVERLAY="${VDT_OVERLAY:-"FALSE"}"
VDT_GPU="${VDT_GPU:-"FALSE"}"

# Overlay specific variables.
VDT_OVERLAY_FILE="${VDT_OVERLAY_FILE:-"${XDG_DATA_HOME:=$HOME/.conf}/vdt/image_overlay"}"
VDT_OVERLAY_COUNT="${VDT_OVERLAY_COUNT:-"10000"}"
VDT_OVERLAY_BS="${VDT_OVERLAY_BS:-"1M"}"

LOGLEVEL="${LOGLEVEL:-"INFO"}"

# Check validity of SIF
# If pointing to directory, use sif in there.
echo "$VDT_BASE_IMAGE"
if [ -d ${VDT_BASE_IMAGE} ]; then
    echo "VDT_BASE_IMAGE is directory, looking for .sif"
    VDT_BASE_IMAGE="${VDT_BASE_IMAGE}/*.sif"
    # TODO only works for dirs with 1 sif
fi
# Check sif is valid
if [[ ! -x ${VDT_BASE_IMAGE} ]]; then
    echo "'${VDT_BASE_IMAGE}' is not a valid container"
    exit 1
fi

# TODO: Should check if GPU avail first
if [[ ${VDT_OVERLAY} == "TRUE" ]];then
    module load CUDA
fi

# Bind minimal paths
export SINGULARITY_BIND="${SINGULARITY_BIND:-\
"/home,\
/etc/hosts,
/etc/opt/slurm,\
/var/run/munge,\
/opt/slurm,\
/opt/nesi,\
/scale_wlg_persistent,\
/scale_wlg_nobackup,\
/nesi,\
/cm,\
/var/lib/sss/mc,\
/opt/nesi,\
/nesi/project,\
/scale_wlg_persistent/filesets/project,\
/nesi/nobackup,\
/scale_wlg_nobackup/filesets/nobackup,\
${VDT_ROOT}"}"

export SINGULARITYENV_LD_LIBRARY_PATH="${SINGULARITYENV_LD_LIBRARY_PATH:-$LD_LIBRARY_PATH}"
export SINGULARITYENV_PATH=${SINGULARITYENV_PATH:-$PATH}
unset SLURM_EXPORT_ENV

# Pass along variables.
for ev in "VDT_WEBSOCKOPTS" "VDT_VNCOPTS"; do
    [ -z "${ev}" ] && export "SINGULARITYENV_$ev"="${!ev}"
done

# Create conf and data dirs.
mkdir -vp   "${XDG_DATA_HOME:-$HOME/.local/share}/vdt" \
            "${XDG_DATA_HOME:-$HOME/.conf}/vdt"

# Build command.
if [[ $LOGLEVEL = "DEBUG" ]]; then
    cmd="singularity --debug shell"
else
    cmd="singularity exec"
fi

if [[ ${VDT_OVERLAY} == "TRUE" ]]; then
    if [ ! -f "${OVERLAY_FILE}" ]; then
        # Run mkfs command within container
        singularity exec "${VDT_BASE_IMAGE}" bash -c " \
        mkdir -p overlay_tmp/upper overlay_tmp/work && \
        dd if=/dev/zero of=${VDT_OVERLAY_FILE} count=${VDT_OVERLAY_COUNT} bs=${VDT_OVERLAY_BS} && \
        mkfs.ext3 -d overlay_tmp ${VDT_OVERLAY_FILE} && \
        rm -rf overlay_tmp"
    fi
    cmd="${cmd} --overlay ${VDT_OVERLAY_FILE}"
fi

cmd="${cmd} ${VDT_BASE_IMAGE} ${VDT_RUNSCRIPT} ${1}"

echo "$cmd"
${cmd}
