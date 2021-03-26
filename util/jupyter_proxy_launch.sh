#!/bin/bash
export VDT_ROOT="${VDT_ROOT:-"$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)")"}"
export VDT_SOCKET_PORT=${1}
export VDT_HOME=${VDT_HOME:-$HOME/.vdt}
export VDT_BASE_IMAGE="${VDT_BASE_IMAGE:-"${VDT_ROOT}/sif"}"


if [ -d ${VDT_BASE_IMAGE} ]; then
    debug "VDT_BASE_IMAGE is directory, looking for .sif"
    VDT_BASE_IMAGE="${VDT_BASE_IMAGE}/*.sif"
fi
if [ ! -x ${VDT_BASE_IMAGE} ]; then
    error "'${VDT_BASE_IMAGE}' is not a valid container"
fi 

# Create a temporary index.html file, bind over existing one.
# Sets parameter for noVNC to point to correct websocket path. 
mkdir -p "${VDT_HOME}"
temp_index_html=$(mktemp "$VDT_HOME/XXX")
echo "<meta http-equiv=\"refresh\" content=\"0; URL='${2}'\"/>" > "$temp_index_html"

export SINGULARITY_BINDPATH="$SINGULARITY_BINDPATH,${temp_index_html}:/opt/noVNC/index.html"
"$VDT_ROOT/util/singularity_wrapper.sh" run "${VDT_BASE_IMAGE}"

# Remove tmp file
rm ${temp_index_html}   