/*
WM_MOUSEMOVE() v0.01
	Callback to enable ToolTips for Controls
	Called whenever the mouse hovers over a control, this function shows a tooltip for the control over
    which it is hovering. The tooltip text is specified in a global variable called variableOfControl_TT
    
By:
	Avi Aryan
	Extracted from "Settings GUI Plug.ahk" to make it more public 
*/

WM_MOUSEMOVE()
; 
{
    static currControl, prevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
	
	;--- Descriptions --------------

	; **** Settings GUI **************************
	NEW_LIMITMAXCLIPS_TT := TXT.SET_T_limitmaxclips
	NEW_MAXCLIPS_TT := TXT.SET_T_maxclips
	NEW_THRESHOLD_TT := TXT.SET_T_threshold
	NEW_COPYBEEP_TT := TXT.SET_T_copybeep
	NEW_QUALITY_TT := TXT.SET_T_quality
	NEW_KEEPSESSION_TT := TXT.SET_T_keepsession
	NEW_ISMESSAGE_TT := TXT.SET_T_ismessage
	new_default_pformat_TT := TXT.SET_T_pformat
	NEW_DAYSTOSTORE_TT := TXT.SET_T_daystostore
	NEW_ISIMAGESTORED_TT := TXT.SET_T_images
	pst_k_TT := TXT.SET_T_pst
	actmd_k_TT := TXT.SET_T_actmd
	chnl_K_TT := TXT.SET_T_chnl
	cfilep_K_TT := TXT.SET_T_cfilep
	cfolderp_K_TT := TXT.SET_T_cfolderp
	cfiled_K_TT := TXT.SET_T_cfiled
	hldClip_K_TT := TXT.SET_T_holdClip
	PITSWP_K_TT := TXT.SET_T_pitswp
	NEW_ischannelmin_TT := TXT.SET_T_ischannelmin
	plugM_k_TT := TXT.SET_t_PLUGM
	new_PreserveClipPos_TT := TXT.SET_T_keepactivepos
	org_K_TT := TXT.SET_org
	new_startSearch_TT := TXT.SET_T_startSearch
	new_revFormat2def_TT := TXT.SET_T_revFormat2def
	hst_K_TT := TXT.SET_T_histshort
	new_winClipjump_TT := TXT.SET_T_winClipjump

	; **** Channel Organizer *********************
	chOrgToggleLeftRight_TT := TXT.ORG_toggleLeftRight
	chOrg_search_TT := TXT.ORG_search
	chorgNew_TT := TXT.ORG_createnew
	chOrgUp_TT := TXT.ORG_up
	chOrgDown_TT := TXT.ORG_down
	chOrgEdit_TT := TXT.ORG_edit
	chorg_openPastemode_TT := TXT.ORG_openPastemode
	chOrg_props_TT := TXT.ORG_props
	chOrgCut_TT := TXT.ORG_cut
	chOrgCopy_TT := TXT.ORG_copy
	chOrgDelete_TT := TXT.ORG_delete

	;---------------------------------------------

	currControl := A_GuiControl
    If (currControl <> prevControl and !InStr(currControl, " ") and !Instr(currControl, "&"))
    {
		ToolTip, ,,, 4	;remove the old Tooltip
		global Text_TT := %currControl%_TT
		SetTimer, DisplayToolTip, 650
        prevControl := currControl
    }
    return

DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip, % Text_TT,,, 4  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 8000
    return

removeToolTip:
    SetTimer, removeToolTip, Off
    ToolTip, ,,, 4
    return
}