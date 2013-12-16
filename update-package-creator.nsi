;!include filefunc.nsh
SetCompressor /SOLID lzma
SilentInstall silent

VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "Clipjump Updater File"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "Avi Aryan"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" "Clipjump"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "(C) Avi Aryan"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "Updates Clipjump"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "9.9.2"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "9.9.2.0"

VIProductVersion "9.9.2.0"

Section "ins"
!define SF_SELECTED   1
;Var /GLOBAL filename
;Var /GLOBAL cmdp
StrCpy $0 "$EXEDIR"
sleep 1000 # let clipjump.exe close

SetOutPath "$0\..\"
file clipjump_code.ahk
;file source\*.*
ExecWait '"$EXEDIR\..\static\verpatch.exe" "$EXEDIR\..\Clipjump.exe" "9.9.2.0" /va /pv "9.9.2.0"'
Exec '$EXEDIR\..\Clipjump.exe'
SectionEnd

OutFile "clipjumpupdate_9.9.2.0.exe"