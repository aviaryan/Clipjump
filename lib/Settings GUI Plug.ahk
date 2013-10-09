;Gui Settings for Clipjump
;A lot of thanks to chaz

; Tooltip Number for Settings GUI - 4
gui_Settings()
; Preconditions: ini settings in variables starting with _ini
; Postconditions: Builds and shows a GUI in which Clipjump settings can be changed. New settings are written to the configuration file when OK or Apply is pressed, but only if changes have been made.
{
	global
	local settingsHaveChanged := false

	;enable tooltips
	OnMessage(0x200, "WM_MOUSEMOVE")

	Gui, Settings:New
	Gui, Margin, 8, 8
	Gui, Add, GroupBox,	w289 h197, Main		; for every new checkbox add 18 pixels to the height, and for every new spinner (UpDown control) add 26 pixels
	; The total width of the GUI is about 289 x 2
	
	Gui, Add, CheckBox, xp+9 yp+22 Section Checked%ini_limitMaxClips% vnew_limitMaxClips gchkbox_limitMaxClips, &Limit the maximum number of active clipboards	; when this is checked the following two controls will be disabled
	Gui, Add, Text,		xs+16, &Minimum number of active clipboards:
	Gui, Add, Edit,		xm+225 yp-3 w50 r1 Number vnew_MaxClips gedit_MaxClips
	Gui, Add, UpDown,	Range1-1000 gupdown_MaxClips, %ini_MaxClips%
	
	Gui, Add, Text,		xs+16,	Clipboard &threshold:
	Gui, Add, Edit,		xm+225 yp-3 w50 r1 Number vnew_Threshold gedit_Threshold
	Gui, Add, UpDown,	Range1-1000 gupdown_Threshold, %ini_Threshold%

	Gui, Add, Text,		xs, &Quality of preview thumbnail:
	Gui, Add, Edit,		xm+225 yp-3 w50 r1 Number vnew_Quality gedit_Quality
	Gui, Add, UpDown,	Range1-100 gupdown_Quality, %ini_Quality%

	Gui, Add, Checkbox, xs Checked%ini_IsMessage%		vnew_IsMessage			gchkbox_IsMessage,			&Show verification ToolTip when copying
	Gui, Add, Checkbox, xs Checked%ini_KeepSession%		vnew_KeepSession		gchkbox_KeepSession,		&Retain clipboard data upon application restart
	Gui, Add, Checkbox, % "xs Checked" !ini_formatting " vnew_formatting			gchkbox_formatting",		Start with No &Formatting mode Enabled 

	;---- Clipboard H
	Gui, Add, GroupBox,	xm y213 w289 h74,	Clipboard History  ;h=169 + 16 ; + 10 in v8.7

	Gui, Add, Text,		xp+9 yp+22,		Number of days to keep items in &history:
	Gui, Add, Edit,		xm+225 yp-3 w50 r1 Number vnew_DaysToStore gedit_DaysToStore
	Gui, Add, UpDown,	Range0-100000 gupdown_DaysToStore, %ini_DaysToStore%

	Gui, Add, Checkbox,	xs y+8 Checked%ini_IsImageStored% vnew_IsImageStored gchkbox_IsImageStored, Store &images in history

	;---- Shortcuts
	Gui, Add, GroupBox, ym w289 h197 vshortcutgroupbox,	Shortcuts
	Gui, Add, Text, 	xp+9 yp+22 section,	Paste-Mode (Ctrl + ..)
	Gui, Add, Edit, 	Limit1 Uppercase -Wantreturn xs+155 yp-3 w120 vpst_K ghotkey_paste, % paste_k
	Gui, Add, Text, 	xs y+8,		Copy File Path(s)
	Gui, Add, Hotkey, 	xs+155 yp-3 vcfilep_K   ghotkey_cfilep, % Copyfilepath_K
	Gui, Add, Text,		xs y+8,		Copy Active Folder Path
	Gui, Add, Hotkey,	xs+155 yp-3 vcfolderp_K ghotkey_cfolderp, % Copyfolderpath_K
	Gui, Add, Text,		xs y+8,		Copy File Data
	Gui, Add, Hotkey,	xs+155 yp-3 vcfiled_K   ghotkey_cfiled, % Copyfiledata_K
	Gui, Add, Text,		xs y+8,		Select Channel
	Gui, Add, Hotkey,	xs+155 yp-3 vchnl_K		ghotkey_chnl, % channel_K
	Gui, Add, Text,		xs y+8,		One Time Stop
	Gui, Add, Hotkey,	xs+155 yp-3 vot_K		ghotkey_ot, % onetime_K

	;---- Channels
	Gui, Add, GroupBox, xs-9 y213 w289 h74, Clipjump Channels 	;h=169 + 16 ; +10 in v8.7 
	Gui, Add, Checkbox, xs yp+22 Checked%ini_IsChannelMin% vnew_IsChannelMin gchkbox_isChannelMin, Use Minimal GUI

	;---- Buttons
	Gui, Font, Underline
	Gui, Add, Text, 	y293 x480 cBlue gsettings_open_advanced, See Advanced Settings
	Gui, font, norm
	Gui, Add, Button,	x186 y318 w75 h23 Default, 	&OK 	;57 in vertical
	Gui, Add, Button,	x+8 w75 h23,			&Cancel
	Gui, Add, Button,	x+8 w75 h23	Disabled,	&Apply

	Gui, Settings:Show, , %PROGNAME% Settings

	if ini_limitMaxClips = 0
	{
		Control, Disable, , Edit1, %PROGNAME% Settings
		Control, Disable, , Edit2, %PROGNAME% Settings
	}

	;disable hotkey keys
	Hotkey, IfWinActive, %PROGNAME% Settings
	#If IsHotkeyControlActive()
	Hotkey, If, IsHotkeyControlActive()
	Hotkey,% Copyfilepath_K, shortcutblocker_settings, On UseErrorLevel
	Hotkey,% Copyfolderpath_K, shortcutblocker_settings, On UseErrorLevel
	Hotkey,% Copyfiledata_K, shortcutblocker_settings, On UseErrorLevel
	Hotkey,% channel_K, shortcutblocker_settings, On UseErrorLevel
	Hotkey,% onetime_K, shortcutblocker_settings, On UseErrorLevel
	Hotkey, If
	#If
	Hotkey, If
	return

chkbox_limitMaxClips:
	Gui, Settings:Submit, NoHide
	if new_limitMaxClips = 0
	{
		GuiControl, , Edit1, 0
		Control, Disable, , Edit1, %PROGNAME% Settings
		Control, Disable, , Edit2, %PROGNAME% Settings
	}
	else if new_limitMaxClips = 1
	{
		GuiControl, , Edit1,% !ini_Maxclips ? 20 : ini_MaxClips
		Control, Enable, , Edit1, %PROGNAME% Settings
		Control, Enable, , Edit2, %PROGNAME% Settings
	}
	; there isn't a return on purpose
edit_MaxClips:
updown_MaxClips:
edit_Threshold:
updown_Threshold:
edit_Quality:
updown_Quality:
chkbox_KeepSession:
chkbox_IsMessage:
chkbox_formatting:
edit_DaysToStore:
updown_DaysToStore:
chkbox_IsImageStored:
hotkey_cfilep:
hotkey_cfolderp:
hotkey_cfiled:
hotkey_chnl:
hotkey_ot:
chkbox_ischannelmin:
	Control, Enable, , &Apply, %PROGNAME% Settings
	settingsHaveChanged := true
	return

hotkey_paste:
	GuiControlGet, pst_k
	pst_K := Trim(pst_k, "ESCXZ `t")
	if pst_k =
		GuiControl,, pst_k
	Control, Enable, , &Apply, %PROGNAME% Settings
	settingsHaveChanged := true
	return

settingsButtonOk:
	Gui, Settings:Submit, NoHide
	if settingsHaveChanged		; we don't it to save if settings haven't changed (to increase performance, though minimal)
	{
		save_Settings()
		load_Settings() , validate_Settings()
		settingsHaveChanged := false
	}
	Gui, Settings:Destroy
	return

settingsButtonCancel:
settingsGuiEscape:
settingsGuiClose:
	Gui, Settings:Destroy
	Tooltip, ,,, 4
	settingsHaveChanged := false
	OnMessage(0x200, "")
	EmptyMem()
	return
	
settingsButtonApply:
	Gui, Settings:Submit, NoHide
	if settingsHaveChanged
	{
		save_Settings()
		load_Settings() , validate_Settings()
		settingsHaveChanged := false
	}
	Control, Disable, , &Apply, %PROGNAME% Settings
	return

settings_open_advanced:
	try {
		run % "notepad.exe " CONFIGURATION_FILE
		WinWaitActive, ahk_class Notepad
		Send ^g
		;Winwait, Go To Line
		Send % NUMBER_ADVANCED "{Enter}"
	} 
	catch {
		MsgBox, 16, ERROR, Clipjump is not able to find the settings file (settings.ini) or Notepad ? Make sure both exist in their respective places. `n`nTry contacting the author if problem persists.
	}
	return

}

WM_MOUSEMOVE()	; From the help file
; Called whenever the mouse hovers over a control, this function shows a tooltip for the control over
; which it is hovering. The tooltip text is specified in a global variable called variableOfControl_TT
{
    static currControl, prevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
	
	;--- Descriptions --------------

	static NEW_LIMITMAXCLIPS_TT := "Will Clipjump's Clipboards be limited`nChecked = yes"
	static NEW_MAXCLIPS_TT := "It is the minimum no of clipboards that you want simultaneously to be active.`nIf you want 20, SPECIFY 20."

	static NEW_THRESHOLD_TT := "
	(Ltrim
		Threshold is the extra number of clipboard that will be active other than your minimum limit..
		Most recommended value is 10.

		[TIP] - Threshold = 1 will make Clipjump store an exact number of maximum clipboards.
	)"

	static NEW_QUALITY_TT := "The quality of Thumbnail previews you want to have.`nRecommended value is 90`nCan be between 1 - 100"
	static NEW_KEEPSESSION_TT := "Should Clipjump continue with all the saved clipboards after it's restart"
	static NEW_ISMESSAGE_TT := "This value determines whether you want to see the ""Transferred to Clipjump"" message or not while copy/cut operations."
	static NEW_FORMATTING_TT := "Do you want Clipjump to start with No-Formatting Mode enabled ?`nTick for Yes."

	static NEW_DAYSTOSTORE_TT := "Number of days for which the clipboard record will be stored"
	static NEW_ISIMAGESTORED_TT := "Should clipboard images be stored in history ?"

	static pst_k_TT := "Single character combination to use with Ctrl in activating [PASTE MODE]`nNote that letters  E C X Z S  are reserved."
						. "`n`nAlso make sure to see ""Copy bypassing Clipjump"" in the help file"
	static chnl_K_TT := "Shortcut to show the <Select Channel> Window`nSet the shortcut to None to disable the key combination"
	static cfilep_K_TT := "Shortcut to copy selected file's path`nSet the shortcut to None to disable the functionality"
	static cfolderp_K_TT := "Shortcut to copy selected folder's path`nSet the shortcut to None to disable the functionality"
	static cfiled_K_TT := "Shortcut to copy selected file contents to Clipjump`nSet it to None to disable the functionality"
	static OT_K_TT := "
	(LTrim
		Select shortcut for [One Time Stop] feature.
		[One Time Stop] feature will make Clipjump ignore the next data that is transferred to the system Clipboards from the time it is activated.
		Set the key to None to free the key combination and disable the functionality
	)"

	static NEW_ischannelmin_TT := "
	(LTrim
		Makes the Channel GUI minimal in details and more productive.
		The Minimal GUI will not contain any buttons, you will have to use ENTER to confirm.
	)"

	;---------------------------------------------

	currControl := A_GuiControl
    If (currControl <> prevControl and !InStr(currControl, " ") and !Instr(currControl, "&"))
    {
		ToolTip, ,,, 4	;remove the old Tooltip
		global Text_TT := %currControl%_TT
		SetTimer, DisplayToolTip, 650
        prevControl := currControl
    }
    return

DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip, % Text_TT,,, 4  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 8000
    return

removeToolTip:
    SetTimer, removeToolTip, Off
    ToolTip, ,,, 4
    return
}

load_Settings(all=false)
; Preconditions: None
; Postconditions: Reads settings from the configuration file and saves them in corresponding variables beginning with "ini_".
{
	global
	IniRead, ini_limitMaxClips,	%CONFIGURATION_FILE%, Main, limit_MaxClips
	IniRead, ini_MaxClips,		%CONFIGURATION_FILE%, Main, Minimum_No_Of_Clips_to_be_Active
	IniRead, ini_Threshold,		%CONFIGURATION_FILE%, Main, Threshold
	IniRead, ini_IsMessage,		%CONFIGURATION_FILE%, Main, Show_Copy_Message
	IniRead, ini_Quality,		%CONFIGURATION_FILE%, Main, Quality_of_Thumbnail_Previews
	IniRead, ini_KeepSession,	%CONFIGURATION_FILE%, Main, Keep_Session
	IniRead, ini_Version,		%CONFIGURATION_FILE%, System, Version
	IniRead, ini_DaysToStore,	%CONFIGURATION_FILE%, Clipboard_History, Days_to_store
	IniRead, ini_IsImageStored,	%CONFIGURATION_FILE%, Clipboard_History, Store_images

	IniRead, Copyfilepath_K,% CONFIGURATION_FILE, Shortcuts, Copyfilepath_K
	IniRead, Copyfolderpath_K,% CONFIGURATION_FILE, Shortcuts, Copyfolderpath_K
	IniRead, Copyfiledata_K,% CONFIGURATION_FILE, Shortcuts, Copyfiledata_K
	Iniread, channel_K,% CONFIGURATION_FILE, Shortcuts, channel_K
	Iniread, onetime_K,% CONFIGURATION_FILE, Shortcuts, onetime_K
	Iniread, paste_K, % CONFIGURATION_FILE, Shortcuts, paste_K

	Iniread, ini_IsChannelMin,% CONFIGURATION_FILE, Channels, IsChannelMin

	if (all) {
		Iniread, history_K,  % CONFIGURATION_FILE, Advanced, history_K
		history_K := HParse(history_K)

		Iniread, ini_formatting, % CONFIGURATION_FILE, Advanced, Start_with_formatting, %A_space%
		FORMATTING := ini_formatting ? 1 : 0

		Iniread, MSG_PASTING_t,% CONFIGURATION_FILE, Advanced, Show_pasting_tip, %A_space%
		MSG_PASTING := MSG_PASTING_t ? MSG_PASTING : ""

		iniread, windows_copy_k,% CONFIGURATION_FILE, Advanced, windows_copy_shortcut, %A_space%
		iniread, windows_cut_k, % CONFIGURATION_FILE, Advanced, windows_cut_shortcut, %A_space%
		windows_copy_k := HParse(windows_copy_k) , windows_cut_k := Hparse(windows_cut_k)

		iniread, ini_is_duplicate_copied, % CONFIGURATION_FILE, Advanced, is_duplicate_copied, %A_space%
	}

}

save_Settings()
; Preconditions: New settings are saved in variables beginning in "new_", corresponding to each setting.
; Postconditions: Settings in variables starting in "new_" are saved in the configuration file in the corresponding key.
{
	global
	IniWrite, %new_limitMaxClips%,		%CONFIGURATION_FILE%, Main, limit_MaxClips
	IniWrite, % (new_limitMaxClips ? new_Maxclips : 0) , %CONFIGURATION_FILE%, Main, Minimum_No_Of_Clips_to_be_Active
	IniWrite, %new_Threshold%,		%CONFIGURATION_FILE%, Main, Threshold
	IniWrite, %new_IsMessage%,		%CONFIGURATION_FILE%, Main, Show_Copy_Message
	IniWrite, %new_Quality%,		%CONFIGURATION_FILE%, Main, Quality_of_Thumbnail_Previews
	IniWrite, %new_KeepSession%,	%CONFIGURATION_FILE%, Main, Keep_Session
	Iniwrite, % !new_formatting, 	%CONFIGURATION_FILE%, Advanced, Start_with_formatting
	IniWrite, %new_DaysToStore%,	%CONFIGURATION_FILE%, Clipboard_History, Days_To_Store
	IniWrite, %new_IsImageStored%,	%CONFIGURATION_FILE%, Clipboard_History, Store_Images
	
	IniWrite, %Cfilep_K%  ,% CONFIGURATION_FILE, Shortcuts, Copyfilepath_K
	IniWrite, %Cfolderp_K%,% CONFIGURATION_FILE, Shortcuts, Copyfolderpath_K
	IniWrite, %Cfiled_K%  ,% CONFIGURATION_FILE, Shortcuts, Copyfiledata_K
	Iniwrite, %chnl_K%	  ,% CONFIGURATION_FILE, Shortcuts, channel_K
	IniWrite, %ot_K% 	  ,% CONFIGURATION_FILE, Shortcuts, onetime_K
	Iniwrite, %pst_k%	  ,% CONFIGURATION_FILE, Shortcuts, paste_K

	Iniwrite, %new_ischannelMin%, % CONFIGURATION_FILE , Channels, IsChannelMin

	  hkZ( (T := Cfilep_K) ? T : Copyfilepath_K, 	   "CopyFile", T?1:0) 
	, hkZ( (T := Cfolderp_K) ? T : Copyfolderpath_K, "CopyFolder", T?1:0) 
	, hkZ( (T := Cfiled_K) ? T : Copyfiledata_K,     "CopyFileData", T?1:0)
	, hkZ( (T := chnl_K)   ? T : channel_K,			 "channelGUI",  T?1:0)
	, hkZ( (T := ot_K)	   ? T : onetime_K,			"onetime",		T?1:0)
	, hkZ( "$^" ( (T := pst_k) ? T : paste_k ), 		"paste", 	T?1:0)

	Copyfilepath_K := cfilep_K
	, Copyfolderpath_K := cfolderp_K
	, Copyfilepath_K := cfiled_K
	, channel_K := chnl_K
	, onetime_K := ot_K
	, paste_K := pst_K
}

save_Default(full=1){
; Saves the default settings for Clipjump
	
	if (full){
	IniWrite, 1, % CONFIGURATION_FILE, Main, limit_MaxClips
	IniWrite, 20,% CONFIGURATION_FILE, Main, Minimum_No_Of_Clips_to_be_Active
	IniWrite, 10,% CONFIGURATION_FILE, Main, Threshold
	IniWrite, 1, % CONFIGURATION_FILE, Main, Show_Copy_Message
	IniWrite, 90,% CONFIGURATION_FILE, Main, Quality_of_Thumbnail_Previews
	IniWrite, 1, % CONFIGURATION_FILE, Main, Keep_Session

	IniWrite, 10,% CONFIGURATION_FILE, Clipboard_History, Days_to_store
	IniWrite, 1, % CONFIGURATION_FILE, Clipboard_History, Store_Images
	}

	IniWrite, %VERSION%,% CONFIGURATION_FILE, System, Version

	s := "Shortcuts"
	Ini_Write(s, "Copyfilepath_K", "^!c")
	Ini_Write(s, "Copyfolderpath_K", "^!x")
	Ini_Write(s, "Copyfiledata_K", "^!f")
	Ini_write(s, "channel_K", "^+c")
	Ini_write(s, "onetime_k", "!s")
	ini_write(s, "paste_k", "V")

	Ini_Write("Channels", "IsChannelMin", "0")
	;---- Non GUI
	Ini_write(s := "Advanced", "history_k", "Win + c")
	Ini_write(s, "instapaste_write_clipboard", "0")
	ini_write(s, "Start_with_formatting", "1")
	ini_write(s, "Show_pasting_tip", "0")
	ini_write(s, "windows_copy_shortcut", "")
	ini_write(s, "windows_cut_shortcut",  "")
	ini_write(s, "is_duplicate_copied", "1")
}


Ini_write(section, key, value, ifblank=true){
	Iniread, v,% CONFIGURATION_FILE,% section,% key

	if ifblank && (v == "ERROR")
		IniWrite,% value,% CONFIGURATION_FILE,% section,% key
	if !ifblank
		IniWrite,% value,% CONFIGURATION_FILE,% section,% key
}


validate_Settings()
; The function validates the settings for Clipjump . 
; The reason validate_Settings() is not inside load_Settings() is conflicts with Ini_MaxClips and its unlimited value (0).
{
	global

	if !ini_MaxClips			; if blank
		ini_MaxClips := 9999999
	if ini_MaxClips is not integer
		ini_MaxClips := 20
	If ini_Threshold is not integer
		ini_Threshold := 10

	CopyMessage := !ini_IsMessage ? "" : MSG_TRANSFER_COMPLETE " {" ( (CN.Name=="") ? "Default" : CN.Name ) "}"

	If ini_Quality is not Integer
		ini_Quality := 20
	if ini_KeepSession is not integer
		ini_KeepSession := 1
	ini_formatting := ini_formatting ? 1 : 0

	if !ini_KeepSession
		clearData()

	TOTALCLIPS := ini_Threshold + ini_Maxclips
	CN.TotalClips := TotalClips

	ini_IsImageStored := ini_IsImageStored = 0 ? 0 : 1
	ini_DaysToStore := ini_DaysToStore < 0 ? 0 : ini_DaysToStore

	if !ini_DaysToStore
	{
		NOINCOGNITO := false
		if CALLER_STATUS
			Menu, tray, icon, icons\no_history.ico
		Menu, Tray, check, &Incognito Mode
	}

	if paste_K = ERROR
		paste_K := "V"
	paste_K := Substr(paste_K, 1, 1)
}