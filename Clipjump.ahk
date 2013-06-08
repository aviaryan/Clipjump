/*
	Clipjump v5.0b2
	
	Copyright 2013 Avi Aryan

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/

SetWorkingDir, %A_ScriptDir%
SetBatchLines,-1
SetKeyDelay, -1
#SingleInstance, force
CoordMode,Mouse

;*********Program Vars**********************************************************

progname = Clipjump
version = 5.0b2
updatefile = https://dl.dropboxusercontent.com/u/116215806/Products/Clipjump/Clipjumpversion.txt
productpage = http://avi-win-tips.blogspot.com/p/Clipjump.html

;*******************************************************************************
Clipboard = 
Iniread,version_ini,settings.ini,System,Version

If ( !FileExist("settings.ini") or version_ini != version )
{
;Faster
datatobeadded=
(
[Main]
Minimum_No_Of_Clips_to_be_Active=20
;It is the minimum no of clipboards that you want simultaneously to be active.``nIf you want 20, SPECIFY 20.``nIf you want Unlimited, leave it blank. (Not Recommended)
Threshold=10
;Threshold is the extra number of clipboard that will be active other than your minimum limit..``nMost recommended value is 10.``n[TIP] - Threshold = 1 will make Clipjump store exact number of clipboards.
Show_Copy_Message=1
;This value determines whether you want to see the "Transfered to Clipjump" message or not while copy/cut operations.``n1 = enabled (default)``n0 = disabled
Quality_of_Thumbnail_Previews=20
;The quality of Thumbnail previews you want to have.``nRecommended to let it be 20``Can be between 1 - 100
Keep_Session=1
;Should Clipjump keep all the saved clipboards after each Clipjump restart or simply Windows restart if you run it at Start up.``n1 = Yes (Clipboards kept)``n0 = No
Remove_Ending_Linefeeds=1
;Remove Linefeeds from end of Clips . These linefeeds if not removed can cause an Extra ENTER to be simulated while pasting Clips in Text-Holders.``n1 = Yes (Recommended)``n0 = No
[System]
Wait_Key=200
;Dont Edit (decrease) this key. 
Version=%version%
;Current Clipjump Version
[Clipboard_History]
Days_to_store=10
;Number of days for which the clipboard record will be stored
Store_Images=1
;Should clipboard images be stored in history ?``n1=yes``n0=no
)

	FileDelete,settings.ini
	FileAppend,%datatobeadded%,settings.ini
	FileCreateShortcut,%A_ScriptFullPath%,%A_Startup%/Clipjump.lnk
}

IniRead,maxclips,settings.ini,Main,Minimum_No_Of_Clips_to_be_Active
IniRead,threshold,settings.ini,Main,Threshold
IniRead,ismessage,settings.ini,Main,Show_Copy_Message
IniRead,quality,settings.ini,Main,Quality_of_Thumbnail_Previews
IniRead,keepsession,settings.ini,Main,Keep_Session
IniRead,R_lf,settings.ini,Main,Remove_Ending_Linefeeds
Iniread,generalsleep,settings.ini,System,Wait_Key
Iniread,version_ini,settings.ini,System,Version
Iniread,days_to_store,settings.ini,Clipboard_History,Days_to_store
iniread,isimagestored,settings.ini,Clipboard_History,Store_images

IfEqual,maxclips
	maxclips := 9999999
if maxclips is not integer
	maxclips := 20
If threshold is not integer
	threshold := 10

CopyMessage := ismessage = 0 ? "" : "Transfered to Clipjump"

If quality is not Integer
	quality = 20
if keepsession is not integer
	keepsession := 1

R_lf := R_lf = 0 ? 0 : 1

if generalsleep is not Integer
	generalsleep := 200
IfLess,generalsleep,200
	generalsleep := 200

IfEqual,keepsession,0
	gosub, cleardata

isimagestored := isimagestored = 0 ? 0 : 1
days_to_store := days_to_store < 0 ? 0 : (days_to_store > 200 ? 200 : days_to_store)	;A max 200 days is allowed
gosub, historycleanup

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

;*******GUIS******************************************************

;Preview GUI
Gui +LastFound +AlwaysOnTop -Caption +ToolWindow
gui, add, picture,x0 y0 w400 h300 vimagepreview,

;About GUI
Gui, 2:Font, S18 CRed, Consolas
Gui, 2:Add, Text, x2 y0 w550 h40 +Center gupdt, Clipjump v%version%
Gui, 2:Font, S14 CBlue, Verdana
Gui, 2:Add, Text, x2 y40 w550 h30 +Center gblog, Avi Aryan
Gui, 2:Font, S16 CBlack, Verdana
Gui, 2:Font, S14 CBlack, Verdana
Gui, 2:Add, Text, x2 y70 w550 h30 +Center, A Magical Clipboard Manager
Gui, 2:Add, Picture, x230 y110 w100 h100,% (A_Iscompiled ? A_ScriptFullPath : A_ScriptDir "/iconx.ico")
Gui, 2:Font, S14 CRed Bold, Consolas
Gui, 2:Add, Text, x2 y230 w200 h30 gsettings, Edit Settings
Gui, 2:Font, CBlack
Gui, 2:Add, Text, x2 y260 w300 h30 ghistory, See Clipjump History
Gui, 2:Add, Text, x2 y290 w300 h30 ghlp, Go Online - See Manual
Gui, 2:Font, S14 CBlack, Verdana
Gui, 2:Add, Text, x-8 y330 w560 h24 +Center, Copyright (C) 2013

;Settings GUI
Gui, 3:Default
Gui, 3:Add, TreeView,x2 y130 r15 w300 gTvclick
TV_Main := TV_Add("Main")
TV_Add("Minimum no of clips to be Active", TV_Main)
TV_Add("Threshold", TV_Main)
TV_Add("Show Copy Message", TV_Main)
TV_Add("Quality of Thumbnail Previews", TV_Main)
TV_Add("Keep Session", TV_Main)
TV_Add("Remove Ending Linefeeds", TV_Main)
TV_Clipboard_History := TV_Add("Clipboard History")
TV_Add("Days to store", TV_Clipboard_History)
TV_Add("Store Images", TV_Clipboard_History)

Gui, 3:Font, S18 CRed, Consolas
Gui, 3:Add, Text, x2 y0 w540 h30 +Center, Clipjump Settings Editor
Gui, 3:Font, S12 CBlue, Consolas
Gui, 3:Add, Text, x2 y30 w100 h20 , Description
Gui, 3:Font, S8 CGreen, Consolas
Gui, 3:Add, Text, x2 y50 w540 h70 vsettings_dtext,
Gui, 3:Font, S11 CBlack, Consolas
Gui, 3:Add, Edit, x342 y130 w170 h20 vsettings_edit, 
Gui, 3:Font, S10 CBrown, Consolas
Gui, 3:Add, Text, x2 y390 w540 h20 vsettings_savestatus,
Gui, 3:Font, S12 CBlack, Consolas
Gui, 3:Add, Button, x222 y420 w100 h30 , Save

;ClipboardHistory GUI
Gui, 4:Default
Gui, 4:Font, S18 CRed, Consolas
Gui, 4:Add, Text, x2 y0 w724 h40 +Center, Clipjump Clipboard History
Gui, 4:Font, S8 CBlack, Consolas
Gui, 4:Add, ListView, x2 y90 w720 r20 ghistoryclick vhistorylist, Clip|Date|Hiddendate		;600|120|1

Gui, 4:Font, S13 Cblue, Consolas
Gui, 4:Add, Text, x2 y50 w100 h30 , Search
Gui, 4:Font, S12 CBlack, Consolas
Gui, 4:Add, Edit, x242 y50 w470 h30 ghistory_edit vhistory_edit
Gui, 4:Font, S10 CGreen, Consolas
Gui, 4:Add, Text, x2 y470 w610 h40 , Double Click to open a clip`nRight Click to see context menu
Gui, 4:Font, CBlack
Gui, 4:Add, Button, x600 y470 w100 h40, Delete_All

;History Preview
Gui, 5:+ToolWindow
Gui, 5:Font, S10 CDefault, Consolas
Gui, 5:Add, Edit, x2 y2 w0 h0 +VScroll +ReadOnly +Multi vhistory_text,
Gui, 5:Add, Picture, x3 y3 vhistory_pic
Gui, 5:Add, Button, x152 y340 w220 h30 , Copy_to_Clipboard

;******************************************************************
;MENUS

;TRAY
Menu,Tray,NoStandard
Menu,Tray,Add,%progname%,main
Menu,Tray,Tip,Clipjump by Avi Aryan
if !(A_isCompiled)
	Menu,Tray,Icon,iconx.ico
Menu,Tray,Add
Menu,Tray,Add,Clipboard History		(Win+C),history
Menu,Tray,Add
Menu,Tray,Add,Preferences,settings
Menu,Tray,Add,Run At Start Up,strtup
Menu,Tray,Add,Check for Updates,updt
Menu,Tray,Add
Menu,Tray,Add,Readme,rdme
Menu,Tray,Add,See Online Help,hlp
Menu,Tray,Add
Menu,Tray,Add,Quit,qt
Menu,Tray,Default,%progname%

;History Right-Click Menu
Menu,HisMenu,Add,Copy to Clipjump,history_clipboard
Menu,HisMenu,Add
Menu,HisMenu,Add,Delete,history_delete

;********************************************************************
;STARTUP
IfExist,%a_startup%/Clipjump.lnk
{
FileDelete,%a_startup%/Clipjump.lnk
FileCreateShortcut,%A_ScriptFullPath%,%A_Startup%/Clipjump.lnk
Menu,Tray,Check,Run At Start Up
}

FileCreateDir,cache
FileCreateDir,cache/clips
FileCreateDir,cache/thumbs
FileCreateDir,cache/fixate
FileCreateDir,cache/history
FileSetAttrib,+H,%a_scriptdir%\cache

scrnhgt := A_ScreenHeight / 2.5
scrnwdt := A_ScreenWidth / 2

caller := true
in_back := false

Hotkey,$^v,Paste,On
Hotkey,$^c,NativeCopy,On
Hotkey,$^x,NativeCut,On
Hotkey,^!c,CopyFile,On
Hotkey,^!x,CopyFolder,On
Hotkey,#c,History,On
;Environment
OnMessage(0x4a, "Receive_WM_COPYDATA")  ; 0x4a is WM_COPYDATA

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
	gosub, showpreview
	Tooltip,% "Clip " realclipno " of " cursave "  " fixstatus (WinExist("Display_Cj") ? "" : "`nSorry, the preview/path can't be loaded") 
	settimer,ctrlcheck,50
}
else
{
	length := strlen(Clipboard)
	IfGreater,length,200
	{
		StringLeft,halfclip,Clipboard, 200
		halfclip := halfclip . "`n`n....[More]"
	}
	else
		halfclip := Clipboard
	ToolTip, Clip %realclipno% of %cursave% %fixstatus%`n`n%halfclip%
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
If errlvl = 1
{
	IfNotEqual,Clipboard,%lastclip%
	{
	cursave+=1
	gosub, clipsaver
	LastClip := Clipboard
	FileAppend,%Lastclip%,cache\history\%A_Now%.hst
	Tooltip, %CopyMessage%
	tempsave := cursave
	IfEqual,cursave,%totalclips%
		gosub,compacter
	}
}
If errlvl = 2
{
	cursave+=1
	Tooltip, %CopyMessage%
	tempsave := cursave
	LastClip := 
	gosub, thumbgenerator
	if (isimagestored)
		FileCopy,cache\thumbs\%cursave%.jpg,cache\history\%A_Now%.jpg
	gosub, clipsaver
	IfEqual,cursave,%totalclips%
		gosub, compacter
}
sleep, 500
Tooltip
EmptyMem()
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
	gosub, showpreview
	Tooltip,% "Clip " realclipno " of " cursave "  " fixstatus (WinExist("Display_Cj") ? "" : "`nSorry, the preview/path can't be loaded")
	settimer,ctrlcheck,50
}
else
{
	length := strlen(Clipboard)
	IfGreater,length,200
	{
		StringLeft,halfclip,Clipboard, 200
		halfclip := halfclip . "`n`n....[More]"
	}
	else
		halfclip := Clipboard
	ToolTip, Clip %realclipno% of %cursave% %fixstatus%`n`n%halfclip%
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

NativeCopy:
Critical
Hotkey,$^c,NativeCopy,Off
Hotkey,$^c,Blocker,On
Send, ^c
setTimer,CtrlforCopy,50
gosub, CtrlforCopy
return

NativeCut:
Critical
Hotkey,$^x,NativeCut,Off
Hotkey,$^x,Blocker,On
Send, ^x
setTimer,CtrlforCopy,50
gosub, CtrlforCopy
return

CtrlForCopy:
GetKeyState,Ctrlstate,ctrl
if ctrlstate = u
{
Hotkey,$^c,NativeCopy,on
Hotkey,$^x,NativeCut,on
setTimer,CtrlforCopy,Off
}
return

Blocker:
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
caller := false
gui, hide
IfEqual,ctrlref,cancel
{
	ToolTip, Canceled
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
			Tooltip, Pasting...
			if (R_lf)
			{
			if (Substr(Clipboard,-1) == "`r`n")
			{
				CopyMessage = 
				StringTrimRight,Clipboard,clipboard,2
				Send, ^v
				sleep, %generalsleep%
				Loop
					IfExist,cache\clips\%cursave%.avc
						break
				CopyMessage = Transfered to Clipjump
			}
			else
			{
				If (Substr(Clipboard,-11) == "   --[PATH][")
				{
					StringTrimRight,tempclip,Clipboard,12
					SendInput {RAW} %tempclip%
				}
				else
				{
				CopyMessage = 
				Send, ^v
				sleep, %generalsleep%
				Loop
					IfExist,cache\clips\%cursave%.avc
						break
				CopyMessage = Transfered to Clipjump
				}
			}
			}
			else
			{
			If (Substr(Clipboard,-11) == "   --[PATH][")
				{
				StringTrimRight,tempclip,Clipboard,12
				SendInput {RAW} %tempclip%
				}
				else
				{
				CopyMessage = 
				Send, ^v
				sleep, %generalsleep%
				Loop
					IfExist,cache\clips\%cursave%.avc
						break
				CopyMessage = Transfered to Clipjump
				}
			}
			tempsave := realactive
		}
SetTimer,ctrlcheck,Off
caller := true , in_back := false , tempclip := "" , ctrlref := ""
sleep, 700
Tooltip
Hotkey,^S,Ssuspnd,Off
Hotkey,^c,MoveBack,Off
Hotkey,^x,Cancel,Off
Hotkey,^Space,Fixate,Off
Hotkey,^x,Deleteall,Off
Hotkey,^x,Delete,Off
;;
Hotkey,$^c,NativeCopy,On
Hotkey,$^x,NativeCut,On
;;
EmptyMem()
}
return

Ssuspnd:
SetTimer,ctrlcheck,Off
ctrlref := "" , tempsave := realactive
Hotkey,^c,MoveBack,Off
Hotkey,^x,Cancel,Off
Hotkey,^Space,Fixate,Off
Hotkey,^x,Deleteall,Off
Hotkey,^x,Delete,Off
Hotkey,^S,Ssuspnd,Off
;;
Hotkey,$^c,NativeCopy,On
Hotkey,$^x,NativeCut,On
;;
in_back := false , caller := false
addtowinclip(realactive, "has Clip " . realclipno)
caller := true
Gui, hide
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
LastClip := 
FileDelete,cache\clips\*.avc
FileDelete,cache\thumbs\*.jpg
FileDelete,cache\fixate\*.fxt
cursave := 0 , tempsave := 0
return

clearclip:
LastClip := 
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
if FileExist(A_ScriptDir . "\cache\thumbs\" . tempsave . ".jpg")
{
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
ay := ay + (scrnhgt / 8)
Gui, Show, x%ax% y%ay% h%displayh% w%displayw%, Display_Cj
}
return

;**************** SETTINGS ************************************************************************************
TvClick:
if (A_GuiEvent == "DoubleClick") or (Tv_Enter = 1)
{
	Gui, 3:Default
	GuiControl,3:,settings_savestatus,
	TV_GetText( tv_outkey, TV_GetSelection() ) , TV_GetText( tv_outsec, TV_GetParent(TV_GetSelection()) ) , Tv_Enter := 0
	if (tv_outkey != tv_outsec)
	{
		tv_outkey_formatted := tv_outkey
		StringReplace,tv_outkey,tv_outkey,%A_space%,_,ALL
		StringReplace,tv_outsec,tv_outsec,%A_space%,_,ALL
		settings_edit := _IniRead("settings.ini", tv_outsec, tv_outkey, settings_dtext)
		GuiControl,3:,settings_dtext,% settings_dtext
		GuiControl,3:,settings_edit,% settings_edit
	}
}
return

3ButtonSave:
Gui,3:Submit,Nohide
Iniwrite,%settings_edit%,settings.ini,%tv_outsec%,%tv_outkey%
GuiControl,3:,settings_savestatus,% "Settings for " tv_outkey_formatted " saved"
return

;**************** HISTORY *******************************************************************************

Historyclick:
if A_GuiEvent = DoubleClick
{
	LV_GetText(clip_file_path, A_EventInfo, 3)
	if Instr(clip_file_path, ".jpg")
	{
		GuiControl,5:move,history_text,w0 h0
		Guicontrol,5:move,history_pic,w530 h320
		Guicontrol,5:,history_pic,*w530 *h320 cache\history\%clip_file_path%
		history_text_act := false
	}
	else
	{
		GuiControl,5:move,history_text,w530 h320
		Guicontrol,5:move,history_pic,w0 h0
		Lv_GetText(clip_text, A_eventinfo, 1)
		GuiControl,5:,history_text,% clip_text
		history_text_act := true
	}
	Gui, 5:Show, w531 h379, Clip Preview
}
else if A_GuiEvent = R
{
	LV_GetText(clip_file_path, A_EventInfo, 3)
	Menu, HisMenu, Show, %A_guix%, %A_guiy%
}
return

history_edit:
Gui, 4:Default
Gui,4:Submit,nohide
HistoryUpdate(history_edit)
return

history_delete:
Gui,4:submit,nohide
FileDelete, cache\history\%clip_file_path%
Guicontrol,4:focus,history_edit
Gui, 4:Default
HistoryUpdate(history_edit)
return

history_clipboard:
if !Instr(clip_file_path, ".jpg")
{
	FileRead,temp_read,cache\history\%clip_file_path%
	Clipboard := temp_read
}
return

4ButtonDelete_All:
FileDelete,cache\history\*
HistoryUpdate()
return

5ButtonCopy_to_Clipboard:
if history_text_act
	Clipboard := clip_text
else
{
	FileCreateDir,Restored images
	temp_a_now := A_now
	Filecopy,cache\history\%clip_file_path%,Restored images\%temp_a_now%.jpg
	run, Restored images
	loop,
		if winexist("Restored images")
			break
	Send,% temp_a_now
}
return

;********** INSIDE *********

historycleanup:
cur_time := A_now
Envadd,cur_time,-%days_to_store%,D
loop, cache\history\*
{
	temp_file_name := Substr(A_LoopFileName,1,-4)
	EnvSub,temp_file_name,cur_time,S
	if temp_file_name < 0
		FileDelete,cache\history\%A_loopfilename%
}
return

HistoryUpdate(crit=""){
LV_Delete()
loop, cache\history\*
{
	if Instr(A_loopfilefullpath, ".hst")
		Fileread,lv_temp,%A_LoopFileFullPath%
	else
		lv_temp := "<IMAGE ! CANT BE SHOWN AS TEXT>"
	
	if Instr(lv_temp, crit)
	{
		lv_date := Substr(A_loopfilename,7,2) "/" Substr(A_loopfilename,5,2) " , " Substr(A_loopfilename,9,2) ":" Substr(A_loopfilename,11,2)
		LV_Add("", lv_temp, lv_date, A_loopfilename)	;not parsing here to maximize speed
	}
}
LV_ModifyCol(1, "600") , LV_ModifyCol(2, "120 NoSort") , Lv_ModifyCol(3, "1")
}

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
BrowserRun("http://avi-win-tips.blogspot.com/2013/04/Clipjump-online-guide.html")
return

settings:
GuiControl,3:,settings_savestatus,
Gui, 3:Show, w547 h462, Clipjump Settings Editor
return
history:
Gui, 4:Default
HistoryUpdate()
Gui, 4:Show, w724 h526, Clipjump History Tool
return
main:
Gui, 2:Show, x416 y126 h354 w557, Clipjump v%version%
return

2GuiClose:
gui, 2:hide
EmptyMem()
return

3GuiClose:
gui, 3:hide
MsgBox, 36, Notification, New settings will take effect after Clipjump restart.`nDo you want to reload Clipjump?
IfMsgBox, Yes
	Reload
return

strtup:
Menu,Tray,Togglecheck,Run At Start Up
IfExist, %a_startup%/Clipjump.lnk
	FileDelete,%a_startup%/Clipjump.lnk
else
	FileCreateShortcut,%A_ScriptFullPath%,%A_Startup%/Clipjump.lnk
return

updt:
URLDownloadToFile,%updatefile%,%a_scriptdir%/cache/latestversion.txt
FileRead,latestversion,%a_scriptdir%/cache/latestversion.txt
IfGreater,latestversion,%version%
{
MsgBox, 48, Update Available, Your Version = %version%         `nCurrent Version = %latestversion%       `n`nGo to Website
IfMsgBox OK
	BrowserRun(productpage)
}
else
	MsgBox, 64, Clipjump, No Updates Available
return

installationopen:
run, %a_scriptdir%/help files/Clipjump_offline_help.html
return

blog:
BrowserRun("www.avi-win-tips.blogspot.com")
return

;******FUNCTIONS*************************************************

addtowinclip(lastentry, extratip)
{
ToolTip, System Clipboard %extratip%
IfNotEqual,cursave,0
	fileread,Clipboard,*c %A_ScriptDir%/cache/clips/%lastentry%.avc

IF (Substr(Clipboard,-11) == "   --[PATH][")
	StringTrimRight,Clipboard,Clipboard,12
sleep, 1000
ToolTip
}

;#################### COMMUNICATION ##########################################

Receive_WM_COPYDATA(wParam, lParam)
{
	global caller
    StringAddress := NumGet(lParam + 2*A_PtrSize)  ; Retrieves the CopyDataStruct's lpData member.
    caller := StrGet(StringAddress)  ; Copy the string out of the structure.
}
;##############################################################################
#Include, lib/imagelib.ahk
#include, lib/gdiplus.ahk
#include, lib/_ini.ahk
#include, lib/anticj_func_labels.ahk

;# 	window native shortcuts
#IfWinActive, Clipjump History Tool
{
	$Rbutton::Send, {Rbutton 2}
}
#IfWinActive
#IfWinActive, Clipjump Settings Editor
{
	~Enter::
	Tv_Enter := 1
	gosub, Tvclick
	return
}
#IfWinActive