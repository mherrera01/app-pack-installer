; File: APChooseApps.nsh
; Author: Miguel Herrera

!include "TreeViewControl.nsh"

!macro AP_DEFINE_UI_CHOOSE_APPS_PAGE

  ;--------------------------------
  ; CAP (Choose Apps Page) variables

    Var dialogCAP
    Var appsTreeViewCAP

  ;--------------------------------
  ; Main functions triggered on custom page creation and disposal

    Function chooseAppsPage

      !insertmacro MUI_HEADER_TEXT "Choose Apps" "Choose the \
        applications to install from the bundle selected."

      nsDialogs::Create 1018
      Pop $dialogCAP

      ${If} $dialogCAP == "error"
        Call .onGuIEnd
        Quit
      ${EndIf}

      ${NSD_CreateLabel} 0% 0% 100% 20u "Check the applications you want \
        to install and unmark the ones not needed. Ensure that you are \
        properly connected to the internet and click Next to continue."
      Pop $0

      ${NSD_CreateCheckBox} 0% 17% 5% 6% ""
      Pop $0

      ${NSD_CreateLabel} 5% 17% 95% 12u "Manually manage each app setup \
        for a custom installation"
      Pop $0

      ; Create tree view for the apps
      ${TV_CREATE} 0% 30% 60% 65% ""
      Pop $appsTreeViewCAP

      ${TV_INSERT_ITEM} $appsTreeViewCAP "Aplicación 1"

      System::Call "*(&t128) i .R0"
      System::Call "*(i ${TVIF_TEXT}|${TVIF_HANDLE}, i r0, i, i, i R0, i 128, i, i, i, i, i, i, i, i, i) i .R1"
      SendMessage $appsTreeViewCAP ${TVM_GETITEM} 0 $R1
      System::Free $R1

      System::Call "kernel32::lstrcpy(t .s, i R0)"
      Pop $0
      MessageBox MB_OK $0
      System::Free $R0

      ${NSD_CreateGroupBox} 65% 30% 34% 55% "Description"
      Pop $0

        ${NSD_CreateLabel} 67% 40% 30% 40% "App info"
        Pop $0

      ${NSD_CreateLabel} 67% 88% 30% 12u "Apps selected: 0"
      Pop $0

      nsDialogs::Show

    FunctionEnd

    Function chooseAppsPageLeave
    FunctionEnd

!macroend
