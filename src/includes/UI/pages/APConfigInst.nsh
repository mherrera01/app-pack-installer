; File: APConfigInst.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_CONFIG_INST_PAGE

  ;--------------------------------
  ; CFIP (ConFig Installation Page) variables

    Var dialogCFIP

  ;--------------------------------
  ; Main functions triggered on custom page creation and disposal

    Function configInstPage

      !insertmacro MUI_HEADER_TEXT "Configure Installation" ""

      nsDialogs::Create 1018
      Pop $dialogCFIP

      ${If} $dialogCFIP == "error"
        Call .onGuIEnd
        Quit
      ${EndIf}

      ${NSD_CreateComboBox} 0% 0% 30% 50% ""
      Pop $0
      
      nsDialogs::Show

    FunctionEnd

    Function configInstPageLeave
    FunctionEnd

!macroend
