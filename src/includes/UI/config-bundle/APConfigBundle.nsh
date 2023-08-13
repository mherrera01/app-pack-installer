; File: APConfigBundle.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_CONFIG_BUNDLE_PAGE

  ;--------------------------------
  ; CFBP (ConFig Bundle Page) variables

    Var dialogCFBP
    Var boldFontCFBP

  ;--------------------------------
  ; Main functions triggered on custom page creation and disposal

    Function configBundlePage

      !insertmacro MUI_HEADER_TEXT "Configure Bundle" "TODO"

      nsDialogs::Create 1018
      Pop $dialogCFBP

      ${If} $dialogCFBP == "error"
        Call .onGuIEnd
        Quit
      ${EndIf}

      ; Create a bold font for important notes
      CreateFont $boldFontCFBP "Microsoft Sans Serif" "8.25" "700"

      ${NSD_CreateLabel} 0% 1% 3% 12u "1."
      Pop $0
      SendMessage $0 ${WM_SETFONT} $boldFontCFBP 0

      ${NSD_CreateLabel} 4% 1% 23% 20u "Verify the properties \
        of the app bundle"
      Pop $0

      ; magick convert test.png -define icon:auto-resize="64,32,24,16" test.ico
      File "/oname=$PLUGINSDIR\bundle.ico" ".\icons\bundle.ico"
      System::Call "user32::LoadImage(i, t '$PLUGINSDIR\bundle.ico', i ${IMAGE_ICON}, i 24, i 24, i ${LR_LOADFROMFILE}) i .R0"

      ${NSD_CreateButton} 30% 0% 32 32 ""
      Pop $0
      ${NSD_AddStyle} $0 ${BS_ICON}

      SendMessage $0 ${BM_SETIMAGE} ${IMAGE_ICON} $R0

      ${NSD_CreateHLine} 38% 16 25% 0u ""
      Pop $0

      File "/oname=$PLUGINSDIR\choose-apps.ico" ".\icons\choose-apps.ico"
      System::Call "user32::LoadImage(i, t '$PLUGINSDIR\choose-apps.ico', i ${IMAGE_ICON}, i 22, i 22, i ${LR_LOADFROMFILE}) i .R0"

      ${NSD_CreateButton} 63% 0% 32 32 ""
      Pop $0
      ${NSD_AddStyle} $0 ${BS_ICON}

      SendMessage $0 ${BM_SETIMAGE} ${IMAGE_ICON} $R0

      ${NSD_CreateLabel} 73% 1% 3% 12u "2."
      Pop $0
      SendMessage $0 ${WM_SETFONT} $boldFontCFBP 0

      ${NSD_CreateLabel} 77% 1% 23% 20u "Choose the apps \
        you want to install"
      Pop $0

      ; TODO. Free the icon loaded
      ; System::Call "user32::DestroyIcon(i handle returned by LoadImage)"

      File "/oname=$PLUGINSDIR\select-step.ico" ".\icons\select-step.ico"
      System::Call "user32::LoadImage(i, t '$PLUGINSDIR\select-step.ico', i ${IMAGE_ICON}, i 32, i 32, i ${LR_LOADFROMFILE}) i .R0"

      ${NSD_CreateIcon} 30% 13% 32 32 ""
      Pop $0
      SendMessage $0 ${STM_SETICON} $R0 0

      ${NSD_CreateIcon} 63% 13% 32 32 ""
      Pop $0
      SendMessage $0 ${STM_SETICON} $R0 0
      ShowWindow $0 ${SW_HIDE}

      nsDialogs::CreateControl "STATIC" ${DEFAULT_STYLES}|${SS_BLACKFRAME} 0 0% 21% 100% 1% ""
      Pop $0

      nsDialogs::Show

    FunctionEnd

    Function configBundlePageLeave
    FunctionEnd

!macroend
