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

initChannels(){
	global
	CN := {}
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
			CN.Total := A_index
		}
		Else
			break
	CN.NG := 0 , CN.N := ""

	Iniread, temp, %CONFIGURATION_FILE%, channels, % CN.NG, %A_space%
	CN.Name := (temp=="") or (temp==A_temp) ? "Default" : temp
	ini_write("channels", "0", CN.Name)

	CN["TOTALCLIPS"] := TOTALCLIPS
}

changeChannel(cIndex, backup_old:=1){
; changes channel
; creates new channel if needed
	if cIndex is not Integer
		return 0
	if ( cIndex == CN.Total ) 	; new channel create
	{
		CN.Total+=1 , CDS[cIndex] := {} , CPS[cIndex] := {} 	; create storage objs
		CN["TEMPSAVE" cIndex] := CN["CURSAVE" cIndex] := 0
	} else if ( cIndex > CN.Total )
		return 0
	Iniread, temp, %CONFIGURATION_FILE%, channels, %cIndex%, %A_space%
	CN.Name := (temp=="") or (temp==A_temp) ? (!cIndex ? "Default" : cIndex) : temp

	if !cIndex
		TOTALCLIPS := CN["TOTALCLIPS"]
		, cIndex := ""
	else
		TOTALCLIPS := CN["TOTALCLIPS" cIndex] ? CN["TOTALCLIPS" cIndex] : 999999999999 			;if exist, use it

	if backup_old
		CN["TEMPSAVE" CN.N] := TEMPSAVE , CN["CURSAVE" CN.N] := CURSAVE	, CN.prevCh := CN.NG	;Saving Old - TEMPSAVE is auto-corrected at 
		;the end of paste mode and so no need to fix it.
	CN.N := cIndex , CN.NG := !CN.N?0:CN.N 				;note that cIndex has been emptied if 0

	TEMPSAVE := CN["TEMPSAVE" cIndex] + 0 , CURSAVE := CN["CURSAVE" cIndex] + 0		;Restoring current

	T := Substr(CLIPS_dir, 0)
	if T is Integer
		CLIPS_dir := Substr(CLIPS_dir, 1, -1) , THUMBS_dir := Substr(THUMBS_dir, 1, -1)

	CLIPS_dir .= cIndex , THUMBS_dir .= cIndex

	FileCreateDir, %CLIPS_dir%
	FileCreateDir, %THUMBS_dir%

	LASTCLIP := LASTFORMAT := IScurCBACTIVE := "" 								;make all false as they are different for other channels
	renameChannel(CN.NG, CN.Name)
	if WinExist(TXT.ORG__name " ahk_class AutoHotkeyGUI") 		; change channel in ORG
		gosub chorg_addchUseList
	EmptyMem()
	return 1
}

renameChannel(ch, nm){
	ini_write("Channels", ch, Trim(nm), 0)
	if ( CN.NG == ch )
	{
		CN.Name := nm
		CopyMessage := !ini_IsMessage ? "" : MSG_TRANSFER_COMPLETE " {" CN.Name "}"
		Menu, Tray, Tip, % PROGNAME " {" CN.Name "}"
	}
}

;--------------------------- select channel box --------------------------------------------------------------

choosechannelgui(guiname=""){
	static channel_list
	if guiname=
		guiname := TXT.CHC_name
	channel_list := ""
	Gui, choosech:New
	Gui, choosech: +ToolWindow -MaximizeBox
	Gui, Add, Text, x7 y7, % TXT.CNL_choose
	lst := channel_find()
	StringReplace, lst, lst, |, ``|, All
	StringReplace, lst, lst, `n, |, All
	Gui, Add, Listbox, x+20 vchannel_list h150, % lst
	Gui, Add, button, x7 y+10 gchoosechbuttonok Default, OK
	Gui, Add, button, x+10 yp gchoosechbuttoncancel, % TXT.SET_cancel
	Gui, Show,, % guiname
	WinWaitActive, % guiname
	WinWaitClose, % guiname
	channel_list := Trim( Substr(channel_list, 1, Instr(channel_list, "-")-1) )
	return is_notcancel ? "" : channel_list

chooseChButtonOK:
	Gui, choosech:submit, nohide
	if channel_list
		Gui, choosech:Destroy
	return

chooseChButtoncancel:
choosechGuiClose:
	is_notcancel := "-"
	Gui, choosech:Destroy
	return
}

;--------------------------- find a channel ------------------------------------------------------------------

channel_find(name=""){
	local str, rINI
	; returns list of channels if name is empty
	rINI := Ini2Obj(CONFIGURATION_FILE)
	name := Trim(name)

	if name is Number
		return name
	else if (name != "")
	{
		for k,v in rINI["Channels"]
			if v = %name%
				return k
	}
	else
		loop % CN.Total
			str .= A_index-1 " - " rINI["Channels"][A_index-1] "`n"
	return Rtrim( str, "`n" )
}

;--------------------------- Other functions ------------------------------------------------------

; moves a channel or deletes it; in moving dest channel if exists is deleted
manageChannel(orig, new=""){
	static l := "clips thumbs"
	;global CN

	if new=
	{
		if !orig
			return 	; dnt delete 0
		loop, parse, l, % A_space
			FileRemoveDir, % "cache\" A_LoopField orig, 1
		ini_delete("Channels", orig)
		CDS[orig] := {} , CPS[orig] := {}
		; move channels one step back
		c := 0
		loop % CN.Total-orig-1
		{
			c := A_index
			loop, parse, l, % A_space
				FileMoveDir, % "cache\" A_LoopField orig+c , % "cache\" A_LoopField orig+c-1, R
			CDS[orig+c-1] := CDS[orig+c] , CPS[orig+c-1] := CPS[orig+c]
			ini_write("Channels", orig+c-1, (z:=Ini_read("Channels", orig+c)) && (z != orig+c) ? z : orig+c-1, 0 )
		}
		;done ... final steps
		ini_delete("Channels", orig+c) , CDS[orig+c] := {} , CPS[orig+c] := {}			; delete any name to avoid confusion

		bk := CN.NG
		initChannels()
		if ( bk >= orig )
			changeChannel(bk-1, 0) 		; change the channel using proper methodology as initchannels() disturbs it
		else changeChannel(bk, 0)
		prefs2Ini()
	}
	else
	{
		;NOT IMPLEMENTED YET - implement CDS also
		;loop, parse, l, % A_space
		;	FileRemoveDir, % "cache\" A_LoopField new, 1
		;loop, parse, l, % A_Space
		;	FileMoveDir, % "cache\" A_loopfield orig, % "cache\" A_loopfield new, R
		;ini_write("Channels", new, (z:=Ini_read("Channels", orig)) ? z : new, 0 )
		;; final steps
		;if CN.NG == orig
		;	changeChannel(new)
	}
}

;-------------------------- ACCESSIBILTY SHORTCUTS ------------------------------------------------

; #if IsActive(PROGNAME " " TXT.CNL__name, "window")
; 	Up::
; 		GuiControl, channel:, ChannelUpdown, +1
; 		gosub, ChannelUpdown
; 		return
; 	Down::
; 		GuiControl, channel:, ChannelUpdown, +-1
; 		gosub, ChannelUpdown
; 		return
; #if