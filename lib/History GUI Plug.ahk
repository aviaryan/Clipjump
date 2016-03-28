;History Gui labels and functions
;A lot Thanks to chaz who first improved it

/**
 * Creates and shows a GUI for managing and viewing the clipboard history
 * @return {void}
 */
gui_History(){
	global
	static x, y, how_sort := 2_sort := 3_sort := 0, what_sort := 2
	local selected_row, thisguisize
	hst_genWt := 750
	;2_3_sort are the vars storing how cols are sorted , 1 means in Sort ; 0 means SortDesc

	Gui, History:new
	Gui, Color, F6F8E1
	Gui, Margin, 7, 7
	Gui, +Resize +MinSize500x300

	Iniread, history_w, % CONFIGURATION_FILE, Clipboard_History_window, w, %A_Space%
	Iniread, h, % CONFIGURATION_FILE, Clipboard_History_window, h, %A_Space%

	Gui, Add, Button, h23 Section Default	vhistory_ButtonPreview	ghistory_ButtonPreview, % TXT.HST_preview
	Gui, Add, Button, x+6 ys h23			vhistory_ButtonDelete	ghistory_ButtonDelete, % TXT.HST_del
	Gui, Add, Button, x+6 ys h23 			vhistory_ButtonDeleteAll ghistory_ButtonDeleteAll, % TXT.HST_clear
	Gui, Add, Text, x+35 ys+5 					vhistory_SearchText, % TXT.HST_search
	Gui, Add, Checkbox, x+10 ys+5 Checked%history_partial% vhistory_partial ghistory_SearchBox, % TXT.HST_partial
	Gui, Add, Edit, ys  	ghistory_SearchBox	vhistory_SearchBox
	Gui, Font, s9, Courier New
	Gui, Font, s9, Consolas
	Gui, Add, ListView, % "xs+1 HWNDhistoryLV ghistoryLV vhistoryLV LV0x4000 w" (history_w ? history_w-25 : hst_genWt-25) , % TXT.HST_clip "|" TXT.HST_date "|" TXT.HST_size "|Hiddendate"

	Gui, Add, StatusBar
	Gui, Font
	GuiControl, Focus, history_SearchBox

	;History Right-Click Menu
	Menu, HisMenu, Add, % TXT.HST_m_prev , history_MenuPreview
	Menu, HisMenu, Add
	;Use a Space and a tab to separate
	Menu, HisMenu, Add, % TXT.HST_m_copy , history_clipboard
	Menu, HisMenu, Add, % TXT.HST_m_insta , history_InstaPaste
	Menu, HisMenu, Add, % TXT.SET_HoldClip " `t(" TXT["_!c"] ")", history_HoldClip
	Menu, HisMenu, Add, % TXT.HST_m_edit , history_EditClip
	Menu, HisMenu, Add, % TXT.HST_m_export , history_exportclip
	Menu, HisMenu, Add
	Menu, HisMenu, Add, % TXT.HST_m_ref, history_SearchBox
	Menu, HisMenu, Add, % TXT.HST_m_del, history_ButtonDelete 
	Menu, HisMenu, Default, % TXT.HST_m_prev

	historyUpdate()
	history_UpdateSTB()
	LV_ModifyCol(what_sort, how_sort ? "Sort" : "SortDesc")

	if ((h+0) == WORKINGHT)
	{
		Gui, History:Show, Maximize, % PROGNAME " " TXT.HST__name
		WinMinimize, % PROGNAME " " TXT.HST__name
		WinMaximize, % PROGNAME " " TXT.HST__name
		GuiControl, focus, history_SearchBox
	}
	else
		Gui, History:Show,% ( x ? "x" x " y" y : "" ) " w" (history_w?history_w:hst_genWt) " h" (h?h:500), % PROGNAME " " TXT.HST__name

	WinWaitActive, % PROGNAME " " TXT.HST__name
	WinGetPos, x, y

	;resize the search box
	GuiControlGet, history_SearchBox, History:pos 		;extract x for later use
	WinGetPos,,, thisguisize,, % PROGNAME " " TXT.HST__name
	GuiControl, Move, history_SearchBox, % "w" (thisguisize- history_Searchboxx - 21) 		;7,7 for outer border, 7 for inner border

	;create hotkeys
	Hotkey, IfWinActive, % PROGNAME " " TXT.HST__name
	Hotkey, F5, history_SearchBox, On
	Hotkey, If
	Hotkey, If, IsHisListViewActive()
	hkZ("^c", "history_clipboard")
	hkZ("^e", "history_exportclip")
	hkZ("^h", "history_EditClip")
	hkZ("!d", "historySearchfocus")
	hkZ("^f", "historySearchfocus")
	hkZ("!c", "history_holdClip")
	Hotkey, If
	Hotkey, If, IsPrevActive()
	hkZ("^f", "prevSearchfocus")
	Hotkey, If
	return

/**
 * label to invoke preview button
 */
history_MenuPreview:
	Send {vk0d}
	return

/**
 * label triggered when search box contents are changed and then updates the list
 */
history_SearchBox:
	Critical, On
	Gui, History:Default
	Gui, History:Submit, NoHide
	historyUpdate(history_SearchBox, 0, history_partial)
	LV_ModifyCol(what_sort, how_sort ? "Sort" : "SortDesc") 		;sort column correctly
	return

/**
 * trigerred when button preview is pressed
 * opens the preview window
 */
history_ButtonPreview:
	Gui, History:Default
	Gui, submit, nohide
	if (LV_GetNext() == "0")
		v := selected_row
	else v := LV_GetNext()

	LV_GetText(clip_id, v, hidden_date_no)
	if (HISTORYOBJ[clip_id] == 0){ ;type text
		data := getFromTable("history", "data", "id=" clip_id)
		clip_data := data[1]
		genHTMLforPreview(clip_data)
		gui_Clip_Preview(PREV_FILE, history_searchbox)
	} else {
		data := getFromTable("history", "fileid", "id=" clip_id)
		gui_Clip_Preview(path := data[1], history_SearchBox)
	}
	return

history_ButtonDelete:
	history_ButtonDelete()
	return

/**
 * button event to delete all history
 */
history_ButtonDeleteAll:
	Gui, +OwnDialogs
	MsgBox, 257, Clear History,% TXT.HST_delall_msg
	IfMsgBox, OK
	{
		FileDelete, cache\history\*
		execSql("delete from history")
		historyUpdate()
		history_UpdateSTB()
	}
	return

/**
 * list view (clips list) handler
 * responsible for sorting and stuff
 */
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

/**
 * method to allow editing a history clip
 */
history_EditClip: 		; label inside to call history_searchbox which uses local func variables
	Gui, History:Default
	LV_GetText(clip_id, LV_GetNext(0), hidden_date_no)
	if (HISTORYOBJ[clip_id] == 1){
		data := getFromTable("history", "fileid", "id=" clip_id)
		runwait % ini_defImgEditor " """ A_WorkingDir "\" data[1] """"
	} else {
		data := getFromTable("history", "data", "id=" clip_id)
		STORE.ErrorLevel := 0
		out := multInputBox("Edit Clip", "Make your changes and then click OK", 10, data[1], "History")
		if (STORE.ErrorLevel == 1){
			execSql("update history set data=""" escapeQuotesSql(out) """ where id=" clip_id, 1)
		}
	}
	gosub history_SearchBox
	return

/**
 * add the selected history clip to holdclip
 */
history_HoldClip:
	while !IsHisListViewActive()
		sleep 50
	Gui, History:Default
	LV_GetText(clip_id, LV_GetNext(0), hidden_date_no)
	data := getFromTable("history", "data", "id=" clip_id)
	STORE.holdClip_preText := data[1]
	gosub holdclip
	return

/**
 * context menu history gui
 * reponsible for showing right click on clip menu
 */
historyGuiContextMenu:
	if (A_GuiControl != "historyLV") or (LV_GetNext() = 0)
		return
	selected_row := LV_GetNext()
	Menu, HisMenu, Show, %A_GuiX%, %A_GuiY%
	return

/**
 * gui resize handler
 */
historyGuiSize:
	if (A_EventInfo != 1)	; ignore minimising
	{
		gui_w := a_guiwidth , gui_h := a_guiheight

		SendMessage, 0x1000+29, 1,	0, SysListView321, % PROGNAME " " TXT.HST__name
		w2 := ErrorLevel
		SendMessage, 0x1000+29, 2,	0, SysListView321, % PROGNAME " " TXT.HST__name
		w3 := ErrorLevel

		GuiControl, Move, historyLV, % "w" (gui_w - 15) " h" (gui_h - 65)     ;+20 H in no STatus Bar
		LV_ModifyCol(1, gui_w-15-w2-w3-25) 				;gui_w - x  where   x  =  width of all cols + 25
		GuiControl, Move, history_SearchBox, % " w" (gui_w - (history_SearchBoxx ?  history_SearchBoxx : hst_genWt-300)  -7) ; 7 for innermargin
	}
	return

/**
 * gui close handler
 * saves the position, height, width and exits
 */
historyGuiClose:
historyGuiEscape:
	Wingetpos, x, y,, h, % PROGNAME " " TXT.HST__name

	h := h > WORKINGHT ? WORKINGHT : gui_h               ;gui_h and gui_w are function vars created in the historyGUISIze label (above).

	Ini_write(temp_h := "Clipboard_History_window", "w", gui_w, 0)
	Ini_write(temp_h, "h", h, 0)

	SendMessage, 0x1000+29, 1,	0, SysListView321, % PROGNAME " " TXT.HST__name
	w2 := ErrorLevel
	SendMessage, 0x1000+29, 2,	0, SysListView321, % PROGNAME " " TXT.HST__name
	w3 := ErrorLevel
	Ini_write(temp_h, "w2", w2, 0)
	Ini_write(temp_h, "w3", w3, 0)

	Gui, History:Destroy
	Menu, HisMenu, DeleteAll
	EmptyMem() 				;Free memory
	return
}

/**
 * shows the preview of a clip
 * param path - path to the html file of the clip generated disk or path to jpg file for image
 * param searchbox - searchbox content of the history gui, same is shown in preview
 * param owner - owner of gui
 */
gui_Clip_Preview(path, searchBox="", owner="History")
{
	global prev_copybtn, prev_findtxt, prev_handle, preview_search, prev_picture, preview, prev_findtxtw
	static wt := A_ScreenWidth / 2.2 , ht := A_ScreenHeight / 2.5 ;, maxlines = Round(ht / 13)
	preview := {}

	preview.isimg := Instr(Substr(path, -2), "jpg") ? 1 : 0
	preview.path := A_workingdir "\" path
	preview.owner := owner

	Gui, Preview:New
	Gui, Margin, 0, 0

	if preview.isimg
	{
		Gui, Add, Picture, w%wt% h%ht% vprev_picture, 
		Gdip_getlengths(preview.path, w, h)
		preview.w := w , preview.h := h
		wf := preview.w/wt , hf := preview.h/ht
		if (wf>=hf) && (wf>1)
			wn := preview.w/wf , hn:= preview.h/wf
		else if (hf>wf) && (hf>1)
			wn := preview.w/hf , hn := preview.h/hf
		else
		 	wn := preview.w , hn := preview.h
		GuiControl, , prev_picture,% " *w" wn " *h" hn " " preview.path
	}
	else
	{
		try {
			Gui, Add, ActiveX, w%wt% h%ht% vprev_handle, Shell.Explorer
			ComObjConnect(prev_handle, new ActiveXEvent) 				;do this only when the previous one succeeds
		}
		try prev_handle.Navigate( preview.path )
	}

	Gui, Font, s11
	Gui, Add, Button, % "x5 y+10 h27 gbutton_Copy_To_Clipboard Default vprev_copybtn Section", % TXT.PRV_copy
	; button's x till 130 , search's width will 200 p from right
	Gui, Add, Text, % "x" wt-200 " yp+2 h23 vprev_findtxt", % TXT.PRV_find 		; +2 to level text
	Gui, Font, norm
	Gui, Add, Edit, % "x+10 yp-2 w155 h23 vpreview_search gpreviewSearch " ( preview.isimg ? "+ReadOnly" : "" ),  	; -5 margin on right side
	Gui, Add, Text, x5 y+0 w5 			; white-space just below the button

	Gui, Preview:+Owner%owner%
	Gui, % preview.owner ":+Disabled"
	Gui, Preview: +Resize +MaximizeBox -MinimizeBox
	Gui, Preview:Show, AutoSize, % TXT.PRV__name

	GuiControlGet, prev_findtxt, Preview:Pos
	if !preview.isimg
		GuiControl, , preview_search, % searchBox
	return

/**
 * copy previewed clip to clipboard
 */
button_Copy_to_Clipboard:
	Gui, Preview:Submit, nohide
	if !preview.isimg
		try Clipboard := prev_handle.Document.body.innerText
	else
		Gdip_SetImagetoClipboard(preview.path)
	sleep 500
	gosub, previewGuiClose
	return

/**
 * close preview gui
 */
previewGuiClose:
previewGuiEscape:
	Gui, % preview.owner ":-Disabled"
	Gui, Preview:Destroy
	prev_handle := ""
	prev_document := ""
	EmptyMem()
	return

/**
 * search in preview gui
 * highlights the matches too
 */
previewSearch:
	Critical
	Gui, submit, nohide
	prev_document := prev_handle.Document.body.createTextRange
	prev_document.execCommand("BackColor", 0, "White")
	preview_search := Trim(preview_search, A_space)
	if preview_search =
		return

	try {
	;highlight partial matches
	if history_partial
		loop, parse, preview_search, %A_space%, %A_space%
		{
			while prev_document.findtext(A_LoopField)
				prev_document.execCommand("BackColor", 0, "Aqua")        
				, prev_document.Collapse(0)
			prev_document := prev_handle.Document.body.createTextRange
		}

	;highlight exact matches
	while prev_document.findtext(preview_search)
		prev_document.execCommand("BackColor", 0, "Yellow")        
		, prev_document.Collapse(0) 

	}
	return

/**
 * preview gui resize handler
 */
PreviewGuiSize:
	if (A_EventInfo != 1)
	{
		gui_w := A_GuiWidth , gui_h := A_GuiHeight
		GuiControl, move, preview_search, % "x" gui_w-160 " y" gui_h-30
		GuiControl, move, prev_findtxt, % "x" gui_w- (prev_findtxtw ? prev_findtxtw+167 : 210) " y" gui_h-30
		GuiControl, move, prev_copybtn, % "y" gui_h-32
		if !preview.isimg
			GuiControl, move, prev_handle, % "w" gui_w " h" gui_h-42
		else {
			GuiControl, move, prev_handle, % "w" gui_w " h" gui_h-42

			wn := gui_w , hn := gui_h-42
			if (gui_w+0)>preview.w
				wn := preview.w
			if (gui_h-42)>preview.h
				hn := preview.h
			
			GuiControl, , prev_picture, % "*w" wn " *h" hn " " preview.path
		}
	}
	return

}

/**
 * transfers the selected item from listview to clipboard
 * @param  {Number} startRow row to start searching the selected clip. 0
 * @return {Number} selected clip row no
 */
history_clipboard(sTartRow=0){
	Gui, History:Default
	row_selected := LV_GetNext(sTartRow)
	if !row_selected
		return 0
	LV_GetText(clip_id, row_selected, hidden_date_no)

	if (HISTORYOBJ[clip_id] == 0) {
		FileRead, temp_Read, cache\history\%clip_id%
		temp_read := getFromTable("history", "data", "id=" clip_id)[1]
		try Clipboard := temp_Read
	} else if (HISTORYOBJ[clip_id] == 1) { ; in case row_selected=0 , this case ensures the code is not executed
		filepath := getFromTable("history", "fileid", "id=" clip_id)[1]
		Gdip_SetImagetoClipboard(filepath)
	}
	return row_selected
}

/**
 * updates the clipboard history window list wrt search filter
 * @param  {String}  crit    search filter
 * @param  {Boolean} create  create the gui, useful for first time
 * @param  {Boolean} partial perform partial search
 * @return {void}
 */
historyUpdate(crit="", create=true, partial=false){
	; Updates the clipboard history window list
	; works when search content is changed
	local totalSize := 0
	local result, Row

	LV_Delete()
	func := Func(partial ? "Superinstr" : "Instr") , thirdpm := partial ? 1 : 0		;The third param 0 has diff meanings in both cases

	crit := trim(crit)
	if (crit == ""){
		q := "select * from history"
	} else if partial {
		likestr := ""
		loop, parse, crit, % " `t", % " `t"
			likestr .= "data like ""%" A_loopfield "%"" and "
		likestr := Substr(likestr, 1, -4)
		q := "select * from history where " likestr
	} else {
		q := "select * from history where data like ""%" crit "%"""
	}

	result := ""
	if !DB.GetTable(q, result)
		msgbox error
	loop % result.RowCount
	{
		result.Next(Row)
		clipdata := Row[2] ;data
		clipdate := Row[5]
		totalsize += ( clipsize := Row[6] )
		LV_Add("", clipdata, clipdate, clipsize, Row[1])
		HISTORYOBJ[Row[1]] := Row[3]
	}

	history_UpdateSTB("" totalSize/1024)

	if create
	{
		Iniread, w2,% CONFIGURATION_FILE, Clipboard_History_window, w2, 155
		Iniread, w3,% CONFIGURATION_FILE, Clipboard_History_window, w3, 70
		w1 := (history_w - 15 - w2 - w3)
		LV_ModifyCol(1, w1) , LV_ModifyCol(2, w2?w2:155) , Lv_ModifyCol(3, (w3?w3:70) " Integer") , Lv_ModifyCol(4, "0")
	}
}

/**
 * reutrns the size of history
 * @param  {String} option no idea
 * @return {number} size in kb
 */
history_GetSize(option := ""){
	If (option == ""){
    	data := getFromTable("history", "sum(size)", "id>-1")
    	R := data[1]
	} else {

	}

    return R/1024
}

/**
 * update size in status bar
 * @param  {String} size size to show
 * @return {void}
 */
history_UpdateSTB(size=""){
	; If size is passed, that size is used
	Gui, History:Default
	SB_SetText(TXT.HST_dconsump " : " ( size="" ? history_GetSize() : size ) " KB")
}

/**
 * deletes selected rows from history
 * @return {void}
 */
history_ButtonDelete(){
	Gui, History:Default

	temp_row_s := 0 , rows_selected := "" , list_clipfilepath := ""
	while (temp_row_s := Lv_GetNext(temp_row_s))
		rows_selected .= temp_row_s ","
	rows_selected := Substr(rows_selected, 1, -1)     ;get CSV row numbers

	;Get Row names
	loop, parse, rows_selected,`,
		LV_GetText(clip_id, A_LoopField, hidden_date_no)
		, list_clipfilepath .= clip_id "`n" 	;Important for faster results
	;Delete Rows
	loop, parse, rows_selected,`,
		LV_Delete(A_LoopField+1-A_index)
	;Delete items
	loop, parse, list_clipfilepath, `n
	{
		deleteHistoryById(A_loopfield)
	}
	
	Guicontrol, History:Focus, history_SearchBox
	history_UpdateSTB()
}

/**
 * history insta paste feature
 */
history_InstaPaste:
	IniRead, clipboard_instapaste, % CONFIGURATION_FILE, Advanced, Instapaste_write_clipboard, %A_Space%
	WinHide, % PROGNAME " " TXT.HST__name
	temp_curRow := 0
	loop {
		if clipboard_instapaste
			temp_curRow := history_clipboard(temp_curRow)
		else
			API.blockMonitoring(1)
			, IScurCBACTIVE := 0  			;cur Clipboard is no longer active
			, temp_curRow := history_clipboard(temp_curRow)
		if !temp_curRow
			break
		SendInput, % ( A_index>1 ? "{Enter}" : "" ) "^{vk56}"
		sleep 110
	}
	API.blockMonitoring(0)
	if ini_HisCloseOnInstaPaste
	{
		WinClose, % PROGNAME " " TXT.HST__name
		WinWaitClose, % PROGNAME " " TXT.HST__name
	} else {
		sleep 200 	; extra layer
		WinShow, % PROGNAME " " TXT.HST__name
	}
	return

/**
 * exports selected clip
 * gets the clip from clipboard
 */
history_exportclip:
	CALLER := 0 , ONCLIPBOARD := ""
	history_clipboard()
	while !ONCLIPBOARD 				;wait for onclibboard to be breached
		sleep 50
	ClipWait, ,1
	loop
		if !FileExist(temp := A_MyDocuments "\export" A_index ".cj")
			break
	try FileAppend, %ClipboardAll%, %temp%
	CALLER := CALLER_STATUS
	MsgBox, 64, % PROGNAME " " TXT.HST__name, % "Selected Clip " TXT._exportedto "`n" temp
	return


; by Jethrow
; Helps in copy and paste in Shell Explorer
class ActiveXEvent {
	DocumentComplete(prev_handle) {
		static doc
		ComObjConnect(doc:=prev_handle.document, new ActiveXEvent)
	}
	OnKeyPress(doc) {
		static keys := {1:"selectall", 3:"copy", 22:"paste", 24:"cut"}
		keyCode := doc.parentWindow.event.keyCode
		if keys.HasKey(keyCode)
			Doc.ExecCommand(keys[keyCode])
	}
}


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


; --------------------------- SQL STORAGE FUNCTIONS --------------------------------------

createHisTable(){
; creates the History Table if it doesnt exist
; called by the migrateHistory function
	q = 
	(
		CREATE TABLE if not exists history `(
		id	INTEGER PRIMARY KEY AUTOINCREMENT,
		data 	TEXT,
		type	INTEGER,
		fileid 	TEXT,
		time	TEXT,
		size 	INTEGER
		`)
	)
	if !DB.Exec(q)
		msgbox % "db create history table"
}

addHistoryText(data, timestamp){
; adds some text data to history
; the timestamp is in A_Now format
	timestamp := convertTimeSql( timestamp )
	q := "insert into history (data, type, time, size) values (""" 
		. escapeQuotesSql(data)
		. """, 0, """ 
		. timestamp """, "
		. fileSizeFromStr(data) ")"
	if (!DB.Exec(q))
		msgbox % q
}

addHistoryImage(imgpath, timestamp){
; addes image to history
; image specified by image path (imgpath)
; timestamp is in A_Now format
	timestamp := convertTimeSql(timestamp)
	fptr := FileOpen(imgpath, "r")
	size := fptr.Length
	fptr.Close()
	while (FileExist(rname := "cache\history\" getRandomStr(15) ".jpg")){
		; loop till new file name
	}

	FileCopy, % imgpath, % rname
	q := "insert into history (data, type, time, size, fileid) values ("
		. """[IMAGE]"", " 
		. 1 ","
		. """" timestamp """, "
		. size ", "
		. """" rname """)"

	If !DB.Exec(q)
		MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
}

deleteHistoryById(id){
; deletes a history element by its ID in the table
	if (HISTORYOBJ[id] == 1){
		imgpath := getFromTable("history", "fileid", "id=" id)[1]
		FileDelete, % imgpath
	}
	execSql("delete from history where id=" id)
}

fillHISTORYOBJ(){
; fills the HISTORYOBJ array
; It contains ID v/s type information
; HISTORYOBJ[ID] = type ( 0 or 1 )
	local result
	q := "select id,type from history"
	result := ""
	if !DB.GetTable(q, result)
		msgbox error
	loop % result.RowCount
		HISTORYOBJ[Row[1]] := Row[2]
}

;------------------------------------ MIGRATE ----------------------------------------------

migrateHistory(){
; migrates History files to the database
	createHisTable()
	DB.Exec("BEGIN TRANSACTION")
	API.showTip("Moving history files to database. This process may take some time.")
	loop, cache\history\*
	{
		if (strlen(A_LoopFileName) != 18) ; YYYYMMDDHHMMSS.ext
			continue
		if (A_LoopFileExt == "jpg"){
			addHistoryImage(A_LoopFileFullPath, Substr(A_LoopFileName,1,-4))
			FileDelete, % A_LoopFileFullPath
		} else if (A_LoopFileExt == "txt"){
			FileRead, tdata, % A_LoopFileFullPath
			addHistoryText(tdata, Substr(A_LoopFileName,1,-4))
			FileDelete, % A_LoopFileFullPath
		}
	}
	DB.Exec("COMMIT TRANSACTION")
	API.removeTip()
}

;------------------------------------ ACCESSIBILITY SHORTCUTS -------------------------------

historySearchfocus:
	GuiControl, History:focus, history_SearchBox
	return
prevSearchfocus:
	GuiControl, Preview:focus, preview_search
	return
; Using these function so that #if is created properly and hotkey command works and so no errors in non-eng computers
IsHisListViewActive(){
	return IsActive("SysListView321", "classnn") && IsActive(PROGNAME " " TXT.HST__name, "window") && ctrlRef==""
}
IsPrevActive(){
	return Winactive(TXT.PRV__name " ahk_class AutoHotkeyGUI") && ctrlRef==""
}

#if IsActive("Edit1", "classnn") and IsActive(PROGNAME " " TXT.HST__name, "window")
	$Down::
		Gui, History:Default
		GuiControl, focus, historyLV
		LV_Modify(1, "Select Focus")
		return
#if
#if IsHisListViewActive()
	Space::gosub history_InstaPaste
	Del::history_ButtonDelete()
#if
#if IsPrevActive()
#if
#if ( IsActive(PROGNAME " " TXT.HST__name, "window") and ctrlRef=="" )
	MButton::
	KeyWait, Mbutton
	Click
	sleep 50
	gosub history_InstaPaste
	return
#if