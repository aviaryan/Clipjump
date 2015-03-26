;@Plugin-Name Move to Channel regexp
;@Plugin-Description Use this plugin to move the selected item to a particular channel based on a regular expression
;@Plugin-Author Danielo Rodriguez (@danielo515)
;@Plugin-Tags channel move regexp

;@Plugin-param1 What is to be done, 0 = copy, 1 = cut

plugin_move2channel_regex(zWhat){
	if !zWhat
		zSend := "^{vk43}"
	else zSend := "^{vk58}"
	ONCLIPBOARD := 3 ; any other positive number other than 1
	Send, % zSend
	while ( ONCLIPBOARD != 1 )
		sleep 100
	clip := API.getClipAt(CN.NG) ;get first clip text at current channel(default parameters of getClipAt)
	regexs := Object()
	regexs["N#\d+"] := "tickets" ;simple example. The key should be the regex and the value the channel name. Channel should exists
	for reg, channelName in regexs 
	{
		hasMatch := RegExMatch(clip,reg)
		if ( hasMatch > 0 ){
			destChannel := channel_find(channelName)
			if( CN.NG <> destChannel)
				API.manageClip(destChannel)
			API.showTip("Moved to ".channelName,"2000")
			break
			}
	}
}
