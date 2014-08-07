;@Plugin-Name Hotstring-Paste
;@Plugin-Version 0.26
;@Plugin-Description Edit the file "plugins\hotPaste.lib\base.ahk" to add hotstrings (like hotkeys) that will paste the desired clip when you write a particular text.
;@Plugin-Description Run this plugin once from here to have the 'base.ahk' file created.
;@Plugin-Author AutoHotkey, Avi
;@Plugin-Tags instant pasting

#Hotstring EndChars `n `t

plugin_hotPaste(){
	FileCreateDir, plugins\hotPaste.lib

test := "
(
; writing 'cj_site' followed by a space/Enter/Tab will PASTE the site URL
::cj_site::
	API.PasteText(""http://clipjump.sourceforge.net"")
	return

::1stClip::
	API.Paste(0,1)		; write '1stClip' to paste clip 1 of channel 0.
	return

::3clip:: 				
	API.Paste(CN.NG, 3)    ; CN.NG has the current active channel number, this pastes 3rd clip of active channel
	return

; EDIT THIS FILE TO ADD MORE AND RESTART TO HAVE THEM LOADED
)"

	if !FileExist( zPath := "plugins\hotPaste.lib\base.ahk" )
		FileAppend, % test, % zPath

	MsgBox, 64, Hello, % "Please edit the plugins\hotPaste.lib\base.ahk file to meet your needs. See the documentation of HotPaste in help file for more info."
	; . "A Gui will be added to this plugin in the future versions."
	Run % ini_defEditor " """ "plugins\hotPaste.lib\base.ahk"""
}


;/////////////////////     PLUGIN STARTS    //////////////////////////////////////////

IfWinNotActive, a_window_dat_never_exists
{
;////////////////////   HOTRSTRINGS AREA  ///////////////////////////////////


#Include *i %A_ScriptDir%\plugins\hotPaste.lib\base.ahk


; //////////////////// END OF HOTSTRINGS AREA //////////////////////////////
}