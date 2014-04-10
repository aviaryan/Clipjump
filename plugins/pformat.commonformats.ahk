;@Plugin-Name Common Formats
;@Plugin-Description Shows a gui to paste with a format from many types of predefined formats. Can be easily extended to include more formats.
;@Plugin-Description Only works for Text ([Text] or [File/Folder]) type data.
;@Plugin-Author Avi
;@Plugin-Tags pformat
;@Plugin-version 0.1
;@Plugin-Previewable 0


;------------------------------------------------------------- Paste Formats ------------------------------------

plugin_pformat_commonformats_None(zin){
	return zin , STORE.ClipboardChanged := 0
}

plugin_pformat_commonformats_htmlList(zin){
	return RegExReplace(Trim(zin, "`r`n "), "m)^", "<li>") , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_BBCodeList(zin){
	return RegExReplace(Trim(zin, "`r`n "), "m)^", "[*]") , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_NoFormatting(zin){
	return RTrim(zin, "`r`n") , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_NumberedList(zin){
	zin := Trim(zin, "`r`n ")
	loop, parse, zin, `n, `r
		zout .= A_index ". " A_LoopField
	return zout , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_Lowercase(zin){
	StringLower, zout, zin
	return zout , STORE.ClipboardChanged := 1
}

plugin_pformat_commonformats_UpperCase(zin){
	StringUpper, zout, zin
	return zout , STORE.ClipboardChanged := 1
}


;--------------------------------- The Plugin File Starts , end of Paste Formats ---------------------------------
;-----------------------------------------------------------------------------------------------------------------


plugin_pformat_commonformats(zin){
	static zchosenformat, zedit
	zDone := zOut := ""

	Gui, commonformat:New
	Gui, +AlwaysOnTop +ToolWindow -MaximizeBox

	Gui, Add, ListBox, x5 y5 r15 w120 vzchosenformat gzchosenformat section, % plugin_pformat_commonformats_listfunc(A_ScriptDir "\plugins\pformat.commonformats.ahk")
	Gui, Add, Edit, x+10 w400 h200 vzedit +multi, % zin
	Gui, Add, Button, xs y+30 +Default, OK
	Gui, Add, Button, x+30 yp gplugin_pformat_commonformats_apply, &Apply
	Gui, commonformat:Show,, Choose Format

	while !zDone
		sleep 200
	gosub plugin_pformat_commonformats_end
	return zOut

commonformatbuttonOK:
plugin_pformat_commonformats_dopaste:
	Gui, commonformat:Submit, nohide
	If zchosenformat=
		zchosenformat := "None"
	zOut := Func("plugin_pformat_commonformats_" zchosenformat).(zin)
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

zchosenformat:
	Gui, commonformat:Submit, nohide
	if A_GuiEvent=DoubleClick
		gosub commonformatbuttonOK
	ELSE {
		if zchosenformat=
			zchosenformat := "None"
		zchosenformat := "plugin_pformat_commonformats_" zchosenformat
		zoutput := %zchosenformat%(zin)
		STORE.ClipboardChanged := 0 		; remove any clipboard change
		GuiControl, commonformat:, Edit1, % zoutput
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
		{
			If zfk not in plugin_pformat_commonformats_listfunc,plugin_pformat_commonformats
				lst .= "`n" LTrim(zfk, "plugin_pformat_commonformats_")
		}
		p := q+Strlen(o)-1
	}

	Sort, lst
	return Trim( RegExReplace(lst, "`n", "|"),"|" )
}


;plugin_pformat_commonformats_Delimiters(zin){
;	zobj := {"{each}": "", "{none}": ""}
;	zinpDel := inputbox("Input Delimiter", "What is the input delimiter in this clip?`nLeave 'blank' for Linefeed/Linebreak/Enter"
;		. "`nWrite {each} to separate each character")
;	if zinpDel=
;		zinpDel := "`n"
;	if zinpDel={each}
;		zinpDel := ""

;	zoutpDel := inputbox("Output Delimiter", "By what do you want the output to be delimited/separated ?`nLeave blank for Enter`nWrite {none} to make output"
;	. " delimited by" . " nothing")
;	if zoutpDel=
;		zoutpDel := "`r`n"
;	if zoutpDel={none}
;		zoutpDel := ""
;	loop, parse, zinpDel, % zinpDel, `r
;		zout .= A_LoopField zoutpDel
;	return RTrim(zout, zoutpDel) , STORE.ClipboardChanged := 1
;}