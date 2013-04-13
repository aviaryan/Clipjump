/*

	ClipJump --- The Multiple Clipboard Manager
	v 3.0
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
SetKeyDelay, -1
#SingleInstance, force

Clipboard = 
IfNotExist,settings.ini
{
IniWrite,20,settings.ini,Main,Minimum_No_Of_Clips_to_be_Active
IniWrite,10,settings.ini,Main,Threshold
IniWrite,1,settings.ini,Main,Show_Copy_Message
IniWrite,20,settings.ini,Main,Quality_of_Thumbnail_Previews
IniWrite,1,settings.ini,Main,Keep_Session
IniWrite,1,settings.ini,Main,Remove_Ending_Linefeeds
Iniwrite,200,settings.ini,System,Wait_Key
}
IniRead,maxclips,settings.ini,Main,Minimum_No_Of_Clips_to_be_Active
IniRead,threshold,settings.ini,Main,Threshold
IniRead,ismessage,settings.ini,Main,Show_Copy_Message
IniRead,quality,settings.ini,Main,Quality_of_Thumbnail_Previews
IniRead,keepsession,settings.ini,Main,Keep_Session
IniRead,R_lf,settings.ini,Main,Remove_Ending_Linefeeds
Iniread,generalsleep,settings.ini,System,Wait_Key

if (R_lf == "ERROR")
{
	IniWrite,1,settings.ini,Main,Remove_Ending_Linefeeds
	Iniwrite,200,settings.ini,System,Wait_Key
}

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
if keepsession is not integer
	keepsession = 1
if (R_lf == 0)
	R_lf := false
else
	R_lf := true

if generalsleep is not Integer
	generalsleep := 200

IfLess,generalsleep,200
	generalsleep := 200

IfEqual,keepsession,0
	gosub, cleardata

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

;*********Program Vars**********************************************************

progname = ClipJump
version = 3.0
Author = Avi Aryan
updatefile = http://avis-sublime-4-autohotkey.googlecode.com/files/clipjumpversion.txt
productpage = http://avi-win-tips.blogspot.com/p/clipjump.html

;*******GUIS****************************************************
Gui +LastFound +AlwaysOnTop -Caption +ToolWindow
gui, add, picture,x0 y0 w400 h300 vimagepreview,

Gui, 2:Font, S18 CRed, Verdana
Gui, 2:Add, Text, x2 y0 w550 h40 +Center gupdt, ClipJump v%version%
Gui, 2:Font, S14 CBlue, Verdana
Gui, 2:Add, Text, x2 y40 w550 h30 +Center gblog, Avi Aryan
Gui, 2:Font, S16 CBlack, Verdana
Gui, 2:Font, S14 CBlack, Verdana
Gui, 2:Add, Text, x2 y70 w550 h30 +Center, A Magical Clipboard Manager
Gui, 2:Font, S14 CBlack, Verdana
Gui, 2:Font, S14 CRed, Verdana
Gui, 2:Add, Text, x2 y120 w100 h30 , Thanks
Gui, 2:Font, S12 CBlue Bold, Verdana
Gui, 2:Add, Text, x2 y150 w550 h90 , Sean for his Screen Capture Function.`nTic (Tariq Potter) for GDI+ Library.`nKen and Luke for pointing out bugs.
Gui, 2:Font, S14 CBlack Bold, Verdana
Gui, 2:Add, Text, x2 y260 w300 h30 ginstallationopen, Click to see How to Use
Gui, 2:Add, Text, x2 y290 w300 h30 grdme, Readme
Gui, 2:Font, S14 CBlack, Verdana
Gui, 2:Add, Text, x-8 y330 w560 h24 +Center, Copyright (C) 2013
;******************************************************************
Menu,Tray,NoStandard
Menu,Tray,Add,%progname%,main
Menu,Tray,Tip,ClipJump by Avi Aryan
Menu,Tray,Add
Menu,Tray,Add,ReadMe,rdme
Menu,Tray,Add,Run At Start Up,strtup
Menu,Tray,Add,Check for Updates,updt
Menu,Tray,Add
Menu,Tray,Add,See Online Help,hlp
Menu,Tray,Add
Menu,Tray,Add,Quit,qt
Menu,Tray,Default,%progname%

IfExist,%a_startup%/ClipJump.lnk
	Menu,Tray,Check,Run At Start Up

FileCreateDir,cache
FileCreateDir,cache/clips
FileCreateDir,cache/thumbs
FileCreateDir,cache/fixate
FileSetAttrib,+H,%a_scriptdir%\cache

scrnhgt := A_ScreenHeight / 2.5
scrnwdt := A_ScreenWidth / 2

caller := true
in_back := false
Hotkey,$^v,Paste,On
Hotkey,^!c,CopyFile,On
Hotkey,^!x,CopyFolder,On
EmptyMem()
return
;End Of Auto-Execute============================================

paste:
gui, hide
caller := false
if (in_back)
{
in_back := false
If (tempsave == 1)
	tempsave := cursave
else
	tempsave-=1
}
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
Hotkey,^Space,Fixate,On
Hotkey,^S,Ssuspnd,On

fileread,Clipboard,*c %A_ScriptDir%/cache/clips/%tempsave%.avc
gosub, fixcheck
realclipno := cursave - tempsave + 1
ifequal,clipboard
{
	Tooltip, Clip %realclipno% of %cursave% %fixstatus%
	gosub, showpreview
	settimer,ctrlcheck,50
}
else
{
	length := strlen(Clipboard)
	IfGreater,length,200
	{
		StringLeft,halfclip,Clipboard, 200
		halfclip := halfclip . "                      >>>>  .............More"
	}
	else
		halfclip := Clipboard
	ToolTip, Clip %realclipno% of %cursave% %fixstatus%`n%halfclip%
	settimer,ctrlcheck,50
}
realactive := tempsave
tempsave-=1
If (tempsave == 0)
	tempsave := cursave
}
return

OnClipboardChange:
Critical
If (caller)
{
errlvl := ErrorLevel
gosub, clipchange
}
return

clipchange:
tempclipall := ClipboardAll
If (clipboard != "" or tempclipall != "")
{
If errlvl = 1
{
	cursave+=1
	gosub, clipsaver
	Tooltip, %CopyMessage%
	tempsave := cursave
	IfEqual,cursave,%totalclips%
		gosub,compacter
}
If errlvl = 2
{
	cursave+=1
	Tooltip, %CopyMessage%
	tempsave := cursave
	gosub, thumbgenerator
	gosub, clipsaver
	IfEqual,cursave,%totalclips%
		gosub, compacter
}
tempclipall = 
sleep, 500
Tooltip
}
return

MoveBack:
gui, hide
in_back := true
tempsave := realactive + 1
IfEqual,realactive,%cursave%
	tempsave := 1
realactive := tempsave
fileread,Clipboard,*c %A_ScriptDir%/cache/clips/%tempsave%.avc
gosub, fixcheck
realclipno := cursave - tempsave + 1
ifequal,clipboard
{
	Tooltip, Clip %realclipno% of %cursave% %fixstatus%`n
	gosub, showpreview
	settimer,ctrlcheck,50
}
else
{
	StringLeft,halfclip,Clipboard,200
	ToolTip, Clip %realclipno% of %cursave% %fixstatus%`n%halfclip%
	settimer,ctrlcheck,50
}
return

Cancel:
gui, hide
ToolTip, Cancel Paste Operation`nRelease Control to Confirm
ctrlref = cancel
Hotkey,^Space,fixate,Off
Hotkey,^S,Ssuspnd,Off
Hotkey,^x,Cancel,Off
Hotkey,^x,Delete,On
return

Delete:
ToolTip, Delete the current clip`nRelease Control to Confirm`nPress X Again to Delete All Clips.
ctrlref = delete
Hotkey,^x,Delete,Off
Hotkey,^x,DeleTEall,On
return

Deleteall:
Tooltip, Delete all Clips`nRelease Control to Confirm`nPress X Again to Cancel
ctrlref = deleteall
Hotkey,^x,DeleteAll,Off
Hotkey,^x,Cancel,On
return

Fixate:
IfExist,cache\fixate\%realactive%.fxt
{
	fixstatus := ""
	FileDelete,%A_ScriptDir%\cache\fixate\%realactive%.fxt
}
else
{
	fixstatus := "[FIXED]"
	FileAppend,,%A_ScriptDir%\cache\fixate\%realactive%.fxt
}
IfEqual,clipboard
	Tooltip, Clip %realclipno% of %cursave% %fixstatus%`n
else
	ToolTip, Clip %realclipno% of %cursave% %fixstatus%`n%halfclip%
return

clipsaver:
fileappend,%ClipboardAll%,cache/clips/%cursave%.avc
loop,%cursave%
{
tempno := cursave - a_index + 1
IfExist,cache\fixate\%tempno%.fxt
{
	t_tempno := tempno + 1
	FileMove,cache\clips\%t_tempno%.avc,cache\clips\%t_tempno%_a.avc
	FileMove,cache\clips\%tempno%.avc,cache\clips\%t_tempno%.avc
	FileMove,cache\clips\%t_tempno%_a.avc,cache\clips\%tempno%.avc
	IfExist,cache\thumbs\%tempno%.jpg
	{
		FileMove,cache\thumbs\%t_tempno%.jpg,cache\thumbs\%t_tempno%_a.jpg
		FileMove,cache\thumbs\%tempno%.jpg,cache\thumbs\%t_tempno%.jpg
		FileMove,cache\thumbs\%t_tempno%_a.jpg,cache\thumbs\%tempno%.jpg
	}
	FileMove,cache\fixate\%tempno%.fxt,cache\fixate\%t_tempno%.fxt
}
}
t_tempno =
tempno = 
return

fixcheck:
IfExist,cache\fixate\%tempsave%.fxt
	fixstatus := "[FIXED]"
else
	fixstatus := ""
return

ctrlcheck:
GetKeyState,ctrlstate,ctrl
if ctrlstate=u
{
gui, hide
IfEqual,ctrlref,cancel
{
	ToolTip, Cancelled
	tempsave := cursave
}
	else IfEqual,ctrlref,deleteall
	{
		Tooltip,Everything Deleted
		gosub, cleardata
	}
	else IfEqual,ctrlref,delete
		{
			Tooltip,Deleted
			gosub, clearclip
		}
		else
		{
			caller := false
			Tooltip, Pasting...
			if (R_lf)
			{
			if (Substr(Clipboard,-1) == "`r`n")
			{
			IfWinActive, ahk_class XLMAIN
				SendInput, %Clipboard%{Up 2}
			else
			{
				CopyMessage = 
				StringTrimRight,Clipboard,clipboard,2
				Send, ^v
				sleep, %generalsleep%
				Loop
					IfExist,cache\clips\%cursave%.avc
						break
				CopyMessage = Transfered to ClipJump
			}
			}
			else
			{
			IfWinActive, ahk_class XLMAIN
			{
				IF (Substr(Clipboard,-11) == "   --[PATH][")
				{
					StringTrimRight,tempclip,Clipboard,12
					SendInput {RAW} %tempclip%
				}
				else
					SendInput %clipboard%
			}
			else
			{
				IF (Substr(Clipboard,-11) == "   --[PATH][")
				{
					StringTrimRight,tempclip,Clipboard,12
					SendInput {RAW} %tempclip%
				}
				else
					Send, ^v
			}
			}
			}
			else
			{
			IfWinActive, ahk_class XLMAIN
			{
				IF (Substr(Clipboard,-11) == "   --[PATH][")
				{
					StringTrimRight,tempclip,Clipboard,12
					SendInput {RAW} %tempclip%
				}
				else
					SendInput %clipboard%
			}
			else
			{
				IF (Substr(Clipboard,-11) == "   --[PATH][")
				{
					StringTrimRight,tempclip,Clipboard,12
					SendInput {RAW} %tempclip%
				}
				else
					Send, ^v
			}
			}
			tempsave := realactive
		}
SetTimer,ctrlcheck,Off
caller := true
in_back := false
tempclip = 
ctrlref = 
sleep, 700
Tooltip
Hotkey,^S,Ssuspnd,Off
Hotkey,^c,MoveBack,Off
Hotkey,^x,Cancel,Off
Hotkey,^Space,Fixate,Off
Hotkey,^x,Deleteall,Off
Hotkey,^x,Delete,Off
EmptyMem()
}
return

Ssuspnd:
SetTimer,ctrlcheck,Off
ctrlref = 
tempsave := realactive
Hotkey,^c,MoveBack,Off
Hotkey,^x,Cancel,Off
Hotkey,^Space,Fixate,Off
Hotkey,^x,Deleteall,Off
Hotkey,^x,Delete,Off
Hotkey,^S,Ssuspnd,Off
in_back := false
caller := false
addtowinclip(realactive, "has Clip " . realclipno)
caller := true
return

compacter:
loop, %threshold%
{
	FileDelete,%A_ScriptDir%\cache\clips\%a_index%.avc
	FileDelete,%A_ScriptDir%\cache\thumbs\%a_index%.jpg
	FileDelete,%A_ScriptDir%\cache\fixate\%a_index%.fxt
}
loop, %maxclips%
{
	avcnumber := a_index + threshold
	FileMove,%a_scriptdir%/cache/clips/%avcnumber%.avc,%A_ScriptDir%/cache/clips/%a_index%.avc
	filemove,%a_scriptdir%/cache/thumbs/%avcnumber%.jpg,%a_scriptdir%/cache/thumbs/%a_index%.jpg
	filemove,%a_scriptdir%/cache/fixate/%avcnumber%.fxt,%a_scriptdir%/cache/fixate/%a_index%.fxt
}
cursave := maxclips
tempsave := cursave
return

cleardata:
FileDelete,cache\clips\*.avc
FileDelete,cache\thumbs\*.jpg
FileDelete,cache\fixate\*.fxt
cursave := 0
tempsave := 0
return

clearclip:
FileDelete,cache\clips\%realactive%.avc
FileDelete,cache\thumbs\%realactive%.jpg
FileDelete,cache\fixate\%realactive%.fxt
tempsave := realactive - 1
if (tempsave == 0)
	tempsave := 1
gosub, renamecorrect
cursave-=1
return

renamecorrect:
looptime := cursave - realactive
If (looptime != 0)
{
loop,%looptime%
{
	newname := realactive
	realactive+=1
	FileMove,cache/clips/%realactive%.avc,cache/clips/%newname%.avc
	FileMove,cache/thumbs/%realactive%.jpg,cache/thumbs/%newname%.jpg
	FileMove,cache/fixate/%realactive%.fxt,cache/fixate/%newname%.fxt
}
}
return

thumbgenerator:
ClipWait,,1
Convert(0, A_ScriptDir . "\cache\thumbs\" . cursave . ".jpg", quality)
return

showpreview:
GDIPToken := Gdip_Startup()
pBM := Gdip_CreateBitmapFromFile( A_ScriptDir . "\cache\thumbs\" . tempsave . ".jpg" )
widthofthumb := Gdip_GetImageWidth( pBM )
heightofthumb := Gdip_GetImageHeight( pBM )  
Gdip_DisposeImage( pBM )                                         
Gdip_Shutdown( GDIPToken )

IfGreater,heightofthumb,%scrnhgt%
	displayh := heightofthumb / 2
else
	displayh := heightofthumb
IfGreater,widthofthumb,%scrnwdt%
	displayw := widthofthumb / 2
else
	displayw := widthofthumb

GuiControl,,imagepreview,*w%displayw% *h%displayh% cache\thumbs\%tempsave%.jpg
MouseGetPos,ax,ay
ay := ay + (scrnhgt / 9)
Gui, Show, x%ax% y%ay% h%displayh% w%displayw%
return

;****************COPY FILE/FOLDER******************************************************************************

copyfile:
CopyMessage = File Path(s) copied to Clipjump
selectedfile := GetFile()
IfNotEqual,selectedfile
	Clipboard := selectedfile . "   --[PATH]["
sleep, %generalsleep%
CopyMessage = Transfered to Clipjump
return

copyfolder:
CopyMessage = Active Folder Path copied to Clipjump
openedfolder := GetFolder()
IfNotEqual,openedfolder
	Clipboard := openedfolder . "   --[PATH]["
sleep, %generalsleep%
Copymessage = Transfered to Clipjump
return

;***************Extra Functions and Labels**********************************************************************
qt:
ExitApp

rdme:
Run, readme.txt
return

hlp:
Run, iexplore.exe "http://avi-win-tips.blogspot.com/2013/04/clipjump-online-guide.html"
return

main:
Gui, 2:Show, x416 y126 h354 w557, Clipjump v%version%
return

2GuiClose:
gui, 2:hide
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

installationopen:
rUN, Installation And Usage.txt
return

blog:
run, iexplore.exe "www.avi-win-tips.blogspot.com"
return

;******FUNCTIONS*************************************************

addtowinclip(lastentry, extratip)
{
ToolTip, Windows Clipboard %extratip%
IfNotEqual,cursave,0
	fileread,Clipboard,*c %A_ScriptDir%/cache/clips/%lastentry%.avc

IF (Substr(Clipboard,-11) == "   --[PATH][")
	StringTrimRight,Clipboard,Clipboard,12
sleep, 1000
ToolTip
}
EmptyMem()
{
return, dllcall("psapi.dll\EmptyWorkingSet", "UInt", -1)
}

GetFile(hwnd="")
{
	hwnd := hwnd ? hwnd : WinExist("A")
	WinGetClass class, ahk_id %hwnd%
	if (class="CabinetWClass" or class="ExploreWClass" or class="Progman")
		for window in ComObjCreate("Shell.Application").Windows
			if (window.hwnd==hwnd)
    sel := window.Document.SelectedItems
	for item in sel
	ToReturn .= item.path "`n"
	return Trim(ToReturn,"`n")
}

GetFolder()
{
WinGetClass,var,A
If var in CabinetWClass,ExplorerWClass,Progman
{
IfEqual,var,Progman
	v := A_Desktop
else
{
winGetText,Fullpath,A
loop,parse,Fullpath,`r`n
{
IfInString,A_LoopField,:\
{
StringGetPos,pos,A_Loopfield,:\,L
Stringtrimleft,v,A_loopfield,(pos - 1)
break
}
}
}
return, v
}
}
#Include, imagelib.ahk
#include, gdiplus.ahk