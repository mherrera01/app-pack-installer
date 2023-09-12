; File: APConfigBundle.nsh
; Author: Miguel Herrera

!define JSON_ITEM_MAX_DESC 192

!macro AP_CHECK_JSON_GET_ERROR_CFBP jsonField

  ${If} ${Errors}
    Push "The JSON field '${jsonField}' is missing/misplaced."
    Call updateJsonValidationUIVBS
    ClearErrors
    Return
  ${EndIf}

!macroend

!macro AP_ALLOCATE_JSON_ITEM_INFO isApp desc url

  System::Store S

  StrCpy $0 "${desc}" ${JSON_ITEM_MAX_DESC}
  StrCpy $1 "${url}"

  ; In case the URL string has the same length as the maximum
  ; allowed by NSIS, it is assumed that the value has been truncated.
  StrLen $2 $1
  ${If} $2 == ${NSIS_MAX_STRLEN}
    StrCpy $1 "The URL is too long. NSIS maximum string length is 1024."
  ${EndIf}

  ; Allocate a buffer to set the JSON item description and URL.
  ; The isApp variable indicates whether the JSON item is an app group
  ; (0) or an app (1). This pointer is then stored in the lParam
  ; parameter, so that it can be retrieved from the TVN_GETINFOTIP
  ; notification.
  System::Call "*(i ${isApp}, t r0, t r1) i .R0"
  Push $R0

  ; Store the pointer in an array for then deallocating the memory
  nsArray::Set jsonItemInfoArray $R0

  System::Store L

!macroend

!macro AP_DEFINE_UI_CONFIG_BUNDLE_PAGE

  ;--------------------------------
  ; CFBP (ConFig Bundle Page) variables

    Var dialogCFBP
    Var backButtonCFBP
    Var nextButtonCFBP

    ; First step menu
    Var vbStepIconCFBP
    Var vbOkStepIconCFBP
    Var vbErrorStepIconCFBP
    Var vbStepButtonCFBP
    Var vbFirstStepInfoCFBP
    Var vbStepInfoCFBP

    ; Second step menu
    Var caStepIconCFBP
    Var caStepButtonCFBP
    Var caSecondStepInfoCFBP
    Var caStepInfoCFBP

    ; Step selector
    Var selectStepIconCFBP
    Var vbStepSelectorCFBP
    Var caStepSelectorCFBP

    ;--------------------------------
    ; Validate bundle step

      ; Default bundle UI handlers
      Var downloadStatusInfoVBS
      Var retryDownloadButtonVBS
      Var downloadProgressBarVBS
      Var disclaimerLabelInfoVBS
      Var disclaimerInfoVBS

      ; Custom bundle UI handlers
      Var warningLabelInfoVBS
      Var warningInfoVBS
      Var trustCustomBundleCheckVBS
      Var trustCustomBundleInfoVBS

      ; HTTP download ID
      Var downloadDefBundleIdVBS

      ; JSON validation UI handlers
      Var jsonValidationBoxVBS
      Var appGroupsLabelInfoVBS
      Var appGroupsInfoVBS
      Var appsLabelInfoVBS
      Var appsInfoVBS
      Var vLineValidationVBS
      Var validationStatusInfoVBS
      Var validationMsgInfoVBS

      ; JSON values
      Var jsonCountAppGroupsVBS
      Var jsonCountAppsVBS

    ;--------------------------------
    ; Choose apps step

      Var appsTreeViewCAS
      Var appDescBoxCAS
      Var appDescInfoCAS

      Var appsSelectedInfoCAS
      Var appsSelectedDataCAS
      Var currentAppsSelectedCAS

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

      ; Clear the error flag as it is set by the nsJSON/nsArray functions
      ClearErrors

      ; Get the back and next button handlers
      GetDlgItem $nextButtonCFBP $HWNDPARENT 1
      GetDlgItem $backButtonCFBP $HWNDPARENT 3

      ; The back button performs the same operation as the leave
      ; function, due to the page disposal
      ${NSD_OnBack} configBundlePageLeave

      ;--------------------------------
      ; First step menu UI

        ${NSD_CreateLabel} 0% 1% 3% 12u "1."
        Pop $vbFirstStepInfoCFBP
        SendMessage $vbFirstStepInfoCFBP ${WM_SETFONT} $boldFontText 0

        ${NSD_CreateLabel} 4% 1% 23% 20u "Verify the properties \
          of the app bundle"
        Pop $vbStepInfoCFBP

        ; Load the icons for the different bundle states
        System::Call "user32::LoadImage(i, t '$PLUGINSDIR\icons\bundle-ok.ico', \
          i ${IMAGE_ICON}, i 24, i 24, i ${LR_LOADFROMFILE}) i .s"
        Pop $vbOkStepIconCFBP

        System::Call "user32::LoadImage(i, t '$PLUGINSDIR\icons\bundle-error.ico', \
          i ${IMAGE_ICON}, i 24, i 24, i ${LR_LOADFROMFILE}) i .s"
        Pop $vbErrorStepIconCFBP

        ; Display the initial icon button
        ${AP_CREATE_ICON_UI_ELEM} 30% 0% 7% 14% 1 "bundle.ico" 24 $vbStepIconCFBP
        Pop $vbStepButtonCFBP
        ${NSD_OnClick} $vbStepButtonCFBP onChangeStepClickCFBP

      ${NSD_CreateHLine} 38% 16 25% 0u ""
      Pop $0

      ;--------------------------------
      ; Second step menu UI

        ${AP_CREATE_ICON_UI_ELEM} 63% 0% 7% 14% 1 "choose-apps.ico" 22 $caStepIconCFBP
        Pop $caStepButtonCFBP
        ${NSD_OnClick} $caStepButtonCFBP onChangeStepClickCFBP

        ${NSD_CreateLabel} 73% 1% 3% 12u "2."
        Pop $caSecondStepInfoCFBP
        SendMessage $caSecondStepInfoCFBP ${WM_SETFONT} $boldFontText 0

        ${NSD_CreateLabel} 77% 1% 23% 20u "Choose the apps \
          you want to install"
        Pop $caStepInfoCFBP

      ;--------------------------------
      ; Step selector UI

        ${AP_CREATE_ICON_UI_ELEM} 30% 13% 7% 14% 0 "select-step.ico" 32 $selectStepIconCFBP
        Pop $vbStepSelectorCFBP

        ${NSD_CreateIcon} 63% 13% 7% 14% ""
        Pop $caStepSelectorCFBP
        SendMessage $caStepSelectorCFBP ${STM_SETICON} $selectStepIconCFBP 0

        nsDialogs::CreateControl "STATIC" ${DEFAULT_STYLES}|${SS_BLACKFRAME} 0 0% 21% 100% 1% ""
        Pop $0

      ;--------------------------------
      ; The steps UI content

        ;--------------------------------
        ; Validate bundle step

          ; Different procedures depending on the previous page
          ; UI for the default bundle download
          ${If} $defaultBundleButtonStateCBP == ${BST_CHECKED}

            ; The status is set when the download starts
            ${NSD_CreateLabel} 0% 28% 80% 12u ""
            Pop $downloadStatusInfoVBS

            ${NSD_CreateButton} 85% 28% 15% 12u "Retry"
            Pop $retryDownloadButtonVBS
            ${NSD_OnClick} $retryDownloadButtonVBS onRetryDownloadVBS

            ; Create the progress bar of the bundle download
            ${NSD_CreateProgressBar} 0% 38% 100% 14u ""
            Pop $downloadProgressBarVBS

            ; Set the progress bar range from 0 to 100 (percentage)
            SendMessage $downloadProgressBarVBS ${PBM_SETRANGE32} 0 100

            ; JSON validation UI (starting on 50% in the Y axis)
            Push 50
            Call createJsonValidationUIVBS

            ; Disclaimer bold text
            ${NSD_CreateLabel} 0% 85% 15% 12u "Disclaimer: "
            Pop $disclaimerLabelInfoVBS
            SendMessage $disclaimerLabelInfoVBS ${WM_SETFONT} $boldFontText 0

            ${NSD_CreateLabel} 16% 85% 84% 20u "There is no intention of \
              appropriating any of the third-party software components in \
              use. All the applications belong to their respective owners."
            Pop $disclaimerInfoVBS

            ; Download the default bundle and update the UI
            Call httpDefBundleDownloadVBS

          ${ElseIf} $customBundleButtonStateCBP == ${BST_CHECKED}

            ; JSON validation UI (starting on 28% in the Y axis)
            Push 28
            Call createJsonValidationUIVBS

            ; Warning bold text
            ${NSD_CreateLabel} 0% 65% 13% 12u "Warning: "
            Pop $warningLabelInfoVBS
            SendMessage $warningLabelInfoVBS ${WM_SETFONT} $boldFontText 0

            ${NSD_CreateLabel} 14% 65% 86% 26u "${PRODUCT_NAME} downloads \
              and executes the application setups specified in the custom \
              bundle. No security check is made to the links provided by the \
              JSON file and, hence, malicious code could be executed."
            Pop $warningInfoVBS

            ${NSD_CreateCheckBox} 14% 88% 4% 6% ""
            Pop $trustCustomBundleCheckVBS
            ${NSD_OnClick} $trustCustomBundleCheckVBS onTrustBundleClickVBS

            ${NSD_CreateLabel} 19% 88% 81% 12u "I trust the custom \
              bundle source"
            Pop $trustCustomBundleInfoVBS

            ; Disable buttons until the JSON validation is completed
            EnableWindow $caStepButtonCFBP 0
            EnableWindow $trustCustomBundleCheckVBS 0
            Push 0
            Call toggleBackNextButtonsCFBP

            ; The JSON validation UI is set to the loading status
            Push 0
            Call updateJsonValidationUIVBS

          ${Else}

            ; No bundle button selected
            Call .onGuIEnd
            Quit

          ${EndIf}

        ;--------------------------------
        ; Choose apps step

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

          ${NSD_CreateGroupBox} 65% 30% 34% 55% "Description"
          Pop $appDescBoxCAS

            ${NSD_CreateLabel} 67% 40% 30% 40% "Position your mouse over \
              a component to see its description."
            Pop $appDescInfoCAS

            ; Grey out the description until the mouse is over an app
            EnableWindow $appDescInfoCAS 0

          ${NSD_CreateLabel} 67% 88% 20% 12u "Apps selected:"
          Pop $appsSelectedInfoCAS

          StrCpy $currentAppsSelectedCAS "0"
          ${NSD_CreateLabel} 90% 88% 7% 12u "$currentAppsSelectedCAS"
          Pop $appsSelectedDataCAS

      ; The validate bundle step is first displayed
      Push 1
      Call changeStepUICFBP

      ${If} $customBundleButtonStateCBP == ${BST_CHECKED}

        ; Create a thread for validating the custom bundle without
        ; blocking the UI
        ${Thread_Create} threadCustomBundleVBS $0

      ${EndIf}

      nsDialogs::Show

      ; Kill the progress bar timer, if any
      ${NSD_KillTimer} ondownloadProgressBarVBS

    FunctionEnd

    Function configBundlePageLeave

      ; Free the icons loaded
      System::Call "user32::DestroyIcon(i $vbStepIconCFBP)"
      System::Call "user32::DestroyIcon(i $vbOkStepIconCFBP)"
      System::Call "user32::DestroyIcon(i $vbErrorStepIconCFBP)"
      System::Call "user32::DestroyIcon(i $caStepIconCFBP)"
      System::Call "user32::DestroyIcon(i $selectStepIconCFBP)"

      ; Free the memory allocated
      ${ForEachIn} jsonItemInfoArray $0 $1
        System::Free $1
      ${Next}

    FunctionEnd

  ;--------------------------------
  ; Steps menu functions

    Function toggleBackNextButtonsCFBP
      
      ; Enable (1) or disable (0) the back/next buttons of the page
      Pop $0
      EnableWindow $backButtonCFBP $0
      EnableWindow $nextButtonCFBP $0

    FunctionEnd

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
      Push $1
      Call toggleVisibilityUIVBS

      ; Opposite value | 0 ^ 1 = 1, 1 ^ 1 = 0
      IntOp $0 $0 ^ 1
      EnableWindow $caSecondStepInfoCFBP $0
      EnableWindow $caStepInfoCFBP $0
      EnableWindow $nextButtonCFBP $0

      IntOp $1 $0 * ${SW_SHOW}
      ShowWindow $caStepSelectorCFBP $1

      ; Show/hide the choose apps UI
      Push $1
      Call toggleVisibilityUICAS

    FunctionEnd

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
  ; Validate bundle step functions

    Function toggleVisibilityUIVBS

      ; Show (SW_SHOW) or hide (SW_HIDE) the UI components
      System::Store Sr0

      ; The UI depends on the bundle selected
      ${If} $defaultBundleButtonStateCBP == ${BST_CHECKED}

        ShowWindow $downloadStatusInfoVBS $0
        ShowWindow $retryDownloadButtonVBS $0
        ShowWindow $downloadProgressBarVBS $0
        ShowWindow $disclaimerLabelInfoVBS $0
        ShowWindow $disclaimerInfoVBS $0

      ${ElseIf} $customBundleButtonStateCBP == ${BST_CHECKED}

        ShowWindow $warningLabelInfoVBS $0
        ShowWindow $warningInfoVBS $0
        ShowWindow $trustCustomBundleCheckVBS $0
        ShowWindow $trustCustomBundleInfoVBS $0

      ${EndIf}

      ; The JSON validation UI
      ShowWindow $jsonValidationBoxVBS $0
      ShowWindow $appGroupsLabelInfoVBS $0
      ShowWindow $appGroupsInfoVBS $0
      ShowWindow $appsLabelInfoVBS $0
      ShowWindow $appsInfoVBS $0
      ShowWindow $vLineValidationVBS $0
      ShowWindow $validationStatusInfoVBS $0
      ShowWindow $validationMsgInfoVBS $0

      ; Restore the original values of the registers
      System::Store L

    FunctionEnd

    Function createJsonValidationUIVBS

      ; Get the position in the Y axis (percentage) of the UI
      ; group box, as a starting point for the rest of the elements
      Pop $0

      IntOP $1 $0 + 8
      IntOp $2 $0 + 18

      ${NSD_CreateGroupBox} 0% "$0%" 100% 30% ""
      Pop $jsonValidationBoxVBS

        ${NSD_CreateLabel} 5% "$1%" 15% 12u "App groups:"
        Pop $appGroupsLabelInfoVBS

        ${NSD_CreateLabel} 20% "$1%" 10% 12u ""
        Pop $appGroupsInfoVBS

        ${NSD_CreateLabel} 5% "$2%" 15% 12u "Apps:"
        Pop $appsLabelInfoVBS

        ${NSD_CreateLabel} 20% "$2%" 10% 12u ""
        Pop $appsInfoVBS

        ${NSD_CreateVLine} 35% "$1%" 0u 24u ""
        Pop $vLineValidationVBS

        ${NSD_CreateLabel} 40% "$1%" 55% 12u ""
        Pop $validationStatusInfoVBS

        ${NSD_CreateLabel} 40% "$2%" 55% 12u ""
        Pop $validationMsgInfoVBS

    FunctionEnd

    Function httpDefBundleDownloadVBS

      ; Disable the back/next and second step buttons until the
      ; download is completed
      EnableWindow $caStepButtonCFBP 0
      Push 0
      Call toggleBackNextButtonsCFBP

      ; The JSON validation UI is set to the loading status
      Push 0
      Call updateJsonValidationUIVBS

      ; Disable the retry button and set the download status
      EnableWindow $retryDownloadButtonVBS 0
      ${NSD_SetText} $downloadStatusInfoVBS "Downloading default bundle..."

      ; Create a timer to update the progress bar of the
      ; background bundle download (each 1000 ms)
      ${NSD_CreateTimer} ondownloadProgressBarVBS 1000

      ; Download asynchronously the default app bundle in the %temp% folder
      NScurl::http GET "${DEFAULT_BUNDLE_JSON_LINK}" \
        "$PLUGINSDIR\Apps.json" /TIMEOUT 30s /BACKGROUND /END

      ; On background mode, the transfer ID is returned
      Pop $downloadDefBundleIdVBS

    FunctionEnd

    ;--------------------------------
    ; JSON bundle

      Function updateJsonValidationUIVBS

        ; Get the JSON validation status. 0 for loading, 1 on
        ; success and an error message otherwise
        System::Store Sr0

        ; Loading status
        ${If} $0 == 0
          ${NSD_SetText} $appGroupsInfoVBS "..."
          ${NSD_SetText} $appsInfoVBS "..."

          ${NSD_SetText} $validationStatusInfoVBS "Validation status: \
            ............................ LOADING"
          ${NSD_SetText} $validationMsgInfoVBS ""

        ; Success status
        ${ElseIf} $0 == 1
          ${AP_SET_UI_COUNT_LIMIT} $appGroupsInfoVBS $jsonCountAppGroupsVBS
          ${AP_SET_UI_COUNT_LIMIT} $appsInfoVBS $jsonCountAppsVBS

          ${NSD_SetText} $validationStatusInfoVBS "Validation status: \
            .................................... OK"
          ${NSD_SetText} $validationMsgInfoVBS "Bundle validated successfully."

        ; Error status when a message is pushed to the stack
        ${Else}
          ${NSD_SetText} $appGroupsInfoVBS "X"
          ${NSD_SetText} $appsInfoVBS "X"

          ${NSD_SetText} $validationStatusInfoVBS "Validation status: \
            ............................... ERROR"
          ${NSD_SetText} $validationMsgInfoVBS "$0"

          ; Enable the back button
          EnableWindow $backButtonCFBP 1

          ; Set the bundle error icon
          SendMessage $vbStepButtonCFBP ${BM_SETIMAGE} ${IMAGE_ICON} $vbErrorStepIconCFBP

        ${EndIf}

        ; Restore the original values of the registers
        System::Store L

      FunctionEnd

      Function setJsonBundlePropVBS

        ; Count the number of elements in appGroups
        ; The parameter /end must be included to prevent stack corruption
        nsJSON::Get /count "appGroups" /end
        Pop $jsonCountAppGroupsVBS
        !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "appGroups"

        IntOp $R0 $jsonCountAppGroupsVBS - 1
        StrCpy $jsonCountAppsVBS 0

        ; Check that all the parameters from the JSON are correct
        ; Iterate through the appGroups list
        ${ForEach} $R1 0 $R0 + 1

          ; Check if the app group has a name
          nsJSON::Get "appGroups" /index $R1 "groupName" /end
          Pop $0
          !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "groupName"

          ; Get the app group description, if any
          nsJSON::Get "appGroups" /index $R1 "groupDesc" /end
          Pop $1
          ${If} ${Errors}
            StrCpy $1 ""
            ClearErrors
          ${EndIf}

          ; Allocate the app group info retrieved from the JSON
          ; to associate it to the tree view item
          !insertmacro AP_ALLOCATE_JSON_ITEM_INFO 0 $1 ""
          Pop $1

          ; Insert the app group to the tree view
          ${TV_INSERT_ITEM} $appsTreeViewCAS ${TVI_ROOT} $0 $1
          Pop $3
          ${TV_SET_ITEM_CHECK} $appsTreeViewCAS $3 0

          nsJSON::Get /count "appGroups" /index $R1 "apps" /end
          Pop $0
          !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "apps"

          IntOp $jsonCountAppsVBS $jsonCountAppsVBS + $0
          IntOp $R2 $0 - 1

          ; Iterate through the apps list
          ${ForEach} $R3 0 $R2 + 1

            nsJSON::Get "appGroups" /index $R1 "apps" /index $R3 "name" /end
            Pop $0
            !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "name"

            nsJSON::Get "appGroups" /index $R1 "apps" /index $R3 "description" /end
            Pop $1
            ${If} ${Errors}
              StrCpy $1 ""
              ClearErrors
            ${EndIf}

            nsJSON::Get "appGroups" /index $R1 "apps" /index $R3 "setupURL" /end
            Pop $2
            !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "setupURL"

            ; Allocate the app info retrieved from the JSON to associate
            ; it to the tree view item
            !insertmacro AP_ALLOCATE_JSON_ITEM_INFO 1 $1 $2
            Pop $1

            ; Insert the app to the group in the tree view
            ${TV_INSERT_ITEM} $appsTreeViewCAS $3 $0 $1
            Pop $0

          ${Next}

        ${Next}

        ; Set a successful JSON validation UI
        Push 1
        Call updateJsonValidationUIVBS

        ; Enable the back button
        EnableWindow $backButtonCFBP 1

        ; Set the successful bundle icon
        SendMessage $vbStepButtonCFBP ${BM_SETIMAGE} ${IMAGE_ICON} $vbOkStepIconCFBP

        ; Enable the next step/trust bundle button 
        ${If} $customBundleButtonStateCBP == ${BST_CHECKED}
          EnableWindow $trustCustomBundleCheckVBS 1
        ${Else}
          EnableWindow $caStepButtonCFBP 1
        ${EndIf}

      FunctionEnd

      Function validateJsonBundleVBS

        ; Get the JSON bundle location
        Pop $0

        ; Load the JSON file
        ; TODO: nsJSON cannot read UTF-8 files in unicode. Nevertheless,
        ; UTF-16 encoding is allowed, so maybe converting UTF-8 to UTF-16
        ; could be a workaround:
        ; https://nsis.sourceforge.io/Unicode_plug-in
        nsJSON::Set /file "$0"
        ${If} ${Errors}
          Push "The JSON bundle could not be opened."
          Call updateJsonValidationUIVBS
          ClearErrors
        ${Else}
          Call setJsonBundlePropVBS
        ${EndIf}

      FunctionEnd

    ;--------------------------------
    ; Events

      Function onRetryDownloadVBS

        ; Empty the stack
        Pop $0

        ; Retry the default bundle download
        Call httpDefBundleDownloadVBS

      FunctionEnd

      Function ondownloadProgressBarVBS

        ; Check if an error ocurred during the download
        NScurl::query /ID $downloadDefBundleIdVBS "@ERROR@"
        Pop $0
        ${If} $0 != "OK"
          ${NSD_KillTimer} ondownloadProgressBarVBS

          ; Cancel the background download that failed
          NScurl::cancel /ID $downloadDefBundleIdVBS /REMOVE

          ; Display an error download status
          ${NSD_SetText} $downloadStatusInfoVBS "Download error. Check \
            your internet connection."

          ; Allow the user to retry the download
          EnableWindow $retryDownloadButtonVBS 1

          ; The JSON validation cannot be performed
          Push "The default bundle must be downloaded first."
          Call updateJsonValidationUIVBS
          Return
        ${EndIf}

        ; Get the download status in a formatted string
        NScurl::query /ID $downloadDefBundleIdVBS "[@PERCENT@%] @OUTFILE@, \
          @XFERSIZE@ / @FILESIZE@ @ @SPEED@"
        Pop $0

        ; Display the download status in the UI
        ${NSD_SetText} $downloadStatusInfoVBS "$0"

        ; Get the download percentage and update progress bar
        NScurl::query /ID $downloadDefBundleIdVBS "@PERCENT@"
        Pop $0
        SendMessage $downloadProgressBarVBS ${PBM_SETPOS} $0 0

        ; Check if the download is complete
        ${If} $0 == "100"
          ${NSD_KillTimer} ondownloadProgressBarVBS

          ; Update the download status to 'Completed'
          ${NSD_SetText} $downloadStatusInfoVBS "Completed"

          ; Create a thread for validating the default bundle without
          ; blocking the UI
          ${Thread_Create} threadDefBundleVBS $0

        ${EndIf}

      FunctionEnd

      Function onTrustBundleClickVBS

        ; Empty the stack
        Pop $0

        ; Enable the second step button only if the user trusts
        ; the custom bundle
        ${NSD_GetState} $trustCustomBundleCheckVBS $0
        EnableWindow $caStepButtonCFBP $0

      FunctionEnd

    ;--------------------------------
    ; Thread routines

      Function threadDefBundleVBS

        ; Validate the default JSON bundle in a different thread
        Push "$PLUGINSDIR\Apps.json"
        Call validateJsonBundleVBS

      FunctionEnd

      Function threadCustomBundleVBS

        ; Validate the bundle provided in the previous page in a different thread
        Push "$jsonFileInputStateCBP"
        Call validateJsonBundleVBS

      FunctionEnd

  ;--------------------------------
  ; Choose apps step functions

    Function toggleVisibilityUICAS

      ; Show (SW_SHOW) or hide (SW_HIDE) the UI components
      System::Store Sr0

      ShowWindow $appsTreeViewCAS $0
      ShowWindow $appDescBoxCAS $0
      ShowWindow $appDescInfoCAS $0
      ShowWindow $appsSelectedInfoCAS $0
      ShowWindow $appsSelectedDataCAS $0

      ; Restore the original values of the registers
      System::Store L

    FunctionEnd

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
        ${AP_SET_UI_COUNT_LIMIT} $appsSelectedDataCAS $currentAppsSelectedCAS

      ; With the TVS_INFOTIP applied, the cursor is over an item
      ${ElseIf} $1 = ${TVN_GETINFOTIP}

        ; Read the item and its info in lParam from the
        ; NMTVGETINFOTIP structure
        System::Call "*$2(i, i, i, i, i, i .R0, i .R1)"

        ; Get the description string by using the lparam buffer
        System::Call "*$R1(i, t .r3, t)"

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
