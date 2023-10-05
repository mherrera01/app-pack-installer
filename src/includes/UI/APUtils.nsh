; File: APUtils.nsh
; Author: Miguel Herrera

;--------------------------------
; AP_SET_UI_NUM_LIMIT
; Set a positive number to a text UI element by limiting the digits
; shown. If maxDigits = 3 and value >= 1000, then 999+ is displayed.
;
; - elemUI: The text UI element
; - value: The integer value (positive) to display
; - maxDigits: The max number of digits allowed in the UI element.
;   Must be greater than 0.

  !macro __CALL_AP_SET_UI_NUM_LIMIT elemUI value maxDigits

    Push "${elemUI}"
    Push "${value}"
    Push "${maxDigits}"

    ${CallArtificialFunction} __AP_SET_UI_NUM_LIMIT

  !macroend

  !macro __AP_SET_UI_NUM_LIMIT

    ; maxDigits ($2), value ($1) and elemUI ($0)
    System::Store Sr2r1r0

    ; Get the number digits
    StrLen $3 $1

    ; Check that the arguments are valid
    ${If} $1 >= 0
    ${AndIf} $2 > 0

    ; The value is greater than the max number of digits
    ${AndIf} $3 > $2

      IntFmt $3 "%0$2u" 0
      StrCpy $3 "1$3"
      IntOp $3 $3 - 1

      ${NSD_SetText} $0 "$3+"

    ${Else}
      ${NSD_SetText} $0 "$1"
    ${EndIf}

    System::Store L

  !macroend

  !define AP_SET_UI_NUM_LIMIT "!insertmacro __CALL_AP_SET_UI_NUM_LIMIT"

;--------------------------------
; AP_LOAD_ICON
; Load an icon from the file given. Its handle is returned in the
; stack, and it must be then destroyed with user32::DestroyIcon().
;
; - name: The name of the .ico file, which must be in the
;   $PLUGINSDIR\icons\ directory.
; - size: The width and height in pixels of the icon to load.

  !macro __CALL_AP_LOAD_ICON name size

    Push "${name}"
    Push "${size}"

    ${CallArtificialFunction} __AP_LOAD_ICON

  !macroend

  !macro __AP_LOAD_ICON

    ; size ($1) and name ($0)
    System::Store Sr1r0

    StrCpy $0 "$PLUGINSDIR\icons\$0"
    System::Call "user32::LoadImage(i, t r0, i ${IMAGE_ICON}, i r1, i r1, i ${LR_LOADFROMFILE}) i .s"

    System::Store L

  !macroend

  !define AP_LOAD_ICON "!insertmacro __CALL_AP_LOAD_ICON"

;--------------------------------
; AP_CREATE_ICON_UI_ELEM
; Create an UI element, returned in the stack, to display an icon.
;
; - x, y, w, h: Position and size of the UI element.
; - isButton: 1 for creating a button with the ${BS_ICON} style.
;   Otherwise, just an icon UI element is shown.
; - hIcon: The handle of the icon to display.

  !macro __CALL_AP_CREATE_ICON_UI_ELEM x y w h isButton hIcon

    Push "${x}"
    Push "${y}"
    Push "${w}"
    Push "${h}"
    Push "${isButton}"
    Push "${hIcon}"

    ${CallArtificialFunction} __AP_CREATE_ICON_UI_ELEM

  !macroend

  !macro __AP_CREATE_ICON_UI_ELEM

    ; hIcon ($5), isButton ($4), h ($3), w ($2), y ($1), x ($0)
    System::Store Sr5r4r3r2r1r0

    ${If} $4 == 1

      ; Create a button with an icon associated
      ${NSD_CreateButton} $0 $1 $2 $3 ""
      Pop $R0
      ${NSD_AddStyle} $R0 ${BS_ICON}

      SendMessage $R0 ${BM_SETIMAGE} ${IMAGE_ICON} $5

    ${Else}

      ; Create an UI icon
      ${NSD_CreateIcon} $0 $1 $2 $3 ""
      Pop $R0
      SendMessage $R0 ${STM_SETICON} $5 0

    ${EndIf}

    ; Push to the stack the UI element created
    Push $R0

    System::Store L

  !macroend

  !define AP_CREATE_ICON_UI_ELEM "!insertmacro __CALL_AP_CREATE_ICON_UI_ELEM"
