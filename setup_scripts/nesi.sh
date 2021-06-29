#!/bin/bash

# Check destop directory exists.
mkdir -vp "${XDG_DESKTOP_DIR:=$HOME/Desktop}"

create_directory_links(){
    # Create links to projects. (max 8)
    read -ra pj <<<$(find "/nesi/project/" -maxdepth 1 -mindepth 1 -iname "*[0-9]" -writable -type d)
    read -ra nb <<<$(find "/nesi/nobackup/" -maxdepth 1 -mindepth 1 -iname "*[0-9]" -writable -type d)

    if [[ $(echo "${pj[@]}" | wc -w) -gt 8 ]];then
        pjd="/_projects"
        mkdir "${XDG_DESKTOP_DIR}${pjd}"
    fi
    if [[ $(echo "${nb[@]}" | wc -w) -gt 8 ]];then
        nbd="/_nobackup"
        mkdir "${XDG_DESKTOP_DIR}${nbd}"
    fi
    for proj in "${pj[@]}";do
        ln -sv "$proj" "${XDG_DESKTOP_DIR}${pjd}/project_$(basename $proj)" 2>/dev/null
    done
    for proj in "${nb[@]}";do
        ln -sv "$proj" "${XDG_DESKTOP_DIR}${nbd}/nobackup_$(basename $proj)" 2>/dev/null
    done
}

create_icon(){
    name=$1
    # Path to desktop entry
    de_name="${name//[^a-zA-Z0-9]/}"
    # Add icon to desktop, and to applications list
cat << EOF > "${XDG_DESKTOP_DIR}/${de_name}.desktop"
[Desktop Entry]
Type=Application
Exec=${2}
Icon=${3}
Name=${name}
Terminal=false
EOF

chmod 760 -v "${XDG_DESKTOP_DIR}/${de_name}.desktop" "${XDG_DATA_HOME}/${de_name}.desktop"

IFS=',' read -r -a fileassoc <<< ${5}
for f in "${fileassoc[@]}";do
    xdg-mime default "${de_name}.desktop" $f
done

}

cat << EOF > "${XDG_DESKTOP_DIR}/support.desktop"
[Desktop Entry]
Encoding=UTF-8
Name=Support Documentation
Type=Link
URL=https://support.nesi.org.nz/hc/en-gb
Icon=text-html
EOF

chmod 760 -v ${XDG_DESKTOP_DIR}/support.desktop

create_directory_links
create_icon "Terminal" "bash -c 'exo-open --launch TerminalEmulator'" "utilities-terminal"

# Try remove action plugin from window. (To stop Maxime logging out >:)
