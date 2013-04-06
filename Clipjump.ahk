/*

	ClipJump --- The Multiple Clipboard Manager
	v 0.1
    Copyright (C) 2013  Avi Aryan
	
	############## IMPORTANT ##################
	Use only with AutoHotkey_L-32 bit ANSI version.
	
	###########################################

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Contact  ---  

    Web    -   www.avi-win-tips.blogspot.com
    Email  -   aviaryanap@gmail.com
*/
SetWorkingDir, %A_ScriptDir%
SetBatchLines,-1
#SingleInstance, force

Clipboard = 
IfNotExist,settings.ini
{
IniWrite,20,settings.ini,Main,Minimum_No_Of_Clips_to_be_Active
IniWrite,10,settings.ini,Main,Threshold
IniWrite,1,settings.ini,Main,Show_Copy_Message
IniWrite,20,settings.ini,Main,Quality_of_Thumbnail_Previews
}
IniRead,maxclips,settings.ini,Main,Minimum_No_Of_Clips_to_be_Active
IniRead,threshold,settings.ini,Main,Threshold
IniRead,ismessage,settings.ini,Main,Show_Copy_Message
IniRead,quality,settings.ini,Main,Quality_of_Thumbnail_Previews
IfEqual,maxclips
	maxclips = 9999999
if maxclips is not integer
	maxclips = 20
If threshold is not integer
	threshold = 10
IfEqual,ismessage,0
	CopyMessage = 
else
	CopyMessage = Transfered to ClipJump
If quality is not Integer
	quality = 20

totalclips := Threshold + maxclips

loop,
{
IfNotExist,cache/Clips/%a_index%.avc
{
	cursave := a_index - 1
	tempsave := cursave
	break
}
}
progname = ClipJump
version = 0.1
Author = Avi Aryan
updatefile = http://avis-sublime-4-autohotkey.googlecode.com/files/clipjumpversion.txt
productpage = http://avi-win-tips.blogspot.com/p/clipjump.html

Gui +LastFound +AlwaysOnTop -Caption +ToolWindow
gui, add, picture,x0 y0 w400 h300 vimagepreview,

Menu,Tray,NoStandard
Menu,Tray,Add,%progname%,main
Menu,Tray,Tip,ClipJump by Avi Aryan
Menu,Tray,Add
Menu,Tray,Add,ReadMe,rdme
Menu,Tray,Add,Run At Start Up,strtup
Menu,Tray,Add,Check for Updates,updt
Menu,Tray,Add
Menu,Tray,Add,Quit,qt
Menu,Tray,Default,%progname%

IfExist,%a_startup%/ClipJump.lnk
	Menu,Tray,Check,Run At Start Up

FileCreateDir,cache
FileCreateDir,cache/clips
FileCreateDir,cache/thumbs
caller := true
return
;End Of Auto-Execute============================================

$^v::
gui, hide
caller := false
IfNotExist,cache/clips/%tempsave%.avc
{
	Tooltip, No Clip Exists
	sleep, 700
	Tooltip
	Reload
}
else
{
Hotkey,^c,MoveBack,On
Hotkey,^x,Cancel,On
fileread,Clipboard,*c %A_ScriptDir%/cache/clips/%tempsave%.avc
realclipno := cursave - tempsave + 1
ifequal,clipboard
{
	Tooltip, Clip %realclipno% of %cursave%
	gosub, showpreview
	settimer,ctrlcheck,50
}
else
{
	StringLeft,halfclip,Clipboard, 200
	ToolTip, Clip %realclipno% of %cursave%`n%halfclip%
	settimer,ctrlcheck,50
}
realactive := tempsave
tempsave-=1
If (tempsave == 0)
	tempsave := cursave
}
return

OnClipboardChange:
If (caller)
{
tempclipall := ClipboardAll
If (clipboard != "" or tempclipall != "")
{
If errorlevel = 1
{
	FileRead,oldclip,*c cache/clips/%cursave%.avc
	If oldclip <> %tempclipall%
	{
		cursave+=1
		fileappend,%ClipboardAll%,cache/clips/%cursave%.avc
		Tooltip, %CopyMessage%
		tempsave := cursave
		IfEqual,cursave,%totalclips%
			gosub,compacter
	}
	else
		Tooltip,Same Selection
	Clipboard := 
	sleep, 500
	ToolTip
}
If errorlevel = 2
{
	cursave+=1
	fileappend,%clipboardall%,cache/clips/%cursave%.avc
	Tooltip, %CopyMessage%
	tempsave := cursave
	gosub, thumbgenerator
	IfEqual,cursave,%totalclips%
		gosub, compacter
	Clipboard := 
	sleep, 500
	Tooltip
}
tempclipall = 
oldclip = 
}
}
return

MoveBack:
gui, hide
tempsave := realactive + 1
IfEqual,realactive,%cursave%
	tempsave := 1
realactive := tempsave
fileread,Clipboard,*c %A_ScriptDir%/cache/clips/%tempsave%.avc
realclipno := cursave - tempsave + 1
ifequal,clipboard
{
	Tooltip, Clip %realclipno% of %cursave%`n
	gosub, showpreview
	settimer,ctrlcheck,50
}
else
{
	StringLeft,halfclip,Clipboard,200
	ToolTip, Clip %realclipno% of %cursave%`n%halfclip%
	settimer,ctrlcheck,50
}
return

Cancel:
gui, hide
ToolTip, Cancel Paste Operation`nRelease Control to Confirm
ctrlref = cancel
Hotkey,^x,Cancel,Off
Hotkey,^x,DeleteAll,On
return

Deleteall:
Tooltip, Delete all Clips`nRelease Control to Confirm`nPress X Again to Cancel
ctrlref = deleteall
Hotkey,^x,DeleteAll,Off
Hotkey,^x,Cancel,On
return

ctrlcheck:
GetKeyState,ctrlstate,ctrl
if ctrlstate=u
{
gui, hide
IfEqual,ctrlref,cancel
	ToolTip, Cancelled
	else IfEqual,ctrlref,deleteall
	{
		Tooltip,Deleted
		gosub, cleardata
	}
	else
	{
		Tooltip, Pasting...
		send, ^v
	}
SetTimer,ctrlcheck,Off
caller := true
ctrlref = 
tempsave := cursave
sleep, 700
Tooltip
Hotkey,^c,MoveBack,Off
Hotkey,^x,Cancel,Off
Clipboard := 
}
return

compacter:
loop, %threshold%
	FileDelete,%A_ScriptDir%\cache\clips\%a_index%.avc
loop, %threshold%
	FileDelete,%A_ScriptDir%\cache\thumbs\%a_index%.avc
loop, %maxclips%
{
	avcnumber := a_index + threshold
	FileMove,%a_scriptdir%/cache/clips/%avcnumber%.avc,%A_ScriptDir%/cache/clips/%a_index%.avc
	filemove,%a_scriptdir%/cache/thumbs/%avcnumber%.jpg,%a_scriptdir%/cache/thumbs/%a_index%.jpg
}
cursave := maxclips
tempsave := cursave
return

cleardata:
FileRemoveDir,cache/clips,1
FileRemoveDir,cache/thumbs,1
FileCreateDir,cache/clips
FileCreateDir,cache/thumbs
cursave = 0
Hotkey,^x,Deleteall,Off
return

thumbgenerator:
ClipWait,,1
Convert(0, A_ScriptDir . "\cache\thumbs\" . cursave . ".jpg", quality)
return

showpreview:
GuiControl,,imagepreview,*w400 *h300 cache\thumbs\%tempsave%.jpg
MouseGetPos,ax,ay
ay+=30
Gui, Show, x%ax% y%ay% h300 w400
return

;***************Extras**********************************************************************
qt:
ExitApp
return
rdme:
Run, readme.txt
return
main:
MsgBox, 64, %progname% v%version%, %progname% v%version%`n`nBy Avi Aryan`nThanks to Sean for his Image Capture Function`n`nSee Readme.txt for more details.
IfMsgBox OK
	run, iexplore.exe "www.avi-win-tips.blogspot.com"
return
strtup:
Menu,Tray,Togglecheck,Run At Start Up
IfExist, %a_startup%/ClipJump.lnk
	FileDelete,%a_startup%/ClipJump.lnk
else
	FileCreateShortcut,%A_ScriptDir%/ClipJump.exe,%A_Startup%/ClipJump.lnk
return
updt:
URLDownloadToFile,%updatefile%,%a_scriptdir%/cache/latestversion.txt
FileRead,latestversion,%a_scriptdir%/cache/latestversion.txt
IfGreater,latestversion,%version%
{
MsgBox, 48, Update Avaiable, Your Version = %version%         `nCurrent Version = %latestversion%       `n`nGo to Website
IfMsgBox OK
	run, iexplore.exe "%productpage%"
}
else
	MsgBox, 64, ClipJump, No Updates Available
return
#Include, imagelib.ahk