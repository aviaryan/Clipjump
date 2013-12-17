; Clipjump API functions to be included and used in 3rd party scripts
; Uses the ClipjumpConmmunicator function

;msgbox % Clipjump.IncognitoMode(1)
;return

#include %A_ScriptDir%/ClipjumpCommunicator.ahk

class Clipjump
{
	static k := "API:"
	static cbF := A_temp "\cjcb.txt"

	; pastes clip at channel and clipno
	paste(channel="", clipno=""){
		return CjControl(this.k "paste`n" channel "`n" clipno)
	}

	; get Clip At channel and clipno .
	; toreturn = 1 returns clipboard text , =2 returns clipboardall data
	getClipAt(channel=0, clipno=1, toreturn=1){
		k := CjControl(this.k "getClipAt`n" channel "`n" clipno "`n" toreturn)
		if k
		{
			this._wait4file()
			if toreturn=1
				Fileread, out, % this.cbF
			else
			{
				CjControl(2) 		; disable monitoring
				oldclip := ClipboardAll
				Clipboard := ""
				Fileread, Clipboard, % "*c " this.cbF
				ClipWait, , 1
				out := ClipboardAll
				Clipboard := oldclip
				CjControl(1)   		; enable
			}
			FileDelete, % this.cbF
			return out
		}
		else return ""
	}

	; p=1 turns on Incongito mode
	IncognitoMode(p=1){
		return CjControl(this.k "IncognitoMode`n" p)
	}

	; get Clip's location in clipjump's cache dir
	getCliploc(channel=0, clipno=1){
		k := CjControl(this.k "getCliploc`n" channel "`n" clipno)
		if k
		{
			this._wait4file()
			FileRead, out, % this.cbF
			FileDelete, % this.cbF
			return out
		}
		else return 0
	}


	; Reserved functions used by the class
	_wait4file(){
		while !FileExist(this.cbF)
			sleep 15
	}
}