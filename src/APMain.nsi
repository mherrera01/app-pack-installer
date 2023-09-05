; File: APMain.nsi
; Author: Miguel Herrera

;--------------------------------
; Includes

  !include "MUI2.nsh"
  !include "nsDialogs.nsh"
  !include "LogicLib.nsh"
  !include "FileFunc.nsh"
  !include "nsThread.nsh"
  !include "nsArray.nsh"

  ; User-defined NSH files
  !addincludedir ".\includes"
  !addincludedir ".\includes\UI"

  !include "APCoreUI.nsh"

;--------------------------------
; Defines

  ; 1 for installing in the \TestInstallDir folder
  ; 0 for a production environment
  !define TEST 1
  !define PRODUCT_NAME "AppPack"

  ; The product version must be numerical with the format X.X.X
  !define PRODUCT_VERSION 1.0.0

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

    ; Initialize the $PLUGINSDIR keyword which points to %temp%\nsxXXXX.tmp\
    ; Required for storing temporal files created by the installer
    InitPluginsDir

    ; Perform some initializations for the UI custom pages
    Call initCustomPagesUI

  FunctionEnd

  ; Last function called when the installer is closed
  Function .onGuIEnd

    ; The Nscurl plugin must be unloaded so that the NScurl.dll file
    ; can be removed from the %temp% folder.

    ; Get the NScurl module handle.
    ; System:Call PROC [(PARAM1, PARAM2, ...) [RETURN]]:
    ; PROC -> kernel32::GetModuleHandle
    ; (PARAM1) -> (t 'NScurl.dll') | type = string, source = concrete value
    ; RETURN -> i .s | type = integer, source = ignored, destination = stack
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

  Section

    ; Clear the error flag as it is set by ExecWait
    ClearErrors

    DetailPrint "Installing apps..."

    ; Download the app setup
    NScurl::http GET "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" \
      "$PLUGINSDIR\apps\chrome.msi" /TIMEOUT 30s /END

    ; It works, but if Google Chrome is already installed, an error is returned.
    ; TODO: Check how to handle the different error codes.
    ExecWait 'msiexec.exe /i "$PLUGINSDIR\apps\chrome.msi"'
    ${If} ${Errors}
      DetailPrint "Error"
      ClearErrors
    ${EndIf}

  SectionEnd
