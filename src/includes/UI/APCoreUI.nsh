; File: APCoreUI.nsh
; Author: Miguel Herrera

!include "TreeViewControl.nsh"
!include "APChooseBundle.nsh"
!include "config-bundle\APConfigBundle.nsh"

!macro AP_SET_UI_SETTINGS

  ; Show a message to the user when the installer is aborted
  !define MUI_ABORTWARNING

  ; Display customized icon
  !define MUI_ICON ".\icons\AppPack.ico"
  !define MUI_UNICON ".\icons\AppPack.ico"

  ; Display customized text in the welcome page
  !define MUI_WELCOMEPAGE_TEXT "Setup will guide you through the \
    installation of ${PRODUCT_NAME}.$\n$\nA bundle of third-party \
    applications you choose will be installed on your computer. Make \
    sure you have an internet connection.$\n$\nIt is recommended that \
    you close all other applications before starting Setup. This will \
    make it possible to update relevant system files without having \
    to reboot your computer.$\n$\nClick Next to continue."

!macroend

!macro AP_INSERT_UI_PAGES

  ; The order in which the pages are inserted, is the same as
  ; the one displayed in the UI

  ; Installer pages
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "..\LICENSE"

  ; Custom pages
  Page custom configBundlePage configBundlePageLeave /ENABLECANCEL
  Page custom chooseBundlePage chooseBundlePageLeave /ENABLECANCEL

  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  ; Pages in the uninstaller
  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

!macroend

!macro AP_SET_UI_LANGUAGES

  !insertmacro MUI_LANGUAGE "English"

!macroend

;--------------------------------
; Custom pages

!macro AP_DEFINE_UI_CUSTOM_PAGES

  !insertmacro AP_DEFINE_UI_CHOOSE_BUNDLE_PAGE
  !insertmacro AP_DEFINE_UI_CONFIG_BUNDLE_PAGE

!macroend
