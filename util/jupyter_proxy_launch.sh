#!/bin/bash
export VDT_ROOT="${VDT_ROOT:-"$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)")"}"
export VDT_SOCKET_PORT=${1}
export VDT_HOME=${VDT_HOME:-"$HOME/.vdt"}
export VDT_BASE_IMAGE="${VDT_BASE_IMAGE:-"${VDT_ROOT}/sif"}"
#export VDT_LOGFILE=${VDT_LOGFILE:-"$(tty)"}

export LOGLEVEL=DEBUG

module purge  # > /dev/null  2>&1
module unload XALT/NeSI -q
module load Python Singularity/3.7.1 -q 

module load CUDA

echo "Using port:${1} and basepath:${2}"

if [ -d ${VDT_BASE_IMAGE} ]; then
    echo  "VDT_BASE_IMAGE is directory, looking for .sif"
    VDT_BASE_IMAGE="${VDT_BASE_IMAGE}/*.sif"
fi
if [ ! -x ${VDT_BASE_IMAGE} ]; then
    echo "'${VDT_BASE_IMAGE}' is not a valid container"
    exit 1
fi 

# Create a temporary index.html file, bind over existing one.
# Sets parameter for noVNC to point to correct websocket path. 
mkdir -p "${VDT_HOME}"
temp_index_html=$(mktemp "$VDT_HOME/XXX")

# Maybe could be external css
cat << EOF > "$temp_index_html"
<head>
<style>
#throbber {
  position: absolute;
  left: 50%;
  top: 50%;
  z-index: 1;
  width: 120px;
  height: 120px;
  margin: -76px 0 0 -76px;
  border: 16px solid #f3f3f3;
  border-radius: 50%;
  border-top: 16px solid #3498db;
  -webkit-animation: spin 2s linear infinite;
  animation: spin 2s linear infinite;
}
@-webkit-keyframes spin {
  0% { -webkit-transform: rotate(0deg); }
  100% { -webkit-transform: rotate(360deg); }
}
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
.animate-bottom {
  position: relative;
  -webkit-animation-name: animatebottom;
  -webkit-animation-duration: 1s;
  animation-name: animatebottom;
  animation-duration: 1s
}
@-webkit-keyframes animatebottom {
  from { bottom:-100px; opacity:0 } 
  to { bottom:0px; opacity:1 }
}
@keyframes animatebottom { 
  from{ bottom:-100px; opacity:0 } 
  to{ bottom:0; opacity:1 }
}
</style>
<script>
function onFrameLoad() {
  document.getElementById("throbber").style.display = "none";
  document.getElementById("vdt").style.display = "block";
};
</script>
</head>
<div id="throbber"></div>
<iframe id="vdt" src='${2}' onload="onFrameLoad(this)" style="display:none,position:fixed; top:0; left:0; bottom:0; right:0; width:100%; height:100%; border:none; margin:0; padding:0; overflow:hidden; z-index:999999;">
    <h1>insert throbber here</h1>
</iframe>
EOF

# cat << EOF > "$temp_index_html"
# <script>
# function onFrameLoad() {
#   alert('myframe is loaded');
# };
# </script>
# <iframe src='${2}' onload="onFrameLoad(this)" style="position:fixed; top:0; left:0; bottom:0; right:0; width:100%; height:100%; border:none; margin:0; padding:0; overflow:hidden; z-index:999999;">
#     <h1>insert throbber here</h1>
# </iframe>
# EOF

#echo "<meta http-equiv=\"refresh\" content=\"0; URL='${2}'\"/>" 

export VDT_WEBSOCKOPTS="--verbose " #--timeout=90"
export SINGULARITY_BINDPATH="$SINGULARITY_BINDPATH,${temp_index_html}:/opt/noVNC/index.html"
"$VDT_ROOT/util/singularity_wrapper.sh" run "${VDT_BASE_IMAGE}"

# Remove tmp file
rm ${temp_index_html}   