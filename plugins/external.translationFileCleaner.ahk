;@Plugin-Name Translation File Cleaner
;@Plugin-Description Finds extra and duplicate keys in translation files and shows them
;@Plugin-Author Avi
;@Plugin-version 0.1
;@Plugin-Tags translation maintenance

;@Plugin-param1 The language file name to look in (without the .txt)
#Include %A_ScriptDir%\..\publicAPI.ahk


projectDir := A_WorkingDir

FileRead, fstr, Clipjump.ahk

loop, lib\*.ahk
{
	tmp := ""
	FileRead, tmp, % A_LoopFileFullPath
	fstr .= "`n" tmp
}

; MANAGING ARGUEMENT
F = %1%
if ( F == "" ) ; if no arguement passed
	ExitApp

F := "languages\" F ".txt"
if !FileExist(F){
	Msgbox, Translation file not found.
	ExitApp
}

kobj := {}

loop, read, % F
{
	m := Trim(A_LoopReadLine)
	if ((Instr(m,";")==1) || (Instr(m,"=")==1) || !m)
		continue
	k := Trim(Substr(m, 1, Instr(m,"=")-1))
	if !Instr(fstr, k)
		err .= k "`n"
	if !kobj.hasKey(k)
		kobj[k] := 0
	else
		dup .= k "`n"
}

cj := new Clipjump()
str = "INVALIDS`n`n%err%`n`nDUPLICATES`n`n%dup%"
fstr := "guiMsgBox(""Translation File Cleaner Results"","  str ")"
cj.runFunction(fstr)