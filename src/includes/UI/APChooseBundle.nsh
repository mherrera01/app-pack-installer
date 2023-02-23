; File: APChooseBundle.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_CHOOSE_BUNDLE_PAGE

  ;--------------------------------
  ; CBP (Choose Bundle Page) variables

    Var dialogCBP
    Var defaultBundleButtonCBP
    Var customBundleButtonCBP
    Var radioButtonDescCBP

    ; Customized app bundle UI handlers
    Var createJsonInfoCBP
    Var templateButtonCBP
    Var selectJsonInfoCBP
    Var jsonFileInputCBP
    Var browseJsonButtonCBP

    Var saveTemplateDirCBP
    Var nextButtonCBP

    ; Variables to keep the UI state
    Var defaultBundleButtonStateCBP
    Var customBundleButtonStateCBP
    Var radioButtonDescStateCBP
    Var jsonFileInputStateCBP

  ;--------------------------------
  ; Function that set the default UI values

    Function setDefaultUIValuesCBP

      StrCpy $defaultBundleButtonStateCBP ${BST_CHECKED}
      StrCpy $customBundleButtonStateCBP ${BST_UNCHECKED}
      StrCpy $radioButtonDescStateCBP "Download a predefined bundle of \
        apps from the internet."
      StrCpy $jsonFileInputStateCBP ""

    FunctionEnd

  ;--------------------------------
  ; Main functions triggered on custom page creation and disposal

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
        Pop $defaultBundleButtonCBP

        ; Select default radio button
        ${NSD_OnClick} $defaultBundleButtonCBP onRadioClickCBP
        ${NSD_SetState} $defaultBundleButtonCBP $defaultBundleButtonStateCBP

        ; Custom bundle, which accepts a JSON file given by the user
        ${NSD_CreateAdditionalRadioButton} 5% 12% 40% 12u "Custom bundle"
        Pop $customBundleButtonCBP
        ${NSD_OnClick} $customBundleButtonCBP onRadioClickCBP
        ${NSD_SetState} $customBundleButtonCBP $customBundleButtonStateCBP

        ${NSD_CreateGroupBox} 50% 0% 45% 20% ""
        Pop $0

          ${NSD_CreateLabel} 52% 5% 42% 20u "$radioButtonDescStateCBP"
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
          ${NSD_OnClick} $templateButtonCBP onDownloadTemplateCBP

          ${NSD_CreateLabel} 10% 65% 80% 12u "Select a JSON file:"
          Pop $selectJsonInfoCBP

          ${NSD_CreateFileRequest} 10% 75% 55% 12u "$jsonFileInputStateCBP"
          Pop $jsonFileInputCBP
          SendMessage $jsonFileInputCBP ${EM_SETREADONLY} 1 0

          ${NSD_CreateBrowseButton} 70% 75% 20% 12u "Browse..."
          Pop $browseJsonButtonCBP
          ${NSD_OnClick} $browseJsonButtonCBP onJsonBrowseCBP

      ; Get the next button handler
      GetDlgItem $nextButtonCBP $HWNDPARENT 1
      
      ; Enable just the default UI components
      Push $customBundleButtonStateCBP
      Call toggleUIComponentsCBP
      
      nsDialogs::Show

    FunctionEnd

    ; Only called when the 'Next' button is clicked
    Function chooseBundlePageLeave

      ; Store the current UI states for loading them on the next page creation
      ${NSD_GetState} $defaultBundleButtonCBP $defaultBundleButtonStateCBP
      ${NSD_GetState} $customBundleButtonCBP $customBundleButtonStateCBP
      ${NSD_GetText} $radioButtonDescCBP $radioButtonDescStateCBP
      ${NSD_GetText} $jsonFileInputCBP $jsonFileInputStateCBP

    FunctionEnd

  ;--------------------------------
  ; Helper functions

    Function toggleUIComponentsCBP
      
      ; Enable or disable the UI components that depend on choosing
      ; the custom bundle option
      Pop $0
      EnableWindow $createJsonInfoCBP $0
      EnableWindow $templateButtonCBP $0
      EnableWindow $selectJsonInfoCBP $0
      EnableWindow $jsonFileInputCBP $0
      EnableWindow $browseJsonButtonCBP $0

    FunctionEnd

    Function setNextButtonStateOnJsonCBP

      ; Get the JSON file from the UI component
      ${NSD_GetText} $jsonFileInputCBP $0

      ; Enable or disable the next button depending on whether a JSON
      ; file has been selected
      ${If} $0 == ""
        EnableWindow $nextButtonCBP 0
      ${Else}
        EnableWindow $nextButtonCBP 1
      ${EndIf}

    FunctionEnd

  ;--------------------------------
  ; Event functions

    Function onRadioClickCBP

      ; Get the control handler of the UI component that triggered the event
      Pop $0

      ; Change UI components depending on the radio button
      ${If} $0 == $defaultBundleButtonCBP
        ${NSD_SetText} $radioButtonDescCBP "Download a predefined bundle of \
          apps from the internet."

        ; Disable the UI components for a customized app bundle
        Push 0
        Call toggleUIComponentsCBP

        ; Enable the next button as no JSON file is required
        EnableWindow $nextButtonCBP 1

      ${ElseIf} $0 == $customBundleButtonCBP
        ${NSD_SetText} $radioButtonDescCBP "Full control over the apps and \
          versions you download, providing a valid JSON."

        ; Enable the UI components for a customized app bundle
        Push 1
        Call toggleUIComponentsCBP

        ; Check whether the next button must be enabled or not
        Call setNextButtonStateOnJsonCBP
      ${EndIf}

    FunctionEnd

    Function onDownloadTemplateCBP

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

    Function onJsonBrowseCBP

      ; Empty the stack
      Pop $0

      ; Get the directory from the UI component
      ${NSD_GetText} $jsonFileInputCBP $0

      ; Open a window to select a JSON file
      nsDialogs::SelectFileDialog open "$0" ".json files|*.json"
      Pop $0
      ${If} $0 != "error"
        ${NSD_SetText} $jsonFileInputCBP "$0"

        ; Check whether the next button must be enabled or not
        Call setNextButtonStateOnJsonCBP
      ${EndIf}

    FunctionEnd

!macroend
