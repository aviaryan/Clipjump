/*
Clipjump Communicator v4
---------------------
Use this function to momentarily disable/enable Clipjump's "Clipboard monitoring" .

#####################
HOW TO USE
#####################
To DISABLE the selected of the following functions , sum their codes and send in the function -
    Clipboard Monitoring - 2
    Paste Mode - 4    
    Copy file path - 8
    Copy folder path - 16
    Copy file data - 32
    Clipbord History Shortcut - 64
    Select Channel - 128
    One Time Stop shortcut - 256

DISABLE ALL = Use a single code '1048576'

ENABLE ALL = Use a single code  '1'

#####################
NOTES
    SEE EXAMPLE
	Make sure Clipjump is named as "Clipjump" (Case-Sensitive) both in exe or in ahk form

#####################
Example
    To disable , Clipboard Monitoring and Copy file path shortcut, you use
        CjControl(2+8) = CjControl(10)
    Now to enable Copy file path shortcut but keep disabled the Clipboard Monitoring, use
        CjControl(1) - enable all functionalities
        CjControl(2) - disable Clipboard monitoring
*/

;###########################################################################################
;FUNCTION (See HOW TO USE   above)
;###########################################################################################

CjControl(ByRef Code)
{
    global
    local IsExe, TargetScriptTitle, CopyDataStruct, Prev_DetectHiddenWindows, Prev_TitleMatchMode, Z, S

    if ! (IsExe := CjControl_check())
        return -1       ;Clipjump doesn't exist

	TargetScriptTitle := "Clipjump" (IsExe=1 ? ".ahk ahk_class AutoHotkey" : ".exe ahk_class AutoHotkey")
    
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
        if A_index>100
            return -1 ;Timeout..
    }

    DetectHiddenWindows %Prev_DetectHiddenWindows%
    SetTitleMatchMode %Prev_TitleMatchMode%

    while !FileExist(A_temp "\clipjumpcom.txt")
       sleep 50
    FileDelete % A_temp "\clipjumpcom.txt"

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