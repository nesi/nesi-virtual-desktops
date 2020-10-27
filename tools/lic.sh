#!/bin/bash -ea

get_lic(){ #<path> <env-var> <func>
    for licence in $1; do
        if [ "${licence: -4}" == ".lic" ] && [ -r "$licence" ]; then
            export "$2"="$("${3}" "${licence}")"
            found="${found}${2}\n"
            break
        fi
    done
}
lecho(){ echo "$1"; }
lansys(){ sed -ne 's/^SERVER=// p' "$1"; }
labaqus(){ echo "@$(awk '{print $2}' "$1")" ; }

main(){
    found="Setting licence environment variables:\n"
    
    # get_lic "/opt/nesi/share/COMSOL/Licenses/*" "SINGULARITYENV_LMCOMSOL_LICENSE_FILE" lecho
    # get_lic "/opt/nesi/share/MATLAB/Licenses/*" "SINGULARITYENV_MLM_LICENSE_FILE" labaqus
    # get_lic "/opt/nesi/share/ANSYS/Licenses/*" "SINGULARITYENV_ANSYSLMD_LICENSE_FILE" lansys
    # get_lic "/opt/nesi/share/ANSYS/Licenses/*" "SINGULARITYENV_ANSOFTD_LICENSE_FILE" lansys
    # get_lic "/opt/nesi/share/ABAQUS/Licenses/*" "SINGULARITYENV_ABAQUSLM_LICENSE_FILE" lecho
    # printf '%b' "$found"

    get_lic "/opt/nesi/share/COMSOL/Licenses/*" "LMCOMSOL_LICENSE_FILE" lecho
    get_lic "/opt/nesi/share/MATLAB/Licenses/*" "MLM_LICENSE_FILE" lecho
    get_lic "/opt/nesi/share/ANSYS/Licenses/*" "ANSYSLMD_LICENSE_FILE" lansys
    get_lic "/opt/nesi/share/ANSYS/Licenses/*" "ANSOFTD_LICENSE_FILE" lansys
    get_lic "/opt/nesi/share/ABAQUS/Licenses/*" "ABAQUSLM_LICENSE_FILE" labaqus
    printf '%b' "$found"
}
main
