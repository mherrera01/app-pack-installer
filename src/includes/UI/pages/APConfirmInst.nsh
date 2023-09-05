; File: APConfirmInst.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_CONFIRM_INST_PAGE

  ;--------------------------------
  ; CIP (Confirm Installation Page) variables

    Var dialogCIP

  ;--------------------------------
  ; Main functions triggered on custom page creation and disposal

    Function confirmInstPage

      !insertmacro MUI_HEADER_TEXT "Confirm Installation" ""

      nsDialogs::Create 1018
      Pop $dialogCIP

      ${If} $dialogCIP == "error"
        Call .onGuIEnd
        Quit
      ${EndIf}

      ; Clear the error flag as it is set by the nsArray functions
      ClearErrors

      ; Get the next button handler and change the text to 'Install'
      GetDlgItem $0 $HWNDPARENT 1
      ${NSD_SetText} $0 "Install"

      ${NSD_CreateComboBox} 0% 0% 30% 50% ""
      Pop $0
      
      nsDialogs::Show

    FunctionEnd

    Function confirmInstPageLeave
    FunctionEnd

!macroend
