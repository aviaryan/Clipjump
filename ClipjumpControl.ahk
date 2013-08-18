;@Ahk2Exe-SetName Clipjump Controller
;@Ahk2Exe-SetDescription Clipjump Controller
;@Ahk2Exe-SetVersion 0.4
;@Ahk2Exe-SetCopyright (C) 2013 Avi Aryan
;@Ahk2Exe-SetOrigFilename ClipjumpControl.exe

SetWorkingDir %A_ScriptDir%
#NoTrayIcon

loop %0%
{
	X = %1%
	CjControl(X "")
	ExitApp
}

num := 8

Gui, Font, s14, Consolas
Gui, Add, Text, x10 y10 +Center, Clipjump Control
Gui, Font, s11, Arial

Gui, Add, Checkbox, xs+10 y+35 vcb2 gcbox, Disable Clipboard Monitoring(2)
Gui, Add, Checkbox, y+15 vcb4 gcbox, Disable Paste Mode(4)
Gui, Add, Checkbox, y+15 vcb8 gcbox, Disable Copy File path shortcut(8)
Gui, Add, Checkbox, y+15 vcb16 gcbox, Disable Copy Folder path shortcut(16)
Gui, Add, Checkbox, y+15 vcb32 gcbox, Disable Copy File data shortcut(32)
Gui, Add, Checkbox, y+15 vcb64 gcbox, Disable Clipboard History shortcut(64)
Gui, Add, Checkbox, y+15 vcb128 gcbox, Disable Select Channel shortcut(128)
Gui, Add, Checkbox, y+15 vcb256 gcbox, Disable One Time shortcut(256)

Gui, Add, radio, y+25 vrb1 genable group, Enable Clipjump(1)
Gui, Add, radio, y+15 vrb1048576 gdisable, Total Disable(1048576)

Gui, Font, s11
Gui, Add, Button , x135 w50 y+25, OK

Gui, Add, StatusBar,y+25 vsb, Please choose a option

Gui, Show, w320, Clipjump Controller

return

GuiClose:
	ExitApp
	return

enable:
	loop % num
		GuiControl,,% "cb" 2**A_index, 0
	SB_SetText("Code: 1")
	return

disable:
	loop % num
		GuiControl,,% "cb" 2**A_index, 0
	SB_SetText("Code: 1048576")
	return

cbox:
	Gui, submit, nohide
	GuiControl,, rb1, 0
	GuiControl,, rb1048576, 0
	t := 0
	loop % num
		temp := "cb" 2**A_index , t += %temp% ? 2**A_index : 0
	SB_SetText("Code: " t)
	return

ButtonOK:
	Gui, submit, nohide
	R := Cjcontrol(C := Substr(sb, Instr(sb, A_space, 0, 0)+1))

	if R = -1
	{
		SB_SetText("Clipjump not found!")
		return
	}
	if 	C>1
		SB_SetText("Clipjump Disabled with code: " C)
	else
		SB_SetText("Clipjump Enabled")
	return

#Include ClipjumpCommunicator.ahk