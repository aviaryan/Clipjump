; Cutomizer
/*
What is supported?
	k = %func()%
	a.b = %func()%
	a.b = some_string is supported (Obviously)
	a.b = %c.d%
*/

loadCustomizations(){
	if !FileExist("ClipjumpCustom.ini") {
		FileAppend, % ";Customizer File for Clipjump`n;Add your custom settings here", ClipjumpCustom.ini
		return
	}
	f := "ClipjumpCustom.ini"

	IniRead, o, % f 	; load sections
	loop, parse, o,`n, %A_space%
	{
		Iniread, s, % f, % A_LoopField 	; read that section
		tobj := {}

		loop, parse, s,`n, %A_Space%
		{	; read each key
			a := ""
			loop % 3-Strlen(A_index)
				a .= "0"
			a .= A_index
			k := Trim( Substr(A_LoopField, 1, p:=Instr(A_LoopField, "=")-1) ) , v := Trim( Substr(A_LoopField, p+2) )
			if k=bind
				tobj.bind := v
			else if k=noautorun
				tobj.noautorun := v
			else tobj[a k] := v
		}
		if !(tobj.noautorun) && (tobj.bind = "")
			customization_Run(tobj)
		else
			hkZ( tobj.bind := "$" Hparse(tobj.bind), "CustomHotkey", 1 ) ; create hotkey
			, CUSTOMS[tobj.bind] := {}
			, CUSTOMS[tobj.bind] := tobj.Clone()
		CUSTOMS["_" A_LoopField] := tobj.Clone() 	; store section object for use later
	}
}

customization_Run(obj){
	for k,v in obj
	{
		;try { ; Try - No need currently
		k := Ltrim(k, "0123456789") 	; correct key
		loop { 			; change %..% vars to keys
			if !($op1 := Instr(v, "%", 0, 1, 1)) || !($op2 := Instr(v, "%", 0, 1, 2))
				break
			$match := Substr(v, $op1, $op2-$op1+1)
			$var := Substr($match,2,-1)

			if RegExMatch($var, "iU)^[^ `t]+\(.*\)$")
				$var := RunFunc($var)
			else if Instr($var, ".")
			{
				loop, parse, $var,`.
					$j%A_index% := Trim(A_LoopField) , $n := A_index-1
				if $n=1
					$var := %$j1%[$j2]
				if $n=2
					$var := %$j1%[$j2][$j3]
			}
			else $var := %$var%
			StringReplace, v, v, % $match, % $var
		}
		
		if k = run
		{
			if !Instr(v, "(")
				gosub % IsLabel(v) ? v : "keyblocker"
			else RunFunc(v)
		}
		else if k = tip
			autoTooltip(v, 1000, 8)
		else if k = send
			SendInput, % RegExMatch( g:=HParse(v), "[#!\^\+]" ) = 1 ? g : v				; parse keys like Ctrl+Alt+k
		else if k = sleep
			sleep % v
		else if (k != "bind") or (k != "noautorun")
		{
			if Instr(k,".")
			{
				loop, parse, k,`.
					$j%A_index% := Trim(A_LoopField) , $n := A_index-1
				if $n=1
					%$j1%[$j2] := v
				if $n=2
					%$j1%[$j2][$j3] := v
			}
			else %k% := v
		}
		;} ; catch
		;catch {
		;MsgBox, 16, Clipjump, % TXT.CUS_error "`nkey = " k "`nvalue = " v
		;}
	}
}

RunFunc(v){
	; runs dynamic functions
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
		return r := Act_API(str, "API:")
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
	return r
}

CustomHotkey:
	customization_Run( CUSTOMS[A_ThisHotkey] )
	return