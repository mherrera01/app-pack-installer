; File: APChooseApps.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_CHOOSE_APPS_PAGE

  ;--------------------------------
  ; CAP (Choose Apps Page) variables

    Var dialogCAP
    Var appsTreeViewCAP
    Var appDescInfoCAP

    Var currentAppsSelectedCAP
    Var appsSelectedInfoCAP

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

      ${NSD_CreateCheckBox} 0% 17% 4% 6% ""
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

      ${TV_INSERT_ITEM} $appsTreeViewCAP ${TVI_ROOT} "Browsers" "Access to websites."
      Pop $0
      ${TV_SET_ITEM_CHECK} $appsTreeViewCAP $0 0

      ${TV_INSERT_ITEM} $appsTreeViewCAP $0 "Firefox" "Firefox is a free open-source \
        browser whose development is overseen by the Mozilla Corporation."
      Pop $0
      ${TV_SET_ITEM_CHECK} $appsTreeViewCAP $0 ${TVIS_CHECKED}

      ${NSD_CreateGroupBox} 65% 30% 34% 55% "Description"
      Pop $0

        ${NSD_CreateLabel} 67% 40% 30% 40% "Position your mouse over \
          a component to see its description."
        Pop $appDescInfoCAP

        ; Grey out the description until the mouse is over an app
        EnableWindow $appDescInfoCAP 0

      ${NSD_CreateLabel} 67% 88% 20% 12u "Apps selected:"
      Pop $0

      StrCpy $currentAppsSelectedCAP "1"
      ${NSD_CreateLabel} 90% 88% 7% 12u "$currentAppsSelectedCAP"
      Pop $appsSelectedInfoCAP

      nsDialogs::Show

    FunctionEnd

    Function chooseAppsPageLeave
    FunctionEnd

  ;--------------------------------
  ; Event functions

    Function onTreeViewNotifyCAP

      Pop $0 ; UI handle
      Pop $1 ; Message code

      ; A pointer to the NMHDR stucture. For some notification
      ; messages, this parameter points to a larger structure
      ; that has the NMHDR structure as its first member.
      Pop $2

      ; The item checkbox state has changed
      ${If} $1 = ${NM_TVSTATEIMAGECHANGING}

        ; Read the new item state from the NMTVSTATEIMAGECHANGING structure
        System::Call "*$2(i, i, i, i, i .R0, i .R1)"

        ; When selecting the tree view elements with the keyboard,
        ; their image states can change with the space key. Even if
        ; an item does not have a checkbox (state = 0), one appears,
        ; leading to undesired behaviour.
        ${If} $R0 == 0
          ; Prevent the item state change
          ${NSD_Return} 1
        ${EndIf}

        ${If} $R1 = 2 ; Checked
          IntOp $currentAppsSelectedCAP $currentAppsSelectedCAP + 1
        ${ElseIf} $R1 = 1 ; Unchecked
          IntOp $currentAppsSelectedCAP $currentAppsSelectedCAP - 1
        ${EndIf}

        ; Update the apps selected UI
        ${NSD_SetText} $appsSelectedInfoCAP "$currentAppsSelectedCAP"

      ; With the TVS_INFOTIP applied, the cursor is over an item
      ${ElseIf} $1 = ${TVN_GETINFOTIP}

        ; Read the item and its description (in lParam) from the
        ; NMTVGETINFOTIP structure
        System::Call "*$2(i, i, i, i, i, i .R0, i .R1)"

        ; Get the description string by using the lparam buffer
        System::Call "kernel32::lstrcpy(t .r3, i R1)"

        ; Check if the item has a description, as it is optional
        ${If} $3 == ""

          ; Show the item name if there is no description
          ${TV_GET_ITEM_TEXT} $appsTreeViewCAP $R0
          Pop $3

        ${EndIf}

        ${NSD_SetText} $appDescInfoCAP "$3"
        EnableWindow $appDescInfoCAP 1

      ${EndIf}

    FunctionEnd

!macroend
