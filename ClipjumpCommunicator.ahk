/*

Clipjump Communicator
---------------------
Use this function to momentarily disable/enable Clipjump's "Clipboard monitoring" .

#####################
HOW TO USE
#####################
To disable Clipjump, execute
	CjControl(0)

To later enable Clipjump, execute
	CjControl(1)

AN EXAMPLE IS SET UP BELOW (READY TO RUN), WHEN YOU UNDERSTAND THE CONCEPT , DELETE IT.

#####################
NOTES
	Make sure Clipjump is named as "Clipjump" (Case-Sensitive) both in exe or in ahk form

PLEASE >>>
	Clipboard Monitoring is the method by which Cj monitors Clipboards for new data transfered to Clipboard in a hidden manner. Like PrintScreen, like sending data to
	clipboard by AHK Script and using Context menu to send data.
	This can be helpful if you want to use Clipboard for fetching/transferring huge data.
	If you want to completely disable Clipjump, close and then run it at a required condition.

*/

;Run this Script. Make sure Clipjump v 5.0+ is also running.

Clipboard := "@ I write this on clipboard, Clipjump can catch me. no no"
ToolTip, CLIPJUMP will have the copied text `n "%Clipboard%"`n`nPress Esc to remove this ToolTip`n Then try PRESSING Alt + g
KeyWait,Esc,D
ToolTip

!g::
CjControl(0)	;disable Cj Monitoring
sleep, 100	;A short sleep is necessary
Clipboard := "I am Don. Clipjump can't catch me. ha ha"

Text=
(
Clipboard (not Clipjump) has
"%Clipboard%"
Dont believe me.
Press Esc OR use Right-Click > Paste to paste written text on Clipboard
Also see that Clipjump altough it is running, doesnt have this text.
)
Tooltip, %Text%

KeyWait,Esc,D
Send,^v
CjControl(1)	;enable Cj Monitoring
ToolTip
ExitApp
return

;End of Example

;###########################################################################################
;FUNCTION
;###########################################################################################

CjControl(ByRef StringToSend)  ; ByRef saves a little memory in this case.
; This function sends the specified string to the specified window and returns the reply.
; The reply is 1 if the target window processed the message, or 0 if it ignored it.
{
	Process,Exist,Clipjump.exe
	TargetScriptTitle := "Clipjump" (Errorlevel=0 ? ".ahk " : ".exe ") "ahk_class AutoHotkey"
    VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)
    SizeInBytes := (StrLen(StringToSend) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)
    NumPut(&StringToSend, CopyDataStruct, 2*A_PtrSize)
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows On
    SetTitleMatchMode 2
    SendMessage, 0x4a, 0, &CopyDataStruct,, %TargetScriptTitle%
    DetectHiddenWindows %Prev_DetectHiddenWindows%
    SetTitleMatchMode %Prev_TitleMatchMode%
    return ErrorLevel  ; Return SendMessage's reply back to our caller.
}