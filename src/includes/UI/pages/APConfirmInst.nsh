; File: APConfirmInst.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_CONFIRM_INST_PAGE

  ;--------------------------------
  ; CIP (Confirm Installation Page) variables

    Var dialogCIP

    Var drivesDropListCIP

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

      ${NSD_CreateDropList} 0% 0% 30% 50% ""
      Pop $drivesDropListCIP

      ${GetDrives} "ALL" getDrivesInfo

      nsDialogs::Show

    FunctionEnd

    Function confirmInstPageLeave
    FunctionEnd

  ;--------------------------------
  ; Helper functions

    Function getDrivesInfo

      ${NSD_CB_AddString} $drivesDropListCIP "$9"
	    Push $0

    FunctionEnd

!macroend
