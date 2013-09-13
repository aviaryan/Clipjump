;The About GUI for Clipjump

aboutGUI(){

	global
	;About GUI
	Gui, 2:Destroy

	Gui, 2:Font, S18, Consolas
	Gui, 2:Add, Edit, x0 y0 w0 h0,
	Gui, 2:Add, Link, x188 y0 gupdt, <a href="http://avi-win-tips.blogspot.com/p/clipjump.html">Clipjump</a> v%version%
	Gui, 2:Font, S14, 
	Gui, 2:Add, Link, x187 y+5 gblog, <a href="http://www.github.com/avi-aryan">Avi Aryan</a> (C) 2013
	Gui, 2:Font, norm
	Gui, 2:Add, Groupbox, x0 y80 w550 h170, About
	Gui, 2:Font, S10, Courier New
	
	Gui, 2:Add, Text, xp+5 y110 wp+0, % "
	(LTrim`t , Join`s
		Clipjump was created to make working with Multiple Clipboards as easy (and fast) as it gets. It is a one and only highly innovated tool that makes you work with Multiple
		Clipboards like never ever before. Use this free tool and feel the difference.`n`nIf you find the tool fabulous, please consider spreading the word!`nA short note of
		appreciation will help many enjoy the benefits of this freebie.
	)"
	
	Gui, 2:Font, S12 norm +underline, Arial
	Gui, 2:Add, Text, x2 y280 gsettings , Edit Settings
	Gui, 2:Add, Text, yp+30 ghistory,% "See Clipjump's History (" hParse_Rev(history_K) ")"
	Gui, 2:Add, Text, yp+30 ghlp, Help

	Gui, 2:Show, w552, % PROGNAME " [ Channel: " CN.Name " ]"
	return

blog:
	BrowserRun(AUTHOR_PAGE)
	return

2GuiClose:
	Gui, 2:Hide
	EmptyMem()
	return

}

trayMenu(){
	global

	;Tray Icon
	if !A_isCompiled			;Important for showing Cj's icon in the Titlebar of GUI
		Menu, Tray, Icon, icons\icon.ico
	Menu, Tray, NoStandard
	Menu, Tray, Add, About %PROGNAME%, main
	Menu, Tray, Tip, % PROGNAME " {" CN.Name "}"
	Menu, Tray, Add		; separator
	Menu, Tray, Add, &Incognito mode, incognito
	Menu, Tray, Add 	; separator
	Menu, Tray, Add,% "Clipboard &history`t" Hparse_Rev(history_K), history
	Menu, Tray, Add,% "Select &Channel`t" Hparse_Rev(channel_K), channelGUI
	Menu, Tray, Add, &Settings, settings
	Menu, Tray, Add		; separator
	Menu, Tray, Add, Check for &updates, updt
	Menu, Tray, Add, Run at startup, strtup
	Menu, Tray, Add, H&elp, hlp
	Menu, Tray, Add		; separator
	Menu, Tray, Add, &Restart, reload
	Menu, Tray, Add, &Exit, qt
	Menu, Tray, Default, About %PROGNAME%
	return

qt:
	ExitApp

reload:
	Reload
	return
}