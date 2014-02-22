/*
Plugin management Routines
*/

updatePluginList() {
	FileDelete, plugins\_registry.ahk
	loop, plugins\*.ahk
		st .= "#Include, %A_ScriptDir%\plugins\" A_LoopFileName "`n"
	FileAppend, % st, plugins\_registry.ahk
}

loadPlugins() {
	loop, plugins\*.ahk
	{
		if A_LoopFileName = _registry.ahk
			continue
		; read plugin dets
		FileRead, ov, % A_LoopFileFullPath
		p:=1 , detobj := {}
		while RegExMatch(ov, "im)^;@Plugin-.*$", o, p){
			ps := Substr(o, Instr(o,"-")+1) , pname := Substr(ps, 1, Instr(ps," ")-1) , ptext := Substr(ps, Instr(ps, " ")+1)
			p += Strlen(o) , detobj[pname] := ptext
		}

		filename := Substr(A_LoopFileName, 1, -4) , c := 0
		loop, parse, filename,`.
			name%A_index% := A_LoopField , c++
		if c>0 && !IsObject(PLUGINS[name1])
			PLUGINS[name1] := detobj
		if c>1 && !IsObject(PLUGINS[name1][name2])
			PLUGINS[name1][name2] := detobj
		if c>2 && !IsObject(PLUGINS[name1][name2][name3])
			PLUGINS[name1][name2][name3] := detobj
	}
	msgbox % plugins.autoupdate.description
}