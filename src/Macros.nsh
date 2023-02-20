; File: Macros.nsh
; Author: Miguel Herrera

;--------------------------------
; Compile-time code

!macro INSERT_APP_SECTION appName sectionName

  Section "${appName}" "${sectionName}"

    SetOutPath "$INSTDIR"

    ; Download the setup executable
    NScurl::http GET "https://github.com/wixtoolset/wix3/releases/latest/download/wix311.exe" "$INSTDIR\wix311.exe" /TIMEOUT 1m /CANCEL /RESUME /END

  SectionEnd

!macroend
