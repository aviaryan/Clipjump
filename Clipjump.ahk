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
;@Ahk2Exe-SetVersion 10.5.9.8
;@Ahk2Exe-SetCopyright Avi Aryan
;@Ahk2Exe-SetOrigFilename Clipjump.exe

SetWorkingDir, %A_ScriptDir%
SetBatchLines,-1
#NoEnv
#SingleInstance, force
#ClipboardTimeout 0              ;keeping this value low as I already check for OpenClipboard in OnClipboardChange label
CoordMode, Mouse
CoordMode, Tooltip
FileEncoding, UTF-8
ListLines, Off
#KeyHistory 0
#HotkeyInterval 1000
#MaxHotkeysPerInterval 1000

global ini_LANG := ""

;*********Program Vars**********************************************************
; Capitalised variables (here and everywhere) indicate that they are global

global PROGNAME := "Clipjump"
global VERSION := "10.5.9.8"
global CONFIGURATION_FILE := "settings.ini"

ini_LANG := ini_read("System", "lang")
global TXT := Translations_load("languages/" ini_LANG ".txt") 		;Load translations

global UPDATE_FILE := "https://raw.github.com/avi-aryan/Clipjump/master/version.txt"
global PRODUCT_PAGE := "http://clipjump.sourceforge.net"
global HELP_PAGE := "http://avi-win-tips.blogspot.com/2013/04/clipjump-online-guide.html"
global AUTHOR_PAGE := "http://aviaryan.sourceforge.net"

global MSG_TRANSFER_COMPLETE := TXT.TIP_copied " " PROGNAME    ;not space
global MSG_CLIPJUMP_EMPTY := TXT.TIP_empty1 "`n`n" PROGNAME " " TXT.TIP_empty2 "`n`n" TXT.TIP_empty3 ;not `n`n
global MSG_ERROR := TXT.TIP_error
global MSG_MORE_PREVIEW := TXT.TIP_more
global MSG_PASTING := TXT.TIP_pasting
global MSG_DELETED := TXT.TIP_deleted
global MSG_ALL_DELETED := TXT.TIP_alldeleted
global MSG_CANCELLED := TXT.TIP_cancelled
global MSG_FIXED := TXT.TIP_fixed
global MSG_HISTORY_PREVIEW_IMAGE := TXT.HST_viewimage
global MSG_FILE_PATH_COPIED := TXT.TIP_filepath " " PROGNAME
global MSG_FOLDER_PATH_COPIED := TXT.TIP_folderpath " " PROGNAME

;History Tool
global hidden_date_no := 4 , history_w , history_partial

;*******************************************************************************

;Creating Storage Directories
FileCreateDir, cache
FileCreateDir, cache/clips
FileCreateDir, cache/thumbs
FileCreateDir, cache/fixate
FileCreateDir, cache/history
FileSetAttrib, +H, %A_ScriptDir%\cache

;Init Non-Ini Configurations
FileDelete, % A_temp "/clipjumpcom.txt"
try Clipboard := ""

;Global Data Holders
Sysget, temp, MonitorWorkArea
global WORKINGHT := tempbottom-temptop
global restoreCaller := 0

;Global Inits
global CN := {} , CUSTOMS := {} , CDS := {} , SEARCHOBJ := {} , TOTALCLIPS, ACTIONMODE := {} , ACTIONMODE_DEF := "H S C X F D P O E F1 L"
global cut_is_delete_windows := "XLMAIN QWidget" 			;excel , kingsoft office
global CURSAVE, TEMPSAVE, LASTCLIP, LASTFORMAT, IScurCBACTIVE := 0
global NOINCOGNITO := 1, SPM := {}

;Initailizing Common Variables
global CALLER_STATUS, CLIPJUMP_STATUS := 1		; global vars are not declared like the below , without initialising
global CALLER := CALLER_STATUS := true, IN_BACK := false
global CLIP_ACTION := "", ONCLIPBOARD := 0 , ISACTIVEEXCEL := 0 , HASCOPYFAILED := 0 , ctrlRef		;specific purpose global vars

;Init General vars
is_pstMode_active := 0

;Setting up Icons
FileCreateDir, icons
FileInstall, icons\no_history.Ico, icons\no_history.Ico, 0 			;Allow users to have their icons
FileInstall, icons\no_monitoring.ico, icons\no_monitoring.ico, 0

;Ini Configurations
Iniread, ini_Version, %CONFIGURATION_FILE%, System, Version

If !FileExist(CONFIGURATION_FILE)
{
	save_default(1)
	
	MsgBox, 52, Recommended, Do you want to see the Clipjump help ?
	IfMsgBox, Yes
		gosub, hlp

	if !A_IsAdmin
		MsgBox, 16, WARNING, Clipjump is not running as Administrator`nThis (may) cause improper functioning of the program.`n`n[This message will be shown only once]

	try TrayTip, Clipjump, Hi!`nClipjump is now activated.`nTry doing some quick copy and pastes..., 10, 1

}
else if (ini_Version != VERSION)
	save_default(0) 			;0 corresponds to selective save


;Global Ini declarations
global ini_IsImageStored , ini_Quality , ini_MaxClips , ini_Threshold , ini_IsChannelMin := 1 , CopyMessage, FORMATTING
		, Copyfolderpath_K, Copyfilepath_K, Copyfilepath_K, channel_K, onetime_K, paste_k, actionmode_k, ini_is_duplicate_copied, ini_formatting, ini_actmd_keys
		, ini_CopyBeep , beepFrequency , ignoreWindows

; (search) paste mode keys 
global pastemodekey := {} , spmkey := {}
temp_keys := "a|c|s|z|space|x|e|up|down|f"
loop, parse, temp_keys,|
	pastemodekey[A_LoopField] := "^" A_LoopField
temp_keys := "Enter|Up|Down|Home"
loop, parse, temp_keys, |
	spmkey[A_LoopField] := A_LoopField

global windows_copy_k, windows_cut_k

;Initialising Clipjump Channels
initChannels()
;loading Settings
load_Settings(1)
validate_Settings()
;load custom settings
loadCustomizations()

trayMenu()

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
Gui +LastFound +AlwaysOnTop -Caption +ToolWindow +Border
gui, add, picture,x0 y0 w400 h300 vimagepreview,

;More GUIs and Menus can be seen in lib folder

;********************************************************************
;STARTUP
IfExist, %A_Startup%/Clipjump.lnk
{
	FileDelete, %A_Startup%/Clipjump.lnk
	FileCreateShortcut, % H_Compiled ? A_ScriptDir "\Clipjump.exe" : A_ScriptFullPath, %A_Startup%/Clipjump.lnk
	Menu, Options_Tray, Check, % TXT.TRY_startup
}

global CLIPS_dir := "cache/clips"
	, THUMBS_dir := "cache/thumbs"
	, FIXATE_dir := "cache/fixate"
	, NUMBER_ADVANCED := 29 + CN.Total 					;the number stores the line number of ADVANCED section

;Setting Up shortcuts
hkZ( ( paste_k ? "$^" paste_k : emptyvar ) , "Paste")
hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
hkZ(Copyfilepath_K, "CopyFile") , hkZ(Copyfolderpath_K, "CopyFolder")
hkZ(history_K, "History")
hkZ(Copyfiledata_K, "CopyFileData")
hkZ(channel_K, "channelGUI")
hkZ(onetime_K, "oneTime")
hkZ(pitswap_K, "pitswap")
hkZ(actionmode_K, "actionmode")
;more shortcuts
hkZ(windows_copy_k, "windows_copy") , hkZ(windows_cut_k, "windows_cut")
;Environment
OnMessage(0x4a, "Receive_WM_COPYDATA")  ; 0x4a is WM_COPYDATA
;Clean History
historyCleanup()
init_actionmode()

;create Ignore windows group from Space-separated values
temp_delim := !Instr(ignoreWindows, "|") ? " " : "|"
loop, parse, ignoreWindows, % temp_delim
	GroupAdd, ignoreGroup, ahk_class %A_LoopField%
;group created

loadClipboardDataS()
OnExit, exit
EmptyMem()
return

;Tooltip No 1 is used for Paste Mode tips, 2 is used for notifications , 3 is used for updates , 4 is used in Settings , 5 is used in Action Mode
;6 used in Class Tool, 7.........., 8 used in Customizer

;OLD VERSION COMPATIBILITES TO REMOVE
; Temp delim
;End Of Auto-Execute================================================================================================================

loadClipboardDataS(){
	API.blockMonitoring(1)
	loop % CN.Total
	{
		fp := "cache\clips" ( A_index-1 ? A_index-1 : "" )
		CDS[R:=A_index-1] := {}
		loop, % fp "\*.avc"
		{
			ONCLIPBOARD:=""
			FileRead, Clipboard, % "*c " A_LoopFileFullPath
			Z := Clipboard
			while !ONCLIPBOARD
				sleep 1
			if Z !=
				CDS[R][Substr(A_LoopFileName,1,-4)] := Z
				;, CDS[R][y "f"] := GetClipboardFormat()		; extenstion .avc is removed
		}
	}
	API.blockMonitoring(0)
}

paste:
	Critical, On

	IfWinActive, ahk_group ignoreGroup
	{
		Send ^{vk56}
		return
	}

	Gui, 1:Hide
	CALLER := 0
	ctrlRef := "pastemode"
	if IN_BACK
		IN_BACK_correction()

	If !FileExist(CLIPS_dir "/" TEMPSAVE ".avc")
	{
		if !oldclip_exist
		{
			oldclip_exist := 1
			try oldclip_data := ClipboardAll
		}

		try Clipboard := ""
		hkZ(pastemodekey.up, "channel_up") , hkZ(pastemodekey.down, "channel_down") 		;activate the 2 keys to jump channels
		Tooltip, % "{" CN.Name "} " MSG_CLIPJUMP_EMPTY 				;No Clip Exists
		setTimer, ctrlCheck, 50
	}
	else
	{
		if !oldclip_exist 					;will be false when V is pressed for 1st time
		{
			oldclip_exist := 1
			try oldclip_data := ClipboardAll
			catch temp {
				makeClipboardAvailable(0)  						; make clipbboard available in case it is blocked
			}
		}
		else
			IScurCBACTIVE := 0 				;false it when V is pressed for the 2nd time

		if !is_pstMode_active
			hkZ_pasteMode(1) , is_pstMode_active := 1

		if !IScurCBACTIVE 				;if the current clipboard is not asked for , then only load from file
			try FileRead, Clipboard, *c %A_ScriptDir%/%CLIPS_dir%/%TEMPSAVE%.avc
		try temp_clipboard := Clipboard
		;temp_clipboard := CDS[CN.NG][TEMPSAVE]

		fixStatus := fixCheck()
		realclipno := CURSAVE - TEMPSAVE + 1

		if temp_clipboard =
			showPreview()
		else
		{
			If strlen(temp_clipboard) > 200
			{
				StringLeft,halfclip,temp_clipboard, 200
				halfClip := halfClip . "`n`n" MSG_MORE_PREVIEW
			}
			else halfClip := temp_clipboard
		}
		PasteModeTooltip(temp_clipboard)
		SetTimer, ctrlCheck, 50

		realActive := TEMPSAVE
		TEMPSAVE -= 1
		If (TEMPSAVE == 0)
			TEMPSAVE := CURSAVE
	}
	return

onClipboardChange:
	Critical, On
	if ONCLIPBOARD=
	{
		ONCLIPBOARD:=1
		return
	}
	ONCLIPBOARD := 1 		;used by paste/or another to identify if OnCLipboard has been breached

	ifwinactive, ahk_group IgnoreGroup
		return

	If CALLER
	{
		if !WinActive("ahk_class XLMAIN")
			 try   clipboard_copy := makeClipboardAvailable() , ISACTIVEEXCEL := 0
		else try   clipboard_copy := LASTCLIP , ISACTIVEEXCEL := 1  	;so that Cj doesnt open excel clipboard (for a longer time) and cause problems 
		;clipboard_copy = lastclip as to remove duplicate copies in excel , ^x or ^c makes lastclip empty

		try eventinfo := A_eventinfo

		if ISACTIVEEXCEL
			isLastFormat_changed := 1                           ;same reason as above
		else
			try isLastFormat_changed :=  ( LASTFORMAT != (temp_lastformat := GetClipboardFormat(0)) )   ?   1   :   0

		if isLastFormat_changed or ( LASTCLIP != clipboard_copy) or ( clipboard_copy == "" )
			returnV := clipChange(eventinfo, clipboard_copy)

		LASTFORMAT := temp_lastformat , CLIP_ACTION := returnV ? "" : CLIP_ACTION  		;make CLIP_ACTION empty if copy/cut succeeded else let it be so that if window uses
			;2 transfers like Excel , the demand can be fulfilled
		IScurCBACTIVE := returnV 									;current clipboard is active after new data copied to clipboard SUCCESSFULLY

		if !ISACTIVEEXCEL 				;excel has known bugs with AHK and manipulating clipboard *infront* of it will cause errors
			makeClipboardAvailable(0) 						;close clipboard in case it is still opened by clipjump
	}
	else
	{
		LASTFORMAT := WinActive("ahk_class XLMAIN") ? "" : GetClipboardFormat(0)
		;IScurCBACTIVE := 0 					; clipboard was changed and so this should be zero
		if restoreCaller
			restoreCaller := "" , CALLER := CALLER_STATUS
		if onetimeOn
		{
			onetimeOn := 0 ;--- To avoid OnClipboardChange label to open this routine [IMPORTANT]
			sleep 500 ;--- Allows the restore Clipboard Transfer in apps
			CALLER := CALLER_STATUS
			autoTooltip("One Time Stop " TXT.TIP_deactivated, 600, 2)
			changeIcon()
		}
	}
	return

clipChange(CErrorlevel, clipboard_copy) {

	If CErrorlevel = 1
	{
		if ( clipboard_copy != LASTCLIP ) or ( clipboard_copy == "" )        ;dont let go if lastclip = clipboard_copy = <empty>
		{
			CURSAVE += 1

			if ISACTIVEEXCEL
				LASTCLIP := clipsaver()
			else
				temp := clipSaver() , LASTCLIP := clipboard_copy

			If HASCOPYFAILED
			{
				CURSAVE -= 1 , TEMPSAVE := CURSAVE
				return
			}

			if NOINCOGNITO and ( CN.Name != "pit" )
				FileAppend, %LASTCLIP%, cache\history\%A_Now%.txt

			BeepAt(ini_CopyBeep, beepFrequency)
			ToolTip, %copyMessage%

			if CLIP_ACTION = CUT
			{
				WinGetClass, activeclass, A
				if Instr(cut_is_delete_windows, activeclass)
					Send {vk2e} 			;del
			}

			TEMPSAVE := CURSAVE
			if ( CURSAVE >= TOTALCLIPS )
				compacter()

			returnV := 1
		}
	}
	else If CErrorlevel = 2
	{
			CURSAVE += 1 , TEMPSAVE := CURSAVE , LASTCLIP := ""

			clipSaver()
			if HASCOPYFAILED
			{
				CURSAVE -= 1 , TEMPSAVE := CURSAVE
				return
			}

			BeepAt(ini_CopyBeep, beepFrequency)
			ToolTip, %copyMessage%
			thumbGenerator()

			if NOINCOGNITO and ini_IsImageStored and ( CN.Name != "pit" )
				FileCopy, %THUMBS_dir%\%CURSAVE%.jpg, cache\history\%A_Now%.jpg

			if ( CURSAVE >= TOTALCLIPS )
				compacter()

			returnV := 2
	}
	SetTimer, TooltipOff, 500
	emptyMem()
	return returnV
}

moveBack:
	Critical

	IfWinActive, ahk_group IgnoreGroup
		return

	Gui, 1:Hide
	IN_BACK := true
	TEMPSAVE := realActive + 1
	if realActive = %CURSAVE%
		TEMPSAVE := 1
	realActive := TEMPSAVE
	IScurCBACTIVE := 0 			;the key will be always pressed after V
	try FileRead, clipboard, *c %CLIPS_dir%/%TEMPSAVE%.avc
	try temp_clipboard := Clipboard
	;temp_clipboard := CDS[CN.NG][TEMPSAVE]

	fixStatus := fixCheck()
	realClipNo := CURSAVE - TEMPSAVE + 1
	if temp_clipboard =
		showPreview()
	else
	{
		if strlen(temp_clipboard) > 200
		{
			StringLeft, halfClip, temp_clipboard, 200
			halfClip := halfClip "`n`n" MSG_MORE_PREVIEW
		}
		else halfClip := temp_clipboard
	}
	PasteModeTooltip(temp_clipboard)
	SetTimer, ctrlCheck, 50
	return

IN_BACK_correction(){ 	; corrects TEMPSAVE value when C (backwards) is used in paste mode
	global
	IN_BACK := false
	If (TEMPSAVE == 1)
		TEMPSAVE := CURSAVE
	else
		TEMPSAVE -= 1
}

;-------------- paste mode tips ------------------------

cancel:
	Gui, Hide
	ToolTip, % TXT.TIP_cancelm "`t(1)`n" TXT.TIP_modem
	ctrlref := "cancel"
	if SPM.ACTIVE
		gosub SPM_dispose 	; dispose it if There - Note that this step ends the label as ctrlCheck dies so ctrlRef is kept upwards to be updated
	hkZ(pastemodekey.space, "fixate", 0) , hkZ(pastemodekey.z, "Formatting", 0) , hkZ(pastemodekey.a, "navigate_to_first", 0)
	hkZ(pastemodekey.s, "Ssuspnd", 0) , hkZ(pastemodekey.up, "channel_up", 0) , hkZ(pastemodekey.down, "channel_down", 0)
	hkZ(pastemodekey.f, "searchpm", 0) , hkZ(pastemodekey.x, "Cancel", 0) , hkZ(pastemodekey.x, "Delete", 1)
	return

delete:
	ToolTip, % TXT.TIP_delm "`t`t(2)`n" TXT.TIP_modem
	ctrlref := "delete"
	hkZ(pastemodekey.x, "Delete", 0) , hkZ(pastemodekey.x, "cutclip", 1)
	return

cutclip:
	Tooltip, % TXT.TIP_move "`t`t(3)`n" TXT.TIP_modem
	ctrlref := "cut"
	hkZ(pastemodekey.x, "cutclip", 0) , hkZ(pastemodekey.x, "copyclip", 1)
	return

copyclip:
	Tooltip, % TXT.TIP_copy "`t`t(4)`n" TXT.TIP_modem
	ctrlref := "copy"
	hkZ(pastemodekey.x, "copyclip", 0) , hkZ(pastemodekey.x, "DeleteAll", 1)
	return

deleteall:
	Tooltip, % TXT.TIP_delallm "`t`t(5)`n" TXT.TIP_modem
	ctrlref := "deleteAll"
	hkZ(pastemodekey.x, "DeleteAll", 0) , hkZ(pastemodekey.x, "Cancel", 1)
	return

nativeCopy:
	Critical
	hkZ("$^c", "nativeCopy", 0) , hkZ("$^c", "keyblocker")
	if ini_is_duplicate_copied or WinActive("ahk_class XLMAIN")
		LASTCLIP := ""
	CLIP_ACTION := "COPY"
	Send, ^{vk43}
	setTimer, ctrlforCopy, 50
	gosub, ctrlforCopy
	return

nativeCut:
	Critical
	hkZ("$^x", "nativeCut", 0) , hkZ("$^x", "keyblocker")
	if ini_is_duplicate_copied or WinActive("ahk_class XLMAIN")
		LASTCLIP := ""
	CLIP_ACTION := "CUT"
	Send, ^{vk58}
	setTimer, ctrlforCopy, 50
	gosub, ctrlforCopy
	return

ctrlForCopy:
	if GetKeyState("Ctrl", "P") = 0		; if key is up
	{
		Critical 			;To make sure the hotkeys are changed
		hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
		SetTimer, ctrlforCopy, Off
	}
	return

Formatting:
	FORMATTING := !FORMATTING
	PasteModeTooltip(temp_clipboard)
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
	PasteModeTooltip(temp_clipboard)
	return

navigate_to_first: 		; navigates clip pos to the first in paste mode
	if IN_BACK
		IN_BACK_correction()
	TEMPSAVE := CURSAVE 		; make tempsave 29 if total clips (cursave) is 29 . so load the first (latest) clip
	gosub paste
	return

clipSaver() {

	FileDelete, %CLIPS_dir%/%CURSAVE%.avc
	HASCOPYFAILED := 0

	Tooltip, Processing,,, 7
	while !copied
	{
		if ( A_index=100 ) {
			HASCOPYFAILED := 1
			Tooltip,,,, 7
			return
		}

		try {
			if ISACTIVEEXCEL
			{
				foolGUI(1) 										;foolGUI() is a blank gui to get focus over excel [crazy bug- crazy fix]
				tempC := ClipboardAll
				tempCB := Clipboard
				FileAppend, %tempC%, %CLIPS_dir%/%CURSAVE%.avc
				foolGUI(0)
			}
			else
				FileAppend, %ClipboardAll%, %CLIPS_dir%/%CURSAVE%.avc
			CDS[CN.NG][CURSAVE] := ISACTIVEEXCEL ? tempCB : Clipboard ;, CDS[CN.NG][CURSAVE "f"] := GetClipboardFormat()
			copied := 1
		} catch {
			if ISACTIVEEXCEL
				foolGUI(0)
		}
	}
	Tooltip,,,, 7
	; check for empty file
	FileRead, test, %CLIPS_dir%/%CURSAVE%.avc
	if test=
		return (HASCOPYFAILED := 1) * ablankvar 			;actually the return doesnt matter here

	Loop, %CURSAVE%
	{
		tempNo := CURSAVE - A_Index + 1
		IfExist, %FIXATE_dir%\%tempNo%.fxt 		; manage the fixed clips so they stay intact
		{
			t_TempNo := tempNo + 1
			FileMove, %CLIPS_dir%\%t_TempNo%.avc,	%CLIPS_dir%\%t_TempNo%_a.avc
			FileMove, %CLIPS_dir%\%tempNo%.avc,		%CLIPS_dir%\%t_TempNo%.avc
			FileMove, %CLIPS_dir%\%t_TempNo%_a.avc,	%CLIPS_dir%\%tempNo%.avc
			z := CDS[CN.NG][t_TempNo] , CDS[CN.NG][t_TempNo] := CDS[CN.NG][tempNo] , CDS[CN.NG][tempNo] := z
			IfExist, %THUMBS_dir%\%tempNo%.jpg
			{
				FileMove, %THUMBS_dir%\%t_TempNo%.jpg,	%THUMBS_dir%\%t_TempNo%_a.jpg
				FileMove, %THUMBS_dir%\%tempNo%.jpg,	%THUMBS_dir%\%t_TempNo%.jpg
				FileMove, %THUMBS_dir%\%t_TempNo%_a.jpg, %THUMBS_dir%\%tempNo%.jpg
			}
			FileMove, %FIXATE_dir%\%tempNo%.fxt, %FIXATE_dir%\%t_TempNo%.fxt
		}
	}

	return tempCB
}

fixCheck() {
	IfExist, %FIXATE_dir%\%TEMPSAVE%.fxt 	;TEMPSAVE is global
		Return "[FIXED]"
}

;Shows the Clipjump Paste Mode tooltip
PasteModeTooltip(temp_clipboard) {
	global
	if temp_clipboard =
		ToolTip % "{" CN.Name "} Clip " realclipno " of " CURSAVE "`t" fixStatus (WinExist("Display_Cj") ? "" : "`n`n" MSG_ERROR "`n`n"), % SPM.X, % SPM.Y
	else
		ToolTip % "{" CN.Name "} Clip " realclipno " of " CURSAVE "`t" GetClipboardFormat() "`t" fixstatus (!FORMATTING ? "`t[" TXT.TIP_noformatting "]" : "") 
		. "`n`n" halfclip, % SPM.X, % SPM.Y
}


ctrlCheck:
	if (!GetKeyState("Ctrl")) && (!SPM.ACTIVE)
	{
		Critical
		SetTimer, ctrlCheck, Off
		CALLER := false , sleeptime := 300
		TEMPSAVE := realActive 				; keep the current clip pos saved

		Gui, 1:Hide
		if ctrlRef = cancel
		{
			ToolTip, %MSG_CANCELLED%
			sleeptime := 200
		}
		else if ctrlRef = deleteAll
		{
			Critical, Off 			;End Critical so that the below function can overlap this thread
			IScurCBACTIVE := 0 		; now not active in clipjump

			temp21 := TT_Console(TXT.TIP_delallprompt, "Y N")
			if temp21 = Y
			{
				Tooltip, %MSG_ALL_DELETED%
				clearData()
			}
			else
				Tooltip, %MSG_CANCELLED%

			Critical, On 			;Just in case this may be required.

		}
		else if ctrlRef = delete
		{
			IScurCBACTIVE := 0
			ToolTip, %MSG_DELETED%
			clearClip(realActive)
		}
		else if ctrlRef in cut,copy
		{
			Tooltip
			Critical, Off
			temp21 := choosechannelgui()
			if Instr(temp21, "-") != 1
			{
				API.manageClip( temp21 , empty, empty, ( ctrlref == "cut" ) ? 0 : 1 )
				Tooltip, % TXT.TIP_done
			}
			else Tooltip, % TXT.TIP_copycutfailed
			Critical, On
		}
		else if ctrlRef = pastemode
		{
			ToolTip, %MSG_PASTING%
			if !FORMATTING
			{
				if Instr(GetClipboardFormat(), "Text")
				{
					Critical, Off 			; off to enable thread overlap
					ONCLIPBOARD := 0
					try Clipboard := Rtrim(Clipboard, "`r`n")
					while !ONCLIPBOARD
						sleep 5 			; wait for ONC label to be done
					Critical, On 			; on critical for just the case
				}
				Send, ^{vk56}

				sleeptime := 1
			}
			else
			{
				Send, ^{vk56}
				sleeptime := 100
			}
		}

		IN_BACK := false , is_pstMode_active := 0 , oldclip_exist := 0
		hkZ_pasteMode(0)
		restoreCaller := 1 			; Restore CALLER in the ONC label . This a second line of defence wrt to the last line of this label.

		Critical, Off
		; The below thread will be interrupted when the Clipboard command is executed. The ONC label will exit as CALLER := 0 in the situtaion

		if ctrlref in cancel, delete, DeleteAll
			if !IScurCBACTIVE 						;dont disturb current clipboard if it is already active
				try Clipboard := oldclip_data       ;The command opens, writes and closes clipboard . The ONCC Label is launched when writing takes place.

		sleep % sleeptime
		Tooltip
		
		restoreCaller := 0		; make it 0 in case Clipboard was not touched (Pasting was done) 
		ctrlRef := ""
		CALLER := CALLER_STATUS , EmptyMem()
	}
	return

Ssuspnd:
	SetTimer, ctrlCheck, Off
	ctrlRef := ""
	TEMPSAVE := realActive

	hkZ_pasteMode(0)

	IN_BACK := CALLER := 0
	addToWinClip(realactive , "has Clip " realclipno)
	CALLER := CALLER_STATUS
	Gui, 1:Hide
	return

hkZ_pasteMode(mode=0){
; mode=0 is for initialising Clipjump
; mode=1 is for init Paste Mode
	Critical

	hkZ(pastemodekey.c, "MoveBack", mode) , hkZ(pastemodekey.x, "Cancel", mode) , hkZ(pastemodekey.z, "Formatting", mode)
	hkZ(pastemodekey.space, "Fixate", mode) , hkZ(pastemodekey.s, "Ssuspnd", mode) , hkZ(pastemodekey.e, "export", mode)
	hkZ(pastemodekey.up, "channel_up", mode) , hkZ(pastemodekey.down, "channel_down", mode) , hkZ(pastemodekey.a, "navigate_to_first", mode)
	hkZ(pastemodekey.f, "searchpm", mode)

	if !mode        ;init Cj
	{
		hkZ(pastemodekey.x, "DeleteAll", 0) , hkZ(pastemodekey.x, "Delete", 0)
		hkZ(pastemodekey.x, "cutclip", 0) , hkZ(pastemodekey.x, "copyclip", 0)
		hkZ("$^x", "keyblocker", 0) , hkZ("$^c", "keyblocker", 0) 			;taken as a preventive step
		hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
	}
}

;changeCDS(nc, nx, ){
;	if nc=
;		nc := oc
;	CDS[nc][nx] := CDS[oc][ox]
;	CDS[nc][nx "f"] := CDS[oc][ox "f"]
;}

;--------------------------- CHANNEL FUNCTIONS ----------------------------------------------------------------

channel_up:
	CN.NG += 2 				;+2 to counter that -1 below
channel_down:
	CN.NG -= 1 , correctTEMPSAVE()
	if Instr(CN.NG, "-")
		CN.NG := CN.Total-1
	else if (CN.NG == CN.Total) 		;if no of channels has exceeded
		CN.NG := 0
	changeChannel(CN.NG) , CN.pit_NG := ""
	gosub, paste
	return

pitSwap:
	if ( CN.pit_NG != "" )
	{
		changeChannel(CN.pit_NG) , CN.pit_NG := ""
		, autoTooltip("PitSwap Deactivated", 500)
		return
	}
	if (temp := channel_find("pit")) == ""
		autoTooltip("""Pit"" channel not found !", 800, 2)
	else
		CN.pit_NG := CN.NG , changeChannel(temp)
		, autoTooltip("PitSwap Activated", 500)
	return

;---------------     Clips management based functions       ------------------

correctTEMPSAVE(){
	TEMPSAVE += 1 		;to make active clip index be same when switching channels , counter-effects TEMPSAVE-=1 in paste_mode label.
	if in_back
		IN_BACK_correction()
	if TEMPSAVE > %CURSAVE%
		TEMPSAVE := 1
}

compacter() {
	loop, %ini_Threshold%
	{
		CDS[CN.NG][A_index] := ""
		FileDelete, %A_ScriptDir%\%CLIPS_dir%\%A_Index%.avc
		FileDelete, %A_ScriptDir%\%THUMBS_dir%\%A_Index%.jpg
		FileDelete, %A_ScriptDir%\%FIXATE_dir%\%A_Index%.fxt
	}
	loop % CURSAVE-ini_Threshold
	{
		avcNumber := A_Index + ini_Threshold
		CDS[CN.NG][A_index] := CDS[CN.NG][avcNumber] , CDS[CN.NG][avcNumber] := ""
		FileMove, %A_ScriptDir%/%CLIPS_dir%/%avcnumber%.avc, %A_ScriptDir%/%CLIPS_dir%/%A_Index%.avc, 1
		FileMove, %A_ScriptDir%/%THUMBS_dir%/%avcnumber%.jpg, %A_ScriptDir%/%THUMBS_dir%/%A_Index%.jpg, 1
		FileMove, %A_ScriptDir%/%FIXATE_dir%/%avcnumber%.fxt, %A_ScriptDir%/%FIXATE_dir%/%A_Index%.fxt, 1
	}
	TEMPSAVE := CURSAVE := ini_MaxClips
}

clearData() {
	LASTCLIP := ""
	CDS[CN.NG] := {}
	FileDelete, %CLIPS_dir%\*.avc
	FileDelete, %THUMBS_dir%\*.jpg
	FileDelete, %FIXATE_dir%\*.fxt
	CURSAVE := 0
	TEMPSAVE := 0
}

clearClip(realActive) {
	LASTCLIP := ""
	CDS[CN.NG][realActive] := ""
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
			CDS[CN.NG][newname] := CDS[CN.NG][realactive] , CDS[CN.NG][realActive] := ""
			FileMove, %CLIPS_dir%/%realactive%.avc,	 %CLIPS_dir%/%newname%.avc, 1
			FileMove, %THUMBS_dir%/%realactive%.jpg, %THUMBS_dir%/%newname%.jpg, 1
			FileMove, %FIXATE_dir%/%realactive%.fxt, %FIXATE_dir%/%newname%.fxt, 1
		}
	}
}

thumbGenerator() {
	Critical
	ClipWait, 3, 1 				;Dont need a Clipwait here , but just for special cases I put a wait of 3 secs
	Gdip_CaptureClipboard( A_ScriptDir "\" THUMBS_dir "\" CURSAVE ".jpg", ini_Quality)
}

;~ ;**************** GUI Functions ***************************************************************************

showPreview(){
	static scrnhgt := A_ScreenHeight / 2 , scrnwdt := A_ScreenWidth / 2

	if FileExist( (img := A_ScriptDir "\" THUMBS_dir "\" TEMPSAVE ".jpg") )
	{
		Gdip_getLengths(img, widthOfThumb, heightOfThumb)

		if ( heightOfThumb > scrnHgt ) or ( widthOfThumb > scrnWdt )
			displayH := heightOfThumb / 2
			, displayW := widthOfThumb / 2
		else 
			displayH := heightofthumb
			, displayW := widthOfThumb

		GuiControl, , imagepreview, *w%displayW% *h%displayH% %THUMBS_dir%\%TEMPSAVE%.jpg
		MouseGetPos, ax, ay
		ay := ay + (scrnHgt / 10)

		; Try ensures we dont see the error if it happens due to thread overlaps
		try Gui, Show, x%ax% y%ay% h%displayh% w%displayw%, Display_Cj
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


;----------------------- ACTION MODE AND GET CLASS TOOL ----------------------------------------------------


actionmode:
	temp_am := TT_Console(ACTIONMODE.text, ACTIONMODE.keys, temp3, temp3, 5, "s8", "Consolas|Courier New")
	if ACTIONMODE[temp_am] != ""
		gosub % ACTIONMODE[temp_am]
	else
		EmptyMem()
	return

init_actionmode() {
	;ini_actmd_keys stores user prefs till Help File

	t12 := {}
	loop, parse, ini_actmd_keys, %A_space%, %A_space%
		t12.Insert(A_LoopField)

	ACTIONMODE := {(t12.1): "history", (t12.2): "channelGUI", (t12.3): "copyfile", (t12.4): "copyfolder", (t12.5): "CopyFileData", (t12.6): "disable_clipjump"
		, (t12.7): "pitswap", (t12.8): "onetime", (t12.9): "settings", (t12.10): "hlp", (t12.11): "classTool"}

	ACTIONMODE.keys := ini_actmd_keys " Esc End Q"

	status_text := !CLIPJUMP_STATUS ? TXT.ACT_enable : TXT.ACT_disable   ;8

	;auto-detect width
	; max 35
	ACTIONMODE.text := ""
	.  PROGNAME " " TXT.ACT__name
	. "`n-----------"
	. "`n"
	. "`n" fillwithSpaces(TXT.HST__name, 35) " -  " t12.1 		;35 is default
	. "`n" fillwithSpaces(TXT.CNL__name)     " -  " t12.2
	. "`n" fillwithSpaces(TXT._cfilep)       " -  " t12.3
	. "`n" fillwithSpaces(TXT._cfolderp)     " -  " t12.4
	. "`n" fillwithSpaces(TXT._cfiled)       " -  " t12.5
	. "`n" fillwithSpaces(status_text " " PROGNAME) " -  " t12.6
	. "`n" fillwithSpaces(TXT._pitswp)       " -  " t12.7
	. "`n" fillwithSpaces(TXT._ot)           " -  " t12.8
	. "`n"
	. "`n" fillwithSpaces(TXT.IGN__name)     " -  " t12.11
	. "`n" fillwithSpaces(TXT.SET__name)     " -  " t12.9
	. "`n" fillwithSpaces(TXT.TRY_help)      " -  " t12.10
	. "`n"
	. "`n" fillwithSpaces(TXT.ACT_exit)      " -  Esc, End, Q"

}
;****************COPY FILE/FOLDER/DATA***************************************************************************

copyFile:
	copyMessage := MSG_FILE_PATH_COPIED
	selectedFile := GetFile()
	if ( selectedFile != "" )
		try Clipboard := selectedfile
	CopyMessage := MSG_TRANSFER_COMPLETE " {" CN.Name "}"
	return

copyFolder:
	copyMessage := MSG_FOLDER_PATH_COPIED
	openedFolder := GetFolder()
	if ( openedfolder != "" )
		try Clipboard := openedFolder
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
		try Fileread, Clipboard, *c %selectedFile%
		ClipWait, 1, 1
		oldclip := ClipboardAll
		CALLER := CALLER_STATUS
		try Clipboard := oldclip
		oldclip := ""           ;The methodology is adopted due to an AHK Bug
	}
	else
	{
		FileRead, temp,% selectedFile
		try Clipboard := temp
	}

	sleep 1000
	hkZ(CopyFileData_k, "CopyFileData")
	return

;**********       Extra Functions and Labels            *******************************************************

hlp:
	if A_IsCompiled
		run Clipjump.chm
	else
		run % FileExist("Clipjump.chm") ? "Clipjump.chm" : "chm_files\clipjump.html"
	return

strtup:
	Menu, Options_Tray, Togglecheck, % TXT.TRY_startup
	IfExist, %A_Startup%/Clipjump.lnk
		FileDelete, %A_Startup%/Clipjump.lnk
	else FileCreateShortcut, % H_Compiled ? A_ScriptDir "\Clipjump.exe" : A_ScriptFullPath, %A_Startup%/Clipjump.lnk
	return

updt:
	Tooltip, Checking for Updates ...... , , , 3
	URLDownloadToFile, %UPDATE_FILE%, %A_ScriptDir%/cache/latestversion.txt
	ToolTip, ,,, 3
	FileRead, temp, %A_ScriptDir%/cache/latestversion.txt
	lversion_changes := "`n`nChanges`n"
	loop, parse, temp, `n, `r
		if A_index=1
			latestVersion := A_LoopField
		else lversion_changes .= "`n" A_LoopField
	;if Instr(latestVersion, "z") 										; z in the update file is a version which is non-auto updatable
	;	latestVersion := Substr(latestVersion, 2) , noautoupdate := 1
	;else noautoupdate := 0
	noautoupdate := 1

	if !IsLatestRelease(VERSION, latestversion, "b|a")
	{
		if noautoupdate {
			MsgBox, 48, Clipjump Update available, % "Your Version: `t`t" VERSION "`nCurrent version: `t`t" latestVersion "`n`nGo to website to download newer version" 
			. lversion_changes
			;. " as auto-update facility is not available."
			IfMsgBox OK
				BrowserRun(PRODUCT_PAGE)
		}
		;else {
		;	MsgBox, 67, Clipjump Update Available, % "The latest version is " latestVersion ". `n" TXT.UPD_automsg
		;	IfMsgBox, Yes
		;		AutoUpdate(latestVersion)
		;	else IfMsgBox, No
		;		BrowserRun(PRODUCT_PAGE)
		;}
	}
	else MsgBox, 64, %PROGNAME%, % TXT.ABT_noupdate
	return

;AutoUpdate(v){
;	loop, cache\clipjumpupdate*.exe 		; old files
;		FileDelete, % A_LoopFileFullPath

;	Tooltip, % "Downloading Update file for version " v,,, 3
;	URLDownloadToFile, % "https://sourceforge.net/projects/clipjump/files/clipjumpupdate_" v ".exe/download", % "cache\" v ".exe"
;	if ErrorLevel=1
;		return autoTooltip("Update was not downloaded", 4, 3)
;	Tooltip,,,, 3
;	while !FileExist("cache\" v ".exe")
;		sleep 20

;	MsgBox, 64, Clipjump Update, % TXT.UPD_restart
;	OnExit
;	save_Exit()
;	run % "cache\" v ".exe"
;	Exitapp
;}

;************************************** Helper FUNCTIONS ****************************************

addToWinClip(lastEntry, extraTip)
{
	ToolTip, System Clipboard %extraTip%
	if CURSAVE
		try FileRead, Clipboard, *c %A_ScriptDir%/%CLIPS_dir%/%lastentry%.avc
	Sleep, 1000
	ToolTip
}

changeIcon(){
global

	if A_IsCompiled or H_Compiled 		; H_Compiled is a user var created if compiled with ahk_h
		Menu, tray, icon,*
	else
		Menu, tray, icon, icons\icon.ico
	if !NOINCOGNITO
		Menu, Tray, icon, icons\no_history.ico
	if !CALLER_STATUS or !CALLER
		Menu, Tray, icon, icons\no_monitoring.ico
}

oneTime:
	CALLER := false
	onetimeOn := 1
	autoTooltip("One Time Stop " TXT.TIP_activated, 600, 2)
	changeIcon()
	return

incognito:
	Menu, Options_Tray, Togglecheck, % TXT.TRY_incognito
	NOINCOGNITO := !NOINCOGNITO
	changeIcon()
	return

export:
	Gui, 1:Hide
	SetTimer, ctrlCheck, Off
	ctrlRef := "" , TEMPSAVE := realActive
	hkZ_pasteMode(0) , CALLER := CALLER_STATUS

	loop
		if !FileExist(temp := A_MyDocuments "\export" A_index ".cj")
			break
	Tooltip % "{" CN.Name "} Clip " realClipNo " " TXT._exportedto "`n" temp
	SetTimer, TooltipOff, 1000
	try FileAppend, %ClipboardAll%, % temp
	return

windows_copy:
	CALLER := 0
	Send ^{vk43}
	sleep 100
	makeClipboardAvailable(0)   ;wait till Clipboard is ready
	CALLER := CALLER_STATUS
	return

windows_cut:
	CALLER := 0
	Send ^{vk58}
	sleep 100
	makeClipboardAvailable(0)
	CALLER := CALLER_STATUS
	return

;Copies text to a var in the script without invoking Clipjump
CopytoVar(clipwait_time=3, send_macro="^{vk43}"){

	CALLER := 0
    try oldclip := ClipboardAll
    try Clipboard := ""
    Send % send_macro
    ClipWait, % clipwait_time
    try var := Clipboard
    try Clipboard := oldclip
    CALLER := CALLER_STATUS

    return var
}

disable_clipjump:
	CLIPJUMP_STATUS := !CLIPJUMP_STATUS
	CALLER := CALLER_STATUS := CLIPJUMP_STATUS
	, hkZ("$^c", "NativeCopy", CLIPJUMP_STATUS) , hkZ("$^x", "NativeCut", CLIPJUMP_STATUS)
	changeIcon()

	hkZ( ( paste_k ? "$^" paste_k : emptyvar ) , "Paste", CLIPJUMP_STATUS)
	Menu, Options_Tray, % !CLIPJUMP_STATUS ? "Check" : "Uncheck", % TXT.TRY_disable " " PROGNAME
	init_actionmode() 			;refresh enable/disable text in action mode
	return

;#################### COMMUNICATION ##########################################

;The function enables/disables Clipjump with respect to the Communicator.
Act_CjControl(C){
	global
	local p:=0,d

	if C = 1
	{
		CALLER := CALLER_STATUS := CLIPJUMP_STATUS := 1
		, hkZ("$^c", "NativeCopy") , hkZ("$^x", "NativeCut")
		, hkZ(Copyfilepath_K, "CopyFile") , hkZ(Copyfolderpath_K, "CopyFolder"), hkZ(CopyFileData_K, "CopyFileData") 
		, hkZ(Channel_K, "channelGUI") , hkZ(onetime_K, "onetime") 
		, hkZ( ( paste_k ? "$^" paste_k : emptyvar ) , "Paste") , hkZ(history_K, "History")
		changeIcon()
		Menu, Options_Tray, UnCheck, % TXT.TRY_disable " " PROGNAME
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
			CALLER := 0 , CALLER_STATUS := 0
			, hkZ("$^c", "NativeCopy", 0) , hkZ("$^x", "NativeCut", 0)
			, changeIcon()
		else if A_LoopField = 4
			hkZ( ( paste_k ? "$^" paste_k : emptyvar ) , "Paste", 0)
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

	if !Instr(d, "2 4")
	{
		CLIPJUMP_STATUS := 1
		Menu, Options_Tray, UnCheck, % TXT.TRY_disable " " PROGNAME
	}

}

Receive_WM_COPYDATA(wParam, lParam)
{
	global
    Local D
    static k := "API:" , apif := "Act_API"

   D := StrGet( NumGet(lParam + 2*A_PtrSize) )  ;unicode transfer
    if D is not Integer
    	if !Instr(D, k)
    		D := StrGet( NumGet(lParam + 2*A_PtrSize), 8, "UTF-8")  ;ansi conversion
    if Instr(D, k)
    	%apif%(D, k) 	; done to not cause error if no lib is included
    else Act_CjControl(D)

    while !FileExist(A_temp "\clipjumpcom.txt")
    	FileAppend, a,% A_temp "\clipjumpcom.txt"

    return 1
}

;##############################################################################

#Include %A_ScriptDir%\lib\Searchpastemode.ahk
#Include %A_ScriptDir%\lib\Customizer.ahk
#Include %A_ScriptDir%\lib\API.ahk
#Include %A_ScriptDir%\lib\translations.ahk
#Include %A_ScriptDir%\lib\classtool.ahk
#Include %A_ScriptDir%\lib\multi.ahk
#Include %A_ScriptDir%\lib\aboutgui.ahk
#include %A_ScriptDir%\lib\TT_Console.ahk
#include %A_ScriptDir%\lib\Gdip_min.ahk
#include %A_ScriptDir%\lib\HotkeyParser.ahk
#include %A_ScriptDir%\lib\anticj_func_labels.ahk
#include %A_ScriptDir%\lib\settings gui plug.ahk
#include %A_ScriptDir%\lib\history gui plug.ahk

;------------------------------------------------------------------- X -------------------------------------------------------------------------------