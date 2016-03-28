; Plugin API for Clipjump

/**
 * run a api function in the string given
 * @param {string} D string with the function call
 * @param {string} k api prefix, here 'api:'
 */
Act_API(D, k){
	static cbF := A_temp "\cjcb.txt"
	static rFuncs := "|getClipAt|getClipLoc|getVar|runFunction|getClipDataByTag"
	static resChar := "`r"

	fname := Substr(  D, l := Strlen(k)+1, ( Instr(D, resChar)?Instr(D, resChar):Strlen(D)+1 ) -l  )
	p := Trim(Substr( D, Instr(D, resChar) ? Instr(D, resChar)+1 : 2000000 ))
	ps := {}
	loop, parse, p, % resChar
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
	else if n=5
		r := API[fname](ps.1, ps.2, ps.3, ps.4, ps.5)

	if Instr(rFuncs, "|" fname "|")
		FileAppend, % r, % cbF
	return r
}


/**
 * API Class
 * includes all methods accessible through the api
 */
class API
{
	; pastes clips from certain postion in certain channel
	; if both are blank, paste 1st clip from currently active channel
	paste(channel="", clipno=""){
		this.blockMonitoring(1)
		if  (channel="") && (clipno="")
		{
			if !IsCurCBActive
				try FileRead, Clipboard, *c %A_WorkingDir%\%CLIPS_dir%\%TEMPSAVE%.avc
		}
		else {
			r := this.getClipLoc(channel, clipno)
			try_ClipboardFromFile(r, 10)
			;try Fileread, Clipboard, *c %r%
		}

		Send ^{vk56}
		this.blockMonitoring(0)
	}

	; get Clip content
	; toreturn = 1 < return Clipboard text data > 
	; toreturn = 2 < return ClipboardAll binary data >
	getClipAt(channel=0, clipno=1, toreturn=1, Byref err=""){
		if toreturn=1
			ret := CDS[channel][ this.getChStrength(channel)-clipno+1 ]
		else {
			this.blockMonitoring(1)
			r := this.getClipLoc(channel, clipno)
			try Fileread, Clipboard, *c %r%
			err := GetClipboardformat()="" ? 0 : 1
			ret := ClipboardAll
			this.blockMonitoring(0)
		}
		return ret
	}

	; 0 = cut , 1 = copy
	; if channel is empty, active channel is used
	; if clip is empty, active clip in paste mode (Clip x of y, "x") is used.
	manageClip(new_channel=0, channel="", clip="", flag=0){
		if channel=
			channel := CN.NG
		c_info := this.getChInfo(channel)
		if clip =
			clip := c_info.realTEMPSAVE
		else clip := c_info.realCURSAVE - clip + 1
		nc_info := this.getChInfo(new_channel)

		origClip := "cache\clips" c_info.p "\" clip ".avc" , origThumb := "cache\thumbs" c_info.p "\" clip ".jpg"
		newClip := "cache\clips" nc_info.p "\" nc_info.realCURSAVE + 1 ".avc"
		newThumb := "cache\thumbs" nc_info.p "\" nc_info.realCURSAVE + 1 ".jpg"

		; process
		if flag
		{
			FileTransfer(origClip, newClip) , FileTransfer(origThumb, newThumb)
			CDS[new_channel][nc_info.realCURSAVE+1] := CDS[channel][clip]
			CPS[new_channel][nc_info.realCURSAVE+1] := CPS[channel][clip]
			manageFIXATE( nc_info.realCURSAVE + 1, new_channel, nc_info.p)
		}
		else
		{
			FileTransfer(origClip, newClip, 0) , FileTransfer(origThumb, newThumb, 0)
			CPS[new_channel][nc_info.realCURSAVE+1] := CPS[channel][clip] , CPS[channel].remove(Clip) ; .remove() auto adjusts cavities in array
			CDS[new_channel][nc_info.realCURSAVE+1] := CDS[channel][clip] , CDS[channel].remove(Clip) 
			c_Folder1 := "cache\clips" c_info.p "\" , c_Folder2 := "cache\thumbs" c_info.p "\"
			loop % c_info.realCURSAVE-clip
			{
				FileMove, % c_Folder1 clip+A_Index ".avc", % c_Folder1 clip+A_Index-1 ".avc", 1
				FileMove, % c_Folder2 clip+A_Index ".jpg", % c_Folder2 clip+A_index-1 ".jpg", 1
			}

			if (new_channel == channel){
				ClipTransfer(c_info.p, nc_info.realCURSAVE+1, c_info.p, nc_info.realCURSAVE, 0)
				; no need for changing arr as .remove() handles it
				return
			}
			manageFIXATE( nc_info.realCURSAVE + 1, new_channel, nc_info.p )
			IsCurCBActive := 0
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
		CDS[chno] := {} , CPS[chno] := {}
		f := this.getChInfo(chno)
		FileDelete, % "cache\clips" f.p "\*.avc"
		FileDelete, % "cache\thumbs" f.p "\*.jpg"
		FileDelete, % "cache\clips" f.p "\prefs.ini"
		;FileDelete, % "cache\fixate" f.p "\*.fxt"
		CN["CURSAVE" f.p] := CN["TEMPSAVE" f.p] := 0
		if f.isactive
			CURSAVE := TEMPSAVE := 0 , LASTCLIP := ""
	}

	;runs a plugin
	; filename - filename of plugin with .ahk . Example > pformat.noformatting.ahk
	; parameters - if no parameter is passed, function itself obtains them.
	runPlugin(filename, parameters*){
		for k,v in PLUGINS["<>"]
		{
			if ( v["plugin_path"] == filename )
			{
				fpath := v["*"] , plugin_displayname := v["name"] , dirNum := v["#"] , Silent := v["silent"]
				break
			}
		}
		; run
		if FileExist(fpath) {
			if !parameters.maxIndex() && !Silent {
				loop 3
					If PLUGINS["<>"][dirNum].hasKey("param" A_index) {
						Inputbox, param, % "Plugin " plugin_displayname, % PLUGINS["<>"][dirNum]["param" A_index],, 500
						if ErrorLevel=0
							params .= " """ param """" 	;if OK
						else return
					}
					else break
			} else {
				for k,v in parameters
					params .= " """ v """"
			}

			try Run % A_AhkPath " """ A_WorkingDir "\" fpath """" params
			catch 
				MsgBox, 16, Error, % TXT.API_extPlugMiss . "`n" fpath
		}
		else {
			if !IsFunc(fpath)
			{
				MsgBox, 16, Error, % TXT.API_plugCorrupt "`n" plugin_displayname
				return
			}
			; else execture
			if !parameters.maxIndex() && !Silent {
				funcobj := Func(fpath) , funcps := ""
				loop % funcobj.maxParams
				{
					prompt := ""
					prompt := PLUGINS["<>"][dirNum]["param" A_index]
					if prompt=
						prompt := "#" A_index " " TXT.PLG_fetchparam
					InputBox, param, % "Plugin " plugin_displayname, % prompt,, 500
					if ErrorLevel=0
						funcps .= RegexReplace(param, ",", "ª") ","
					else return
				}
			} else {
				for k,v in parameters
					funcps .= Regexreplace(v, ",", "ª") ","
			}
			ret := runfunc(fpath "(" RTrim(funcps, ",") ")")
			return ret
		}
	}

	; shows paste mode tooltip with search at the passed channel and clip posn
	showPasteTipAt(ch, cl, x="", y=""){
		_tmpsv := TEMPSAVE , _cnl := CN.NG, _cursv := CURSAVE
		CN["CURSAVE" CN.N] := CURSAVE , CN["TEMPSAVE" CN.N] := TEMPSAVE 	; load all values in CN obj
		v := API.getChStrength(ch)-cl+1
		changeChannel(ch, 0)
		TEMPSAVE := v
		SPM.ACTIVE := 1
		SPM.X := x , SPM.Y := y
		gosub paste
		gosub searchpm
		SPM.TEMPSAVE := _tmpsv
		SPM.Channel := _cnl
	}

	; returns the contents of first element with tag
	getClipDataByTag(tag){
		robj := this.getClipByTag(tag)
		for k,v in robj
			return this.getClipAt(v[1], v[2])
	}

	; returns an array of clips which have the tag
	; RETURN
	; channel at index 0 and clip at 1
	; example - [ [0,1] , [0,2] ]
	getClipByTag(tag){
		robj := {}
		for k,v in CPS
		{
			mindex := this.getChStrength(k)
			for k2,item in v
				if Instr(" " Trim(item["Tags"]) " ", " " tag " ")
					robj.insert( [k, mindex-k2+1] )
		}
		return robj
	}

	; runs any other function like choosechannelgui() , changeChannel()
	runFunction(funcString){
		return runFunc(funcString)
	}

	; runs the Label
	runLabel(label){
		gosub % ( IsLabel(label) ? label : "emptylabel" )
	}

	; gets total no of clips in a channel
	getChStrength(channel){
		o := API.getChInfo(channel)
		return o.realCURSAVE
	}
	
	; deletes a clip
	deleteClip(channel, clip){
		Critical
		if (channel = "") or (clip = "")
			return 0
		zbkCh := CN.NG , zbkClip := TEMPSAVE	; create backup of current channel
		CN["CURSAVE" CN.N] := CURSAVE , CN["TEMPSAVE" CN.N] := TEMPSAVE
		changeChannel(channel)
		clearClip( API.getChStrength(channel) - clip + 1 )
		changeChannel(zbkCh)
		;if (channel != zbkCh)  ; this was bcuz when clip from channel that was already active was deleted, tempsave can get invalid
			TEMPSAVE := zbkClip
		return 1
	}

	; adds clip to a chanel
	; input = the string that is created as a new clip
	; isbinary = 1 - makes the function take 'input' as binary
	addClip(channel, byref input, isbinary := 0){
		cInfo := API.getChInfo(channel)
		if isbinary {
			ret := input
			input := this.Binary2Text(ret)
		}
		else
			API.Text2Binary(input, ret)
		FileAppend, %ret%, % "cache\clips" cInfo.p "\" cInfo.realCURSAVE+1 ".avc"
		CDS[channel][cInfo.realCURSAVE+1] := input
		manageFIXATE( cInfo.realCURSAVE + 1, channel, cInfo.p )
		CN["CURSAVE" cInfo.p] += 1
		if cInfo.isactive
			CURSAVE += 1 	; also cursave if it is active
	}

	; sets a variable
	setVar(var, value){
		global
		value := valueOf(value)
		if Instr(var,".")
		{
			loop, parse, var,`.
				$j%A_index% := Trim(A_LoopField) , $n := A_index-1
			if $n=1
				%$j1%[$j2] := value
			if $n=2
				%$j1%[$j2][$j3] := value
		}
		else %var% := value
	}

	;gets a variable value
	getVar(var){
		return valueOf("%" var "%")
	}

	; EXecute a section in the ClipjumpCustom.ini
	ExecuteSection(secName){
		customization_Run( CUSTOMS["_" secName] )
	}
	
	; p=1 enable incognito mode
	IncognitoMode(p=1){
		NOINCOGNITO := p  		; make it the opp as incognito: will change the sign
		gosub incognito
	}

	; get Clips file location
	getClipLoc(channel="", clipno=""){
		if channel=
			channel := CN.NG
		if clipno=
			clipno := 1
		p := !channel ? "" : channel
		z := (CN.NG==channel) ? CURSAVE : CN["CURSAVE" p] 		;chnl CURSAVE is not updated everytime but when channel is changed. 
		f := A_WorkingDir "\cache\clips" p "\" z-clipno+1 ".avc"
		return FileExist(f) ? f : ""
	}

	;disable Clipjump - status=1 means disable , status=-1 means toggle
	disable(status=1){
		status .= ""
		if (status == "-1")
			gosub disable_clipjump
		else if (status=="1" && CLIPJUMP_STATUS)
			gosub disable_clipjump
		else if (status=="0" && !CLIPJUMP_STATUS)
			gosub disable_clipjump
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
	
	;pastes the given text without copying it to clipjump
	pasteText(Text){
		this.blockMonitoring(1)
		try 
			oldclip := ClipboardAll
		Clipboard := Text
		this.blockMonitoring(0) , this.blockMonitoring(1) 	;2 times cb change, so reset onclipboard var
		sleep 100
		Send ^{vk56}
		sleep 100
		Clipboard := oldclip
		this.blockMonitoring(0)
	}

	;gets binary ClipboardAll data from simple text
	; Text = the string you want to convert to ClipboardAll
	; returnVar = byref variable to return ClipboardAll data
	Text2Binary(Text, byref returnVar){
		this.blockMonitoring(1)
		try {
			oldclip := ClipboardAll
			Clipboard := Text
			this.blockMonitoring(0) , this.blockMonitoring(1)
			returnVar := ClipboardAll
			Clipboard := oldclip
			Error := 0
		}
		catch 
			Error := 1
		this.blockMonitoring(0)
		return Error
	}

	;Tooltip for plugins
	showTip(Text, forTime=""){
		if forTime
			autoTooltip(Text, forTime, 7)
		else
			Tooltip, % Text,,, 7
		;tooltip_setfont("s9", "Courier")
	}

	; removes the above tip
	removeTip(){
		ToolTip,,,, 7
	}

	; get the text from a ClipboardAll binary
	Binary2Text(byref binary){
		this.blockMonitoring(1)
		try 
			Clipboard := binary
		out := trygetvar("Clipboard")
		this.blockMonitoring(0)
		return out
	}

	;------------------------
	;---- API HELPER FUNCS --	
	;------------------------


	; returns obj full of channel information data
	; ret=0 returns string
	getChInfo(c="", ret=1){
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