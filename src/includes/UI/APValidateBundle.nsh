; File: APValidateBundle.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_VALIDATE_BUNDLE_PAGE

  ;--------------------------------
  ; VBP (Validate Bundle Page) variables

    Var dialogVBP
    Var boldFontVBP

    Var downloadDefBundleVBP
    Var downloadStatusInfoVBP
    Var progressDefBundleVBP

    Var appGroupsInfoVBP
    Var appsInfoVBP
    Var jsonCountAppGroupsVBP
    Var jsonCountAppsVBP
    Var validationStatusInfoVBP
    Var validationMsgInfoVBP

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

      CreateFont $boldFontVBP "Microsoft Sans Serif" "8.25" "700"

      ; Clear the error flag as it is set by the nsJSON functions
      ClearErrors

      ; Different procedures depending on the previous page
      ${If} $defaultBundleButtonStateCBP == ${BST_CHECKED}

        ;--------------------------------
        ; UI for the default bundle download

          ${NSD_CreateLabel} 0% 0% 100% 12u "Downloading default bundle..."
          Pop $downloadStatusInfoVBP

          ; Create the progress bar of the bundle download
          ${NSD_CreateProgressBar} 0% 10% 100% 16u ""
          Pop $progressDefBundleVBP

          ; Set the progress bar range from 0 to 100 (percentage)
          SendMessage $progressDefBundleVBP ${PBM_SETRANGE32} 0 100

          ${NSD_CreateGroupBox} 0% 30% 100% 30% ""
          Pop $0

            ${NSD_CreateLabel} 5% 38% 15% 12u "App groups:"
            Pop $0

            ${NSD_CreateLabel} 20% 38% 10% 12u "..."
            Pop $appGroupsInfoVBP

            ${NSD_CreateLabel} 5% 48% 15% 12u "Apps:"
            Pop $0

            ${NSD_CreateLabel} 20% 48% 10% 12u "..."
            Pop $appsInfoVBP

            ${NSD_CreateVLine} 35% 38% 0u 24u ""
            Pop $0

            ${NSD_CreateLabel} 40% 38% 55% 12u "Validation status: \
              ............................ LOADING"
            Pop $validationStatusInfoVBP

            ${NSD_CreateLabel} 40% 48% 55% 12u ""
            Pop $validationMsgInfoVBP

          ${NSD_CreateLabel} 0% 68% 15% 12u "Disclaimer: "
          Pop $0
          SendMessage $0 ${WM_SETFONT} $boldFontVBP 0

          ${NSD_CreateLabel} 16% 68% 84% 20u "There is no intention \
            of appropriating any of the application executables used. \
            All the applications belong to their respective owners."
          Pop $0

          ; Create a timer to update the progress bar of the
          ; background bundle download (each 1000 ms)
          ${NSD_CreateTimer} onProgressDefBundleVBP 1000

          ; Download asynchronously the default app bundle
          NScurl::http GET "${DEFAULT_BUNDLE_JSON_LINK}" \
            "$PLUGINSDIR\Apps.json" /TIMEOUT 1m /BACKGROUND /END
          Pop $downloadDefBundleVBP

          ; Get the back and next button handlers
          GetDlgItem $nextButtonVBP $HWNDPARENT 1
          GetDlgItem $backButtonVBP $HWNDPARENT 3

          ; Disable the back and next buttons until the download is completed
          Push 0
          Call toggleBackNextButtonsVBP

      ${ElseIf} $customBundleButtonStateCBP == ${BST_CHECKED}

      ${EndIf}

      nsDialogs::Show

      ; Kill the progress bar timer, if any
      ${NSD_KillTimer} onProgressDefBundleVBP

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

    Function displayJsonErrorVBP

      ; Get the error message to display
      Pop $0

      ${NSD_SetText} $appGroupsInfoVBP "X"
      ${NSD_SetText} $appsInfoVBP "X"

      ${NSD_SetText} $validationStatusInfoVBP "Validation status: \
        ............................... ERROR"
      ${NSD_SetText} $validationMsgInfoVBP "$0"

      EnableWindow $backButtonVBP 1
      ClearErrors

    FunctionEnd

    Function setJsonBundlePropVBP

      ; Count the number of elements in appGroups
      ; The parameter /end must be included to prevent stack corruption
      nsJSON::Get /count "appGroups" /end
      Pop $jsonCountAppGroupsVBP
      ${If} ${Errors}
        Push "The JSON field 'appGroups' is missing/misplaced."
        Call displayJsonErrorVBP
        Goto jsonGetErrorVBP
      ${EndIf}

      IntOp $1 $jsonCountAppGroupsVBP - 1
      StrCpy $jsonCountAppsVBP 0

      ; Check that all the parameters from the JSON are correct
      ; Iterate through the appGroups list
      ${ForEach} $R1 0 $1 + 1

        ; Check if the app group has a name
        nsJSON::Get "appGroups" /index $R1 "groupName" /end
        Pop $0
        ${If} ${Errors}
          Push "The JSON field 'groupName' is missing/misplaced."
          Call displayJsonErrorVBP
          Goto jsonGetErrorVBP
        ${EndIf}

        nsJSON::Get /count "appGroups" /index $R1 "apps" /end
        Pop $0
        ${If} ${Errors}
          Push "The JSON field 'apps' is missing/misplaced."
          Call displayJsonErrorVBP
          Goto jsonGetErrorVBP
        ${EndIf}

        IntOp $jsonCountAppsVBP $jsonCountAppsVBP + $0
        IntOp $2 $0 - 1

        ; Iterate through the apps list
        ${ForEach} $R2 0 $2 + 1

          nsJSON::Get "appGroups" /index $R1 "apps" /index $R2 "name" /end
          Pop $0
          ${If} ${Errors}
            Push "The JSON field 'name' is missing/misplaced."
            Call displayJsonErrorVBP
            Goto jsonGetErrorVBP
          ${EndIf}

          nsJSON::Get "appGroups" /index $R1 "apps" /index $R2 "setupURL" /end
          Pop $0
          ${If} ${Errors}
            Push "The JSON field 'setupURL' is missing/misplaced."
            Call displayJsonErrorVBP
            Goto jsonGetErrorVBP
          ${EndIf}

        ${Next}

      ${Next}

      StrLen $0 $jsonCountAppGroupsVBP
      ${If} $0 > 3
        ${NSD_SetText} $appGroupsInfoVBP "999+"
      ${Else}
        ${NSD_SetText} $appGroupsInfoVBP "$jsonCountAppGroupsVBP"
      ${EndIf}

      StrLen $0 $jsonCountAppsVBP
      ${If} $0 > 3
        ${NSD_SetText} $appsInfoVBP "999+"
      ${Else}
        ${NSD_SetText} $appsInfoVBP "$jsonCountAppsVBP"
      ${EndIf}

      ${NSD_SetText} $validationStatusInfoVBP "Validation status: \
        .................................... OK"
      ${NSD_SetText} $validationMsgInfoVBP "Default bundle \
        validated successfully."

      ; Enable the back and next buttons
      Push 1
      Call toggleBackNextButtonsVBP

    jsonGetErrorVBP:
    FunctionEnd

  ;--------------------------------
  ; Event functions

    Function onProgressDefBundleVBP

      ; Get the download status in a formatted string
      NScurl::query /ID $downloadDefBundleVBP "[@PERCENT@%] @OUTFILE@, \
        @XFERSIZE@ / @FILESIZE@ @ @SPEED@"
      Pop $0

      ; Display the download status in the UI
      ${NSD_SetText} $downloadStatusInfoVBP "$0"

      ; Get the download percentage and update progress bar
      NScurl::query /ID $downloadDefBundleVBP "@PERCENT@"
      Pop $0
      SendMessage $progressDefBundleVBP ${PBM_SETPOS} $0 0

      ; Check if the download is complete
      ${If} $0 == "100"
        ${NSD_KillTimer} onProgressDefBundleVBP

        ; Update the download status to 'Completed'
        ${NSD_SetText} $downloadStatusInfoVBP "Completed"

        ; Load the default JSON bundle
        ; TEST --------------------------------
        nsJSON::Set /file "$PLUGINSDIR\Apps.json"
        ${If} ${Errors}
          Push "The downloaded bundle could not be opened."
          Call displayJsonErrorVBP
        ${Else}
          Call setJsonBundlePropVBP
        ${EndIf}

      ${EndIf}

    FunctionEnd

!macroend
