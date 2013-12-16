; COMPILE INSTRUCTIONS
; run _compile_genfiles.ahk to generate clipjump_code.ahk
; Then Compile this

SetWorkingDir, % A_ScriptDir
;#SingleInstance force
#NoTrayIcon
FileEncoding, UTF-8
ListLines, Off

if !A_IsCompiled
{
	MsgBox, Compile it first
	Exitapp
}

Init()
Exitapp
return

Init(){
	if !(FileExist("clipjump_code.ahk")) && !(A_IsCompiled)
		runwait, _compile_genfiles.ahk
	FileInstall, clipjump_code.ahk, clipjump_code.ahk, 0 		; write if not exist
	managePlugins()
	run %A_ScriptName% /E "%A_ScriptDir%\clipjump_code.ahk"
}

managePlugins(){
	FileRead, f, clipjump_code.ahk
	p1 := "`n#Inc" 
	p2 := "lude %A_ScriptDir%\plugins\"
	p := p1 p2
	if FileExist("plugins")
		loop, plugins\*.ahk
			temp := p A_LoopFileName
			, z .= !Instr(f, temp) ? temp : ""
	FileAppend, % z, clipjump_code.ahk
}