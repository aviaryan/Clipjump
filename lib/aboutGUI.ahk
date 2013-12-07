;The About GUI for Clipjump

aboutGUI(){

	global
	static w_ofreset
	;About GUI
	w_ofreset := getControlinfo("button", TXT.ABT_reset, "w", "s10", "Arial")

	Gui, 2:Destroy
	Gui, 2:Margin, 0, 0
	Gui, 2:Font, s18, Courier New
	Gui, 2:Font, S18, Consolas
	Gui, 2:Add, Edit, x0 y0 w0 h0,
	Gui, 2:Add, Link, x188 y5 gupdt, <a href="%PRODUCT_PAGE%">%PROGNAME%</a> v%version%
	Gui, 2:Font, S12, 
	Gui, 2:Add, Link, xp+3 y+3 gblog, <a href="%AUTHOR_PAGE%">Avi Aryan</a> (C) 2013

	Gui, 2:Font, S11 norm, Arial
	Gui, 2:Add, Text, y+30 x10, Language
	Gui, 2:Font, s9
	Gui, 2:Add, DropDownList, yp x+20 vini_LANG gupdateLang,
	Translations_loadlist() 			;loads the list in the above ddl
	
	Gui, 2:Font, s11, Courier New
	Gui, 2:Add, Groupbox, x7 y130 w540 h100, About
	Gui, 2:Font, S10, Arial
	
	Gui, 2:Add, Text, xp+10 y160 wp-10, % "
	(LTrim`t , Join`s
		Clipjump is a Windows only Clipboard Manager created in AutoHotkey. `nIt inhibits the very basic ideas from Skrommel's ClipStep but adds many new features and critical bug fixes.
	)"

	Gui, 2:Font, S10, Arial
	Gui, 2:Add, Button, xp-10 y+60 w70 g2GuiClose Default, OK
	Gui, 2:Add, Button, % "x" 552-w_ofreset-5 " yp greset", % TXT.ABT_reset 		;leaving 5 as margin
	Gui, 2:Add, Text, y+0 h0,

	Gui, 2:Show, w552, % PROGNAME " " (!CLIPJUMP_STATUS ? "{Disabled}" : "") " [ Channel: " CN.Name " ]"
	return

blog:
	BrowserRun(AUTHOR_PAGE)
	return

2GuiClose:
	Gui, 2:Hide
	EmptyMem()
	return

updateLang:
	Gui, 2:submit, nohide
	TXT := Translations_load("languages/" ini_LANG ".txt")
	Translations_apply()
	ini_write("System", "Lang", ini_LANG, 0)
	return

reset:
	MsgBox, 20, Warning, % TXT.ABT_resetM
	IfMsgBox, Yes
	{
		FileRemoveDir, cache, 1
		FileDelete, settings.ini
		if A_IsCompiled
			FileRemoveDir, icons, 1
		IfExist, %A_Startup%/Clipjump.lnk
		{
			MsgBox, 52, Resetting %PROGNAME%,% TXT.ABT_removeStart
			IfMsgBox, Yes
				FileDelete, %A_Startup%/Clipjump.lnk
		}
		MsgBox, 64, Reset Complete, % PROGNAME " " TXT.ABT_resetfinal
		OnExit,
		ExitApp
	}
	return
}

trayMenu(destroy=0){
	global

	if destroy
	{
		Menu, Tray, DeleteAll
		Menu, Options_Tray, Delete
		Menu, Tools_Tray, Delete
	}

	;Tray Icon
	if !A_isCompiled			;Important for showing Cj's icon in the Titlebar of GUI
		Menu, Tray, Icon, icons\icon.ico
	Menu, Tray, NoStandard
	Menu, Tray, Add, % TXT.ABT__name " " PROGNAME, main
	Menu, Tray, Tip, % PROGNAME " {" CN.Name "}"
	Menu, Tray, Add
	Menu, Tray, Add,% TXT.SET_actmd "`t" Hparse_Rev(actionmode_k), actionmode
	Menu, Tray, Add		; separator
		Menu, Options_Tray, Add, % TXT.TRY_incognito, incognito
		Menu, Options_Tray, Add, % TXT.TRY_disable " " PROGNAME, disable_clipjump
		Menu, Options_Tray, Add, % TXT.TRY_startup, strtup
	Menu, Tray, Add, % TXT.TRY_options, :Options_Tray
		Menu, Tools_Tray, Add, % TXT.HST__name "`t" Hparse_Rev(history_K), history
		Menu, Tools_Tray, Add, % TXT.SET_chnl "`t" Hparse_Rev(channel_K), channelGUI
		Menu, Tools_Tray, Add, % TXT.IGN__name, classTool
		Menu, Tools_Tray, Add, % TXT.SET__name, settings
	Menu, Tray, Add, % TXT.TRY_tools, :Tools_Tray
	Menu, Tray, Add		; separator
	Menu, Tray, Add, % TXT.TRY_updates, updt
	Menu, Tray, Add, % TXT.TRY_help, hlp
	Menu, Tray, Add		; separator
	Menu, Tray, Add, % TXT.TRY_restart, reload
	Menu, Tray, Add, % TXT.TRY_exit, exit
	Menu, Tray, Default, % TXT.ABT__name " " PROGNAME
	return

reload:
	OnExit
	save_Exit()
	Reload
	return
}