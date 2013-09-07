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
;@Ahk2Exe-SetVersion 8.4
;@Ahk2Exe-SetCopyright (C) 2013 Avi Aryan
;@Ahk2Exe-SetOrigFilename Clipjump.exe

SetWorkingDir, %A_ScriptDir%
SetBatchLines,-1
#SingleInstance, force
#ClipboardTimeout 50              ;keeping this value low as I already check for OpenClipboard in OnClipboardChange label
CoordMode, Mouse
FileEncoding, UTF-8
#HotkeyInterval 1000
#MaxHotkeysPerInterval 1000

;*********Program Vars**********************************************************
; Capitalised variables (here and everywhere) indicate that they are global

global PROGNAME := "Clipjump"
global VERSION := "8.4"
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

Loop, cache\history\*.hst                 ;Rename old .hst extensions
{
	SplitPath, A_LoopFileName,,,, fileNameNoExt
	FileMove, %A_LoopFileDir%\%fileNameNoExt%.hst, %A_LoopFileDir%\%fileNameNoExt%.txt, 1
}

;*******************************************************************************

;Init Non-Ini Configurations
Clipboard := ""
FileDelete, % A_temp "/clipjumpcom.txt"

;Global Data Holders
Sysget, temp, MonitorWorkArea
global WORKINGHT := tempbottom-temptop

;Global Inits
global CN := {} , TOTALCLIPS
global CURSAVE, TEMPSAVE, LASTCLIP, LASTFORMAT
global NOINCOGNITO := 1

;Ini Configurations
Iniread, ini_Version, %CONFIGURATION_FILE%, System, Version

If !FileExist(CONFIGURATION_FILE)
{
	save_default(1)
	;FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%/Clipjump.lnk
	
	MsgBox, 52, Recommended, Do you want to see the Clipjump help ?
	IfMsgBox, Yes
		gosub, hlp

	if !A_IsAdmin
		MsgBox, 16, WARNING, Clipjump is not running as Administrator`nThis (may) cause improper functioning of the program`nIf it does, you know what to do.

	if !A_isUnicode
		MsgBox, 16, WARNING, It is recommended to use AHK_L Unicode for using Clipjump.`nIf you are using some another version`, you can but remember my word.`n`nDon't Worry `,this message will be shown just once .

	try {
		TrayTip, Clipjump, Hi!`nClipjump is now activated.`nTry doing some quick copy and pastes..., 10, 1
	}
}
else if (ini_Version != VERSION)
	save_default(0) 			;0 corresponds to selective save


;Global Ini declarations
global ini_IsImageStored , ini_Quality , ini_MaxClips , ini_Threshold , ini_IsChannelMin := 1 , CopyMessage
		, Copyfolderpath_K, Copyfilepath_K, Copyfilepath_K, channel_K, onetime_K

;loading Settings
load_Settings(1)
trayMenu()
validate_Settings()

;Clean History
historyCleanup()

;Initialising Clipjump Channels
initChannels()

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

;More GUIs and Menus can be seen in lib folder

;********************************************************************
;STARTUP
IfExist, %A_Startup%/Clipjump.lnk
{
	FileDelete, %A_Startup%/Clipjump.lnk
	FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%/Clipjump.lnk
	Menu, Tray, Check, Run at startup
}

;Creating Storage Directories
FileCreateDir, cache
FileCreateDir, cache/clips
FileCreateDir, cache/thumbs
FileCreateDir, cache/fixate
FileCreateDir, cache/history
FileSetAttrib, +H, %A_ScriptDir%\cache

;Initailizing Common Variables
global CALLER := true
	, IN_BACK := false
	, FORMATTING := true

global CLIPS_dir := "cache/clips"
	, THUMBS_dir := "cache/thumbs"
	, FIXATE_dir := "cache/fixate"

;Setting Up shortcuts
hkZ("$^v", "Paste")
hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
hkZ(Copyfilepath_K, "CopyFile") , hkZ(Copyfolderpath_K, "CopyFolder")
hkZ(history_K, "History")
hkZ(Copyfiledata_K, "CopyFileData")
hkZ(channel_K, "channelGUI")
hkZ(onetime_K, "oneTime")

;Environment
OnMessage(0x4a, "Receive_WM_COPYDATA")  ; 0x4a is WM_COPYDATA

EmptyMem()
return

;End Of Auto-Execute================================================================================================================

paste:
	Gui, 1:Hide
	CALLER := false
	ctrlRef := "pastemode"
	if IN_BACK
	{
		IN_BACK := false
		If (TEMPSAVE == 1)
			TEMPSAVE := CURSAVE
		else
			TEMPSAVE -= 1
	}
	If !FileExist(CLIPS_dir "/" TEMPSAVE ".avc")
	{
		Tooltip, %MSG_CLIPJUMP_EMPTY% 			;No Clip Exists
		sleep, 700
		Tooltip
		CALLER := true
	}
	else
	{
		if !oldclip_exist
		{
			oldclip_exist := 1
			oldclip_data := ClipboardAll       			;no single line
		}
		hkZ_Group(1)

		FileRead, Clipboard, *c %A_ScriptDir%/%CLIPS_dir%/%TEMPSAVE%.avc
		fixStatus := fixCheck()
		realclipno := CURSAVE - TEMPSAVE + 1

		if Clipboard =
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
		makeClipboardAvailable()
		if ( LASTFORMAT != (LASTFORMAT := GetClipboardFormat(0)) ) or ( LASTCLIP != Clipboard ) or ( Clipboard == "" )
			clipChange(A_EventInfo)
	}
	else
	{
		LASTFORMAT := GetClipboardFormat(0)
		if onetimeOn
		{
			onetimeOn := 0 ;--- To avoid OnClipboardChange label to open this routine [IMPORTANT]
			sleep 500 ;--- Allows the restore Clipboard Transfer in apps
			CALLER := true
			ToolTip, One Time Stop Deactivated
			SetTimer, TooltipOff, 600
		}
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

			if NOINCOGNITO
				FileAppend, %LASTCLIP%, cache\history\%A_Now%.txt

			ToolTip, %copyMessage%
			TEMPSAVE := CURSAVE
			if ( CURSAVE >= TOTALCLIPS )
				compacter()
		}
	}
	else If ClipErrorlevel = 2
	{
			CURSAVE += 1 , TEMPSAVE := CURSAVE , LASTCLIP := ""
			ToolTip, %copyMessage%
			thumbGenerator()

			if NOINCOGNITO and ini_IsImageStored
				FileCopy, %THUMBS_dir%\%CURSAVE%.jpg, cache\history\%A_Now%.jpg

			clipSaver()
			if ( CURSAVE >= TOTALCLIPS )
				compacter()
	}
	SetTimer, TooltipOff, 500
	emptyMem()
}

moveBack:
	Gui, 1:Hide
	IN_BACK := true
	TEMPSAVE := realActive + 1
	if realActive = %CURSAVE%
		TEMPSAVE := 1
	realActive := TEMPSAVE
	FileRead, clipboard, *c %CLIPS_dir%/%TEMPSAVE%.avc
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
	hkZ("$^c", "nativeCopy", 0) , hkZ("$^c", "keyblocker")
	LASTCLIP := "" 
	Send, ^c
	setTimer, ctrlforCopy, 50
	gosub, ctrlforCopy
	return

nativeCut:
	Critical
	hkZ("$^x", "nativeCut", 0) , hkZ("$^x", "keyblocker")
	LASTCLIP := ""
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

Formatting:
	FORMATTING := !FORMATTING
	PasteModeTooltip()
	return

fixate:
	IfExist, %FIXATE_dir%\%realActive%.fxt
	{
		fixStatus := ""
		FileDelete, %A_ScriptDir%\%FIXATE_dir%\%realactive%.fxt
	}
	else
	{
		fixStatus := MSG_FIXED
		FileAppend, , %A_ScriptDir%\%FIXATE_dir%\%realActive%.fxt
	}
	PasteModeTooltip()
	return

clipSaver() {
	FileDelete, %CLIPS_dir%/%CURSAVE%.avc

	makeClipboardAvailable()
	FileAppend, %ClipboardAll%, %CLIPS_dir%/%CURSAVE%.avc

	Loop, %CURSAVE%
	{
		tempNo := CURSAVE - A_Index + 1
		IfExist, %FIXATE_dir%\%tempNo%.fxt
		{
			t_TempNo := tempNo + 1
			FileMove, %CLIPS_dir%\%t_TempNo%.avc,	%CLIPS_dir%\%t_TempNo%_a.avc
			FileMove, %CLIPS_dir%\%tempNo%.avc,		%CLIPS_dir%\%t_TempNo%.avc
			FileMove, %CLIPS_dir%\%t_TempNo%_a.avc,	%CLIPS_dir%\%tempNo%.avc
			IfExist, %THUMBS_dir%\%tempNo%.jpg
			{
				FileMove, %THUMBS_dir%\%t_TempNo%.jpg,	%THUMBS_dir%\%t_TempNo%_a.jpg
				FileMove, %THUMBS_dir%\%tempNo%.jpg,	%THUMBS_dir%\%t_TempNo%.jpg
				FileMove, %THUMBS_dir%\%t_TempNo%_a.jpg, %THUMBS_dir%\%tempNo%.jpg
			}
			FileMove, %FIXATE_dir%\%tempNo%.fxt, %FIXATE_dir%\%t_TempNo%.fxt
		}
	}

}

fixCheck() {
	IfExist, %FIXATE_dir%\%TEMPSAVE%.fxt 	;TEMPSAVE is global
		Return "[FIXED]"
}

;Shows the Clipjump Paste Mode tooltip
PasteModeTooltip() {
	global
	if Clipboard =
		ToolTip % "{" CN.Name "} Clip " realclipno " of " CURSAVE "`t" fixStatus (WinExist("Display_Cj") ? "" : "`n`n" MSG_ERROR)
	else
		ToolTip % "{" CN.Name "} Clip " realclipno " of " CURSAVE "`t" GetClipboardFormat() "`t" fixstatus (!FORMATTING ? "`t[NO-FORMATTING]" : "") "`n`n" halfclip
}


ctrlCheck:
	if !GetKeyState("Ctrl")
	{
		CALLER := 0 , sleeptime := 700

		Gui, 1:Hide
		if ctrlRef = cancel
		{
			ToolTip, %MSG_CANCELLED%
			TEMPSAVE := CURSAVE , sleeptime := 200
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

			if !FORMATTING
			{
				if Instr(GetClipboardFormat(), "Text")
					Clipboard .= "" , LASTCLIP := Clipboard
				Send, ^v
			}
			else
				Send, ^v
			sleeptime := 100

			TEMPSAVE := realActive
		}
		SetTimer, ctrlCheck, Off
		IN_BACK := false , ctrlRef := ""

		hkZ_Group(0)

		if sleeptime != 100  ;pasted
			oldclip_exist := 0
			, Clipboard := oldclip_data

		sleep % sleeptime-20
		ToolTip

		CALLER := true , EmptyMem()
	}
	return

Ssuspnd:
	SetTimer, ctrlCheck, Off
	ctrlRef := ""
	TEMPSAVE := realActive

	hkZ_Group(0)

	IN_BACK := CALLER := 0
	addToWinClip(realactive , "has Clip " realclipno)
	CALLER := true
	Gui, 1:Hide
	return

hkZ_Group(mode=0){
; mode=0 is initialising Clipjump
; mode=1 is init Paste Mode
	hkZ("^c", "MoveBack", mode) , hkZ("^x", "Cancel", mode) , hkZ("^Z", "Formatting", mode)
	hkZ("^Space", "Fixate", mode) , hkZ("^S", "Ssuspnd", mode) , hkZ("^e", "export", mode)

	if !mode        ;init Cj
		hkZ("^x", "DeleteAll", 0) , hkZ("^x", "Delete", 0)
		, hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")

}

;---------------     Clips management based functions       ------------------

compacter() {
	loop, %ini_Threshold%
	{
		FileDelete, %A_ScriptDir%\%CLIPS_dir%\%A_Index%.avc
		FileDelete, %A_ScriptDir%\%THUMBS_dir%\%A_Index%.jpg
		FileDelete, %A_ScriptDir%\%FIXATE_dir%\%A_Index%.fxt
	}
	loop % CURSAVE-ini_Threshold
	{
		avcNumber := A_Index + ini_Threshold
		FileMove, %A_ScriptDir%/%CLIPS_dir%/%avcnumber%.avc, %A_ScriptDir%/%CLIPS_dir%/%A_Index%.avc
		FileMove, %A_ScriptDir%/%THUMBS_dir%/%avcnumber%.jpg, %A_ScriptDir%/%THUMBS_dir%/%A_Index%.jpg
		FileMove, %A_ScriptDir%/%FIXATE_dir%/%avcnumber%.fxt, %A_ScriptDir%/%FIXATE_dir%/%A_Index%.fxt
	}
	TEMPSAVE := CURSAVE := ini_MaxClips
}

clearData() {
	LASTCLIP := ""
	FileDelete, %CLIPS_dir%\*.avc
	FileDelete, %THUMBS_dir%\*.jpg
	FileDelete, %FIXATE_dir%\*.fxt
	CURSAVE := 0
	TEMPSAVE := 0
}

clearClip(realActive) {
	LASTCLIP := ""
	FileDelete, %CLIPS_dir%\%realactive%.avc
	FileDelete, %THUMBS_dir%\%realactive%.jpg
	FileDelete, %FIXATE_dir%\%realactive%.fxt
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
			FileMove, %CLIPS_dir%/%realactive%.avc,	 %CLIPS_dir%/%newname%.avc
			FileMove, %THUMBS_dir%/%realactive%.jpg, %THUMBS_dir%/%newname%.jpg
			FileMove, %FIXATE_dir%/%realactive%.fxt, %FIXATE_dir%/%newname%.fxt
		}
	}
}

thumbGenerator() {
	ClipWait, , 1
	Gdip_CaptureClipboard(A_ScriptDir "\" THUMBS_dir "\" CURSAVE ".jpg", ini_Quality)
}

;~ ;**************** GUI Functions ***************************************************************************

showPreview(){
	static scrnhgt := A_ScreenHeight / 2.5 , scrnwdt := A_ScreenWidth / 2

	if FileExist(A_ScriptDir "\" THUMBS_dir "\" TEMPSAVE ".jpg")
	{
		GDIPToken := Gdip_Startup()
		pBM := Gdip_CreateBitmapFromFile( A_ScriptDir "\" THUMBS_dir "\" TEMPSAVE ".jpg" )
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

		GuiControl, , imagepreview, *w%displayW% *h%displayH% %THUMBS_dir%\%TEMPSAVE%.jpg
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

	if !ini_DaysToStore                    ;Dont delete old data
		return

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

;****************COPY FILE/FOLDER/DATA***************************************************************************

copyFile:
	copyMessage := MSG_FILE_PATH_COPIED
	selectedFile := GetFile()
	if ( selectedFile != "" )
		Clipboard := selectedfile
	CopyMessage := MSG_TRANSFER_COMPLETE " {" CN.Name "}"
	return

copyFolder:
	copyMessage := MSG_FOLDER_PATH_COPIED
	openedFolder := GetFolder()
	if ( openedfolder != "" )
		Clipboard := openedFolder
	copyMessage := MSG_TRANSFER_COMPLETE " {" CN.Name "}"
	return

CopyFileData:
	hkZ(Copyfiledata_K, "CopyFileData", 0) ;disable key for repeate copies

	selectedFile := GetFile()
	temp_extension := SubStr(selectedFile, Instr(selectedFile, ".", 0, 0)+1)

	if temp_extension in jpg,jpeg,tiff,png,bmp,gif
		Gdip_SetImagetoClipboard(selectedFile)

	else if temp_extension in cj,avc
	{
		CALLER := 0
		Fileread, Clipboard, *c %selectedFile%
		ClipWait, 1, 1
		oldclip := ClipboardAll
		CALLER := true
		Clipboard := oldclip , oldclip := ""           ;The methodology is adopted due to an AHK Bug
	}
	else
	{
		FileRead, temp,% selectedFile
		Clipboard := temp
	}

	sleep 1000
	hkZ(CopyFileData_k, "CopyFileData")
	return

;**********       Extra Functions and Labels            *******************************************************

hlp:
	if A_IsCompiled
		run Clipjump.chm
	else
		run chm_files/clipjump.html
	return

settings:
	Gui, 2:Hide
	gui_Settings()
	return
	
history:
	Gui, 2:Hide
	gui_History()
	return

channelGUI:
	channelGUI()
	return

main:
	aboutGUI()
	return

strtup:
	Menu, Tray, Togglecheck, Run at Startup
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

;****** Helper FUNCTIONS ****************************************

addToWinClip(lastEntry, extraTip)
{
	ToolTip, System Clipboard %extraTip%
	if CURSAVE
		FileRead, Clipboard, *c %A_ScriptDir%/%CLIPS_dir%/%lastentry%.avc
	Sleep, 1000
	ToolTip
}

oneTime:
	CALLER := false
	onetimeOn := 1
	Tooltip % "One Time Stop ACTIVATED"
	setTimer, TooltipOff, 600
	return

incognito:
	Menu, Tray, Togglecheck, &Incognito Mode
	NOINCOGNITO := !NOINCOGNITO
	return

export:
	Gui, 1:Hide
	SetTimer, ctrlCheck, Off
	ctrlRef := "" , TEMPSAVE := realActive
	hkZ_Group(0) , CALLER := true

	loop
		if !FileExist(temp := A_MyDocuments "\export" A_index ".cj")
			break
	Tooltip % "{" CN.Name "} Clip " realClipNo " exported to `n" temp
	SetTimer, TooltipOff, 1000
	FileAppend, %ClipboardAll%, % temp
	return

;type=1
;	returns Text
;type=0
;	returns data types
GetClipboardFormat(type=1){		;Thanks nnnik
	Critical, On

 	DllCall("OpenClipboard", "int", "")
 	while c := DllCall("EnumClipboardFormats","Int",c?c:0)
		x .= "," c
	DllCall("CloseClipboard")

	if type
  		if Instr(x, ",1") and Instr(x, ",13")
    		return "[Text]"
 		else If Instr(x, ",15")
    		return "[File/Folder]"
    	else
    		return ""
    else
    	return x
}

;#################### COMMUNICATION ##########################################

;The function enables/disables Clipjump with respect to the Communicator.
Act_CjControl(C){
	global
	local p:=0,d

	if C = 1
	{
		CALLER := 1
		, hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
		, hkZ(Copyfilepath_K, "CopyFile") , hkZ(Copyfolderpath_K, "CopyFolder"), hkZ(CopyFileData_K, "CopyFileData") 
		, hkZ(Channel_K, "channelGUI") , hkZ(onetime_K, "onetime") 
		, hkZ("$^v", "Paste") , hkZ(history_K, "History")
		return
	}

	;--- Backward Compatibility
	if C<1
		C := 2+4+64
	;--- 

	if C = 1048576
		d := "2 4 8 16 32 64 128 256"
	else
		d := getParams(C)

	loop, parse, d, %A_space%
		if A_LoopField = 2
			CALLER := 0
			, hkZ("$^c", "NativeCopy", 0) , hkZ("$^x", "NativeCut", 0)
		else if A_LoopField = 4
			hkZ("$^v", "Paste", 0)
		else if A_LoopField = 8
			hkZ(Copyfilepath_K, "CopyFile", 0)
		else if A_LoopField = 16
			hkZ(Copyfolderpath_K, "CopyFolder", 0)
		else if A_LoopField = 32
			hkZ(CopyFileData_K, "CopyFileData", 0)
		else if A_LoopField = 64
			hkZ(history_K, "History", 0)
		else if A_LoopField = 128
			hkZ(Channel_K, "channelGUI", 0)
		else if A_LoopField = 256
			hkZ(onetime_K, "onetime", 0)
}

Receive_WM_COPYDATA(wParam, lParam)
{
	global
    Local D

    D := StrGet( NumGet(lParam + 2*A_PtrSize) ) + 0  ;unicode transfer
    if D is not Integer
    	D := StrGet( NumGet(lParam + 2*A_PtrSize), 8, "UTF-8")  ;ansi conversion

    Act_CjControl(D)

    while !FileExist(A_temp "\clipjumpcom.txt")
    	FileAppend, a,% A_temp "\clipjumpcom.txt"

    ;-- Backward Compatibility
    if D=1
    	setTimer, clipjumpcom_delete, 500
    ;----

    return 1
}

clipjumpcom_delete:
	SetTimer, clipjumpcom_delete, Off
	FileDelete, % A_temp "\clipjumpcom.txt"
	return

;##############################################################################

#Include %A_ScriptDir%\lib\multi.ahk
#Include %A_ScriptDir%\lib\aboutgui.ahk
#include %A_ScriptDir%\lib\Gdip_All.ahk
#include %A_ScriptDir%\lib\anticj_func_labels.ahk
#include %A_ScriptDir%\lib\settings gui plug.ahk
#include %A_ScriptDir%\lib\history gui plug.ahk
;#include %A_ScriptDir%\lib\history gui plug_new.ahk
;#include %A_ScriptDir%\lib\dlg.ahk

#include %A_ScriptDir%\lib\HotkeyParser.ahk

;------------------------------------------------------------------- X -------------------------------------------------------------------------------