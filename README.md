[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/4906)
# nesi-virtual-desktops

## Usage
### Basic
See [Connecting to a Virtual Desktop](https://support.nesi.org.nz/hc/en-gb/articles/360001600235-Connecting-to-a-Virtual-Desktop).
### Through JupyterHub
#### Installation
`pip install --user git+https://github.com/nesi/nesi-virtual-desktops`
#### Unstallation
`pip uninstall vdt-jupyter-proxy`
#### Usage
Click the button ya dummy.

## Files
```
vdt/
├── bin
│   ├── vdt
│   ├── vdt_clean
│   ├── vdt_kill
│   ├── vdt_list
│   ├── vdt_shell
│   └── vdt_start
├── dep
│   └── nesi_websockify.patch
├── lockfiles/
├── sif
│   ├── rebuild.sh
│   └── vdt_base.def
├── tests
│   └── test.sh
├── util
│   ├── common.sh
│   ├── jupyter_proxy_launch.sh
│   ├── singularity_runscript.sh
│   └── singularity_wrapper.sh
└── README.md
```

### `bin/`
For terrible code that should be thrown away.
User commands. Elaborate here maye.

### `dep/`
Dependencies. When developing, have copies of them here. 
#### `nesi_websockify.diff`
A patchfile used during container build.
### `lockfiles/`
Where lockfiles are currently being put. Should be empty in this repo.

Deprecated

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
All of these variables are passed to the container during start.

### VDT_ROOT

Location of this repo.

### VDT_HOME 

For lockfiles

`"$HOME/.vdt"`

### VDT_LOCKFILES
Location of lockfiles.

`"$VDT_ROOT/lockfiles"`
### VDT_TEMPLATES 
Location of templates. See templates.

`"$VDT_ROOT/templates"`
### VDT_BASE
Selected template.

`"default"`
### VDT_INSTANCE_NAME
Name used for Singularity instance.

`"${VDT_BASE}_${USER}"`
### VDT_LOGFILE
Location of logfile.
Amalgumation of
* Messages from these scripts.
* vncserver -log

`"${VDT_HOME}/${VDT_INSTANCE_NAME}.${remote:-$(hostname)}:${VDT_SOCKET_PORT}.log"}"`
### VDT_SOCKET_PORT
Forwarded port used to connect to websockify. 
Must be input by user.
### VDT_DISPLAY_PORT
Display port used by vnc.
Random nubmer between 1100 and 2000
### VDT_WEBSOCKOPTS
Additional options to pass to websockify.
### VDT_VNCOPTS
Additional options to pass to vnc.

## Other Enviroment Variables
### XDG_CONFIG_HOME
Location of desktop setup.

`"$HOME/.config"`

## Notes for supporting on Mahuika

This repo is in `/opt/nesi/vdt`


~~Currently storing all `.sif` files in `/opt/nesi/containers/images`, `image` in template should link here.~~

Run `rebuild.sh` to update. e.g. `rebuild.sh nesi-virtual-desktops_eng.sif`. 
