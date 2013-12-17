## [Clipjump](http://clipjump.sourceforge.net)
A Magical Clipboard Manager  
  
[Download](http://goo.gl/tUi4K)  
[Online Manual](http://avi-win-tips.blogspot.com/2013/04/clipjump-online-guide.html)
  
A Multiple-Clipboard management utility for Windows.  
Allows you to simultaneously use multiple clipboards like never before.  
Everything that is transferred to your clipboard will get automatically transferred to the Multiple-Clipboards.  
It's fast , it's easy, it's magic.  
  

#### Running from the Source
1. Get [AutoHotkey](http://www.autohotkey.com) and install it.
2. Then double-click `Clipjump.ahk` to run it with AutoHotkey.exe
  
#### Compiling the Source (Current Method)
1. Use [Ahk2Exe](https://github.com/fincs/Ahk2Exe) Compiler included in the AHK_L distribution to compile `Clipjump.ahk` with icon `iconx.ico`.
2. Use a suitable version of `Unicode` as the Base File.  
  
~~**AND (new method)**  
1. Run `_compile_genfiles.ahk` to generate `clipjump_code.ahk`  
2. Use Ahk_H Compiler to compile `ClipjumpHexe.ahk` using a unicode AutoHotkey.exe as the base file.  
3. ResHack the file to add icons natively into it i.e. don't use icons/icon.ico.~~  
  
  
#### Setting up the Installer
1. Use 7-zip's SFX archive feature.  
2. UPX 7z.sfx for smaller executables.  
  