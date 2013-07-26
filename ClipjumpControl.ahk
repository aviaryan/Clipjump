;@Ahk2Exe-SetName Clipjump Controller
;@Ahk2Exe-SetDescription Clipjump Controller
;@Ahk2Exe-SetVersion 0.2
;@Ahk2Exe-SetCopyright (C) 2013 Avi Aryan
;@Ahk2Exe-SetOrigFilename ClipjumpControl.exe

SetWorkingDir %A_ScriptDir%
#NoTrayIcon

loop %0%
{
	X = %1%
	CjControl(X+0)
	ExitApp
}

Gui, Font, s14, Consolas
Gui, Add, Text, x10 y10 +Center, Clipjump Control
Gui, Font, s12, Arial
Gui, Add, Radio, xs+10 y+40 vrad0 gcb Group, Disable just Clipboard Monitoring(0)
Gui, Add, Radio, y+20 vrad_1 gcb, Disable Paste Mode Also(-1)
Gui, Add, Radio, y+20 vrad_2 gcb, Disable Clipboard History Also(-2)
Gui, Add, Radio, y+40 vrad1 gcb, Enable Clipjump(1)

Gui, Add, Text, h30
Gui, Add, StatusBar,y+30, Please choose a option

Gui, Show,, Clipjump Controller
return

GuiClose:
	ExitApp
	return

cb:
	C := Substr(A_GuiControl, 4)
	StringReplace, C, C,_,-
	R := Cjcontrol(C := C+0)
	if R = -1
	{
		SB_SetText("Clipjump not found!")
		return
	}
	if C<1
		SB_SetText("Clipjump Disabled")
	else
		SB_SetText("Clipjump Enabled")
	return

#Include ClipjumpCommunicator.ahk