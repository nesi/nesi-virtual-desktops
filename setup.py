from setuptools import setup, find_packages
from setuptools.command.install import install
import os
import subprocess


class InstallCommand(install):
    user_options = install.user_options + [
        ('setup=', None, "Additional setup steps")
    ]

    def initialize_options(self):
        install.initialize_options(self)
        self.setup = None

    def finalize_options(self):
        install.finalize_options(self)

    def run(self):
        if self.setup:
            avail_setup=[]
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

        install.run(self)

setup(
    name="vdt_jupyter_proxy",
    version="2.4.0",
    description="launch vdt from jupyterproxy",
    url="git-repo-here",
    packages=find_packages(),
    python_requires=">3.8",
    package_data={"vdt_jupyter_proxy": ["crap_icon.svg"]},
    entry_points={
        "jupyter_serverproxy_servers": ["vdt = vdt_jupyter_proxy:setup_vdt"]
    },
    cmdclass={
        'install': InstallCommand,
    },
    install_requires=["jupyter-server-proxy"],
)
