from setuptools import setup, find_packages
from setuptools.command.install import install
import os
import subprocess

module_out = (
    subprocess.check_output(
        'module -t avail | grep "^R/" | tail -n +2',
        stderr=subprocess.STDOUT,
        shell=True,
    )
    .decode("utf-8")
    .strip()
)


class InstallCommand(install):
    user_options = install.user_options + [("setup=", None, "Additional setup steps")]

    def initialize_options(self):
        install.initialize_options(self)
        self.setup = None

    def finalize_options(self):
        install.finalize_options(self)

    def run(self):
        if self.setup:
            avail_versions = []
            avail_setup = []
            for file in os.listdir("setup_scripts"):
                if file.endswith(".sh"):
                    avail_setup.append(file[:-3])

            for setup_script in self.setup.split(","):
                if setup_script in avail_setup:
                    print(f"Running '{self.setup}.sh'")
                    subprocess.call(f"./setup_scripts/{setup_script}.sh", shell=True)
                else:
                    print(f"'{setup_script}' is not a valid setup script.")
                    print(f"Valid options are {','.join(avail_setup)}")
        # self.setup
        install.run(self)


setup(
    name="jupyter_proxy_vdt",
    version="3.0.6",
    description="launch vdt from jupyterproxy",
    url="https://github.com/nesi/nesi-virtual-desktops",
    packages=find_packages(),
    python_requires=">3.8",
    package_data={
        "jupyter_proxy_vdt": [
            "crap_icon.svg",
            "singularity_wrapper.bash",
            "singularity_runscript.bash",
        ]
    },
    entry_points={
        "jupyter_serverproxy_servers": [
            "vdt = jupyter_proxy_vdt:setup_jupyter_proxy_vdt"
        ]
    },
    cmdclass={
        "install": InstallCommand,
    },
    install_requires=["jupyter-server-proxy"],
)
