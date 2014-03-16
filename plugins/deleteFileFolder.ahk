;@Plugin-Name Delete [File/Folder]
;@Plugin-Description Deletes clips that are [File/Folder] type from a channel.
;@Plugin-Author Avi
;@Plugin-Version 0.1
;@Plugin-Tags clip management file folder

;@Plugin-param1 The channels whose [file/folder]s are to be deleted separated by space. If this param is empty, all channels that exist are taken into account.

plugin_deleteFileFolder(zchannels=""){
	Critical 				; As all clip files are disturbed, it is necessary to be non-interruptible
	if zchannels=
		loop % CN.Total 	; Cn.total contains total channels
			zchannels .= A_index-1 " "
	zchannels := Trim(zchannels, " ")
	if zchannels=
		return 0
	zbkCh := CN.NG 	; create backup of current channel
	CN["CURSAVE" CN.N] := CURSAVE , CN["TEMPSAVE" CN.N] := TEMPSAVE 	; put CURSAVE (stores total clips in a channel) and TEMPSAVE in the object

	API.blockMonitoring(1) 	; block Clipboard monitoring as Clipboard will be heavily changed during the process
	loop, parse, zchannels, %A_Space%
	{
		if FileExist("cache\clips" (zCfactor := A_LoopField ? A_LoopField : "") ) 	;for ch. 0, we have cache\clips
		{
			API.showTip("Deleting Clips of type [File/Folder] from channel " A_LoopField) 	; show tip
			changeChannel(A_LoopField) 		; change Channel to the one to be examined
			loop, cache\clips%zCfactor%\*.avc
			{
				ONCLIPBOARD := 0 	; This var is made 1 by the OnClipboardChange: label that responds to system clipboard change.
				FileRead, Clipboard, *c %A_LoopFileFullPath% 	; read clip file to clipboard
				zFormat := getClipboardFormat() 				; get its format
				if ( zFormat == "[" TXT.TIP_file_folder "]" ) 	; if format is file/folder
				{
					clearClip( Substr(A_LoopFileName,1,-4) ) 	; clear the file/folder clip
				}
			}
		}
	}
	Critical, Off 	; Off Critical so that if ONCLIPBOARDCHANGE: wants, it can update the var ONCLIPBOARD
	while !ONCLIPBOARD 		; wait for the final ONCLIPBOARD to be 1
	{
		if A_index>40		; break if something unexpected happened
			break
		sleep 5
	}
	API.showTip("Delete [File/Folder] Plugin Finished", 800) 		; remove the tip after 800 ms
	changeChannel(zbkCh) 		;change channel back
	API.blockMonitoring(0)
}

plugin_deleteFileFolder:
	API.runPlugin("deleteFileFolder.ahk")
	return