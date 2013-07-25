/*
Clipjump Communicator v2
---------------------
Use this function to momentarily disable/enable Clipjump's "Clipboard monitoring" .

#####################
HOW TO USE
#####################
To disable Clipjump, do the following -
    to disable just clipboard monitoring
        CjControl(0)
    to disable ^v Paste mode as well
        CjControl(-1)
    to disable Clipjump History shortcut #c as well
        CjControl(-2)

To later enable Clipjump [at all modes], execute
	CjControl(1)

AN EXAMPLE IS SET UP BELOW (READY TO RUN), WHEN YOU UNDERSTAND THE CONCEPT , DELETE IT.

#####################
NOTES
	Make sure Clipjump is named as "Clipjump" (Case-Sensitive) both in exe or in ahk form

PLEASE >>>
	Clipboard Monitoring is the method by which Cj monitors Clipboards for new data transfered to Clipboard in a hidden manner. Like PrintScreen, like sending data to
	clipboard by AHK Script and using Context menu to send data.
	This can be helpful at times when you transfer data to Clipboard for temporaray purposes.
    Use the disable modes a/c need . For ultimate disable, use -2

*/

;###########################################################################################
;FUNCTION (See HOW TO USE   above)
;###########################################################################################

CjControl(ByRef StringToSend)
{
    global
    local IsExe, TargetScriptTitle, CopyDataStruct, Prev_DetectHiddenWindows, Prev_TitleMatchMode, Z, S

    if ! (IsExe := CjControl_check())
        return -1       ;Clipjump doesn't exist

	TargetScriptTitle := "Clipjump" (IsExe=2 ? ".ahk ahk_class AutoHotkey" : ".exe ahk_class AutoHotkey")

    VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)
    SizeInBytes := (StrLen(StringToSend) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)
    NumPut(&StringToSend, CopyDataStruct, 2*A_PtrSize)
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows On
    SetTitleMatchMode 2
    Z := 0

    while !Z
    {
        SendMessage, 0x4a, 0, &CopyDataStruct,, %TargetScriptTitle%
        Z := ErrorLevel
    }

    DetectHiddenWindows %Prev_DetectHiddenWindows%
    SetTitleMatchMode %Prev_TitleMatchMode%

    if ( (StringToSend+0)<1 )
    {
        while !FileExist(A_temp "\clipjumpcom.txt")
            sleep 50
        FileDelete % A_temp "\clipjumpcom.txt"
    }

    return 1        ;True
}

CjControl_check(){
    
    HW := A_DetectHiddenWindows , TM := A_TitleMatchMode
    DetectHiddenWindows, On
    SetTitleMatchMode, 2
    Process, Exist, Clipjump.exe
    E := ErrorLevel , A := WinExist("\Clipjump.ahk - ahk_class AutoHotkey")
    DetectHiddenWindows,% HW
    SetTitleMatchMode,% TM

    return E ? 1 : (A ? 2 : 0)
}