;@Plugin-Name SentenceCase
;@Plugin-Description Paste Text in Sentence Case
;@Plugin-Author Avi
;@Plugin-Tags pformat
;@Plugin-version 0.0.1
;@Plugin-Previewable 1

;@Plugin-param1 Text to convert in Sentence case

plugin_pformat_sentencecase(zin){
	zCS := getClipboardFormat()
	if (zCS== "[" TXT.TIP_text "]")
	{
		zin_copy := zin , STORE.ClipboardChanged := 1
		loop, parse, zin, `.?!`n`r
		{
			zChanged := plugin_pformat_sentencecase_upper(A_LoopField)
			StringReplace, zin_copy, zin_copy, % A_LoopField, % zChanged
		}
		return zin_copy
	}
	else return zin
}

plugin_pformat_sentencecase_upper(zin){
	zStart := RegExMatch(zin, "iU)[a-z]", zFout)
	StringUpper, zFout, zFout
	zFst := Substr(zin, 1, (zStart?zStart:1)-1)
	zAll := Substr( zin, (zStart?zStart:1)+Strlen(zFout) )
	StringLower, zAll, zAll
	return zFst zFout zAll
}