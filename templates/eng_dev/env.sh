#!/bin/bash -e
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cp ${V} -rn "$ROOT"/Desktop/ "$HOME"

vecho () {
    # For verbose print.
    if [[ $VERBOSE ]]; then
        echo "$@"
    fi
}

# COMSOL
licence_dir="/opt/nesi/share/COMSOL/Licenses/*"
FOUND_LIC=""
export SINGULARITY_BINDPATH="$SINGULARITY_BINDPATH,/opt/nesi/share/COMSOL"
found="0"
for licence in  $licence_dir;do
    if [ "${licence: -4}" == ".lic" ]; then
        if [ -r "$licence" ];then
            export SINGULARITYENV_LMCOMSOL_LICENSE_FILE="${licence}"
            found="1"
            export FOUND_LIC="${FOUND_LIC}COMSOL, "
        fi
    fi
done
if [ "${found}" != "1" ]; then
    echo "No valid licence found for COMSOL. :("
fi
# Special Snowflakes
#ANSYS
# Slightly different file sytax.
# LMD rather than LM

licence_dir="/opt/nesi/share/ANSYS/Licenses/*"
export SINGULARITY_BINDPATH="$SINGULARITY_BINDPATH,/opt/nesi/share/ANSYS"
found="0"
for licence in $licence_dir; do
    if [ "${licence: -4}" == ".lic" ]; then
        if [ -r "$licence" ]; then
            export SINGULARITYENV_ANSYSLMD_LICENSE_FILE="$(sed -ne 's/^SERVER=// p'  $licence)"
            export SINGULARITYENV_ANSOFTD_LICENSE_FILE="$(sed -ne 's/^SERVER=// p' $licence)"
            found="1"
            export FOUND_LIC="${FOUND_LIC}ANSYS, "
        fi
    fi
done
if [ "${found}" != "1" ]; then
    echo "No valid licence found for ANSYS. :("
fi
# ABAQUS
# Has to have an '@' symbol for some reason.

licence_dir="/opt/nesi/share/ABAQUS/Licenses/*"
export SINGULARITY_BINDPATH="$SINGULARITY_BINDPATH,/opt/nesi/share/ABAQUS"
found="0"
for licence in  $licence_dir; do
    if [ "${licence: -4}" == ".lic" ]; then
        if [ -r "$licence" ];then
            export "SINGULARITYENV_ABAQUSLM_LICENSE_FILE=@$(awk '{print $2}' $licence)"
            found="1"
            export FOUND_LIC="${FOUND_LIC}ABAQUS, "
        fi
    fi
done
if [ "${found}" != "1" ]; then
    echo "No valid licence found for ABAQUS. :("
fi
    licence_dir="/opt/nesi/share/MATLAB/Licenses/*"
export SINGULARITY_BINDPATH="$SINGULARITY_BINDPATH,/opt/nesi/share/MATLAB"

found="0"

for licence in $licence_dir; do
    if [ "${licence: -4}" == ".lic" ]; then
        if [ -r "$licence" ]; then
            export SINGULARITYENV_MLM_LICENSE_FILE=$licence
            found="1"
            export FOUND_LIC="${FOUND_LIC}MATLAB, "
        fi
    fi
done
if [ "${found}" != "1" ]; then
    echo "No valid licence found for MATLAB. :("
fi
if [ ! -z "$FOUND_LIC" ]; then
    echo "Valid licence files found for ${FOUND_LIC}"
fi

vecho $SINGULARITY_BINDPATH


