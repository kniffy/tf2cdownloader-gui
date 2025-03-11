# tf2cdownloader-gui
simple graphical downloader for Team Fortress 2 Classic  

static beta builds are available on the
[releases](https://github.com/kniffy/tf2cdownloader-gui/releases) page  

### notes
development has now ended, tf2c is set to be released on steam, making this  
tool redundant :^)  

for users still on version 2.1.4, you may need to edit `rev.txt` to contain `214`  
it was left as `213` by mistake..  

there is currently no checking of free disk space, or deletion of temp files!  
ensure you have more than enough space eg. 20+gb  

### building
1. install `chicken`  
`apt install chicken-bin` on debian  
`pacman -S chicken` on arch  

2. install chicken eggs  
`chicken-install -sudo pstk json-abnf srfi-18`  

3. compile  
`csc -static -gui -O3 -d0 tf2cd.scm`  

