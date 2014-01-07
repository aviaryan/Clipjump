; Cutomizer FUNCTIONS for Clipjump
; bind, run, tip
; not () is label
; for bind , create object containing other vals , executed by a_thishotkey

loadCustomizations(){
	if !FileExist("ClipjumpCustom.ini") {
		FileAppend, % ";Customizer File for Clipjump`n;Add your custom settings here", ClipjumpCustom.ini
		return
	}
	f := "ClipjumpCustom.ini"

	IniRead, o, % f 	; load sections
	loop, parse, o,`n, %A_space%
	{
		Iniread, s, % f, % A_LoopField
		tobj := {} , c:=0

		loop, parse, s,`n, %A_Space%
		{
			k := Trim( Substr(A_LoopField, 1, p:=Instr(A_LoopField, "=")-1) ) , v := Trim( Substr(A_LoopField, p+2) )
			if k=bind
				tobj.bind := v
			else tobj[A_index k] := v
		}
		if tobj.bind = ""
			customization_Run(tobj)
		else {
			hkZ( tobj.bind := Hparse(tobj.bind), "CustomHotkey", 1 ) ; create hotkey
			CUSTOMS[tobj.bind] := {}
			for k,v in tobj
				CUSTOMS[tobj.bind][k] := v
		}
	}
}

customization_Run(obj){
	global pastemodekey
	for k,v in obj
	{
		if RegExMatch(k, "[0-9]+run$")
		{
			if !Instr(v, "(")
				gosub % IsLabel(v) ? v : "keyblocker"
			else{
				fn := Substr(v, 1, Instr(v,"(")-1)
				pms := Substr(v, Instr(v,"(")+1, -1) , ps := {}
				loop, parse, pms,`,, %A_Space%
					ps.Insert(A_LoopField)
				n := ps.MaxIndex()
				; API functions
				if Instr(fn, "."){
					str := "API:" , str .= Substr(fn, Instr(fn,".")+1)
					loop % n
						str .= "`n" ps[A_index]
					Act_API(str, "API:")
				}
				; else normal function
				if !n
					r := %fn%()
				else if n=1
					r := %fn%(ps.1)
				else if n=2
					r := %fn%(ps.1, ps.2)
				else if n=3
					r := %fn%(ps.1, ps.2, ps.3)
				else if n=4
					r := %fn%(ps.1, ps.2, ps.3, ps.4)
			}
		}
		else if RegExMatch(k, "[0-9]+tip$")
			autoTooltip(v, 1000, 8)
		else if RegExMatch(k, "[0-9]+send$")
			SendInput, % RegExMatch( g:=HParse(v), "[#!\^\+]" ) = 1 ? g : v				; parse keys like Ctrl+Alt+k
		else if RegExMatch(k, "[0-9]+sleep$")
			sleep % v
		else if k != "bind"
		{
			k := Ltrim(k, "0123456789")
			if Instr(k,".")
			{
				loop, parse, k,`.
					j%A_index% := Trim(A_LoopField) , n := A_index-1
				if n=1
					%j1%[j2] := v
				if n=2
					%j1%[j2][j3] := v
			}
			else %k% := v
		}
	}
}

CustomHotkey:
	customization_Run( CUSTOMS[A_ThisHotkey] )
	return