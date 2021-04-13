import os
import subprocess
import pkg_resources
from pathlib import Path


# def get_singularity_path():
#     """find the path for singularity executable on NeSI"""
#     cmd_result = subprocess.run(
#         "module load Singularity && which singularity",
#         capture_output=True,
#         shell=True,
#         timeout=10,
#     )
#     return cmd_result.stdout.strip().decode()


def setup_vdt():

    def_vdt="/opt/nesi/vdt"
    #def_vdt="/nesi/project/nesi99999/Callum/vdt"

    vdt_root = os.getenv('VDT_ROOT',def_vdt)
    account = os.environ["SLURM_JOB_ACCOUNT"]
    os.environ["LOGLEVEL"] = "DEBUG"

    # # See if can find central install.
    # try:
    #     jupyter_wrapper
    #     #rstudio_password = (home_path / ".rstudio_server_password").read_text()
    # except FileNotFoundError:
    #     # If no.


    jupyter_wrapper = f"{vdt_root}/util/jupyter_proxy_launch.sh"
    icon_path = pkg_resources.resource_filename("vdt_jupyter_proxy", "crap_icon.svg")
    launcher_title = "VirtualDesktop" if "VDT_TEST" in os.environ else "VirtualDesktopTest"

    return {
    'command': [jupyter_wrapper, '{port}', 'vnc.html?path={base_url}vdt/vnc.html?resize=remote?autoconnect=true' ],
    'timeout': 100,
    'absolute_url': False,
    'new_browser_tab':True,
        "launcher_entry": {
            "icon_path": icon_path,
            "title": launcher_title,
            "enabled": True
        },
    }
