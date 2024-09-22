# tf2cdownloader-gui
simple graphical downloader for Team Fortress 2 Classic  

static beta builds are available on the
[releases](https://github.com/kniffy/tf2cdownloader-gui/releases) page  

### notes
there is currently no checking of free disk space!  
ensure you have more than enough space  

### building
1. install `chicken`  
`apt install chicken-bin` on debian  
`pacman -S chicken` on arch  

2. install `pstk` and `json-abnf`  
`chicken-install -sudo pstk json-abnf`  

3. compile  
`csc -static -gui -O3 -d0 tf2cd.scm`  

