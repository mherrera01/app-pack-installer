; File: APConfigBundle.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_CONFIG_BUNDLE_PAGE

  ;--------------------------------
  ; CFBP (ConFig Bundle Page) variables

    Var dialogCFBP
    Var boldFontCFBP

    ; Validate bundle step
    Var vbStepIconCFBP
    Var vbStepButtonCFBP
    Var vbFirstStepInfoCFBP
    Var vbStepInfoCFBP

    ; Choose apps step
    Var caStepIconCFBP
    Var caStepButtonCFBP
    Var caSecondStepInfoCFBP
    Var caStepInfoCFBP

    ; Step selector
    Var selectStepIconCFBP
    Var vbStepSelectorCFBP
    Var caStepSelectorCFBP

  ;--------------------------------
  ; Variables for the steps UI

    !insertmacro AP_DEFINE_UI_CHOOSE_APPS_VARS

  ;--------------------------------
  ; Main functions triggered on custom page creation and disposal

    Function configBundlePage

      !insertmacro MUI_HEADER_TEXT "Configure Bundle" "Set up the \
        bundle selected."

      nsDialogs::Create 1018
      Pop $dialogCFBP

      ${If} $dialogCFBP == "error"
        Call .onGuIEnd
        Quit
      ${EndIf}

      ; Create a bold font to highlight a text
      CreateFont $boldFontCFBP "Microsoft Sans Serif" "8.25" "700"

      ;--------------------------------
      ; Validate bundle step UI

        ${NSD_CreateLabel} 0% 1% 3% 12u "1."
        Pop $vbFirstStepInfoCFBP
        SendMessage $vbFirstStepInfoCFBP ${WM_SETFONT} $boldFontCFBP 0

        ${NSD_CreateLabel} 4% 1% 23% 20u "Verify the properties \
          of the app bundle"
        Pop $vbStepInfoCFBP

        System::Call "user32::LoadImage(i, t '$PLUGINSDIR\bundle.ico', i ${IMAGE_ICON}, i 24, i 24, i ${LR_LOADFROMFILE}) i .s"
        Pop $vbStepIconCFBP

        ${NSD_CreateButton} 30% 0% 32 32 ""
        Pop $vbStepButtonCFBP
        ${NSD_AddStyle} $vbStepButtonCFBP ${BS_ICON}

        SendMessage $vbStepButtonCFBP ${BM_SETIMAGE} ${IMAGE_ICON} $vbStepIconCFBP
        ${NSD_OnClick} $vbStepButtonCFBP onChangeStepClickCFBP

      ${NSD_CreateHLine} 38% 16 25% 0u ""
      Pop $0

      ;--------------------------------
      ; Choose apps step UI

        System::Call "user32::LoadImage(i, t '$PLUGINSDIR\choose-apps.ico', i ${IMAGE_ICON}, i 22, i 22, i ${LR_LOADFROMFILE}) i .s"
        Pop $caStepIconCFBP

        ${NSD_CreateButton} 63% 0% 32 32 ""
        Pop $caStepButtonCFBP
        ${NSD_AddStyle} $caStepButtonCFBP ${BS_ICON}

        SendMessage $caStepButtonCFBP ${BM_SETIMAGE} ${IMAGE_ICON} $caStepIconCFBP
        ${NSD_OnClick} $caStepButtonCFBP onChangeStepClickCFBP

        ${NSD_CreateLabel} 73% 1% 3% 12u "2."
        Pop $caSecondStepInfoCFBP
        SendMessage $caSecondStepInfoCFBP ${WM_SETFONT} $boldFontCFBP 0

        ${NSD_CreateLabel} 77% 1% 23% 20u "Choose the apps \
          you want to install"
        Pop $caStepInfoCFBP

      ;--------------------------------
      ; Step selector UI

        System::Call "user32::LoadImage(i, t '$PLUGINSDIR\select-step.ico', i ${IMAGE_ICON}, i 32, i 32, i ${LR_LOADFROMFILE}) i .s"
        Pop $selectStepIconCFBP

        ${NSD_CreateIcon} 30% 13% 32 32 ""
        Pop $vbStepSelectorCFBP
        SendMessage $vbStepSelectorCFBP ${STM_SETICON} $selectStepIconCFBP 0

        ${NSD_CreateIcon} 63% 13% 32 32 ""
        Pop $caStepSelectorCFBP
        SendMessage $caStepSelectorCFBP ${STM_SETICON} $selectStepIconCFBP 0

        nsDialogs::CreateControl "STATIC" ${DEFAULT_STYLES}|${SS_BLACKFRAME} 0 0% 21% 100% 1% ""
        Pop $0

      ; The steps UI content
      !insertmacro AP_DEFINE_UI_CHOOSE_APPS_CREATION

      ; The validate bundle step is first displayed
      Push 1
      Call changeStepUICFBP

      nsDialogs::Show

    FunctionEnd

    Function configBundlePageLeave

      ; Free the icons loaded
      System::Call "user32::DestroyIcon(i $vbStepIconCFBP)"
      System::Call "user32::DestroyIcon(i $caStepIconCFBP)"
      System::Call "user32::DestroyIcon(i $selectStepIconCFBP)"

    FunctionEnd

  ;--------------------------------
  ; Helper functions

    Function changeStepUICFBP

      ; Get if the first step must be enabled (1) or disabled (0)
      Pop $0

      EnableWindow $vbFirstStepInfoCFBP $0
      EnableWindow $vbStepInfoCFBP $0

      ; If the first step is enabled then the selector must be shown.
      ; 1 (enabled) * 5 = 5 = SW_SHOW | 0 (disabled) * 5 = 0 = SW_HIDE
      IntOp $1 $0 * ${SW_SHOW}
      ShowWindow $vbStepSelectorCFBP $1

      ; Show/hide the validate bundle UI

      ; Opposite value | 0 ^ 1 = 1, 1 ^ 1 = 0
      IntOp $0 $0 ^ 1
      EnableWindow $caSecondStepInfoCFBP $0
      EnableWindow $caStepInfoCFBP $0

      IntOp $1 $0 * ${SW_SHOW}
      ShowWindow $caStepSelectorCFBP $1

      ; Show/hide the choose apps UI
      Push $1
      Call toggleVisibilityUICAS

    FunctionEnd

  ;--------------------------------
  ; Event functions

    Function onChangeStepClickCFBP

      ; Get the step button that triggered the event
      Pop $0

      ; Push 1 to the stack if the first step is selected
      ; and 0 otherwise
      ${If} $0 == $vbStepButtonCFBP
        Push 1
      ${ElseIf} $0 == $caStepButtonCFBP
        Push 0
      ${EndIf}

      Call changeStepUICFBP

    FunctionEnd

  ;--------------------------------
  ; Functions for the steps UI

    !insertmacro AP_DEFINE_UI_CHOOSE_APPS_FUNC

!macroend
