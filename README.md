[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/4906)
# nesi-virtual-desktops

## Usage
### Basic
See [Connecting to a Virtual Desktop](https://support.nesi.org.nz/hc/en-gb/articles/360001600235-Connecting-to-a-Virtual-Desktop).
### Through JupyterHub
Click the button ya dummy.
#### Installation
`pip install --user git+https://github.com/nesi/nesi-virtual-desktops --install-option="--setup=engineering"`

  ##### Setuptools install options
  Setuptools arguments can be invoked when using `pip` with the `--install-option` flag.
  e.g. `pip install --user 
  * ```--setup=[script1],[script2],...```
  Scripts can be placed in `setup_scripts` to set up certain 'flavors' of desktop.
  Takes comma delimited list of scripts. If script exists in `setup_scripts` that script will be run post installation.
   e.g. `--setup=nesi,nesi_engineering` will run `./setup_scripts/nesi.sh` then `./setup_scripts/nesi.sh` 

#### Unstallation
`pip uninstall vdt-jupyter-proxy`

## Files
```
vdt/
├── bin/
│   ├── vdt
│   ├── vdt_clean
│   ├── vdt_kill
│   ├── vdt_list
│   ├── vdt_shell
│   └── vdt_start
├── dep/
│   └── nesi_websockify.patch
├── setup_scripts/
│   ├── nesi_engineering.sh
│   └── nesi.sh
├── sif/
│   ├── rebuild.sh
│   └── vdt_base.def
├── tests/
│   └── test.sh
├── util/
│   ├── common.sh
│   ├── jupyter_proxy_launch.sh
│   ├── singularity_runscript.sh
│   └── singularity_wrapper.sh
├── vdt_jupyter_proxy/
│   ├── __init__.py
│   └── crap_icon.svg
├── setup.py
├── vdt
└── README.md
```

### `bin/`
For terrible code that should be thrown away.
User commands. Elaborate here maybe.
From mostly dep'd non-jupyter use.
### `dep/`
Dependencies. When developing, have copies of them here. 
#### `nesi_websockify.diff`
A patchfile used during container build.
### `setup_scripts/`
Optional scripts designed to be run at first time setup.
#### `nesi.sh`
Adds some applications and symlinks to user projects.
#### `nesi_engineering.sh`
Engineering flavour desktop.
### `sif/`
For singularity stuff. Probably put image here.
#### `rebuild.sh`
Run to rebuild
#### `vdt_base.def` 
Main definition file
### `tests/`
### `util/`
Stuff thats not supposed to be user facing.
#### `singularity_runscript.sh`
Script for singularity %runscript. Launched inside container on startup.
#### `singularity_wrapper.sh`
Wraps container launch, sets bind paths etc.
#### `jupyter_proxy_launch.sh`
Entry point for jupyter proxy.
### `vdt_jupyter_proxy/`
Suff for python setuptools.
### `README.md`
Don't
### `setup.py`
For setuptools
## Enviroment Variables
Any variable starting with `VDT_` will be passed to the container during start.
However, unlike with `SINGULARITYENV_` the prefix will be kept. 
`SINGULARITYENV_ENV`  ->  `ENV` 

`DT_ENV`  ->  `VDT_ENV`

| ENV_VAR  | Default | Purpose | Set/Referenced |
| ------------- | ------------- | ------------- | ------------- |
| VDT_LOGFILE  | `"/dev/null"` | Location of logfile. | `vncserver -log`
| VDT_ROOT  |  | Location of this repo. | |
| VDT_HOME | `"$HOME/.vdt"` | | |
| VDT_SETUP |`$VDT_HOME/vdt_setup.conf`| Location of setup file. ||
| VDT_LOCKFILES | `"$VDT_ROOT/lockfiles"` | dep |
| VDT_LOCKFILE | `"$VDT_LOCKFILES/"` | dep |
| VDT_TEMPLATES | `"$VDT_ROOT/templates"` | dep|||
| VDT_BASE | `"default"` | | dep |||
| VDT_INSTANCE_NAME | `"${VDT_BASE}_${USER}"` | dep |
| VDT_SOCKET_PORT | | Forwarded port used to connect to websockify. | Set by user |
| VDT_DISPLAY_PORT | Random nubmer between 1100 and 2000 | Display port used by vnc. |
| VDT_WEBSOCKOPTS | | Additional options to pass to websockify. |
| VDT_VNCOPTS | | Additional options to pass to vnc ||

## Other Enviroment Variables

| ENV_VAR  | Default | Purpose | Set/Referenced |
| ------------- | ------------- | ------------- | ------------- |
| XDG_CONFIG_HOME |`$HOME/.config` | Location of desktop setup. | 


## Notes for supporting on Mahuika

This repo is in `/opt/nesi/vdt`


~~Currently storing all `.sif` files in `/opt/nesi/containers/images`, `image` in template should link here.~~

Run `rebuild.sh` to update. e.g. `rebuild.sh nesi-virtual-desktops_eng.sif`. 


## Testing
git clone {this}
cd {this}
export VDT_ROOT=$PWD
export VDT_TEST=True
pip install --user .
Set to use local directory.
