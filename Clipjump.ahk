/*
	Clipjump
	
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

;@Ahk2Exe-SetName Clipjump
;@Ahk2Exe-SetDescription Clipjump
;@Ahk2Exe-SetVersion 6.0b1
;@Ahk2Exe-SetCopyright (C) 2013 Avi Aryan
;@Ahk2Exe-SetOrigFilename Clipjump.exe

SetWorkingDir, %A_ScriptDir%
SetBatchLines,-1
SetKeyDelay, -1
#SingleInstance, force
CoordMode,Mouse

;*********Program Vars**********************************************************
; Capitalised variables (here and everywhere) indicate that they are global

global PROGNAME := "Clipjump"
global VERSION := "6.0b1"
global CONFIGURATION_FILE := "settings.ini"
global UPDATE_FILE := "https://dl.dropboxusercontent.com/u/116215806/Products/Clipjump/Clipjumpversion.txt"
global PRODUCT_PAGE := "http://avi-win-tips.blogspot.com/p/Clipjump.html"
global HELP_PAGE := "http://avi-win-tips.blogspot.com/2013/04/Clipjump-online-guide.html"
global AUTHOR_PAGE := "www.avi-win-tips.blogspot.com"

global MSG_TRANSFER_COMPLETE := "Transferred to " PROGNAME
global MSG_CLIPJUMP_EMPTY := PROGNAME " is empty"
global MSG_ERROR := "[The preview/path cannot be loaded]"
global MSG_MORE_PREVIEW := "[More]"
global MSG_PASTING := "Pasting..."
global MSG_DELETED := "Deleted"
global MSG_ALL_DELETED := "All data deleted"
global MSG_CANCELLED := "Cancelled"
global MSG_FIXED := "[FIXED]"
global MSG_HISTORY_PREVIEW_IMAGE := "[Double-click to view image]"
global MSG_FILE_PATH_COPIED := "File path(s) copied to " PROGNAME
global MSG_FOLDER_PATH_COPIED := "Active folder path copied to " PROGNAME

;*******************************************************************************
Clipboard := ""
Iniread, ini_Version, %CONFIGURATION_FILE%, System, Version

If (!FileExist(CONFIGURATION_FILE) or ini_Version != VERSION)
{
;Faster
dataToBeAdded =
( LTrim
	[Main]
	limit_MaxClips=1
	;Will Clipjump's Clipboard be limited ! 1 = yes
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
	[System]
	Wait_Key=200
	;Dont Edit (decrease) this key. 
	Version=%VERSION%
	;Current Clipjump Version
	[Clipboard_History]
	Days_to_store=10
	;Number of days for which the clipboard record will be stored
	Store_Images=1
	;Should clipboard images be stored in history ?``n1=yes``n0=no
)

	FileDelete, %CONFIGURATION_FILE%
	FileAppend, %dataToBeAdded%, %CONFIGURATION_FILE%
	FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%/Clipjump.lnk
	
	MsgBox, 52, Recommended, It seems that you are running Clipjump v5.0 for the first time.`nDo you want to see ONLINE GUIDE before using ? `nDon't worry `, it won't take more than 10 minutes.`n`nNote that Clipjump doesn't have a offline help.
	IfMsgBox, Yes
		gosub, hlp
}

;Global Ini declarations
global ini_IsImageStored , ini_Quality , ini_MaxClips , ini_Threshold
load_Settings()

if !ini_MaxClips			; if blank
	ini_MaxClips := 9999999
if ini_MaxClips is not integer
	ini_MaxClips := 20
If ini_Threshold is not integer
	ini_Threshold := 10

global CopyMessage := ini_IsMessage = 0 ? "" : MSG_TRANSFER_COMPLETE

If ini_Quality is not Integer
	ini_Quality := 20
if ini_KeepSession is not integer
	ini_KeepSession := 1

ini_RemoveLineFeeds := ini_RemoveLineFeeds = 0 ? 0 : 1

if ini_GeneralSleep is not Integer
	ini_GeneralSleep := 200
if ini_GeneralSleep < 200
	ini_GeneralSleep := 200

if !ini_KeepSession
	clearData()

ini_IsImageStored := ini_IsImageStored = 0 ? 0 : 1
ini_DaysToStore := ini_DaysToStore < 0 ? 0 : (ini_DaysToStore > 200 ? 200 : ini_DaysToStore)	;A max 200 days is allowed.
gosub, historyCleanup

global TOTALCLIPS := ini_Threshold + ini_MaxClips
global CURSAVE, TEMPSAVE, LASTCLIP

loop
{
	IfNotExist, cache/Clips/%A_Index%.avc
	{
		CURSAVE := A_Index - 1 , TEMPSAVE := CURSAVE
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

;ClipboardHistory GUI
Gui, 4:Default
Gui, 4:+Resize
Gui, 4:Font, S18
Gui, 4:Add, Text, x0 y0 w724 h40 +Center, Clipjump Clipboard History		;Static1
Gui, 4:Font, S8 CBlack, Consolas
Gui, 4:Add, ListView, x2 y90 w720 r20 ghistoryclick vhistorylist, Clip|Date|Hiddendate		;600|120|1

Gui, 4:Font, S13
Gui, 4:Add, Text, x2 y50 w100 h30 , Search
Gui, 4:Font, S12 CBlack
Gui, 4:Add, Edit, x242 y50 w470 h30 ghistory_edit vhistory_edit
Gui, 4:Font, S10 CGreen
Gui, 4:Add, Text, x2 y470 w610 h40 , Double Click to open a clip`nRight Click to see context menu		;Static3
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
Menu, Tray, NoStandard
Menu, Tray, Add, %PROGNAME%, main
Menu, Tray, Tip, %PROGNAME% by Avi Aryan
if !(A_isCompiled)
	Menu, Tray, Icon, iconx.ico
Menu, Tray, Add		; separator
Menu, Tray, Add, Clipboard History		(Win+C), history
Menu, Tray, Add		; separator
Menu, Tray, Add, Preferences, settings
Menu, Tray, Add, Run At Start Up, strtup
Menu, Tray, Add, Check for Updates, updt
Menu, Tray, Add		; separator
Menu, Tray, Add, Readme, rdme
Menu, Tray, Add, See Online Help, hlp
Menu, Tray, Add		; separator
Menu, Tray, Add, Quit, qt
Menu, Tray, Default, %PROGNAME%

;History Right-Click Menu
Menu, HisMenu, Add, Copy to Clipjump, history_clipboard
Menu, HisMenu, Add		; separator
Menu, HisMenu, Add, Delete, history_delete

;********************************************************************
;STARTUP
IfExist, %A_Startup%/Clipjump.lnk
{
	FileDelete, %A_Startup%/Clipjump.lnk
	FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%/Clipjump.lnk
	Menu, Tray, Check, Run at start up
}

FileCreateDir, cache
FileCreateDir, cache/clips
FileCreateDir, cache/thumbs
FileCreateDir, cache/fixate
FileCreateDir, cache/history
FileSetAttrib, +H, %A_ScriptDir%\cache

global CALLER := true
global IN_BACK := false

hkZ("$^v", "Paste")
hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
hkZ("^!c", "CopyFile") , hkZ("^!x", "CopyFolder")
hkZ("#c", "History")
;Environment
OnMessage(0x4a, "Receive_WM_COPYDATA")  ; 0x4a is WM_COPYDATA

EmptyMem()
return
;End Of Auto-Execute============================================

paste:
	Gui, Hide
	CALLER := false
	if IN_BACK
	{
		IN_BACK := false
		If (TEMPSAVE == 1)
			TEMPSAVE := CURSAVE
		else
			TEMPSAVE -= 1
	}
	IfNotExist,cache/clips/%TEMPSAVE%.avc
	{
		Tooltip, %MSG_CLIPJUMP_EMPTY% ;No Clip Exists
		sleep, 700
		Tooltip
		CALLER := true
	}
	else
	{
		hkZ("^c", "MoveBack") , hkZ("^x", "Cancel")
		hkZ("^Space", "Fixate")
		hkZ("^S", "Ssuspnd")

		FileRead, Clipboard, *c %A_ScriptDir%/cache/clips/%TEMPSAVE%.avc
		fixStatus := fixCheck()
		realclipno := CURSAVE - TEMPSAVE + 1
		if Clipboard =	; if blank
		{
			showPreview()
			ToolTip,% "Clip  " realClipNo " of " CURSAVE "  " fixStatus (WinExist("Display_Cj") ? "" : "`n" MSG_ERROR) 
			SetTimer, ctrlCheck, 50
		}
		else
		{
			length := strlen(Clipboard)
			IfGreater,length,200
			{
				StringLeft,halfclip,Clipboard, 200
				halfClip := halfClip . "`n`n" MSG_MORE_PREVIEW
			}
			else halfClip := Clipboard
			ToolTip,% "Clip " realclipno " of " CURSAVE "`t" GetClipboardFormat() "`t" fixstatus "`n`n" halfclip
			SetTimer, ctrlCheck, 50
		}
			realActive := TEMPSAVE
			TEMPSAVE -= 1
			If (TEMPSAVE == 0)
				TEMPSAVE := CURSAVE
	}
	return

onClipboardChange:
	Critical
	If CALLER
		if WinactiveOffice()
		{
			if Office_Const
				clipChange(ErrorLevel) , Office_Const := false
			CALLER := true
			Office_Const := true
		}
		else
			clipChange(Errorlevel)
	return

clipChange(ClipErrorlevel) {

	If ClipErrorlevel = 1
	{
		if ( Clipboard != LASTCLIP )
		{
			CURSAVE += 1
			clipSaver()
			LASTCLIP := clipboard
			FileAppend, %LASTCLIP%, cache\history\%A_Now%.hst
			ToolTip, %copyMessage%
			TEMPSAVE := CURSAVE
			if CURSAVE = %TOTALCLIPS%
				compacter()
		}
	}
	else If ClipErrorlevel = 2
	{
			CURSAVE += 1 , TEMPSAVE := CURSAVE , LASTCLIP := ""

			ToolTip, %copyMessage%
			thumbGenerator()
			if ini_IsImageStored
				FileCopy, cache\thumbs\%CURSAVE%.jpg, cache\history\%A_Now%.jpg
			clipSaver()
			if CURSAVE = %TOTALCLIPS%
				compacter()
	}
	sleep, 500
	ToolTip
	emptyMem()
}

moveBack:
	Gui, Hide
	IN_BACK := true
	TEMPSAVE := realActive + 1
	if realActive = %CURSAVE%
		TEMPSAVE := 1
	realActive := TEMPSAVE
	FileRead, clipboard, *c %A_ScriptDir%/cache/clips/%TEMPSAVE%.avc
	fixStatus := fixCheck()
	realClipNo := CURSAVE - TEMPSAVE + 1
	if Clipboard =	; if blank
	{
		showPreview()
		ToolTip, % "Clip " realclipno "of " CURSAVE "  " fixStatus (WinExist("Display_Cj") ? "" : "`n" MSG_ERROR)
		SetTimer, ctrlCheck, 50
	}
	else
	{
		length := strlen(Clipboard)
		if length > 200
		{
			StringLeft, halfClip, Clipboard, 200
			halfClip := halfClip "`n`n" MSG_MORE_PREVIEW
		}
		else halfClip := Clipboard
		ToolTip, % "Clip " realclipno " of " CURSAVE "`t" GetClipboardFormat() "`t" fixstatus "`n`n" halfclip
		SetTimer, ctrlCheck, 50
	}
	return

cancel:
	Gui, Hide
	ToolTip, Cancel paste operation`t(1)`nRelease Ctrl to confirm`nPress X to switch modes
	ctrlref := "cancel"
	hkZ("^Space", "fixate", 0)
	hkZ("^S", "Ssuspnd", 0)
	hkZ("^x", "Cancel", 0) , hkZ("^x", "Delete", 1)
	return

delete:
	ToolTip, Delete current`t`t(2)`nRelease Ctrl to confirm`nPress X to switch modes
	ctrlref := "delete"
	hkZ("^x", "Delete", 0) , hkZ("^x", "DeleteAll", 1)
	return

deleteall:
	Tooltip, Delete all`t`t(3)`nRelease Ctrl to confirm`nPress X to switch modes
	ctrlref := "deleteAll"
	hkZ("^x", "DeleteAll", 0) , hkZ("^x", "Cancel", 1)
	return

nativeCopy:
	Critical
	hkZ("$^c", "nativeCopy", 0)
	hkZ("$^c", "blocker")
	Send, ^c
	setTimer, ctrlforCopy, 50
	gosub, ctrlforCopy
	return

nativeCut:
	Critical
	hkZ("$^x", "nativeCut", 0)
	hkZ("$^x", "blocker")
	Send, ^x
	setTimer, ctrlforCopy, 50
	gosub, ctrlforCopy
	return

ctrlForCopy:
	if GetKeyState("Ctrl", "P") = 0		; if key is up
	{
		hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
		SetTimer, ctrlforCopy, Off
	}
	return

blocker:
	return

fixate:
	IfExist, cache\fixate\%realActive%.fxt
	{
		fixStatus := ""
		FileDelete, %A_ScriptDir%\cache\fixate\%realactive%.fxt
	}
	else
	{
		fixStatus := MSG_FIXED
		FileAppend, , %A_ScriptDir%\cache\fixate\%realActive%.fxt
	}
	if ( Clipboard == "" )	; if blank
		Tooltip, Clip %realclipno% of %CURSAVE% %fixstatus%`n
	else
		ToolTip % "Clip " realclipno " of " CURSAVE "`t" GetClipboardFormat() "`t" fixstatus "`n`n" halfclip
	return

clipSaver() {
	FileAppend, %ClipboardAll%, cache/clips/%CURSAVE%.avc
	Loop, %CURSAVE%
	{
		tempNo := CURSAVE - A_Index + 1
		IfExist, cache\fixate\%tempNo%.fxt
		{
			t_TempNo := tempNo + 1
			FileMove, cache\clips\%t_TempNo%.avc,	cache\clips\%t_TempNo%_a.avc
			FileMove, cache\clips\%tempNo%.avc,		cache\clips\%t_TempNo%.avc
			FileMove, cache\clips\%t_TempNo%_a.avc,	cache\clips\%tempNo%.avc
			IfExist, cache\thumbs\%tempNo%.jpg
			{
				FileMove, cache\thumbs\%t_TempNo%.jpg,	cache\thumbs\%t_TempNo%_a.jpg
				FileMove, cache\thumbs\%tempNo%.jpg,	cache\thumbs\%t_TempNo%.jpg
				FileMove, cache\thumbs\%t_TempNo%_a.jpg, cache\thumbs\%tempNo%.jpg
			}
			FileMove, cache\fixate\%tempNo%.fxt, cache\fixate\%t_TempNo%.fxt
		}
	}
}

fixCheck() {
	IfExist, cache\fixate\%TEMPSAVE%.fxt 	;TEMPSAVE is global
		Return "[FIXED]"
}

ctrlCheck:
	if !GetKeyState("Ctrl")
	{
		CALLER := 0
		Gui, Hide
		if ctrlRef = cancel
		{
			ToolTip, %MSG_CANCELLED%
			TEMPSAVE := CURSAVE
		}
		else if ctrlRef = deleteAll
		{
			Tooltip, %MSG_ALL_DELETED%
			clearData()
		}
		else if ctrlRef = delete
		{
			ToolTip, %MSG_DELETED%
			clearClip(realActive)
		}
		else
		{
			ToolTip, %MSG_PASTING%
			CopyMessage := ""
			Send, ^v
			Sleep, %ini_GeneralSleep%
			;~ Loop
			;~ {
				;~ IfExist, cache\clips\%CURSAVE%.avc
					;~ break
			;~ }
			copyMessage := MSG_TRANSFER_COMPLETE
			TEMPSAVE := realActive
		}
		SetTimer, ctrlCheck, Off
		CALLER := true , IN_BACK := false , tempClip := "" , ctrlRef := ""
		sleep 700
		ToolTip

		hkZ("^s", "ssuspnd", 0)
		hkZ("^Space", "fixate", 0)
		hkZ("^c", "moveBack", 0)
		hkZ("^x", "cancel", 0) , hkZ("^x", "DeleteAll", 0) , hkZ("^x", "Delete", 0)

		hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
		EmptyMem()
	}
	return

Ssuspnd:
	SetTimer, ctrlCheck, Off
	ctrlRef := ""
	TEMPSAVE := realActive

	hkZ("^Space", "fixate", 0)
	hkZ("^c", "moveBack", 0)
	hkZ("^s", "ssuspnd", 0)
	hkZ("^x", "cancel", 0) , hkZ("^x", "DeleteAll", 0) , hkZ("^x", "Delete", 0)

	hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")

	IN_BACK := CALLER := false
	addToWinClip(realactive, "has Clip " realclipno)
	CALLER := true
	Gui, Hide
	return

compacter() {
	loop, %ini_Threshold%
	{
		FileDelete, %A_ScriptDir%\cache\clips\%A_Index%.avc
		FileDelete, %A_ScriptDir%\cache\thumbs\%A_Index%.jpg
		FileDelete, %A_ScriptDir%\cache\fixate\%A_Index%.fxt
	}
	loop, %ini_MaxClips%
	{
		avcNumber := A_Index + ini_Threshold
		FileMove, %A_ScriptDir%/cache/clips/%avcnumber%.avc, %A_ScriptDir%/cache/clips/%A_Index%.avc
		FileMove, %A_ScriptDir%/cache/thumbs/%avcnumber%.jpg, %A_ScriptDir%/cache/thumbs/%A_Index%.jpg
		FileMove, %A_ScriptDir%/cache/fixate/%avcnumber%.fxt, %A_ScriptDir%/cache/fixate/%A_Index%.fxt
	}
	TEMPSAVE := CURSAVE := ini_MaxClips
}

clearData() {
	LASTCLIP := ""
	FileDelete, cache\clips\*.avc
	FileDelete, cache\thumbs\*.jpg
	FileDelete, cache\fixate\*.fxt
	CURSAVE := 0
	TEMPSAVE := 0
}

clearClip(realActive) {
	LASTCLIP := ""
	FileDelete, cache\clips\%realactive%.avc
	FileDelete, cache\thumbs\%realactive%.jpg
	FileDelete, cache\fixate\%realactive%.fxt
	TEMPSAVE := realActive - 1
	if (TEMPSAVE == 0)
		TEMPSAVE := 1
	gosub, renameCorrect
	CURSAVE -= 1
}

renameCorrect:
	loopTime := CURSAVE - realactive
	If loopTime != 0
	{
		loop, %loopTime%
		{
			newName := realActive
			realActive += 1
			FileMove, cache/clips/%realactive%.avc,	cache/clips/%newname%.avc
			FileMove, cache/thumbs/%realactive%.jpg, cache/thumbs/%newname%.jpg
			FileMove, cache/fixate/%realactive%.fxt, cache/fixate/%newname%.fxt
		}
	}
	return

thumbGenerator() {
	ClipWait, , 1
	Convert(0, A_ScriptDir "\cache\thumbs\" CURSAVE ".jpg", ini_Quality)
}

showPreview(){

	static scrnhgt := A_ScreenHeight / 2.5
	static scrnwdt := A_ScreenWidth / 2
	if FileExist(A_ScriptDir "\cache\thumbs\" TEMPSAVE ".jpg")
	{
		GDIPToken := Gdip_Startup()
		pBM := Gdip_CreateBitmapFromFile( A_ScriptDir "\cache\thumbs\" TEMPSAVE ".jpg" )
		widthOfThumb := Gdip_GetImageWidth( pBM )
		heightOfThumb := Gdip_GetImageHeight( pBM )  
		Gdip_DisposeImage( pBM )                                         
		Gdip_Shutdown( GDIPToken )

		if heightOfThumb > %scrnHgt%
			displayH := heightOfThumb / 2
		else displayH := heightofthumb
		if widthOfThumb > %scrnWdt%
			displayW := widthOfThumb / 2
		else displayW := widthOfThumb

		GuiControl, , imagepreview, *w%displayW% *h%displayH% cache\thumbs\%TEMPSAVE%.jpg
		MouseGetPos, ax, ay
		ay := ay + (scrnHgt / 8)
		Gui, Show, x%ax% y%ay% h%displayh% w%displayw%, Display_Cj
	}
}

;**************** SETTINGS ************************************************************************************

TvClick:
	if (A_GuiEvent == "DoubleClick") or (Tv_Enter = 1)
	{
		Gui, 3:Default
		GuiControl, 3:, settings_SaveStatus
		TV_GetText( tv_outkey, TV_GetSelection() )
		TV_GetText( tv_outsec, TV_GetParent(TV_GetSelection()) )
		TV_Enter := 0
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
	Gui, 3:Submit, Nohide
	Iniwrite, %settings_Edit%, %CONFIGURATION_FILE%, %tv_OutSec%, %tv_OutKey%
	GuiControl, 3:, settings_savestatus, % "Settings for " tv_Outkey_Formatted " saved"
	return

;**************** HISTORY *******************************************************************************

Historyclick:
	history_selected := LV_GetCount("S")
	if A_GuiEvent = DoubleClick
	{
		LV_GetText(clip_file_path, A_EventInfo, 3) , history_endsel := A_EventInfo
		
		if Instr(clip_file_path, ".jpg")
		{
			GuiControl, 5:move, history_Text, w0 h0
			Guicontrol, 5:move, history_Pic, w530 h320
			Guicontrol, 5:, history_Pic, *w530 *h320 cache\history\%clip_file_path%
			history_text_act := false 
		}
		else
		{
			GuiControl, 5:Move, history_Text, w530 h320
			Guicontrol, 5:Move, history_Pic, w0 h0
			Lv_GetText(clip_text, A_eventinfo, 1)
			GuiControl, 5:, history_Text, % clip_text
			history_Text_Act := true
		}
		Gui, 5:Show, w531 h379, Clip Preview
	}
	else if A_GuiEvent = R
	{
		LV_GetText(clip_file_path, A_EventInfo, 3) , history_endsel := A_EventInfo , Lv_GetText(clip_text, A_eventinfo, 1)
		history_text_act := Instr(clip_file_path, ".jpg") ? 0 : 1
		Menu, HisMenu, Show, %A_guix%, %A_guiy%
	}
	return

history_edit:
	Gui, 4:Default
	Gui, 4:Submit, NoHide
	HistoryUpdate(history_Edit, false)
	return

history_delete:
	Gui, 4:Default
	loop,% history_selected
	{
		LV_GetText(clip_file_path, history_endsel-A_index+1, 3)
		FileDelete,% "cache\history\" clip_file_path
	}
	Guicontrol, 4:focus, history_edit
	historyUpdate(history_edit, false)
	return

4ButtonDelete_All:
	MsgBox, 20, WARNING, This will delete all the clipboard history.`nDo you want to continue ?
	IfMsgBox, Yes
	{
		FileDelete, cache\history\*
		HistoryUpdate(" ", false)
	}
	return

history_clipboard:
5ButtonCopy_to_Clipboard:
	if history_Text_Act
		Clipboard := clip_Text
	else
	{
		FileCreateDir, Restored Images
		temp_A_Now := A_Now
		Filecopy, cache\history\%clip_file_path%, Restored Images\%temp_a_now%.jpg
		Run, Restored Images
		Loop
			if WinActive("Restored Images")
				break
		Send, % temp_A_Now
	}
	return

;********** INSIDE *********

historyCleanup:
	cur_Time := A_now
	Envadd, cur_Time, -%ini_DaysToStore%, D
	Loop, cache\history\*
	{
		temp_file_name := Substr(A_LoopFileName, 1, -4)
		EnvSub, temp_File_Name, cur_Time, S
		if temp_File_Name < 0
			FileDelete, cache\history\%A_LoopFileName%
	}
	return

HistoryUpdate(crit="", create=true)
{
	LV_Delete()
	loop, cache\history\*
	{
		if Instr(A_loopfilefullpath, ".hst")
			Fileread, lv_temp, %A_LoopFileFullPath%
		else
			lv_temp := MSG_HISTORY_PREVIEW_IMAGE
		
		if Instr(lv_temp, crit)
		{
			lv_Date := Substr(A_loopfilename,7,2) "/" Substr(A_loopfilename,5,2) " , " Substr(A_loopfilename,9,2) ":" Substr(A_loopfilename,11,2)
			LV_Add("", lv_Temp, lv_Date, A_LoopFileName)	;not parsing here to maximize speed
		}
	}
	if create
		LV_ModifyCol(1, "600") , LV_ModifyCol(2, "120 NoSort") , Lv_ModifyCol(3, "1")
}

;****************COPY FILE/FOLDER******************************************************************************

copyFile:
	copyMessage := MSG_FILE_PATH_COPIED
	selectedFile := GetFile()
	if ( selectedFile != "" )
		Clipboard := selectedfile
	Sleep, %ini_GeneralSleep%
	CopyMessage := MSG_TRANSFER_COMPLETE
	return

copyFolder:
	copyMessage := MSG_FOLDER_PATH_COPIED
	openedFolder := GetFolder()
	if ( openedfolder != "" )
		Clipboard := openedFolder
	Sleep, %ini_GeneralSleep%
	copyMessage := MSG_TRANSFER_COMPLETE
	return

;***************Extra Functions and Labels**********************************************************************
qt:
	ExitApp

rdme:
	Run, readme.txt
	return

hlp:
	BrowserRun(HELP_PAGE)
	return

settings:
	gui_Settings()
	return
	
history:
	Gui, 4:Default
	HistoryUpdate()
	Gui, 4:Show, w724 h526, %PROGNAME% History Tool
	return
	
main:
	Gui, 2:Show, x416 y126 h354 w557, %PROGNAME% v%VERSION%
	return

2GuiClose:
	Gui, 2:Hide
	EmptyMem()
	return

4GuiSize:
	Gui, 4:Default
	Anchor("historylist", "wh") , Anchor("Button1", "xy") , Anchor("Static3", "y") , Anchor("history_edit", "w") , Anchor("Static1", "w")
	LV_ModifyCol(1, A_Guiwidth-124)
	GuiControl, , Static1, Clipjump History Tool
	return

strtup:
	Menu, Tray, Togglecheck, Run at Start Up
	IfExist, %A_Startup%/Clipjump.lnk
		FileDelete, %A_Startup%/Clipjump.lnk
	else FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%/Clipjump.lnk
	return

updt:
	URLDownloadToFile, %UPDATE_FILE%, %A_ScriptDir%/cache/latestversion.txt
	FileRead, latestVersion, %A_ScriptDir%/cache/latestversion.txt
	if latestVersion > %VERSION%
	{
		MsgBox, 48, Update available, Your Version: %VERSION%         `nCurrent version = %latestVersion%       `n`nGo to website
		IfMsgBox OK
			BrowserRun(PRODUCT_PAGE)
	}
	else MsgBox, 64, Clipjump, No updates available
	return

installationopen:
	run, %A_ScriptDir%/help files/Clipjump_offline_help.html
	return

blog:
	BrowserRun(AUTHOR_PAGE)
	return

;******FUNCTIONS*************************************************

addToWinClip(lastEntry, extraTip)
{
	ToolTip, System Clipboard %extraTip%
	if CURSAVE
		FileRead, Clipboard, *c %A_ScriptDir%/cache/clips/%lastentry%.avc

	if (Substr(Clipboard, -11) == "   --[PATH][")
		StringTrimRight, Clipboard, Clipboard, 12
	Sleep, 1000
	ToolTip
}

GetClipboardFormat(){		;Thanks nnnik
  DllCall("OpenClipboard")
  while c := DllCall("EnumClipboardFormats","Int",c?c:0)
    x .= "," c
  DllCall("CloseClipboard")
  if Instr(x, ",1") and Instr(x, ",13")
    return "[Text]"
  else If Instr(x, ",15")
    return "[File/Folder]"
  else
    return "[Text]"
}

hkZ(HotKey, Label, Status=1) {
	Hotkey,% HotKey,% Label,% Status ? "On" : "Off"
}

WinActiveOffice(){
	;Not included - Word and Onenote
	var := "ahk_class XLMAIN,ahk_class rctrl_renwnd32,ahk_class Framework::CFrame,ahk_class OFFDOCCACHE,ahk_class CAG_STANDALONE,ahk_class PPTFrameClass"
	loop,parse,var,`,
		if WinActive(A_loopfield)
			return 1
}

;#################### COMMUNICATION ##########################################

Receive_WM_COPYDATA(wParam, lParam)
{
	global CALLER
    StringAddress := NumGet(lParam + 2*A_PtrSize)  ; Retrieves the CopyDataStruct's lpData member.
    CALLER := StrGet(StringAddress)  ; Copy the string out of the structure.
}

;##############################################################################
#Include, lib/imagelib.ahk
#include, lib/gdiplus.ahk
#include, lib/_ini.ahk
#include, lib/anticj_func_labels.ahk
#include, lib/anchor.ahk
#include, lib/settings gui plug.ahk

;# 	window native shortcuts
#If WinActive( "Clipjump History Tool")
{
	$Rbutton::Send, {Rbutton 2}
}
#IfWinActive
#If, WinActive(PROGNAME " Settings Editor")
{
	~Enter::
	Tv_Enter := 1
	gosub, Tvclick
	return
}
#IfWinActive