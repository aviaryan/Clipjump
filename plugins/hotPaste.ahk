;@Plugin-Name Hotstring-Paste
;@Plugin-Description Edit this plugin file to add hotstrings (like hotkeys) that will paste the desired clip when you write a particular text.
;@Plugin-Description Makes badass use of the awesome hotstrings feature in AutoHotkey
;@Plugin-Author AutoHotkey, Avi
;@Plugin-Tags instant pasting

plugin_hotPaste(){
	MsgBox, 64, Hello, % "Please edit the plugins\hotPaste.ahk file to meet your needs. The Comments in the file will guide you through.`n"
	 . "A Gui will be added to this plugin in the future versions."
}


;/////////////////////     PLUGIN STARTS    //////////////////////////////////////////

IfWinNotActive, a_window_dat_never_exists
{
;////////////////////   HOTRSTRINGS AREA  ///////////////////////////////////

/*
;writing 'cjsite' followed by a space or enter or fullstop(.) expands the action to API.paste(2, 1)

::cjsite::
	API.Paste(2,1) 		; Clip 1 of channel 2 has http://clipjump.sourceforge.net [FIXED] via the Fixate feature.
	return
*/

;WRITE MORE HOTRSINGS BELOW (and don't forget to restart)




}