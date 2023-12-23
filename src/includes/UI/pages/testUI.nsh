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

    ${TBR_V_CREATE} 40% 10%
    Pop $0
    ${TBR_SET_IMAGE_LIST} $0 $iListTest

    ; Use I_IMAGENONE to indicate that the button does not have an image
    ${TBR_V_INSERT_BUTTON} $0 0 $iIcon1Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Export logfile"
    ${TBR_V_INSERT_BUTTON} $0 1 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Show bundle details"
    ${TBR_V_INSERT_BUTTON} $0 2 ${I_IMAGENONE} ${TBRI_ENABLED} ${TBRI_SHOW_LABEL} ""
    ${TBR_V_INSERT_BUTTON} $0 3 $iIcon2Test ${TBRI_DISABLED} ${TBRI_SHOW_TOOLTIP} "Show bundle details"
    ${TBR_V_INSERT_BUTTON} $0 4 $iIcon2Test ${TBRI_DISABLED} ${TBRI_SHOW_TOOLTIP} "Show bundle details"
    ${TBR_V_INSERT_BUTTON} $0 5 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Show bundle details"

    System::Call "user32::GetClientRect(i r0, @ r1)"
    System::Call "*$1(i, i, i .r2, i .r3)"
    MessageBox MB_OK "x = $2, y = $3"

    nsDialogs::CreateControl "STATIC" ${DEFAULT_STYLES} 0 39% 9% 30% 91% ""
    Pop $0
    SetCtlColors $0 "" 0xE2E2E2

    ; --- VERTICAL FIXED ---

    ${TBR_V_CREATE_FIXED}
    Pop $0
    ${TBR_SET_IMAGE_LIST} $0 $iListTest

    ${TBR_V_INSERT_BUTTON} $0 0 $iIcon1Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Export logfile"
    ${TBR_V_INSERT_BUTTON} $0 1 $iIcon2Test ${TBRI_ENABLED} ${TBRI_SHOW_TOOLTIP} "Show bundle details"

    nsDialogs::CreateControl "STATIC" ${DEFAULT_STYLES} 0 0% 0% 30% 100% ""
    Pop $0
    SetCtlColors $0 "" 0xE2E2E2

    /* System::Call "user32::GetClientRect(i r0, @ r1)"
    System::Call "*$1(i, i, i .r2, i .r3)"

    ; This should be called only once, in the core UI
    ${NSD_InitCommonControlsEx} ${ICC_COOL_CLASSES}

    ; Why padding is added at the begginning of the rebar. Without visual styles this does not happen
    IntOp $4 $3 + 4

    ; CCS_NORESIZE = 0x0004, CCS_NOPARENTALIGN = 0x0008, CCS_VERT = 0x0080
    nsDialogs::CreateControl "ReBarWindow32" ${WS_CHILD}|${WS_VISIBLE}|${WS_TABSTOP}|${WS_CLIPSIBLINGS}|\
      ${CCS_NODIVIDER}|0x0004|0x0008|0x0080 0 30% 40% "$2" "$4" ""
    Pop $1

    ; System::Call "uxtheme::SetWindowTheme(i r1, t '', t '')"

    ; RB_SETBKCOLOR = 0x0413
    ; SendMessage $1 0x0413 0 0x00DCDCDC

    ; RB_GETBKCOLOR = 0x0414
    ; SendMessage $1 0x0414 0 0 $4
    ; MessageBox MB_OK "$4"

    ; RBBIM_STYLE = 0x0001, RBBIM_COLORS = 0x0002, RBBIM_CHILD = 0x0010, RBBIM_CHILDSIZE = 0x0020, RBBIM_HEADERSIZE = 0x0800
    ; RBBS_FIXEDSIZE = 0x0002, RBBS_CHILDEDGE = 0x0004, RBBS_GRIPPERALWAYS = 0x0080, RBBS_NOGRIPPER = 0x0100
    ; Vertical: cxMinChild and cx are vertical and cyMinChild is horizontal
    System::Call "*(&l4, i 0x0001|0x0002|0x0010|0x0020|0x0800, i 0x0002|0x0100, i, i 0x00F8F8F8, t, i, i, i r0, i r3, i r2, i, i, i, i, i, i, i, i, i 0, i, i, i, i, i) i .R0"

    ; RB_INSERTBAND (unicode) = 0x040A
    SendMessage $1 0x040A 0 $R0 */

    nsDialogs::Show

  FunctionEnd

  Function testPageLeave

    System::Call "user32::DestroyIcon(i $icon1Test)"
    System::Call "user32::DestroyIcon(i $icon2Test)"
    System::Call "comctl32::ImageList_Destroy(i $iListTest)"

  FunctionEnd

!macroend
