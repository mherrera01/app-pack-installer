; File: APConfigBundle.nsh
; Author: Miguel Herrera

!macro AP_CHECK_JSON_GET_ERROR_CFBP jsonField

  ${If} ${Errors}
    Push "The JSON field '${jsonField}' is missing/misplaced."
    Call updateJsonValidationUICFBP
    ClearErrors
    Return
  ${EndIf}

!macroend

!macro AP_DEFINE_UI_CONFIG_BUNDLE_PAGE

  ;--------------------------------
  ; CFBP (ConFig Bundle Page) variables

    Var dialogCFBP

    ; Validate bundle step
    Var vbStepIconCFBP
    Var vbStepButtonCFBP
    Var vbFirstStepInfoCFBP
    Var vbStepInfoCFBP

    ; Choose apps step
    Var caStepIconCFBP
    Var caStepButtonCFBP
    Var caSecondStepInfoCFBP
    Var caStepInfoCFBP

    ; Step selector
    Var selectStepIconCFBP
    Var vbStepSelectorCFBP
    Var caStepSelectorCFBP

    Var backButtonCFBP
    Var nextButtonCFBP

  ;--------------------------------
  ; Variables for the steps UI

    !insertmacro AP_DEFINE_UI_VALIDATE_BUNDLE_VARS
    !insertmacro AP_DEFINE_UI_CHOOSE_APPS_VARS

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

      ; Clear the error flag as it is set by the nsJSON functions
      ClearErrors

      ; Get the back and next button handlers
      GetDlgItem $nextButtonCFBP $HWNDPARENT 1
      GetDlgItem $backButtonCFBP $HWNDPARENT 3

      ;--------------------------------
      ; First step UI menu

        ${NSD_CreateLabel} 0% 1% 3% 12u "1."
        Pop $vbFirstStepInfoCFBP
        SendMessage $vbFirstStepInfoCFBP ${WM_SETFONT} $boldFontText 0

        ${NSD_CreateLabel} 4% 1% 23% 20u "Verify the properties \
          of the app bundle"
        Pop $vbStepInfoCFBP

        System::Call "user32::LoadImage(i, t '$PLUGINSDIR\icons\bundle.ico', \
          i ${IMAGE_ICON}, i 24, i 24, i ${LR_LOADFROMFILE}) i .s"
        Pop $vbStepIconCFBP

        ${NSD_CreateButton} 30% 0% 7% 14% ""
        Pop $vbStepButtonCFBP
        ${NSD_AddStyle} $vbStepButtonCFBP ${BS_ICON}

        SendMessage $vbStepButtonCFBP ${BM_SETIMAGE} ${IMAGE_ICON} $vbStepIconCFBP
        ${NSD_OnClick} $vbStepButtonCFBP onChangeStepClickCFBP

      ${NSD_CreateHLine} 38% 16 25% 0u ""
      Pop $0

      ;--------------------------------
      ; Second step UI menu

        System::Call "user32::LoadImage(i, t '$PLUGINSDIR\icons\choose-apps.ico', \
          i ${IMAGE_ICON}, i 22, i 22, i ${LR_LOADFROMFILE}) i .s"
        Pop $caStepIconCFBP

        ${NSD_CreateButton} 63% 0% 7% 14% ""
        Pop $caStepButtonCFBP
        ${NSD_AddStyle} $caStepButtonCFBP ${BS_ICON}

        SendMessage $caStepButtonCFBP ${BM_SETIMAGE} ${IMAGE_ICON} $caStepIconCFBP
        ${NSD_OnClick} $caStepButtonCFBP onChangeStepClickCFBP

        ${NSD_CreateLabel} 73% 1% 3% 12u "2."
        Pop $caSecondStepInfoCFBP
        SendMessage $caSecondStepInfoCFBP ${WM_SETFONT} $boldFontText 0

        ${NSD_CreateLabel} 77% 1% 23% 20u "Choose the apps \
          you want to install"
        Pop $caStepInfoCFBP

      ;--------------------------------
      ; Step selector UI

        System::Call "user32::LoadImage(i, t '$PLUGINSDIR\icons\select-step.ico', \
          i ${IMAGE_ICON}, i 32, i 32, i ${LR_LOADFROMFILE}) i .s"
        Pop $selectStepIconCFBP

        ${NSD_CreateIcon} 30% 13% 7% 14% ""
        Pop $vbStepSelectorCFBP
        SendMessage $vbStepSelectorCFBP ${STM_SETICON} $selectStepIconCFBP 0

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

            !insertmacro AP_DEFINE_UI_VB_DEFAULT_CREATION
            ${NSD_OnClick} $retryDownloadButtonVBS onRetryDownloadCFBP

            ; Download the default bundle and update the UI
            Call httpDefBundleDownloadCFBP

          ${ElseIf} $customBundleButtonStateCBP == ${BST_CHECKED}

            !insertmacro AP_DEFINE_UI_VB_CUSTOM_CREATION
            ${NSD_OnClick} $trustCustomBundleCheckVBS onTrustBundleClickCFBP

            ; Disable buttons until the JSON validation is completed
            EnableWindow $caStepButtonCFBP 0
            EnableWindow $trustCustomBundleCheckVBS 0
            Push 0
            Call toggleBackNextButtonsCFBP

            ; The JSON validation UI is set to the loading status
            Push 0
            Call updateJsonValidationUICFBP

          ${Else}

            ; No bundle button selected
            Call .onGuIEnd
            Quit

          ${EndIf}

        ;--------------------------------
        ; Choose apps step

          !insertmacro AP_DEFINE_UI_CHOOSE_APPS_CREATION

      ; The validate bundle step is first displayed
      Push 1
      Call changeStepUICFBP

      ${If} $customBundleButtonStateCBP == ${BST_CHECKED}

        ; Create a thread for validating the custom bundle without
        ; blocking the UI
        ${Thread_Create} threadCustomBundleCFBP $0

      ${EndIf}

      nsDialogs::Show

      ; Kill the progress bar timer, if any
      ${NSD_KillTimer} ondownloadProgressBarVBS

    FunctionEnd

    Function configBundlePageLeave

      ; Free the icons loaded
      System::Call "user32::DestroyIcon(i $vbStepIconCFBP)"
      System::Call "user32::DestroyIcon(i $caStepIconCFBP)"
      System::Call "user32::DestroyIcon(i $selectStepIconCFBP)"

    FunctionEnd

  ;--------------------------------
  ; Helper functions

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

    ;--------------------------------
    ; Validate bundle step functions

      Function httpDefBundleDownloadCFBP

        ; Disable the back/next and second step buttons until the
        ; download is completed
        EnableWindow $caStepButtonCFBP 0
        Push 0
        Call toggleBackNextButtonsCFBP

        ; The JSON validation UI is set to the loading status
        Push 0
        Call updateJsonValidationUICFBP

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

      Function updateJsonValidationUICFBP

        ; Get the JSON validation status. 0 for loading, 1 on
        ; success and an error message otherwise
        Pop $0

        ; Loading status
        ${If} $0 == 0
          ${NSD_SetText} $appGroupsInfoVBS "..."
          ${NSD_SetText} $appsInfoVBS "..."

          ${NSD_SetText} $validationStatusInfoVBS "Validation status: \
            ............................ LOADING"
          ${NSD_SetText} $validationMsgInfoVBS ""

        ; Success status
        ${ElseIf} $0 == 1
          !insertmacro AP_SET_UI_COUNT_LIMIT $appGroupsInfoVBS $jsonCountAppGroupsVBS
          !insertmacro AP_SET_UI_COUNT_LIMIT $appsInfoVBS $jsonCountAppsVBS

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

        ${EndIf}

      FunctionEnd

      Function validateJsonBundleVBS

        ; Get the JSON bundle location
        Pop $0

        ; Load the JSON file
        nsJSON::Set /file "$0"
        ${If} ${Errors}
          Push "The JSON bundle could not be opened."
          Call updateJsonValidationUICFBP
          ClearErrors
        ${Else}
          Call setJsonBundlePropCFBP
        ${EndIf}

      FunctionEnd

      Function setJsonBundlePropCFBP

        ; Count the number of elements in appGroups
        ; The parameter /end must be included to prevent stack corruption
        nsJSON::Get /count "appGroups" /end
        Pop $jsonCountAppGroupsVBS
        !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "appGroups"

        IntOp $1 $jsonCountAppGroupsVBS - 1
        StrCpy $jsonCountAppsVBS 0

        ; Check that all the parameters from the JSON are correct
        ; Iterate through the appGroups list
        ${ForEach} $R1 0 $1 + 1

          ; Check if the app group has a name
          nsJSON::Get "appGroups" /index $R1 "groupName" /end
          Pop $0
          !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "groupName"

          nsJSON::Get /count "appGroups" /index $R1 "apps" /end
          Pop $0
          !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "apps"

          IntOp $jsonCountAppsVBS $jsonCountAppsVBS + $0
          IntOp $2 $0 - 1

          ; Iterate through the apps list
          ${ForEach} $R2 0 $2 + 1

            nsJSON::Get "appGroups" /index $R1 "apps" /index $R2 "name" /end
            Pop $0
            !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "name"

            nsJSON::Get "appGroups" /index $R1 "apps" /index $R2 "setupURL" /end
            Pop $0
            !insertmacro AP_CHECK_JSON_GET_ERROR_CFBP "setupURL"

          ${Next}

        ${Next}

        ; Set a successful JSON validation UI
        Push 1
        Call updateJsonValidationUICFBP

        ; Enable the back button
        EnableWindow $backButtonCFBP 1

        ; Enable the next step/trust bundle button 
        ${If} $customBundleButtonStateCBP == ${BST_CHECKED}
          EnableWindow $trustCustomBundleCheckVBS 1
        ${Else}
          EnableWindow $caStepButtonCFBP 1
        ${EndIf}

      FunctionEnd

  ;--------------------------------
  ; Event functions

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

    Function onRetryDownloadCFBP

      ; Empty the stack
      Pop $0

      ; Retry the default bundle download
      Call httpDefBundleDownloadCFBP

    FunctionEnd

    Function onTrustBundleClickCFBP

      ; Empty the stack
      Pop $0

      ; Enable next button only if the user trusts the custom bundle
      ${NSD_GetState} $trustCustomBundleCheckVBS $0
      EnableWindow $nextButtonCFBP $0

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
        Call updateJsonValidationUICFBP
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
        ${Thread_Create} threadDefBundleCFBP $0

      ${EndIf}

    FunctionEnd

  ;--------------------------------
  ; Functions for the steps UI

    !insertmacro AP_DEFINE_UI_VALIDATE_BUNDLE_FUNC
    !insertmacro AP_DEFINE_UI_CHOOSE_APPS_FUNC

  ;--------------------------------
  ; Thread routines

    Function threadDefBundleCFBP

      ; Validate the default JSON bundle in a different thread
      Push "$PLUGINSDIR\Apps.json"
      Call validateJsonBundleVBS

    FunctionEnd

    Function threadCustomBundleCFBP

      ; Validate the bundle provided in the previous page in a different thread
      Push "$jsonFileInputStateCBP"
      Call validateJsonBundleVBS

    FunctionEnd

!macroend
