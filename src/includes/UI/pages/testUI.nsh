!macro TEST_PAGE

  Var dialogTest
  Var iListTest

  Var icon1Test
  Var iIcon1Test
  Var icon2Test
  Var iIcon2Test

  Function testPage

    !insertmacro MUI_HEADER_TEXT "Test" "Testing the UI."

    nsDialogs::Create 1018
    Pop $dialogTest

    ${If} $dialogTest == "error"
      Call .onGuIEnd
      Quit
    ${EndIf}

    ; Create an image list of 24x24 pixels
    ; ILC_MASK = 0x0001, ILC_COLOR32 = 0x0020
    System::Call "comctl32::ImageList_Create(i 24, i 24, i 0x0001|0x0020, i 2, i 0) i .s"
    Pop $iListTest

    ${AP_LOAD_ICON} "bundle-export.ico" 24
    Pop $icon1Test

    ${AP_LOAD_ICON} "bundle-details.ico" 24
    Pop $icon2Test

    ; Add the icon handle, returned by AP_LOAD_ICON, to the image list
    System::Call "comctl32::ImageList_AddIcon(i $iListTest, i $icon1Test) i .s"
    Pop $iIcon1Test

    System::Call "comctl32::ImageList_AddIcon(i $iListTest, i $icon2Test) i .s"
    Pop $iIcon2Test

    /* ${TBR_V_CREATE} 60% 20% ${TBR_DIVIDER}
    Pop $0
    ${TBR_SET_BTN_PADDING} $0 8 12
    ; ${TBR_SET_DEF_ILIST} $0 ""

    ; Use I_IMAGENONE to indicate that the button does not have an image
    ${TBR_INSERT_BUTTON} $0 0 $iIcon1Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Export logfile"
    ${TBR_INSERT_BUTTON} $0 1 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Show bundle details"
    ${TBR_INSERT_BUTTON} $0 2 ${I_IMAGENONE} ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} ""
    ${TBR_INSERT_BUTTON} $0 3 ${I_IMAGENONE} ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} "Only this text"
    ${TBR_INSERT_BUTTON} $0 4 $iIcon2Test ${TBRI_DISABLED} ${TBRI_SHOW_TOOLTIP} "Show bundle details"
    ${TBR_INSERT_SEP} $0
    ${TBR_INSERT_BUTTON} $0 5 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} "Show bundle details"

    ; Free the internal data and resize the toolbar
    ${TBR_END_RESIZE} $0

    GetFunctionAddress $1 onToolbarNotifyTest
    nsDialogs::OnNotify $0 $1

    ${TBR_H_CREATE} 8% 30% ${TBR_NO_DIVIDER}
    Pop $0
    ${TBR_SET_DEF_ILIST} $0 $iListTest

    ${TBR_INSERT_BUTTON} $0 0 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Tooltip"
    ${TBR_INSERT_BUTTON} $0 1 $iIcon1Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Tooltip 2"
    ${TBR_INSERT_SEP} $0
    ${TBR_INSERT_BUTTON} $0 2 ${I_IMAGENONE} ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} "Just text"
    ${TBR_INSERT_SEP} $0
    ${TBR_INSERT_BUTTON} $0 3 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} "Click here"

    ${TBR_END_RESIZE} $0 */

    ; --- HORIZONTAL FIXED ---

    ${TBR_H_CREATE_FIXED} ${TBR_NO_DIVIDER}
    Pop $0
    ${TBR_SET_DEF_ILIST} $0 $iListTest

    ${TBR_INSERT_BUTTON} $0 0 $iIcon1Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Tooltip"
    ${TBR_INSERT_BUTTON} $0 1 $iIcon1Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Tooltip 2"
    ${TBR_INSERT_SEP} $0
    ${TBR_INSERT_BUTTON} $0 2 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} "Activate"
    ${TBR_INSERT_BUTTON} $0 3 ${I_IMAGENONE} ${TBRI_DISABLED} ${TBRI_SHOW_LABEL} "Disabled for now"

    ${TBR_END_RESIZE} $0

    GetFunctionAddress $1 onToolbarNotifyTest
    nsDialogs::OnNotify $0 $1

    ; --- VERTICAL FIXED ---

    /* ${TBR_V_CREATE_FIXED} ${TBR_DIVIDER}
    Pop $0
    ${TBR_SET_DEF_ILIST} $0 $iListTest
    ${TBR_SET_BTN_PADDING} $0 10 10

    ${TBR_INSERT_BUTTON} $0 0 $iIcon1Test ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} "Paint"
    ${TBR_INSERT_BUTTON} $0 1 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} "Add Text"
    ${TBR_INSERT_BUTTON} $0 2 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} "Highlight"
    ${TBR_INSERT_BUTTON} $0 3 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} "Remove"

    ${TBR_END_RESIZE} $0

    System::Call "user32::GetClientRect(i r0, @ r1)"
    System::Call "*$1(i, i, i .r2, i .r3)"
    MessageBox MB_OK "x = $2, y = $3" */

    nsDialogs::CreateControl "STATIC" ${DEFAULT_STYLES} 0 0% 0% 100% 100% ""
    Pop $0
    SetCtlColors $0 "" 0xE2E2E2

    nsDialogs::Show

  FunctionEnd

  Function testPageLeave

    System::Call "user32::DestroyIcon(i $icon1Test)"
    System::Call "user32::DestroyIcon(i $icon2Test)"
    System::Call "comctl32::ImageList_Destroy(i $iListTest)"

  FunctionEnd

  Function onToolbarNotifyTest

    Pop $0  ; UI handle
    Pop $1  ; Message code
    Pop $2  ; A pointer to the NMHDR stucture

    ; A toolbar button has been clicked
    ${If} $1 = ${NM_CLICK}

      ; Get the button identifier from the NMMOUSE structure
      System::Call "*$2(i, i, i, i .R0, i, i, i, i)"

      ${If} $R0 == 2
        ${TBR_TOGGLE_BUTTON} $0 3 1
      ${EndIf}

    ${EndIf}

  FunctionEnd

!macroend
