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

      ; The TVS_CHECKBOXES style must be set after the tree view creation
      ; with SetWindowLong. Otherwise, as the documentation states, the
      ; checkboxes might appear unchecked (even if they are explicitly
      ; checked with the TVM_SETITEM message) depending on timing issues.
      System::Call "user32::GetWindowLong(i $appsTreeViewCAP, i ${GWL_STYLE}) i .R0"
      IntOp $R0 ${TVS_CHECKBOXES} | $R0
      System::Call "user32::SetWindowLong(i $appsTreeViewCAP, i ${GWL_STYLE}, i R0)"

      GetFunctionAddress $0 onTreeViewNotifyCAP
      nsDialogs::OnNotify $appsTreeViewCAP $0

      ${TV_INSERT_ITEM} $appsTreeViewCAP ${TVI_ROOT} "Aplicación 1"
      Pop $0

      ${TV_INSERT_ITEM} $appsTreeViewCAP $0 "Sub Aplicación"
      Pop $0

      ${TV_SET_ITEM_CHECK} $appsTreeViewCAP $0 ${TVIS_CHECKED}

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

  ;--------------------------------
  ; Helper functions

    ; https://stackoverflow.com/questions/47814925/nsis-listview-is-possible-to-set-checkbox-as-disabled
    Function onTreeViewNotifyCAP

      Pop $0 ; UI handle
      Pop $1 ; Message code
      Pop $2 ; A pointer to the NMHDR stucture

      ; https://stackoverflow.com/questions/1774026/checking-a-win32-tree-view-item-automatically-checks-all-child-items
      ${If} $1 = ${NM_TVSTATEIMAGECHANGING}
        MessageBox MB_OK "Item unchecked/checked"
      ${EndIf}

    FunctionEnd

!macroend
