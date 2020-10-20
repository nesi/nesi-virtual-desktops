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
mk_icn "MATLAB_2018b" \
"Exec=module load MATLAB/2018b;matlab" \
"Name=MATLAB 2018b" \
"Icon=/opt/nesi/share/MATLAB/R2018b/bin/glnxa64/cef_resources/matlab_icon.png"
mk_icn "MATLAB_2019b" \
"Exec=module load MATLAB/2019b;matlab" \
"Name=MATLAB 2019b" \
"Icon=/opt/nesi/share/MATLAB/R2019b/bin/glnxa64/cef_resources/matlab_icon.png"
mk_icn "MATLAB_2020a" \
"Exec=module load MATLAB/2020a;matlab" \
"Name=MATLAB 2020a" \
"Icon=/opt/nesi/share/MATLAB/R2020/bin/glnxa64/cef_resources/matlab_icon.png"

fi
if [[ -n "$LMCOMSOL_LICENSE_FILE" ]];then
mk_icn "COMSOL_5.5" \
"Exec=module load COMSOL/5.5;comsol" \
"Icon=/opt/nesi/share/COMSOL/comsol155/multiphysics/bin/glnxa64/comsol.png" \
"Name=COMSOL 5.5"
fi
if [[ -n "$ANSYSLMD_LICENSE_FILE" ]];then
mk_icn "ANSYSsysc2020R1" \
"Exec=module load ANSYS/2020R1;systemcoupling --guiserver" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=ANSYS System Coupling 2020R1" 
mk_icn "ANSYSwb2020R1" \
"Exec=module load ANSYS/2020R1;runwb2" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=ANSYS Workbench 2020R1" 
mk_icn "ANSYScfx2020R1" \
"Exec=module load ANSYS/2020R1;cfx5launch" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=CFX 2020R1" 
mk_icn "ANSYSflu2020R1" \
"Exec=module load ANSYS/2020R1;fluent" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=ANSYS Fluent 2020R1" 
mk_icn "ANSYSwb2019R3" \
"Exec=module load ANSYS/2019R3;runwb2" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=ANSYS Workbench 2019R3" 
mk_icn "ANSYScfx2019R3" \
"Exec=module load ANSYS/2019R3;cfx5launch" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=CFX 2019R3" 
mk_icn "ANSYSflu192" \
"Exec=module load ANSYS/19.2;fluent" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=ANSYS Fluent 19.2"
mk_icn "ANSYSwb192" \
"Exec=module load ANSYS/19.2;runwb2" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=ANSYS Workbench 19.2" 
mk_icn "ANSYScfx192" \
"Exec=module load ANSYS/19.2;cfx5launch" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=CFX 19.2" 
mk_icn "ANSYSflu192" \
"Exec=module load ANSYS/19.2;fluent" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=ANSYS Fluent 19.2"
mk_icn "ANSYSflu192" \
"Exec=module load ANSYS/19.2;fluent" \
"Icon=/opt/nesi/share/ANSYS/v201/commonfiles/images/workbench.ico" \
"Name=ANSYS Fluent 19.2"
fi

if [[ -n "$ABAQUSLM_LICENSE_FILE" ]];then
mk_icn "ABAQUScae" \
"Exec=module load ABAQUS/2019;abaqus cae -mesa" \
"Icon=/opt/nesi/share/ABAQUS/2019/SimulationServices/V6R2019x/CAADoc/linux_a64.doc/English/CAAIcons/images/logoabaqus.png" \
"Name=ABAQUS 2019"
fi
 
# Create links to projects. (max 8)
(find "/nesi/project/" -maxdepth 1 -mindepth 1 -iname "*[0-9]" -writable -type d | head -n 8) | while read -r proj;do
    ln -s "$proj" "$XDG_DESKTOP_DIR/project_$(basename $proj)" 2>/dev/null
done

# Create links to nobackup. (max 8)
(find "/nesi/nobackup/" -maxdepth 1 -mindepth 1 -iname "*[0-9]" -writable -type d | head -n 8) | while read -r proj;do
    ln -s "$proj" "$XDG_DESKTOP_DIR/nobackup_$(basename $proj)" 2>/dev/null
done
