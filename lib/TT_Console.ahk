/*
TT_Console() v0.01
	Use Tooltip as a User Interface

By:
	Avi Aryan
*/

TT_Console( msg, keys, x="", y="", whichtooltip=1, font_options="", font_face="" ) {

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
	{
		;WinWait ahk_class tooltips_class32
		;win := WinExist()
		gosub TT_Console_SetFont
	}

	;create hotkeys
	loop, parse, keys, %A_space%, %a_space%
		Hotkey, % A_LoopField, TT_Console_Check, On

	while !is_TTkey_pressed
		sleep 20

	ToolTip,,,, % whichtooltip

	loop, parse, keys, %A_space%, %a_space%
		Hotkey, % A_LoopField, TT_Console_Check, Off

	return what_pressed


TT_Console_Check:
	what_pressed := A_ThisHotkey
	is_TTkey_pressed := 1
	return

TT_Console_CreateFont:
	Gui, TTfont:Font, %font_options%, %font_face%
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