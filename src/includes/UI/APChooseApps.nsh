; File: APChooseApps.nsh
; Author: Miguel Herrera

; Include the header file that allows to create and handle
; a ListView control
!include "CommCtrl.nsh"

; Fix a bug in the header file, so that there are not
; verbose compilation errors
!ifndef _COMMCTRL_NSH_VERBOSE
  !define _COMMCTRL_NSH_VERBOSE ${_COMMCTRL_VERBOSE} 
!endif

!macro AP_DEFINE_UI_CHOOSE_APPS_PAGE

  ;--------------------------------
  ; CAP (Choose Apps Page) variables

    Var dialogCAP
    Var appsListViewCAP

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

      ${NSD_CreateListView} 0% 30% 60% 65% ""
      Pop $appsListViewCAP

      ; Modify the style of the list view
      ; ListView styles: http://msdn.microsoft.com/library/bb774739.aspx
      ; Extended ListView styles: http://msdn.microsoft.com/library/bb774732.aspx
      SendMessage $appsListViewCAP ${LVM_SETEXTENDEDLISTVIEWSTYLE} 0 ${LVS_EX_CHECKBOXES}|${LVS_EX_FULLROWSELECT}

      ${NSD_LV_InsertColumn} $appsListViewCAP 0 100 "Apps"

      ${NSD_LV_InsertItem} $appsListViewCAP 0 "Elem1"
      ${NSD_LV_InsertItem} $appsListViewCAP 1 "Elem2"

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
