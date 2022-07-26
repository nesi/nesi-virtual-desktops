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
```
cd sif
tar -cf  skel.tar skel
git add skel
git commit -m 'updated skel'
git push origin main
```

Then rebuild

## Rebuilding image using syslab remote build service.
```
./rebuild.sh image.def
```

Where `image.def` is the def file of the image you want to build.

## Uploading to syslab cloud

## Image files on NeSI.

New builds should be placed 

```
/opt/nesi/containers/vdt_base/vdt_base_0-0-0.sif
```

Symlink `vdt_base.sif` should point to the newest version.