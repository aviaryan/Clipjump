;@Plugin-Name History file paths cleaner
;@Plugin-Description Cleans History tool of copied file paths and folder paths.
;@Plugin-Author Avi
;@Plugin-version 0.1
;@Plugin-Tags history cleaning

historypath := A_ScriptDir "\..\cache\history\"
SetWorkingDir, %historypath%
z := 0

loop, *.txt
{
 	Fileread, var, %A_LoopFileName%
 	match := 1
 	loop, parse, var, `n, `r
 		if !RegExMatch(A_LoopField, "i)^[A-Z]:\\[^\*\?\""\|]*$")
			match := 0
	if match {
		FileDelete, % A_LoopFileName
		z++
	}
}

Msgbox, Cleaned %z% Items from the History.