; File: APValidateBundle.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_VALIDATE_BUNDLE_PAGE

  ;--------------------------------
  ; VBP (Validate Bundle Page) variables

    Var dialogVBP
    Var downloadDefBundleVBP
    Var downloadStatusInfoVBP
    Var progressDefBundleVBP

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

      ${NSD_CreateLabel} 0% 0% 100% 12u "Downloading default bundle..."
      Pop $downloadStatusInfoVBP

      ; Create the progress bar of the bundle download
      ${NSD_CreateProgressBar} 0% 10% 100% 16u ""
        Pop $progressDefBundleVBP

      ; Set the progress bar range from 0 to 100 (percentage)
      SendMessage $progressDefBundleVBP ${PBM_SETRANGE32} 0 100

      ; Create a timer to update the progress bar of the
      ; background bundle download (each 1000 ms)
      ${NSD_CreateTimer} onProgressDefBundle 1000

      ; Download asynchronously the default app bundle
      NScurl::http GET "${DEFAULT_BUNDLE_JSON_LINK}" \
        "$PLUGINSDIR\Apps.json" /TIMEOUT 1m /BACKGROUND /END
      Pop $downloadDefBundleVBP

      ; Clear the error flag as it is set by the nsJSON functions
      /*ClearErrors

      ; Load the json file in which the apps info is stored
      nsJSON::Set /file "$EXEDIR\Apps.json"
      ; IfErrors continue

      ; Get the value from apps[0] -> setupURL
      ; The parameter /end must be included to prevent stack corruption
      nsJSON::Get "apps" /index 0 "setupURL" /end
      IfErrors continue
      Pop $0*/

      ; Display the value from the JSON file
      ; ${NSD_CreateLabel} 1u 26u 100% 100% "SetupURL: $0"
      ; Pop $0

      ; Get the back and next button handlers
      GetDlgItem $nextButtonVBP $HWNDPARENT 1
      GetDlgItem $backButtonVBP $HWNDPARENT 3

      ; Disable the back and next buttons until the download is completed
      Push 0
      Call toggleBackNextButtons

      nsDialogs::Show

      ; Kill the previously set timer
      ${NSD_KillTimer} onProgressDefBundle

    FunctionEnd

    Function validateBundlePageLeave
    FunctionEnd

  ;--------------------------------
  ; Helper functions

    Function toggleBackNextButtons
      
      ; Enable or disable the back/next buttons of the page
      Pop $0
      EnableWindow $backButtonVBP $0
      EnableWindow $nextButtonVBP $0

    FunctionEnd

  ;--------------------------------
  ; Event functions

    Function onProgressDefBundle

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
        ; Enable the back and next buttons
        Push 1
        Call toggleBackNextButtons

        ; Update the download status to 'Completed'
        ${NSD_SetText} $downloadStatusInfoVBP "Completed"

        ${NSD_KillTimer} onProgressDefBundle
      ${EndIf}

    FunctionEnd

!macroend
