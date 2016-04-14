/*
	Clipjump

	Copyright 2013-15 Avi Aryan

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
;@Ahk2Exe-SetVersion 12.5
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

global ini_LANG := "" , H_Compiled := RegexMatch(Substr(A_AhkPath, Instr(A_AhkPath, "\", 0, 0)+1), "iU)^(Clipjump).*(\.exe)$") && (!A_IsCompiled) ? 1 : 0
global mainIconPath := H_Compiled || A_IsCompiled ? A_AhkPath : "icons/icon.ico"

/*
**********************
PROGRAM VARIABLES
**********************
*/

global PROGNAME := "Clipjump"
global VERSION := "12.5"
global CONFIGURATION_FILE := "settings.ini"

ini_LANG := ini_read("System", "lang")
if !ini_LANG
	ini_LANG := "english"
global TXT := Translations_load("languages/" ini_LANG ".txt") 		;Load translations

global UPDATE_FILE := "http://sourceforge.net/projects/clipjump/files/version.txt/download"
global PRODUCT_PAGE := "http://clipjump.sourceforge.net"
global HELP_PAGE := "http://clipjump.sourceforge.net/docs"
global AUTHOR_PAGE := "http://aviaryan.in"

global MSG_TRANSFER_COMPLETE
 , MSG_CLIPJUMP_EMPTY
 , MSG_ERROR
 , MSG_MORE_PREVIEW
 , MSG_PASTING
 , MSG_DELETED
 , MSG_ALL_DELETED
 , MSG_CANCELLED
 , MSG_FIXED
 , MSG_HISTORY_PREVIEW_IMAGE
 , MSG_FILE_PATH_COPIED
 , MSG_FOLDER_PATH_COPIED
 Translations_fixglobalVars() ; copymessage will be globalized and fixed in validateSettings()

;History Tool
global hidden_date_no := 4 , history_w , history_partial := 1 ;start off with partial=1 <> much better
global PREV_FILE := "cache\prev.html" , GHICON_PATH := A_ScriptDir "\icons\octicons-local.ttf"
global DBPATH := "cache\data.db"

/*
****************
BASIC STRUCTURE
****************
*/

;Creating Storage Directories
FileCreateDir, cache
FileCreateDir, cache/clips
FileCreateDir, cache/thumbs
FileCreateDir, cache/history
FileSetAttrib, -H, %A_WorkingDir%\cache

;Init Non-Ini Configurations
FileDelete, % A_temp "/clipjumpcom.txt"
try Clipboard := ""


/*
*********
VARIABLES
*********
*/
Sysget, temp, MonitorWorkArea
global WORKINGHT := tempbottom-temptop, restoreCaller := 0, startUpComplete := 0

;Global Inits
global CN := {}, CUSTOMS := {}, CDS := {}, CPS := {}, SEARCHOBJ := {}, HISTORYOBJ := {}, TOTALCLIPS, ACTIONMODE := {}, PLUGINS := {}, STORE := {}
global cut_is_delete_windows := "XLMAIN QWidget" 			;excel, kingsoft office
global CURSAVE, TEMPSAVE, LASTCLIP, LASTFORMAT, Islastformat_Changed := 1, IScurCBACTIVE := 0, curPformat, curPfunction, curPisPreviewable
global NOINCOGNITO := 1, SPM := {}, protected_DoBeep := 1
global pastemodekey := {} , spmkey := {}
global windows_copy_k, windows_cut_k, ini_OpenAllChbyDef := 0, pstIdentifier := "^", pstKeyName := (pstIdentifier == "^") ? "Ctrl" : "LWin"

;Initailizing Common Global Variables
global CALLER_STATUS, CLIPJUMP_STATUS := 1		; global vars are not declared like the below , without initialising
global CALLER := CALLER_STATUS := 1, IN_BACK := 0, MULTIPASTE, PASTEMODE_ACT
global CLIP_ACTION := "", ONCLIPBOARD := 1 , ISACTIVEEXCEL := 0 , HASCOPYFAILED := 0 , ctrlRef		;specific purpose global vars
global wasManualClipboard := false

;Global Ini declarations
global ini_IsImageStored , ini_Quality , ini_MaxClips , ini_Threshold , ini_isMessage, CopyMessage, ini_DaysToStore
		, Copyfolderpath_K, Copyfilepath_K, Copyfilepath_K, onetime_K, paste_k, actionmode_k, ini_is_duplicate_copied, ini_formatting
		, ini_CopyBeep , beepFrequency , ignoreWindows, ini_defEditor, ini_defImgEditor, ini_def_Pformat, pluginManager_k, holdClip_K, ini_PreserveClipPos
		, chOrg_K, ini_startSearch, ini_revFormat2def, ini_pstMode_X, ini_pstMode_Y, ini_HisCloseOnInstaPaste, history_K, ini_ram_flush, ini_winClipjump := 1
		, ini_monitorClipboard := 0

;Init General vars
is_pstMode_active := 0

/*
***********************
GET THE PROGRAM WORKING
***********************
*/

;Setting up Icons
FileCreateDir, icons
FileInstall, icons\no_history.Ico, icons\no_history.Ico, 0 			;Allow users to have their icons
FileInstall, icons\no_monitoring.ico, icons\no_monitoring.ico, 0

;MANAGE PROGRAM UPDATE
Iniread, ini_Version, %CONFIGURATION_FILE%, System, Version

;FileCreateDir, plugins/pformat
;FileCreateDir, plugins/external
;migratePlugins()

If !FileExist(CONFIGURATION_FILE)
{
	save_default(1)
	if !Instr(VERSION, "b") 		; betas have b
	{
		MsgBox, 52, Recommended, % TXT.ABT_seehelp
		IfMsgBox, Yes
			gosub, hlp
	}
	if !A_IsAdmin
		MsgBox, 16, WARNING, % TXT.ABT_runadmin
	try TrayTip, Clipjump, % TXT.ABT_cjready , 10, 1
}
else if (ini_Version != VERSION)
{
	save_default(0) 			;0 corresponds to selective save
	gosub Reload 		; Update plugin includes with what the user has incase he updates his Clipjump
	sleep 10000 		; to counter race condition
}

; start history
; migrate if needed
global DB := new SQLiteDB()
if (!FileExist(DBPATH))
	isnewdb := 1
else
	isnewdb := 0
if (!DB.OpenDB(DBPATH))
	msgbox some error occured

/*
***********************
DEFAULT SETTINGS LOADING
************************
*/
temp_keys := "Enter|Up|Down|Home"
loop, parse, temp_keys,|
	spmkey[A_LoopField] := A_LoopField

init_actionmode() ;Initialising Clipjump Channels
initChannels()

/*
********************
LOAD USER SETTINGS
********************
*/
trayMenu() ; before customization and settings as customization can affect tray
;loading Settings
load_Settings(1)
validate_Settings()
loadPlugins()

loop
{
	IfNotExist, cache/Clips/%A_Index%.avc
	{
		CURSAVE := A_Index - 1 , TEMPSAVE := CURSAVE
		break
	}
}


global CLIPS_dir := "cache/clips"
	, THUMBS_dir := "cache/thumbs"
	, FIXATE_txt := "fixed"
	, NUMBER_ADVANCED := 34 + CN.Total 					;the number stores the line number of ADVANCED section

/*
******************************
MORE SETTINGS A/C USER SETTINGS
******************************
*/

temp_keys := "a|c|s|z|space|x|e|up|down|f|h|Enter|t|F1|q"
loop, parse, temp_keys,|
	pastemodekey[A_LoopField] := A_LoopField

;Setting Up shortcuts
hkZ( ( paste_k ? "$" pstIdentifier paste_k : emptyvar ) , "Paste")
copyCutShortcuts()
hkZ(Copyfilepath_K, "CopyFile") , hkZ(Copyfolderpath_K, "CopyFolder")
hkZ(history_K, "History")
hkZ(Copyfiledata_K, "CopyFileData") , hkZ(channel_K, "channelGUI")
hkZ(onetime_K, "oneTime") , hkZ(pitswap_K, "pitswap")
hkZ(actionmode_K, "actionmode") , hkZ(pluginManager_k, "pluginManagerGUI")
hkZ(holdClip_K, "holdClip") , hkZ(chOrg_K, "channelOrganizer")
;more shortcuts
hkZ(windows_copy_k, "windows_copy") , hkZ(windows_cut_k, "windows_cut")

;create Ignore windows group from | separated values
loop, parse, ignoreWindows,|
	GroupAdd, ignoreGroup, ahk_class %A_LoopField%
;group created

/*
*********************
LOAD END-USER CUSTOMIZATIONS
*********************
*/

loadClipboardDataS()
loadCustomizations()

/*
***************
ERROR HANDLINGS AND
COMPATIBILITY
***************
*/

if FileExist(GHICON_PATH)
	DllCall("GDI32.DLL\AddFontResourceEx", Str, GHICON_PATH ,UInt,(FR_PRIVATE:=0x10), Int,0)
else
	MsgBox, 16, % PROGNAME, % valueof(TXT.ABT_errorFontIcon)

if (isnewdb == 1){
	migrateHistory()
}

/*
**********
LAST WORDS
**********
*/

fillHISTORYOBJ()
historyCleanup() ;Clean History
OnMessage(0x4a, "Receive_WM_COPYDATA")  ; 0x4a is WM_COPYDATA
; Portable Startup
IfExist, %A_Startup%/Clipjump.lnk
{
	FileDelete, %A_Startup%/Clipjump.lnk
	FileCreateShortcut, % H_Compiled ? A_AhkPath : A_ScriptFullPath, %A_Startup%/Clipjump.lnk
	Menu, Options_Tray, Check, % TXT.TRY_startup
}
EmptyMem()
lastClipboardTime := 0
startUpComplete := 1
OnExit, exit

return

;Tooltip No 1 is used for Paste Mode tips, 2 is used for notifications , 3 is used for updates , 4 is used in WM_MOUSEMOVE , 5 is used in Action Mode
;6 used in Class Tool, 7 in API (Plugin) , 8 used in Customizer, 9 used in history tool, 10 in edit clips, 11 in Channel Organizer

;End Of Auto-Execute================================================================================================================

loadClipboardDataS(){
	API.showTip(TXT.TIP_initMsg)
	API.blockMonitoring(1)
	loop % CN.Total
	{
		fp := "cache\clips" ( A_index-1 ? A_index-1 : "" )
		CDS[R:=A_index-1] := {}
		CPS[R] := ini2Obj(fp "\prefs.ini")
		loop, % fp "\*.avc"
		{
			ONCLIPBOARD:="" , Z := ""
			if try_ClipboardfromFile(A_LoopFileFullPath, 300)
				Z := trygetVar("Clipboard", 500) 	; 300 tries minimize chances of Clipboard recorders like Exekutor to interrupt 
			else ONCLIPBOARD := 1 , Z := ""

			while !ONCLIPBOARD
				sleep 5
			CDS[R][Substr(A_LoopFileName,1,-4)] := Z
		}
	}
	API.removeTip()
	API.blockMonitoring(0)
}

paste:
	Critical, On
	IfWinActive, ahk_group ignoreGroup
	{
		Send ^{vk56}
		return
	}

	Gui, imgprv:Destroy
	CALLER := 0
	if !ctrlRef
		firstPasteMode := 1
	if ini_startSearch && firstPasteMode
		SPM.ACTIVE := 1
	ctrlRef := "pastemode"
	if IN_BACK
		IN_BACK_correction()

	if (TEMPSAVE>CURSAVE) or !TEMPSAVE
		TEMPSAVE := CURSAVE

	If !FileExist(CLIPS_dir "/" TEMPSAVE ".avc")
	{
		if !oldclip_exist
		{
			oldclip_exist := 1
			try oldclip_data := ClipboardAll
		}

		try Clipboard := ""
		hkZ(pstIdentifier pastemodekey.up, "channel_up") , hkZ(pstIdentifier pastemodekey.down, "channel_down") 		;activate the 2 keys to jump channels
		PasteModeTooltip("{" CN.Name "} " MSG_CLIPJUMP_EMPTY, 1) 				;No Clip Exists
		setTimer, ctrlCheck, 50
	}
	else
	{
		if !oldclip_exist 					;will be false when V is pressed for 1st time
		{
			oldclip_exist := 1
			try oldclip_data := ClipboardAll
			catch {
				makeClipboardAvailable(0)  						; make clipbboard available in case it is blocked
			}
		}
		else
			IScurCBACTIVE := 0 				;false it when V is pressed for the 2nd time

		if !is_pstMode_active
			hkZ_pasteMode(1) , is_pstMode_active := 1

		if !IScurCBACTIVE 				;if the current clipboard is not asked for , then only load from file
			try_ClipboardfromFile(A_WorkingDir "/" CLIPS_dir "/" TEMPSAVE ".avc") 	; gets file onto clipboard trying 100 times

		temp_clipboard := trygetVar("Clipboard")  	;gets variable with multiple tries

		fixStatus := fixCheck()
		realclipno := CURSAVE - TEMPSAVE + 1

		if temp_clipboard =
			showPreview()
		else
		{
			If strlen(temp_clipboard) > 200
				halfClip := Substr(temp_clipboard, 1, 200) "`n`n" MSG_MORE_PREVIEW
			else halfClip := temp_clipboard
			if curPisPreviewable
				halfClip := %curPfunction%(halfClip)
		}
		realActive := TEMPSAVE
		PasteModeTooltip(temp_clipboard)
		SetTimer, ctrlCheck, 50

		TEMPSAVE -= 1
		If (TEMPSAVE == 0)
			TEMPSAVE := CURSAVE
	}
	if ini_startSearch && firstPasteMode
		setTimer, run_searchpm, -10 	; dont open in this thrd. critical
	firstPasteMode := 0
	return

onClipboardChange:
	Critical, On
	if !ONCLIPBOARD
	{
		ONCLIPBOARD:=1 	; if let blank, the label ends quickly
		return
	}
	ONCLIPBOARD := 1 		;used by paste/or another to identify if OnCLipboard has been breached
	if !startUpComplete 	;if not started, not allow - after onclipboard=1 as the purpose of onc is served
		return
	; check for machine-done clipboard manipulations
	timeDiff := TickCount64() - lastClipboardTime
	lastClipboardTime := TickCount64()
	if (timeDiff < 200){
		return
	}
	; check monitor clipboard setting
	if (ini_monitorClipboard == 0) {
		if (wasManualClipboard == false){
			return
		} else {
			wasManualClipboard := false
			setTimer, manualClipboardTimer, Off
		}
	}
	; ignore windows
	ifwinactive, ahk_group IgnoreGroup
		return

	;debugTip("1") ;<<<<<<<
	If CALLER
	{
		STORE.CBCaptured := 0
		if !WinActive("ahk_class XLMAIN")
			 try   clipboard_copy := makeClipboardAvailable() , ISACTIVEEXCEL := 0
		else try   clipboard_copy := LASTCLIP , ISACTIVEEXCEL := 1  	;so that Cj doesnt open excel clipboard (for a longer time) and cause problems 
		;clipboard_copy = lastclip as to remove duplicate copies in excel , ^x or ^c makes lastclip empty
		;debugTip("2") ;<<<<<<<<<
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
		if CPS[CN.NG][CURSAVE][FIXATE_txt]	; not active if the first clip is FIXED
			IScurCBACTIVE := 0
		if !ISACTIVEEXCEL 				;excel has known bugs with AHK and manipulating clipboard *infront* of it will cause errors
			makeClipboardAvailable(0) 						;close clipboard in case it is still opened by clipjump
		;debugTip("") ;<<<<<<<<<<<<
		STORE.CBCaptured := 1
	}
	else
	{
		;debugTip("pst mode 2") ;<<<<<<<<<<<<
		LASTFORMAT := WinActive("ahk_class XLMAIN") ? "" : GetClipboardFormat(0)
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
		;debugTip("") ;<<<<<<<<<<
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
				LASTCLIP := clipboard_copy , temp := clipSaver()

			If HASCOPYFAILED
			{
				CURSAVE -= 1 , TEMPSAVE := CURSAVE
				return
			}

			if NOINCOGNITO and ( CN.Name != "pit" ){
				addHistoryText(LASTCLIP, A_now)
			}

			BeepAt(ini_CopyBeep, beepFrequency)
			ToolTip, %copyMessage%

			if CLIP_ACTION = CUT
			{
				WinGetClass, activeclass, A
				if Instr(cut_is_delete_windows, activeclass)
					Send {vk2e} 			;del
			}

			TEMPSAVE := CURSAVE
			while ( CURSAVE >= TOTALCLIPS )
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

			if NOINCOGNITO and ini_IsImageStored and ( CN.Name != "pit" ){
				addHistoryImage(THUMBS_dir "\" CURSAVE ".jpg", A_Now)
			}

			while ( CURSAVE >= TOTALCLIPS )
				compacter()

			returnV := 2
	}
	SetTimer, TooltipOff, 500
	emptyMem()
	return returnV
}

moveBack:
	Critical ;, On
	IfWinActive, ahk_group IgnoreGroup
		return
	Gui, imgprv:Destroy
	IN_BACK := true
	TEMPSAVE := realActive + 1
	if realActive = %CURSAVE%
		TEMPSAVE := 1
	realActive := TEMPSAVE
	IScurCBACTIVE := 0 			;the key will be always pressed after V
	try_ClipboardfromFile(CLIPS_dir "/" TEMPSAVE ".avc")
	temp_clipboard := trygetVar("Clipboard")

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
		IF curPisPreviewable
			halfClip := %curPfunction%(halfClip)
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

multiPaste:
	if SPM.ACTIVE {
		WinHide, Clipjump_SPM ahk_class AutoHotkeyGUI
		WinWaitNotActive, Clipjump_SPM ahk_class AutoHotkeyGUI
		temp_spmWasActive := 1
	}
	MULTIPASTE := PASTEMODE_ACT := 1
	while PASTEMODE_ACT
		sleep 50 		; wait till ctrlCheck: runs
	if MULTIPASTE 		; if multipaste is still ON, becomes OFF due to release of ctrl (which doesnt disturb when spm is active)
		gosub paste
	if temp_spmWasActive {
		WinShow, Clipjump_SPM ahk_class AutoHotkeyGUI
		temp_spmWasActive := 0
	}
	return

cancel:
	Gui, Hide
	PasteModeTooltip(TXT.TIP_cancelm "`t(1)`n" TXT.TIP_modem, 1)
	ctrlref := "cancel"
	if SPM.ACTIVE
		gosub SPM_dispose 	; dispose it if There - Note that this step ends the label as ctrlCheck dies so ctrlRef is kept upwards to be updated
	hkZ_pasteMode(0, 0) , hkZ_pi(pastemodekey.x, "Delete", 1)
	return

delete:
	PasteModeTooltip(TXT.TIP_delm "`t`t(2)`n" TXT.TIP_modem, 1)
	ctrlref := "delete"
	hkZ_pi(pastemodekey.x, "Delete", 0) , hkZ_pi(pastemodekey.x, "cutclip", 1)
	return

cutclip:
	PasteModeTooltip(TXT.TIP_move "`t`t(3)`n" TXT.TIP_modem, 1)
	ctrlref := "cut"
	hkZ_pi(pastemodekey.x, "cutclip", 0) , hkZ_pi(pastemodekey.x, "copyclip", 1)
	return

copyclip:
	PasteModeTooltip(TXT.TIP_copy "`t`t(4)`n" TXT.TIP_modem, 1)
	ctrlref := "copy"
	hkZ_pi(pastemodekey.x, "copyclip", 0) , hkZ_pi(pastemodekey.x, "DeleteAll", 1)
	return

deleteall:
	PasteModeTooltip(TXT.TIP_delallm "`t`t(5)`n" TXT.TIP_modem, 1)
	ctrlref := "deleteAll"
	hkZ_pi(pastemodekey.x, "DeleteAll", 0) , hkZ_pi(pastemodekey.x, "Cancel", 1)
	return

nativeCopy:
	Critical
	if WinActive("ahk_class XLMAIN")
	{
		copyCutShortcuts(0)
		hkZ("$^c", "keyblocker")
		LASTCLIP := ""
		setTimer, ctrlforCopy, 50
	}
	if ini_is_duplicate_copied
		LASTCLIP := ""
	CLIP_ACTION := "COPY"
	wasManualClipboard := true
	setTimer, manualClipboardTimer, -1000
	Send, ^{vk43}
	return

nativeCut:
	Critical
	if WinActive("ahk_class XLMAIN")
	{
		copyCutShortcuts(0)
		hkZ("$^x", "keyblocker")
		LASTCLIP := ""
		setTimer, ctrlforCopy, 50
	}
	if ini_is_duplicate_copied
		LASTCLIP := ""
	CLIP_ACTION := "CUT"
	wasManualClipboard := true
	setTimer, manualClipboardTimer, -1000
	Send, ^{vk58}
	return

ctrlForCopy:
	if GetKeyState("Ctrl", "P") = 0		; if key is up
	{
		Critical 			;To make sure the hotkeys are changed
		copyCutShortcuts()	; keyblocker is removed bcoz ^x and ^c overwrites it
		SetTimer, ctrlforCopy, Off
	}
	return

manualClipboardTimer:
	wasManualClipboard := false
	return

Formatting:
	matched_pformat := 0 , curPformat := Trim(curPformat)
	if curPformat=
		matched_pformat := 1
	for key,value in PLUGINS["pformat"]
	{
		if matched_pformat {
			curPformat := value.name , curPfunction := value["*"] , matched_pformat := 0
			break
		}
		if ( value["name"] == curPformat )
			matched_pformat := 1
	}
	;rebuild show text
	if temp_clipboard != ""
	{
		If strlen(temp_clipboard) > 200
		{
			StringLeft,halfclip,temp_clipboard, 200
			halfClip := halfClip . "`n`n" MSG_MORE_PREVIEW
		}
		else halfClip := temp_clipboard
	}
	if matched_pformat
		curPformat := "" , curPisPreviewable := 0 ; case of switching to default
	else halfClip := (curPisPreviewable := value["Previewable"]) ? %curPfunction%(halfClip) : halfClip
	if ctrlRef = pastemode
		PasteModeTooltip(temp_clipboard) 	; rebuild prvw
	return

fixate:
	If CPS[CN.NG][realActive][FIXATE_txt]
		fixStatus := "" , CPS[CN.NG][realActive].remove(FIXATE_txt)
	else
		fixStatus := MSG_FIXED , AddClipPref(CN.NG, realActive, FIXATE_txt, 1)
	prefs_changed := 1
	PasteModeTooltip(temp_clipboard)
	return

TogglejumpClip:
	jumpClip_sign := !jumpClip_sign
	return

AddjumpClip:
	if IN_BACK
		IN_BACK_correction()
	TEMPSAVE += (!jumpClip_sign ? -Substr(A_ThisHotkey, 2)+1 : Substr(A_ThisHotkey, 2)+1)
	loop 	; as somthing like +9 could make tempsave = 17 when tempsave was 8 and the cursave is also 8
		if (TEMPSAVE>CURSAVE)
			TEMPSAVE := TEMPSAVE-CURSAVE
		else if TEMPSAVE<1
			TEMPSAVE := CURSAVE+TEMPSAVE
		else break
	gosub paste
	return

move_to_first:
	API.manageClip(CN.NG, CN.NG, realClipNo, 0)
	gosub navigate_to_first
	return

navigate_to_first:
	if IN_BACK
		IN_BACK_correction()
	TEMPSAVE := CURSAVE 		; make tempsave 29 if total clips (cursave) is 29 . so load the first (latest) clip
	gosub paste
	return

setClipTag:
	gosub endPastemode
	InputBox, ov, % TXT._tags, % TXT.TIP_tagprompt ,,,,,,,, % CPS[CN.NG][realActive]["Tags"]
	if !ErrorLevel
		AddClipPref(CN.NG, realActive, "Tags", ov), Prefs2Ini() , autoTooltip(TXT.TIP_done, 800, 2)
	else autoTooltip(TXT.TIP_cancelled, 800, 2)
	EmptyMem()
	return

clipSaver() {
	FileDelete, %CLIPS_dir%/%CURSAVE%.avc
	HASCOPYFAILED := 0

	Tooltip, % TXT["_processing"],,, 7
	while !copied
	{
		if ( A_index=100 ) or HASCOPYFAILED {
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
				foolGUI(0)
			}
			else
				tempC := ClipboardAll

			if Substr(CN.Name, 1, 1) = "_" 		; protected channels
			{
				Critical, Off
				BeepAt(protected_DoBeep, 2000, 200)
				temp21 := TT_Console("{" CN.Name "}`n " TXT.TIP_confirmcopy, "Y N Insert")
				Critical, On
			}
			if (temp21 = "Y") or (temp21 = "")
			{
				FileAppend, %tempC%, %CLIPS_dir%/%CURSAVE%.avc
				CDS[CN.NG][CURSAVE] := ISACTIVEEXCEL ? tempCB : Clipboard
				copied := 1
			}
			else {
				LASTCLIP := "" , LASTFORMAT := "" , HASCOPYFAILED := 1 	; lastclip was not captured by cj
				if (temp21 = "Insert") {
					Tooltip, % TXT["_processing"]
					SetTimer, addClipLater, -50
				}
			}
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

	manageFIXATE(CURSAVE, CN.NG, CN.N)
	return tempCB
}

manageFIXATE(clipAdded, channel, Dir_constant){
	; manages how Fixed clip are re-positioned when a new clip is added disturing the order.
	; It is necessary for the new clip to be added at Clip 1 position
	path_CLIPS := "cache\clips" Dir_constant
	path_THUMBS := "cache\thumbs" Dir_constant

	Loop, %clipAdded%
	{
		tempNo := clipAdded - A_Index + 1
		If CPS[channel][tempNo][FIXATE_txt]
		{
			t_TempNo := tempNo + 1
			FileMove, %path_CLIPS%\%t_TempNo%.avc,		%path_CLIPS%\%t_TempNo%_a.avc
			FileMove, %path_CLIPS%\%tempNo%.avc,		%path_CLIPS%\%t_TempNo%.avc
			FileMove, %path_CLIPS%\%t_TempNo%_a.avc,	%path_CLIPS%\%tempNo%.avc

			z := CDS[channel][t_TempNo] , CDS[channel][t_TempNo] := CDS[channel][tempNo] , CDS[channel][tempNo] := z
			IfExist, %path_THUMBS%\%tempNo%.jpg
			{
				FileMove, %path_THUMBS%\%t_TempNo%.jpg,	%path_THUMBS%\%t_TempNo%_a.jpg
				FileMove, %path_THUMBS%\%tempNo%.jpg,	%path_THUMBS%\%t_TempNo%.jpg
				FileMove, %path_THUMBS%\%t_TempNo%_a.jpg, %path_THUMBS%\%tempNo%.jpg
			}
			rmv := CPS[channel][t_tempNo] , CPS[channel][t_tempNo] := CPS[channel][tempNo] , CPS[channel][tempno] := rmv
			prefs_changed := 1
		}
	}
	if prefs_changed
		Prefs2Ini()
}


fixCheck() {
	If CPS[CN.NG][TEMPSAVE][FIXATE_txt]
		Return TXT.TIP_fixed
}

;Shows tooltips in Clipjump Paste Modes
PasteModeTooltip(cText, notpaste=0) {
	global
	local tx, ty
	if STORE["pstTipRebuild"] {
		Tooltip
		TooltipEx()
		STORE["pstTipRebuild"] := 0
	}
	; SPM.X and y contain place to show a/c searchbox
	tx := ini_pstMode_X ? ini_pstMode_X : SPM.X , ty := ini_pstMode_Y ? ini_pstMode_Y : SPM.Y
	if (notpaste == 1){
		Tooltip, % cText, % tx, % ty
	} else {
		tagText := (t := CPS[CN.NG][realActive]["Tags"]) != "" ? "(" t ")" : ""
		if (cText == "")
			ToolTip % "{" CN.Name "} Clip " realclipno " of " CURSAVE fillWithSpaces("",7) tagText " " fixStatus 
		. (WinExist("Display_Cj") ? "" : "`n`n" MSG_ERROR "`n`n"), % tx, % ty
		else
			ToolTip % "{" CN.Name "} Clip " realclipno " of " CURSAVE fillWithSpaces("",7) GetClipboardFormat() fillWithSpaces("",5) (curPformat ? "[" curPformat "]" : "") 
			. fillWithSpaces("",5) tagText " " fixstatus "`n`n" halfclip, % tx, % ty
	}
}

ctrlCheck:
	if ((!GetKeyState(pstKeyName)) && (!SPM.ACTIVE)) || PASTEMODE_ACT
	{
		Critical
		SetTimer, ctrlCheck, Off
		CALLER := false , sleeptime := 300 , TEMPSAVE := realActive 				; keep the current clip pos saved
		Gui, imgprv:Destroy
		; Change vars a/c MULTIPASTE
		if MULTIPASTE && !GetKeyState(pstKeyName) && !temp_spmWasActive 		;if spmIsActive user is not expected to cancel by releasing Ctrl
			if ctrlRef = pastemode
				ctrlRef := "cancel"
		; ---
		if ctrlRef = cancel
		{
			PasteModeTooltip(MSG_CANCELLED, 1)
			sleeptime := 200
		}
		else if ctrlRef = deleteAll
		{
			Critical, Off 			;End Critical so that the below function can overlap this thread
			IScurCBACTIVE := 0 		; now not active in clipjump

			temp21 := TT_Console_PasteMode(TXT.TIP_delallprompt, "Y N")
			if temp21 = Y
			{
				PasteModeTooltip(MSG_ALL_DELETED,1)
				clearData()
			}
			else
				PasteModeTooltip(MSG_CANCELLED,1)

			Critical, On 			;Just in case this may be required.
		}
		else if ctrlRef = delete
		{
			IScurCBACTIVE := 0
			PasteModeToolTip(MSG_DELETED,1)
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
				PasteModeTooltip(TXT.TIP_done,1)
			}
			else PasteModeTooltip(TXT.TIP_copycutfailed,1)
			Critical, On
		}
		else if ctrlRef = pastemode
		{
			PasteModeToolTip(MSG_PASTING,1)
			if (GetKeyState("Shift")) ; POP
				dopop := 1
			if curPformat 	;use curpf to get the func
			{
				Critical, Off
				API.blockMonitoring(1) 	; this is done to have the boomerang effect ONCLIPBOARD work.
				STORE.ClipboardChanged := 0
				zCb := trygetVar("Clipboard")
				if IsFunc(curPfunction)
					Coutput := %curPfunction%(zCb) 	; don't try here, the exception in fileread-filemissing-commonformats will nt allow it.
				if STORE.ClipboardChanged
					try Clipboard := Coutput , IScurCBACTIVE := 0
				else ONCLIPBOARD := 1
				API.blockMonitoring(0, 5)
				Critical, On
				Send, ^{vk56}
				sleeptime := 1
			}
			else
			{
				Send, ^{vk56}
				sleeptime := 100
			}
		}

		IN_BACK := is_pstMode_active := oldclip_exist := jumpClip_sign := 0
		hkZ_pasteMode(0)
		restoreCaller := 1 			; Restore CALLER in the ONC label . This a second line of defence wrt to the last line of this label.

		Critical, Off
		; The below thread will be interrupted when the Clipboard command is executed. The ONC label will exit as CALLER := 0 in the situtaion
		if ((ctrlRef == "pastemode") && dopop) ; pop clip
		{
			clearClip(TEMPSAVE)
			IScurCBACTIVE := 0
		}
		if !ini_PreserveClipPos
			TEMPSAVE := cursave 		; not preserve active clip

		if ctrlref in cancel, delete, DeleteAll
			if !IScurCBACTIVE 						;dont disturb current clipboard if it is already active
				try Clipboard := oldclip_data       ;The command opens, writes and closes clipboard . The ONCC Label is launched when writing takes place.

		sleep % sleeptime
		Tooltip

		restoreCaller := PASTEMODE_ACT := 0 	; restoreCaller - make it 0 in case Clipboard was not touched (Pasting was done)
		if !GetKeyState(pstKeyName) && !SPM.ACTIVE
			MULTIPASTE := 0 		; deactivated when Ctrl released
		ctrlRef := ""
		CALLER := CALLER_STATUS
		if ini_revFormat2def
			set_pformat(ini_def_Pformat)
		if prefs_changed
			Prefs2Ini() 	; save preferences in memory
		EmptyMem()
		dopop := 0
	} else {
		; record previous shift presses too
		; is more user convenient
		if (GetKeyState("Shift")) 
			dopop := 1
		else
			dopop := 0
	}
	return

endPastemode:
	; ends the paste abruptly - as required by export and suspend
	Gui, imgprv:Destroy
	Tooltip
	SetTimer, ctrlCheck, Off
	if SPM.ACTIVE
		gosub SPM_dispose
	if !ini_PreserveClipPos
		TEMPSAVE := cursave
	else TEMPSAVE := realActive
	API.blockMonitoring(1)
	if !IScurCBACTIVE
		try Clipboard := oldclip_data
	API.blockMonitoring(0)
	ctrlRef := "", restoreCaller := is_pstMode_active := IN_BACK := oldclip_exist := jumpClip_sign := 0
	hkZ_pasteMode(0) , CALLER := CALLER_STATUS
	if ini_revFormat2def
		set_pformat(ini_def_Pformat)
	if prefs_changed
		Prefs2Ini()
	EmptyMem()
	return

Ssuspnd:
	gosub endPastemode
	addToWinClip(realactive , TXT.TIP_syscb)
	return

pstMode_Help:
	Tooltip
	TooltipEx(TXT.SET_shortcuts "`n" TXT.TIP_help, __x, __y, 1, getHFONT("s8", "Consolas"))
	;PasteModeTooltip(TXT.SET_shortcuts "`n" TXT.TIP_help, 1) ;, "S8, Consolas")
	STORE["pstTipRebuild"] := 1
	return

addClipLater:
	while !STORE.CBCaptured 	; wait for capture to over
		sleep 50
	tempVar := ClipboardAll
	API.AddClip(0, tempVar, 1)
	autoTooltip(TXT.TIP_protectedMoved, 700)
	return

hkZ_pasteMode(mode=0, disableAll=1){
; mode=0 is for initialising Clipjump
; mode=1 is for init Paste Mode
	Critical

	loop 9
		hkZ(pstIdentifier A_index, "AddjumpClip", mode) 	; above them to allow any modifications
	hkZ(pstIdentifier "-", "TogglejumpClip", mode)
	hkZ_pi(pastemodekey.c, "MoveBack", mode) , hkZ_pi(pastemodekey.x, "Cancel", mode) , hkZ_pi(pastemodekey.z, "Formatting", mode)
	hkZ_pi(pastemodekey.space, "Fixate", mode) , hkZ_pi(pastemodekey.s, "Ssuspnd", mode) , hkZ_pi(pastemodekey.e, "export", mode)
	hkZ_pi(pastemodekey.up, "channel_up", mode) , hkZ_pi(pastemodekey.down, "channel_down", mode) , hkZ_pi(pastemodekey.a, "navigate_to_first", mode)
	hkZ_pi(pastemodekey.f, "searchpm", mode) , hkZ_pi(pastemodekey.h, "editclip", mode) , hkZ_pi(pastemodekey.enter, "multiPaste", mode)
	hkZ_pi(pastemodekey.t, "setClipTag", mode) , hkZ_pi(pastemodekey.F1, "pstMode_Help", mode) , hkZ_pi(pastemodekey.q, "move_to_first", mode)

	if (!mode) && disableAll        ;init Cj
	{
		hkZ_pi(pastemodekey.x, "DeleteAll", 0) , hkZ_pi(pastemodekey.x, "Delete", 0)
		hkZ_pi(pastemodekey.x, "cutclip", 0) , hkZ_pi(pastemodekey.x, "copyclip", 0)
		hkZ("$^x", "keyblocker", 0) , hkZ("$^c", "keyblocker", 0) 			;taken as a preventive step
		copyCutShortcuts()
	}
}

;--------------------------- CHANNEL FUNCTIONS ----------------------------------------------------------------

channel_up:
	CN.NG += 2
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
	EmptyMem()
	return

holdClip:
	; cut - make own by clipjump custom ---- send = this, then del
	API.blockMonitoring(1) , ONCLIPBOARD := 0 , IScurCBACTIVE := 0
	if ( STORE.holdClip_preText == "" )
		Send % ( STORE.holdClip_send ? STORE.holdClip_send : "^{vk43}" )
	else
		try Clipboard := STORE.holdClip_preText
	STORE.holdClip_send := "^{vk43}" , STORE.holdClip_preText := "" 	; default

	while !ONCLIPBOARD
	{
		if A_Index>20
		{
			API.blockMonitoring(0)
			return
		}
		sleep 50
	}
	holdclip_continue := 1 , hkZ( ( paste_k ? "$" pstIdentifier paste_k : emptyvar ) , "Paste", 0) 	; disable paste mode
	try temp_cb := trygetVar("Clipboard")
	keyPressed := TT_Console(TXT.TIP_holdclip "`n`n" Substr(temp_cb, 1, 200) " ...", "Insert F2 Esc", __x, __y, __fontops, __fontname, 1, 1)
	if keyPressed = F2
	{
		guiMsgBox(TXT["_output"], API.runPlugin("pformat.commonformats.ahk", Clipboard) )
	}
	else if keyPressed = Insert
	{
		try t_cb := ClipboardAll
		try Clipboard := ""
	}
	API.blockMonitoring(0)
	if keyPressed = Insert
		try Clipboard := t_cb
	hkZ( ( paste_k && CLIPJUMP_STATUS ? "$" pstIdentifier paste_k : emptyvar ) , "Paste")
	EmptyMem()
	return

;---------------     Clips management based functions       ------------------

correctTEMPSAVE(){
	TEMPSAVE += 1 		;to make active clip index be same when switching channels , counter-effects TEMPSAVE-=1 in paste_mode label.
	if in_back
		IN_BACK_correction()
	if TEMPSAVE > %CURSAVE%
		TEMPSAVE := 1
	return TEMPSAVE
}

compacter() {
	loop, %ini_Threshold%
	{
		CDS[CN.NG][A_index] := ""
		FileDelete, %A_WorkingDir%\%CLIPS_dir%\%A_Index%.avc
		FileDelete, %A_WorkingDir%\%THUMBS_dir%\%A_Index%.jpg
		CPS[CN.NG].remove(A_index)
	}
	loop % CURSAVE-ini_Threshold
	{
		avcNumber := A_Index + ini_Threshold
		CDS[CN.NG][A_index] := CDS[CN.NG][avcNumber] , CDS[CN.NG][avcNumber] := ""
		FileMove, %A_WorkingDir%/%CLIPS_dir%/%avcnumber%.avc, %A_WorkingDir%/%CLIPS_dir%/%A_Index%.avc, 1
		FileMove, %A_WorkingDir%/%THUMBS_dir%/%avcnumber%.jpg, %A_WorkingDir%/%THUMBS_dir%/%A_Index%.jpg, 1
		; Auto rmd := CPS[CN.NG].remove(avcnumber) , CPS[CN.NG][A_Index] := rmd
	}
	TEMPSAVE := CURSAVE := CURSAVE - ini_Threshold 	; dont use TOTALCLIPS, could be a late clip compaction due to ini
}

clearData() {
	API.emptyChannel(CN.NG)
}

clearClip(realActive) {
	LASTCLIP := ""
	CDS[CN.NG][realActive] := ""
	FileDelete, %CLIPS_dir%\%realactive%.avc
	FileDelete, %THUMBS_dir%\%realactive%.jpg
	CPS[CN.NG].remove(realActive)
	TEMPSAVE := realActive - 1
	if (TEMPSAVE == 0)
		TEMPSAVE := 1
	renameCorrect(realActive)
	CURSAVE -= 1
}

renameCorrect(realActive) {
	loopTime := CURSAVE - realactive
	loop, %loopTime%
	{
		newName := realActive
		realActive += 1
		CDS[CN.NG][newname] := CDS[CN.NG][realactive] , CDS[CN.NG][realActive] := ""
		FileMove, %CLIPS_dir%/%realactive%.avc,	 %CLIPS_dir%/%newname%.avc, 1
		FileMove, %THUMBS_dir%/%realactive%.jpg, %THUMBS_dir%/%newname%.jpg, 1
		; Auto rmv := CPS[CN.NG].remove(realActive) , CPS[CN.NG][newname] := rmv
	}
}

thumbGenerator() {
	Critical
	ClipWait, 3, 1 				;Dont need a Clipwait here , but just for special cases I put a wait of 3 secs
	Gdip_CaptureClipboard( A_WorkingDir "\" THUMBS_dir "\" CURSAVE ".jpg", ini_Quality)
}

Prefs2Ini(){
global
	loop % CN.Total
	{
		fp := "cache\clips" (A_index-1 ? A_index-1 : "")
		Obj2Ini( CPS[A_index-1] , fp "\prefs.ini" )
	}
	prefs_changed := 0
}

ClipPref_makeKeys(Ch, Cl){
	static l := "fixed|Tags"
	if !IsObject( CPS[Ch][Cl] )
		CPS[Ch][Cl] := {}
	loop, parse, l, |
		if !CPS[Ch][Cl].hasKey(A_LoopField)
			CPS[Ch][Cl][A_LoopField] := ""
}

AddClipPref(Ch, Cl, Pr, val){
	ClipPref_makeKeys(Ch, Cl)
	CPS[Ch][Cl][Pr] := val
}

;~ ;**************** GUI Functions ***************************************************************************

showPreview(){
	static scrnhgt := A_ScreenHeight / 2 , scrnwdt := A_ScreenWidth / 2
	static imagepreview

	Gui, imgprv:New
	Gui, imgprv:+LastFound +AlwaysOnTop -Caption +ToolWindow +Border
	Gui, add, picture,x0 y0 w400 h300 vimagepreview,

	if FileExist( (img := A_WorkingDir "\" THUMBS_dir "\" TEMPSAVE ".jpg") )
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
		if (scrnwdt*2-ax < displayw/2)
			ax := 2
		if (scrnhgt*2-ay < displayh/2)
			ay := 2
		; Try ensures we dont see the error if it happens due to thread overlaps
		tx := ini_pstMode_X ? ini_pstMode_X : ax , ty := ini_pstMode_Y ? ini_pstMode_Y : ay

		try Gui, imgprv:Show, x%tx% y%ty% h%displayh% w%displayw% NoActivate, Display_Cj
	}
}

historyCleanup(){
;Cleans history in bunch
	local Row
	if !ini_DaysToStore                    ;Dont delete old data
		return

	q := "select id from history where (strftime('%s', date('now', '-" ini_DaysToStore " days')) - strftime('%s', time)) > 0"
	recs := ""
	if (!DB.Query(q, recs))
		msgbox % "Error history cleanup `n " DB.ErrorMsg "`n" DB.ErrorCode "`n" q

	DB.Exec("BEGIN TRANSACTION")
	while ( recs.Next(Row) > 0 )
	{
		deleteHistoryById(Row[1])
	}
	DB.Exec("COMMIT TRANSACTION")
}


;----------------------- ACTION MODE ----------------------------------------------------

actionmode:
	update_actionmode()
	temp_am := TT_Console(ACTIONMODE.text, ACTIONMODE.keys, __x, __y, "s9", "Consolas", 5)
	if ACTIONMODE[temp_am] != "Exit_actmd"
	{
		if Instr(ACTIONMODE[temp_am] , "(")
			RunFunc(ACTIONMODE[temp_am])
		else if ACTIONMODE[temp_am]
			gosub % ACTIONMODE[temp_am]
		else if temp_am is Integer 			; give user chance to override setting
			if changeChannel(temp_am)
				autoTooltip( RegExReplace(TXT.CNL_chngMsg, "%cv1%", temp_am " {" CN.Name "}"), 800, 2)
			else autoTooltip( RegExReplace(TXT.CNL_chNtExst, "%cv1%", temp_am " {" CN.Name "}"), 800, 2)
	}
	else
		EmptyMem()
	return

init_actionmode(){
	ACTIONMODE := {H: "history", O: "channelOrganizer", C: "copyfile", X: "copyfolder", F: "CopyFileData", D: "disable_clipjump"
		, P: "pitswap", T: "onetime", E: "settings", F1: "hlp", Esc: "Exit_actmd", M: "pluginManager_GUI()", F2: "OpenShortcutsHelp", L: "classTool"
		, U: "API.runPlugin(updateClipjumpClipboard.ahk)", B: "holdclip"
		, H_caption: TXT.HST__name, O_caption: TXT.SET_org, C_caption: TXT._cfilep, X_caption: TXT._cfolderp, F_caption: TXT._cfiled 
		, D_caption: TXT.ACT_disable " " PROGNAME, P_caption: TXT._pitswp, T_caption: TXT._ot, E_caption: TXT.SET__name
		, F1_caption: TXT.TRY_help, Esc_caption: TXT.ACT_exit, M_caption: TXT.PLG__name, F2_caption: TXT.try_pstmdshorts, L_caption: TXT.IGN__name
		, U_caption: TXT.PLG_sync_cb, B_caption: TXT.SET_holdclip}
}		; use runPlugin so that user might delete plugin

update_actionmode(){
	static numadd := "0123456789"
	thetext := ""
	.  PROGNAME " " TXT.ACT__name
	. "`n-----------"
	. "`n"
	ACTIONMODE.remove("text") , ACTIONMODE.remove("keys")

	thetext .= "`n" fillWithSpaces(TXT.ACT_switchChannel, 25) " -  " "0..9"

	for k,v in ACTIONMODE
	if !Instr(k, "_") && (k != "Esc") && v{
		thekeys .= k " "
		thetext .= "`n" fillwithSpaces( ACTIONMODE[k "_caption"] ? ACTIONMODE[k "_caption"] : v , 25 ) " -  " k
	}
	if ACTIONMODE.Esc
		thetext .= "`n`n" fillwithSpaces( ACTIONMODE.Esc_caption ? ACTIONMODE.Esc_caption : ACTIONMODE.Esc , 25 ) " -  Esc" , thekeys .= "Esc"
	loop, parse, numadd
		thekeys .= " " A_LoopField
	ACTIONMODE.keys := Trim(thekeys)
	ACTIONMODE.text := thetext
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
		API.blockMonitoring(1)
		try_ClipboardfromFile(selectedFile)
		ClipWait, 1, 1
		oldclip := ClipboardAll
		API.blockMonitoring(0)
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
	if A_IsCompiled or H_Compiled
		run Clipjump.chm
	else
		run % FileExist("Clipjump.chm") ? "Clipjump.chm" : "website\_site\index.html"
	return

strtup:
	Menu, Options_Tray, Togglecheck, % TXT.TRY_startup
	IfExist, %A_Startup%/Clipjump.lnk
		FileDelete, %A_Startup%/Clipjump.lnk
	else FileCreateShortcut, % H_Compiled ? A_AhkPath : A_ScriptFullPath, %A_Startup%/Clipjump.lnk
	return

updt:
	Tooltip, Checking for Updates ...... , , , 3
	URLDownloadToFile, %UPDATE_FILE%, %A_WorkingDir%/cache/latestversion.txt
	ToolTip, ,,, 3
	FileRead, temp, %A_WorkingDir%/cache/latestversion.txt
	lversion_changes := "`n`nCHANGES`n"
	loop, parse, temp, `n, `r
		if A_index=1
			latestVersion := A_LoopField
		else lversion_changes .= "`n" A_LoopField

	if !IsLatestRelease(VERSION, latestversion, "b|a")
	{
		MsgBox, 48, Clipjump Update available, % "Your Version: `t`t" VERSION "`nCurrent version: `t`t" latestVersion . lversion_changes
		IfMsgBox OK
			BrowserRun(PRODUCT_PAGE)
	}
	else MsgBox, 64, %PROGNAME%, % TXT.ABT_noupdate
	return

;************************************** Helper FUNCTIONS ****************************************

addToWinClip(lastEntry, extraTip){
	API.blockMonitoring()
	PasteModeToolTip( Valueof(extraTip), 1)
	if CURSAVE
		try FileRead, Clipboard, *c %A_WorkingDir%/%CLIPS_dir%/%lastentry%.avc
	Sleep, 1000
	ToolTip
	API.blockMonitoring(0)
}

/**
 * makes the shortcut responsible for copy and cut to clipjump
 * status - enabled/disabled
 * @return {void}
 */
copyCutShortcuts(status = 1){
	if (ini_winClipjump == 1){
		hkZ("$^c", "windows_copy", status) , hkZ("$^x", "windows_cut", status)
		hkZ("#c", "NativeCopy", status) , hkZ("#x", "NativeCut", status)
	} else {
		hkZ("$^c", "NativeCopy", status) , hkZ("$^x", "NativeCut", status)
	}
}

changeIcon(){
global

	if A_IsCompiled or H_Compiled 		; H_Compiled is a user var created if compiled with ahk_h
		Menu, tray, icon, % A_AhkPath
	else
		Menu, tray, icon, % mainIconPath
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
	gosub endPastemode
	loop
		if !FileExist(temp := A_MyDocuments "\export" A_index ".cj")
			break
	Tooltip % "{" CN.Name "} Clip " realClipNo " " TXT._exportedto "`n" temp
	SetTimer, TooltipOff, 2500
	try FileAppend, %ClipboardAll%, % temp
	return

editclip:
	correctTEMPSAVE()
	editClip(CN.NG, CURSAVE-TEMPSAVE+1, "pstmd")
	return

editClip(cnl, clip, owner="none"){
; Opens def editor for editing a clip
	global
	local ClipLoc, EditImg, tmpsv, temp_clipboard2
	clipLoc := API.getClipLoc(cnl, clip) , tmpsv := API.getChStrength(cnl)-clip+1
	if owner != "pstmd"
	{
		API.blockMonitoring(1) 
		try_ClipboardfromFile(clipLoc) 
		API.blockMonitoring(0)
	}
	temp_clipboard := trygetVar("Clipboard")
	Tooltip, % TXT.TIP_editing,,, 10
	if owner = pstmd
	{
		IScurCBACTIVE := 1
		gosub endPastemode
	}
	EditImg := 0

	if !GetClipboardFormat()
	{
		EditImg := 1
		Gdip_CaptureClipboard(A_WorkingDir "\cache\edit.jpg", 100)
		if !FileExist("cache\edit.jpg")
		{
			autoTooltip(TXT.TIP_editnotdone, 800, 10)
			return
		}
		run, % ini_defImgEditor " """ A_WorkingDir "\cache\edit.jpg" """",,, editclip_pid
	}
	else {
		FileDelete, cache\edit.txt
		FileAppend, % temp_clipboard , cache\edit.txt
		run, % ini_defEditor " """ A_WorkingDir "\cache\edit.txt" """",,, editclip_pid
	}

	hkZ("Esc", "editclip_cancel", 1)
	Critical, Off

	loop {
		Process, Exist, % editclip_pid
		if !ErrorLevel
			break
		sleep 100
	}
	if (editclip_cancel) {
		editclip_cancel := "" , autoTooltip(TXT.TIP_editnotdone, 800, 10)
		return
	}

	if EditImg {
		API.blockMonitoring(1)
		Gdip_SetImagetoClipboard(A_WorkingDir "\cache\edit.jpg")
		ClipWait, 3, 1
		try FileAppend, %ClipboardAll%, % clipLoc
		Gdip_CaptureClipboard( A_WorkingDir "\cache\thumbs" (!cnl ? "" : cnl) "\" tmpsv ".jpg", ini_Quality)
		FileDelete, cache\edit.jpg
		API.blockMonitoring(0)
	} else {
		Fileread, temp_clipboard2, cache\edit.txt
		API.Text2Binary(temp_clipboard2, temp_clipboardall)
		FileDelete, % clipLoc
		FileAppend, % temp_clipboardall, % clipLoc
		CDS[cnl][tmpsv] := temp_clipboard2
	}

	autoTooltip(TXT.TIP_editdone, 800, 10)
	if owner = pstmd
		IScurCBACTIVE := false
	STORE.ErrorLevel := 1
	return EditImg ? TXT.HST_viewimage : temp_clipboard2

editclip_cancel:
	Critical, On
	editclip_cancel := 1
	hkZ("Esc", "editclip_cancel", 0)
	Process, Close, % editclip_pid
	return
}

windows_copy:
	API.blockMonitoring(1)
	Send ^{vk43}
	sleep 100
	makeClipboardAvailable(0)   ;wait till Clipboard is ready
	API.blockMonitoring(0)
	return

windows_cut:
	API.blockMonitoring(1)
	Send ^{vk58}
	sleep 100
	makeClipboardAvailable(0)
	API.blockMonitoring(0)
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
	copyCutShortcuts(CLIPJUMP_STATUS)
	changeIcon()

	hkZ( ( paste_k ? "$" pstIdentifier paste_k : emptyvar ) , "Paste", CLIPJUMP_STATUS)
	Menu, Options_Tray, % !CLIPJUMP_STATUS ? "Check" : "Uncheck", % TXT.TRY_disable " " PROGNAME
	init_actionmode() 			;refresh enable/disable text in action mode
	return

routines_Exit() {
	Ini_write("Clipboard_history_window", "partial", history_partial, 0)
	if IsObject(DB){
		DB.CloseDb()
		DB := ""
	}
	Prefs2Ini()
	updatePluginIncludes()
	DllCall( "GDI32.DLL\RemoveFontResourceEx",Str, GHICON_PATH,UInt,(FR_PRIVATE:=0x10),Int,0)
}

;#################### COMMUNICATION ##########################################

;The function enables/disables Clipjump with respect to the Communicator.
Act_CjControl(C){
	Msgbox, 48, % PROGNAME, % "Clipjump Controller has been discontinued."
}

Receive_WM_COPYDATA(wParam, lParam){
	global
    Local D
    static k := "API:" , cmd := "cmd:"

	D := StrGet( NumGet(lParam + 2*A_PtrSize) )  ;unicode transfer
    if D is not Integer
    	if !Instr(D, k) 	; if both are false and so the input is garbled (chinese)
    		D := StrGet( NumGet(lParam + 2*A_PtrSize), 8, "UTF-8")  ;ansi conversion
    if Instr(D, k)
    	a := Act_API(D, k) 	; done to not cause error if no lib is included
    else Act_CjControl(D)

    while !FileExist(A_temp "\clipjumpcom.txt")
    	FileAppend, a,% A_temp "\clipjumpcom.txt"

    EmptyMem()
    return 1
}

;##############################################################################

#Include %A_ScriptDir%\lib\WM_MOUSEMOVE.ahk
#Include %A_ScriptDir%\lib\Searchpastemode.ahk
#Include %A_ScriptDir%\lib\Customizer.ahk
#Include %A_ScriptDir%\lib\API.ahk
#Include %A_ScriptDir%\lib\translations.ahk
#Include %A_ScriptDir%\lib\multi.ahk
#Include %A_ScriptDir%\lib\aboutgui.ahk
#include %A_ScriptDir%\lib\TT_Console.ahk
#include %A_ScriptDir%\lib\Gdip_min.ahk
#include %A_ScriptDir%\lib\HotkeyParser.ahk
#include %A_ScriptDir%\lib\anticj_func_labels.ahk
#include %A_ScriptDir%\lib\settings gui plug.ahk
#include %A_ScriptDir%\lib\history gui plug.ahk
#include %A_ScriptDir%\lib\pluginManager.ahk
#include %A_ScriptDir%\lib\channelOrganizer.ahk
#include %A_ScriptDir%\lib\TooltipEx.ahk
#include %A_ScriptDir%\lib\SQLiteDB\Class_SQLiteDB.ahk
#include %A_ScriptDir%\lib\settingsHelper.ahk
#include *i %A_ScriptDir%\plugins\_registry.ahk

;------------------------------------------------------------------- X -------------------------------------------------------------------------------