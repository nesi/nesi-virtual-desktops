#!/bin/bash

module purge > /dev/null  2>&1
module load Python Singularity/3.6.1 -q 
module unload XALT/NeSI -q

scriptname="${BASH_SOURCE[0]}"
#desktop="eng_dev"
root="$( cd "$( dirname "${scriptname}" )" >/dev/null 2>&1 && pwd )"    # Location of this script 

if [ "$#" -ne 1 ]; then
    echo "'${scriptname}' expects a port number as input."
    exit 1
fi

# display_port=$(shuf -i 1100-2000 -n 1)
# socket_port=$1

#TOP="$($root/list_vdt | tail -n 1 | awk '{print $1;}')"

#export SINGULARITY_BINDPATH="/run,/etc/machine-id,/opt/nesi,/scale_wlg_persistent/filesets/project,/scale_wlg_nobackup/filesets/nobackup"
#export instance_name="jupyter_vdt_$(hostname)"

# if [[ -f "${root}/${desktop}/env.sh" ]];then
#     source "${root}/${desktop}/env.sh"
# fi

#singularity run --cleanenv --app startvdt "$(readlink -f "$root/$desktop/image")"  :${display_port} && singularity run --cleanenv --app connectvdt "$(readlink -f "$root/$desktop/image")" "${socket_port}" "${display_port}"


#echo $TOP

"${root}/vdt_start" -v -s "${1}"


#exit

#"${root}/start_vdt" "${display_port}" 
#"${root}/connect_vdt" "${display_port}" "${1}"

# vecho () {
#     # For verbose print.
#     if [[ $VERBOSE ]]; then
#         echo "$@"
#     fi
# }
