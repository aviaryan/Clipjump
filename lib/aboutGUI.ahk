;The About GUI for Clipjump

aboutGUI(){

	global
	static w_ofreset, w_versiontxt, versiontxt
	;About GUI
	w_ofreset := getControlinfo("button", TXT.ABT_reset, "w", "s10", "Arial")
	w_versiontxt := getControlinfo("Link", versiontxt := "<a href=""" PRODUCT_PAGE """>" PROGNAME "</a> v" version, "w", "s18", "Consolas")

	Gui, 2:Destroy
	Gui, 2:Margin, 0, 0
	Gui, 2:Font, s18, Courier New
	Gui, 2:Font, S18, Consolas
	Gui, 2:Add, Edit, x0 y0 w0 h0,
	Gui, 2:Add, Link, % "x" (522-w_versiontxt)/2 " y5 gupdt", % versiontxt
	Gui, 2:Font, S12, 
	Gui, 2:Add, Link, x180 y+3 gblog, <a href="%AUTHOR_PAGE%">Avi Aryan</a> (C) %A_year%

	Gui, 2:Font, S11 norm, Arial
	Gui, 2:Add, Text, y+30 x10, % TXT._language
	Gui, 2:Font, s9
	Gui, 2:Add, DropDownList, yp x+20 vini_LANG gupdateLang,
	Translations_loadlist() 			;loads the list in the above ddl
	
	Gui, 2:Font, s11, Courier New
	Gui, 2:Add, Groupbox, x7 y130 w540 h100, % TXT.ABT__name
	Gui, 2:Font, S10, Arial
	
	Gui, 2:Add, Text, xp+10 y160 wp-10, % TXT.ABT_info

	Gui, 2:Font, S10, Arial
	Gui, 2:Add, Button, xp-10 y+60 w70 g2GuiClose Default, OK
	Gui, 2:Add, Button, % "x" 552-w_ofreset-5 " yp greset", % TXT.ABT_reset 		;leaving 5 as margin
	Gui, 2:Add, Text, y+0 h0,

	Gui, 2:Show, w552, % PROGNAME " [ Channel: " CN.Name " ]"
	return

blog:
	BrowserRun(AUTHOR_PAGE)
	return

2GuiEscape:
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
		FileDelete, ClipjumpCustom.ini
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
		Menu, Maintanence_Tray, Delete
		Menu, Help_Tray, Delete
	}

	;Tray Icon
	Menu, Tray, Icon, % mainIconPath
	Menu, Tray, NoStandard
	Menu, Tray, Add, % TXT.ABT__name " " PROGNAME, main
	Menu, Tray, Tip, % PROGNAME " {" CN.Name "}"
	Menu, Tray, Add
	Menu, Tray, Add,% TXT.SET_actmd "`t" Hparse_Rev(actionmode_k), actionmode
	Menu, Tray, Add		; separator
		Menu, Maintanence_Tray, Add, % TXT.PLG_delFileFolder, plugin_deleteFileFolder
		Menu, Maintanence_Tray, Add, % TXT.TRY_updates, updt
	Menu, Tray, Add, % TXT._maintenance, :Maintanence_Tray
		Menu, Options_Tray, Add, % TXT.TRY_incognito, incognito
		Menu, Options_Tray, Add, % TXT.TRY_disable " " PROGNAME, disable_clipjump
		Menu, Options_Tray, Add, % TXT.TRY_startup, strtup
	Menu, Tray, Add, % TXT.TRY_options, :Options_Tray
		Menu, Tools_Tray, Add, % TXT.SET_org "`t" Hparse_Rev(chOrg_K), channelOrganizer
		Menu, Tools_Tray, Add, % TXT.HST__name "`t" Hparse_Rev(history_K), history
		Menu, Tools_Tray, Add, % TXT.IGN__name, classTool
		Menu, Tools_Tray, Add, % TXT.PLG__name "`t" Hparse_Rev(pluginManager_k), pluginManagerGUI
		Menu, Tools_Tray, Add, % TXT.SET__name, settings
	Menu, Tray, Add, % TXT.TRY_tools, :Tools_Tray
		Menu, Help_Tray, Add, % TXT.TRY_pstmdshorts, openShortcutsHelp
		Menu, Help_Tray, Add, % "FAQ", openFaq
		Menu, Help_Tray, Add
		Menu, Help_Tray, Add, % "Clipjump.chm", hlp
	Menu, Tray, Add
	Menu, Tray, Add, % TXT.TRY_help, :Help_Tray
	Menu, Tray, Add
	Menu, Tray, Add, % TXT.TRY_reloadcustom, reloadCustom
	Menu, Tray, Add, % TXT.TRY_restart, reload
	Menu, Tray, Add, % TXT.TRY_exit, exit
	Menu, Tray, Default, % TXT.ABT__name " " PROGNAME
	return

}

openFaq:
	try run hh.exe mk:@MSITStore:%A_WorkingDir%\Clipjump.chm::/docs/faq.html
	catch
		MsgBox, 16, % PROGNAME, % TXT.ABT_chmErr
	return

openShortcutsHelp:
	try run hh.exe mk:@MSITStore:%A_WorkingDir%\Clipjump.chm::/docs/shortcuts.html#pstmd
	catch
		MsgBox, 16, % PROGNAME, % TXT.ABT_chmErr
	return

reload:
	OnExit,
	routines_Exit()
	Reload
	return