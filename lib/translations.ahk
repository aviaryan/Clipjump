;Translations Function for Clipjump
;IDEAS
;Translation files are simple text-files with var=value syntax . Add ; before for comment . Only newline comments
;returns object

;REGIONS
;TIP , ABT , HST , PRV ,  SET , CNL , TRY , ACT , IGN , LNG, CHC , API , PLG _ (used for independent names)


Translations_load(file="languages\english.txt", default_file="languages\english.txt"){
	obj := {} , f := default_file

	if !FileExist(default_file){
		MsgBox, 16, Warning, % TXT.LNG_error
	}

	loop 2
	{
		loop, read, % f
		{
			if !( line := Trim(A_LoopReadLine) ) or ( Instr(line, ";") = 1 )
				continue
			p := Instr(line, "=")
			if p = 1
				value := Ltrim( Substr(line, 2) )   ,  obj[var] .= "`n" value
			else
				var := Trim( Substr(line, 1, p-1) )   ,   value := LTrim( Substr(line, p+1) )
				, obj[var] := value
		}
		p := 0
		f := file
	}
	return obj
}

Translations_apply(){
	;applies the loaded translations in vars to all GUIs and needed places
	;channelGUI(1)
	trayMenu(1)
	init_actionmode()
	Translations_fixglobalvars()
}

Translations_fixglobalvars(){
	global
	MSG_TRANSFER_COMPLETE := valueof(TXT.TIP_copied_2)
	CopyMessage := !ini_IsMessage ? "" : MSG_TRANSFER_COMPLETE " {" CN.Name "}"
	
	MSG_CLIPJUMP_EMPTY := TXT.TIP_empty1 "`n`n" valueof(TXT.TIP_empty2_2) "`n`n" TXT.TIP_empty3 ;not `n`n
	MSG_ERROR := TXT.TIP_error
	MSG_MORE_PREVIEW := TXT.TIP_more
	MSG_PASTING := TXT.TIP_pasting
	MSG_DELETED := TXT.TIP_deleted
	MSG_ALL_DELETED := TXT.TIP_alldeleted
	MSG_CANCELLED := TXT.TIP_cancelled
	MSG_FIXED := TXT.TIP_fixed
	MSG_HISTORY_PREVIEW_IMAGE := TXT.HST_viewimage
	MSG_FILE_PATH_COPIED := TXT.TIP_filepath " " PROGNAME
	MSG_FOLDER_PATH_COPIED := TXT.TIP_folderpath " " PROGNAME
}

Translations_loadlist(){
	;load the lang files in dropdown form
	loop, languages\*.txt
		r .= Substr(A_LoopFileName, 1, -4) "|"
		, r .= ( Substr(A_LoopFileName, 1, -4) == ini_Lang ) ? "|" : ""
	GuiControl, 2:, ini_Lang, % "|" r
} 