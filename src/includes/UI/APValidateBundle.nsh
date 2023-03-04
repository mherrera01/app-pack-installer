; File: APValidateBundle.nsh
; Author: Miguel Herrera

!macro AP_SET_UI_JSON_COUNT_VBP elemUI value

  ; Not to show more than 3 digits in the JSON count UI
  StrLen $0 ${value}
  ${If} $0 > 3
    ${NSD_SetText} ${elemUI} "999+"
  ${Else}
    ${NSD_SetText} ${elemUI} "${value}"
  ${EndIf}

!macroend

!macro AP_CHECK_JSON_GET_ERROR_VBP jsonField

  ${If} ${Errors}
    Push "The JSON field '${jsonField}' is missing/misplaced."
    Call updateJsonValidationUIVBP
    Return
  ${EndIf}

!macroend

!macro AP_DEFINE_UI_VALIDATE_BUNDLE_PAGE

  ;--------------------------------
  ; VBP (Validate Bundle Page) variables

    Var dialogVBP
    Var boldFontVBP

    ; Default bundle UI handlers
    Var downloadStatusInfoVBP
    Var retryDownloadButtonVBP
    Var downloadProgressBarVBP

    ; HTTP download ID
    Var downloadDefBundleIdVBP

    ; JSON validation UI handlers
    Var appGroupsInfoVBP
    Var appsInfoVBP
    Var validationStatusInfoVBP
    Var validationMsgInfoVBP

    ; JSON values
    Var jsonCountAppGroupsVBP
    Var jsonCountAppsVBP

    Var backButtonVBP
    Var nextButtonVBP

  ;--------------------------------
  ; Main functions triggered on custom page creation and disposal

    Function validateBundlePage

      !insertmacro MUI_HEADER_TEXT "Validate Bundle" "Verify the \
        properties of the application bundle."

      nsDialogs::Create 1018
      Pop $dialogVBP

      ${If} $dialogVBP == "error"
        Abort
      ${EndIf}

      ; Create a bold font for the disclaimer
      CreateFont $boldFontVBP "Microsoft Sans Serif" "8.25" "700"

      ; Clear the error flag as it is set by the nsJSON functions
      ClearErrors

      ; Get the back and next button handlers
      GetDlgItem $nextButtonVBP $HWNDPARENT 1
      GetDlgItem $backButtonVBP $HWNDPARENT 3

      ; Different procedures depending on the previous page
      ; UI for the default bundle download
      ${If} $defaultBundleButtonStateCBP == ${BST_CHECKED}

        ; The status is set when the download starts
        ${NSD_CreateLabel} 0% 0% 80% 12u ""
        Pop $downloadStatusInfoVBP

        ${NSD_CreateButton} 85% 0% 15% 12u "Retry"
        Pop $retryDownloadButtonVBP
        ${NSD_OnClick} $retryDownloadButtonVBP onRetryDownloadVBP

        ; Create the progress bar of the bundle download
        ${NSD_CreateProgressBar} 0% 10% 100% 16u ""
        Pop $downloadProgressBarVBP

        ; Set the progress bar range from 0 to 100 (percentage)
        SendMessage $downloadProgressBarVBP ${PBM_SETRANGE32} 0 100

        ;--------------------------------
        ; JSON validation UI

          ${NSD_CreateGroupBox} 0% 30% 100% 30% ""
          Pop $0

            ${NSD_CreateLabel} 5% 38% 15% 12u "App groups:"
            Pop $0

            ${NSD_CreateLabel} 20% 38% 10% 12u ""
            Pop $appGroupsInfoVBP

            ${NSD_CreateLabel} 5% 48% 15% 12u "Apps:"
            Pop $0

            ${NSD_CreateLabel} 20% 48% 10% 12u ""
            Pop $appsInfoVBP

            ${NSD_CreateVLine} 35% 38% 0u 24u ""
            Pop $0

            ${NSD_CreateLabel} 40% 38% 55% 12u ""
            Pop $validationStatusInfoVBP

            ${NSD_CreateLabel} 40% 48% 55% 12u ""
            Pop $validationMsgInfoVBP

        ; Disclaimer bold text
        ${NSD_CreateLabel} 0% 68% 15% 12u "Disclaimer: "
        Pop $0
        SendMessage $0 ${WM_SETFONT} $boldFontVBP 0

        ${NSD_CreateLabel} 16% 68% 84% 20u "There is no intention \
          of appropriating any of the application executables used. \
          All the applications belong to their respective owners."
        Pop $0

        ; Download the default bundle and update the UI
        Call httpDefBundleDownloadVBP

      ${ElseIf} $customBundleButtonStateCBP == ${BST_CHECKED}
      ${EndIf}

      nsDialogs::Show

      ; Kill the progress bar timer, if any
      ${NSD_KillTimer} ondownloadProgressBarVBP

    FunctionEnd

    Function validateBundlePageLeave
    FunctionEnd

  ;--------------------------------
  ; Helper functions

    Function toggleBackNextButtonsVBP
      
      ; Enable (1) or disable (0) the back/next buttons of the page
      Pop $0
      EnableWindow $backButtonVBP $0
      EnableWindow $nextButtonVBP $0

    FunctionEnd

    Function httpDefBundleDownloadVBP

      ; Disable the back and next buttons until the download is completed
      Push 0
      Call toggleBackNextButtonsVBP

      ; The JSON validation UI is set to the loading status
      Push 0
      Call updateJsonValidationUIVBP

      ; Disable the retry button and set the download status
      EnableWindow $retryDownloadButtonVBP 0
      ${NSD_SetText} $downloadStatusInfoVBP "Downloading default bundle..."

      ; Create a timer to update the progress bar of the
      ; background bundle download (each 1000 ms)
      ${NSD_CreateTimer} ondownloadProgressBarVBP 1000

      ; Download asynchronously the default app bundle in the %temp% folder
      NScurl::http GET "${DEFAULT_BUNDLE_JSON_LINK}" \
        "$PLUGINSDIR\Apps.json" /TIMEOUT 1m /INSIST /BACKGROUND /END

      ; On background mode, the transfer ID is returned
      Pop $downloadDefBundleIdVBP

    FunctionEnd

    Function updateJsonValidationUIVBP

      ; Get the JSON validation status. 0 for loading, 1 on
      ; success and an error message otherwise
      Pop $0

      ; Loading status
      ${If} $0 == 0
        ${NSD_SetText} $appGroupsInfoVBP "..."
        ${NSD_SetText} $appsInfoVBP "..."

        ${NSD_SetText} $validationStatusInfoVBP "Validation status: \
          ............................ LOADING"
        ${NSD_SetText} $validationMsgInfoVBP ""

      ; Success status
      ${ElseIf} $0 == 1
        !insertmacro AP_SET_UI_JSON_COUNT_VBP $appGroupsInfoVBP $jsonCountAppGroupsVBP
        !insertmacro AP_SET_UI_JSON_COUNT_VBP $appsInfoVBP $jsonCountAppsVBP

        ${NSD_SetText} $validationStatusInfoVBP "Validation status: \
          .................................... OK"
        ${NSD_SetText} $validationMsgInfoVBP "Default bundle \
          validated successfully."

      ; Error status when a message is pushed to the stack
      ${Else}
        ${NSD_SetText} $appGroupsInfoVBP "X"
        ${NSD_SetText} $appsInfoVBP "X"

        ${NSD_SetText} $validationStatusInfoVBP "Validation status: \
          ............................... ERROR"
        ${NSD_SetText} $validationMsgInfoVBP "$0"

        ; Enable the back button and clear the error flag
        EnableWindow $backButtonVBP 1
        ClearErrors

      ${EndIf}      

    FunctionEnd

    Function setJsonBundlePropVBP

      ; Count the number of elements in appGroups
      ; The parameter /end must be included to prevent stack corruption
      nsJSON::Get /count "appGroups" /end
      Pop $jsonCountAppGroupsVBP
      !insertmacro AP_CHECK_JSON_GET_ERROR_VBP "appGroups"

      IntOp $1 $jsonCountAppGroupsVBP - 1
      StrCpy $jsonCountAppsVBP 0

      ; Check that all the parameters from the JSON are correct
      ; Iterate through the appGroups list
      ${ForEach} $R1 0 $1 + 1

        ; Check if the app group has a name
        nsJSON::Get "appGroups" /index $R1 "groupName" /end
        Pop $0
        !insertmacro AP_CHECK_JSON_GET_ERROR_VBP "groupName"

        nsJSON::Get /count "appGroups" /index $R1 "apps" /end
        Pop $0
        !insertmacro AP_CHECK_JSON_GET_ERROR_VBP "apps"

        IntOp $jsonCountAppsVBP $jsonCountAppsVBP + $0
        IntOp $2 $0 - 1

        ; Iterate through the apps list
        ${ForEach} $R2 0 $2 + 1

          nsJSON::Get "appGroups" /index $R1 "apps" /index $R2 "name" /end
          Pop $0
          !insertmacro AP_CHECK_JSON_GET_ERROR_VBP "name"

          nsJSON::Get "appGroups" /index $R1 "apps" /index $R2 "setupURL" /end
          Pop $0
          !insertmacro AP_CHECK_JSON_GET_ERROR_VBP "setupURL"

        ${Next}

      ${Next}

      ; Set a successfull JSON validation UI
      Push 1
      Call updateJsonValidationUIVBP

      ; Enable the back and next buttons
      Push 1
      Call toggleBackNextButtonsVBP

    FunctionEnd

  ;--------------------------------
  ; Event functions

    Function onRetryDownloadVBP

      ; Retry the default bundle download
      Call httpDefBundleDownloadVBP

    FunctionEnd

    Function ondownloadProgressBarVBP

      ; Check if an error ocurred during the download
      NScurl::query /ID $downloadDefBundleIdVBP "@ERROR@"
      Pop $0
      ${If} $0 != "OK"
        ${NSD_KillTimer} ondownloadProgressBarVBP

        ; Cancel the background download that failed
        NScurl::cancel /ID $downloadDefBundleIdVBP /REMOVE

        ; Display an error download status
        ${NSD_SetText} $downloadStatusInfoVBP "Download error. Check \
          your internet connection."

        ; Allow the user to retry the download
        EnableWindow $retryDownloadButtonVBP 1

        ; The JSON validation cannot be performed
        Push "The default bundle must be downloaded first."
        Call updateJsonValidationUIVBP
        Return
      ${EndIf}

      ; Get the download status in a formatted string
      NScurl::query /ID $downloadDefBundleIdVBP "[@PERCENT@%] @OUTFILE@, \
        @XFERSIZE@ / @FILESIZE@ @ @SPEED@"
      Pop $0

      ; Display the download status in the UI
      ${NSD_SetText} $downloadStatusInfoVBP "$0"

      ; Get the download percentage and update progress bar
      NScurl::query /ID $downloadDefBundleIdVBP "@PERCENT@"
      Pop $0
      SendMessage $downloadProgressBarVBP ${PBM_SETPOS} $0 0

      ; Check if the download is complete
      ${If} $0 == "100"
        ${NSD_KillTimer} ondownloadProgressBarVBP

        ; Update the download status to 'Completed'
        ${NSD_SetText} $downloadStatusInfoVBP "Completed"

        ; Load the default JSON bundle
        nsJSON::Set /file "$PLUGINSDIR\Apps.json"
        ${If} ${Errors}
          Push "The downloaded bundle could not be opened."
          Call updateJsonValidationUIVBP
        ${Else}
          Call setJsonBundlePropVBP
        ${EndIf}

      ${EndIf}

    FunctionEnd

!macroend
