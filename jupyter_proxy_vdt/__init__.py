from curses.panel import version
import os
import subprocess
import pkg_resources
from pkg_resources import resource_filename
from pathlib import Path

def setup_jupyter_proxy_vdt():

    pkg_path = "jupyter_proxy_vdt"
    icon_path = resource_filename(pkg_path, "crap_icon.svg")
    wrapper_path = resource_filename(pkg_path, "singularity_wrapper.bash")
    runscript_path = resource_filename(pkg_path, "singularity_runscript.bash") # Is inferred in wrapper.

    pkg_version = pkg_resources.require(pkg_path)[0].version
    launcher_title = f"Virtual Desktop {pkg_version}"
    
    return {
    "command": [wrapper_path, "{port}", "vnc.html?path={base_url}vdt/vnc.html&autoconnect=true&resize=remote"],
    "timeout": 300,
    "environment": {"VDT_BASE_IMAGE": "/opt/nesi/containers/vdt_base/dev_vdt_base.sif"},
    "absolute_url": False,
    "new_browser_tab":True,
        "launcher_entry": {
            "icon_path": icon_path,
            "title": launcher_title,
            "enabled": True
        },
    }
