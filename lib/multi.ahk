;--------------------- CHANNELS FOR CLIPJUMP --------------------------
;== IDEAS ==
;	TEMPSAVE, CURSAVE
;		TOTALCLIPS
;
;	Folders to be specified by N ("", 1, 2, 3)
;	CN.TotalClips = unlimited for other modes (1, 2, 3, 4, 5, 6) and as specified in Ini for 0 channel
;	CN.Name = name of channel
;	CN.N = contains Folder names amendment of the active Channel
;	CN.NG = contains real channel indexes 0,1,2
;	CN.Total = Total number of channels
; 	CN.pit_NG = contains item active before the Pit swap
;   
;   out of these CN.Total and TEMPSAVE,CURSAVE are only permananent var, all others are temporarily created at channel change.
;----------------------------------------------------------------------

channelGUI(destroygui=0){
	global
	static local_ini_IsChannelMin, advice3wt, advice1wt, advicewidth, cancelwt, deletewt

	if (destroygui) {
		local_ini_IsChannelMin := ""
		return
	}

	advice3wt := getControlInfo("text", TXT.CNL_advice3, "w", "s8", "Lucida Console")
	advice1wt := getControlInfo("text", TXT.CNL_advice1, "w", "s8", "Lucida Console")
	deletewt := getControlInfo("button", TXT.CNL_delete, "w", "s10", "Arial")
	cancelwt := getControlInfo("button", TXT.CNL_cancel, "w", "s10", "Arial")

	advicewidth := advice3wt >= advice1wt ? advice3wt : advice1wt
	advicewidth := advicewidth<450 ? 400 : advicewidth
	try Gui, Channel:Default 			; just incase no gui exists

	If ( ini_IsChannelMin != local_ini_IsChannelMin )
	{
			Gui, Channel:New  ;Total width ~ 549
			Gui, Font, S12
			Gui, Add, Text, x4 y6, % TXT.CNL_choose

			Gui, Font, S10
			Gui, Add, Edit, % "x" advicewidth-150-4 " w150 section yp-2 +Readonly vcIndex"
			Gui, Add, Updown,% "Wrap Range0-" CN.Total " gChannelupdown vChannelupdown", 0

			Gui, Font, S12
			Gui, Add, Text, x4 y+10, % TXT.CNL_channelname
			Gui, Font, S10
			Gui, Add, Edit, xs yp-2 w150 vcname -Multi gedit_cname, % CN.Name

		if !ini_IsChannelMin
		{
			Gui, Font, S8, Lucida Console
			Gui, Add, Text, x4 y+25 section vtxt_cnladvice, % TXT.CNL_advice1
			Gui, Add, Text, y+5, % TXT.CNL_advice2
			Gui, Add, Text, y+5, % TXT.CNL_advice3
			; see top for the width calculation
			Gui, Font, S10, Arial
			Gui, Add, Button, x4 y+25 gchannel_Usebutton Default, % TXT.CNL_use
			; see top for widths
			Gui, Add, Button, % "x" advicewidth -4 -deletewt -cancelwt " yp+0 gchannel_deleteButton", % TXT.CNL_delete
			Gui, Add, Button, % "x" advicewidth -cancelwt " yp+0 gchannel_Cancelbutton", % TXT.CNL_cancel
			Gui, Add, StatusBar

			Hotkey, Enter, Channel_usebutton, Off
		}
		else
		{
			Gui, Add, StatusBar

			Hotkey, IfWinActive, % PROGNAME " " TXT.CNL__name
			Hotkey, Enter, Channel_usebutton, On
			Hotkey, Del, Channel_deletebutton, On
			Hotkey, IfWinActive
		}

		local_ini_IsChannelMin := ini_IsChannelMin
	}

	CN["TEMPSAVE" CN.N] := TEMPSAVE , CN["CURSAVE" CN.N] := CURSAVE

	Gui, Channel:Default
	GuiControl,, cIndex, % CN.NG
	GuiControl,, cName , % CN.Name
	Gui, Show, , % PROGNAME " " TXT.CNL__name

	SB_SetText(TXT.CNL_statusbar " - " CN["CURSAVE" CN.N])
	return

edit_cname:
	Gui, Channel:submit, nohide
	ini_write("Channels", cIndex, cName, 0)
	return

Channel_usebutton:
	Gui, Channel:Submit, nohide
	changeChannel(cIndex) , CN.pit_NG := ""
	if ( cIndex == CN.Total-1 )  			; -1 as CN.tOTAL is already updated in changeChannel()
		local_ini_IsChannelMin := "x" 		;force re-building Gui

	ToolTip % "Channel " CN.Name " active"
	setTimer, TooltipOff, 500
Channel_cancelbutton:
	Gui, Channel:hide
	GuiControl, , cIndex, % CN.NG
	GuiControl, , cName,  % CN.Name
	return

;delete routine
Channel_deletebutton:
	Gui, Channel:submit, nohide
	if !cIndex
		MsgBox, 48, Clipjump Channels, % TXT.CNL_del_default
	else
	{
		MsgBox, 52, % "Clipjump Channel : " cname , % TXT.CNL_delmsg
		IfMsgBox, Yes
		{
			manageChannel(cIndex)
			GuiControl, channel: , cIndex, % cIndex-1
			gosub ChannelUpdown
		}
	}
	return

channelGUIClose:
channelGUIEscape:
	Gui, Channel:Hide
	return

}

ChannelUpdown:
	Gui, Channel:Submit, nohide
	Gui, Channel:Default
	SB_SetText(TXT.CNL_statusbar " - " CN["CURSAVE" (!cIndex?"":cIndex)])
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

	Iniread, temp, %CONFIGURATION_FILE%, channels, %cIndex%, %A_space%
	CN.Name := (temp=="") or (temp==A_temp) ? (!cIndex ? "Default" : cIndex) : temp

	if !cIndex
		TOTALCLIPS := CN["TOTALCLIPS"]
		, cIndex := ""
	else
		TOTALCLIPS := 999999999999

	CN["TEMPSAVE" CN.N] := TEMPSAVE , CN["CURSAVE" CN.N] := CURSAVE		;Saving Old
	CN.N := cIndex , CN.NG := !CN.N?0:CN.N 				;note that cIndex has been emptied if 0

	TEMPSAVE := CN["TEMPSAVE" cIndex] + 0 , CURSAVE := CN["CURSAVE" cIndex] + 0		;Restoring current

	T := Substr(CLIPS_dir, 0)
	if T is Integer
		FIXATE_dir := Substr(FIXATE_dir, 1, -1) , CLIPS_dir := Substr(CLIPS_dir, 1, -1) , THUMBS_dir := Substr(THUMBS_dir, 1, -1)

	FIXATE_dir .= cIndex , CLIPS_dir .= cIndex , THUMBS_dir .= cIndex

	FileCreateDir, %CLIPS_dir%
	FileCreateDir, %FIXATE_dir%
	FileCreateDir, %THUMBS_dir%

	LASTCLIP := LASTFORMAT := IScurCBACTIVE := "" 								;make all false as they are different for other channels
	CopyMessage := !ini_IsMessage ? "" : MSG_TRANSFER_COMPLETE " {" CN.Name "}"

	Menu, Tray, Tip, % PROGNAME " {" CN.Name "}"
}

;--------------------------- Pit ------------------------------------------------------------------

channel_Pitindex(){
	Iniread, o, %CONFIGURATION_FILE%, Channels
	loop, parse, o, `n, `r
	{
		if Substr(A_LoopField, -3) = "=pit"
		{
			N := Substr(A_LoopField, 1, -4)
			break
		}
	}
	return N
}

;--------------------------- Other functions ------------------------------------------------------

; moves a channel or deletes it; in moving dest channel if exists is deleted
manageChannel(orig, new=""){
	static l := "clips fixate thumbs"
	global CN

	if new=
	{
		loop, parse, l, % A_space
			FileRemoveDir, % "cache\" A_LoopField orig, 1
		try Inidelete,% CONFIGURATION_FILE, Channels, % orig 
		; move channels on step back
		loop % CN.Total-orig-1
		{
			c := A_index
			loop, parse, l, % A_space
				FileMoveDir, % "cache\" A_LoopField orig+c , % "cache\" A_LoopFileName orig+c-1, R
			ini_write("Channels", orig+c-1, (z:=Ini_read("Channels", orig+c)) ? z : orig+c-1, 0 )
			CN["CURSAVE" orig+c-1] := CN["CURSAVE" orig+c]
			CN["TEMPSAVE" orig+c-1] := CN["TEMPSAVE" orig+c]
		}
		;done ... final steps
		if !c 						;if the channel was last-loop not run
			CN["CURSAVE" orig] := CN["TEMPSAVE" orig] := ""

		CN.Total -= 1
		Gui, Channel:Default
		GuiControl, % "+Range0-" CN.Total, ChannelUpdown
		if CN.NG == orig
			TEMPSAVE := "" , CURSAVE := "" 		; if delted chnl was active , it is dead now
			, changeChannel(orig-1)
	}
	else
	{
		;NOT IMPLEMENTED YET
		loop, parse, l, % A_space
			FileRemoveDir, % "cache\" A_LoopField new, 1
		loop, parse, l, % A_Space
			FileMoveDir, % "cache\" A_loopfield orig, % "cache\" A_loopfield new, R
		ini_write("Channels", new, (z:=Ini_read("Channels", orig)) ? z : new, 0 )
		; final steps
		if CN.NG == orig
			changeChannel(new)
	}
}

;-------------------------- ACCESSIBILTY SHORTCUTS ------------------------------------------------

#if IsActive(PROGNAME " " TXT.CNL__name, "window")
	Up::
		GuiControl, channel:, ChannelUpdown, +1
		gosub, ChannelUpdown
		return
	Down::
		GuiControl, channel:, ChannelUpdown, +-1
		gosub, ChannelUpdown
		return
#if