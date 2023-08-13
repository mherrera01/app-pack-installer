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

    ; Add the common files of the installer
    File "..\LICENSE"
    File "..\README.md"
    File ".\icons\AppPack.ico"
    
    ;--------------------------------
    ; The registry keys are stored under the WOW6432Node directory (32 bits)

    ; Store installation folder and version in the machine registry
    WriteRegStr HKLM "Software\${PRODUCT_NAME}" "Path" $INSTDIR
    WriteRegStr HKLM "Software\${PRODUCT_NAME}" "Version" ${PRODUCT_VERSION}
    
    ; Create registry keys in the local machine for uninstalling
    WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegStr HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}" "DisplayIcon" '"$INSTDIR\AppPack.ico"'
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

    ; https://nsis-dev.github.io/NSIS-Forums/html/t-333450.html
    /*${ForEach} $R1 0 $jsonCountAppsVBP + 1

      ; Download the setup executable
      NScurl::http GET "https://github.com/wixtoolset/wix3/releases/latest/download/wix311.exe" \
        "$INSTDIR\Apps\wix311.exe" /TIMEOUT 30s /END

    ${Next}*/

  SectionEnd

!macroend

!macro AP_INSERT_UNINSTALL_SECTION

  Section "Uninstall"

    ; Delete all the app setups, if installed
    Delete "$INSTDIR\Apps\wix311.exe"

    ; Remove the apps folder
    RMDir "$INSTDIR\Apps"

    ; Delete common files and the uninstaller
    Delete "$INSTDIR\LICENSE"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\AppPack.ico"
    Delete "$INSTDIR\Uninstall.exe"
    
    ; Remove the installation folder
    ; Never use the /r paramater as it is unsafe
    RMDir "$INSTDIR"

    ; Delete the registry keys in the local machine
    DeleteRegKey HKLM "${UN_REGISTRY_DIR}\${PRODUCT_NAME}"
    DeleteRegKey HKLM "Software\${PRODUCT_NAME}"

  SectionEnd

!macroend
