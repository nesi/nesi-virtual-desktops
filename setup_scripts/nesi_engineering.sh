#!/bin/bash

# Make nec is sary directories
mkdir -vp "${XDG_DESKTOP_DIR:=$HOME/Desktop}"
mkdir -vp "${XDG_DATA_HOME:=$HOME/.local/share}"
mkdir -vp "${VDT_HOME:=$HOME/.vdt}"

create_icon(){
    name=$1
    # Path to desktop entry
    de_name="${name//[^a-zA-Z0-9]/}"
    # Add icon to desktop, and to applications list
cat << EOF | tee "${XDG_DESKTOP_DIR}/${de_name}.desktop" > "${XDG_DATA_HOME}/${de_name}.desktop"
[Desktop Entry]
Type=Application
Exec=${2}
Icon=${3}
Name=${name}
Terminal=false
Categories=Engineering
EOF

chmod 760 -v "${XDG_DESKTOP_DIR}/${de_name}.desktop" "${XDG_DATA_HOME}/${de_name}.desktop"

IFS=',' read -r -a fileassoc <<< ${5}
for f in "${fileassoc[@]}";do
    xdg-mime default "${de_name}.desktop" $f
done

}

create_icon "MATLAB 2019b" "matlab" "/opt/nesi/share/MATLAB/R2019b/bin/glnxa64/cef_resources/matlab_icon.png" "text/m,application/mat"
create_icon "CFX5" "cfx5launch" "/opt/nesi/share/ANSYS/v202/Addins/Images/CFX.ico"
create_icon "Fluent" "fluent" "/opt/nesi/share/ANSYS/v202/commonfiles/images/workbench.ico"
create_icon "ANSYS Workbench 2020R2" "runwb2" "/opt/nesi/share/ANSYS/v202/commonfiles/images/workbench.ico"
create_icon "ABAQUS 2020" "abaqus cae" "/opt/nesi/share/ABAQUS/2020/linux_a64/CAEresources/graphic/icons/icoR_application.png"
create_icon "COMSOL 15.5" "comsol" "/opt/nesi/share/COMSOL/comsol155/multiphysics/bin/glnxa64/comsol.png"

#if vdtrc doesn't exist, create it.
if [ ! -f ${VDT_HOME}/vdtrc.sh ];then
    echo "#!/bin/bash" > "${VDT_HOME}/vdtrc.sh"
fi

# Add required module commands.
cat << EOF >> ${VDT_HOME}/vdtrc.sh
module load ANSYS/2020R2
module load COMSOL/5.5
module load ABAQUS/2020
module load MATLAB/2019b
module load OpenFOAM
EOF

chmod 760 -v "${VDT_HOME}/vdtrc.sh"