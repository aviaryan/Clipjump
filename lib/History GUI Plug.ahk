;History Gui labels and functions
;A lot Thanks to chaz

gui_History()
; Creates and shows a GUI for managing and viewing the clipboard history
{
	global
	static x, y, how_sort := 2_sort := 3_sort := 0, what_sort := 2
	;2_3_sort are the vars storing how cols are sorted , 1 means in Sort ; 0 means SortDesc

	Gui, History:new
	Gui, Margin, 7, 7
	Gui, +Resize +MinSize390x110

	Gui, Add, Button, w75 h23 Section Default	vhistory_ButtonPreview	ghistory_ButtonPreview, &Preview
	Gui, Add, Button, x+6 ys w75 h23			vhistory_ButtonDelete	ghistory_ButtonDelete, Dele&te item
	Gui, Add, Button, x+6 ys w75 h23 			vhistory_ButtonDeleteAll ghistory_ButtonDeleteAll, Clear &history
	Gui, Add, Text, x+15 ys+5 					vhistory_SearchText,	Search &Filter:
	Gui, Add, Edit, ys+1  	ghistory_SearchBox	vhistory_SearchBox
	;Gui, Font, s9, Courier New
	;Gui, Font, s9, Lucida Console
	Gui, Font, s9, Consolas
	Gui, Add, ListView, xs+1 HWNDhistoryLV ghistoryLV vhistoryLV LV0x4000, Clip|Date|Size(B)|Hiddendate

	Gui, Add, StatusBar
	Gui, Font
	GuiControl, Focus, history_SearchBox

	;History Right-Click Menu
	Menu, HisMenu, Add, &Preview, history_ButtonPreview
	Menu, HisMenu, Add
	Menu, HisMenu, Add, % "&Copy        (Ctrl+C)", history_clipboard
	Menu, HisMenu, Add, % "&Insta-Paste (Space)", history_InstaPaste
	Menu, HisMenu, Add
	Menu, HisMenu, Add, % "&Export Clip (Ctrl+E)", history_exportclip
	Menu, HisMenu, Add, &Delete, history_ButtonDelete
	Menu, HisMenu, Default, &Preview

	Iniread, w, % CONFIGURATION_FILE, Clipboard_History_window, w, %A_Space%
	Iniread, h, % CONFIGURATION_FILE, Clipboard_History_window, h, %A_Space%

	historyUpdate()
	history_UpdateSTB()
	LV_ModifyCol(what_sort, how_sort ? "Sort" : "SortDesc")

	if ((h+0) == WORKINGHT)
	{
		Gui, History:Show, Maximize, %PROGNAME% Clipboard History
		WinMinimize, %PROGNAME% Clipboard History
		WinMaximize, %PROGNAME% Clipboard History
		GuiControl, focus, history_SearchBox
	}
	else
		Gui, History:Show,% ( x ? "x" x " y" y : "" ) " w" (w?w:700) " h" (h?h:500), %PROGNAME% Clipboard History

	WinWaitActive, %PROGNAME% Clipboard History
	WinGetPos, x, y
	return

history_ButtonPreview:
	LV_GetText(clip_file_path, LV_GetNext("", "Focused"), hidden_date_no)
	if Instr(clip_file_path, ".jpg")
		gui_History_Preview("image")
	else 
	{
		FileRead, previewText, cache\history\%clip_file_path%
		gui_History_Preview("text", previewText)
	}
	return

history_ButtonDelete:
	Gui, History:Default

	temp_row_s := 0 , rows_selected := "" , list_clipfilepath := ""
	while (temp_row_s := Lv_GetNext(temp_row_s))
		rows_selected .= temp_row_s ","
	rows_selected := Substr(rows_selected, 1, -1)     ;get CSV row numbers

	;Get Row names
	loop, parse, rows_selected,`,
		LV_GetText(clip_file_path, A_LoopField, hidden_date_no)
		, list_clipfilepath .= clip_file_path "`n" 	;Important for faster results

	;Delete Rows
	loop, parse, rows_selected,`,
		LV_Delete(A_LoopField+1-A_index)

	;Delete items
	loop, parse, list_clipfilepath, `n
		FileDelete, % "cache\history\" A_LoopField
	
	Guicontrol, History:Focus, history_SearchBox
	history_UpdateSTB()
	return

history_ButtonDeleteAll:
	Gui, +OwnDialogs
	MsgBox, 257, Clear History, Are you sure you want to permanently clear %PROGNAME%'s clipboard history?
	IfMsgBox, OK
	{
		FileDelete, cache\history\*
		historyUpdate()
		history_UpdateSTB()
	}
	return

history_SearchBox:
	Critical, On
	Gui, History:Default
	Gui, History:Submit, NoHide
	historyUpdate(history_SearchBox, 0)
	LV_ModifyCol(what_sort, how_sort ? "Sort" : "SortDesc") 		;sort column correctly
	return

historyLV:
	Gui, History:Default

	if A_GuiEvent = DoubleClick
		gosub, history_ButtonPreview
	else if (A_GuiEvent == "ColClick")
	{
		LV_SortArrow(historyLV, A_EventInfo)
		, what_sort := A_EventInfo
		, temp := %what_sort%_sort 				;retrieve currrent col value
		, 2_sort := 3_sort := 0					;change all cols values
		, how_sort := %what_sort%_sort := ! (temp) 			;update real current col value
	}
	return

history_clipboard:
	history_clipboard()
	return

historyGuiContextMenu:
	if (A_GuiControl != "historyLV") or (LV_GetNext() = 0)
		return
	Menu, HisMenu, Show, %A_GuiX%, %A_GuiY%
	return

historyGuiSize:
	if (A_EventInfo != 1)	; ignore minimising
	{
		gui_w := a_guiwidth , gui_h := a_guiheight

		SendMessage, 0x1000+29, 1,	0, SysListView321, %PROGNAME% Clipboard History
		w2 := ErrorLevel
		SendMessage, 0x1000+29, 2,	0, SysListView321, %PROGNAME% Clipboard History
		w3 := ErrorLevel

		LV_ModifyCol(1, gui_w-w2-w3-40) 				;gui_w - x  where   x  =  width of all cols + 40
		GuiControl, Move, historyLV, % "w" (gui_w - 15) " h" (gui_h - 65)     ;+20 H in no STatus Bar
		GuiControl, Move, history_SearchBox, % "x330 w" (gui_w - 338)
	}
	return

historyGuiClose:
historyGuiEscape:
	Wingetpos, x, y,, h, %PROGNAME% Clipboard History

	h := h > WORKINGHT ? WORKINGHT : gui_h               ;gui_h and gui_w are function vars created in the historyGUISIze label (above).

	Ini_write(temp_h := "Clipboard_History_window", "w", gui_w, 0)
	Ini_write(temp_h, "h", h, 0)

	SendMessage, 0x1000+29, 0,	0, SysListView321, %PROGNAME% Clipboard History   ; 0x1000+29 is LVM_GETCOLUMNWIDTH
	w1 := ErrorLevel
	SendMessage, 0x1000+29, 1,	0, SysListView321, %PROGNAME% Clipboard History
	w2 := ErrorLevel
	SendMessage, 0x1000+29, 2,	0, SysListView321, %PROGNAME% Clipboard History
	w3 := ErrorLevel
	Ini_write(temp_h, "w1", w1, 0)
	Ini_write(temp_h, "w2", w2, 0)
	Ini_write(temp_h, "w3", w3, 0)

	Gui, History:Destroy
	Menu, HisMenu, DeleteAll
	EmptyMem() 				;Free memory
	return
}


gui_History_Preview(mode, previewText = "")
; Creates and shows a GUI for viewing history items
{
	global
	static wt := A_ScreenWidth / 2 , ht := A_ScreenHeight / 2 , maxlines = Round(ht / 13)
	
	Gui, Preview:New
	if mode = image
	{
		Gui, Margin, 0, 0
		Gui, Add, Picture, w%wt% h%ht% vhistory_pic, cache\history\%clip_file_path%
		history_Text_Act := false
	}
	else if mode = text
	{
		Gui, Margin, 8, 8
		Gui, Font, s9, Consolas
		;13 pixels = 1 line
		r := ( t:=getLines(previewText) ) > maxlines ? maxlines : ( (t+8) > maxlines ? maxlines : t+8 )
		Gui, Add, Edit, w%wt% r%r% +ReadOnly -Wrap +HScroll vhistory_text, %previewText%
		Gui, Font
		history_Text_Act := true
	}
	Gui, Add, Button, % "x" (wt/2)-55 " y+10 w110 h23 gbutton_Copy_To_Clipboard Default", Copy to Clipboard

	Gui, Preview:+OwnerHistory
	Gui, History:+Disabled
	Gui, Preview: -MaximizeBox -MinimizeBox
	Gui, Preview:Show, AutoSize, Preview
	return
	
button_Copy_to_Clipboard:
	Gui, Preview:Submit, nohide
	if history_Text_Act
		try Clipboard := history_text
	else
		Gdip_SetImagetoClipboard("cache\history\" clip_file_path)
	sleep 500 		;Sleep to show Tootlip and allow Clipboard-capture
	gosub, previewGuiClose
	return

previewGuiClose:
previewGuiEscape:
	Gui, History:-Disabled
	Gui, Preview:Destroy
	EmptyMem()			;Free Memory
	return
}


history_clipboard(){
; Transfers the selected item from Listview to Clipboard
; -
	Gui, History:Default
	row_selected := LV_GetNext(0)
	LV_GetText(clip_file_path, row_selected, hidden_date_no)
	if !Instr(clip_file_path, ".jpg")
	{
		FileRead, temp_Read, cache\history\%clip_file_path%
		try Clipboard := temp_Read
	}
	else
		Gdip_SetImagetoClipboard("cache\history\" clip_file_path)
}


historyUpdate(crit="", create=true)
; Update the history GUI listview
; create=false will prevent re-drawing of Columns , useful when the function is called in the SearchBox label and Gui Size is customized.
{
	static his_obj := {}
	local totalSize := 0

	LV_Delete()
	Loop, cache\history\*
	{
		if Instr(A_LoopFileFullPath, ".txt")
		{
			if !his_obj[A_LoopFileName "_data"]
			{
				Fileread, lv_temp, %A_LoopFileFullPath%
				data := his_obj[A_LoopFileName "_data"] := lv_temp
			}
			else
				data := his_obj[A_LoopFileName "_data"]
		}
		else if Instr(A_LoopFileFullPath, ".jpg")
			data := his_obj[A_LoopFileName "_data"] := MSG_HISTORY_PREVIEW_IMAGE
		else Continue
		
		if Instr(data, crit)
		{
			if !his_obj[A_LoopFileName "_date"]
			{
				his_obj[A_LoopFileName "_date"] := Substr(A_LoopFileName,1,4) "-" Substr(A_LoopFileName,5,2) "-" Substr(A_LoopFileName,7,2) "  "
						. Substr(A_LoopFileName,9,2) ":" Substr(A_LoopFileName,11,2) ":" Substr(A_LoopFileName, 13, 2)
				FileGetSize, O,% A_LoopFileFullPath
				his_obj[A_LoopFileName "_size"] := O
			}

			LV_Add("", data, his_obj[A_LoopFileName "_date"], t := his_obj[A_LoopFileName "_size"], A_LoopFileName)
			totalSize += t 				; speed factor
		}
	}

	history_UpdateSTB("" totalSize/1024)

	if create
	{
		Iniread, w1,% CONFIGURATION_FILE, Clipboard_History_window, w1, %A_Space%
		Iniread, w2,% CONFIGURATION_FILE, Clipboard_History_window, w2, %A_Space%
		Iniread, w3,% CONFIGURATION_FILE, Clipboard_History_window, w3, %A_Space%
		LV_ModifyCol(1, w1?w1:445) , LV_ModifyCol(2, w2?w2:155) , Lv_ModifyCol(3, (w3?w3:70) " Integer") , Lv_ModifyCol(4, "0")
	}
}

history_GetSize(I := ""){
;returns the size of given filename in history
	If I !=
		FileGetSize, R, % "cache\history\" I, B
	else
		Loop, cache\history\*.*, , 1
    		R += %A_LoopFileSize%

    return R/1024
}

history_UpdateSTB(size=""){
	; If size is passed, that size is used
	Gui, History:Default
	SB_SetText("Disk Consumption : " ( size="" ? history_GetSize() : size ) " KB")
}


history_InstaPaste:
	IniRead, clipboard_instapaste, % CONFIGURATION_FILE, Advanced, Instapaste_write_clipboard, %A_Space%
	if clipboard_instapaste
		history_clipboard()
	else
		CALLER := 0
		, history_clipboard()

	WinClose, %PROGNAME% Clipboard History
	WinWaitClose, %PROGNAME% Clipboard History
	Send, ^v
	CALLER := CALLER_STATUS
	return

history_exportclip:
	CALLER := false
	history_clipboard()
	ClipWait, ,1
	loop
		if !FileExist(temp := A_MyDocuments "\export" A_index ".cj")
			break
	Tooltip,% "Selected Clip exported to `n" temp
	SetTimer, TooltipOff, 1000
	try FileAppend, %ClipboardAll%, %temp%
	CALLER := CALLER_STATUS
	return

LV_SortArrow(h, c, d="")	; by Solar (http://www.autohotkey.com/forum/viewtopic.php?t=69642)
; Shows a chevron in a sorted listview column pointing in the direction of sort (like in Explorer)
; h = ListView handle (use +hwnd option to store the handle in a variable)
; c = 1 based index of the column
; d = Optional direction to set the arrow. "asc" or "up". "desc" or "down".
{
	static ptr, ptrSize, lvColumn, LVM_GETCOLUMN, LVM_SETCOLUMN
	if (!ptr)
		ptr := A_PtrSize ? ("ptr", ptrSize := A_PtrSize) : ("uint", ptrSize := 4)
		,LVM_GETCOLUMN := A_IsUnicode ? (4191, LVM_SETCOLUMN := 4192) : (4121, LVM_SETCOLUMN := 4122)
		,VarSetCapacity(lvColumn, ptrSize + 4), NumPut(1, lvColumn, "uint")
	c -= 1, DllCall("SendMessage", ptr, h, "uint", LVM_GETCOLUMN, "uint", c, ptr, &lvColumn)
	if ((fmt := NumGet(lvColumn, 4, "int")) & 1024) {
		if (d && d = "asc" || d = "up")
			return
		NumPut(fmt & ~1024 | 512, lvColumn, 4, "int")
	} else if (fmt & 512) {
		if (d && d = "desc" || d = "down")
			return
		NumPut(fmt & ~512 | 1024, lvColumn, 4, "int")
	} else {
		Loop % DllCall("SendMessage", ptr, DllCall("SendMessage", ptr, h, "uint", 4127), "uint", 4608)
			if ((i := A_Index - 1) != c)
				DllCall("SendMessage", ptr, h, "uint", LVM_GETCOLUMN, "uint", i, ptr, &lvColumn)
				,NumPut(NumGet(lvColumn, 4, "int") & ~1536, lvColumn, 4, "int")
				,DllCall("SendMessage", ptr, h, "uint", LVM_SETCOLUMN, "uint", i, ptr, &lvColumn)
		NumPut(fmt | (d && d = "desc" || d = "down" ? 512 : 1024), lvColumn, 4, "int")
	}
	return DllCall("SendMessage", ptr, h, "uint", LVM_SETCOLUMN, "uint", c, ptr, &lvColumn)
}

;------------------------------------ ACCESSIBILITY SHORTCUTS -------------------------------

;#if IsActive(PROGNAME " Clipboard History", "window")
;	F5::historyUpdate(blankvar, 0)
;#if
#if IsActive("Edit1", "classnn") and IsActive(PROGNAME " Clipboard History", "window")
	$Down::
		Controlfocus, SysListView321, A
		Send {Down}
		return
#if
#if ( IsActive("SysListView321", "classnn") and IsActive(PROGNAME " Clipboard History", "window") and ctrlRef!="pastemode" )
	Space::gosub history_InstaPaste
	^c::history_clipboard()
	^e::gosub history_exportclip
	Del::Send !t               ;Alt - shortcut for Delete
	!d::Send !f  			   ;Alt - shortcut for Search
	^f::Send !f
#if