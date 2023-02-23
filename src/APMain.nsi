; File: APMain.nsi
; Author: Miguel Herrera

;--------------------------------
; Includes

  ; User-defined NSH files
  !addincludedir ".\includes"
  !addincludedir ".\includes\UI"

  !include "APSections.nsh"
  !include "APCoreUI.nsh"

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

  ; Links where the app bundles are located
  !define TEMPLATE_JSON_LINK "https://raw.githubusercontent.com/mherrera01/app-pack-installer/develop/appBundles/Template.json"
  !define DEFAULT_BUNDLE_JSON_LINK "https://raw.githubusercontent.com/mherrera01/app-pack-installer/develop/appBundles/Apps.json"

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
  !insertmacro AP_SET_UI_SETTINGS

  ; Insert the UI (built-in and custom) pages
  !insertmacro AP_INSERT_UI_PAGES

  ; Set the UI languages
  !insertmacro AP_SET_UI_LANGUAGES

  ; Define the parameters and functions for the custom pages
  !insertmacro AP_DEFINE_UI_CUSTOM_PAGES

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

      ; Initialize the $PLUGINSDIR keyword which points to %temp%\nsxXXXX.tmp\
      ; Required for storing temporal files created by the installer
      InitPluginsDir

      ; Set the default values of the custom pages
      Call setDefaultUIValuesCBP

  FunctionEnd

  ; Last function called when the installer is closed
  Function .onGuIEnd

    ; The Nscurl plugin must be unloaded so that the NScurl.dll file
    ; can be removed from the %temp% folder.

    ; Get the NScurl module handle.
    ; The 't' prefix indicates that the module name is null-terminated.
    ; A paramater is needed to get the GetModuleHandle return value:
    ; (i . s) consists of type (i = integer), source (. = ignored) and
    ; destination (s = stack).
    System::Call "kernel32::GetModuleHandle(t 'NScurl.dll') i .s"
    Pop $0

    ${If} $0 != 0
      ; Free the Nscurl module
      System::Call "kernel32::FreeLibrary(i $0) i .s"
      Pop $0
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
