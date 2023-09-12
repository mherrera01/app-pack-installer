; File: Utils.nsh
; Author: Miguel Herrera

;--------------------------------
; AP_SET_UI_COUNT_LIMIT
; Limit the number of digits shown in a text UI component
; (elemUI) to avoid an overflow.
; If value has more than three digits, then 999+ is displayed.

  !macro __CALL_AP_SET_UI_COUNT_LIMIT elemUI value

    Push "${elemUI}"
    Push "${value}"

    ${CallArtificialFunction} __AP_SET_UI_COUNT_LIMIT

  !macroend

  !macro __AP_SET_UI_COUNT_LIMIT

    ; value ($1) and elemUI ($0)
    System::Store Sr1r0

    StrLen $2 $1
    ${If} $2 > 3
      ${NSD_SetText} $0 "999+"
    ${Else}
      ${NSD_SetText} $0 "$1"
    ${EndIf}

    System::Store L

  !macroend

  !define AP_SET_UI_COUNT_LIMIT "!insertmacro __CALL_AP_SET_UI_COUNT_LIMIT"

;--------------------------------
; AP_CREATE_ICON_UI_ELEM
; Create an UI element, returned in the stack, to display an icon.
;
; ; x, y, w, h: Position and size of the UI element.
; ; isButton: 1 for creating a button with the ${BS_ICON} style.
;   Otherwise, just an icon UI element is shown.
; ; iName: The name of the .ico file, which must be in the
;   $PLUGINSDIR\icons\ directory.
; ; iSize: The width and heigth in pixels of the icon to load.
; ; iconVar: The variable where the handle of the icon loaded
;   will be stored. This handle must be then used in
;   user32::DestroyIcon().

  !macro __CALL_AP_CREATE_ICON_UI_ELEM x y w h isButton iName iSize iconVar

    Push "${x}"
    Push "${y}"
    Push "${w}"
    Push "${h}"
    Push "${isButton}"
    Push "${iName}"
    Push "${iSize}"

    ${CallArtificialFunction} __AP_CREATE_ICON_UI_ELEM
    Pop "${iconVar}"

  !macroend

  !macro __AP_CREATE_ICON_UI_ELEM

    ; iSize ($6), iName ($5), isButton ($4), h ($3), w ($2), y ($1), x ($0)
    System::Store Sr6r5r4r3r2r1r0

    StrCpy $5 "$PLUGINSDIR\icons\$5"
    System::Call "user32::LoadImage(i, t r5, i ${IMAGE_ICON}, i r6, i r6, i ${LR_LOADFROMFILE}) i .R0"

    ${If} $4 == 1

      ; Create a button with an icon associated
      ${NSD_CreateButton} $0 $1 $2 $3 ""
      Pop $R1
      ${NSD_AddStyle} $R1 ${BS_ICON}

      SendMessage $R1 ${BM_SETIMAGE} ${IMAGE_ICON} $R0

    ${Else}

      ; Create an UI icon
      ${NSD_CreateIcon} $0 $1 $2 $3 ""
      Pop $R1
      SendMessage $R1 ${STM_SETICON} $R0 0

    ${EndIf}

    ; Push to the stack the UI element created ($R1) and
    ; the icon handle ($R0)
    Push $R1
    Push $R0

    System::Store L

  !macroend

  !define AP_CREATE_ICON_UI_ELEM "!insertmacro __CALL_AP_CREATE_ICON_UI_ELEM"
