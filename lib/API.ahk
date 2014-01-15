; Plugin API for Clipjump

Act_API(D, k){
	static cbF := A_temp "\cjcb.txt"
	static rFuncs := "|getClipAt|getClipLoc|"

	fname := Substr(  D, l := Strlen(k)+1, ( Instr(D, "`n")?Instr(D, "`n"):Strlen(D)+1 ) -l  )
	p := Substr( D, Instr(D, "`n") ? Instr(D, "`n")+1 : 200 )
	ps := {}
	loop, parse, p, `n
		ps.Insert(A_LoopField)
	n := ps.MaxIndex()

	if !n
		r := API[fname]()
	if n=1
		r := API[fname](ps.1)
	else if n=2
		r := API[fname](ps.1, ps.2)
	else if n=3
		r := API[fname](ps.1, ps.2, ps.3)
	else if n=4
		r := API[fname](ps.1, ps.2, ps.3, ps.4)

	if Instr(rFuncs, "|" fname "|")
		FileAppend, % r, % cbF
	return r
}


class API
{
	; pastes clips from certain postion in certain channel
	; if both are blank, paste 1st clip from currently active channel
	paste(channel="", clipno=""){
		this.blockMonitoring(1)
		if  (channel="") && (clipno="")
		{
			if !IsCurCBActive
				try FileRead, Clipboard, *c %A_ScriptDir%\%CLIPS_dir%\%TEMPSAVE%.avc
		}
		else {
			r := this.getClipLoc(channel, clipno)
			try Fileread, Clipboard, *c %r%
		}

		Send ^{vk56}
		this.blockMonitoring(0)
	}

	; get Clip content
	; toreturn = 1 < return Clipboard text data > 
	; toreturn = 2 < return ClipboardAll binary data >
	getClipAt(channel=0, clipno=1, toreturn=1, Byref err=""){
		this.blockMonitoring(1)
		r := this.getClipLoc(channel, clipno)
		try Fileread, Clipboard, *c %r%
		err := GetClipboardformat()="" ? 0 : 1
		if toreturn=1
			ret := Clipboard
		else
			ret := ClipboardAll
		this.blockMonitoring(0)
		return ret
	}

	manageClip(new_channel=0, channel="", clip="", flag=0) 	; 0 = cut , 1 = copy
	{
		; if channel is empty, active channel is used
		; if clip is empty, active clip in paste mode (Clip x of y, "x") is used.
		if channel=
			channel := CN.NG
		c_info := this.getChInfo(channel)
		if clip =
			clip := c_info.realTEMPSAVE
		else clip := c_info.realCURSAVE - clip + 1

		f := "cache\clips" c_info.p "\" clip ".avc"

		nc_info := this.getChInfo(new_channel)
		; process
		if flag
		{
			FileCopy, % f, % "cache\clips" nc_info.p "\" nc_info.realCURSAVE + 1 ".avc", 1
			CDS[new_channel][nc_info.realCURSAVE+1] := CDS[channel][clip]
		}
		else
		{
			Filemove, % f, % "cache\clips" nc_info.p "\" nc_info.realCURSAVE + 1 ".avc", 1
			CDS[new_channel][nc_info.realCURSAVE+1] := CDS[channel][clip] , CDS[channel][clip] := ""

			c_Folder1 := "cache\clips" c_info.p "\" , c_Folder2 := "cache\fixate" c_info.p "\" , c_Folder3 := "cache\thumbs" c_info.p "\"
			loop % c_info.realCURSAVE-clip
			{
				FileMove, % c_Folder1 clip+A_Index ".avc", % c_Folder1 clip+A_Index-1 ".avc", 1
				FileMove, % c_Folder2 clip+A_Index ".txt", % c_Folder2 clip+A_index-1 ".txt", 1
				FileMove, % c_Folder3 clip+A_Index ".jpg", % c_Folder3 clip+A_index-1 ".jpg", 1
				CDS[channel][clip+A_index-1] := CDS[channel][clip+A_index] , CDS[channel][clip+A_index] := ""
			}
		}
		; fix vars
		CN["CURSAVE" nc_info.p] += 1
		if nc_info.isactive
			CURSAVE += 1 	; also cursave if it is active

		if !flag
		{
			CN["CURSAVE" c_info.p] -= 1
			CN["TEMPSAVE" c_info.p] -= (CN["TEMPSAVE" c_info.p] > CN["CURSAVE" c_info.p]) ? 1 : 0 	; if the 29th file of 29 files was deleted and 29 was active
			if c_info.isactive
				CURSAVE -= 1 , TEMPSAVE -= (TEMPSAVE > CURSAVE) ? 1 : 0
		}
		return
	}

	; if channel no is empty, it DEFAULTS to current channel
	; you can also use name of a channel > like API.emptyChannel("web")
	emptyChannel(chno=""){
		if chno =
			chno := CN.NG
		if chno is not Integer
			chno := channel_find(chno)
		CDS[chno] := {}
		f := this.getChInfo(chno)
		FileDelete, % "cache\clips" f.p "\*.avc"
		FileDelete, % "cache\thumbs" f.p "\*.jpg"
		FileDelete, % "cache\fixate" f.p "\*.fxt"
		CN["CURSAVE" f.p] := CN["TEMPSAVE" f.p] := 0
		if f.isactive
			CURSAVE := TEMPSAVE := 0 , LASTCLIP := ""
	}

	; p=1 enable incognito mode
	IncognitoMode(p=1){
		NOINCOGNITO := p  		; make it the opp as incognito: will change the sign
		gosub incognito
	}

	; get Clips file location wrt Clipjump's directory
	getClipLoc(channel="", clipno=""){
		if channel=
			channel := CN.NG
		if clipno=
			clipno := 1
		p := !channel ? "" : channel
		z := (CN.NG==channel) ? CURSAVE : CN["CURSAVE" p] 		;chnl CURSAVE is not updated everytime but when channel is changed. 
		f := A_ScriptDir "\cache\clips" p "\" z-clipno+1 ".avc"
		return FileExist(f) ? f : ""
	}

	;blocks CB monitoring
	blockMonitoring(yes=1, sleeptime=10){
		Critical, Off 		; necessary to let onclipboard break process if needed
		if yes
		{
			CALLER := 0 , ONCLIPBOARD := ""
			while CALLER
				sleep % sleeptime
		} else {
			while !ONCLIPBOARD
			{
				sleep % sleeptime
				if (sleeptime*A_index) > 1000
					break
			}
			CALLER := CALLER_STATUS
		}
	}
	

	;---- API HELPER FUNCS --	
	getChInfo(c="", ret=1){
		; returns obj full of channel information data
		; ret=0 returns string
		if c=
			c := CN.NG
		o := {}
		if CN.NG == c
			o.isactive := 1
		o.p := p := !c ? "" : c
		o.realCURSAVE := o.isactive ? CURSAVE : CN["CURSAVE" p] , o.channelCURSAVE := CN["CURSAVE" p]
		o.realTEMPSAVE := o.isactive ? TEMPSAVE : CN["TEMPSAVE" p] , o.channelTEMPSAVE := CN["TEMPSAVE" p]
		if ret
			return o
		; make string
		for k,v in o
			str .= k "`t" v "`n"
		return str
	}
}