;The About GUI for Clipjump

aboutGUI(){

	global
	;About GUI
	Gui, 2:Destroy

	Gui, 2:Font, S18, Consolas
	Gui, 2:Add, Text, x0 y0 w550 h40 +Center gupdt, Clipjump v%version%
	Gui, 2:Font, S14 +bold, 
	Gui, 2:Add, Text, xp+0 yp+40 wp+0 h30 +Center gblog, Avi Aryan (C) 2013
	Gui, 2:Font, norm
	Gui, 2:Add, Groupbox, xp+0 y80 wp+0 h170, About
	Gui, 2:Font, S10, Courier New
	
	Gui, 2:Add, Text, xp+5 y110 wp+0, % "
	(LTrim`t , Join`s
		Clipjump was created to make working with Multiple Clipboards as easy (and fast) as it gets. It is a one and only highly innovated tool that makes you work with Multiple
		Clipboards like never ever before. Use this free tool and feel the difference.`n`nIf you find the tool fabulous, please consider spreading the word!`nA short note of
		appreciation will help many enjoy the benefits of this freebie.
	)"
	
	Gui, 2:Font, S12 norm +underline, Arial
	Gui, 2:Add, Text, x2 y280 gsettings , Edit Settings
	Gui, 2:Add, Text, yp+30 ghistory, See Clipjump's History (Win + C)
	Gui, 2:Add, Text, yp+30 ghlp, Help

	Gui, 2:Show, w552, % PROGNAME " [ Channel: " CN.NG " ]"
	return

blog:
	BrowserRun(AUTHOR_PAGE)
	return

2GuiClose:
	Gui, 2:Hide
	EmptyMem()
	return

}