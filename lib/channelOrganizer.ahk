/* *****************
  Channel Organizer
 * *****************
*/

/**
 * Label to open channel organizer gui
 */
channelOrganizer:
	channelOrganizer()
	return


/**
 * Function to open channel organizer gui
 * @return {void}
 */
channelOrganizer(){
	global
	static chOrg_Lb, chOrg_search, chOrg_Lv
	static Width, Height, w_ofSearch 	; // Needed to make widths and hts save
	static t_horizButtons := 8 , t_startBtn := 2, t_commonBtn := 3

	wt := ini_read("Organizer", "w") , ht := ini_read("Organizer", "h")
	if !wt
		wt := A_ScreenWidth>1300 ? 900 : 750
	if !ht
		ht := A_ScreenHeight>800 ? 500 : 400
	w_ofSearch := getControlInfo("button", TXT.HST_search, "w", "s10")

	;enable tooltips
	OnMessage(0x200, "WM_MOUSEMOVE")

	Gui, chOrg:New
	Gui, +Resize +MinSize850x500
	Gui, Color, D2D2D2
	Gui, Font, s10
	Gui, Add, Text, % "x" wt - w_ofSearch - 200 " y10", % TXT.HST_search
	Gui, Font, s9
	Gui, Add, Edit, % "x" wt-200 " yp w200 vchOrg_search gchOrg_search", 		; width of EDIT is fixed = 200
	Gui, Font, s10
	Gui, Add, Button, % "x" 5+115+4+30+4 " yp vchorgNew gchorgNew ", % TXT.ORG_NewClip
	Gui, Add, Text, x+30 yp+4, % TXT.ORG_chooseCh
	Gui, Add, DropDownList, x+10 w150 yp-3 vchorg_useCh gchorg_useCh,
	gosub chOrg_addChUseList
	Gui, Add, ListBox, section x5 y+10 w115 h%ht% gchOrg_Lb vchOrg_Lb -LV0X10 AltSubmit, ;% "|" chList 	; width of LB is fixed = 115
	gosub chOrg_addChList

	Gui, Font, s16, github-octicons
	Gui, Add, Button, x+4 yp+20 w30 h35 +Disabled, % chrhex("f040")
	Gui, Add, Button, xp y+20 w30 gchOrgUp vchOrgUp, % chrhex("f03d")			; buttons width = 30
	Gui, Add, Button, xp y+2 w30 gchOrgDown vchOrgDown, % chrhex("f03f")
	Gui, Add, Button, xp y+2 w30 gchOrgEdit vchOrgEdit, % chrhex("f058")
	Gui, Add, Button, xp y+2 w30 gchorg_openPastemode vchorg_openPastemode, % chrhex("f032")
	Gui, Add, Button, xp y+2 w30 gchOrg_props vchOrg_props, % chrhex("f015")
	Gui, Add, Button, xp y+2 w30 gchOrgCut vchOrgCut, % chrhex("f035")
	Gui, Add, Button, xp y+2 w30 gchOrgCopy vchOrgCopy, % chrhex("f04d")
	Gui, Add, Button, xp y+2 w30 gchOrgDelete vchOrgDelete, % chrhex("f0d0")
	; x = 5+115 + 4 + 30 = 154 + 4
	Gui, Font
	Gui, Add, ListView, % "x+4 ys -E0x200 w" wt-158 " h" ht " HWNDchOrg_Lv vchOrg_Lv gchOrg_Lv", % "Ch|#|" TXT.HST_clip
	LV_ModifyCol(1, "30 Integer") , LV_ModifyCol(2, "30 Integer") , LV_ModifyCol(3, wt-158 -60 -10)
	Gui, Add, StatusBar
	SB_SetParts(5+115)
	Gui, chOrg:Show,, % TXT.ORG__name

	GuiControl, chOrg:Choose, chOrg_Lb, % ini_OpenAllChByDef ? 1 : CN.NG+2
	gosub chOrg_Lb
	GuiControl, chOrg:+AltSubmit, chOrg_Lv
	; Gui Done

	; // MENU LV
	Menu, chOrgLVMenu, Add, % TXT.HST_m_prev, chOrg_preview
	Menu, chOrgLVMenu, Add
	Menu, chOrgLVMenu, Add, % TXT.ORG_m_insta, chOrg_paste
	Menu, chOrgLVMenu, Add, % TXT.PLG_properties, chOrg_props
	Menu, chOrgLVMenu, Add, % TXT.ORG_m_openPst, chOrg_openPasteMode
		Menu, chOrgSubM, Add, % TXT.HST_m_edit, chOrgEdit
		Menu, chOrgSubM, Add, % TXT.ORG_m_inc , chOrgUp
		Menu, chOrgSubM, Add, % TXT.ORG_m_dec , chOrgDown
		Menu, chOrgSubM, Add, % TXT.TIP_move "    (" TXT["_!x"] ")", chOrgCut
		Menu, chOrgSubM, Add, % TXT.TIP_copy "    (" TXT["_!c"] ")" , chOrgCopy
	Menu, chOrgLVMenu, Add, % TXT._more_options, :chOrgSubM
	Menu, chOrgLVMenu, Add
	Menu, chOrgLVMenu, Add, % TXT.HST_m_ref, chOrg_refresh
	Menu, chOrgLVMenu, Add, % TXT.HST_m_del, chOrgDelete
	Menu, chOrgLVMenu, Default, % TXT.HST_m_prev

	; // MENU LB
	Menu, chOrgLBMenu, Add, % TXT._new, chOrgNewCh
	Menu, chOrgLBMenu, Add, % TXT.ORG_m_inc, chOrgUp
	Menu, chOrgLBMenu, Add, % TXT.ORG_m_dec, chOrgDown
	Menu, chOrgLBMenu, Add, % TXT._rename " (F2)", chOrg_renameCh
	Menu, chOrgLBMenu, Add, % TXT.HST_m_del, chOrgDelete

	; Hotkeys
	Hotkey, If, IsChorgActive()
	hkZ("F5", "chOrg_refresh")
	hkZ("^f", "chOrg_searchfocus")
	hkZ("^n", "chOrgNew")
	hkZ("^+n", "chOrgNewCh")
	hkZ("^g", "chOrg_useChFocus")
	hkZ("!a", "chOrg_activateLB")
	hkZ("!s", "chOrg_activateLV")
	Hotkey, If
	Hotkey, If, IsChOrgLVActive()
	hkZ("Enter", "chOrg_preview")
	hkZ("Space", "chOrg_paste")
	hkZ("!Enter", "chOrg_props")
	hkZ("^o", "chOrg_openPasteMode")
	hkZ("^h", "chOrgEdit")
	hkZ("Del", "chOrgDelete")
	hkZ("!Up", "chOrgUp")
	hkZ("!Down", "chOrgDown")
	hkZ("!x", "chOrgCut")
	hkZ("!c", "chOrgCopy")
	Hotkey, If
	Hotkey, If, IsChOrgLBActive()
	hkZ("Del", "chOrgDelete")
	hkZ("!Up", "chOrgUp")
	hkZ("!Down", "chOrgDown")
	hkZ("F2", "chOrg_renameCh")
	Hotkey, If
	Hotkey, If, IsChOrgSearchActive()
	hkZ("Tab", "chOrg_activateLV")
	Hotkey, If
	Hotkey, If, IsPrevActive()
	hkZ("^f", "prevSearchfocus")
	Hotkey, If
	return

/**
 * add channel list to the listbox
 */
chOrg_addChList:
	chList := RegexReplace( Trim( channel_find(), "`n" ), "`n", "|" )
	Sort, chList, D| N
	GuiControl, chOrg:, ListBox1, % "||" chList
	return

/**
 * gui resize handler
 */
chOrgGuiSize:
	if (A_EventInfo != 1){
		gui_w := A_GuiWidth , gui_h := A_GuiHeight
		GuiControl, move, SysListView321, % "w" gui_w-158-5-2 " h" gui_h-80
		GuiControl, move, ListBox1, % "h" gui_h-80
		GuiControl, move, Edit1, % "x" gui_w-200-5
		GuiControl, movedraw, Static1, % "x" gui_w- w_ofsearch-200-5
		width := gui_w-158-5-2
		height := gui_h-80
		LV_ModifyCol(3, Width -60 -10)
	}
	return

/**
 * context menu handler
 */
chOrgGuiContextMenu:
	if (A_GuiControl == "chOrg_Lv")
		Menu, chOrgLVMenu, Show, %A_GuiX%, %A_GuiY%
	else if (A_GuiControl == "chOrg_Lb")
	{
		gosub chOrg_isChActive
		if isChActive
			Menu, chOrgLBMenu, Show, %A_GuiX%, %A_GuiY%
	}
	return

/**
 * gui close/exit handler
 */
chOrgGuiEscape:
chOrgGuiClose:
	Ini_write("Organizer", "w", width+158-5-2+2, 0) , Ini_write("Organizer", "h", height+2, 0) 	; +2 dont know why
	Gui, chOrg:Destroy
	Menu, chOrgLVMenu, DeleteAll
	Menu, chOrgLBMenu, DeleteAll
	Menu, chOrgSubM, DeleteAll
	OnMessage(0x200, "") 		; This will conflict in case both settings and chorg are active at the same time
	Tooltip,,,, 4
	EmptyMem()
	return

/**
 * label to handle up/down of clips and channels
 */
chOrgUp:
chOrgDown: 	; dont make these labels critical
	Gui, chorg:Default
	t_Up := A_ThisLabel="chOrgUp" ? 1 : 0
	gosub chOrg_isChActive
	if !isChActive {
		gosub chOrg_getSelected
		if Instr(rSel, "`n")
		{
			chOrg_notification(TXT.ORG_error)
			return
		}
		temp_row_s := LV_GetNext(0)
		;while (temp_row_s := LV_GetNext(temp_row_s)) {
			LV_GetText(fch, temp_row_s, 1) , LV_GetText(fcl, temp_row_s, 2)
			spRow := t_Up ? temp_row_s-1 : temp_row_s+1
			if (fcl==1) && (t_Up==1) 	; 1st clip not go up - thanks to fump2000
				return
			sch := scl := ""
			LV_GetText(sch, spRow, 1) , LV_GetText(scl, spRow, 2)
			if (sch != "") {
				chOrg_clipSwap(fch, fcl, sch, scl)
				LV_GetText(ftxt, temp_row_s, 3) , LV_GetText(stxt, spRow, 3)
				Gui, chOrg:Default
				LV_Modify(temp_row_s, "", fch, fcl, stxt) 		; // change only 3rd col.. 
				LV_Modify(SprOW,"", sch, scl, ftxt)
				LV_Modify(temp_row_s, "-Select -Focus")
				LV_Modify(spRow, "Select")
			}
		;}
	} else {
		gosub chorg_getChSelected
		nCh := chSel + (t_Up ? -1 : 1)
		if chOrg_clipFolderSwap(chSel, nCh){
			gosub chOrg_addChList
			gosub chOrg_addChUseList
		}
	}
	return

/**
 * clip/channel delete handler
 * also allows emptying a channel
 */
chOrgDelete:
	Critical
	gosub chOrg_isChActive
	if !isChActive {
		gosub chOrg_getSelected
		tobj := {}
		loop, parse, rSel, % "`n"
		{
			k := Substr(A_LoopField, 1, Instr(A_LoopField, "-")-1) , v := Substr(A_LoopField, Instr(A_LoopField, "-")+1)
			tobj[k] .= v "`n"
		}
		; Sort and delete
		for k,v in tobj
		{
			Sort, v, % "N R" ; reverse
			v := Trim(v)
			loop, parse, v, % "`n"
			{
				if (Trim(A_LoopField) == "")
					continue
				API.deleteClip(k, A_LoopField)
				z := A_LoopField
				lvgcb := LV_GetCount()
				cons := 0
				loop % lvgcb ; Silent delete
				{
					LV_GetText(tch, A_index+cons, 1)
					if (tch != k)
						continue
					LV_GetText(tcl, A_index+cons, 2)
					if (tcl < z)
						continue
					if (tcl == z){
						LV_Delete(A_index)
						cons := -1
						continue
					}
					LV_Modify(A_index+cons, "Col2", tcl-1)
				}
			}
		}
		chOrg_notification(TXT.ORG_clpdelMsg)
	}
	else {
		if (chOrg_Lb != "") && (chOrg_Lb>1) {
			gosub chorg_getChSelected
			MsgBox, 67, % TXT.ORG_delCnlMsgTitle, % TXT.ORG_delCnlMsg
			IfMsgBox, Yes
			{
				manageChannel(chSel)
				gosub chOrg_addChList
				gosub chOrg_addChUseList
			}
			IfMsgBox, No
			{
				API.emptyChannel(chSel)
				Gui, chorg:Default
				LV_Delete()
			}
			IfMsgBox, Cancel
				chOrg_notification( TXT.TIP_cancelled)
			else chOrg_notification(TXT.TIP_done)
		}
	}
	return

/**
 * clip copy/move handler
 */
chOrgCut:
chOrgCopy:
; single cut/ multi copy supported
	gosub chOrg_getSelected
	flag := A_ThisLabel="chOrgCut" ? 0 : 1
	chOrg_notification(flag ? TXT.ORG_copyingclp : TXT.ORG_movingclp, 99999999)
	if (A_ThisLabel="chOrgCut") && Instr(rSel, "`n")
	{
		chOrg_notification(TXT.ORG_error)
		return
	}
	ret := chooseChannelGui(TXT._destChannel)
	if ret=
	{
		chOrg_notification(TXT.TIP_cancelled)
		return
	}
	Gui, chOrg:Default
	loop, parse, rSel, `n
	{
		API.manageClip(ret, Substr(A_LoopField, 1, Instr(A_LoopField, "-")-1) , Substr(A_LoopField, Instr(A_LoopField, "-")+1) , flag )
		chOrg_notification("In Process")
	}
	chOrg_notification(TXT.TIP_done)
	gosub chOrg_refresh
	return

/**
 * label to show create new clip dialog
 */
chOrgNew:
	gosub chorg_getChSelected
	if chSel<0
		chSel := CN.NG
	STORE.ErrorLevel := 0
	out := multInputBox(TXT.ORG_createnew, TXT.ORG_createnewpr " - " chSel, 15, blank, "chOrg")
	if STORE.ErrorLevel
	{
		API.addClip(chSel, out)
		gosub chOrg_refresh
	} Else
		chOrg_notification(TXT.TIP_cancelled)
	return

/**
 * label for creating new channel action
 */
chOrgNewCh:
	InputBox, out, % TXT.ORG_newchname,,,,,,,,, % CN.Total
	if !ErrorLevel {
		changeChannel(CN.Total)
		renameChannel(CN.Total-1, out)
		gosub chOrg_addChList
		gosub chOrg_addChUseList ; No need as changeChannel calls it but Needed here as it name changes later on
		; GuiControl, chOrg:Choose, Listbox1, % CN.Total+1 ; makes no sense to open an empty channel
	}
	return

/**
 * get selected channel id and name
 */
chorg_getChSelected:
	Gui, chorg:Submit, nohide
	chSel := chOrg_Lb-2
	chSelname := ini_read("Channels", chSel)
	return

/**
 * is channel list active or not
 * not in case clip list is active
 */
chOrg_isChActive:
	Gui, chorg:Default
	GuiControlGet, isChActive, chOrg:, % "Button" t_startBtn 		; Cut button not enabled when LB is active
	if (isChActive == chrhex("f040"))
		isChActive := 1
	else isChActive := 0
	return

/**
 * get selected clips from the list
 */
chOrg_getSelected:
	Gui, chOrg:Default
	temp_row_s := 0 , rSel := ""
	while ( temp_row_s := LV_GetNext(temp_row_s) )
	{
		LV_GetText(out_ch, temp_row_s, 1) , LV_GetText(out_cl, temp_row_s, 2)
		rSel .= out_ch "-" out_cl "`n"
		last_Row := temp_row_s
	}
	rSel := Trim(rSel, "`n")
	return

/**
 * edit a selected clip or channel
 */
chOrgEdit:
	gosub chOrg_isChActive
	if isChActive
		gosub chOrg_renameCh
	else {
		gosub chOrg_getSelected
		STORE.ErrorLevel := 0
		ret := editClip(out_ch, out_cl)
		if STORE.ErrorLevel
			LV_Modify(last_Row, "", out_ch, out_cl, ret)
		else chOrg_notification(TXT.TIP_cancelled, 800)
	}
	return

/**
 * open paste mode for the selected clip
 */
chOrg_openPasteMode: ; Toggles the interface
	gosub chOrg_getSelected
	opnPstMd_cn := out_ch , opnPstMd_cl := API.getChStrength(out_ch)-out_cl+1
	if ( opnPstMd_cn == CN.NG ) && ( opnPstMd_cl == realActive ) && SPM.ACTIVE
	{
		gosub endPasteMode
		opnPstMd_cn := opnPstMd_cl := ""
	}
	else ;WinGetPos, x, y,,, % TXT.ORG__name " ahk_class AutoHotkeyGUI"
		API.showPasteTipAt(out_ch, out_cl) ;, x+100, y+160)
	return

/**
 * close the organizer gui and paste the selected clip
 */
chOrg_paste:
	gosub chOrg_getSelected
	gosub chOrgGuiClose
	WinWaitClose, % TXT.ORG__name
	loop, parse, rSel, `n
	{
		API.paste( Substr(A_LoopField, 1, Instr(A_LoopField, "-")-1) , Substr(A_LoopField, Instr(A_LoopField, "-")+1) )
		sleep 30
		SendInput, {Enter}
	}
	return

/**
 * show properties of the selected clip
 */
chOrg_props:
	gosub chOrg_getSelected
	out_cl := API.getChStrength(out_ch)-out_cl+1
	ClipPref_makeKeys(out_ch, out_cl)
	SB_SetText(TXT._editing, 2)
	CPS[out_ch][out_cl] := ObjectEditView( CPS[out_ch][out_cl], Array(TXT.ORG_editprops, "chOrg", TXT.ORG_oEditMsg, 150), 0 )
	prefs2Ini()
	chOrg_notification(blank, 10)
	return

/**
 * preview the selected clip
 */
chOrg_preview:
	gosub chOrg_getSelected
	out_cl := API.getChStrength(out_ch) - out_cl + 1
	out_ch := out_ch ? out_ch : ""
	if FileExist(clippath := "cache\thumbs" out_ch "\" out_cl ".jpg")
		gui_Clip_preview(clippath, blank, "chOrg")
	else {
		clipdata := CDS[out_ch ? out_ch : 0][out_cl] 	; dont use LV here, limit of 8192 chrs
		genHTMLforPreview(clipdata)
		gui_Clip_preview(PREV_FILE, chOrg_search, "chOrg")
	}
	return

/**
 * rename a channel and then refresh the channel list
 */
chOrg_renameCh:
	gosub chorg_getChSelected
	InputBox, outName, % TXT.ORG__name, % TXT.ORG_renameAsk " -> " chSel,, 500, 200,,,,, % chSelname
	if (ErrorLevel=1) or (outName="")
		return
	renameChannel(chSel, outName)
	gosub chOrg_addChList
	gosub chOrg_addChUseList
	return

/**
 * activate a channel
 */
chorg_UseCh:
	Gui, chorg:Submit, nohide
	changeChannel(channel_find(chorg_UseCh)) 	; chChannel() will handle that list
	return

/**
 * list view (clip list) event handler
 */
chOrg_Lv:
	Gui, chOrg:Default
	GuiControl, , % "Button" t_startBtn, % chrhex("f03e")
	loop % t_horizButtons
		GuiControl, Enable, % "Button"  A_index+t_startBtn
	if A_GuiEvent = DoubleClick
		gosub chOrg_preview
	return

/**
 * activate the list box i.e. channels list
 */
chOrg_activateLB:
	GuiControl, chOrg:focus, ListBox1
	sleep 50 ; Needed
	gosub chOrg_Lb
	return

/**
 * activate the list view i.e. clips list
 */
chOrg_activateLV:
	GuiControl, chOrg:focus, SysListView321
	sleep 50
	gosub chOrg_Lv
	LV_Modify(0, "-Select")
	LV_Modify(1, "Select Focus")
	return

/**
 * refresh the clip list
 * triggers when you edit the text in search box
 * or press refresh (F5)
 * or change focus to list box (channels list) in order to change channel
 */
chOrg_refresh:
chOrg_search:
chOrg_Lb:
	Gui, chOrg:submit, nohide
	Gui, chOrg:default
	;msgbox here
	GuiControl, chOrg:,% "Button" t_startBtn, % chrhex("f040")
	if chOrg_Lb=1
		loop % t_horizButtons 		; in case all channels are selected
			GuiControl, chOrg:Disable, % "Button"  A_index+t_startBtn
	else {
		loop % t_horizButtons-t_commonBtn-1 	; 3=buttons common in bth LB LV
			GuiControl, chOrg:Disable, % "Button"  A_index+t_startBtn+t_commonBtn
		loop % t_commonBtn
			GuiControl, chOrg:Enable,  % "Button"  A_Index+t_startBtn
		GuiControl, chOrg:Enable, % "Button" t_horizButtons+t_startBtn
	}
	chOrgLV_update(chOrg_search, chOrg_Lb>1 ? chOrg_Lb-2 : "")
	return

}

/**
 * add the active channel selector list (the one on top)
 */
chOrg_addChUseList:
	chList := Trim(channel_find(), "`n")
	chListnew := ""
	loop, parse, chList, % "`n"
		chListnew .= Substr(A_loopfield, Instr(A_loopfield, "-")+1) "|"
	chList := RTrim(chListnew, "|")

	StringReplace, chList, chList, % CN.Name, % CN.Name "|"
	chList .= (Substr(chList, 0) == "|") ? "|" : ""
	GuiControl, chOrg:, ComboBox1, % "|" chList
	return

/**
 * label to focus on active channel selector
 */
chOrg_useChFocus:
	GuiControl, chOrg:focus, ComboBox1
	return

/**
 * focus on search box
 */
chOrg_searchfocus:
	GuiControl, chOrg:Focus, Edit1
	return

/**
 * swap two channel
 * essentially their id's will be swapped
 * @param  {int} orig_ch channel 1
 * @param  {int} new_ch  channel 2
 * @return {bool} 1 for success
 */
chOrg_clipFolderSwap(orig_ch, new_ch){
	if (new_ch<0) or ( new_ch >= CN.Total )
		return 0

	origch := orig_ch ? orig_ch : "" , newch := new_ch ? new_ch : ""
	ClipFolderTransfer(newch, newch "_a", 0, "R")
	ClipFolderTransfer(origch, newch, 0, "R")
	ClipFolderTransfer(newch "_a", origch, 0, "R")

	obj_orig := CDS[orig_ch] , obj_new := CDS[new_ch] 	; update cached datas
	CDS[orig_ch] := obj_new , CDS[new_ch] := obj_orig
	obj_orig := CPS[orig_ch] , obj_new := CPS[new_ch] 	; update prefs
	CPS[orig_ch] := obj_new , CPS[new_ch] := obj_orig

	CN["TEMPSAVE" CN.N] := TEMPSAVE , CN["CURSAVE" CN.N] := CURSAVE 	; submit active values
	ts_orig := CN["TEMPSAVE" origch] , cs_orig := CN["CURSAVE" origch] ; update cursave values
	CN["TEMPSAVE" origch] := CN["TEMPSAVE" newch] , CN["CURSAVE" origch] := CN["CURSAVE" newch]
	CN["TEMPSAVE" newch] := ts_orig , CN["CURSAVE" newch] := cs_orig

	orig_name := ini_read("Channels", orig_ch) , Ini_write("Channels", orig_ch, ini_read("Channels", new_ch), 0)
	ini_write("Channels", new_ch, orig_name, 0)

	if ( CN.NG == orig_ch )
		changeChannel(new_ch, 0) 	; 0 for dont save prev values is neccesary
	return 1
}

/**
 * swaps two clips
 * @param  {int} fch first channel
 * @param  {int} fcl first clip
 * @param  {int} sch second channel
 * @param  {int} scl second clip
 * @return {void}
 */
chOrg_clipSwap(fch, fcl, sch, scl){
	f_sub := (fch?fch:"") , s_sub := (sch?sch:"")
	f_cno := API.getChStrength(fch)-fcl+1 , s_cno := API.getChStrength(sch)-scl+1

	ClipTransfer(s_sub, s_cno, s_sub, s_cno "_a", 0)
	ClipTransfer(f_sub, f_cno, s_sub, s_cno, 0)
	ClipTransfer(s_sub, s_cno "_a", f_sub, f_cno, 0)
	bk := CDS[sch][s_cno] , CDS[sch][s_cno] := CDS[fch][f_cno] , CDS[fch][f_cno] := bk
	bk := CPS[sch][s_cno] , CPS[sch][s_cno] := CPS[fch][f_cno] , CPS[fch][f_cno] := bk
}

/**
 * shows notification in the gui status bar
 * @param  {string} text text to show
 * @param  {int} time time to show in ms
 * @return {void}
 */
chOrg_notification(text, time=800){
	Gui, chOrg:Default
	SB_SetText(text, 2)
	SetTimer, chOrg_notification, % time
}

/**
 * timer'ed label to clear the notification
 */
chOrg_notification:
	SetTimer, chOrg_notification, Off
	Gui, chOrg:Default
	SB_SetText(empty, 2)
	return


IsChorgActive(){
	return WinActive( TXT.ORG__name " ahk_class AutoHotkeyGUI") && ctrlRef==""
}
IsChOrgLVActive(){
	return IsActive("SysListView321", "classnn") && WinActive(TXT.ORG__name " ahk_class AutoHotkeyGUI") && ctrlRef==""
}
IsChOrgLBActive(){
	return IsActive("ListBox1", "classnn") && WinActive(TXT.ORG__name " ahk_class AutoHotkeyGUI") && ctrlRef==""
}
IsChOrgSearchActive(){
	return IsActive("Edit1", "classnn") && WinActive(TXT.ORG__name " ahk_class AutoHotkeyGUI") && ctrlRef==""
}

/**
 * updates the list view with the current search
 * @param  {String} term    term to filter by
 * @param  {int} channel channel number if any
 * @return {void}
 */
chOrgLV_update(term="", channel=""){
	Gui, chOrg:Default
	LV_Delete() , term := Trim(term) , ct := 0
	if channel=
	{
		for k,v in CDS
		{
			maxindex := API.getChStrength(k)
			loop % maxindex
				if SuperInstr( (v2 := getRealCD( v[maxIndex-A_index+1] )) " " CPS[k][maxIndex-A_index+1]["Tags"] , term, 1)
					LV_Add("", k, A_index, v2) , ct++
		}
	}
	else {
		maxIndex := API.getChStrength(channel)
		loop % maxIndex
			if SuperInstr( (v := getRealCD( CDS[channel][maxIndex-A_index+1] )) " " CPS[channel][maxIndex-A_index+1]["Tags"] , term, 1)
				LV_Add("", channel, A_index, v) , ct++
	}
	SB_SetText(TXT.ORG_countStatus " - " ct, 1)
}


#If IsChorgActive()
#If
#If IsChOrgLVActive()
#If
#If IsChOrgLBActive()
#If
#If IsChOrgSearchActive()
#If