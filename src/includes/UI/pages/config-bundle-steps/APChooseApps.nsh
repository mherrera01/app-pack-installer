; File: APChooseApps.nsh
; Author: Miguel Herrera

;--------------------------------
; CAS (Choose Apps Step) variables

  !macro AP_DEFINE_UI_CHOOSE_APPS_VARS

    Var appsTreeViewCAS
    Var appDescBoxCAS
    Var appDescInfoCAS

    Var appsSelectedInfoCAS
    Var appsSelectedDataCAS
    Var currentAppsSelectedCAS

  !macroend

;--------------------------------
; UI elements displayed on the page creation

  !macro AP_DEFINE_UI_CHOOSE_APPS_CREATION

    ; Create tree view for the apps
    ${TV_CREATE} 0% 30% 60% 65% ""
    Pop $appsTreeViewCAS

    ; The TVS_CHECKBOXES style must be set after the tree view creation
    ; with SetWindowLong. Otherwise, as the documentation states, the
    ; checkboxes might appear unchecked (even if they are explicitly
    ; checked with the TVM_SETITEM message) depending on timing issues.
    System::Call "user32::GetWindowLong(i $appsTreeViewCAS, i ${GWL_STYLE}) i .R0"
    IntOp $R0 ${TVS_CHECKBOXES} | $R0
    System::Call "user32::SetWindowLong(i $appsTreeViewCAS, i ${GWL_STYLE}, i R0)"

    GetFunctionAddress $0 onTreeViewNotifyCAS
    nsDialogs::OnNotify $appsTreeViewCAS $0

    ${TV_INSERT_ITEM} $appsTreeViewCAS ${TVI_ROOT} "Browsers" "Access to websites."
    Pop $0
    ${TV_SET_ITEM_CHECK} $appsTreeViewCAS $0 0

    ${TV_INSERT_ITEM} $appsTreeViewCAS $0 "Firefox" "Firefox is a free open-source \
      browser whose development is overseen by the Mozilla Corporation."
    Pop $0
    ${TV_SET_ITEM_CHECK} $appsTreeViewCAS $0 ${TVIS_CHECKED}

    ${NSD_CreateGroupBox} 65% 30% 34% 55% "Description"
    Pop $appDescBoxCAS

      ${NSD_CreateLabel} 67% 40% 30% 40% "Position your mouse over \
        a component to see its description."
      Pop $appDescInfoCAS

      ; Grey out the description until the mouse is over an app
      EnableWindow $appDescInfoCAS 0

    ${NSD_CreateLabel} 67% 88% 20% 12u "Apps selected:"
    Pop $appsSelectedInfoCAS

    StrCpy $currentAppsSelectedCAS "1"
    ${NSD_CreateLabel} 90% 88% 7% 12u "$currentAppsSelectedCAS"
    Pop $appsSelectedDataCAS

  !macroend

;--------------------------------
; Functions

  !macro AP_DEFINE_UI_CHOOSE_APPS_FUNC

  ;--------------------------------
  ; Helper functions

    Function toggleVisibilityUICAS

      ; Show (SW_SHOW) or hide (SW_HIDE) the UI components
      Pop $0
      ShowWindow $appsTreeViewCAS $0
      ShowWindow $appDescBoxCAS $0
      ShowWindow $appDescInfoCAS $0
      ShowWindow $appsSelectedInfoCAS $0
      ShowWindow $appsSelectedDataCAS $0

    FunctionEnd

  ;--------------------------------
  ; Event functions

    Function onTreeViewNotifyCAS

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
          IntOp $currentAppsSelectedCAS $currentAppsSelectedCAS + 1
        ${ElseIf} $R1 = 1 ; Unchecked
          IntOp $currentAppsSelectedCAS $currentAppsSelectedCAS - 1
        ${EndIf}

        ; Update the apps selected UI
        ${NSD_SetText} $appsSelectedDataCAS "$currentAppsSelectedCAS"

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
          ${TV_GET_ITEM_TEXT} $appsTreeViewCAS $R0
          Pop $3

        ${EndIf}

        ${NSD_SetText} $appDescInfoCAS "$3"
        EnableWindow $appDescInfoCAS 1

      ${EndIf}

    FunctionEnd

  !macroend
