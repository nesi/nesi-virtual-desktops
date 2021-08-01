#!/bin/bash -e

# Because I am lazy. - Callum
# Same as other script except different shub repo.


if [[ $# -lt 1 ]];then echo "Not enough args"; exit 1;fi

module load Singularity/3.8.0 Python
module unload XALT
wosif=$(basename ${1%.*})

export SINGULARITY_TMPDIR=/tmp
export SINGULARITY_CACHEDIR=/tmp

chmod 700 -R .${wosif}.sif & rm -rf .${wosif}.sif && mv ${wosif}.sif .${wosif}.sif || : 

if [ "$USER" == "nesi-apps-admin" ];then
    cp /nesi/project/nesi99999/Callum/vdt/sif/vdt_base.sif .
    chmod a+rx -v *.sif
else 
    echo "Go here 'https://cloud.sylabs.io/library' and reset cache"
    singularity -q build -r ${wosif}.sif $1
fi
#for arg in $@; do 

#f [[ -f $arg]]; do

# stat -c "%Y" $arg


#wosif=$(basename ${1%.*})
#echo $wosif
#exit 
#rm -f ".${1}"
#singularity build ".${1}"  "shub://nesi/${wosif/_/:}"
#rm -f "${1}"
#mv ".${1}" "${1}"
#rm -f ".${1}"
#echo "Done!"

#image_path="$(dirname "$0")"
#for sif in ${image_path}/*.sif; do
#	name=$(basename $sif)
#	echo $name
#	singularity build "${image_path}/${name}_"  "shub://nesi/nesi-singularity-recipes:${name%.*}" && \
#	mv -v "${image_path}/${name}_" "${image_path}/${name}"
#done
