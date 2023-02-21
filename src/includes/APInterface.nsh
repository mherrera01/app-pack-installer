; File: APInterface.nsh
; Author: Miguel Herrera

!macro AP_INSERT_UI_SETTINGS

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
  Page custom customizeAppPackPage /ENABLECANCEL
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  ; Pages in the uninstaller
  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

!macroend

!macro AP_INSERT_UI_LANGUAGES

  !insertmacro MUI_LANGUAGE "English"

!macroend

!macro AP_INSERT_UI_CUSTOMIZE_PACK_PAGE

  ; nsDialogs variables for storing the control handlers
  Var dialog
  Var textJsonFile
  Var saveTemplateDir

  Function customizeAppPackPage

    !insertmacro MUI_HEADER_TEXT "Customize AppPack" "Choose the bundle of \
      applications you want to install."

    nsDialogs::Create 1018
    Pop $dialog

    ${If} $dialog == "error"
      Abort
    ${EndIf}

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

    ; ${NSD_Create*} x y width height text
    ; To center a component: 100 - (width + x) = % margin
    ${NSD_CreateHLine} 5% 10u 90% 34u ""
    Pop $0

    ;--------------------------------
    ; UI for a customized app bundle

    ${NSD_CreateGroupBox} 5% 30% 90% 55% "Customized App Bundle"
    Pop $0

      ${NSD_CreateLabel} 10% 40% 60% 20u "Create a custom JSON file with a \
        list of applications. Download the template to follow the correct format."
      Pop $0

      ${NSD_CreateButton} 70% 42% 20% 12u "Template"
      Pop $0
      ${NSD_OnClick} $0 onDownloadTemplate

      ${NSD_CreateLabel} 10% 60% 80% 12u "Select a JSON file:"
      Pop $0

      ${NSD_CreateFileRequest} 10% 70% 55% 12u "$EXEDIR\"
      Pop $textJsonFile

      ${NSD_CreateBrowseButton} 70% 70% 20% 12u "Browse..."
      Pop $0
      ${NSD_OnClick} $0 onJsonBrowse

  ;continue:
    nsDialogs::Show

  FunctionEnd

  Function onDownloadTemplate

    ; Open a window to select the folder where the template will be saved
    nsDialogs::SelectFolderDialog "Select a folder to save the template \
      JSON file." "$EXEDIR\"
    Pop $saveTemplateDir

    ; Exit the function if the user cancels the operation or an error ocurrs
    ${If} $saveTemplateDir == "error"
      Goto saveDirError
    ${EndIf}

    downloadTemplate:

      ; Download the JSON template file
      NScurl::http GET "${TEMPLATE_JSON_LINK}" \
        "$saveTemplateDir\Template.json" /TIMEOUT 1m /POPUP /END
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

    ; Get the directory from the UI component
    ${NSD_GetText} $textJsonFile $0

    ; Open a window to select a JSON file
    nsDialogs::SelectFileDialog open "$0" ".json files|*.json"
    Pop $0
    ${If} $0 != "error"
      ${NSD_SetText} $textJsonFile "$0"
    ${EndIf}

  FunctionEnd

!macroend
