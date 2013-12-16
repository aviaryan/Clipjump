; Plugin API for Clipjump

class API
{
	; pastes clips from certain postion in certain channel
	paste(channel="", clipno=""){
		this.blockMonitoring(1)

		if  (channel="") && (clipno="")
		{
			if !IsCurCBActive
				try FileRead, Clipboard, *c %A_ScriptDir%\%CLIPS_dir%\%TEMPSAVE%.avc
		}
		else {
			r := this.getClipLoc(channel, clipno)
			try Fileread, Clipboard, *c %A_ScriptDir%\%r%
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
		try Fileread, Clipboard, *c %A_ScriptDir%\%r%
		err := GetClipboardformat()="" ? 0 : 1
		if toreturn=1
			ret := Clipboard
		else ret := ClipboardAll
		this.blockMonitoring(0)
		return ret
	}

	; p=1 enable incognito mode
	IncognitoMode(p=1){
		NOINCOGNITO := p  		; make it the opp as incognito: will change the sign
		gosub incognito
	}

	; get Clips file location wrt Clipjump's directory
	getClipLoc(channel=0, clipno=1){
		if channel=
			channel := 0
		if clipno=
			clipno := 1

		p := !channel ? "" : channel
		z := (CN.NG==channel) ? CURSAVE : CN["CURSAVE" p] 		;chnl CURSAVE is not updated everytime but when channel is changed. 
		f := "cache\clips" p "\" z-clipno+1 ".avc"
		return FileExist(f) ? f : ""
	}

	;blocks CB monitoring
	blockMonitoring(yes=1){
		Critical, Off 		; necessary to let onclipboard break process if needed
		if yes
		{
			CALLER := 0 , ONCLIPBOARD := 0
			while CALLER
				sleep 10
		} else {
			while !ONCLIPBOARD
				sleep 20
			CALLER := CALLER_STATUS
		}
	}
	;resolvec
}