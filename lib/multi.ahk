;--------------------- CHANNELS FOR CLIPJUMP --------------------------
;== IDEAS ==
;	TEMPSAVE, CURSAVE
;		TOTALCLIPS
;	Folders to be specified by N
;	TotalClips = unlimited for other modes (1, 2, 3, 4, 5, 6)
;----------------------------------------------------------------------

channelGUI(){
	global
	static local_ini_IsChannelMin

	If ( ini_IsChannelMin != local_ini_IsChannelMin )
	{
		if !ini_IsChannelMin
		{
			Gui, Channel:New
			Gui, Font, S12
			Gui, Add, Text, x4 y6 , &Choose Multi-Clipboard Channel
			Gui, Font, S10
			Gui, Add, Edit, x+165 yp-2 +Readonly vcIndex
			Gui, Add, Updown,% "Wrap Range0-" CN.Total " gChannelupdown", 0
		
			Gui, Font, S8, Lucida Console
			Gui, Add, Text, x4 y+30, Channel number 0 is the mainstream channel and should be used normally.
			Gui, Add, Text, y+5 cGray, Consider using as less channels as possible.`nThis is just a suggestion.
		
			Gui, Font, S10, Arial
			Gui, Add, Button, x4 y+30 w90 gchannel_Usebutton, &Use Channel
			Gui, Add, Button, x+385 yp+0 w70 gchannel_Cancelbutton, Cance&l
			Gui, Add, StatusBar

			Hotkey, Enter, Channel_usebutton, Off
		}
		else
		{
			Gui, Channel:New
			Gui, Font, S12
			Gui, Add, Text, x4 y6 , Choose Multi-Clipboard Channel
			Gui, Font, S10
			Gui, Add, Edit, x+165 yp-2 +Readonly vcIndex
			Gui, Add, Updown,% "Wrap Range0-" CN.Total " gChannelupdown", 0

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

	SB_SetText("Clips in the Channel : " CN["CURSAVE" CN.N])
	return


Channel_usebutton:
	Gui, Channel:Submit, hide
	changeChannel(cIndex)
	ToolTip % "Channel " CN.NG " active"
	setTimer, TooltipOff, 500
Channel_cancelbutton:
	Gui, Channel:Hide
	GuiControl, , cIndex, % CN.NG
	return

ChannelUpdown:
	Gui, Channel:Submit, nohide
	Gui, Channel:Default
	SB_SetText("Clips in the Channel : " CN["CURSAVE" (!cIndex?"":cIndex)])
	return

channelGUIClose:
channelGUIEscape:
	Gui, Channel:Hide
	return

}

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
	CN["N"] := "" , CN.NG := !CN.N?0:CN.N 		;which channel is active
	CN["TOTALCLIPS"] := TOTALCLIPS
}


changeChannel(cIndex){
	global

	if ( CN["TEMPSAVE" (cIndex-1)?cIndex-1:""] == "" )
		CN.Total+=1

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
	copyMessage := MSG_TRANSFER_COMPLETE " {" CN.NG "}"
	Menu, Tray, Tip, % PROGNAME " {" CN.NG "}"
	
}