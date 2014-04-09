/*

This function file helps any AHK script to use Clipjump API functions from its side. 
Just include this file in your script and use the Clipjump Class methods.
It requires the ClipjumpConmmunicator.ahk function file.

Note that API.text2binary() is not supported currently

- 31/3/2014

*/

;Clipjump.Call("IncognitoMode", 1)
;Clipjump.call("pasteText", "some text")
;msgbox % Clipjump.call("getClipLoc", 1, 5)
;Clipjump.call("Paste","","")
;return

#include %A_ScriptDir%/ClipjumpCommunicator.ahk


class Clipjump
{
	static k := "API:"
	static cbF := A_temp "\cjcb.txt"
	static rFuncs := "|getClipAt|getClipLoc|"

	; calls an API function present in API.ahk
	; Almost all of API needs can be fulfilled by this master function 
	; eg > 		Clipjump.call("pasteText", "Some_text 2 paste")
	; 			Clipjump.call("paste", 2, 2)
	;			Clipjump.call("emptyChannel", 2)
	;			Clipjump.call("incognitoMode", 1)

	call(funcName, parameters*){
		for key,val in parameters
			ps .= "`n" val
		FileDelete, % this.cbF
		k := CjControl(this.k funcName ps)
		if k && Instr(this.rFuncs, "|" funcName "|")
		{
			this._wait4file()
			Fileread, out, % this.cbF
			FileDelete, % this.cbF
			return out
		}
		else return ""
	}

	; get Clip At channel and clipno .
 	; toreturn = 1 returns clipboard text , =2 returns clipboardall data
	; Use this function and not Call("getClipAt", ....) for calling getClipAt() as Call() will not work for ClipboardAll data
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


	;------------------------------------------- END -----------------------------------------
	;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

	; Reserved functions used by the class
	_wait4file(){
		while !FileExist(this.cbF)
			sleep 15
	}
}