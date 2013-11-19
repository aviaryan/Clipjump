;#########################
;SUPER CONSTANT FUNCTIONS
;#########################

;BeepAt()
;SoundBeep function
BeepAt(value, freq, duration=150){
	if value
		SoundBeep, % freq, % duration
}

;EmptyMem()
;	Emtpties free memory

EmptyMem(){
	return, dllcall("psapi.dll\EmptyWorkingSet", "UInt", -1)
}

FoolGUI(switch=1){

	if !switch
	{
		Gui, foolgui:Destroy
		return
	}

	Gui, foolgui: -Caption +E0x80000 +LastFound +OwnDialogs +Owner +AlwaysOnTop
	Gui, foolgui: Show, NA, foolgui
	WinActivate, foolgui
}

;Checks and makes sure Clipboard is available
;Use 0 as the param when for calling the function, the aim is only to free clipboard and not get its contents
MakeClipboardAvailable(doreturn=1){

	while !temp
	{
		temp := DllCall("OpenClipboard", "int", "")
		sleep 10
	}
	DllCall("CloseClipboard")
	return doreturn ? Clipboard : ""
}

;type=1
;	returns Text
;type=0
;	returns data types
GetClipboardFormat(type=1){		;Thanks nnnik
	Critical, On

 	DllCall("OpenClipboard", "int", "")
 	while c := DllCall("EnumClipboardFormats","Int",c?c:0)
		x .= "," c
	DllCall("CloseClipboard")

	if type
  		if Instr(x, ",1") and Instr(x, ",13")
    		return "[Text]"
 		else If Instr(x, ",15")
    		return "[File/Folder]"
    	else
    		return ""
    else
    	return x
}

;GetFile()
;	Gets file path of selected item in Explorer

GetFile(hwnd=""){
	hwnd := hwnd ? hwnd : WinExist("A")
	WinGetClass class, ahk_id %hwnd%
	if (class="CabinetWClass" or class="ExploreWClass")
	{
		for window in ComObjCreate("Shell.Application").Windows
			if (window.hwnd==hwnd)
    			sel := window.Document.SelectedItems
    	for item in sel
			ToReturn .= item.path "`n"
    }
    else
    	Toreturn := Copytovar(4)

	return Trim(ToReturn,"`n")
}

;GetFolder()
;	Gets folder path of active window in Explorer

GetFolder()
{
	WinGetClass,var,A
	If var in CabinetWClass,ExplorerWClass,Progman
	{
		IfEqual,var,Progman
			v := A_Desktop
		else
		{
			winGetText,Fullpath,A
			loop,parse,Fullpath,`r`n
			{
				IfInString,A_LoopField,:\
				{
					StringGetPos,pos,A_Loopfield,:\,L
					Stringtrimleft,v,A_loopfield,(pos - 1)
					break
				}
			}
		}
	return v
	}
	else
	{
		return Copytovar(2, "!{sc020}^{sc02e}{Esc}") 			;!d^c
	}
}

;BrowserRun()
;	Runs a web-site in default browser safely.

BrowserRun(site){
RegRead, OutputVar, HKCR, http\shell\open\command 
IfNotEqual, Outputvar
{
	StringReplace, OutputVar, OutputVar,"
	SplitPath, OutputVar,,OutDir,,OutNameNoExt, OutDrive
	run,% OutDir . "\" . OutNameNoExt . ".exe" . " """ . site . """"
}
else
	run,% "iexplore.exe" . " """ . site . """"	;internet explorer
}

;hkZ()
;	Hotkey command function

hkZ(HotKey, Label, Status=1) {
	if Hotkey !=
		Hotkey,% HotKey,% Label,% Status ? "On" : "Off"
}

;Gdip_SetImagetoClipboard()
;	Sets some Image to Clipboard

Gdip_SetImagetoClipboard( pImage ){
	;Sets some Image file to Clipboard
	PToken := Gdip_Startup()
	pBitmap := Gdip_CreateBitmapFromFile(pImage)
	Gdip_SetBitmaptoClipboard(pBitmap)
	Gdip_DisposeImage( pBitmap )
	Gdip_Shutdown( PToken)
}

;Gdip_CaptureClipboard()
;	Captures Clipboard to file

Gdip_CaptureClipboard(file, quality){
	PToken := Gdip_Startup()
	pBitmap := Gdip_CreateBitmapFromClipboard()
	Gdip_SaveBitmaptoFile(pBitmap, file, quality)
	Gdip_DisposeImage( pBitmap )
	Gdip_Shutdown( PToken)
}

; Gdip_Getdimensions()

Gdip_getLengths(img, byref width, byref height) {

	GDIPToken := Gdip_Startup()
	pBM := Gdip_CreateBitmapFromFile( img )
	width := Gdip_GetImageWidth( pBM )
	height := Gdip_GetImageHeight( pBM )
	Gdip_DisposeImage( pBM )
	Gdip_Shutdown( GDIPToken )
}

;	Flexible Active entity analyzer

IsActive(what, oftype="classnn", ispattern=false){
	if oftype = classnn
		ControlGetFocus, O, A
	else if oftype = window
		WinGetActiveTitle, O

	if ispattern
		return Instr(O, what) ? 1 : 0
	else
		return ( O == what ) ? 1 : 0
}

;Taken from Miscellaneous Functions by Avi Aryan
getParams(sum){
	static a := 1
	while sum>0
		loop
		{
			a*=2
			if (a>sum)
			{
				a/=2,p.=Round(a)" ",sum-=a,a:=1
				break
			}
		}
	return Substr(p,1,-1)
}

autoTooltip(Text, Time, which=1){
	ToolTip, % Text, , , % which
	SetTimer,% "Tooltipoff" which ,% Time
}

TooltipOff:
TooltipOff1:
TooltipOff2:
TooltipOff3:
TooltipOff4:
	SetTimer, % A_ThisLabel, Off
	ToolTip,,,, % ( Substr(A_ThisLabel, 0) == "f" ) ? 1 : Substr(A_ThisLabel, 0) 
	return


keyblocker:
	return

shortcutblocker_settings:
	ControlGetFocus, temp, A
	GuiControl, settings:,% temp,% A_ThisHotkey
	return

IsHotkeyControlActive(){
	return IsActive("msctls_hotkey", "classnn", true)
}

getQuant(str, what){
	StringReplace, str, str,% what,% what, UseErrorLevel
	return ErrorLevel
}

;Used for Debugging
debugTip(text, tooltipno=20){
	Tooltip, % text,,, % tooltipno
}

/*
SuperInstr()
	Returns min/max position for a | separated values of Needle(s)
	
	return_min = true  ; return minimum position
	return_max = false ; return maximum position

*/
SuperInstr(Hay, Needles, return_min=true, Case=false, Startpoint=1, Occurrence=1){
	
	pos := return_min*Strlen(Hay)
	Needles := Rtrim(Needles, " ")
	
	if return_min
	{
		loop, parse, Needles, %A_space%
			if ( pos > (var := Instr(Hay, A_LoopField, Case, startpoint, Occurrence)) )
				pos := var
	}
	else
	{
		if Needles=
			return Strlen(Hay)
		loop, parse, Needles, %A_space%
			if ( (var := Instr(Hay, A_LoopField, Case, startpoint, Occurrence)) > pos )
				pos := var
	}
	return pos
}

/*
Compare Versions
*/

IsLatestRelease(prog_ver, cur_ver, exclude_keys="beta|alpha") {

	if RegExMatch(prog_ver, "(" exclude_keys ")")
		return 1

	StringSplit, prog_ver_array, prog_ver,`.
	StringSplit, cur_ver_array, cur_ver  ,`.

	Loop % cur_ver_array0
		if !( prog_ver_array%A_index% >= cur_ver_array%A_index% )
			return 0
	return 1
}