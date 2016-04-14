## Clipjump
  
[Download](https://github.com/aviaryan/Clipjump/releases)  
[Online Manual](http://clipjump.sourceforge.net/docs/)
  
Clipjump is a Multiple-Clipboard management utility for Windows.
It was built to make working with multiple clipboards super fast and super easy.
The program records changes in the system clipboard, stores them without any limits and provides innovative ways to work with them.  


#### Running from the Source
1. Get [AutoHotkey](http://www.ahkscript.org) and install it.
2. Then double-click `Clipjump.ahk` to run it with AutoHotkey.exe


#### Distribution
Clipjump is distributed without compiling and a disguised AutoHotkey.exe renamed as  Clipjump.exe runs Clipjump.ahk  
  
1. Get the [ResHacked AutoHotkey.exe](http://sourceforge.net/projects/clipjump/files/other_downloads/Clipjump_ahkExe.7z/download) from sourceforge. This is the one which is to be distributed as Clipjump.exe  
2. Correct the version numbers of the binary file.  
3. Distribute it with the source.


#### Building the Docs
Docs can be compiled using Jekyll and then Microsoft's HHC. First build the website folder using Jekyll and then compile the jekyll-processed files using HHC.


#### Adding Plugins
Please add your plugins to the [clipjump-addons](https://github.com/aviaryan/clipjump-addons) repository. This repo only contains plugins distributed with official Clipjump release. 
If I realise your plugin is useful for the community, I will distribute it officially and hence it will be added to this repository. See [#68](https://github.com/aviaryan/Clipjump/issues/68)