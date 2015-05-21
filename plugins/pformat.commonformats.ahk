;@Plugin-Name Common Formats
;@Plugin-Description Shows a gui to paste with a format from many types of predefined formats. Can be easily extended to include more formats. 
;@Plugin-Description For that edit the pformat.commonformats.lib/user.ahk file. This file if needed is created when you run this plugin for the first time. 
;@Plugin-Description Only works for Text ([Text] or [File/Folder]) type data.
;@Plugin-Author Avi
;@Plugin-Tags pformat
;@Plugin-version 0.61
;@Plugin-Previewable 0

;@Plugin-Param1 The Input Text

;------------------------------------------------------------- Paste Formats ------------------------------------

; ###### ADD USER paste formats in user.ahk file #####
#Include *i %A_ScriptDir%\plugins\pformat.commonformats.lib\user.ahk
; ####################################################


plugin_pformat_commonformats_None(zin){
	STORE["commonformats_None"] := "This returns the original clip rejecting any change made to the clip."
	return zin , STORE.ClipboardChanged := 0
}

plugin_pformat_commonformats_HTMLList(zin){
	return RegExReplace( Trim(zin, "`r`n "), "m`a)^", "<li>") , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_BBCodeList(zin){
	return RegExReplace( Trim(zin, "`r`n "), "m`a)^", "[*]") , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_TrimFormatting(zin){
	return RTrim(zin, "`r`n") , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_NumberedList(zin){
	zin := Trim(zin, "`r`n ")
	loop, parse, zin, `n, `r
		zout .= A_index ". " A_LoopField "`r`n"
	return zout , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_lowercase(zin){
	StringLower, zout, zin
	return zout , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_TrimWhiteSpace(zin){
	STORE["commonformats_TrimWhiteSpace"] := "Trims white space from the beginning and end of string"
	return Trim(zin, "`r`n `t") , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_DeHTML(zin){
	STORE["commonformats_DeHTML"] := "Deactivates HTML code. All ("" & < >) are translated to (&quot; &amp; &lt; &gt;) and linefeed \n to <br>."
	Transform, o, HTML, % zin
	return plugin_pformat_commonformats_TrimWhiteSpace(o)
}

plugin_pformat_commonformats_UPPERCASE(zin){
	StringUpper, zout, zin
	return zout , STORE.ClipboardChanged := 1
}

#Include *i %A_ScriptDir%\plugins\pformat.commonformats.lib\unhtml.ahk
plugin_pformat_commonformats_UnHTML(zin){
	STORE["commonformats_unhtml"] := "Converts HTML code to Plain Text. Removes tags from HTML code and converts unicode sequences to characters."
	StringReplace, zin, zin, % "<br>", % "`n", All
	return Trim(unhtml(zin), "`n`r`t ") , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_RegexReplace(zin, zps){
	STORE["commonformats_RegexReplace"] := "Write Search Needle in first line and replacement string in second line in Input Field. The Replace is based on Autohotkey's"
	 . " RegexReplace(). Learn more at http://www.autohotkey.com/docs/commands/RegExReplace.htm"

	loop, parse, zps, `n, `r
		zps%A_index% := A_LoopField
	try 
		zout := RegExReplace(zin, zps1, zps2)
	catch 
		zout := zin
	return zout , STORE.ClipboardChanged := 1
}


;--------------------------------- The Plugin File Starts , end of Paste Formats ---------------------------------
;-----------------------------------------------------------------------------------------------------------------


plugin_pformat_commonformats(zin){
	static zchosenformat, zedit, zinputfield, zinfo
	zDone := zOut := ""

	Gui, commonformat:New
	Gui, +AlwaysOnTop +ToolWindow -MaximizeBox

	Gui, Add, ListBox, x5 y5 r15 w140 vzchosenformat gzchosenformat section, % plugin_pformat_commonformats_listfunc(A_ScriptDir "\plugins\pformat.commonformats.ahk")
	. ( (ztemp := plugin_pformat_commonformats_listfunc(ztF := A_ScriptDir "\plugins\pformat.commonformats.lib\user.ahk")) ? "|" ztemp : "" )

	Gui, Add, Edit, x+10 w500 h200 vzedit +multi, % zin

	Gui, Add, GroupBox, xs y+5 h70 w650, Info
	Gui, Add, Edit, xp+5 yp+15 w640 h50 +ReadOnly -Border vzinfo,

	Gui, Add, Button, xs y+40 +Default, OK
	Gui, Add, Button, x+30 yp gplugin_pformat_commonformats_apply, % TXT.SET_apply
	Gui, Add, Text, x+55 yp-15, Input Field
	Gui, Font, s10, Lucida Console
	Gui, Font, s10, Consolas
	Gui, Add, Edit, x+10 yp-2 w441 h40 gzinputfield vzinputfield, 
	Gui, Font
	Gui, commonformat:Show,, % "Choose Format"

	if !FileExist(ztF)
	{
		FileCreateDir, % Substr(ztF, 1, Instr(ztF, "\", 0, 0)-1)
		FileAppend, % "; Add User paste formats here`n; Prefix - plugin_pformat_commonformats_", % ztF
	}

	GuiControl, ChooseString, zchosenformat, % zchosenformat="" ? "None" : zchosenformat ; choose the previous active format
	gosub zchosenformat
	zDone := 0 	; used as an identifier in zchosenformat
	while !zDone
		sleep 200
	gosub plugin_pformat_commonformats_end
	return zOut

commonformatbuttonOK:
;plugin_pformat_commonformats_dopaste:
	Gui, commonformat:Submit, nohide
	STORE.ClipboardChanged := 1 , zOut := zedit
	If (zchosenformat="None") or (zchosenformat="")
		zOut := zin, STORE.ClipboardChanged := 0
	zDone := 1
	return

commonformatGuiEscape:
commonformatGuiClose:
	zDone := 1
	STORE.ClipboardChanged := 1
	zOut := ""				; cancel paste if user escapes or closes the window
	return

plugin_pformat_commonformats_apply:
	Gui, commonformat:Submit, nohide
	zin := zEdit
	return

plugin_pformat_commonformats_end:
	Gui, commonformat:Destroy 		; The original clip will be pasted if you close the gui
	WinWaitClose, Choose Format
	return

zinputfield:
	Gui, commonformat:Submit, nohide
	zoutput := ( zFobj.MaxParams > 1 ) ? zFobj.(zin, zinputfield) : zFobj.(zin)
	STORE.ClipboardChanged := 0 		; remove any clipboard change
	GuiControl, commonformat:, Edit1, % zoutput
	GuiControl, commonformat:, Edit2, % STORE["commonformats_" zchosenformat]
	return

zchosenformat:
	GuiControl, commonformat:, Edit3, % ""
	Gui, commonformat:Submit, nohide
	if (A_GuiEvent="DoubleClick") && (zDone!="")
		gosub commonformatbuttonOK
	else {
		if zchosenformat=
			zchosenformat := "None"
		zFobj := Func("plugin_pformat_commonformats_" zchosenformat)
		if ( zFobj.MaxParams < 2 )
			GuiControl, commonformat:Disable, Edit3
		else {
			GuiControl, commonformat:Enable, Edit3
			GuiControl, commonformat:Focus, Edit3
		}
		gosub zinputfield
	}
	return

}

;---------------------------------- Functions used by this plugin -------------------

plugin_pformat_commonformats_listfunc(file){
	fileread, z, % file
	StringReplace, z, z, `r, , All			; important
	z := RegExReplace(z, "mU)""[^`n]*""", "") ; strings
	z := RegExReplace(z, "iU)/\*.*\*/", "") ; block comments
	z := RegExReplace(z, "m);[^`n]*", "")  ; single line comments
	p:=1 , z := "`n" z
	while q:=RegExMatch(z, "iU)`n[^ `t`n,;``\(\):=\?]+\([^`n]*\)[ `t`n]*{", o, p)
	{
		if IsFunc( zfk := Substr( RegExReplace(o, "\(.*", ""), 2) )
			If zfk not in plugin_pformat_commonformats_listfunc,plugin_pformat_commonformats
				lst .= "`n" RegExReplace(zfk, "^(plugin_pformat_commonformats_)", "", "", 1)
		p := q+Strlen(o)-1
	}
	Sort, lst
	return Trim( RegExReplace(lst, "`n", "|"),"|" )
}

