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

;--------------------------------
; Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "..\LICENSE"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  Page custom downloadPage /ENABLECANCEL
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

    ; Continue for a normal installation
    IfErrors continue

    ; Ask the user for updating
    MessageBox MB_YESNO|MB_ICONQUESTION "${PRODUCT_NAME} version $0 is already \
      installed on your machine.$\nWould you like to update to version ${PRODUCT_VERSION}?" \
      IDYES continue
    
    ; Close the installer if the MessageBox returns NO
    Quit

  continue:
  FunctionEnd

;--------------------------------
; Functions

  Function downloadPage

    !insertmacro MUI_HEADER_TEXT "Apps Download" "Download from the internet the \
      different applications. This may take a while."

    nsDialogs::Create 1018
    Pop $0

    ${If} $0 == error
      Abort
    ${EndIf}

    ; Clear the error flag as it is set by the nsJSON functions
    ClearErrors

    ; Load the json file in which the info about the apps is stored
    nsJSON::Set /file "$EXEDIR\Apps.json"
    IfErrors continue

    ; Get the value from apps[0] -> setupURL
    ; The parameter /end must be included to prevent stack corruption
    nsJSON::Get "apps" /index 0 "setupURL" /end
    IfErrors continue
    Pop $0

    ; Display the value from the JSON file
    ${NSD_CreateLabel} 1u 26u 100% 100% "SetupURL: $0"
    Pop $0

  continue:
    nsDialogs::Show

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
