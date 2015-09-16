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


TT_Console(msg, keys, title="", x="", y="", fontops="", followMouse=0) {

	ttobj := TT("", msg, title)
	if (fontops=="")
		fontops := "Arial,s9"
	ttobj.Font(fontops)

	;show tooltip
	ttobj.Show(msg, x, y)

	;create hotkeys
	loop, parse, keys, %A_space%, %a_space%
		hkZ(A_LoopField, "TT_Console_Check", 1)

	is_TTkey_pressed := 0
	while !is_TTkey_pressed
	{
		if followMouse
		{
			ttobj.Show()
			sleep 200
		}
		else sleep 20
	}

	ToolTip,,,, % whichtooltip
	ttobj.Hide()
	ttobj := ""
	; msgbox % "Report this to dev : " what_pressed

	loop, parse, keys, %A_space%, %a_space%
		hkZ(A_LoopField, "TT_Console_Check", 0)

	return what_pressed


TT_Console_Check:
	what_pressed := A_ThisHotkey
	is_TTkey_pressed := 1
	return
}