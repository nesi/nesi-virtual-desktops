#!/bin/bash
export VDT_SOCKET_PORT=${1}
VDT_HOME=${VDT_HOME:-$HOME/.vdt}
mkdir -p "${VDT_HOME}" # Make sure .vdt exist
tmp_indx=$(mktemp "$VDT_HOME/XXX") # Make tmpdir.
echo "<meta http-equiv=\"refresh\" content=\"0; URL='${2}'\"/>" > "$tmp_indx"
wrapper="/home/cwal219/project/containers/vdt_base/wrapper.sh"
container="/home/cwal219/project/containers/vdt_base/containers_latest.sif"

export SINGULARITY_BINDPATH="$SINGULARITY_BINDPATH,${tmp_indx}:/opt/noVNC/index.html"
$wrapper run $container
rm $tmp_indxcd v1906    