/*

This function file helps any AHK script to use Clipjump API functions from its side. 
Just include this file in your script.

Note that API.text2binary() is not supported currently.
The ClipjumpCommunicator.ahk file is already included in this file.

v 15.5.17

*/

/*
EXAMPLES
(It is necessary to initialize the object with "new")

cj := new Clipjump()

cj.IncognitoMode(1)
cj.pasteText("some text")
msgbox % cj.getClipLoc(1, 5)
cj.Paste("","")
cj["CALLER"] := 0
cj["STORE.somevar"] := "abc value"
msgbox % cj.getVar("version")
msgbox % cj.version

*/

;cj := new Clipjump()
;cj.runFunction("set_pformat(NO-FORMATTING)")
;cj.getClipAt(0, 7)
;msgbox % cj.author_page

class Clipjump
{

	__New(){
	}

	__Call(funcname, parameters*){
		cbF := A_temp "\cjcb.txt"
		rFuncs := "|getClipAt|getClipLoc|getVar|runFunction|"

		resChar := "`r"
		ps := ""
		for key,val in parameters
		{
			StringReplace, val, val, % "`r`n", % "`n", All
			StringReplace, val, val, % "`r", % "`n", All
			ps .= resChar val
		}
		FileDelete, % cbF
		returned := CjControl("API:" funcName ps)
		if (returned>0) && Instr(rFuncs, "|" funcName "|")
		{
			Clipjump_wait4file()
			Fileread, out, % cbF
			FileDelete, % cbF
			return out
		}
		else return ""
	}

	/*
	Use - 
		cj := new Clipjump()
		msgbox % cj.version
	*/
	__Get(var){
		return this.getVar(var)
	}

	/*
	Use -
		cj := new Clipjump()
		cj["pastemodekey.z"] := "y"
		cj.MYVAR := "value"
	*/
	__Set(var, value){
		this.setVar(var, value)
	}

	;-----------------------------------------------------------------------------------------
	;------------------------------------------- END -----------------------------------------
	;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
}

Clipjump_wait4file(){
	while !FileExist(A_temp "\cjcb.txt")
		sleep 15
}


;---------------------- Clipjump Communicator.ahk ---------------------------------------------

CjControl(ByRef Code)
{
    global
    local IsExe, TargetScriptTitle, CopyDataStruct, Prev_DetectHiddenWindows, Prev_TitleMatchMode, Z, S

    if ! (IsExe := CjControl_check())
        return -1       ;Clipjump doesn't exist

	TargetScriptTitle := "Clipjump" (IsExe==1 ? ".ahk ahk_class AutoHotkey" : ".exe ahk_class AutoHotkey")
    
    VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)
    SizeInBytes := (StrLen(Code) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)
    NumPut(&Code, CopyDataStruct, 2*A_PtrSize)
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows On
    SetTitleMatchMode 2
    Z := 0

    while !Z
    {
        SendMessage, 0x4a, 0, &CopyDataStruct,, %TargetScriptTitle%
        Z := ErrorLevel
       	if (Z == "FAIL")
       		Z := ""
        if A_index>100
            return -1 ;Timeout..
    }

    DetectHiddenWindows %Prev_DetectHiddenWindows%
    SetTitleMatchMode %Prev_TitleMatchMode%

    while !FileExist(A_temp "\clipjumpcom.txt")
    {
    	if (A_index>40)		;2 secs total
    		if !CjControl_check()
    			return -1
       	sleep 50
       	;Tooltip, % "waiting for clipjumpcom"
   	}
    FileDelete % A_temp "\clipjumpcom.txt"
    ;ToolTip

    return 1        ;True
}

CjControl_check(){

    HW := A_DetectHiddenWindows , TM := A_TitleMatchMode
    DetectHiddenWindows, On
    SetTitleMatchMode, 2
    A := WinExist("\Clipjump.ahk - ahk_class AutoHotkey")
    E := WinExist("\Clipjump.exe - ahk_class AutoHotkey")
    DetectHiddenWindows,% HW
    SetTitleMatchMode,% TM

    return A ? 1 : (E ? 2 : 0)
}