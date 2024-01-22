; File: ToolBarControl.nsh
; Author: Miguel Herrera

; UI support for the Win32 toolbar
; https://learn.microsoft.com/en-us/windows/win32/controls/toolbar-control-reference

; Styles
!define TBR_TOOLTIPS     0x0100
!define TBR_WRAPABLE     0x0200
!define TBR_ALTDRAG      0x0400
!define TBR_FLAT         0x0800
!define TBR_LIST         0x1000
!define TBR_CUSTOMERASE  0x2000
!define TBR_REGISTERDROP 0x4000
!define TBR_TRANSPARENT  0x8000

; Extended styles
!define TBR_EX_DRAWDDARROWS       0x0001
!define TBR_EX_MIXEDBUTTONS       0x0008
!define TBR_EX_HIDECLIPPEDBUTTONS 0x0010

; Common control styles for the toolbar
!define CCS_NORESIZE      0x0004
!define CCS_NOPARENTALIGN 0x0008
!define CCS_VERT          0x0080

; Messages
!define TBRM_ENABLEBUTTON         0x0401
!define TBRM_SETSTATE             0x0411
!define TBRM_BUTTONCOUNT          0x0418
!define TBRM_GETITEMRECT          0x041D
!define TBRM_BUTTONSTRUCTSIZE     0x041E
!define TBRM_SETBUTTONSIZE        0x041F
!define TBRM_AUTOSIZE             0x0421
!define TBRM_SETIMAGELIST         0x0430
!define TBRM_GETIMAGELIST         0x0431
!define TBRM_SETHOTIMAGELIST      0x0434
!define TBRM_SETDISABLEDIMAGELIST 0x0436
!define TBRM_GETBUTTONSIZE        0x043A
!define TBRM_SETMAXTEXTROWS       0x043C
!define TBRM_INSERTBUTTON         0x0443  ; 0x0415 for ASCII
!define TBRM_GETMAXSIZE           0x0453
!define TBRM_SETEXTENDEDSTYLE     0x0454
!define TBRM_GETPADDING           0x0456
!define TBRM_SETPADDING           0x0457

; Notifications
!define NM_CLICK -2

; Button styles
!define TBB_BUTTON   0x0000
!define TBB_SEP      0x0001
!define TBB_CHECK    0x0002
!define TBB_AUTOSIZE 0x0010
!define TBB_NOPREFIX 0x0020
!define TBB_SHOWTEXT 0x0040

; Button states
!define TBBS_CHECKED       0x0001
!define TBBS_PRESSED       0x0002
!define TBBS_ENABLED       0x0004
!define TBBS_HIDDEN        0x0008
!define TBBS_INDETERMINATE 0x0010
!define TBBS_WRAP          0x0020
!define TBBS_ELLIPSES      0x0040
!define TBBS_MARKED        0x0080

;--------------------------------
; Interface

  !define __TBR_CLASS ToolbarWindow32
  !define __TBR_DEF_STYLES ${WS_CHILD}|${WS_VISIBLE}|${WS_CLIPSIBLINGS}|\
    ${CCS_NORESIZE}|${TBR_TRANSPARENT}|${TBR_FLAT}|${TBR_LIST}|${TBR_TOOLTIPS}

  !define __TBR_ORIEN_HORZ 0
  !define __TBR_ORIEN_VERT 1

  ; The divider is a two-pixel highlight at the top of the toolbar
  !define __TBR_STYLE_DIV 0
  !define __TBR_STYLE_NO_DIV "${CCS_NODIVIDER}"

  !define __TBR_EXTRA_HT_DIV 2
  !define __TBR_EXTRA_HT_NO_DIV 0

  !define TBR_DIVIDER "DIV"
  !define TBR_NO_DIVIDER "NO_DIV"

  ;--------------------------------
  ; TBR_CREATE
  ; Create a horizontal or vertical toolbar control with some default styles.

    !macro __TBR_CREATE orien styles w h x y div

      nsDialogs::CreateControl ${__TBR_CLASS} "${__TBR_DEF_STYLES}|${styles}|${__TBR_STYLE_${div}}" 0 "${x}" "${y}" "${w}" "${h}" ""

      Push "${orien}"
      Push "${__TBR_EXTRA_HT_${div}}"
      ${CallArtificialFunction} __TBR_SET_PROP

    !macroend

    !macro __TBR_SET_PROP

      ; extraHtDiv ($2), orien ($1) and hwndTBR ($0)
      System::Store Sr2r1r0

      ; As the documentation states, the TB_SETEXTENDEDSTYLE message
      ; must be sent to set extended styles
      SendMessage $0 ${TBRM_SETEXTENDEDSTYLE} 0 ${TBR_EX_MIXEDBUTTONS}

      ; To get/set the size of the structure allocated (sizeof), the
      ; &l parameter must be used as follows:
      ; - Get: *(&l .r0, i, i) --> &l. is not part of the structure
      ;   and $0 = 8 bytes (4 + 4)
      ; - Set: *(&l4, i, i) --> The first parameter, which occupies
      ;   4 bytes, sets the size of the structure; 12 bytes (4 + 4 + 4)
      ; - Get & Set: *(&l4 .r0, i, i)
      System::Call "*(&l .r3, i, i, b, b, &v2, i, t) i .R0"

      ; Specify the size of the TBBUTTON structure. NSIS builds a 32-bit
      ; installer, so 2 bytes must be allocated in the bReserved parameter.
      SendMessage $0 ${TBRM_BUTTONSTRUCTSIZE} $3 0
      System::Free $R0

      ; Set the info required for resizing the toolbar
      System::Call "*(i r1, i r2) i .R0"
      nsDialogs::SetUserData $0 "$R0"

      Push $0
      System::Store L

    !macroend

    !define TBR_H_CREATE "!insertmacro __TBR_CREATE ${__TBR_ORIEN_HORZ} ${CCS_NOPARENTALIGN} 0% 0%"
    !define TBR_H_CREATE_FIXED "!insertmacro __TBR_CREATE ${__TBR_ORIEN_HORZ} 0 100% 0% 0 0"

    !define TBR_V_CREATE "!insertmacro __TBR_CREATE ${__TBR_ORIEN_VERT} ${CCS_VERT}|${CCS_NOPARENTALIGN} 0% 0%"
    !define TBR_V_CREATE_FIXED "!insertmacro __TBR_CREATE ${__TBR_ORIEN_VERT} ${CCS_VERT} 0% 100% 0 0"

  ;--------------------------------
  ; TBR_SET_BTN_PADDING

    !macro __TBR_PADDING_TO_HEX pad hex

      ; Max and min padding
      ${If} ${pad} > 0x7FFF
        StrCpy ${hex} "7FFF"
      ${ElseIf} ${pad} < 0
        StrCpy ${hex} "0000"

      ; Format to an hexadecimal value of 4 digits
      ${Else}
        IntFmt ${hex} "%04X" ${pad}
      ${EndIf}

    !macroend

    !macro __CALL_TBR_SET_BTN_PADDING hwndTBR horzPx vertPx

      Push "${hwndTBR}"
      Push "${horzPx}"
      Push "${vertPx}"

      ${CallArtificialFunction} __TBR_SET_BTN_PADDING

    !macroend

    !macro __TBR_SET_BTN_PADDING

      ; vertPx ($2), horzPx ($1) and hwndTBR ($0)
      System::Store Sr2r1r0

      !insertmacro __TBR_PADDING_TO_HEX $1 $3
      !insertmacro __TBR_PADDING_TO_HEX $2 $4

      ; Set the padding between the button edge and its contents
      SendMessage $0 ${TBRM_SETPADDING} 0 "0x$4$3"

      System::Store L

    !macroend

    !define TBR_SET_BTN_PADDING "!insertmacro __CALL_TBR_SET_BTN_PADDING"

  ;--------------------------------
  ; TBR_SET_IMAGE_LIST

    !macro __CALL_TBR_SET_IMAGE_LIST stateMsg hwndTBR imgList

      Push "${stateMsg}"
      Push "${hwndTBR}"
      Push "${imgList}"

      ${CallArtificialFunction} __TBR_SET_IMAGE_LIST

    !macroend

    !macro __TBR_SET_IMAGE_LIST

      ; imgList ($2), hwndTBR ($1) and stateMsg ($0)
      System::Store Sr2r1r0

      ; Set the list with the button images of the toolbar
      SendMessage $1 $0 0 $2

      System::Store L

    !macroend

    !define TBR_SET_DEF_ILIST "!insertmacro __CALL_TBR_SET_IMAGE_LIST ${TBRM_SETIMAGELIST}"
    !define TBR_SET_HOT_ILIST "!insertmacro __CALL_TBR_SET_IMAGE_LIST ${TBRM_SETHOTIMAGELIST}"
    !define TBR_SET_DISABLED_ILIST "!insertmacro __CALL_TBR_SET_IMAGE_LIST ${TBRM_SETDISABLEDIMAGELIST}"

  ;--------------------------------
  ; TBR_INSERT_BUTTON

    ; With the TBR_EX_MIXEDBUTTONS style, the text will be used as
    ; the button's tooltip unless TBB_SHOWTEXT is specified
    !define __TBRI_STYLE_TTIP 0
    !define __TBRI_STYLE_LBL "${TBB_SHOWTEXT}"

    !define TBRI_SHOW_TOOLTIP "TTIP"
    !define TBRI_SHOW_LABEL "LBL"

    ; A button is grayed when it does not accept user input
    !define __TBRI_STATE_DSBL 0
    !define __TBRI_STATE_ENBL "${TBBS_ENABLED}"

    !define TBRI_DISABLED "DSBL"
    !define TBRI_ENABLED "ENBL"

    !macro __CALL_TBR_INSERT_BUTTON hwndTBR id imgIndex userInput textDisplay text

      Push "${hwndTBR}"
      Push "${__TBRI_STATE_${userInput}}"
      Push "${TBB_BUTTON}|${TBB_AUTOSIZE}|${__TBRI_STYLE_${textDisplay}}"
      Push "${id}"
      Push "${imgIndex}"
      Push "${text}"

      ${CallArtificialFunction} __TBR_INSERT_BUTTON

    !macroend

    !macro __CALL_TBR_INSERT_SEP_BUTTON hwndTBR

      Push "${hwndTBR}"
      Push "0"
      Push "${TBB_SEP}"
      Push "-1"
      Push "0"
      Push ""

      ${CallArtificialFunction} __TBR_INSERT_BUTTON

    !macroend

    !macro __TBR_INSERT_BUTTON

      ; text ($5), imgIndex ($4), id ($3), bStyle ($2), bState ($1), hwndTBR ($0)
      System::Store Sr5r4r3r2r1r0

      ; Get the toolbar info
      nsDialogs::GetUserData $0
      Pop $R0

      ${If} $R0 != 0

        System::Call "*$R0(i .R1, i)"

        StrCpy $6 "0"
        ${If} $R1 == "${__TBR_ORIEN_VERT}"
          StrCpy $6 "${TBBS_WRAP}"
        ${EndIf}

        ; Set the button structure to insert
        System::Call "*(i r4, i r3, b $1|$6, b $2, &v2, i, t r5) i .R1"

        ; Insert the button at the beginning
        SendMessage $0 ${TBRM_INSERTBUTTON} 0 $R1
        System::Free $R1

      ${EndIf}

      System::Store L

    !macroend

    !define TBR_INSERT_BUTTON "!insertmacro __CALL_TBR_INSERT_BUTTON"
    !define TBR_INSERT_SEP "!insertmacro __CALL_TBR_INSERT_SEP_BUTTON"

  ;--------------------------------
  ; TBR_END_RESIZE

    !macro __TBR_ADJUST_SIZE maxDim btnMD incrDim btnID

      ; Set the maximum width/height of all the buttons in the toolbar
      ${If} ${maxDim} < ${btnMD}
        StrCpy ${maxDim} "${btnMD}"
      ${EndIf}

      ; Increment the width/height of the toolbar to fit the buttons
      IntOp ${incrDim} ${incrDim} + ${btnID}

    !macroend

    !macro __TBR_LIMIT_SIZE tbrSize maxSize

      ${If} ${tbrSize} > ${maxSize}
        StrCpy ${tbrSize} "${maxSize}"
      ${EndIf}

    !macroend

    !macro __CALL_TBR_END_RESIZE hwndTBR

      Push "${hwndTBR}"

      ${CallArtificialFunction} __TBR_END_RESIZE

    !macroend

    !macro __TBR_END_RESIZE

      ; hwndTBR ($0)
      System::Store Sr0

      ; Get the toolbar info
      nsDialogs::GetUserData $0
      Pop $R0

      ${If} $R0 != 0

        System::Call "*$R0(i .R1, i .R2)"

        ; Get the size of the toolbar
        System::Call "user32::GetClientRect(i r0, @ R3)"
        System::Call "*$R3(i, i, i .R4, i .R5)"
        IntOp $R5 $R5 + $R2

        ; Get the number of buttons
        SendMessage $0 ${TBRM_BUTTONCOUNT} 0 0 $R6
        IntOp $R6 $R6 - 1

        ${ForEach} $R7 0 $R6 + 1

          System::Call "*(i, i, i, i) i .r1"
          SendMessage $0 ${TBRM_GETITEMRECT} $R7 $1
          System::Call "*$1(i .r2, i .r3, i .r4, i .r5)"
          System::Free $1

          ; Calculate the size of the button inserted
          IntOp $4 $4 - $2  ; right - left = width
          IntOp $5 $5 - $3  ; bottom - top = height

          ${If} $R1 == "${__TBR_ORIEN_VERT}"
            !insertmacro __TBR_ADJUST_SIZE $R4 $4 $R5 $5
          ${Else}
            !insertmacro __TBR_ADJUST_SIZE $R5 $5 $R4 $4
          ${EndIf}

        ${Next}

        ; Get the size of the inner dialog where the toolbar is placed
        FindWindow $1 "#32770" "" $HWNDPARENT

        ; Client coordinates are relative, so the upper-left corner is always (0, 0)
        System::Call "user32::GetClientRect(i r1, @ R3)"
        System::Call "*$R3(i, i, i .R6, i .R7)"

        ; The toolbar cannot be bigger than the inner dialog
        !insertmacro __TBR_LIMIT_SIZE $R4 $R6
        !insertmacro __TBR_LIMIT_SIZE $R5 $R7

        ; Take into account the divider
        IntOp $R5 $R5 + $R2

        ; SWP_NOMOVE = 0x0002, SWP_NOZORDER = 0x0004, SWP_SHOWWINDOW = 0x0040
        System::Call "user32::SetWindowPos(i r0, i, i, i, i R4, i R5, i 0x0002|0x0004|0x0040)"

        ; Free the data associated to the toolbar
        System::Free $R0
        nsDialogs::SetUserData $0 "0"

      ${EndIf}

      System::Store L

    !macroend

    !define TBR_END_RESIZE "!insertmacro __CALL_TBR_END_RESIZE"

  ;--------------------------------
  ; TBR_TOGGLE_BUTTON

    !macro __CALL_TBR_TOGGLE_BUTTON hwndTBR id actvState

      Push "${hwndTBR}"
      Push "${id}"
      Push "${actvState}"

      ${CallArtificialFunction} __TBR_TOGGLE_BUTTON

    !macroend

    !macro __TBR_TOGGLE_BUTTON

      ; actvState ($2), id ($1) and hwndTBR ($0)
      System::Store Sr2r1r0

      ; Enable (1) or disable (0) the button
      SendMessage $0 ${TBRM_ENABLEBUTTON} $1 $2

      System::Store L

    !macroend

    !define TBR_TOGGLE_BUTTON "!insertmacro __CALL_TBR_TOGGLE_BUTTON"
