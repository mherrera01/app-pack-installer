; File: APMain.nsi
; Author: Miguel Herrera

;--------------------------------
; Includes

  ; User-defined NSH files
  !addincludedir ".\includes"

  !include "APSections.nsh"
  !include "APInterface.nsh"

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
; Graphical interface

  ; Set UI custom settings
  !insertmacro AP_INSERT_UI_SETTINGS

  ; Insert the UI (built-in and custom) pages
  !insertmacro AP_INSERT_UI_PAGES

  ; Set the UI languages
  !insertmacro AP_INSERT_UI_LANGUAGES

  ; Define the parameters and functions for the custom pages
  !insertmacro AP_INSERT_UI_CUSTOMIZE_PACK_PAGE

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
