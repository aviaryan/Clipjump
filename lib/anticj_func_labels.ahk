;#########################
;SUPER CONSTANT FUNCTIONS
;#########################

;EmptyMem()
;	Emtpties free memory

EmptyMem(){
return, dllcall("psapi.dll\EmptyWorkingSet", "UInt", -1)
}

;GetFile()
;	Gets file path of selected item in Explorer

GetFile(hwnd=""){
	hwnd := hwnd ? hwnd : WinExist("A")
	WinGetClass class, ahk_id %hwnd%
	if (class="CabinetWClass" or class="ExploreWClass" or class="Progman")
		for window in ComObjCreate("Shell.Application").Windows
			if (window.hwnd==hwnd)
    sel := window.Document.SelectedItems
	for item in sel
	ToReturn .= item.path "`n"
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