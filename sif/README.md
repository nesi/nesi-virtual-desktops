# Container inheritence

- rocky8.sif
- rocky8vis.sif
- vdt_base.sif



# Custom plugins
# Global desktop files
/usr/share/xfce4/panel/plugins
/usr/share/applications

# Local desktop files
~/.local/share/applications


./.config/xfce4/panel/
xfce4-panel -r



## Modifying 'skel' files.
cd sif
tar -cpf  skel.tar skel
git add skel

## Rebuilding image using syslab remote build service.
```
./rebuild.sh image.def
```

Where `image.def` is the def file of the image you want to build.

## Uploading to syslab cloud
