;#########################
;LESS CHANGEABLE LABES AND FUNCTIONS
;#########################

; Used Labels

run_searchpm:
	gosub searchpm
	return

settings:
	gui_Settings()
	return

history:
	gui_History()
	return

classTool:
	API.runPlugin("external.ignoreWmanager.ahk")
	return

plugin_deleteFileFolder:
	API.runPlugin("deleteFileFolder.ahk")
	return

main:
	aboutGUI()
	return

exit:
	routines_Exit()
	ExitApp
	return

reloadCustom:
	resetCustomizations()
	loadCustomizations()
	MsgBox, 64, % PROGNAME, % TXT.TIP_done
	return

chrHex(n){
	return chr( base2Number(n, 16) )
}

GetHFONT(Options := "", Name := "") {
   Gui, New
   Gui, Font, % Options, % Name
   Gui, Add, Text, +hwndHTX, Dummy
   HFONT := DllCall("User32.dll\SendMessage", "Ptr", HTX, "UInt", 0x31, "Ptr", 0, "Ptr", 0, "UPtr") ; WM_GETFONT
   Gui, Destroy
   Return HFONT
}

;BeepAt()
;SoundBeep function
BeepAt(value, freq, duration=150){
	if value
		SoundBeep, % freq, % duration
}

;EmptyMem()
;	Emtpties free memory

EmptyMem(){
	return ini_ram_flush ? dllcall("psapi.dll\EmptyWorkingSet", "UInt", -1) : 0
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

;Function for FileCopy, FileMove
FileTransfer(src, dest="", keep_original=1, flag=1){
	if dest =
		FileDelete, % src
	if keep_original
		FileCopy, % src, % dest, % flag
	else
		FileMove, % src, % dest, % flag
}

;Try getting a Variable like Clipboard
tryGetvar(varname, maxtries=100){
	while !fetch_done
	{
		try {
			if A_index>%maxtries%
				break
			ret := %varname%
			fetch_done := 1
		} catch {
			fetch_done := 0 	; I think fetch_done=1 runs even after error and so no use of the try catch happened before
			MakeClipboardAvailable(0, 10)
		}
	}
	return ret
}

; Parses the string and converts the %....% to their respective values
; From   https://github.com/aviaryan/autohotkey-scripts/blob/master/Functions/ValueOf.ahk

Valueof(VarinStr){
global
local Midpoint, emVar, $j, $n
	loop,
	{
		StringReplace, VarinStr, VarinStr,`%,`%, UseErrorLevel
		Midpoint := ErrorLevel / 2
		if Midpoint = 0
			return ( emvar := VarinStr )
		emVar := Substr(VarinStr, Instr(VarinStr, "%", 0, 1, Midpoint)+1, Instr(VarinStr, "%", 0, 1, Midpoint+1)-Instr(VarinStr, "%", 0, 1, Midpoint)-1)

		if Instr(emVar, ".")
		{
			loop, parse, emVar,`.
				$j%A_index% := Trim(A_LoopField) , $n := A_index-1
			if $n=1
				emVar := %$j1%[$j2]
			if $n=2
				emVar := %$j1%[$j2][$j3]
		} 
		else emVar := %emVar%

		VarinStr := Substr(VarinStr, 1, Instr(VarinStr, "%", 0, 1, Midpoint)-1) emVar Substr(VarinStr, Instr(VarinStr, "%", 0, 1, Midpoint+1)+1)
	}
}


multInputBox(Title, caption="", row=5, default="", owner=""){
	static theEdit
	local kw, oDone
	
	theEdit := ""
	kw := A_ScreenWidth<1200 ? 600 : 700
	Gui, mIBox:new
	Gui, Font, s10, Consolas
	Gui, Add, Text, x5 y5, % caption
	Gui, Font, norm, Consolas
	Gui, Add, Edit, xp y+30 w%kw% r%row% vtheEdit, % default
	Gui, Add, Button, x5 y+30 Default, OK
	Gui, Add, Button, x+30 yp gmIboxbuttonCancel, % TXT.SET_Cancel
	if owner {
		Gui, miBox:+owner%owner%
		Gui, %owner%:+Disabled
	}
	Gui, mIbox:Show,, % Title
	while !oDone
		sleep 50
	return theEdit

mIboxbuttonOK:
	Gui, miBox:Submit, nohide
	STORE.ErrorLevel := 1
	gosub mIboxGuiClose
	return

mIboxGuiClose:
mIboxbuttonCancel:
	if owner
		Gui, %owner%:-Disabled
	Gui, mIBox:Destroy
	oDone := 1
	return

}

errMsgBox(Text){
	MsgBox, 48, % TXT["_clipjumpError"], % text "`n`n" TXT.TIP_genErrMsg
}

/*
a := {a: "b",c: "d"}
ret := ObjectEditor(a)
for k,v in ret
	msgbox % k "`n" v
return

Options (opn)
	1: Title
	2: owner
	3: prompt
	4: width
*/

ObjectEditView(obj, opn, readonly=0){
	global
	local oDone

	Gui, objEdit:new
	Gui, Font, s10 underline, Consolas
	Gui, Add, Text, x5 y5, % opn.3
	Gui, Add, Text, xp y+15 section,
	Gui, Font, norm, Consolas

	maxsize := 0
	for k in obj {
		if Strlen(k) > maxsize
			maxsize := Strlen(k)
	}
	maxsize := maxsize*5+100

	for k,v in obj {
		Gui, Add, Text, xs y+7, % k
		Gui, Add, Edit, % "x" maxsize " yp vfield" A_index  (readonly ? " +Readonly" : "") " w" (opn.4 ? opn.4 : 100), % v
	}
	Gui, Add, Button, x5 y+30 Default gobjEditButtonSv, % readonly ? "OK" : TXT._save
	Gui, Add, Button, x+30 yp gobjEditButtoncancel, % TXT.SET_Cancel
	if opn.2 {
		Gui, % "objEdit:+owner" opn.2
		Gui, % opn.2 ":+Disabled"
	}
	Gui, objEdit:Show,, % opn.1

	while !oDone
		sleep 50
	return obj

objEditGuiEscape:
objEditButtonCancel:
objEditGuiClose:
	if opn.2
		Gui, % opn.2 ":-Disabled"
	Gui, objEdit:Destroy
	oDone := 1
	return

objEditButtonSv:
	Gui, objEdit:Submit, nohide
	for k in obj
		obj[k] := field%A_index%
	gosub objEditGuiClose
	return

}

;Try getting a file onto Clipboard
try_ClipboardfromFile(file, maxtries=100){
	;Critical, Off
	temp_ClipbrdLoaded := 0
	while !temp_ClipbrdLoaded
	{
		try {
			if A_index > %maxtries%
				break
			FileRead, Clipboard, *c %file%
			temp_ClipbrdLoaded := 1
		}
	}
	while !DllCall("OpenClipboard", "int", "")
		sleep 10
	DllCall("CloseClipboard")
	return temp_ClipbrdLoaded
}

getRealCD(text){
; Substitues [IMAGE] for blank data in CDS . Used by the search funcs in search paste mode and Organizer
	return text="" ? TXT.HST_viewimage : text
}

ClipTransfer(sub, cno, nsub="", ncno="", keep_original=1, flag=1){
; Copy moves a clip along with the 3 or more files
; TODO Change params in prefs.ini also
	FileTransfer("cache\clips" sub "\" cno ".avc", "cache\clips" nsub "\" ncno ".avc", keep_original, flag)
	FileTransfer("cache\thumbs" sub "\" cno ".jpg", "cache\thumbs" nsub "\" ncno ".jpg", keep_original, flag)
}

ClipSwap(sub, cno, nsub="", ncno=""){
	; Swaps two clips
	ClipTransfer(sub, cno, sub, 100000, 0)
	ClipTransfer(nsub, ncno, sub, cno, 0)
	ClipTransfer(sub, 100000, nsub, ncno, 0)
}

ClipFolderTransfer(sub, nsub, keep_original=1, flag=1){
; Copy moves a channel with the 3 folders
	static d1 := "clips" , d2 := "thumbs" ;, d3 := "fixate"
	loop 2 ;3
		if keep_original
			FileCopyDir, % "cache\" d%A_index% sub, % "cache\" d%A_index% nsub, % flag
		else
			FileMoveDir, % "cache\" d%A_index% sub, % "cache\" d%A_index% nsub, % flag
}

;Checks and makes sure Clipboard is available
;Use 0 as the param when for calling the function, the aim is only to free clipboard and not get its contents
MakeClipboardAvailable(doreturn=1, sleeptime=10){
	;Critical, On
	while !temp
	{
		temp := DllCall("OpenClipboard", "int", "")
		sleep % sleeptime
	}
	DllCall("CloseClipboard")
	if doreturn
		ret := Clipboard
	return ret
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

	if type=1
		if Instr(x, ",1") and Instr(x, ",13")
			return "[" TXT.TIP_text "]"
		else If Instr(x, ",15")
			return "[" TXT.TIP_file_folder "]"
		else
			return ""
	else
		return x
}

;--------------------------------------------------------------------------
;      S Q L     F U N C T I O N S
;--------------------------------------------------------------------------

; Converts YYYYMMDDHHMMSS to YYYY-MM-DD HH:MM:SS
convertTimeSql(t=""){
	if (t == "") 
		t:= A_Now
	return SubStr(t, 1, 4) "-" SubStr(t,5,2) "-" SubStr(t,7,2) " " SubStr(t, 9, 2) ":" SubStr(t,11,2) ":" SubStr(t,13,2)
}

escapeQuotesSql(s){
	; replace quote (") in data content with double quote ("")
	; works like escaping
	StringReplace, s, s, % """", % """""", All
	return s
}

fileSizeFromStr(s){
	; in bytes
	; + 3 comes from other file constraints
	return strlen(s) + 3 
}

execSql(s, warn:=0){
	; execute sql
	if (!DB.Exec(s))
		if (warn)
			msgbox % DB.ErrorCode "`n" DB.ErrorMsg
}

getFromTable(tbl, cols, condition){
	; get from table
	; get only particular columns if necessary
	local recordSet, Row
	
	q := "select " . cols . " from " . tbl . " where " condition
	recordSet := ""
	if !DB.Query(q, recordSet)
		msgbox ERROR
	if (recordSet.RowCount == 0)
		return ""
	else {
		recordSet.Next(Row)
		return Row
	}
}

saveBlobImage(blobobj, path){
	; gets the blob obj 
	; and saves the image from it at path

	HFILE := FileOpen(path, "w")

	If IsObject(blobobj){
		Size := blobobj.Size
		Addr := blobobj.GetAddress("Blob")
		If !(Addr) || !(Size) {
			MsgBox, 0, Error, BlobAddr = %Addr% - BlobSize = %Size%
		} Else {
			VarSetCapacity(MyBLOBVar, Size) ; added
			DllCall("Kernel32.dll\RtlMoveMemory", "Ptr", &MyBLOBVar, "Ptr", Addr, "Ptr", Size) ; added
			HFILE.RawWrite(&MyBLOBVar, Size) ; changed
			;HFILE.RawWrite(Addr + 0, Size) ; original
			blobobj := ""
			HFILE.Close()
			blobobj := ""
		}
	}
}

;-------------------------------------------------------------


getRandomStr(len){
	rStr := "abcdefghijiklmnopqrstuvwxyz0123456789"
	str := ""
	loop % len
	{
		Random, num, 1, 36
		str .= Substr(rStr, num, 1)
	}
	return str
}

genHTMLforPreview(code){
	FileDelete, % PREV_FILE
	FileAppend, % "<pre style=""word-break: break-all; word-wrap: break-word;"">" deActivateHtml(code), % PREV_FILE
}

deactivateHtml(code){
	StringReplace, code, code, >, % "&gt;", All
	StringReplace, code, code, <, % "&lt;", All
	return code
}

TT_Console_PasteMode(text, keys){
	tx := ini_pstMode_X ? ini_pstMode_X : SPM.X , ty := ini_pstMode_Y ? ini_pstMode_Y : SPM.Y
	return TT_Console(text, keys, tx, ty,,, 1)
}

;GetFile()
;	Gets file path of selected item in Explorer

GetFile(hwnd=""){
	hwnd := hwnd ? hwnd : WinExist("A")
	WinGetClass class, ahk_id %hwnd%
	if (class="CabinetWClass" or class="ExploreWClass")
	{
		try for window in ComObjCreate("Shell.Application").Windows
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

GetFolder(){
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
	{
		try
			Hotkey,% HotKey,% Label,% Status ? "On" : "Off"
		catch {
			t := ""
			loop, parse, hotkey
				if A_LoopField is alpha
					t .= "vk" GetVKList(A_LoopField)[1]
				else t .= A_LoopField
			Hotkey, % t,% Label,% (Status ? "On" : "Off") " UseErrorLevel"
			if ErrorLevel = 2
				MsgBox, 16, Clipjump Warning, It looks like the hotkey %t% doesn't exist ? `nRefer to troubleshooting page in help file.
		}
	}
}

/**
 * hkz that prepends pstIdentfier
 */
hkZ_pi(key, label, status=1){
	return hkZ(pstIdentifier key, label, status)
}

; Converts an Ini file to an object
Ini2Obj(Ini){
	out := {}
	loop, read, % Ini
	{
		if ( Instr(l := Trim(A_LoopReadLine), ";") == 1 ) or !l
			continue
		if RegExMatch(l, "iU)\[.*\]", ov)
		{
			curS := Substr(ov, 2, -1) , out[curS] := {}
			continue
		}
		out[curS][ k := Trim( Substr(l, 1, p:=Instr(l, "=")-1) ) ] := Trim( Substr(l, p+2) )
	}
	return out
}

; Saves an object as an Ini file
Obj2Ini(obj, Ini, saveBlank=false){
	FileDelete, % Ini
	for k,v in obj
	{
		t .= "`n[" k "]`r`n"
		for k2,v2 in v
			if (saveBlank) || (v2 != "")
				t .= k2 " = " v2 "`r`n"
	}
	FileAppend, % Trim(t, "`r`n"), % Ini
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
TooltipOff5:
TooltipOff6:
TooltipOff7:
TooltipOff8:
TooltipOff9:
TooltipOff10:
TooltipOff11:
	SetTimer, % A_ThisLabel, Off
	ToolTip,,,, % ( Substr(A_ThisLabel, 0) == "f" ) ? 1 : RegExReplace(A_ThisLabel, "TooltipOff")
	return

emptylabel:
keyblocker:
	return

simplePaste: 		; simple lable to paste CURRENT content on cb.
	Send ^{vk56}
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
debugTip(text, x="", y="", tooltipno=20){
	Tooltip, % text,% x,% y, % tooltipno
}

fillwithSpaces(text="", limit=35){
	loop % limit-Strlen(text)
		r .= A_space
	return text r
}

/**
 * TickCount in 64 bit precision
 */
TickCount64(){
	return DllCall("GetTickCount64", "Cdecl UInt64")
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

IsLatestRelease(prog_ver, cur_ver, exclude_keys="b|a") {

	if RegExMatch(prog_ver, "(" exclude_keys ")")
		return 1

	StringSplit, prog_ver_array, prog_ver,`.
	StringSplit, cur_ver_array, cur_ver  ,`.

	loop % cur_ver_array0 - prog_ver_array0
		var := prog_ver_array0+A_index , prog_ver_array%var% := 0

	Loop % cur_ver_array0
		if !( prog_ver_array%A_index% >= cur_ver_array%A_index% )
			return 0
		else if ( prog_ver_array%A_index% > cur_ver_array%A_index% ) 	; in case cur_ver supplied is of old file
			return 1
	return 1
}

;get width and heights of controls
getControlInfo(type="button", text="", ret="w", fontsize="", fontmore=""){
	static test
	Gui, wasteGUI:New
	Gui, wasteGUI:Font, % fontsize, % fontmore
	Gui, wasteGUI:Add, % type, vtest, % text
	GuiControlGet, test, wasteGUI:pos
	Gui, wasteGUI:Destroy
	if ret=w
		return testw
	if ret=h
		return testh
}

;GUI Message Box to allow selection
guiMsgBox(title, text, owner="", isEditable=0, wait=0, w="", h=""){
	static thebox
	wf := getControlInfo("edit", text, "w", "s9", "Lucida Console")
	hf := getControlInfo("edit", text, "h", "s9", "Lucida Console")
	w := !w ? (wf > A_ScreenWidth/1.5 ? A_ScreenWidth/1.5 : wf+200) : w 	;+10 for scl bar
	h := !h ? (hf > A_ScreenHeight ? A_ScreenHeight : hf+65) : h 		;+10 for margin, +more for the button

	Gui, guiMsgBox:New
	Gui, guiMsgBox:+Owner%owner%
	Gui, -MaximizeBox +AlwaysOnTop
	Gui, Font, s9, Lucida Console
	Gui, Add, Edit, % "x5 y5 w" w-10 " h" h-35 (isEditable ? " -" : " +") "Readonly vthebox +multi -Border", % text
	Gui, Add, button, % "x" w/2-20 " w40 y+5", OK
	GuiControl, Focus, button1
	Gui, guiMsgBox:Show, % "w" w " h" h, % title
	if wait
		while GuiEnds
			sleep 100
	return thebox

guiMsgBoxButtonOK:
guiMsgBoxGuiClose:
guiMsgBoxGuiEscape:
	Gui, guiMsgBox:Submit, nohide
	Gui, guiMsgBox:Destroy
	GuiEnds := 1
	return
}


;inputbox function for use with customizer...
inputBox(title, text){
	Inputbox, o, % title, % text
	if !ErrorLevel
		return o
}

Base2Number(H, base=16){
	S:=Strlen(H),N:=0
	loop,parse,H
		N+=((A_LoopField*1="")?Asc(A_LoopField)-87:A_LoopField)*base**(S-A_index)
	return N
}

max(a, b){
	return (a>b) ? a : b
}

; Code by deo http://www.autohotkey.com/board/topic/74348-send-command-when-switching-to-russian-input-language/#entry474543

GetVKList( letter ){
	SetFormat, Integer, Hex
	vk_list := Array()
	for i, hkl in KeyboardLayoutList()
	{
		retVK := DllCall("VkKeyScanExW","UShort",Asc(letter),"Ptr",hkl,"Short")
		if (retVK = -1)
			continue
		vk := retVK & 0xFF
		StringTrimLeft,vk,vk,2
		if !instr(_list,"|" vk "|")
		{
			_list .= "|" vk "|"
			vk_list.insert(vk)
		}
	}
	SetFormat, Integer, D
	return vk_list
}

KeyboardLayoutList(){
	hkl_num := 20
	VarSetCapacity(hHkls,hkl_num*A_PtrSize,0)
	num := DllCall("GetKeyboardLayoutList","Uint",hkl_num,"Ptr",&hHkls)
	hkl_list := Array()
	loop,% num
		hkl_list.Insert(NumGet(hHkls,(A_index-1)*A_PtrSize,"UPtr"))
	hHkls =
	return hkl_list
}
; !Code by deo