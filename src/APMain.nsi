; File: APMain.nsi
; Author: Miguel Herrera

;--------------------------------
; Includes

  ; User-defined NSH files
  !addincludedir ".\includes"

  !include "APSections.nsh"
  !include "MUI2.nsh"
  !include "nsDialogs.nsh"
  !include "LogicLib.nsh"

;--------------------------------
; Defines

  ; 1 for installing in the \TestInstallDir folder
  ; 0 for a production environment
  !define TEST 1
  !define PRODUCT_NAME "AppPack"

  ; The product version must be numerical with the format X.X.X
  !define PRODUCT_VERSION 1.0.0

  ; Directory where the uninstalling registry keys are stored
  !define UN_REGISTRY_DIR "Software\Microsoft\Windows\CurrentVersion\Uninstall"

  ; Link where the template JSON file is located
  !define TEMPLATE_JSON_LINK "https://raw.githubusercontent.com/mherrera01/app-pack-installer/develop/appBundles/Template.json"

;--------------------------------
; General

  ; Installer name
  Name "${PRODUCT_NAME}"
  OutFile "${PRODUCT_NAME}.exe"
  Unicode True

  ; Default installation folder
  !if ${TEST} = 1
    InstallDir "$EXEDIR\TestInstallDir\${PRODUCT_NAME}"
  !else
    InstallDir "$PROGRAMFILES\${PRODUCT_NAME}"
  !endif

  ; Get installation folder from the machine registry
  ; If available, the default path is overriden (for update purposes)
  InstallDirRegKey HKLM "Software\${PRODUCT_NAME}" "Path"

  ; Request admin privileges for not having problems with the third-party
  ; application setups
  RequestExecutionLevel admin

;--------------------------------
; Installer version info

  ; Necessary for including VIAddVersionKey
  ; The value must be numerical with the format X.X.X.X
  VIProductVersion "${PRODUCT_VERSION}.0"

  ; Info displayed in the Details tab of the installer properties
  VIAddVersionKey ProductName "${PRODUCT_NAME}"
  VIAddVersionKey ProductVersion "${PRODUCT_VERSION}"
  VIAddVersionKey LegalCopyright "Copyright (c) 2023 Miguel Herrera"
  VIAddVersionKey FileVersion "${PRODUCT_VERSION}"
  VIAddVersionKey FileDescription "An installer for a bundle of common Windows applications"

;--------------------------------
; Interface settings

  ; Show a message to the user when the installer is aborted
  !define MUI_ABORTWARNING

  ; Display customized icon
  !define MUI_ICON "..\Icon.ico"
  !define MUI_UNICON "..\Icon.ico"

  !define MUI_WELCOMEPAGE_TEXT "Setup will guide you through the \
    installation of AppPack.$\n$\nA bundle of third-party applications \
    you choose will be installed on your computer. Make sure you have \
    an internet connection.$\n$\nIt is recommended that you close all \
    other applications before starting Setup. This will make it possible \
    to update relevant system files without having to reboot your \
    computer.$\n$\nClick Next to continue."

  ; nsDialogs variables for the customizeAppPack page
  Var dialog
  Var textJsonFile
  Var saveTemplateDir

;--------------------------------
; Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "..\LICENSE"
  Page custom customizeAppPackPage /ENABLECANCEL
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
; Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Callback functions

  Function .onInit

    ; Clear the error flag as it may be set in ReadRegStr
    ClearErrors

    ; Check if there is installer info in the machine registry
    ReadRegStr $0 HKLM "Software\${PRODUCT_NAME}" "Version"

    ; Continue for a normal installation if no registry key is read
    ; IfErrors checks and clears the error flag
    IfErrors continueInst

    ; Ask the user for updating
    MessageBox MB_YESNO|MB_ICONQUESTION "${PRODUCT_NAME} version $0 is already \
      installed on your machine.$\nWould you like to update to version ${PRODUCT_VERSION}?" \
      IDYES continueInst
    
    ; Close the installer if the MessageBox returns NO
    Quit

  continueInst:
  FunctionEnd

;--------------------------------
; Functions

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

;--------------------------------
; Sections

  ; The common files and the uninstaller are installed by default
  !insertmacro AP_INSERT_INSTALLER_SECTION

  ;--------------------------------
  ; Optional apps to install, divided by groups

    SectionGroup "IT"

      !insertmacro AP_INSERT_APP_SECTION "WiX v3 Toolset" "SEC_WiXv3"

    SectionGroupEnd

  ; The section descriptions are set for displaying info text in the MUI Components page
  !insertmacro AP_SET_SECTION_DESC

  ; Uninstall section
  !insertmacro AP_INSERT_UNINSTALL_SECTION
