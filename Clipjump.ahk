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
;@Ahk2Exe-SetVersion 6.7
;@Ahk2Exe-SetCopyright (C) 2013 Avi Aryan
;@Ahk2Exe-SetOrigFilename Clipjump.exe

SetWorkingDir, %A_ScriptDir%
SetBatchLines,-1
#SingleInstance, force
CoordMode, Mouse
FileEncoding, UTF-8

;*********Program Vars**********************************************************
; Capitalised variables (here and everywhere) indicate that they are global

global PROGNAME := "Clipjump"
global VERSION := "6.7"
global CONFIGURATION_FILE := "settings.ini"
global UPDATE_FILE := "https://dl.dropboxusercontent.com/u/116215806/Products/Clipjump/clipjumpversion.txt"
global PRODUCT_PAGE := "http://avi-win-tips.blogspot.com/p/clipjump.html"
global HELP_PAGE := "http://avi-win-tips.blogspot.com/2013/04/clipjump-online-guide.html"
global AUTHOR_PAGE := "http://www.avi-win-tips.blogspot.com"

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
	FileDelete,% CONFIGURATION_FILE		;This is a nec. step to remove comments from prev. versions.
	
	IniWrite, 1, % CONFIGURATION_FILE, Main, limit_MaxClips
	IniWrite, 20,% CONFIGURATION_FILE, Main, Minimum_No_Of_Clips_to_be_Active
	IniWrite, 10,% CONFIGURATION_FILE, Main, Threshold
	IniWrite, 1, % CONFIGURATION_FILE, Main, Show_Copy_Message
	IniWrite, 90,% CONFIGURATION_FILE, Main, Quality_of_Thumbnail_Previews
	IniWrite, 1, % CONFIGURATION_FILE, Main, Keep_Session

	IniWrite, %VERSION%,% CONFIGURATION_FILE, System, Version

	IniWrite, 10,% CONFIGURATION_FILE, Clipboard_History, Days_to_store
	IniWrite, 1, % CONFIGURATION_FILE, Clipboard_History, Store_Images

	FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%/Clipjump.lnk
	
	MsgBox, 52, Recommended, Do you want to see the Clipjump help ?
	IfMsgBox, Yes
		gosub, hlp
}

;Global Ini declarations
global ini_IsImageStored , ini_Quality , ini_MaxClips , ini_Threshold , CopyMessage

load_Settings()		;loads ini settings
validate_Settings()		;validates ini settings

historyCleanup()

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

;Tray Icon
if !A_isCompiled			;Important for showing Cj's icon in the Titlebar of GUI
	Menu, Tray, Icon, iconx.ico

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
Gui, 2:Add, Text, x2 y290 w300 h30 ghlp, See Help file
Gui, 2:Font, S14 CBlack, Verdana
Gui, 2:Add, Text, x-8 y330 w560 h24 +Center, Copyright (C) 2013

;More GUIs can be seen in lib folder

;******************************************************************
;MENUS

;MAIN TRAY
Menu, Tray, NoStandard
Menu, Tray, Add, %PROGNAME%, main
Menu, Tray, Tip, %PROGNAME% by Avi Aryan
Menu, Tray, Add		; separator
Menu, Tray, Add, Clipboard History		(Win+C), history
Menu, Tray, Add		; separator
Menu, Tray, Add, Preferences, settings
Menu, Tray, Add, Run At Start Up, strtup
Menu, Tray, Add, Check for Updates, updt
Menu, Tray, Add		; separator
Menu, Tray, Add, Help, hlp
Menu, Tray, Add		; separator
Menu, Tray, Add, Quit, qt
Menu, Tray, Default, %PROGNAME%

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
global FORMATTING := true

hkZ("$^v", "Paste")
hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
hkZ("^!c", "CopyFile") , hkZ("^!x", "CopyFolder")
hkZ("#c", "History")
;Environment
OnMessage(0x4a, "Receive_WM_COPYDATA")  ; 0x4a is WM_COPYDATA
OnMessage(0x200, "WM_MOUSEMOVE")		; 0x200 is WM_MOUSEMOVE

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
		hkZ("^c", "MoveBack") , hkZ("^x", "Cancel") , hkZ("^Z", "Formatting")
		hkZ("^Space", "Fixate")
		hkZ("^S", "Ssuspnd")

		FileRead, Clipboard, *c %A_ScriptDir%/cache/clips/%TEMPSAVE%.avc
		fixStatus := fixCheck()
		realclipno := CURSAVE - TEMPSAVE + 1
		if Clipboard =	; if blank
			showPreview()
		else
		{
			length := strlen(Clipboard)
			IfGreater,length,200
			{
				StringLeft,halfclip,Clipboard, 200
				halfClip := halfClip . "`n`n" MSG_MORE_PREVIEW
			}
			else halfClip := Clipboard
		}
		PasteModeTooltip()
		SetTimer, ctrlCheck, 50

		realActive := TEMPSAVE
		TEMPSAVE -= 1
		If (TEMPSAVE == 0)
			TEMPSAVE := CURSAVE
	}
	return

onClipboardChange:
	Critical, On
	If CALLER
	{
		sleep, 200		;Wait for the 2nd transfer in Office products OR any other apps
		clipChange(ErrorLevel)
		SetTimer, Empty_Lastclip, 3000 		;Emptying the clipboard to avoid user annoyances when copying items with same text
	}
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
		showPreview()
	else
	{
		length := strlen(Clipboard)
		if length > 200
		{
			StringLeft, halfClip, Clipboard, 200
			halfClip := halfClip "`n`n" MSG_MORE_PREVIEW
		}
		else halfClip := Clipboard
	}
	PasteModeTooltip()
	SetTimer, ctrlCheck, 50

	return

cancel:
	Gui, Hide
	ToolTip, Cancel paste operation`t(1)`nRelease Ctrl to confirm`nPress X to switch modes
	ctrlref := "cancel"
	hkZ("^Space", "fixate", 0) , hkZ("^Z", "Formatting", 0)
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

Formatting:
	FORMATTING := !FORMATTING
	PasteModeTooltip()
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
	PasteModeTooltip()
	return

clipSaver() {
	FileDelete, cache/clips/%CURSAVE%.avc
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

;Shows the Clipjump Paste Mode tooltip
PasteModeTooltip() {
	global
	if ( Clipboard == "" )	; if blank
		ToolTip % "Clip " realclipno " of " CURSAVE "`t" fixStatus (WinExist("Display_Cj") ? "" : "`n`n" MSG_ERROR)
	else
		ToolTip, % "Clip " realclipno " of " CURSAVE "`t" GetClipboardFormat() "`t" fixstatus (!FORMATTING ? "`t[NO-FORMATTING]" : "") "`n`n" halfclip
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

			if !FORMATTING
			{
				if Instr(GetClipboardFormat(), "Text")
					Clipboard .= "" 		;This is how I remove formatting
				Send, ^v
			}
			else
				Send, ^v

			copyMessage := MSG_TRANSFER_COMPLETE
			TEMPSAVE := realActive
		}
		SetTimer, ctrlCheck, Off
		IN_BACK := false , tempClip := "" , ctrlRef := ""

		hkZ("^s", "ssuspnd", 0)
		hkZ("^Space", "fixate", 0) , hkZ("^Z", "Formatting", 0)
		hkZ("^c", "moveBack", 0)
		hkZ("^x", "cancel", 0) , hkZ("^x", "DeleteAll", 0) , hkZ("^x", "Delete", 0)

		hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
		
		EmptyMem()
		sleep, 700
		
		ToolTip
		CALLER := true
	}
	return

Ssuspnd:
	SetTimer, ctrlCheck, Off
	ctrlRef := ""
	TEMPSAVE := realActive

	hkZ("^Space", "fixate", 0) , hkZ("^Z", "Formatting", 0)
	hkZ("^c", "moveBack", 0)
	hkZ("^s", "Ssuspnd", 0)
	hkZ("^x", "cancel", 0) , hkZ("^x", "DeleteAll", 0) , hkZ("^x", "Delete", 0)

	hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")

	IN_BACK := CALLER := false
	addToWinClip(realactive , "has Clip " realclipno)
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
	renameCorrect(realActive)
	CURSAVE -= 1
}

renameCorrect(realActive) {
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
}

thumbGenerator() {
	ClipWait, , 1
	Gdip_CaptureClipboard(A_ScriptDir "\cache\thumbs\" CURSAVE ".jpg", ini_Quality)
}

;~ ;**************** GUI Functions ***************************************************************************

showPreview(){

	static scrnhgt := A_ScreenHeight / 2.5 , scrnwdt := A_ScreenWidth / 2 , displayH , displayW

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

historyCleanup()
;Cleans history in bunch
{
	global
	local cur_Time , temp_file_name
	cur_Time := A_now
	Envadd, cur_Time, -%ini_DaysToStore%, D
	Loop, cache\history\*
	{
		temp_file_name := Substr(A_LoopFileName, 1, -4)
		EnvSub, temp_File_Name, cur_Time, S
		if temp_File_Name < 0
			FileDelete, cache\history\%A_LoopFileName%
	}
}

;****************COPY FILE/FOLDER******************************************************************************

copyFile:
	copyMessage := MSG_FILE_PATH_COPIED
	selectedFile := GetFile()
	if ( selectedFile != "" )
		Clipboard := selectedfile
	CopyMessage := MSG_TRANSFER_COMPLETE
	return

copyFolder:
	copyMessage := MSG_FOLDER_PATH_COPIED
	openedFolder := GetFolder()
	if ( openedfolder != "" )
		Clipboard := openedFolder
	copyMessage := MSG_TRANSFER_COMPLETE
	return

;***************Extra Functions and Labels**********************************************************************

Empty_Lastclip:
	SetTimer, Empty_lastclip, Off
	LASTCLIP := ""
	return

qt:
	ExitApp

hlp:
	run Clipjump.chm
	return

settings:
	Gui, 2:Hide
	gui_Settings()
	return
	
history:
	Gui, 2:Hide
	gui_History()
	return
	
main:
	Gui, 2:Show, x416 y126 h354 w557, %PROGNAME% v%VERSION%
	return

2GuiClose:
	Gui, 2:Hide
	EmptyMem()
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

blog:
	BrowserRun(AUTHOR_PAGE)
	return

;****** Helper FUNCTIONS ****************************************

addToWinClip(lastEntry, extraTip)
{
	ToolTip, System Clipboard %extraTip%
	if CURSAVE
		FileRead, Clipboard, *c %A_ScriptDir%/cache/clips/%lastentry%.avc
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

;The below func is not used at all in Clipjump but is kept as a reference
WinActiveOffice(){
	;Not included - Word, ppt and Onenote
	var := "ahk_class XLMAIN,ahk_class rctrl_renwnd32,ahk_class Framework::CFrame,ahk_class OFFDOCCACHE,ahk_class CAG_STANDALONE"
	loop,parse,var,`,
		if WinActive(A_loopfield)
			return 1
}

;The function enables/disables Clipjump with respect to the Communicator.
;In Communicator , use
;	 0 to disable just clipboard monitoring
;	-1 to disable ^v Paste mode as well
;	-2 to disable Clipjump History shortcut #c as well
;Use 1 to enable at all times
Act_CjControl(C){
	global
	local p

	p := C ? 1 : 0 , CALLER := p
	hkZ("$^c", "NativeCopy", p) , hkZ("$^x", "NativeCut", p)
	hkZ("^!c", "CopyFile", p) , hkZ("^!x", "CopyFolder", p)
	;Special changes
	T := C<-1 ? hkZ("#c", "History", 0) : hkZ("#c", "History", 1)
	T := C<0 ?  hkZ("$^v", "Paste", 0)  : hkZ("$^v", "Paste", 1)
}

;#################### COMMUNICATION ##########################################

Receive_WM_COPYDATA(wParam, lParam)
{
	global
    Local StringAddress := NumGet(lParam + 2*A_PtrSize)  ; Retrieves the CopyDataStruct's lpData member.
    Act_CjControl( StrGet(StringAddress) ) 				; Copy the string out of the structure.
}

;##############################################################################
;#include, lib/gdiplus.ahk
#include, %A_ScriptDir%\lib\Gdip_All.ahk
#include, %A_ScriptDir%\lib\anticj_func_labels.ahk
#include, %A_ScriptDir%\lib\settings gui plug.ahk
#include, %A_ScriptDir%\lib\history gui plug.ahk

;------------------------------------------------------------------- X --------------------------------------------------------------------------------------