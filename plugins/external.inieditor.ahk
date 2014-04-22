;@Plugin-Name IniEditor
;@Plugin-Description IniEditor by rbrtryn
;@Plugin-Author rbrtryn
;@Plugin-Tags settings.ini
;@Plugin-Site http://www.autohotkey.com/board/topic/93868-
;@Plugin-param1 The path of Ini. Leave blank for <settings.ini>


/*
    Ini-File Editor - easily edit INI and create ini files
    Copyright (C) 2013  Robert Ryan rbrtryn@gmail.com 

    
    Released under the MIT license
    http://opensource.org/licenses/MIT
*/

; Autoexecute:

    iniFile := Substr(A_AhkPath, 1, Instr(A_AhkPath, "\", 0, 0)) "settings.ini" ;Default

    loop %0%
    {
        X = %1%
        if X!=
            iniFile := X
        break
    }

    #NoEnv
    #NoTrayIcon 
    #SingleInstance off
    
   ; #Include <OrderedArray>
    OnMessage(0x4E, "WM_NOTIFY")
    
    gosub MakeGui
    Gui Main:Show
    
    ;Loop %0% {
    ;    IniFile := %A_Index%
    ;    Loop %IniFile%
    ;        IniFile := A_LoopFileLongPath
    ;}

    if (IniFile <> "")
        gosub ReadFile
    else 
        gosub NewFile
        
    gosub UpdateSectionMenu
return

;**************************** Main Gui Routines ********************************
MainGuiDropFiles:
    if Dirty() {
        gosub Unsaved
        IfMsgBox Cancel
            return
    }
    Loop, parse, A_GuiEvent, `n
    {
        IniFile := A_LoopField
        break
    }
    gosub ReadFile
return

MainGuiClose:
    if Dirty()
        gosub Unsaved
    IfMsgBox Cancel
        return
ExitApp

MainGuiContextMenu:
    if (A_GuiControl = "SectionList") {
        GuiControl Main:Focus, Sectionlist
        gosub UpdateKeyList
        gosub UpdateSectionMenu
        Menu SecEdit, Show, %A_GuiX%, %A_GuiY%
    }
    else if (A_GuiControl = "KeyList") {
        GuiControl Main:Focus, Keylist
        gosub UpdateKeyMenu
        Menu KeyEdit, Show, %A_GuiX%, %A_GuiY%
    }
return

MainGuiSize:
    Anchor("SectionList", "h1")
    Anchor("KeyList", "h1 w1")
    Anchor("IniFile", "w1", true)
    
    Gui Main:Default
    Gui Main:ListView, SectionList
    LV_Modify(LV_GetNext(), "Vis")
    Gui Main:ListView, KeyList
    LV_Modify(LV_GetNext(), "Vis")
    
    LV_ModifyCol(1, "AutoHdr")
return

SecEditGuiSize:
    Anchor("NewSection", "w1")
    Anchor("SecOk", "x1", true)
    Anchor("SecCancel", "x1", true)
return

KeyEditGuiSize:
    Anchor("NewKey", "w1")
    Anchor("NewValue", "w1")
    Anchor("KeyOK", "x1", true)
    Anchor("KeyCancel", "x1", true)
return

ResizeSection()
{
    static LVM_GETCOLUMNWIDTH := 0x101D
    global SectionListHwnd
    
    Gui Main:Default
    Gui Main:ListView, SectionList
    LV_ModifyCol()
    
    SendMessage 0x101D, 0, 0, , % "ahk_id " SectionListHwnd
    ColumnWidth := ErrorLevel + 25
    if (ColumnWidth < 75)
        ColumnWidth := 75
    if (ColumnWidth > 400)
        ColumnWidth := 400

    WinGetPos, , , winW, , A
    GuiControl Main:Move, SectionList, % "w" ColumnWidth
    GuiControl Main:Move, KeyList, % "x" ColumnWidth + 16 " w" winW - ColumnWidth - 32
    
    Anchor("SectionList")
    Anchor("KeyList")

    LV_ModifyCol(1, "AutoHdr")
}

Help:
    Gui Help:Show, , Help
return

About:
    Gui About:Show, , About
return

WM_NOTIFY(wParam, lParam)
{
    static LVN_ENDSCROLL := 4294967115
    
    hWnd := NumGet(lParam+0, 0, "UPtr")
    Notification := NumGet(lParam+0, 2 * A_PtrSize, "UInt")
    if (Notification = LVN_ENDSCROLL)
        WinSet Redraw, , ahk_id %hWnd%
}
    

;*************************** Routines for dealing with files *******************
NewWindow:
    Run %A_ScriptFullPath%
return

NewFile:
    if Dirty() {
        gosub Unsaved
        IfMsgBox Cancel
            return
    }
    
    IniFile := ""
    GuiControl Main:, IniFile
    Gui Main:Show, , Untitled - INI Editor
    
    IniData := OrderedArray()
    IniFile := SelectedSection := SelectedKey := FileTxt := ""
    
    Gui Main:ListView, KeyList
    LV_Delete()
    Gui Main:ListView, SectionList
    LV_Delete()
    Dirty(false)
    ResizeSection()
    
    Menu FileMenu, Disable, Print`tCtrl+P
    Menu FileMenu, Disable, View Raw`tF8
    gosub UpdateSectionMenu
return

OpenFile:
    if Dirty() {
        gosub Unsaved
        IfMsgBox Cancel
            return
    }
    
    Gui Main:+OwnDialogs
    FileSelectFile IniFile, 8, , Open, Configuration Files (*.ini; *.inf; *.cfg; *.conf; *.txt)
    if (ErrorLevel)
        return
    GuiControl Main:, IniFile, % IniFile
    SplitPath IniFile, FileName
    Gui Main:Show, , %FileName% - INI Editor
    Menu FileMenu, Enable, Print`tCtrl+P
    Menu FileMenu, Enable, View Raw`tF8
    gosub ReadFile
return

RevertFile:
    Gui Main:+OwnDialogs
    MsgBox, 276, Revert Changes, You will lose all of the changes made since the last save.`n`nAre you sure?
    IfMsgBox Yes
        gosub ReadFile
return

ReadFile:
    IniData := OrderedArray()
    FileRead FileTxt, % IniFile

    GuiControl Main:, IniFile, %IniFile%
    SplitPath IniFile, FileName
    Gui Main:Show, , %FileName% - INI Editor
    Menu FileMenu, Enable, Print`tCtrl+P
    Menu FileMenu, Enable, View Raw`tF8

    Gui Main:Default
    Gui Main:ListView, KeyList
    LV_Delete()
    Gui Main:ListView, SectionList
    LV_Delete()
    
    Dirty(false)
    IniRead SectionList, %IniFile%
    Loop Parse, SectionList, `n
    {
        NewSection := A_LoopField
        IniRead KeyList, %IniFile%, %NewSection%
        Loop Parse, KeyList, `n
        {
            RegExMatch(A_Loopfield, "([^=]+?)\h*=\h*(.*)$", Key)
            IniData[NewSection, Key1] := Trim(Key2, "`r`n")
        }
        Gui Main:ListView, SectionList
        LV_Add("", NewSection)
    }
    LV_Add()
    LV_Modify(1, "Select Focus")
    ResizeSection()
return

Unsaved:
    MsgBox, 3, INI Editor, The database has been changed.`n`nDo you want to save the changes?
    IfMsgBox Yes
        if (IniFile = "")
            gosub SaveFileAs
        else
            gosub SaveFile
return

SaveFile:
    Dirty(false)
    
    FileDelete % IniFile
    FileAppend % FileTxt, % IniFile
    
    Progress B2 ZH0, %A_Space%, File Saved
    Sleep 500
    Progress Off
return

SaveFileAs:
    Gui Main:+OwnDialogs
    FileSelectFile NewFile, S16, %IniFile%, Save As, Configuration Files (*.ini; *.inf; *.cfg; *.conf; *.txt)
    
    if not ErrorLevel {
        if (IniFile = "") {
            FileDelete %NewFile%
            FileAppend , , %NewFile%
        }
        else if (IniFile <> NewFile) {
            FileCopy %IniFile%, %NewFile%, 1
        }
        IniFile := NewFile
        GuiControl Main:, IniFile, %IniFile%
        SplitPath IniFile, FileName
        Gui Main:Show, , %FileName% - INI Editor
        gosub SaveFile
    }
return

PrintFile:
    if Dirty() {
        gosub Unsaved
        IfMsgBox Cancel
            return
    }
    Run Notepad.exe /p %iniFile%, , Hide
return

ViewRaw:
    if Dirty() {
        gosub Unsaved
        IfMsgBox Cancel
            return
    }
    GuiControl Disable, SectionList
    GuiControl Disable, KeyList
    Menu MyMenuBar, Disable, File
    
    RunWait Notepad.exe %iniFile%
    gosub ReadFile
    
    GuiControl Enable, SectionList
    GuiControl Enable, KeyList
    GuiControl Focus, SectionList
    Menu MyMenuBar, Enable, File
return

;___Keeps track of whether the data in memory and the file on disk are in sync
Dirty(Setting := "")
{
    static Dirty := ""
    global IniFile
    
    if (Setting <> "") {
        Dirty := Setting
        Menu FileMenu, % (Dirty && Inifile) ? "Enable" : "Disable", Revert`tCtrl+R,
        Menu FileMenu, % (Dirty && Inifile) ? "Enable" : "Disable", Save`tCtrl+S        
    }
    return Dirty
}


;**************************** Routines dealing with Sections of keys ***********
AddSection:
    Gui SecEdit:+OwnerMain
    Gui Main:Default
    Gui Main:ListView, SectionList
    Row := LV_GetNext()
    if (Row = 0 || Row = LV_GetCount())
        EditType := "Add"
    else
        EditType := "AddHere"
    
    Gui SecEdit:Show, , Add New Section
    GuiControl SecEdit:Focus, NewSection
    GuiControl SecEdit:, NewSection
return

ModifySection:
    Gui SecEdit:+OwnerMain
    EditType := "Modify"
    GuiControl SecEdit:, NewSection, %SelectedSection%
    GuiControl SecEdit:Focus, NewSection
    SendMessage 0xB1, 0, -1, , ahk_id %SectionNameHwnd% ; Select all
    Gui SecEdit:Show, , Modify Section Header
return

;__This runs everytime the user changes the section name edit box
SectionName:
    Gui SecEdit:Submit, NoHide
    Gui Main:Default
    Gui Main:ListView, SectionList
    if (NewSection = "") {
        GuiControl SecEdit:, SecError, The Section Name must not be blank
        GuiControl SecEdit:Disable, SecOK
    }
    else if InStr(EditType, "Add") && IniData.HasKey(NewSection) {
        GuiControl SecEdit:, SecError, This Section Name is already being used
        GuiControl SecEdit:Disable, SecOK
    }
    else if (EditType = "Modify" && SelectedSection <> NewSection && IniData.HasKey(NewSection)) {
        GuiControl SecEdit:, SecError, This Section Name is already being used
        GuiControl SecEdit:Disable, SecOK
    }
    else {
        GuiControl SecEdit:, SecError
        GuiControl SecEdit:Enable, SecOK
    }
return

SecEditOK:
    Gui SecEdit:Submit
    Gui Main:Default
    Gui Main:ListView, SectionList

    if (EditType = "Add") {
        Dirty(true)
        IniData[NewSection] := OrderedArray()
        FileTxt .= "`r`n[" NewSection "]`r`n"
        LV_Delete()
        for k, v in IniData
            LV_Add("", k)
        LV_Add()
        LV_Modify(LV_GetCount() - 1, "Vis Select Focus")
    }
    else if (EditType = "AddHere") {
        Dirty(true)
        Gui Main:Default
        Gui Main:ListView, SectionList
        IniData.InsertBefore(SelectedSection, NewSection, OrderedArray())
        Pos := InStr(FileTxt, "[" SelectedSection "]")
        FileTxt := SubStr(FileTxt, 1, Pos - 1) . "`r`n[" NewSection "]`r`n" . SubStr(FileTxt, Pos)
        Row := LV_GetNext()
        LV_Delete()
        for k, v in IniData
            LV_Add("", k)
        LV_Add()
        LV_Modify(Row, "Select Focus Vis")
        GuiControl Main:+Redraw, SectionList
    }
    else if (EditType = "Modify") {
        Dirty(true)
        IniData[NewSection] := IniData[SelectedSection]
        IniData.Remove(SelectedSection)
        StringReplace FileTxt, Filetxt, % "[" SelectedSection "]", % "[" NewSection "]"
        LV_Modify(LV_GetNext(), "Vis Select Focus", NewSection)
    }
    ResizeSection()
return

SecEditGuiEscape:
SecEditCancel:
    Gui SecEdit:Hide
return

;___Runs when the user changes something in the section list view
SectionProc:
    Gui Main:ListView, SectionList 
    if (LV_GetNext() <> 0)
        LV_GetText(SelectedSection, LV_GetNext())
    else {
        SelectedSection := ""
        Gui Main:ListView, KeyList
        LV_Delete()
    }

    if (A_GuiEvent == "I" && InStr(ErrorLevel, "S", true)) {
        SetTimer UpdateKeyList, -100
    }
    else if (A_GuiEvent = "Normal")
        Send {Escape}
    else if (A_GuiEvent = "DoubleClick")
        if LV_GetNext()
            gosub ModifySection
        else
            gosub AddSection
return

UpdateKeyList:
    Gui Main:Default
    Gui Main:ListView, KeyList
    GuiControl Main:-Redraw, KeyList
    LV_Delete()
    for NewKey, NewValue in IniData[SelectedSection]
        LV_Add("", NewKey, NewValue)
    LV_Add()
    LV_ModifyCol(1, "AutoHdr")
    LV_Modify(1, "Select Focus")
    GuiControl Main:+Redraw, KeyList
return

CopySection:
    Pos := InStr(FileTxt, "[" SelectedSection "]")
    End := RegExMatch(FileTxt, "\R+(;|\[|$)", "", Pos + 1)
    Clipboard := SubStr(FileTxt, Pos, End - Pos + 2) . "`r`n" 
    gosub UpdateKeyList
return

CutSection:
    Dirty(true)
    Gui Main:Default
    Gui Main:ListView, KeyList
    LV_Delete()
    gosub CopySection
    StringReplace FileTxt, FileTxt, % Clipboard
    IniData.Remove(SelectedSection)
    Gui Main:ListView, SectionList
    LV_Delete(LV_GetNext())
    LV_Modify(LV_GetNext(0, "F"), "Select Focus Vis")
    ResizeSection()
return

DelSection:
    SavedClip := ClipboardAll
    gosub CutSection
    Clipboard := SavedClip
return

PasteSection:  
    Dirty(true)
    Gui Main:Default
    Gui Main:ListView, SectionList
    RegExMatch(Clipboard, "^\[\K[^]]+", NewSection)
    while IniData.HasKey(NewSection)
        if (A_Index = 1)
            NewSection .= "(1)"
        else
            NewSection := RegExReplace(NewSection, "\(\d+\)$", "(" A_Index ")")
    
    if LV_GetNext() = 0 or LV_GetNext() = LV_GetCount() {
        FileTxt .= RegExReplace(Clipboard, "\[[^]]+]", "[" NewSection "]")
        IniData[NewSection] := OrderedArray()
    }
    else {
        Pos := InStr(FileTxt, "[" SelectedSection "]")
        FileTxt := (Pos > 1 ? SubStr(FileTxt, 1, Pos - 1) : "") 
                 . RegExReplace(Clipboard, "\[[^]]+]", "[" NewSection "]") 
                 . SubStr(FileTxt, Pos)
        IniData.InsertBefore(SelectedSection, NewSection, OrderedArray())
    }

    Loop Parse, Clipboard, `n
    {
        if (A_Index = 1)
            continue
        RegExMatch(A_Loopfield, "([^=]+?)\h*=\h*(.*)$", Key)
        IniData[NewSection, Key1] := Trim(Key2, "`r`n")
    }
    Row := LV_GetNext()
    GuiControl Main:-Redraw, SectionList
    LV_Delete()
    for k, v in IniData
        LV_Add("", k)
    LV_Add()
    LV_Modify(Row, "Select Focus Vis")
    ResizeSection()
    GuiControl Main:+Redraw, SectionList
return

;**************************** Routines dealing with individual Key-Value pairs**
AddKey:
    Gui KeyEdit:+OwnerMain
    Gui Main:Default
    Gui Main:ListView, KeyList
    
    Row := LV_GetNext()
    if (Row = 0 || Row = LV_GetCount())
        EditType := "Add"
    else
        EditType := "AddHere"
    
    Gui KeyEdit:Show, , Add New Key
    GuiControl KeyEdit:Focus, NewKey
    GuiControl KeyEdit:, NewKey
    GuiControl KeyEdit:, NewValue
return

ModifyKey:
    Gui KeyEdit:+OwnerMain
    EditType := "Modify"
    GuiControl KeyEdit:Focus, NewKey
    GuiControl KeyEdit:, NewKey, %SelectedKey%
    GuiControl KeyEdit:, NewValue, %SelectedValue%
    SendMessage 0xB1, 0, -1, , ahk_id %KeyNameHwnd% ; Select all
    Gui KeyEdit:Show, AutoSize, Modify Key
return

;__This runs everytime the user changes the key name edit box
KeyName:
    Gui KeyEdit:Submit, NoHide
    Gui Main:Default
    Gui Main:ListView, KeyList
    if (NewKey = "") {
        GuiControl KeyEdit:, KeyError, The Key Name must not be blank
        GuiControl KeyEdit:Disable, KeyOK
    }
    else if InStr(EditType, "Add") && IniData[SelectedSection].HasKey(NewKey) {
        GuiControl KeyEdit:, KeyError, This Key Name is already being used
        GuiControl KeyEdit:Disable, KeyOK
    }
    else if (EditType = "Modify" && SelectedKey <> NewKey && IniData[SelectedSection].HasKey(NewKey)) {
        GuiControl KeyEdit:, KeyError, This Key Name is already being used
        GuiControl KeyEdit:Disable, KeyOK
    }
    else {
        GuiControl KeyEdit:, KeyError
        GuiControl KeyEdit:Enable, KeyOK
    }
return

KeyEditOK:
    Gui Main:+OwnDialogs
    Gui KeyEdit:Submit
    Gui Main:Default    
    Gui Main:ListView, KeyList
    
    Pos := InStr(FileTxt, "[" SelectedSection "]") + StrLen(SelectedSection) + 2
    if (EditType = "Add") {
        Dirty(true)
        IniData[SelectedSection, NewKey] := NewValue
        Pos := RegExMatch(FileTxt, "\R+;|\R+\[", "", Pos)
        FileTxt := SubStr(FileTxt, 1, Pos - 1) . "`r`n" . NewKey . " = " . NewValue . SubStr(FileTxt, Pos)
        LV_Add("Select", NewKey, NewValue)
        LV_Modify(LV_GetNext(), "Vis Select Focus")
    }
    else if (EditType = "AddHere") {
        Dirty(true)
        IniData[SelectedSection].InsertBefore(SelectedKey, NewKey, NewValue)
        Pos := RegExMatch(FileTxt, "\R+\Q" SelectedKey "\E", "", Pos)
        FileTxt := SubStr(FileTxt, 1, Pos - 1) . "`r`n" . NewKey . " = " . NewValue . SubStr(FileTxt, Pos)
        Row := LV_GetNext()
        LV_Delete()
        for k, v in IniData[SelectedSection]
            LV_Add("", k, v)
        LV_Modify(Row, " Select Vis Focus")
    }
    else if (EditType = "Modify") {
        Dirty(true)
        IniData[SelectedSection].Remove(SelectedKey)
        IniData[SelectedSection, NewKey] := NewValue
        FileTxt := RegExReplace(FileTxt
                 , "(\R)\Q" SelectedKey "\E(\h*=\h*).*?(?=\R|$)"
                 , "$1" NewKey "$2" NewValue, "", 1, Pos)
        LV_Modify(LV_GetNext(), "Vis Select Focus", NewKey, NewValue)
    }
    
    LV_ModifyCol(1, "AutoHdr")
return

KeyEditGuiEscape:
KeyEditCancel:
    Gui KeyEdit:Hide
return

CopyKey:
    Pos := InStr(FileTxt, "[" SelectedSection "]") + StrLen(SelectedSection) + 2
    Pos := RegExMatch(FileTxt, "\R\K\Q" SelectedKey "\E\h*=\h*[^\r\n]+", NewKey, Pos)
    Clipboard := Trim(NewKey, "`r`n" A_Space)
return

CutKey:
    Dirty(true)
    Gui Main:Default
    Gui Main:ListView, KeyList
    gosub CopyKey
    FileTxt := SubStr(FileTxt, 1, Pos -1) . SubStr(FileTxt, Pos + StrLen(ClipBoard) + 2)
    IniData[SelectedSection].Remove(SelectedKey)
    LV_Delete(LV_GetNext())
    LV_Modify(LV_GetNext(0, "F"), "Select Focus Vis")
    LV_ModifyCol(1, "AutoHdr")
return

DelKey:
    SavedClip := ClipboardAll
    gosub CutKey
    Clipboard := SavedClip
return

PasteKey:
    Dirty(true)
    Gui Main:Default
    Gui Main:ListView, KeyList
    RegExMatch(ClipBoard, "([^=]+?)\h*=\h*(.*)$", Key)

    while IniData[SelectedSection].HasKey(Key1)
        if (A_Index = 1)
            Key1 .= "(1)"
        else
            Key1 := RegExReplace(Key1, "\(\d+\)$", "(" A_Index ")")
    
    if LV_GetNext() = 0 or LV_GetNext() = LV_GetCount() {
        IniData[SelectedSection, Key1] := Key2
        Pos := InStr(FileTxt, "[" SelectedSection "]") + StrLen(SelectedSection) + 2
        Pos := RegExMatch(FileTxt, "\R+;|\R+\[|$", "", Pos)
        FileTxt := SubStr(FileTxt, 1, Pos - 1) . "`r`n" . Key1 . " = " . Key2 . SubStr(FileTxt, Pos)
    }
    else {
        IniData[SelectedSection].InsertBefore(SelectedKey, Key1, Key2)
        Pos := InStr(FileTxt, "[" SelectedSection "]") + StrLen(SelectedSection) + 2
        Pos := RegExMatch(FileTxt, "\R+\Q" SelectedKey "\E", "", Pos)
        FileTxt := SubStr(FileTxt, 1, Pos - 1) . "`r`n" . Key1 . " = " . Key2 . SubStr(FileTxt, Pos)
    }

    Row := LV_GetNext()
    LV_Delete()
    for k, v in IniData[SelectedSection]
        LV_Add("", k, v)
    LV_Add()
    LV_Modify(Row, "Focus Select Vis")
    LV_ModifyCol(1, "AutoHdr")
return

;___Runs when the user changes something in the key list view
KeyProc:
    Critical
    Gui Main:Default
    Gui Main:ListView, KeyList
    
    if (LV_GetNext() <> 0) {
        LV_GetText(SelectedKey, LV_GetNext(), 1)
        LV_GetText(SelectedValue, LV_GetNext(), 2)
    }
    else {
        SelectedKey := ""
        SelectedValue := ""
    }
    
    if (A_GuiEvent = "DoubleClick" && SelectedSection <> "") {
        if LV_GetNext()
            gosub ModifyKey
        else
            gosub AddKey
    }
    
    if GuiControlGetFocus("Keylist")
        gosub UpdateKeyMenu
    else
        gosub UpdateSectionMenu
return

UpdateKeyMenu:
    Gui Main:Default
    Gui Main:ListView, KeyList\
    if (SelectedSection <> "") {
        Menu KeyEdit, Enable, Add Key...`tCtrl+A
        if (Clipboard ~= "^[^=]+=.+$")
            Menu KeyEdit, Enable, Paste Key`tCtrl+V
        else
            Menu KeyEdit, Disable, Paste Key`tCtrl+V
    }
    else {
        Menu KeyEdit, Disable, Add Key...`tCtrl+A
        Menu KeyEdit, Disable, Paste Key`tCtrl+V
    }
    
    if LV_GetNext() = 0 || LV_GetNext() = LV_GetCount() {
        Menu KeyEdit, Disable, Modify Key...`tCtrl+M
        Menu KeyEdit, Disable, Delete Key`tDel
        Menu KeyEdit, Disable, Cut Key`tCtrl+X
        Menu KeyEdit, Disable, Copy Key`tCtrl+C
    }
    else {
        Menu KeyEdit, Enable, Modify Key...`tCtrl+M
        Menu KeyEdit, Enable, Delete Key`tDel
        Menu KeyEdit, Enable, Cut Key`tCtrl+X
        Menu KeyEdit, Enable, Copy Key`tCtrl+C
    }
    
    Menu MyMenuBar, Delete
    Menu MyMenuBar, Add, File, :FileMenu
    Menu, MyMenuBar, Add, Edit, :KeyEdit
    Menu MyMenuBar, Add, Help, :About
    Gui Main:Menu, MyMenuBar

    GuiControl Main:-Grid, SectionList
    GuiControl Main:+Grid, KeyList
return

UpdateSectionMenu:
    Gui Main:Default
    Gui Main:ListView, SectionList
    Menu SecEdit, % !(Clipboard ~= "^\[\K[^]]+") ? "Disable" : "Enable", Paste Section`tCtrl+V
    if LV_GetNext() = 0 || LV_GetNext() = LV_GetCount() {
        Menu SecEdit, Disable, Modify Section Name...`tCtrl+M
        Menu SecEdit, Disable, Delete Section`tDel
        Menu SecEdit, Disable, Cut Section`tCtrl+X
        Menu SecEdit, Disable, Copy Section`tCtrl+C
    }
    else {
        Menu SecEdit, Enable, Modify Section Name...`tCtrl+M
        Menu SecEdit, Enable, Delete Section`tDel
        Menu SecEdit, Enable, Cut Section`tCtrl+X
        Menu SecEdit, Enable, Copy Section`tCtrl+C
    }
    
    Menu MyMenuBar, Delete
    Menu MyMenuBar, Add, File, :FileMenu
    Menu, MyMenuBar, Add, Edit, :SecEdit
    Menu MyMenuBar, Add, Help, :About
    Gui Main:Menu, MyMenuBar

    GuiControl Main:+Grid, SectionList
    GuiControl Main:-Grid, KeyList
return 

GuiControlGetFocus(ID)
{
    GuiControlGet out, FocusV
    return (out = ID)
}

MakeGui:
    Gui Main:Margin, 8, 8
    Gui Main:+Resize +MinSize410x215
    Gui Main:Font, s10, Verdana
	Gui Main:Add, Text, r1 Section, Now Editing:
	Gui Main:Add, Text, x+8 yp w590 r1 0x8000 vIniFile
    Gui Main:Add, ListView, % "AltSubmit NoSortHdr Grid -Multi xm y+8 "
                            . "r20 w75 gSectionProc HWNDSectionListHwnd "
                            . "vSectionList ", Section
    Gui Main:Add, ListView, % "AltSubmit NoSortHdr -Multi x+8 "
                            . "r20 w600 gKeyProc vKeyList", Key|Value
    
    Gui SecEdit:+OwnerMain
    Gui SecEdit:Margin, 8, 8
    Gui SecEdit:+Resize +MinSize +MinSize270x +MaxSize +MaxSize800x
    Gui SecEdit:Font, s10, Verdana
    Gui SecEdit:Add, Text, , Section Name:
    Gui SecEdit:Add, Edit, r1 w300 HWNDSectionNameHwnd vNewSection gSectionName
    Gui SecEdit:Add, Text, cRed vSecError xm w300 r1
    Gui SecEdit:Add, Button, xm+142 w75 h25 gSecEditOK vSecOK Default, OK
    Gui SecEdit:Add, Button, x+8 w75 h25 gSecEditCancel vSecCancel, Cancel
    
    Gui KeyEdit:+OwnerMain
    Gui KeyEdit:Margin, 8, 8
    Gui KeyEdit:+Resize +MinSize +MinSize240x +MaxSize +MaxSize800x
    Gui KeyEdit:Font, s10, Verdana
    Gui KeyEdit:Add, Text, ym+3 r1, Key Name:
    Gui KeyEdit:Add, Edit, w425 r1 -WantReturn HWNDKeyNameHwnd vNewKey gKeyName
    Gui KeyEdit:Add, Text, r1, Key Value:
    Gui KeyEdit:Add, Edit, w425 r3 -WantReturn vNewValue
    Gui KeyEdit:Add, Text, cRed vKeyError w300 r1
    Gui KeyEdit:Add, Button, xm+267 w75 h25 Default vKeyOK gKeyEditOK, OK
    Gui KeyEdit:Add, Button, x+8 w75 h25 gKeyEditCancel vKeyCancel, Cancel    

    Gui Help:+OwnerMain
    Gui Help:Font, s9
    Gui Help:Font, , Courier New
    Gui Help:Font, , Consolas
    Gui Help:Add, Text, w700, % ""
            . "Menu Commands:`n`n"
            . "File Menu`n"
            . "     New`t- Loads a blank ini-file.`n"
            . "     New Window`t- Starts a new instance of INI Editor.`n"
            . "     Open...`t- Opens an ini-file.`n"
            . "     Revert`t- Cancels any changes since the last save.`n"
            . "     Save`t- Saves the file currently being edited.`n"
            . "     Save As`t- Saves the current file under a new name.`n"
            . "     View Raw`t- Opens the file in Notepad. Changes are read back into `n"
            . "`t`t     INI Editor when the Notepad window closes.`n"
            . "     Print`t- Sends the ini-file to the default printer.`n"
            . "     Exit`t- Closes the currently running instance.`n`n"
            . "Edit Menu`n"
            . "     Add Section/Key...`t`t- Adds a new Section/Key above the current row.`n"
            . "     Modify Section/Key...`t- Edits the Section Name or Key Name and Value.`n"
            . "     Delete Section/Key`t`t- Removes the Section/Key.`n"
            . "     Cut Section/Key`t`t- Copies the Section/Key to the Clipboard and removes it from list.`n"
            . "     Copy Section/Key`t`t- Copies the Section/Key to the Clipboard.`n"
            . "     Paste Section/Key`t`t- Pastes the Section/Key above the current row.`n`n"
            . "Help Menu`n"
            . "     Help`t`t- Displays this dialog.`n"
            . "     About INI Editor`t- Displays author and license information.`n`n"
            . "Double-clicking On a ListView will bring up the appropriate Add or Modify dialog.`n`n"
            . "Drag and drop to the scripts icon or the main GUI are both supported."
            
    Gui About:+OwnerMain
    Gui About:Font, s9
    Gui About:Font, , Courier New
    Gui About:Font, , Consolas
    Gui About:Add, Text, w200 Center, % ""
            . "INI Editor`n"
            . "© Robert Ryan 2013"
    Gui About:Add, Link, xm+45, <a href="mailto:rbrtryn@gmail.com">rbrtryn@gmail.com</a>
    Gui About:Add, Link, xm+70, <a href="http://opensource.org/licenses/MIT">License</a>

    Menu FileMenu, Add, New`tCtrl+N, NewFile
    Menu FileMenu, Add, Open...`tCtrl+O, OpenFile
    Menu FileMenu, Add, Revert`tCtrl+R, RevertFile
    Menu FileMenu, Add, Save`tCtrl+S, SaveFile
    Menu FileMenu, Add, Save As...`tCtrl+Shift+S, SaveFileAs
    Menu FileMenu, Add
    Menu FileMenu, Add, New Window`tCtrl+W, NewWindow
    Menu FileMenu, Add, View Raw`tF8, ViewRaw
    Menu FileMenu, Add
    Menu FileMenu, Add, Print`tCtrl+P, PrintFile, P5
    Menu FileMenu, Add
    Menu FileMenu, Add, Exit, MainGuiClose
    
    Menu KeyEdit, Add, Add Key...`tCtrl+A, AddKey
    Menu KeyEdit, Add, Modify Key...`tCtrl+M, ModifyKey
    Menu KeyEdit, Add
    Menu KeyEdit, Add, Delete Key`tDel, DelKey
    Menu KeyEdit, Add, Cut Key`tCtrl+X, CutKey
    Menu KeyEdit, Add, Copy Key`tCtrl+C, CopyKey
    Menu KeyEdit, Add, Paste Key`tCtrl+V, PasteKey
    
    Menu SecEdit, Add, Add Section...`tCtrl+A, AddSection
    Menu SecEdit, Add, Modify Section Name...`tCtrl+M, ModifySection
    Menu SecEdit, Add
    Menu SecEdit, Add, Delete Section`tDel, DelSection
    Menu SecEdit, Add, Cut Section`tCtrl+X, CutSection
    Menu SecEdit, Add, Copy Section`tCtrl+C, CopySection
    Menu SecEdit, Add, Paste Section`tCtrl+V, PasteSection
    
    Menu About, Add, Help, Help
    Menu About, Add
    Menu About, Add, About INI Editor, About
    
    Menu MyMenuBar, Add, File, :FileMenu
    Menu MyMenuBar, Add, Edit, :SecEdit
    Menu MyMenuBar, Add, Help, :About
    Gui Main:Menu, MyMenuBar
return

/* Function: Anchor
    Defines how controls should be automatically positioned relative to the new dimensions of a window when resized.
Parameters:
    i - a control HWND, associated variable name or ClassNN to operate on
    a - (optional) one or more of the anchors: 'x', 'y', 'w' (width) and 'h' (height),
        optionally followed by a relative factor, e.g. "x h0.5"
    r - (optional) true to redraw controls, recommended for GroupBox and Button types
Examples:
> "x y"  ; will bound a control to its relative postion from ( right of GUI // bottom of GUI )
> "w0.5" ; any change in the width of the window will resize the width of the control on a 2:1 ratio
> "h" ; will resize the control as much as height has increased // decreased
> "w" ; will resize the control as much as width has increased // decreased

Remarks:
    To assume the current window size for the new bounds of a control (i.e. resetting) simply omit the second and third parameters.
    However if the control had been created with DllCall() and has its own parent window,
        the container AutoHotkey created GUI must be made default with the +LastFound option prior to the call.
    For a complete example see anchor-example.ahk.

     */
Anchor(i, a = "", r = false) {
    static c, cs = 12, cx = 255, cl = 0, g, gs = 8, gl = 0, gpi, gw, gh, z = 0, k = 0xffff
    If z = 0
        VarSetCapacity(g, gs * 99, 0), VarSetCapacity(c, cs * cx, 0), z := true
    If (!WinExist("ahk_id" . i)) {
        GuiControlGet, t, Hwnd, %i%
        If ErrorLevel = 0
            i := t
        Else ControlGet, i, Hwnd, , %i%
    }
    VarSetCapacity(gi, 68, 0), DllCall("GetWindowInfo", "UInt", gp := DllCall("GetParent", "UInt", i), "UInt", &gi)
        , giw := NumGet(gi, 28, "Int") - NumGet(gi, 20, "Int"), gih := NumGet(gi, 32, "Int") - NumGet(gi, 24, "Int")
    If (gp != gpi) {
        gpi := gp
        Loop, %gl%
            If (NumGet(g, cb := gs * (A_Index - 1)) == gp) {
                gw := NumGet(g, cb + 4, "Short"), gh := NumGet(g, cb + 6, "Short"), gf := 1
                Break
            }
        If (!gf)
            NumPut(gp, g, gl), NumPut(gw := giw, g, gl + 4, "Short"), NumPut(gh := gih, g, gl + 6, "Short"), gl += gs
    }
    ControlGetPos, dx, dy, dw, dh, , ahk_id %i%
    Loop, %cl%
        If (NumGet(c, cb := cs * (A_Index - 1)) == i) {
            If a =
            {
                cf = 1
                Break
            }
            giw -= gw, gih -= gh, as := 1, dx := NumGet(c, cb + 4, "Short"), dy := NumGet(c, cb + 6, "Short")
                , cw := dw, dw := NumGet(c, cb + 8, "Short"), ch := dh, dh := NumGet(c, cb + 10, "Short")
            Loop, Parse, a, xywh
                If A_Index > 1
                    av := SubStr(a, as, 1), as += 1 + StrLen(A_LoopField)
                        , d%av% += (InStr("yh", av) ? gih : giw) * (A_LoopField + 0 ? A_LoopField : 1)
            DllCall("SetWindowPos", "UInt", i, "Int", 0, "Int", dx, "Int", dy
                , "Int", InStr(a, "w") ? dw : cw, "Int", InStr(a, "h") ? dh : ch, "Int", 4)
            If r != 0
                DllCall("RedrawWindow", "UInt", i, "UInt", 0, "UInt", 0, "UInt", 0x0101) ; RDW_UPDATENOW | RDW_INVALIDATE
            Return
        }
    If cf != 1
        cb := cl, cl += cs
    bx := NumGet(gi, 48), by := NumGet(gi, 16, "Int") - NumGet(gi, 8, "Int") - gih - NumGet(gi, 52)
    If cf = 1
        dw -= giw - gw, dh -= gih - gh
    NumPut(i, c, cb), NumPut(dx - bx, c, cb + 4, "Short"), NumPut(dy - by, c, cb + 6, "Short")
        , NumPut(dw, c, cb + 8, "Short"), NumPut(dh, c, cb + 10, "Short")
    Return, true
}

; OrderedArray code by Lexikos
; Modifications and additional methods by rbrtryn
; http://tinyurl.com/lhtvalv
OrderedArray(prm*)
{
    ; Define prototype object for ordered arrays:
    static base := Object("__Set", "oaSet", "_NewEnum", "oaNewEnum"
                        , "Remove", "oaRemove", "Insert", "oaInsert", "InsertBefore", "oaInsertBefore")
    ; Create and return new ordered array object:
    return Object("_keys", Object(), "base", base, prm*)
}

oaSet(obj, prm*)
{
    ; If this function is called, the key must not already exist.
    ; Sub-class array if necessary then add this new key to the key list
    if prm.maxindex() > 2
        ObjInsert(obj, prm[1], OrderedArray())
    ObjInsert(obj._keys, prm[1])
    ; Since we don't return a value, the default behaviour takes effect.
    ; That is, a new key-value pair is created and stored in the object.
}

oaNewEnum(obj)
{
    ; Define prototype object for custom enumerator:
    static base := Object("Next", "oaEnumNext")
    ; Return an enumerator wrapping our _keys array's enumerator:
    return Object("obj", obj, "enum", obj._keys._NewEnum(), "base", base)
}

oaEnumNext(e, ByRef k, ByRef v="")
{
    ; If Enum.Next() returns a "true" value, it has stored a key and
    ; value in the provided variables. In this case, "i" receives the
    ; current index in the _keys array and "k" receives the value at
    ; that index, which is a key in the original object:
    if r := e.enum.Next(i,k)
        ; We want it to appear as though the user is simply enumerating
        ; the key-value pairs of the original object, so store the value
        ; associated with this key in the second output variable:
        v := e.obj[k]
    return r
}

oaRemove(obj, prm*)
{
    r := ObjRemove(obj, prm*)         ; Remove keys from main object
    Removed := []                     
    for k, v in obj._keys             ; Get each index key pair
        if not ObjHasKey(obj, v)      ; if key is not in main object
            Removed.Insert(k)         ; Store that keys index to be removed later
    for k, v in Removed               ; For each key to be removed
        ObjRemove(obj._keys, v, "")   ; remove that key from key list
    return r
}

oaInsert(obj, prm*)
{
    r := ObjInsert(obj, prm*)            ; Insert keys into main object
    enum := ObjNewEnum(obj)              ; Can't use for-loop because it would invoke oaNewEnum
    while enum[k] {                      ; For each key in main object
        if (k = "_keys")
            continue 
        for i, kv in obj._keys           ; Search for key in obj._keys
            if (k = kv)                  ; If found...
                continue 2               ; Get next key in main object
        ObjInsert(obj._keys, k)          ; Else insert key into obj._keys
    }
    return r
}

oaInsertBefore(obj, key, prm*)
{
    OldKeys := obj._keys                 ; Save key list
    obj._keys := []                      ; Clear key list
    for idx, k in OldKeys {              ; Put the keys before key
        if (k = key)                     ; back into key list
            break
        obj._keys.Insert(k)
    }
    
    r := ObjInsert(obj, prm*)            ; Insert keys into main object
    enum := ObjNewEnum(obj)              ; Can't use for-loop because it would invoke oaNewEnum
    while enum[k] {                      ; For each key in main object
        if (k = "_keys")
            continue 
        for i, kv in OldKeys             ; Search for key in OldKeys
            if (k = kv)                  ; If found...
                continue 2               ; Get next key in main object
        ObjInsert(obj._keys, k)          ; Else insert key into obj._keys
    }
    
    for i, k in OldKeys {                ; Put the keys after key
        if (i < idx)                     ; back into key list
            continue
        obj._keys.Insert(k)
    }
    return r
}