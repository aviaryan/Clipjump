;@Plugin-Name Hotstring-Paste
;@Plugin-Version 0.2
;@Plugin-Description Edit this plugin file to add hotstrings (like hotkeys) that will paste the desired clip when you write a particular text.
;@Plugin-Description Makes badass use of the awesome hotstrings feature in AutoHotkey
;@Plugin-Author AutoHotkey, Avi
;@Plugin-Tags instant pasting

#Hotstring EndChars `n `t

plugin_hotPaste(){
	MsgBox, 64, Hello, % "Please edit the plugins\hotPaste.ahk file to meet your needs. The Comments in the file will guide you through.`n"
	 . "A Gui will be added to this plugin in the future versions."
}


;/////////////////////     PLUGIN STARTS    //////////////////////////////////////////

IfWinNotActive, a_window_dat_never_exists
{
;////////////////////   HOTRSTRINGS AREA  ///////////////////////////////////

/*
EXAMPLES (Commented, are not executed)

	; writing 'cj_site' followed by a space or enter or tab expands the action to API.paste(2, 1)
	::cj_site::
		API.Paste(2,1) 		; Clip 1 of channel 2 has http://clipjump.sourceforge.net [FIXED] via the Fixate feature.
		return
	
	::1stClip::
		API.Paste(1,1)		; write '1stClip' to paste clip 1 of channel 1.
		return
	
	::adres:: 				
		API.PasteText("Building 12, Toms Street, Sector 4, BigCity, ISA")    ; write 'adres' to paste the address given here
		return
*/

; NOT Commented (WORKS)
; write   'cj_site'   followed by space to see   'http://clipjump.sourceforge.net'   pasted

::cj_site::
	API.PasteText("http://clipjump.sourceforge.net")
	return

; WRITE MORE HOTSTRINGS BELOW (and don't forget to restart)










; //////////////////// END OF HOTSTRINGS AREA //////////////////////////////
}