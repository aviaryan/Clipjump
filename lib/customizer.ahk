; Customizer
/*
What is supported?
	k = %func()%
	a.b = %func()%
	a.b = some_string is supported (Obviously)
	a.b = %c.d%
*/


/**
 * loads customs from the ClipjumpCustom.ini file
 * @return {void}
 */
loadCustomizations(){
	if !FileExist("ClipjumpCustom.ini") {
		FileAppend, % ";Customizer File for Clipjump`n;Add your custom settings here`n`n[AutoRun]`n;auto-run items go here", ClipjumpCustom.ini
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
		if !(tobj.noautorun) && (tobj.bind = "") && !startUpComplete
			customization_Run(tobj)
		else if (tobj.bind != "") && (tobj.noautorun == 0) && !startUpComplete
			customization_Run(tobj)
		if Hparse(tobj.bind) 	; if key is valid
			hkZ( tobj.bind := "$" Hparse(tobj.bind), "CustomHotkey", 1 ) ; create hotkey
			, CUSTOMS[tobj.bind] := {}
			, CUSTOMS[tobj.bind] := tobj.Clone()
		CUSTOMS["_" A_LoopField] := tobj.Clone() 	; store section object for use later
	}
}


/**
 * reset all customizations applied in Clipjump, including the hotkey bindings
 * @return {void}
 */
resetCustomizations(){
	for k,v in CUSTOMS
	{
		if InStr(k, "_") != 1
			hkZ(v.bind, "CustomHotkey", 0) 	; unregister hk
	}
	CUSTOMS := {}
}


/**
 * runs a customization (the section)
 * @param  {array} obj customization object containing key-value pairs of commands in it
 * @return {void}
 */
customization_Run(obj){
	for k,v in obj
	{
		k := Ltrim(k, "0123456789") 	; correct key
		isf := ((k=="run") && Instr(v,"("))
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
			StringReplace, v, v, % $match, % ( isf ? """" $var """" : $var )
		}

		if k = run
		{
			if !Instr(v, "(")
				gosub % IsLabel(v) ? v : "keyblocker"
			else 
				ans := RunFunc(v)
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
	}
}


/**
 * runs a function in a string
 * @param {string} v function string
 * @Return output of function
 */
RunFunc(v){
; runs dynamic functions
	static rk := "ª"
	static dq := "§"

	fn := Substr(v, 1, Instr(v,"(")-1)
	pms := Substr(v, Instr(v,"(")+1, -1) , ps := {}
	; loop, parse, pms,`,, %A_Space%
	; 	ps.Insert( RegExReplace(A_LoopField, rk, ",") )
	StringReplace, pms, pms, % """""", % dq, All
	pmsbk := Trim(pms)
	
	while (Trim(pmsbk) != ""){
		if ( Instr(pmsbk, """") == 1 ){
			endb := Instr(pmsbk, """", 0, 2)
			z1 := RegExReplace( Substr(pmsbk, 2, endb-2) , rk, ",")
			ps.Insert( RegExReplace(z1, dq, """") )
			pmsbk := Substr(pmsbk, endb+1) ; skip quotes
			pmsbk := Trim(pmsbk) ; ---
			pmsbk := Substr(pmsbk, 2) ; and then comma
		} else { ; comma separated params
			endb := !Instr(pmsbk, ",")?10000:Instr(pmsbk, ",")
			z1 := RegExReplace( Substr(pmsbk, 1, endb-1) , rk, ",")
			ps.Insert(z1)
			pmsbk := Substr(pmsbk, endb+1)
		}
	}

	n := ps.MaxIndex()
	; API functions
	if Instr(fn, "."){
		str := "API:" , str .= Substr(fn, Instr(fn,".")+1)
		loop % n
		{
			temp := ps[A_Index]
			StringReplace, temp, temp, % "`r`n", % "`n", All
			StringReplace, temp, temp, % "`r", % "`n", All
			str .= "`r" temp
		}
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


/**
 * The label to run any hotkey created in Clipjump Custom
 */
CustomHotkey:
	customization_Run( CUSTOMS[A_ThisHotkey] )
	return