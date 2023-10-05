; File: APCoreUI.nsh
; Author: Miguel Herrera

!include "TreeViewControl.nsh"
!include "APUtils.nsh"

!include "pages\APChooseBundle.nsh"
!include "pages\APConfigBundle.nsh"
!include "pages\APConfirmInst.nsh"

!macro AP_SET_UI_SETTINGS

  ; Show a message to the user when the installer is aborted
  !define MUI_ABORTWARNING
  !define MUI_ABORTWARNING_TEXT "Are you sure you want to quit ${PRODUCT_NAME}?"

  ; Display customized icon
  !define MUI_ICON ".\resources\icons\AppPack.ico"

!macroend

!macro AP_INSERT_UI_PAGES

  ; The order in which the pages are inserted, is the same as
  ; the one displayed in the UI

  ;--------------------------------
  ; Welcome page

    !define MUI_WELCOMEFINISHPAGE_BITMAP ".\resources\welcome-page.bmp"
    !define MUI_WELCOMEPAGE_TITLE "Welcome to ${PRODUCT_NAME}"

    ; Display customized text in the welcome page
    !define MUI_WELCOMEPAGE_TEXT "${PRODUCT_NAME} is an open-source installer \
      designed to simplify the process of setting up your computer. You will \
      be able to create a fully customizable environment by installing multiple \
      third-party applications at once. You can either choose from a predefined \
      software bundle, or even provide your own selection.$\n$\nMake sure you \
      have an internet connection.$\nIt is recommended that you close all \
      other applications and reboot your computer when the installation has \
      finished.$\n$\nClick Next to continue."

    !insertmacro MUI_PAGE_WELCOME

  ;--------------------------------
  ; License page

    !define MUI_PAGE_HEADER_SUBTEXT "Please review the license terms of ${PRODUCT_NAME}."

    !define MUI_LICENSEPAGE_TEXT_BOTTOM "${PRODUCT_NAME} is under the MIT \
      license, which is a permissive software license. If you accept the terms \
      of the agreement, click I Agree to continue."

    !insertmacro MUI_PAGE_LICENSE "..\LICENSE"

  ; Custom pages
  Page custom chooseBundlePage chooseBundlePageLeave /ENABLECANCEL
  Page custom configBundlePage configBundlePageLeave /ENABLECANCEL
  Page custom confirmInstPage confirmInstPageLeave /ENABLECANCEL

  ;--------------------------------
  ; Installation page

    !define MUI_PAGE_HEADER_SUBTEXT "Please wait while ${PRODUCT_NAME} is \
      installing the apps."

    !define MUI_INSTFILESPAGE_FINISHHEADER_SUBTEXT "${PRODUCT_NAME} has \
      finished successfully."
    !define MUI_INSTFILESPAGE_ABORTHEADER_SUBTEXT "${PRODUCT_NAME} could not \
      complete the installation successfully."

    !insertmacro MUI_PAGE_INSTFILES

!macroend

!macro AP_SET_UI_LANGUAGES

  !insertmacro MUI_LANGUAGE "English"

!macroend

;--------------------------------
; Custom pages

  !macro AP_DEFINE_UI_CUSTOM_PAGES

    Var boldFontText

    !insertmacro AP_DEFINE_UI_CHOOSE_BUNDLE_PAGE
    !insertmacro AP_DEFINE_UI_CONFIG_BUNDLE_PAGE
    !insertmacro AP_DEFINE_UI_CONFIRM_INST_PAGE

    Function initCustomPagesUI

      ;--------------------------------
      ; Extract the UI icons required by the custom pages to the
      ; temp dir ($PLUGINSDIR)

        ; The icons are retrieved from the MDI library:
        ; https://pictogrammers.com/library/mdi/
        ;
        ; Then the icons are converted to the corresponding ICO
        ; format using ImageMagick.
        ; $> magick convert image.png -define icon:auto-resize="64,32,24,16" icon.ico
        SetOutPath "$PLUGINSDIR\icons"
        File ".\resources\icons\*.ico*"

        ; Set the default $OUTDIR, as SetOutPath locks the temp dir
        SetOutPath "-"

      ; Create a bold font to highlight a text
      CreateFont $boldFontText "Microsoft Sans Serif" "8.25" "700"

      ; Set the default values of the first custom page displayed
      Call setDefaultUIValuesCBP

    FunctionEnd

  !macroend
