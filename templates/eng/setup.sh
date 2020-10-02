#!/bin/bash -a


root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$root/../../lic.sh"

mk_icn(){
    file="${XDG_DESKTOP_DIR:=$HOME/Desktop}/${1}.desktop"
    mkdir -p "$XDG_DESKTOP_DIR"
    shift
    if  [[ -f  $file ]];then return;fi
    echo "[Desktop Entry]" > "${file}"
    echo "Type=Application" >> "${file}"
    for line in "$@";do
        echo "${line}" >> "${file}"
    done
    chmod u+x "$file"
}

export BROWSER=firefox
mkdir -vp ${XDG_DESKTOP_DIR:=$HOME/Desktop}


mk_icn "Terminal" \
"Exec=exo-open --launch TerminalEmulator" \
"Name=Terminal Emulator" \
"Icon=utilities-terminal"

if [[ -n "$MLM_LICENSE_FILE" ]];then
mk_icn "MATLAB_2019b" \
"Exec=/opt/nesi/share/MATLAB/R2019b/bin/matlab" \
"Name=MATLAB 2019b" \
"Icon=/opt/nesi/share/MATLAB/R2019b/bin/glnxa64/cef_resources/matlab_icon.png"

export PATH="/opt/nesi/mahuika/MATLAB/R2019b/bin:$PATH"
export PATH="/opt/nesi/mahuika/MATLAB/R2019b/etc/glnxa64:$PATH"
export _JAVA_OPTIONS="-Xmx256m"
fi
if [[ -n "$LMCOMSOL_LICENSE_FILE" ]];then
mk_icn "COMSOL_5.5" \
"Exec=/opt/nesi/share/COMSOL/comsol155/multiphysics/bin/comsol" \
"Icon=/opt/nesi/share/COMSOL/comsol155/multiphysics/bin/glnxa64/comsol.png" \
"Name=COMSOL 5.5"
fi
if [[ -n "$ANSYSLMD_LICENSE_FILE" ]];then
mk_icn "ANSYSwb" \
"Exec=/opt/nesi/share/ANSYS/v201/Framework/bin/Linux64/runwb2" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=ANSYS Workbench" 
fi

if [[ -n "$ABAQUSLM_LICENSE_FILE" ]];then
mk_icn "ABAQUScae" \
"Exec=/opt/nesi/share/ABAQUS/2019/SIMULIA/Commands/abaqus cae -mesa" \
"Icon=/opt/nesi/share/ABAQUS/2019/SimulationServices/V6R2019x/CAADoc/linux_a64.doc/English/CAAIcons/images/logoabaqus.png" \
"Name=ABAQUS 2019"
fi