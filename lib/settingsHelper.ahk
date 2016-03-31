/**
 * This file has functions which help the settings gui and making changes according to settings.ini in general
 */


/**
 * enable/disable the win for paste mode feature
 * @param  {bool} flag   if 1 then enable, else disable
 * @param  {bool} write  if 1 then also write to settings file
 */
manageWinPasteMode(flag, write=0){
	; disable old shortcut
	hkZ( ( paste_k ? "$" pstIdentifier paste_k : emptyvar ) , "Paste", 0)
	; set the vars
	if (flag == 1){
		pstIdentifier := "#"
		pstKeyName := "LWin"
	} else {
		pstIdentifier := "^"
		pstKeyName := "Ctrl"
	}
	; set the shortcut
	hkZ( ( paste_k && CLIPJUMP_STATUS ? "$" pstIdentifier paste_k : emptyvar ) , "Paste")
	; write
	if (write == 1){
		ini_write("Advanced", "WinForPasteMode", flag, 0)
	}
}