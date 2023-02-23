; File: APInterface.nsh
; Author: Miguel Herrera

!macro AP_SET_UI_SETTINGS

  ; Show a message to the user when the installer is aborted
  !define MUI_ABORTWARNING

  ; Display customized icon
  !define MUI_ICON "..\Icon.ico"
  !define MUI_UNICON "..\Icon.ico"

  ; Display customized text in the welcome page
  !define MUI_WELCOMEPAGE_TEXT "Setup will guide you through the \
    installation of AppPack.$\n$\nA bundle of third-party applications \
    you choose will be installed on your computer. Make sure you have \
    an internet connection.$\n$\nIt is recommended that you close all \
    other applications before starting Setup. This will make it possible \
    to update relevant system files without having to reboot your \
    computer.$\n$\nClick Next to continue."

!macroend

!macro AP_INSERT_UI_PAGES

  ; The order in which the pages are inserted, is the same as
  ; the one displayed in the UI

  ; Installer pages
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "..\LICENSE"

  ; Custom pages
  Page custom chooseBundlePage /ENABLECANCEL
  Page custom validateBundlePage validateBundlePageLeave /ENABLECANCEL

  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  ; Pages in the uninstaller
  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

!macroend

!macro AP_SET_UI_LANGUAGES

  !insertmacro MUI_LANGUAGE "English"

!macroend

;--------------------------------
; Custom pages

  !macro AP_DEFINE_UI_CHOOSE_BUNDLE_PAGE

    ;--------------------------------
    ; CBP (Choose Bundle Page) variables

      Var dialogCBP
      Var radioButtonDescCBP

      ; Customized app bundle UI handlers
      Var createJsonInfoCBP
      Var templateButtonCBP
      Var selectJsonInfoCBP
      Var jsonFileInputCBP
      Var browseJsonButtonCBP

      Var saveTemplateDirCBP

    ;--------------------------------
    ; Main function that creates the custom page

      Function chooseBundlePage

        !insertmacro MUI_HEADER_TEXT "Choose Bundle" "Choose the bundle of \
          applications you want to download."

        nsDialogs::Create 1018
        Pop $dialogCBP

        ${If} $dialogCBP == "error"
          Abort
        ${EndIf}

        ; ${NSD_Create*} x y width height text
        ; To center a component: 100 - |width + x| = % margin

        ;--------------------------------
        ; UI radio buttons

          ; Default bundle, which downloads the JSON file from the internet
          ${NSD_CreateFirstRadioButton} 5% 1% 40% 12u "Default bundle (recommended)"
          Pop $0

          ; Data associated to the radio button handler, that will be
          ; then retrieved by GetUserData
          nsDialogs::SetUserData $0 "DefaultButton"
          ${NSD_OnClick} $0 onRadioClick
          SendMessage $0 ${BM_CLICK} "" "" ; Select radio button

          ; Custom bundle, which accepts a JSON file given by the user
          ${NSD_CreateAdditionalRadioButton} 5% 12% 40% 12u "Custom bundle"
          Pop $0
          nsDialogs::SetUserData $0 "CustomButton"
          ${NSD_OnClick} $0 onRadioClick

          ${NSD_CreateGroupBox} 50% 0% 45% 20% ""
          Pop $0

            ${NSD_CreateLabel} 52% 5% 42% 20u "Download a predefined bundle of \
              apps from the internet."
            Pop $radioButtonDescCBP

          ${NSD_CreateHLine} 5% 25% 90% 0u ""
          Pop $0

        ;--------------------------------
        ; UI for a customized app bundle

          ${NSD_CreateGroupBox} 5% 35% 90% 55% "Customized App Bundle"
          Pop $0

            ${NSD_CreateLabel} 10% 45% 60% 20u "Create a custom JSON file with a \
              list of applications. Download the template to follow the correct format."
            Pop $createJsonInfoCBP

            ${NSD_CreateButton} 70% 47% 20% 12u "Template"
            Pop $templateButtonCBP
            ${NSD_OnClick} $templateButtonCBP onDownloadTemplate

            ${NSD_CreateLabel} 10% 65% 80% 12u "Select a JSON file:"
            Pop $selectJsonInfoCBP

            ${NSD_CreateFileRequest} 10% 75% 55% 12u "$EXEDIR\"
            Pop $jsonFileInputCBP

            ${NSD_CreateBrowseButton} 70% 75% 20% 12u "Browse..."
            Pop $browseJsonButtonCBP
            ${NSD_OnClick} $browseJsonButtonCBP onJsonBrowse

        ; Enable just the default UI components
        Push 0
        Call toggleUIComponents
        
        nsDialogs::Show

      FunctionEnd

    ;--------------------------------
    ; Helper functions

      Function toggleUIComponents
        
        ; Enable or disable the UI components that depend on choosing
        ; the custom bundle option
        Pop $0
        EnableWindow $createJsonInfoCBP $0
        EnableWindow $templateButtonCBP $0
        EnableWindow $selectJsonInfoCBP $0
        EnableWindow $jsonFileInputCBP $0
        EnableWindow $browseJsonButtonCBP $0

      FunctionEnd

    ;--------------------------------
    ; Event functions

      Function onRadioClick

        ; Get the control handler of the UI component that triggered the event
        Pop $0

        ; Get the radio button clicked
        nsDialogs::GetUserData $0
        Pop $1

        ; Change UI components depending on the radio button
        ${If} $1 == "DefaultButton"
          ${NSD_SetText} $radioButtonDescCBP "Download a predefined bundle of \
            apps from the internet."

          ; Disable the UI components for a customized app bundle
          Push 0
          Call toggleUIComponents

        ${ElseIf} $1 == "CustomButton"
          ${NSD_SetText} $radioButtonDescCBP "Full control over the apps and \
            versions you download, providing a valid JSON."

          ; Enable the UI components for a customized app bundle
          Push 1
          Call toggleUIComponents
        ${EndIf}

      FunctionEnd

      Function onDownloadTemplate

        ; Empty the stack
        Pop $0

        ; Open a window to select the folder where the template will be saved
        nsDialogs::SelectFolderDialog "Select a folder to save the template \
          JSON file." "$EXEDIR\"
        Pop $saveTemplateDirCBP

        ; Exit the function if the user cancels the operation or an error ocurrs
        ${If} $saveTemplateDirCBP == "error"
          Goto saveDirError
        ${EndIf}

        downloadTemplate:

          ; Download the JSON template file
          NScurl::http GET "${TEMPLATE_JSON_LINK}" \
            "$saveTemplateDirCBP\Template.json" /TIMEOUT 1m /POPUP /END
          Pop $0

          ${If} $0 == "OK"
            MessageBox MB_OK "Template downloaded successfully."
          ${Else}
            ; Allow the user to retry the download
            MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
              "$0$\nCheck your internet connection." \
              IDRETRY downloadTemplate
          ${EndIf}

      saveDirError:
      FunctionEnd

      Function onJsonBrowse

        ; Empty the stack
        Pop $0

        ; Get the directory from the UI component
        ${NSD_GetText} $jsonFileInputCBP $0

        ; Open a window to select a JSON file
        nsDialogs::SelectFileDialog open "$0" ".json files|*.json"
        Pop $0
        ${If} $0 != "error"
          ${NSD_SetText} $jsonFileInputCBP "$0"
        ${EndIf}

      FunctionEnd

  !macroend

  !macro AP_DEFINE_UI_VALIDATE_BUNDLE_PAGE

    ;--------------------------------
    ; VBP (Validate Bundle Page) variables

      Var dialogVBP
      Var downloadDefBundleVBP
      Var downloadStatusInfoVBP
      Var progressDefBundleVBP

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

        ${NSD_CreateProgressBar} 0% 10% 100% 20u ""
          Pop $progressDefBundleVBP

        SendMessage $progressDefBundleVBP ${PBM_SETRANGE32} 0 100

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

        ; Create a timer to update the progress bar of the
        ; background bundle download (each 1000 ms)
        ${NSD_CreateTimer} onProgressDefBundle 1000

        nsDialogs::Show

        ; Kill the previously set timer
        ${NSD_KillTimer} onProgressDefBundle

      FunctionEnd

      Function validateBundlePageLeave
      FunctionEnd

    ;--------------------------------
    ; Event functions

      Function onProgressDefBundle

        NScurl::query /ID $downloadDefBundleVBP "[@PERCENT@%] @OUTFILE@, \
          @XFERSIZE@ / @FILESIZE@ @ @SPEED@"
        Pop $0

        ${NSD_SetText} $downloadStatusInfoVBP "$0"

        NScurl::query /ID $downloadDefBundleVBP "@PERCENT@"
        Pop $0

        SendMessage $progressDefBundleVBP ${PBM_SETPOS} $0 0

        ; Check if the download is complete for killing the timer
        ${If} $0 == "100"
          ${NSD_KillTimer} onProgressDefBundle
        ${EndIf}

      FunctionEnd

  !macroend
