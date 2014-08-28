;@Plugin-Name UPPERCASE
;@Plugin-Description Paste Text in total UpperCase
;@Plugin-Author Avi
;@Plugin-Tags pformat
;@Plugin-Previewable 1

;@Plugin-param1 Text to convert in Upper case

plugin_pformat_UPPERCASE(zin){
	zCS := getClipboardFormat()
	if (zCS== "[" TXT.TIP_text "]")
	{
		StringUpper, zout, zin
		STORE.ClipboardChanged := 1
		return zout
	}
	else return zin
}