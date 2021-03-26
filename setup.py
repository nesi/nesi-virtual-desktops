from setuptools import setup, find_packages

setup(
    name="vdt_jupyter_proxy",
    version="2.0",
    description="launch vdt from jupyterproxy",
    url="git-repo-here",
    packages=find_packages(),
    python_requires=">3.8",
    package_data={"vdt_jupyter_proxy": ["crap_icon.svg"]},
    entry_points={
        "jupyter_serverproxy_servers": ["vdt = vdt_jupyter_proxy:setup_vdt"]
    },
    install_requires=["jupyter-server-proxy"],
)
