/*
TODO
menu for ListBox

*/

channelOrganizer:
	channelOrganizer()
	return

channelOrganizer(){
	static chOrg_Lb, chOrg_search, chOrg_Lv
	static Width, Height 	; // Needed to make widths and hts save

	wt := ini_read("Organizer", "w") , ht := ini_read("Organizer", "h")
	if !wt
		wt := A_ScreenWidth>1200 ? 800 : 700
	if !ht
		ht := A_ScreenHeight>800 ? 450 : 390
	w_ofSearch := getControlInfo("button", TXT.HST_search, "w", "s10")

	Gui, chOrg:New
	Gui, +Resize +MinSize500x280
	Gui, Color, D2D2D2
	Gui, Font, s10
	Gui, Add, Text, % "x" wt - w_ofSearch - 200 " y10", % TXT.HST_search
	Gui, Font, s9
	Gui, Add, Edit, % "x" wt-200 " yp w200 vchOrg_search gchOrg_search", 		; width of EDIT is fixed = 200
	Gui, Font, s10

	;chList := RegexReplace( Trim( channel_find(), "`n" ), "`n", "|" )
	;Sort, chList, D| N
	Gui, Add, ListBox, section x5 y+10 w115 h%ht% gchOrg_Lb vchOrg_Lb -LV0X10 AltSubmit, ;% "|" chList 	; width of LB is fixed = 115
	gosub chOrg_addChList

	Gui, Font, s12, Wingdings
	Gui, Add, Button, x+4 yp+50 w30 gchOrgUp, % chr(233) 			; buttons width = 30
	Gui, Add, Button, xp y+2 w30 gchOrgDown, % chr(234)
	Gui, Add, Button, xp y+2 w30 gchOrgCut, % chr(34)
	Gui, Add, Button, xp y+2 w30 gchOrgCopy, % chr(52)
	Gui, Add, Button, xp y+2 w30 gchOrgDelete, % chr(251)
	; x = 5+115 + 4 + 30 = 154 + 4
	Gui, Font
	Gui, Add, ListView, % "x+4 ys w" wt-158 " h" ht " HWNDchOrg_Lv vchOrg_Lv gchOrg_Lv", % "Ch|#|" TXT.HST_clip
	LV_ModifyCol(1, "30 Integer") , LV_ModifyCol(2, "30 Integer") , LV_ModifyCol(3, wt-158 -60 -10)
	Gui, Add, StatusBar
	SB_SetParts(5+115)
	Gui, chOrg:Show,, % TXT.ORG__name

	GuiControl, chOrg:Choose, chOrg_Lb, % CN.NG+2
	gosub chOrg_Lb
	GuiControl, chOrg:+AltSubmit, chOrg_Lv
	; Gui Done

	; // MENU
	Menu, chOrgLVMenu, Add, % TXT.HST_m_prev, chOrg_preview
	Menu, chOrgLVMenu, Add
	Menu, chOrgLVMenu, Add, % TXT.HST_m_insta, chOrg_paste
	Menu, chOrgLVMenu, Add
	Menu, chOrgLVMenu, Add, % TXT.ORG_m_inc , chOrgUp
	Menu, chOrgLVMenu, Add, % TXT.ORG_m_dec , chOrgDown
	Menu, chOrgLVMenu, Add, % TXT.TIP_move "`t`t(Alt+X)", chOrgCut
	Menu, chOrgLVMenu, Add, % TXT.TIP_copy "`t`t(Alt+C)" , chOrgCopy
	Menu, chOrgLVMenu, Add, % TXT.HST_m_del, chOrgDelete
	Menu, chOrgLVMenu, Add
	Menu, chOrgLVMenu, Add, % TXT.HST_m_ref, chOrg_refresh
	Menu, chOrgLVMenu, Default, % TXT.HST_m_prev

	; Hotkeys
	Hotkey, IfWinActive, % TXT.ORG__name
	hkZ("F5", "chOrg_refresh")
	hkZ("^f", "chOrg_searchfocus")
	Hotkey, If
	Hotkey, If, IsChOrgLVActive()
	hkZ("Enter", "chOrg_preview")
	hkZ("Space", "chOrg_paste")
	hkZ("Del", "chOrgDelete")
	hkZ("!Up", "chOrgUp")
	hkZ("!Down", "chOrgDown")
	hkZ("!x", "chOrgCut")
	hkZ("!c", "chOrgCopy")
	Hotkey, If

	Hotkey, If, IsPrevActive()
	hkZ("^f", "prevSearchfocus")
	Hotkey, If
	return

chOrg_addChList:
	chList := RegexReplace( Trim( channel_find(), "`n" ), "`n", "|" )
	Sort, chList, D| N
	GuiControl, chOrg:, ListBox1, % "||" chList
	return

chOrgGuiSize:
	if (A_EventInfo != 1){
		Anchor("SysListView321", "wh", "chOrg:")
		Anchor("ListBox1", "h", "chOrg:")
		Anchor("Edit1", "x", "chOrg:")
		Anchor("Static1", "x", "chOrg:")
		Gui, chOrg:Default
		ControlGetPos, , , Width,, SysListView321
		ControlGetPos, , , , Height, ListBox1
		LV_ModifyCol(3, Width -60 -10)
	}
	return

chOrgGuiContextMenu:
	if (A_GuiControl != "chOrg_Lv") or (LV_GetNext() = 0)
		return
	Menu, chOrgLVMenu, Show, %A_GuiX%, %A_GuiY%
	return

chOrgGuiEscape:
chOrgGuiClose:
	Ini_write("Organizer", "w", width+158, 0) , Ini_write("Organizer", "h", height, 0)
	Gui, chOrg:Destroy
	Menu, chOrgLVMenu, DeleteAll
	EmptyMem()
	return

chOrgUp:
chOrgDown:
	Gui, chorg:Default
	tempNo := A_ThisLabel="chOrgUp" ? 1 : 0
	temp_row_s := 0
	while (temp_row_s := LV_GetNext(temp_row_s)) {
		LV_GetText(fch, temp_row_s, 1) , LV_GetText(fcl, temp_row_s, 2)
		spRow := tempNo ? temp_row_s-1 : temp_row_s+1
		sch := scl := ""
		LV_GetText(sch, spRow, 1) , LV_GetText(scl, spRow, 2)
		if (sch != "") {
			chOrg_clipSwap(fch, fcl, sch, scl)
			LV_GetText(ftxt, temp_row_s, 3) , LV_GetText(stxt, spRow, 3)
			Gui, chOrg:Default
			LV_Modify(temp_row_s, "", fch, fcl, stxt) 		; // change only 3rd col.. 
			LV_Modify(SprOW,"", sch, scl, ftxt)
		}
	}
	return


chOrgDelete:
	GuiControlGet, out, chOrg:Enabled, Button3 		; Cut button not enabled when LB is active
	if out {
		gosub chOrg_getSelected
		if Instr(rSel, "`n")
		{
			chOrg_notification(TXT.ORG_error)
			return
		}
		API.deleteClip( Substr(rSel, 1, Instr(rSel, "-")-1) , Substr(rSel, Instr(rSel, "-")+1) )
		chOrg_notification("Selected Clip Deleted")
		gosub chOrg_refresh
		LV_Modify(last_Row, "Select") 	;// TO make up for refresh
	}
	else {
		if (chOrg_Lb != "") && (chOrg_Lb>1) {
			MsgBox, 67, % TXT.ORG_delCnlMsgTitle, % TXT.ORG_delCnlMsg
			IfMsgBox, Yes
			{
				manageChannel(chOrg_Lb-2)
				gosub chOrg_addChList
			}
			IfMsgBox, No
				API.emptyChannel(chOrg_Lb-2)
			IfMsgBox, Cancel
				chOrg_notification( TXT.TIP_cancelled)
			else chOrg_notification("Channel Operation Done")
		}
	}
	return

chOrgCut:
chOrgCopy:
; single cut/ multi copy supported
	gosub chOrg_getSelected
	flag := A_ThisLabel="chOrgCut" ? 0 : 1
	chOrg_notification(flag ? "Copying selected clip(s)" : "Moving selected clip(s)", 99999999)
	if (A_ThisLabel="chOrgCut") && Instr(rSel, "`n")
	{
		chOrg_notification(TXT.ORG_error)
		return
	}
	ret := chooseChannelGui()
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
	chOrg_notification("Done")
	gosub chOrg_refresh
	return

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

chOrg_paste:
	gosub chOrg_getSelected
	gosub chOrgGuiClose
	WinWaitClose, % TXT.ORG__name
	;WinHide, % TXT.ORG__name
	loop, parse, rSel, `n
		API.paste( Substr(A_LoopField, 1, Instr(A_LoopField, "-")-1) , Substr(A_LoopField, Instr(A_LoopField, "-")+1) )
	;WinClose, % TXT.ORG__name
	return

chOrg_preview:
	gosub chOrg_getSelected
	out_cl := API.getChStrength(out_ch) - out_cl + 1
	out_ch := out_ch ? out_ch : ""
	if FileExist(clippath := "cache\thumbs" out_ch "\" out_cl ".jpg")
		gui_Clip_preview(clippath, blank, "chOrg")
	else {
		LV_GetText(clipdata, last_Row, 3)
		FileDelete, % PREV_FILE
		FileAppend, % clipdata, % PREV_FILE
		gui_Clip_preview(PREV_FILE, chOrg_search, "chOrg")
	}
	return

chOrg_Lv:
	Gui, chOrg:Default
	loop 4
		GuiControl, Enable, % "Button"  A_index
	if A_GuiEvent = DoubleClick
		gosub chOrg_preview
	return

chOrg_refresh:
chOrg_search:
chOrg_Lb:
	Gui, chOrg:submit, nohide
	chOrgLV_update(chOrg_search, chOrg_Lb>1 ? chOrg_Lb-2 : "")
	loop 4
		GuiControl, Disable, % "Button"  A_index
	return

}

chOrg_searchfocus:
	GuiControl, chOrg:Focus, Edit1
	return

chOrg_clipSwap(fch, fcl, sch, scl){
	f_sub := (fch?fch:"") , s_sub := (sch?sch:"")
	f_cno := API.getChStrength(fch)-fcl+1 , s_cno := API.getChStrength(sch)-scl+1

	ClipTransfer(s_sub, s_cno, s_sub, s_cno "_a", 0)
	ClipTransfer(f_sub, f_cno, s_sub, s_cno, 0)
	ClipTransfer(s_sub, s_cno "_a", f_sub, f_cno, 0)
	bk := CDS[sch][s_cno] , CDS[sch][s_cno] := CDS[fch][f_cno] , CDS[fch][f_cno] := bk
}

chOrg_notification(text, time=800){
	Gui, chOrg:Default
	SB_SetText(text, 2)
	SetTimer, chOrg_notification, % time
}

chOrg_notification:
	SetTimer, chOrg_notification, Off
	Gui, chOrg:Default
	SB_SetText(empty, 2)
	return

IsChOrgLVActive(){
	return IsActive("SysListView321", "classnn") && IsActive(TXT.ORG__name, "window") && ctrlRef==""
}

; // UPDATES the ListView with current search
chOrgLV_update(term="", channel=""){
	Gui, chOrg:Default
	LV_Delete() , term := Trim(term) , ct := 0
	if channel=
	{
		for k,v in CDS
		{
			maxindex := API.getChStrength(k)
			loop % maxindex
				if SuperInstr( v2 := getRealCD( v[maxIndex-A_index+1] )  , term, 1)
					LV_Add("", k, A_index, v2) , ct++
		}
	}
	else {
		maxIndex := API.getChStrength(channel)
		loop % maxIndex
			if SuperInstr( v := getRealCD( CDS[channel][maxIndex-A_index+1] ) , term, 1)
				LV_Add("", channel, A_index, v) , ct++
	}
	SB_SetText(TXT.ORG_countStatus " - " ct, 1)
}


#If IsChOrgLVActive()
#If

; /// EDITED VERSION
Anchor(i, a = "", guiName="") {
; i = ClassNN OR variable
	r := 1 ;redraw
	static c, cs = 12, cx = 255, cl = 0, g, gs = 8, gl = 0, gpi, gw, gh, z = 0, k = 0xffff
	If z = 0
		VarSetCapacity(g, gs * 99, 0), VarSetCapacity(c, cs * cx, 0), z := true

	GuiControlGet, t, %guiName%HWND, %i%
	i := t

	VarSetCapacity(gi, 68, 0), DllCall("GetWindowInfo", "UInt", gp := DllCall("GetParent", "UInt", i), "UInt", &gi)
		, giw := NumGet(gi, 28, "Int") - NumGet(gi, 20, "Int"), gih := NumGet(gi, 32, "Int") - NumGet(gi, 24, "Int")
	If (gp != gpi) {
		gpi := gp
		Loop, %gl%
			If (NumGet(g, cb := gs * (A_Index - 1)) == gp) {
				gw := NumGet(g, cb + 4, "Short"), gh := NumGet(g, cb + 6, "Short"), gf := 1
				Break
			}
		If (!gf)
			NumPut(gp, g, gl), NumPut(gw := giw, g, gl + 4, "Short"), NumPut(gh := gih, g, gl + 6, "Short"), gl += gs
	}
	ControlGetPos, dx, dy, dw, dh, , ahk_id %i%
	Loop, %cl%
		If (NumGet(c, cb := cs * (A_Index - 1)) == i) {
			If a =
			{
				cf = 1
				Break
			}
			giw -= gw, gih -= gh, as := 1, dx := NumGet(c, cb + 4, "Short"), dy := NumGet(c, cb + 6, "Short")
				, cw := dw, dw := NumGet(c, cb + 8, "Short"), ch := dh, dh := NumGet(c, cb + 10, "Short")
			Loop, Parse, a, xywh
				If A_Index > 1
					av := SubStr(a, as, 1), as += 1 + StrLen(A_LoopField)
						, d%av% += (InStr("yh", av) ? gih : giw) * (A_LoopField + 0 ? A_LoopField : 1)
			DllCall("SetWindowPos", "UInt", i, "Int", 0, "Int", dx, "Int", dy
				, "Int", InStr(a, "w") ? dw : cw, "Int", InStr(a, "h") ? dh : ch, "Int", 4)
			If r != 0
				DllCall("RedrawWindow", "UInt", i, "UInt", 0, "UInt", 0, "UInt", 0x0101) ; RDW_UPDATENOW | RDW_INVALIDATE
			Return
		}
	If cf != 1
		cb := cl, cl += cs
	bx := NumGet(gi, 48), by := NumGet(gi, 16, "Int") - NumGet(gi, 8, "Int") - gih - NumGet(gi, 52)
	If cf = 1
		dw -= giw - gw, dh -= gih - gh
	NumPut(i, c, cb), NumPut(dx - bx, c, cb + 4, "Short"), NumPut(dy - by, c, cb + 6, "Short")
		, NumPut(dw, c, cb + 8, "Short"), NumPut(dh, c, cb + 10, "Short")
	Return, true
}