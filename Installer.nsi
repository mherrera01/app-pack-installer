; File: Installer.nsi
; Author: Miguel Herrera

;--------------------------------
; Includes

  !include "MUI2.nsh"

;--------------------------------
; Defines

  ; 1 for installing in the \TestInstallDir folder
  ; 0 for a production environment
  !define TEST 1
  !define PRODUCT_NAME "AppPack"

  ; The product version must be numerical with the format X.X.X.X
  !define PRODUCT_VERSION 1.0.0.0

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
  VIProductVersion "${PRODUCT_VERSION}"

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

  !define MUI_ICON ".\Icon.ico"

;--------------------------------
; Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE ".\LICENSE"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
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
; Installer sections

Section "${PRODUCT_NAME} (required)" SEC_Installer

  ; The installer data must be installed. Read-only section
  SectionIn RO
  SetOutPath "$INSTDIR"

  ; Add the license, readme and icon of the installer
  File ".\LICENSE"
  File ".\README.md"
  File ".\Icon.ico"
  
  ;--------------------------------
  ; The registry keys are stored under the WOW6432Node directory (32 bits)

  ; Store installation folder and version in the machine registry
  WriteRegStr HKLM "Software\${PRODUCT_NAME}" "Path" $INSTDIR
  WriteRegStr HKLM "Software\${PRODUCT_NAME}" "Version" ${PRODUCT_VERSION}
  
  ; Create registry keys in the local machine for uninstalling
  WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "DisplayIcon" '"$INSTDIR\Icon.ico"'

  ; NoModify and NoRepair set to 1 removes the possibility to modify
  ; and repair from the control panel
  WriteRegDWORD HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "NoModify" 1
  WriteRegDWORD HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "NoRepair" 1

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

SectionGroup "IT"

Section "WiX v3 Toolset" SEC_WiXv3

  SetOutPath "$INSTDIR"

  ; Add the setup executable
  File ".\Apps\wix311.exe"

SectionEnd

SectionGroupEnd

;--------------------------------
; Section descriptions

  ; Language strings
  LangString DESC_Installer ${LANG_ENGLISH} "The installer data."
  LangString DESC_WiXv3 ${LANG_ENGLISH} "The WiX toolset lets developers \
    create installers for Windows."

  ; Assign each language string to the corresponding sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_Installer} $(DESC_Installer)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_WiXv3} $(DESC_WiXv3)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Uninstaller section

Section "Uninstall"

  ; Delete all the app setups, if installed
  Delete "$INSTDIR\wix311.exe"

  ; Delete common files and the uninstaller
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\Icon.ico"
  Delete "$INSTDIR\Uninstall.exe"
  
  ; Remove the installation folder
  ; Never use the /r paramater as it is unsafe
  RMDir "$INSTDIR"

  ; Delete the registry keys in the local machine
  DeleteRegKey HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}"
  DeleteRegKey HKLM "Software\${PRODUCT_NAME}"

SectionEnd
