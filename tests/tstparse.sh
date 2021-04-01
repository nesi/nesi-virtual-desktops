#!/bin/bash -e


while read -r line;do
    [[ ${line} =~ ^\#.* ]] && continue
    mapfile linearray < <(xargs -n1 <<<"$line")
    #declare -a inputarray=( $() )
    if [ -n "${linearray[0]}" ];then
        module load ${linearray[0]}
    fi
    name=${linearray[1]}
    # Path to desktop entry
    de_name="$HOME/Desktop/${name//[^a-zA-Z0-9]/}.desktop"

    [ -e "$de_name" ] && continue
cat << EOF > ${de_name}
[Desktop Entry]
Type=Application
Exec=${linearray[2]}
Icon=${linearray[3]}
Name=${name}
EOF
    chmod 760 "${de_name}"
done < ../util/setup.conf