;Gui Settings for Clipjump
;A lot of thanks to chaz

; When adding new settings m remember to update ADVANCED_NUMBER var in the main file
; Tooltip Number for Settings GUI - 4
gui_Settings()
; Preconditions: ini settings in variables starting with _ini
; Postconditions: Builds and shows a GUI in which Clipjump settings can be changed. New settings are written to the configuration file when OK or Apply is pressed, but only if changes have been made.
{
	global
	local settingsHaveChanged := false
	local size_limitmaxclips, size_keepsession, size_cfolderp, left_size, x_ofhotkeys, size_advanced

	; get max sizes possible of window
	size_limitmaxclips := getControlInfo("checkbox", TXT.SET_limitmaxclips, "w")
	size_keepsession := getControlInfo("checkbox", TXT.SET_keepsession, "w")
	right_size := size_cfolderp := getControlInfo("text", TXT._cfolderp, "w") + 9 + 120 + 50 ;9=max margin ; 120=width of hotkey control, 50 = cstm gap betn controls
	left_size := ( size_limitmaxclips >= size_keepsession ? size_limitmaxclips : size_keepsession ) + 16 + 50 
	; 16= max margin of any control (maxlcips)  ,  50 = width of updown

	;enable tooltips
	OnMessage(0x200, "WM_MOUSEMOVE")

	Gui, Settings:New
	Gui, Margin, 8, 8
	Gui, Add, GroupBox,	% "w" left_size " h267", % TXT.SET_main		; for every new checkbox add 18 pixels to the height, and for every new UpDown control add 26 pixels
	; The total width of the GUI is about 289 x 2
	
	Gui, Add, CheckBox, xp+9 yp+22 Section Checked%ini_limitMaxClips% vnew_limitMaxClips gchkbox_limitMaxClips, % TXT.SET_limitmaxclips	; when this is checked the following two controls will be disabled
	Gui, Add, Text,		xs+16, % TXT.SET_maxclips
	Gui, Add, Edit,	%	"x" left_size-55 " yp-3 w50 r1 Number vnew_MaxClips gedit_MaxClips" 		; 55 = 50(widthofupdown) + 5(margin)
	Gui, Add, UpDown,	Range1-1000 gupdown_MaxClips, %ini_MaxClips%
	
	Gui, Add, Text,		xs+16, % TXT.SET_threshold
	Gui, Add, Edit,	%	"x" left_size-55 " yp-3 w50 r1 Number vnew_Threshold gedit_Threshold"
	Gui, Add, UpDown,	Range1-1000 gupdown_Threshold, %ini_Threshold%

	Gui, Add, Text,		xs, % TXT.SET_quality
	Gui, Add, Edit,	%	"x" left_size-55 " yp-3 w50 r1 Number vnew_Quality gedit_Quality"
	Gui, Add, UpDown,	Range1-100 gupdown_Quality, %ini_Quality%

	Gui, Add, Checkbox, xs Checked%ini_CopyBeep% 		vnew_copyBeep 			gchkbox_copybeep, 		% TXT.SET_copybeep
	Gui, Add, Checkbox, xs Checked%ini_IsMessage%		vnew_IsMessage			gchkbox_IsMessage,		% TXT.SET_ismessage
	Gui, Add, Checkbox, xs Checked%ini_KeepSession%		vnew_KeepSession		gchkbox_KeepSession,	% TXT.SET_keepsession
	Gui, Add, Checkbox, xs Checked%ini_PreserveClipPos%		vnew_PreserveClipPos 	gsettingsChanged, 	% TXT.SET_keepactivepos

	Gui, Add, Text, xs y+10, % TXT.SET_pformat 		; the y param is not needed but to make it symmetrical
	; Build pformats list
	tempLst := "-original-|" (ini_def_pformat="" ? "|" : "")
	for tempK, tempV in PLUGINS.pformat
		tempLst .= tempV["Name"] "|"     ( (ini_def_pformat == tempV["Name"]) ? "|" : "" ) 
	Gui, Add, DropDownList, % "x" left_size-110 " w110 yp-3  r5	vnew_default_pformat 		gdropdown_pformat",		% tempLst


	;---- Clipboard H
	Gui, Add, GroupBox, % "xm y283 w" left_size " h74",	% TXT.SET_cb  ;

	Gui, Add, Text,		xp+9 yp+22,		% TXT.SET_daystostore
	Gui, Add, Edit,	%	"x" left_size-55 " yp-3 w50 r1 Number vnew_DaysToStore gedit_DaysToStore"
	Gui, Add, UpDown,	Range0-100000 gupdown_DaysToStore, %ini_DaysToStore%

	Gui, Add, Checkbox,	xs y+8 Checked%ini_IsImageStored% vnew_IsImageStored gchkbox_IsImageStored, % TXT.SET_images

	;---- Shortcuts
	x_ofhotkeys := left_size+right_size+5-120
	;5 is gap betn two adjacent group boxes , 120 is width of hotkey control
	Gui, Add, GroupBox, % "ym w" right_size " h267 vshortcutgroupbox",	% TXT.SET_shortcuts
	Gui, Add, Text, 	xp+9 yp+22 section,	% TXT.SET_pst
	Gui, Add, Edit, %	"Limit1 Uppercase -Wantreturn x" x_ofhotkeys " yp-3 w120 vpst_K ghotkey_paste", % paste_k
	Gui, Add, Text, 	xs y+8,		% TXT.SET_actmd
	Gui, Add, Hotkey, 	x%x_ofhotkeys% yp-3 vactmd_K   ghotkey_actmd, % Actionmode_K
	Gui, Add, Text, 	xs y+8, 	% TXT.SET_org
	Gui, Add, Hotkey, 	x%x_ofhotkeys% yp-3 vorg_K 		gsettingsChanged, % chOrg_K
	Gui, Add, Text, 	xs y+8,		% TXT._cfilep
	Gui, Add, Hotkey, 	x%x_ofhotkeys% yp-3 vcfilep_K   ghotkey_cfilep, % Copyfilepath_K
	Gui, Add, Text,		xs y+8,		% TXT._cfolderp
	Gui, Add, Hotkey,	x%x_ofhotkeys% yp-3 vcfolderp_K ghotkey_cfolderp, % Copyfolderpath_K
	Gui, Add, Text,		xs y+8,		% TXT._cfiled
	Gui, Add, Hotkey,	x%x_ofhotkeys% yp-3 vcfiled_K   ghotkey_cfiled, % Copyfiledata_K
	Gui, Add, Text,		xs y+8,		% TXT.SET_chnl
	Gui, Add, Hotkey,	x%x_ofhotkeys% yp-3 vchnl_K		ghotkey_chnl, % channel_K
	Gui, Add, Text,		xs y+8,		% TXT.SET_holdclip
	Gui, Add, Hotkey,	x%x_ofhotkeys% yp-3 vhldClip_K		ghotkey_holdClip, % holdClip_K
	Gui, Add, Text, 	xs y+8, 	% TXT.PLG__name
	Gui, Add, Hotkey, 	x%x_ofhotkeys% yp-3 vplugM_K 	ghotkey_plugM, % pluginManager_K

	;---- Channels
	Gui, Add, GroupBox, % "xs-9 y283 w" right_size " h74", % PROGNAME " " TXT.SET_channels
	Gui, Add, Text, 	xs yp+22,	% TXT._pitswp " Hotkey"
	Gui, Add, Hotkey,	x%x_ofhotkeys% yp-3 vpitswp_K  ghotkey_pitswp, % pitswap_K
	Gui, Add, Checkbox, xs y+8 Checked%ini_IsChannelMin% vnew_IsChannelMin gchkbox_isChannelMin, % TXT.SET_ischannelmin

	;---- Buttons
	size_advanced := getControlInfo("text", TXT.SET_advanced, "w", "Underline")
	Gui, Settings:Default
	Gui, Font, Underline
	Gui, Add, Text, 	% "y363 x" left_size+right_size+5-size_advanced " cBlue gsettings_open_advanced", % TXT.SET_advanced 	;+5 for gap betn group boxes
	Gui, Add, Text, 	x9 yp cBlue gClassTool, % TXT.SET_manageignore
	Gui, font, norm
	Gui, Add, Button,	% "x" ((left_size+right_size)/2)-60 " yp+23 Default gsettingsButtonOK", 	&OK 	;57 in vertical
	Gui, Add, Button,	x+8 gsettingsButtonCancel,			% TXT.SET_cancel
	Gui, Add, Button,	x+8	Disabled vsettingsButtonApply gsettingsButtonApply,	% TXT.SET_apply
	GuiControl, Disable, settingsButtonApply

	Gui, Settings:Show, , %PROGNAME% Settings

	if ini_limitMaxClips = 0
	{
		GuiControl, Disable, new_Maxclips
		GuiControl, Disable, new_Threshold
	}

	;disable hotkey keys
	Hotkey, IfWinActive, % PROGNAME " " TXT.SET__name
	#If IsHotkeyControlActive()
	Hotkey, If, IsHotkeyControlActive()
	hkZ(Copyfilepath_K, "shortcutblocker_settings", 1)
	hkZ(Copyfolderpath_K, "shortcutblocker_settings", 1)
	hkZ(Copyfiledata_K, "shortcutblocker_settings", 1)
	hkZ(channel_K, "shortcutblocker_settings", 1)
	hkZ(holdclip_K, "shortcutblocker_settings", 1)
	hkZ(pitswap_K, "shortcutblocker_settings", 1)
	hkZ(actionmode_k, "shortcutblocker_settings", 1)
	hkz(pluginManager_K, "shortcutblocker_settings", 1)
	hkz(chOrg_K, "shortcutblocker_settings", 1)
	Hotkey, If
	#If
	Hotkey, If
	return

chkbox_limitMaxClips:
	Gui, Settings:Submit, NoHide
	if new_limitMaxClips = 0
	{
		GuiControl, , new_Maxclips, 0
		GuiControl, Disable, new_Maxclips
		GuiControl, Disable, new_Threshold
	}
	else if new_limitMaxClips = 1
	{
		GuiControl, , Edit1,% !ini_Maxclips ? 20 : ini_MaxClips
		GuiControl, Enable, new_Maxclips
		GuiControl, Enable, new_Threshold
	}
	; there isn't a return on purpose
settingsChanged:
edit_MaxClips:
updown_MaxClips:
edit_Threshold:
updown_Threshold:
edit_Quality:
updown_Quality:
chkbox_copybeep:
chkbox_KeepSession:
chkbox_IsMessage:
dropdown_pformat:
edit_DaysToStore:
updown_DaysToStore:
chkbox_IsImageStored:
hotkey_cfilep:
hotkey_cfolderp:
hotkey_cfiled:
hotkey_chnl:
hotkey_ot:
chkbox_ischannelmin:
hotkey_pitswp:
hotkey_actmd:
hotkey_plugM:
hotkey_holdClip:
	GuiControl, Enable, settingsButtonApply
	settingsHaveChanged := true
	return

hotkey_paste:
	GuiControlGet, pst_k
	pst_K := Trim(pst_k, "ESCXZAFH `t")
	if pst_k =
		GuiControl,, pst_k
	GuiControl, Enable, settingsButtonApply
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
	GuiControl, Disable, settingsButtonApply
	return

settings_open_advanced:
	try {
		run % "notepad.exe " CONFIGURATION_FILE
		WinWaitActive, ahk_class Notepad
		Send ^{vk47} 					;^g
		;Winwait, Go To Line
		Send % NUMBER_ADVANCED "{vk0d}"
	} 
	catch {
		MsgBox, 16, ERROR, % PROGNAME " " TXT.SET_advanced_error
	}
	return

}

WM_MOUSEMOVE()	; From the help file
; Called whenever the mouse hovers over a control, this function shows a tooltip for the control over
; which it is hovering. The tooltip text is specified in a global variable called variableOfControl_TT
{
    static currControl, prevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
	
	;--- Descriptions --------------

	NEW_LIMITMAXCLIPS_TT := TXT.SET_T_limitmaxclips
	NEW_MAXCLIPS_TT := TXT.SET_T_maxclips
	NEW_THRESHOLD_TT := TXT.SET_T_threshold
	NEW_COPYBEEP_TT := TXT.SET_T_copybeep
	NEW_QUALITY_TT := TXT.SET_T_quality
	NEW_KEEPSESSION_TT := TXT.SET_T_keepsession
	NEW_ISMESSAGE_TT := TXT.SET_T_ismessage
	new_default_pformat_TT := TXT.SET_T_pformat
	NEW_DAYSTOSTORE_TT := TXT.SET_T_daystostore
	NEW_ISIMAGESTORED_TT := TXT.SET_T_images
	pst_k_TT := TXT.SET_T_pst
	actmd_k_TT := TXT.SET_T_actmd
	chnl_K_TT := TXT.SET_T_chnl
	cfilep_K_TT := TXT.SET_T_cfilep
	cfolderp_K_TT := TXT.SET_T_cfolderp
	cfiled_K_TT := TXT.SET_T_cfiled
	hldClip_K_TT := TXT.SET_T_holdClip
	PITSWP_K_TT := TXT.SET_T_pitswp
	NEW_ischannelmin_TT := TXT.SET_T_ischannelmin
	plugM_k_TT := TXT.SET_t_PLUGM
	new_PreserveClipPos_TT := TXT.SET_T_keepactivepos
	org_K_TT := "Shortcut for Channel Organizer"

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
	IniRead, ini_CopyBeep, 		%CONFIGURATION_FILE%, Main, CopyBeep
	IniRead, ini_KeepSession,	%CONFIGURATION_FILE%, Main, Keep_Session
	IniRead, ini_Version,		%CONFIGURATION_FILE%, System, Version
	IniRead, ini_DaysToStore,	%CONFIGURATION_FILE%, Clipboard_History, Days_to_store
	IniRead, ini_IsImageStored,	%CONFIGURATION_FILE%, Clipboard_History, Store_images

	IniRead, Copyfilepath_K,% CONFIGURATION_FILE, Shortcuts, Copyfilepath_K, %A_space%
	IniRead, Copyfolderpath_K,% CONFIGURATION_FILE, Shortcuts, Copyfolderpath_K
	IniRead, Copyfiledata_K,% CONFIGURATION_FILE, Shortcuts, Copyfiledata_K
	Iniread, channel_K,% CONFIGURATION_FILE, Shortcuts, channel_K
	;Iniread, onetime_K,% CONFIGURATION_FILE, Shortcuts, onetime_K
	Iniread, paste_K, % CONFIGURATION_FILE, Shortcuts, paste_K
	Iniread, Actionmode_K, % CONFIGURATION_FILE, Shortcuts, actionmode_k

	Iniread, pitswap_K, % CONFIGURATION_FILE, Channels, pitswap_K
	Iniread, ini_IsChannelMin,% CONFIGURATION_FILE, Channels, IsChannelMin

	holdClip_K := ini_read("Shortcuts", "holdClip_K")
	ini_PreserveClipPos := ini_read("Main", "ini_PreserveClipPos")
	pluginManager_K := ini_read("Shortcuts", "pluginManager_K")
	ini_def_pformat := ini_read("Main", "default_pformat")
	chOrg_K := ini_read("Shortcuts", "chOrg_K")

	; // below are INI only settings , not loaded by settings editor

	if (all) {
		Iniread, history_K,  % CONFIGURATION_FILE, Advanced, history_K
		history_K := HParse(history_K)
		history_partial := Ini_read("Clipboard_history_window", "partial") ? 1 : 0 	; Important as the use of the var in History tool is such that false = 0 .

		Iniread, MSG_PASTING_t,% CONFIGURATION_FILE, Advanced, Show_pasting_tip, %A_space%
		MSG_PASTING := MSG_PASTING_t ? MSG_PASTING : ""

		iniread, windows_copy_k,% CONFIGURATION_FILE, Advanced, windows_copy_shortcut, %A_space%
		iniread, windows_cut_k, % CONFIGURATION_FILE, Advanced, windows_cut_shortcut, %A_space%
		windows_copy_k := HParse(windows_copy_k) , windows_cut_k := Hparse(windows_cut_k)

		iniread, ini_is_duplicate_copied, % CONFIGURATION_FILE, Advanced, is_duplicate_copied, %A_space%

		beepFrequency := ini_read("Advanced", "beepFrequency")
		if !beepFrequency
			beepFrequency := 1500

		ignoreWindows := ini_read("Advanced", "ignoreWindows")
		cut_is_delete_windows := ini_read("Advanced", "cut_equalto_delete")
		ini_defEditor := (t:=ini_read("System", "default_editor")) ? t : "Notepad.exe"
		;change priority once
		priority := ini_read("System", "Priority")
		try Process, Priority,, % Priority
		;v10.7.3
		ini_defImgEditor := (t:=ini_read("System", "default_image_editor")) ? t : "mspaint.exe"
	}

}

save_Settings()
; WORKS FOR THE SETTINGS EDITOR
; Preconditions: New settings are saved in variables beginning in "new_", corresponding to each setting.
; Postconditions: Settings in variables starting in "new_" are saved in the configuration file in the corresponding key.
{
	global
	IniWrite, %new_limitMaxClips%,		%CONFIGURATION_FILE%, Main, limit_MaxClips
	IniWrite, % (new_limitMaxClips ? new_Maxclips : 0) , %CONFIGURATION_FILE%, Main, Minimum_No_Of_Clips_to_be_Active
	IniWrite, %new_Threshold%,		%CONFIGURATION_FILE%, Main, Threshold
	IniWrite, %new_IsMessage%,		%CONFIGURATION_FILE%, Main, Show_Copy_Message
	IniWrite, %new_Quality%,		%CONFIGURATION_FILE%, Main, Quality_of_Thumbnail_Previews
	IniWrite, %new_copyBeep%,  		%CONFIGURATION_FILE%, Main, CopyBeep
	IniWrite, %new_KeepSession%,	%CONFIGURATION_FILE%, Main, Keep_Session
	IniWrite, %new_DaysToStore%,	%CONFIGURATION_FILE%, Clipboard_History, Days_To_Store
	IniWrite, %new_IsImageStored%,	%CONFIGURATION_FILE%, Clipboard_History, Store_Images
	
	IniWrite, %Cfilep_K%  ,% CONFIGURATION_FILE, Shortcuts, Copyfilepath_K
	IniWrite, %Cfolderp_K%,% CONFIGURATION_FILE, Shortcuts, Copyfolderpath_K
	IniWrite, %Cfiled_K%  ,% CONFIGURATION_FILE, Shortcuts, Copyfiledata_K
	Iniwrite, %chnl_K%	  ,% CONFIGURATION_FILE, Shortcuts, channel_K
	Iniwrite, %pst_k%	  ,% CONFIGURATION_FILE, Shortcuts, paste_K
	IniWrite, %actmd_k%   ,% CONFIGURATION_FILE, Shortcuts, actionmode_k

	IniWrite, %pitswp_k%  ,% CONFIGURATION_FILE, Channels, pitswap_K
	Iniwrite, %new_ischannelMin%, % CONFIGURATION_FILE , Channels, IsChannelMin
	; v10.7.3
	ini_write("Main", "default_pformat", new_default_pformat="-original-" ? "" : new_default_pformat, 0) 	; trim reqd to remove space
	ini_write("Shortcuts", "pluginManager_K", plugM_k, 0)
	ini_write("Shortcuts", "holdClip_K", hldClip_K, 0)
	ini_write("Main", "ini_PreserveClipPos", new_PreserveClipPos, 0)
	ini_write("Shortcuts", "chOrg_K", org_k, 0)

	;Disable old shortcuts
	  hkZ(Copyfilepath_K, 	"CopyFile", 0)
	, hkZ(Copyfolderpath_K, "CopyFolder", 0) 
	, hkZ(Copyfiledata_K,   "CopyFileData", 0)
	, hkZ(channel_K,		"channelGUI",  0)
	, hkZ(holdClip_K,		"holdClip",		0)
	, hkZ(paste_k ? "$^" paste_k : emptyvar, "paste", 	0)
	, hkZ(pitswap_K, 	   "PitSwap", 0)
	, hkZ(actionmode_K, 	"actionmode", 0)
	, hkZ(pluginManager_K, 	"pluginManagerGUI", 0)
	, hkZ(chOrg_K, "channelOrganizer", 0)

	;Re-create shortcuts
	  hkZ(Cfilep_K, "CopyFile", 1) 
	, hkZ(Cfolderp_K, "CopyFolder", 1)
	, hkZ(Cfiled_K,   "CopyFileData", 1)
	, hkZ(chnl_K, "channelGUI",  1)
	, hkZ(hldClip_K,	"holdClip",		1)
	, hkZ(pst_k ? "$^" pst_k : emptyvar, "paste", CLIPJUMP_STATUS )
	, hkZ(pitswp_K, "PitSwap", 1)
	, hkZ(actmd_k, "actionmode", 1)
	, hkZ(plugM_k, "pluginManagerGUI", 1)
	, hkZ(org_K, "channelOrganizer", 1)

	;Load settings will load correct values for vars
}

set_pformat(pst_format=""){
; Sets the default pformat at Clipjump startup , runs after all the plugins have been loaded.
	pst_format := pst_format="" ? ini_def_pformat : pst_format
	if pst_format == "-original-"
		pst_format := ""
	for k,v in PLUGINS.pformat
		if ( v["name"] == pst_format )
		{
			curPformat := v["name"] , curPfunction := v["*"] , curPisPreviewable := v["Previewable"]
			success := 1
			break
		}
	if !success 	; if no match was found = default
		curPformat := "" , curPisPreviewable := 0
	return 1
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

	IniWrite, 30,% CONFIGURATION_FILE, Clipboard_History, Days_to_store
	IniWrite, 0, % CONFIGURATION_FILE, Clipboard_History, Store_Images
	}

	IniWrite, %VERSION%,% CONFIGURATION_FILE, System, Version
	ini_write("System", "Priority", "N")
	ini_write("System", "default_editor", "Notepad.exe")
	s := "Shortcuts"
	Ini_Write(s, "Copyfilepath_K")
	Ini_Write(s, "Copyfolderpath_K")
	Ini_Write(s, "Copyfiledata_K")
	Ini_write(s, "channel_K")
	Ini_write(s, "onetime_k") 			;No default specified
	ini_write(s, "paste_k", "V")
	Ini_write(s, "actionmode_k", "^+a")

	ini_write("Channels",  "pitswap_K")
	Ini_Write("Channels", "IsChannelMin", "0")
	;---- Non GUI
	Ini_write(s := "Advanced", "history_k", "Win + c")
	Ini_write(s, "instapaste_write_clipboard", "0")
	ini_write(s, "Show_pasting_tip", "0")
	ini_write(s, "windows_copy_shortcut")
	ini_write(s, "windows_cut_shortcut")
	ini_write(s, "is_duplicate_copied", "1")
	ini_write(s, "beepFrequency", 1500)
	ini_write(s, "ignoreWindows", "")

	ini_write("Main", "CopyBeep", "0")
	ini_write("Advanced", "cut_equalto_delete", cut_is_delete_windows)
	; delete removed v10.7.2.6
	Ini_delete("Advanced", "Start_with_formatting")
	Ini_delete("Advanced", "Actionmode_keys")
	; v10.7.3 added
	ini_write("Main", "default_pformat", "")
	ini_write("Shortcuts", "pluginManager_K", "")
	; v10.7.8
	ini_write("System", "default_image_editor", "mspaint.exe")
	; v10.9
	ini_write("Shortcuts", "holdClip_K", "")
	ini_write("Main", "ini_PreserveClipPos", 1)
	ini_write("Shortcuts", "chOrg_K", "")
}

Ini_write(section, key, value="", ifblank=true){
	;ifblank means if the key doesn't exist

	Iniread, v,% CONFIGURATION_FILE,% section,% key

	if ifblank && (v == "ERROR")
		IniWrite,% value,% CONFIGURATION_FILE,% section,% key
	if !ifblank
		IniWrite,% value,% CONFIGURATION_FILE,% section,% key
}

Ini_read(section, key){
	Iniread, v, % CONFIGURATION_FILE,% section,% key, %A_space%
	if v = %A_temp%
		v := ""
	return v
}

Ini_delete(section, key){
	IniDelete, % CONFIGURATION_FILE, % section, % key
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

	if !ini_KeepSession
		clearData()

	TOTALCLIPS := ini_Threshold + ini_Maxclips
	CN.TotalClips := TotalClips

	ini_IsImageStored := ini_IsImageStored = 0 ? 0 : 1
	ini_DaysToStore := ini_DaysToStore < 0 ? 0 : ini_DaysToStore
	ini_PreserveClipPos := ini_PreserveClipPos ? 1 : 0

	if !ini_DaysToStore
	{
		NOINCOGNITO := false
		if CALLER_STATUS
			Menu, tray, icon, icons\no_history.ico
		Menu, Tray, check, % TXT.TRY_incognito
	}

	if paste_K = ERROR
		paste_K := "V"
	paste_K := Substr(paste_K, 1, 1)
}