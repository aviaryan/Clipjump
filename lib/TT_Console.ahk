/*
TT_Console() v0.02
	Use Tooltip as a User Interface

By:
	Avi Aryan

Info:
	keys - stores space separated values of keys that are prompted for a user input
	font_options - Font options as in Gui ( eg -> s8 bold underline )
	font_face - Font face names. Separate them by a | to set prority

Returns >
	The key which has been pressed
*/


;EXAMPLE
;#Persistent
;a := TT_Console( "Hi`nPress Y to see another message.`nPress N to exit script", "y n", empty_var, empty_var, 1, "s12", "Arial|Consolas")
;if a = y
;{
;	c := TT_Console( "Press V to close me`nPress Esc to let me running", "v Esc")
;	if c = v
;		Exitapp
;}
;Else if a = n
;	Exitapp
;return


TT_Console(msg, keys, x="", y="", whichtooltip=1, font_options="", font_face="", followMouse=0) {

	;create font
	if (font_options) or (font_face)
	{
		createfont := 1
		gosub TT_Console_CreateFont
	}
	;create tooltip
	Tooltip, % msg, % x, % y, % whichtooltip
	;set font
	if createfont
		gosub TT_Console_SetFont

	;create hotkeys
	loop, parse, keys, %A_space%, %a_space%
		hkZ(A_LoopField, "TT_Console_Check", 1)
		;Hotkey, % A_LoopField, TT_Console_Check, On

	while !is_TTkey_pressed
	{
		if followMouse
		{
			Tooltip, % msg,,, % whichtooltip
			if createfont
				gosub TT_Console_SetFont
			sleep 200
		}
		else sleep 20
	}

	ToolTip,,,, % whichtooltip

	loop, parse, keys, %A_space%, %a_space%
		hkZ(A_LoopField, "TT_Console_Check", 0)
		;Hotkey, % A_LoopField, TT_Console_Check, Off

	return what_pressed


TT_Console_Check:
	what_pressed := A_ThisHotkey
	is_TTkey_pressed := 1
	return

TT_Console_CreateFont:
	loop, parse, font_face, |
		Gui, TTfont:Font, %font_options%, %A_LoopField%
	Gui, TTfont:Add, Text, hwnd_hwnd, `.
	SendMessage, 0x31, 0, 0,, ahk_id %_hwnd%
	Gui, TTfont: Destroy
	font := ErrorLevel
	return

TT_Console_SetFont:
	;SendMessage, 0x30, %font%, 1, %ctrl%, ahk_id%win% 
	SendMessage, 0x30, %font%, 1, %ctrl%, ahk_class tooltips_class32
	return
}