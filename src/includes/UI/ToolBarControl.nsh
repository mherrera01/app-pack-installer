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
; 0x0400
!define TBRM_ENABLEBUTTON     0x0401
!define TBRM_SETSTATE         0x0411
!define TBRM_GETITEMRECT      0x041D
!define TBRM_BUTTONSTRUCTSIZE 0x041E
!define TBRM_SETBUTTONSIZE    0x041F
!define TBRM_AUTOSIZE         0x0421
!define TBRM_SETIMAGELIST     0x0430
!define TBRM_GETBUTTONSIZE    0x043A
!define TBRM_SETMAXTEXTROWS   0x043C
!define TBRM_INSERTBUTTON     0x0443  ; 0x0415 for ASCII
!define TBRM_GETMAXSIZE       0x0453
!define TBRM_SETEXTENDEDSTYLE 0x0454
!define TBRM_GETPADDING       0x0456
!define TBRM_SETPADDING       0x0457

; Notifications

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
  !define __TBR_DEF_STYLES ${WS_CHILD}|${WS_VISIBLE}|${WS_TABSTOP}|${WS_CLIPSIBLINGS}|\
    ${CCS_NORESIZE}|${TBR_TRANSPARENT}|${TBR_LIST}|${TBR_TOOLTIPS}

  ;--------------------------------
  ; TBR_CREATE
  ; Create a horizontal or vertical toolbar control with some default styles.

    !define __TBR_CLI_RECT_RT "RT"
    !define __TBR_GET_CLI_RECT_RT "(i, i, i .s, i)"
    !define __TBR_CLI_RECT_BTM "BTM"
    !define __TBR_GET_CLI_RECT_BTM "(i, i, i, i .s)"

    !macro __TBR_CREATE orien styles w h x y

      nsDialogs::CreateControl ${__TBR_CLASS} "${__TBR_DEF_STYLES}|${styles}" 0 "${x}" "${y}" "${w}" "${h}" ""

      Push "${__TBR_GET_CLI_RECT_${orien}}"
      ${CallArtificialFunction} __TBR_SET_PROP

    !macroend

    !macro __TBR_SET_PROP

      ; rectCoord ($1) and hwndTBR ($0)
      System::Store Sr1r0

      ; Set the padding between the button edge and its contents
      SendMessage $0 ${TBRM_SETPADDING} 0 0x00060008

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
      System::Call "*(&l .r2, i, i, b, b, &v2, i, t) i .R0"

      ; Specify the size of the TBBUTTON structure. NSIS builds a 32-bit
      ; installer, so 2 bytes must be allocated in the bReserved parameter.
      SendMessage $0 ${TBRM_BUTTONSTRUCTSIZE} $2 0
      System::Free $R0

      ; Get the size of the inner dialog where the toolbar is placed
      FindWindow $2 "#32770" "" $HWNDPARENT
      System::Call "user32::GetClientRect(i r2, @ r3)"

      ; Get the corresponding rect coordinate
      System::Call "*$3$1"
      Pop $4

      ; Set the maximum width/height of the toolbar
      nsDialogs::SetUserData $0 "$4"

      Push $0
      System::Store L

    !macroend

    !define TBR_H_CREATE "!insertmacro __TBR_CREATE ${__TBR_CLI_RECT_RT} ${CCS_NOPARENTALIGN} 0% 0%"
    !define TBR_H_CREATE_FIXED "!insertmacro __TBR_CREATE ${__TBR_CLI_RECT_RT} ${CCS_NODIVIDER} 100% 0% 0 0"

    !define TBR_V_CREATE "!insertmacro __TBR_CREATE ${__TBR_CLI_RECT_BTM} ${CCS_VERT}|${CCS_NOPARENTALIGN} 0% 2"
    !define TBR_V_CREATE_FIXED "!insertmacro __TBR_CREATE ${__TBR_CLI_RECT_BTM} ${CCS_VERT}|${CCS_NODIVIDER} 0% 100% 0 0"

  ;--------------------------------
  ; TBR_SET_IMAGE_LIST

    !macro __CALL_TBR_SET_IMAGE_LIST hwndTBR imgList

      Push "${hwndTBR}"
      Push "${imgList}"

      ${CallArtificialFunction} __TBR_SET_IMAGE_LIST

    !macroend

    !macro __TBR_SET_IMAGE_LIST

      ; imgList ($1) and hwndTBR ($0)
      System::Store Sr1r0

      ; Sets the list with the button images of the toolbar
      SendMessage $0 ${TBRM_SETIMAGELIST} 0 $1

      System::Store L

    !macroend

    !define TBR_SET_IMAGE_LIST "!insertmacro __CALL_TBR_SET_IMAGE_LIST"

  ;--------------------------------
  ; TBR_INSERT_BUTTON

    ; Style flags
    !define __TBRI_STYLE_NONE 0
    !define __TBRI_STYLE_LABEL "${TBB_SHOWTEXT}"

    !define TBRI_SHOW_TOOLTIP "NONE"
    !define TBRI_SHOW_LABEL "LABEL"

    ; State flags
    !define __TBRI_STATE_NONE 0
    !define __TBRI_STATE_VERT "${TBBS_WRAP}"
    !define __TBRI_STATE_ENABLED "${TBBS_ENABLED}"

    !define TBRI_DISABLED "NONE"
    !define TBRI_ENABLED "ENABLED"

    !macro __CALL_TBR_INSERT_BUTTON orienState hwndTBR id imgIndex userInput textDisplay text

      ${If} ${imgIndex} != ${I_IMAGENONE}
      ${OrIf} ${textDisplay} == ${TBRI_SHOW_LABEL}

        ; Set the button structure to insert
        System::Call "*(i ${imgIndex}, i ${id}, b ${orienState}|${__TBRI_STATE_${userInput}}, b ${TBB_BUTTON}|${__TBRI_STYLE_${textDisplay}}, &v2, i, t '${text}') i .s"

        Push "${hwndTBR}"
        ${CallArtificialFunction} __TBR_INSERT_BUTTON

      ${EndIf}

    !macroend

    !macro __TBR_INSERT_BUTTON

      ; hwndTBR ($0) and btnStruct ($R0)
      System::Store Sr0R0

      ; Insert the button at the beginning
      SendMessage $0 ${TBRM_INSERTBUTTON} 0 $R0

      System::Call "*(i, i, i, i) i .R1"
      SendMessage $0 ${TBRM_GETITEMRECT} 0 $R1
      System::Call "*$R1(i .r1, i .r2, i .r3, i .r4)"

      ; Calculate the size of the button inserted
      IntOp $R2 $3 - $1  ; right - left = width
      IntOp $R3 $4 - $2  ; bottom - top = height

      ; 2 extra pixel high due to the CCS_NODIVIDER style
      IntOp $R3 $R3 + 2

      ; Get the size of the toolbar
      System::Call "user32::GetClientRect(i r0, @ r1)"

      ; Client coordinates are relative, so the upper-left corner is always (0, 0)
      System::Call "*$1(i, i, i .r2, i .r3)"

      nsDialogs::GetUserData $0
      Pop $4

      ${If} $2 < $R2
        StrCpy $2 "$R2"
      ${EndIf}

      ; Increase the height
      IntOp $3 $3 + $R3

      ; Keep the max height
      ${If} $3 >= $4
        StrCpy $3 "$4"
      ${EndIf}

      ; Increase the width in a horizontal toolbar
      /* ${If} $3 < $R3
        StrCpy $3 "$R3"
      ${EndIf}

      ; Increase the width
      IntOp $2 $2 + $R2

      ; Keep the max width
      ${If} $2 >= $4
        StrCpy $2 "$4"
      ${EndIf} */

      ; SWP_NOMOVE = 0x0002, SWP_NOZORDER = 0x0004, SWP_SHOWWINDOW = 0x0040
      System::Call "user32::SetWindowPos(i r0, i, i, i, i r2, i r3, i 0x0002|0x0004|0x0040)"

      System::Free $R0
      System::Free $R1

      System::Store L

    !macroend

    !define TBR_H_INSERT_BUTTON "!insertmacro __CALL_TBR_INSERT_BUTTON ${__TBRI_STATE_NONE}"
    !define TBR_V_INSERT_BUTTON "!insertmacro __CALL_TBR_INSERT_BUTTON ${__TBRI_STATE_VERT}"

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
