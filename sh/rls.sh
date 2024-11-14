#!/usr/bin/env bash
set -eu

## we assume you've already set up the proper chicken eggs, and the fancy
## cross-compiling chicken into its place in /opt
## we also assume you have built launch.exe already

csc -v -gui -static -O3 -d0 -C "-static" -L "-static" -strip tf2cd.scm
upx tf2cd
mkdir -p tf2cd-gui/bin
mv tf2cd tf2cd-gui/
cp -r bin/ tf2cd-gui/
rm tf2cd-gui/bin/aria2c.exe tf2cd-gui/bin/butler.exe tf2cd-gui/bin/tclkit.exe tf2cd-gui/bin/curl.exe
tar cvf tf2cd.tar tf2cd-gui/ 
zstd -19 --long -o tf2cd-gui.tzst tf2cd.tar
rm tf2cd.link tf2cd.tar
rm -r tf2cd-gui

# windows bits
/opt/chicken-shit/cross/bin/mingw-csc -v -static -O3 -C "-static" -L "-static" -strip tf2cd.scm
upx tf2cd.exe
mkdir -p tf2cd-gui-win/bin
mv tf2cd.exe tf2cd-gui-win/
cp launch.exe tf2cd-gui-win/
cp -r bin/ tf2cd-gui-win/
rm tf2cd-gui-win/bin/aria2c tf2cd-gui-win/bin/butler tf2cd-gui-win/bin/tclkit tf2cd-gui-win/bin/curl
zip -r tf2cd-gui-win.zip tf2cd-gui-win/
tar cvf tf2cd-win.tar tf2cd-gui-win/
zstd -19 --long -o tf2cd-gui-win.tzst tf2cd-win.tar
rm tf2cd.link tf2cd-win.tar
rm -r tf2cd-gui-win

# move to tmp
mv tf2cd*.tzst /tmp/
mv tf2cd*.zip /tmp/

