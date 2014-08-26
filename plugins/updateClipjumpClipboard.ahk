;@Plugin-Name Sync Clipjump Clipboard
;@Plugin-Silent 1
;@Plugin-Description Updates/Syncs clipjump clipboards with the current active system clipboard
;@Plugin-Author Avi
;@Plugin-Version 0.1
;@Plugin-Tags system clipboard clipjump

;@Plugin-param1 Pass 1 or True to show confirmation message after updating

plugin_updateClipjumpClipboard(zMsg = 1){
	try
		zcb := ClipboardAll
	catch
		error := 1
	try 
		Clipboard := zcb
	catch
		error := 1
	sleep 500
	if zMsg
		if !error
			API.showTip( "Both Clipboards were synced. Success !", 1200)
		else API.showTip("Operation Failed ! There was an error", 1200)
}