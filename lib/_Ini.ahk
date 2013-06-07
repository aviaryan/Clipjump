/*
_Ini Library v0.2 beta
by Avi Aryan
Licensed under Apache License v2.0 (See Readme.md)
###############################################################
Created as a complete replacement for the default Ini commands.
###############################################################

FUNCTIONS
###############################################################
_IniWrite(Inipath, section, key, value, Keycomment="", Sectioncomment="")
_IniRead(Inipath, section, key, Byref Keycommentvar="", Byref Sectioncommentvar="")
_IniDelete(Inipath, section, key="")

POINTS
###############################################################
* Leave Keycomment or SectionComment in _IniWrite() blank to not add/not modfiy comments
* Make sure you pass Keycommentvar and Sectioncommentvar in _IniRead() as variables and not strings. See below for example.
  You can let the be empty if you dont want to extract corresponding comments
* If key is blank in _IniDelete() , the section will be deleted.

###############################################################
Bugs - Please report
*/

;SetWorkingDir, %A_ScriptDir%
;_iniwrite("settings.ini","Main", "Threshold", 20)
;msgbox,% _iniread("settings.ini","Main", "Threshold", keycmnt, seccmnt) "`nKey comment - " keycmnt "`nSection comment - " seccmnt

;~ _inidelete("black.ini","hollo","exe2")
;return

;===========
;_IniRead() |
;===========

_IniRead(Inipath, section, key, Byref Keycommentvar="", Byref Sectioncommentvar=""){

FileRead,ini,%Inipath%
tempabovesection := Substr(ini, 1, ( (tempabovesection := Instr(ini,"`r`n[" section "]")) ? tempabovesection+1 : ( (Instr(ini, "[" section "]") == 1) ? 1 : 0) ) )
if !(tempabovesection)
	return

StringReplace,tempabovesection,tempabovesection,`r`n,`r`n,UseErrorLevel
lineofsection := ErrorLevel + 1 	;get line of starting of section

loop, 
{
	FileReadLine,curline,%Inipath%,% (lineofsection + A_index)
	if Instr(curline, key) = 1
	{
		keyline := lineofsection + A_index		;curline stores the key
		break
	}
	if Instr(curline, "[") = 1
		break
}
if (keyline != "")
{
	FileReadLine,Keycommentvar,%Inipath%,% (keyline+1)
	keycommentvar := Instr(Ltrim(Keycommentvar), ";") = 1 ? Ltrim(Substr(keycommentvar, 2)) : ""	;if no comment , return blank
	StringReplace,keycommentvar,keycommentvar,``n,`n,All
	FileReadLine,sectioncommentvar,%Inipath%,% (lineofsection+1)
	sectioncommentvar := Instr(sectioncommentvar, ";") = 1 ? Ltrim(Substr(sectioncommentvar, 2)) : ""
	StringReplace,sectioncommentvar,sectioncommentvar,``n,`n,All
	return, Ltrim(Substr(curline, Strlen(key) + 2), "=")	;if equal is left, possible in rare case
}
}

;============
;_IniWrite() |
;============

_IniWrite(Inipath, section, key, value, Keycomment="", Sectioncomment=""){

If !(FileExist(Inipath))	;create file
	FileAppend,%emptyvar%,%Inipath%
FileRead,ini,%Inipath%
if !(Instr(ini, "`r`n[" section "]") or Instr(ini, "[" section "]") = 1)	;create section
	ini .= (ini == "") ? "[" section "]" : "`r`n[" section "]"

tempabovesection := Substr(ini, 1, (tempabovesection := Instr(ini,"`r`n[" section "]")) ? tempabovesection+1 : 1 )	;section will always exist
StringReplace,tempabovesection,tempabovesection,`r`n,`r`n,UseErrorLevel
lineofsection := ErrorLevel + 1 	;get line of starting of section
tempabovesection := (tempabovesection == "[") ? "[" Section "]" : tempabovesection "[" section "]"
StringReplace,tempbelow,ini,%tempabovesection%		;Remove above section.... Now, tempbelow has key1=value1.....
tempbelow := Ltrim(tempbelow, "`r`n")

loop,parse,tempbelow,`n,`r
{
	if Instr(A_LoopField, key) = 1
	{
		keyline := lineofsection + A_index
		break
	}
	if Instr(A_LoopField, "[") = 1
	{
		lastkeyline := lineofsection+A_index	;if key doesnt exist
		break
	}
	lastkeyline := lineofsection + A_index + 1
}
;Keyline empty then create
tempbelow .= "`r`n"	;last entry
if (keyline == "")
{
	keyline := lastkeyline+1 , keynotadd := true , lineins .= key "=" value "`r`n"	;value for key
	if (keycomment != "")
		lineins .= ";" keycomment "`r`n"
	tempbelow := Substr(tempbelow, 1, Instr(tempbelow, "`n", false, 1, lastkeyline-lineofsection-1)) lineins Substr(tempbelow, Instr(tempbelow, "`n", false, 1, lastkeyline-lineofsection-1) + 1)
}
else	;if keyline is something, check for comment
{
	if (Keycomment != "")
	{
	FileReadLine,tempkey,%Inipath%,% keyline + 1
	if !(Instr(Ltrim(tempkey), ";") == 1)
		tempbelow := Substr(tempbelow, 1, Instr(tempbelow, "`n", false, 1, keyline-lineofsection)) "`r`n" Substr(tempbelow, Instr(tempbelow, "`n", false, 1, keyline-lineofsection) + 1)
	}
}
;Section comment
seccomment := false

if (Sectioncomment != "")
{
	FileReadLine,tempsec,%Inipath%,% lineofsection+1
	if !(Instr(Ltrim(tempsec), ";") = 1)
		tempabovesection .= "`r`n" , seccomment := true	;seccomment can change keyline
}
;Lines filled , adding to file
FileDelete, %inipath%
if ((keynotadd) and Sectioncomment == "")
{
	Fileappend,% tempabovesection "`r`n" Rtrim(tempbelow, "`r`n"), %inipath%
	return
}
FileAppend, %tempabovesection%`r`n%tempbelow%, %inipath%
;Adding Data
if !(keynotadd)
{
	Fileatline(inipath, key "=" value, keyline+seccomment)
	if (keycomment != "")
		Fileatline(inipath, ";" keycomment, keyline+1+seccomment)
}
if (Sectioncomment != "")
	Fileatline(inipath, ";" sectioncomment, lineofsection+1)
return
}

;==============
;_Ini_Delete()|
;==============

_IniDelete(Inipath, section, key=""){

FileRead,ini,%Inipath%
tempabovesection := Substr(ini, 1, ( (tempabovesection := Instr(ini,"`r`n[" section "]")) ? tempabovesection+1 : ( (Instr(ini, "[" section "]") == 1) ? 1 : 0) ) )
if !(tempabovesection)
	return

StringReplace,tempabovesection,tempabovesection,`r`n,`r`n,UseErrorLevel
lineofsection := ErrorLevel + 1 	;get line of starting of section

if (key == "")	;delete section
{
	FileReadLine,get,%Inipath%,%lineofsection%
	loop,
	{
		FileReadLine,curline,%Inipath%,% (lineofsection+A_index)
		if Errorlevel = 1
			break
		if Instr(curline, "[") = 1
			break
		get .= "`r`n" curline
	}
	StringReplace,ini,ini,%get%
	FileDelete,%inipath%
	FileAppend,%ini%,%inipath%
	return
}
else	;delete key
{
	loop, 
	{
		FileReadLine,curline,%Inipath%,% (lineofsection + A_index)
		if Instr(curline, key) = 1
		{
			keyline := lineofsection + A_index		;curline stores the key
			break
		}
		if Instr(curline, "[") = 1
			break
	}
	if (keyline != "")
	{
		Fileatline(inipath,"",keyline)
		FileReadline,comment,%Inipath%,keyline	;keyline has decreased due to above
		if Instr(Ltrim(comment), ";") = 1
			Fileatline(inipath,"",keyline)
	}
}
}

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;MISCELLANEOUS HELPER FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Modified Function. taken from Avi's Miscellaneous Functions.ahk
Fileatline(file, what="", linenum=1){
FileRead,filedata,%file%
file1 := Substr(filedata, 1, Instr(filedata, "`r`n", false, 1, linenum-1)-1)	;dont take `r`n

if (var := Instr(filedata, "`r`n", false, 1, linenum))
	file2 := Substr(filedata,var)	;take leading 'r'n (

if (what != "")
	file1 .= "`r`n" what
FileDelete, %file%
filedata := Rtrim(file1 . file2, "`r`n")
FileAppend, %filedata%, %file%
}