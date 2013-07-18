;Gui Settings for Clipjump
;A lot of thanks to chaz

gui_Settings()
; Preconditions: ini settings in variables starting with _ini
; Postconditions: Builds and shows a GUI in which Clipjump settings can be changed. New settings are written to the configuration file when OK or Apply is pressed, but only if changes have been made.
{
	global
	local settingsHaveChanged := false
	
	Gui, Settings:New
	Gui, Margin, 8, 8
	Gui, Add, GroupBox,	w289 h164, Main		; for every new checkbox add 21 pixels to the height, and for every new spinner (UpDown control) add 26 pixels
	
	Gui, Add, CheckBox, xp+9 yp+17 Section Checked%ini_limitMaxClips% vnew_limitMaxClips gchkbox_limitMaxClips, &Limit the maximum number of active clipboards	; when this is checked the following two controls will be disabled
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

	Gui, Add, GroupBox,	xm w289 h69,	Clipboard History

	Gui, Add, Text,		xp+9 yp+17,		Number of days to keep items in &history:
	Gui, Add, Edit,		xm+225 yp-3 w50 r1 Number vnew_DaysToStore gedit_DaysToStore
	Gui, Add, UpDown,	Range1-200 gupdown_DaysToStore, %ini_DaysToStore%

	Gui, Add, Checkbox,	xs y+8 Checked%ini_IsImageStored% vnew_IsImageStored gchkbox_IsImageStored, Store &images in history

	Gui, Add, Button,	x57 w75 h23 Default, 	&OK
	Gui, Add, Button,	x+8 w75 h23,			&Cancel
	Gui, Add, Button,	x+8 w75 h23	Disabled,	&Apply

	Control, Disable, , Button9, %PROGNAME% Settings	; disable the Apply button; see comment below
	Gui, Settings:Show, , %PROGNAME% Settings
	SetTimer, disableApplyButton	; for some reason the Apply button will not stay disabled unless this is done. Without this it'll disable then immediately enable again
	if ini_limitMaxClips = 0
	{
		Control, Disable, , Edit1, %PROGNAME% Settings
		Control, Disable, , Edit2, %PROGNAME% Settings
	}
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
edit_DaysToStore:
updown_DaysToStore:
chkbox_IsImageStored:
	Control, Enable, , Button9, %PROGNAME% Settings
	settingsHaveChanged := true
	return

settingsButtonOk:
	Gui, Settings:Submit, NoHide
	if settingsHaveChanged		; we don't it to save if settings haven't changed (to increase performance, though minimal)
	{
		save_Settings()
		load_Settings()
		settingsHaveChanged := false
	}
	Gui, Settings:Destroy
	return

settingsButtonCancel:
settingsGuiEscape:
settingsGuiClose:
	Gui, Settings:Destroy
	settingsHaveChanged := false
	return
	
settingsButtonApply:
	Gui, Settings:Submit, NoHide
	if settingsHaveChanged
	{
		save_Settings()
		load_Settings()
		settingsHaveChanged := false
	}
	Control, Disable, , Button9, %PROGNAME% Settings
	return
	
disableApplyButton:
	SetTimer, disableApplyButton, Off
	Control, Disable, , Button9, %PROGNAME% Settings
	return
}

WM_MOUSEMOVE()	; From the help file
; Called whenever the mouse hovers over a control, this function shows a tooltip for the control over
; which it is hovering. The tooltip text is specified in a global variable called variableOfControl_TT
{
    static currControl, prevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
	
	static NEW_LIMITMAXCLIPS_TT := "Will Clipjump's Clipboards be limited`nChecked = yes"

	static NEW_MAXCLIPS_TT := "It is the minimum no of clipboards that you want simultaneously to be active.`nIf you want 20, SPECIFY 20."

	static NEW_THRESHOLD_TT := "Threshold is the extra number of clipboard that will be active other than your minimum limit..`nMost recommended value is 10.`n`n[TIP] - Threshold = 1 will make Clipjump store an exact number of maximum clipboards."

	static NEW_QUALITY_TT := "The quality of Thumbnail previews you want to have.`nRecommended value is 90`nCan be between 1 - 100"
	
	static NEW_KEEPSESSION_TT := "Should Clipjump continue with all the saved clipboards after it's restart"
	static NEW_ISMESSAGE_TT := "This value determines whether you want to see the ""Transferred to Clipjump"" message or not while copy/cut operations."

	static NEW_DAYSTOSTORE_TT := "Number of days for which the clipboard record will be stored"
	static NEW_ISIMAGESTORED_TT := "Should clipboard images be stored in history ?"

	currControl := A_GuiControl
    If (currControl <> prevControl and !InStr(currControl, " ") and !Instr(currControl, "&"))
    {
		ToolTip		;remove the old Tooltip
		global Text_TT := %currControl%_TT
		SetTimer, DisplayToolTip, 650
        prevControl := currControl
    }
    return

DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip % Text_TT  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 8000
    return

removeToolTip:
    SetTimer, removeToolTip, Off
    ToolTip
    return
}

load_Settings()
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
}

save_Settings()
; Preconditions: New settings are saved in variables beginning in "new_", corresponding to each setting.
; Postconditions: Settings in variables starting in "new_" are saved in the configuration file in the corresponding key.
{
	global
	IniWrite, %new_limitMaxClips%,		%CONFIGURATION_FILE%, Main, limit_MaxClips
	IniWrite,% new_limitMaxClips ? new_Maxclips : 0, %CONFIGURATION_FILE%, Main, Minimum_No_Of_Clips_to_be_Active
	IniWrite, %new_Threshold%,		%CONFIGURATION_FILE%, Main, Threshold
	IniWrite, %new_IsMessage%,		%CONFIGURATION_FILE%, Main, Show_Copy_Message
	IniWrite, %new_Quality%,		%CONFIGURATION_FILE%, Main, Quality_of_Thumbnail_Previews
	IniWrite, %new_KeepSession%,	%CONFIGURATION_FILE%, Main, Keep_Session
	IniWrite, %new_DaysToStore%,	%CONFIGURATION_FILE%, Clipboard_History, Days_To_Store
	IniWrite, %new_IsImageStored%,	%CONFIGURATION_FILE%, Clipboard_History, Store_Images
	
	validate_Settings()		;change dependant on ini variables
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

	CopyMessage := !ini_IsMessage ? "" : MSG_TRANSFER_COMPLETE

	If ini_Quality is not Integer
		ini_Quality := 20
	if ini_KeepSession is not integer
		ini_KeepSession := 1

	ini_RemoveLineFeeds := ini_RemoveLineFeeds = 0 ? 0 : 1

	if !ini_KeepSession
		clearData()

	ini_IsImageStored := ini_IsImageStored = 0 ? 0 : 1
	ini_DaysToStore := ini_DaysToStore < 0 ? 0 : (ini_DaysToStore > 200 ? 200 : ini_DaysToStore)	;A max 200 days is allowed.
}