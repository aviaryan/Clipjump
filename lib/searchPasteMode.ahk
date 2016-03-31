/*
Search in Paste Mode functions and labels file.
introduced in v10.6
*/

searchPasteMode(x, y, h){
	static searchpm, searchpm_ct
	hkZ(pstIdentifier pastemodekey.f, "SPM_dispose")
	
	Gui, searchpm:New
	Gui, searchpm:+LastFound +AlwaysOnTop -Caption +ToolWindow
	Gui, Add, Edit, x1 y1 w220 R1 vsearchpm gsearchpm_edit -VScroll,
	Gui, Add, Edit, x+5 yp w45 r1 vsearchpm_ct +disabled , ;show like 4/17
	Gui, searchpm:show, % "x" x " y" y " w" 220+2+5+45 " h" h+2, Clipjump_SPM

	Hotkey, IfWinActive, Clipjump_SPM ahk_class AutoHotkeyGUI
	hkZ(spmkey.enter, "spm_paste", 1)
	hkZ(spmkey.home, "spm_cancel", 1)
	hkZ(spmkey.up, "spm_nextres", 1)
	hkZ(spmkey.down, "spm_prevres", 1)
	Hotkey, IfWinActive

	gosub searchpm_edit
	return

searchpm_edit:
	Gui, searchpm:submit, nohide
	SPM.count := searchpm_search(searchpm)
	searchpm_jumptomatch(SPM.CHANNEL, SPM.TEMPSAVE+1, 1, (searchpm="") or (SPM.count=0) ? 1 : 0)
	return

spm_paste:
	ctrlref := "pastemode" , SPM.KEEP := 1 , MULTIPASTE := 0 	;multipaste will end as this step terminates the ops
	gosub SPM_dispose
	return

searchpmGuiEscape:
spm_cancel:
	ctrlref := "cancel" , SPM.KEEP := 1 , MULTIPASTE := 0
	gosub SPM_dispose
	return

spm_nextres:
	if SPM.count {
		correctTEMPSAVE()
		++SEARCHOBJ.pointer
		searchpm_jumptomatch(CN.NG, TEMPSAVE, 1)
	}
	return

spm_prevres:
	if SPM.count {
		correctTEMPSAVE()
		--SEARCHOBJ.pointer
		searchpm_jumptomatch(CN.NG, TEMPSAVE, -1)
	}
	return
}

SPM_dispose:
	Gui, searchpm:Destroy
	SPM.ACTIVE := 0
	if SPM.KEEP
	{
		while ctrlRef != ""
			sleep 20
		changeChannel(SPM.CHANNEL, 0) , TEMPSAVE := realActive := SPM.TEMPSAVE , SPM.KEEP := 0 ; in paste mode where paste occurs, realactive holds tempsave
	}
	SPM := {} , SEARCHOBJ := {}
	return

searchpm:
	SPM.ACTIVE := 1
	Gui, imgprv:Destroy
	WinGetPos, pmtip_x, pmtip_y,,, ahk_class tooltips_class32
	SPM.X := pmtip_x , SPM.Y := pmtip_y
	correctTEMPSAVE() , SPM.TEMPSAVE := TEMPSAVE , SPM.CHANNEL := CN.NG
	CN["CURSAVE" CN.N] := CURSAVE , CN["TEMPSAVE" CN.N] := TEMPSAVE 	; load all values in CN obj
	h := getControlInfo("edit", "some", "h") 		; get height of edit box
	searchPasteMode(pmtip_x, pmtip_y-h-5, h) 		; 5 space betn them
	return

searchpm_search(term){
	SEARCHOBJ := {} , c:=0
	loop % CN.Total
	{
		r := A_index-1
		SEARCHOBJ[r] := {}
		for k,v in CDS[r]
		{
			if SuperInstr( getRealCD(v) " " CPS[r][k]["Tags"] , Trim(term, " "), 1)
				SEARCHOBJ[r][k] := "|" , c++
		}
	}
	SEARCHOBJ.pointer := c?1:0
	SEARCHOBJ.rescount := c
	return c
}

searchpm_jumptomatch(ich, iclip, f, default=0){
	spm_isfound := searchpm_findmatch(ich, iclip, f, nextch, nextclip)
	if ( SEARCHOBJ.pointer > searchobj.rescount )
		SEARCHOBJ.pointer := 1
	if ( SEARCHOBJ.pointer<1 )
		SEARCHOBJ.pointer := SEARCHOBJ.rescount
	if default
		nextch := SPM.CHANNEL , nextclip := SPM.TEMPSAVE
	if spm_isfound
	{
		GuiControl, searchpm:, Edit2, % SEARCHOBj.pointer "/" SEARCHOBJ.rescount
		changeChannel(nextch, 0) ; 0 = don't save values
		IN_BACK := 0 ; not in back - don't allow TEMPSAVE change
		TEMPSAVE := nextclip
		gosub paste
		return 1
	}
	else {
		GuiControl, searchpm:, Edit2, % "0/0"
		changeChannel(nextch, 0)
		IN_BACK := 0 , TEMPSAVE := nextclip
		gosub paste
		return 0
	}
}

searchpm_findmatch(curch, curclip, f:=1, byref nextch="", byref nextclip=""){
	loop % CN.Total+1
	{
		r := f>0 ? (A_index+curch-1) : (1-A_index+curch)
		if (r >= CN.Total)
			r := r-CN.Total
		if r<0
			r := CN.Total+r 	; 
		l := (A_index=CN.Total+1)

		loop % n := SEARCHOBJ[r].maxIndex()
		{
			if f>0
			{
				if SEARCHOBJ[r].haskey(t := n-A_index+1)
				{
					j := 0 , j := (l ? (t>=curclip) : (t<curclip)) + (curch!=r)
					if j
						nextch := r , nextclip := t , done := 1
				}
			}
			else
			{
				if SEARCHOBJ[r].hasKey(t:=A_index)
				{
					j := 0 , j := (l ? (t<=curclip) : (t>curclip)) + (curch!=r)
					if j
						nextch := r , nextclip := t , done := 1
				}
			}
			if done 
				return 1
		}
	}
}