[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/4906)
# nesi-virtual-desktops

## Usage
### Basic
See [Connecting to a Virtual Desktop](https://support.nesi.org.nz/hc/en-gb/articles/360001600235-Connecting-to-a-Virtual-Desktop).
### Through JupyterHub
Click the button ya dummy.
#### Installation

TODO: Setup scripts.

* `pip install --user git+https://github.com/nesi/nesi-virtual-desktops`

| -  | - |
| ------------- | ------------- |
| Default  | `pip install --user --install-option="--setup=nesi" git+https://github.com/nesi/nesi-virtual-desktops` |
| Engineering  | `pip install --user --install-option="--setup=nesi,nesi_engineering" git+https://github.com/nesi/nesi-virtual-desktops` |

* Restart JupyterLab session if running.
##### Setuptools install options
  Setuptools arguments can be invoked when using `pip` with the `--install-option` flag.
  e.g. `pip install --user 
  * ```--setup=[script1],[script2],...```
  Scripts can be placed in `setup_scripts` to set up certain 'flavors' of desktop.
  Takes comma delimited list of scripts. If script exists in `setup_scripts` that script will be run post installation.
   e.g. `--setup=nesi,nesi_engineering` will run `./setup_scripts/nesi.sh` then `./setup_scripts/nesi.sh` 

##### Installation for Testing
```
git clone https://github.com/nesi/nesi-virtual-desktops.git
cd nesi-virtual-desktops
```
Make changes.
Set debug and install from local.
```
pip install -e --user .
```

#### Unstallation
`pip uninstall vdt-jupyter-proxy`

## Customisation
Most of the customisation of the desktop can be done from within,
panels, desktop, software preferences.
### `pre.bash`
Enviroment set in `singularity_wrapper.bash` can be changed by creating a file `$XDG_CONFIG_HOME/vdt/pre.bash`
Anything you want to run *before* launching the container put in here.
See [Set inside container]().
#### pre.bash
```
export VDT_BASE_IMAGE="~/my_custom_container.sif"  # Use a different image file.
export VDT_RUNSCRIPT="~/my_custom_runscript"  # Use a different runscript.

export OVERLAY="TRUE"
export BROWSER="chrome"         # Desktop session will inherit this.

module load ANSYS/2021R2        # Any modules you want to be loaded in main instance go here.
```


### `post.bash`
Enviroment set in `runscript_wrapper.bash` can be changed by creating a file `$XDG_CONFIG_HOME/vdt/post.bash`

Things you may wish to set here are:
VDT_WEBSOCKOPTS, VDT_VNCOPTS, any changes to the wm enviroment, any changes to path, this include module files.

#### post.bash
```

export VDT_VNCOPTS="-depth 16"  # This will start a 16bit desktop
export BROWSER="chrome"         # Desktop session will inherit this.

module load ANSYS/2021R2        # Any modules you want to be loaded in main instance go here.
```

### Custom container
You can build your own container bootstrapping off `vdt_base.sif`/`rocky8vis.sif` and then overwrite the default by setting `VDT_BASE_IMAGE` in `pre.bash`.

## Files
```
vdt/
├── dep/
│   └── nesi_websockify.patch
├── jupyter_proxy_vdt/
│   ├── __init__.py
│   └── icon.svg
├── setup_scripts/
│   ├── nesi_engineering.sh
│   └── nesi.sh
├── sif/
│   ├── rebuild.sh
│   ├── rocky8.def
│   ├── rocky8vis.def
│   └── vdt_base.def
├── tests/
│   └── test.sh
├── util/
│   ├── singularity_runscript.sh
│   └── singularity_wrapper.sh
├── setup.py
├── CUSTOMISATION.md
└── README.md
```

### `dep/`
Dependencies. When developing, have copies of them here. 
#### `nesi_websockify.diff`
A patchfile used during container build.
### `jupyter_proxy_vdt/`
Suff for python setuptools.
#### `__init__.py`
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
#### `rocky8.def` 
#### `rocky8vis.def` 
#### `vdt_base.def` 
Main definition file

### `sif/skel`
Files to modify during container build.

### `tests/`
### `util/`
Stuff thats not supposed to be user facing.
#### `singularity_runscript.sh`
Script for singularity %runscript. Launched inside container on startup.
#### `singularity_wrapper.sh`
Wraps container launch, sets bind paths etc.
### `README.md`
Don't
### `setup.py`
For setuptools
## Enviroment Variables
Any variable starting with `VDT_` will be passed to the container during start.
However, unlike with `SINGULARITYENV_` the prefix will be kept. 
`SINGULARITYENV_ENV`  ->  `ENV` 

`VDT_ENV`  ->  `VDT_ENV`

| ENV_VAR  | Default | Purpose | Set/Referenced |
| ------------- | ------------- | ------------- | ------------- |
| VDT_ROOT  | wrapper location | Location of this repo. | `singularity_wrapper.bash`|
| VDT_TEMPLATES | `"$VDT_ROOT/templates"` | N/A
| VDT_BASE_IMAGE | `"default"` | dep |||
| VDT_WEBSOCKOPTS | `""` | Additional options to pass to websockify. |
| VDT_VNCOPTS | `""` | Additional options to pass to vnc ||
| VDT_RUNSCRIPT | `${VDT_ROOT}/util/singularity_runscript.bash` | runscript to use. |
| VDT_GPU | `""` | Whether to bind CUDA TODO: |
| VDT_OVERLAY | `"FALSE"` | |
| VDT_OVERLAY_FILE | `${XDG_DATA_HOME}/vdt/image_overlay` | |
| VDT_OVERLAY_COUNT | `10000` | |
| VDT_OVERLAY_BS | `1M` | |
| LOGLEVEL | `"INFO"` | |
*Not complete list*

## Other Enviroment Variables

| ENV_VAR  | Default | Purpose | Set/Referenced |
| ------------- | ------------- | ------------- | ------------- |
| XDG_CONFIG_HOME |`$HOME/.config` | Location of desktop setup. | 
| XDG_DATA_HOME |`$HOME/.local/share` | `Overlay image is stored here` |  |
| EBROOTCUDA | "" | If set indicated CUDA loaded by LMOD, will add required CUDA paths. |
## Notes for supporting on Mahuika

~~Currently storing all `.sif` files in `/opt/nesi/containers/`, `image` in template should link here.~~

Run `rebuild.sh` to update. e.g. `rebuild.sh nesi-virtual-desktops_eng.sif`. 

