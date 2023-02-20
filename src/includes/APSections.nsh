; File: APSections.nsh
; Author: Miguel Herrera

;--------------------------------
; A macro is used to insert code at compile time.
; The code defined in a macro will simply be inserted at the location of
; !insertmacro, as if copy/pasted, when the .nsi file is compiled.

!macro AP_INSERT_INSTALLER_SECTION

  Section "${PRODUCT_NAME} (required)" SEC_Installer

    ; The installer data must be installed. Read-only section
    SectionIn RO
    SetOutPath "$INSTDIR"

    ; Add the license, readme and icon of the installer
    File "..\LICENSE"
    File "..\README.md"
    File "..\Icon.ico"
    
    ;--------------------------------
    ; The registry keys are stored under the WOW6432Node directory (32 bits)

    ; Store installation folder and version in the machine registry
    WriteRegStr HKLM "Software\${PRODUCT_NAME}" "Path" $INSTDIR
    WriteRegStr HKLM "Software\${PRODUCT_NAME}" "Version" ${PRODUCT_VERSION}
    
    ; Create registry keys in the local machine for uninstalling
    WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "DisplayIcon" '"$INSTDIR\Icon.ico"'
    WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "Publisher" "Miguel Herrera"
    WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "DisplayVersion" "${PRODUCT_VERSION}"

    ; NoModify and NoRepair set to 1 removes the possibility to modify
    ; and repair from the control panel
    WriteRegDWORD HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "NoModify" 1
    WriteRegDWORD HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "NoRepair" 1

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"

  SectionEnd

!macroend

!macro AP_INSERT_APP_SECTION appName sectionName

  Section "${appName}" "${sectionName}"

    SetOutPath "$INSTDIR"

    ; Download the setup executable
    NScurl::http GET "https://github.com/wixtoolset/wix3/releases/latest/download/wix311.exe" "$INSTDIR\wix311.exe" /TIMEOUT 1m /CANCEL /RESUME /END

  SectionEnd

!macroend

!macro AP_SET_SECTION_DESC

  ; Language strings
  LangString DESC_Installer ${LANG_ENGLISH} "The installer data."
  LangString DESC_WiXv3 ${LANG_ENGLISH} "The WiX toolset lets developers \
    create installers for Windows."

  ; Assign each language string to the corresponding sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_Installer} $(DESC_Installer)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_WiXv3} $(DESC_WiXv3)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

!macroend

!macro AP_INSERT_UNINSTALL_SECTION

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

!macroend
