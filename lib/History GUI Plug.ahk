;History Gui labels and functions
;A lot Thanks to chaz

gui_History()
; Creates and shows a GUI for managing and viewing the clipboard history
{
	global
	static x, y

	Gui, History:new
	Gui, Margin, 7, 7
	Gui, +Resize +MinSize390x110

	Gui, Add, Button, w75 h23 Section Default Disabled	vhistory_ButtonPreview	ghistory_ButtonPreview, &Preview
	Gui, Add, Button, x+6 ys w75 h23 Disabled			vhistory_ButtonDelete	ghistory_ButtonDelete, Dele&te item
	Gui, Add, Button, x+6 ys w75 h23 			vhistory_ButtonDeleteAll ghistory_ButtonDeleteAll, Clear &history
	Gui, Add, Text, x+15 ys+5 					vhistory_SearchText,	Search &Filter:
	Gui, Add, Edit, ys+1  	ghistory_SearchBox	vhistory_SearchBox
	;Gui, Font, s9, Courier New
	;Gui, Font, s9, Lucida Console
	Gui, Font, s9, Consolas
	Gui, Add, ListView, xs+1 AltSubmit HWNDhistoryLV ghistoryLV vhistoryLV LV0x4000, Clip|Date|Hiddendate

	Gui, Add, StatusBar,, % "Total Disk Consumption : " history_GetSize() " KB"
	Gui, Font
	;~ LV_Modify(1, "Focus")
	;~ LV_Modify(1, "Select")
	LV_ModifyCol(2, "Desc SortDesc")
	GuiControl, Focus, history_SearchBox

	;History Right-Click Menu
	Menu, HisMenu, Add, &Preview, history_ButtonPreview
	Menu, HisMenu, Add
	Menu, HisMenu, Add, % "&Copy        (Ctrl+C)", history_clipboard
	Menu, HisMenu, Add, % "&Insta-Paste (Shift+Enter)", history_InstaPaste
	Menu, HisMenu, Add
	Menu, HisMenu, Add, % "&Export Clip (Ctrl+E)", history_exportclip
	Menu, HisMenu, Add, &Delete, history_ButtonDelete
	Menu, HisMenu, Default, &Preview

	Iniread, w, % CONFIGURATION_FILE, Clipboard_History_window, w, %A_Space%
	Iniread, h, % CONFIGURATION_FILE, Clipboard_History_window, h, %A_Space%

	historyUpdate()

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
	LV_GetText(clip_file_path, LV_GetNext("", "Focused"), 3)
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
		LV_GetText(clip_file_path, A_LoopField, 3)
		, list_clipfilepath .= clip_file_path "`n" 	;Important for faster results

	;Delete Rows
	loop, parse, rows_selected,`,
		LV_Delete(A_LoopField+1-A_index)

	;Delete items
	loop, parse, list_clipfilepath, `n
		FileDelete, % "cache\history\" A_LoopField
	
	Guicontrol, History:Focus, history_SearchBox
	return

history_ButtonDeleteAll:
	Gui, +OwnDialogs
	MsgBox, 257, Clear History, Are you sure you want to permanently clear %PROGNAME%'s clipboard history?
	IfMsgBox, OK
	{
		FileDelete, cache\history\*
		historyUpdate()
	}
	return

history_SearchBox:
	Gui, History:Default
	Gui, History:Submit, NoHide
	historyUpdate(history_SearchBox, 0)
	return

historyLV:
	Gui, History:Default
	GuiControl, Enable, history_ButtonDelete
	GuiControl, Enable, history_ButtonPreview

	temp_row_s := 0 , temp_size := 0

	while ( temp_row_s := LV_GetNext(temp_row_s) )
	{
		LV_GetText(clip_file_path, temp_row_s, 3)
		temp_size+= ( clip_file_path == "" ) ? 0 : history_GetSize(clip_file_path)
	}

	if !temp_size
		temp_size := history_GetSize() , SB_SetText("Total Disk Consumption : " temp_size " KB")
	else
		SB_SetText("Selected Size : " temp_size " KB")


	if A_GuiEvent = DoubleClick
		gosub, history_ButtonPreview
	else if A_GuiEvent = ColClick
		LV_SortArrow(historyLV, A_EventInfo)
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
		gui_w := a_guiwidth
		gui_h := a_guiheight
		LV_ModifyCol(1, gui_w-215)
		GuiControl, Move, historyLV, % "w" (gui_w - 15) " h" (gui_h - 65)     ;+20 H in no STB
		GuiControl, Move, history_SearchBox, % "x330 w" (gui_w - 338)
	}
	return

historyGuiClose:
historyGuiEscape:
	Wingetpos, x, y, w, h, %PROGNAME% Clipboard History

	h := h > WORKINGHT ? WORKINGHT : h-36                 ;36 is a value with which h is increased when using Wingetpos

	Ini_write(temp_h := "Clipboard_History_window", "w", w, 0)
	Ini_write(temp_h, "h", h, 0)

	SendMessage, 0x1000+29, 0,	0, SysListView321, %PROGNAME% Clipboard History   ; 0x1000+29 is LVM_GETCOLUMNWIDTH
	w1 := ErrorLevel
	SendMessage, 0x1000+29, 1,	0, SysListView321, %PROGNAME% Clipboard History
	w2 := ErrorLevel
	Ini_write(temp_h, "w1", w1, 0)
	Ini_write(temp_h, "w2", w2, 0)

	Gui, History:Destroy
	Menu, HisMenu, Delete
	EmptyMem() 				;Free memory
	return
}


gui_History_Preview(mode, previewText = "")
; Creates and shows a GUI for viewing history items
{
	global
	
	Gui, Preview:New
	if mode = image
	{
		Gui, Margin, 0, 0
		Gui, Add, Picture, w530 h320 vhistory_pic, cache\history\%clip_file_path%
		history_Text_Act := false
	}
	else if mode = text
	{
		Gui, Margin, 8, 8
		Gui, Font, s9, Consolas
		Gui, Add, Edit, w530 h320 +ReadOnly -Wrap +HScroll vhistory_text, %previewText%
		Gui, Font
		history_Text_Act := true
	}
	Gui, Add, Button, x210 y340 w110 h23 gbutton_Copy_To_Clipboard Default, Copy to Clipboard

	Gui, Preview:+OwnerHistory
	Gui, History:+Disabled
	Gui, Preview: -MaximizeBox -MinimizeBox
	Gui, Preview:Show, AutoSize, Preview
	return
	
button_Copy_to_Clipboard:
	Gui, Preview:Submit, nohide
	if history_Text_Act
		Clipboard := history_text
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
	LV_GetText(clip_file_path, row_selected, 3)
	if !Instr(clip_file_path, ".jpg")
	{
		FileRead, temp_Read, cache\history\%clip_file_path%
		Clipboard := temp_Read
	}
	else
		Gdip_SetImagetoClipboard("cache\history\" clip_file_path)
}


historyUpdate(crit="", create=true)
; Update the history GUI listview
; create=false will prevent re-drawing of Columns , useful when the function is called in the SearchBox label and Gui Size is customized.
{
	LV_Delete()
	Loop, cache\history\*
	{
		if Instr(A_LoopFileFullPath, ".txt")
			Fileread, lv_temp, %A_LoopFileFullPath%
		else if Instr(A_LoopFileFullPath, ".jpg")
			lv_temp := MSG_HISTORY_PREVIEW_IMAGE
		else Continue
		
		if Instr(lv_temp, crit)
		{
			lv_Date := Substr(A_LoopFileName,1,4) "-" Substr(A_LoopFileName,5,2) "-" Substr(A_LoopFileName,7,2) "  "
						. Substr(A_LoopFileName,9,2) ":" Substr(A_LoopFileName,11,2) ":" Substr(A_LoopFileName, 13, 2)

			LV_Add("", lv_Temp, lv_Date, A_LoopFileName)	; not parsing here to maximize speed
		}
	}

	if create
	{
		Iniread, w1,% CONFIGURATION_FILE, Clipboard_History_window, w1, %A_Space%
		Iniread, w2,% CONFIGURATION_FILE, Clipboard_History_window, w2, %A_Space%
		LV_ModifyCol(1, w1?w1:485) , LV_ModifyCol(2, w2?w2:165) , Lv_ModifyCol(3, "0")
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

history_InstaPaste:
	history_clipboard()
	Gui, history:hide
	WinWaitClose, Clipjump Clipboard History
	Send, ^v
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
	FileAppend, %ClipboardAll%, %temp%
	CALLER := true 
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

#if IsActive("Edit1", "classnn")
	$Down::
		Controlfocus, SysListView321, A
		Send {Down}
		return
#if
#if ( IsActive("SysListView321", "classnn") and IsActive("Clipjump Clipboard History", "window") and ctrlRef!="pastemode" )
	+Enter::gosub history_InstaPaste
	^c::history_clipboard()
	^e::gosub history_exportclip
	Del::Send !t               ;Alt - shortcut for Delete
	!d::Send !f  			   ;Alt - shortcut for Search
	^f::Send !f
#if