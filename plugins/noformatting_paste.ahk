;@Plugin-Name NoFormatting Paste
;@Plugin-Description Pastes current clipboard without formatting
;@Plugin-Author Avi
;@Plugin-Tags no-format paste

/*
To create a System Level shortcut, use with Customizer as-

[paste_current_noformatting]
bind = Win+v
run  = API.runPlugin(noformatting_paste.ahk)
*/

plugin_noformatting_paste(){
	API.blockMonitoring(1) 	; blocks Clipboard monitoring by Clipjump
	try Clipboard := Rtrim(Clipboard, "`r`n") 	; Trims clipboard of any formatting
	API.blockMonitoring(0) 	; enable monitoring now
	Send ^{vk56} 	; i.e. ^v
}