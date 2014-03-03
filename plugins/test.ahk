;@Plugin-Name Test Plugin
;@Plugin-Description A test plugin that shows a Message Box
;@Plugin-Author Avi
;@Plugin-Tags plugin worthless

;@Plugin-param1 What the text you want to see in the MessageBox.

;any number of plugin details can be added.
; no _ in plugin name

plugin_test(text="hi"){
	msgbox % text
}