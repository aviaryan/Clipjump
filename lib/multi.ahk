;--------------------- CHANNELS FOR CLIPJUMP --------------------------
;== IDEAS ==
;	TEMPSAVE, CURSAVE
;		TOTALCLIPS
;	Folders to be specified by N ("", 1, 2, 3)
;	TotalClips = unlimited for other modes (1, 2, 3, 4, 5, 6)
;
;	CN.N contains Folder names amendment of the active Channel
;----------------------------------------------------------------------

channelGUI(){
	global
	static local_ini_IsChannelMin

	If ( ini_IsChannelMin != local_ini_IsChannelMin )
	{
			Gui, Channel:New  ;Total width ~ 549
			Gui, Font, S12
			Gui, Add, Text, x4 y6 w235, &Choose Multi-Clipboard Channel
			Gui, Font, S10
			Gui, Add, Edit, x+165 yp-2 +Readonly vcIndex
			Gui, Add, Updown,% "Wrap Range0-" CN.Total " gChannelupdown vChannelupdown", 0

			Gui, Font, S12
			Gui, Add, Text, x4 y+10 w235, Channel &Name
			Gui, Font, S10
			Gui, Add, Edit, x+165 yp-2 w150 vcname gedit_cname, % CN.Name

		if !ini_IsChannelMin
		{
			Gui, Font, S8, Lucida Console
			Gui, Add, Text, x4 y+25, Channel 0 (Default) is the mainstream channel and should be used normally.
			Gui, Add, Text, y+5, Channel Name changes are saved automatically

			Gui, Font, S10, Arial
			Gui, Add, Button, x4 y+25 w90 gchannel_Usebutton, &Use Channel
			Gui, Add, Button, x+385 yp+0 w70 gchannel_Cancelbutton, Cance&l
			Gui, Add, StatusBar

			Hotkey, Enter, Channel_usebutton, Off
		}
		else
		{
			Gui, Add, StatusBar

			Hotkey, IfWinActive, %PROGNAME% Channels
			Hotkey, Enter, Channel_usebutton, On
			Hotkey, IfWinActive
		}

		local_ini_IsChannelMin := ini_IsChannelMin
	}

	CN["TEMPSAVE" CN.N] := TEMPSAVE , CN["CURSAVE" CN.N] := CURSAVE

	Gui, Channel:Default
	GuiControl,, cIndex, % CN.NG
	Gui, Show, , Clipjump Channels

	SB_SetText("Clips in the Channel :" CN["CURSAVE" CN.N])
	return

edit_cname:
	Gui, Channel:submit, nohide
	ini_write("Channels", cIndex, cName, 0)
	return

Channel_usebutton:
	Gui, Channel:Submit, nohide
	changeChannel(cIndex)
	ToolTip % "Channel " CN.Name " active"
	setTimer, TooltipOff, 500
Channel_cancelbutton:
	Gui, Channel:hide
	GuiControl, , cIndex, % CN.NG
	return

channelGUIClose:
channelGUIEscape:
	Gui, Channel:Hide
	return

}

ChannelUpdown:
	Gui, Channel:Submit, nohide
	Gui, Channel:Default
	SB_SetText("Clips in the Channel :" CN["CURSAVE" (!cIndex?"":cIndex)])
	Iniread, cname, %CONFIGURATION_FILE%, channels,% cIndex, %A_space%
	GuiControl,, cname, % (cname=="") ? cIndex : cname
	return

initChannels(){
	global
	loop,
		if FileExist("cache\clips" (T := (A_index-1)?A_index-1:"" ) )
		{
			loop
			{
				IfNotExist, cache/Clips%T%/%A_Index%.avc
				{
					CN["TEMPSAVE" T] := CN["CURSAVE" T] := A_Index - 1
					break
				}
			}
			CN["Total"] := A_index
		}
		Else
			break
	CN.NG := 0 

	Iniread, temp, %CONFIGURATION_FILE%, channels, % CN.NG, %A_space%
	CN.Name := (temp=="") or (temp==A_temp) ? "Default" : temp
	ini_write("channels", "0", "Default")

	CN["TOTALCLIPS"] := TOTALCLIPS
}


changeChannel(cIndex){
	global

	if ( CN["TEMPSAVE" (cIndex?cIndex:"")] == "" )
		CN.Total+=1

	Iniread, temp, %CONFIGURATION_FILE%, channels, % cIndex, %A_space%
	CN.Name := (temp=="") ? (!cIndex ? "Default" : cIndex) : temp

	if !cIndex
		TOTALCLIPS := CN["TOTALCLIPS"]
		, cIndex := ""
	else
		TOTALCLIPS := 999999999999

	CN["TEMPSAVE" CN.N] := TEMPSAVE , CN["CURSAVE" CN.N] := CURSAVE		;Saving Old
	CN.N := cIndex , CN.NG := !CN.N?0:CN.N

	TEMPSAVE := CN["TEMPSAVE" cIndex] , CURSAVE := CN["CURSAVE" cIndex] 	;Restoring current

	T := Substr(CLIPS_dir, 0)
	if T is Integer
		FIXATE_dir := Substr(FIXATE_dir, 1, -1) , CLIPS_dir := Substr(CLIPS_dir, 1, -1) , THUMBS_dir := Substr(THUMBS_dir, 1, -1)

	FIXATE_dir .= cIndex , CLIPS_dir .= cIndex , THUMBS_dir .= cIndex

	FileCreateDir, %CLIPS_dir%
	FileCreateDir, %FIXATE_dir%
	FileCreateDir, %THUMBS_dir%

	LASTCLIP := LASTFORMAT := ""
	copyMessage := MSG_TRANSFER_COMPLETE " {" CN.Name "}"
	Menu, Tray, Tip, % PROGNAME " {" CN.Name "}"
	
}

;-------------------------- ACCESSIBILTY SHORTCUTS ------------------------------------------------

#if IsActive("Clipjump Channels", "window")
	Up::
		GuiControl, channel:, ChannelUpdown, +1
		gosub, ChannelUpdown
		return
	Down::
		GuiControl, channel:, ChannelUpdown, +-1
		gosub, ChannelUpdown
		return
#if