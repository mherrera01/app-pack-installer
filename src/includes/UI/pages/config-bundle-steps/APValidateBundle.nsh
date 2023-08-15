; File: APValidateBundle.nsh
; Author: Miguel Herrera

;--------------------------------
; VBS (Validate Bundle Step) variables

  !macro AP_DEFINE_UI_VALIDATE_BUNDLE_VARS

    ; Default bundle UI handlers
    Var downloadStatusInfoVBS
    Var retryDownloadButtonVBS
    Var downloadProgressBarVBS
    Var disclaimerLabelInfoVBS
    Var disclaimerInfoVBS

    ; HTTP download ID
    Var downloadDefBundleIdVBS

    ; JSON validation UI handlers
    Var jsonValidationBoxVBS
    Var appGroupsLabelInfoVBS
    Var appGroupsInfoVBS
    Var appsLabelInfoVBS
    Var appsInfoVBS
    Var vLineValidation
    Var validationStatusInfoVBS
    Var validationMsgInfoVBS

    ; JSON values
    Var jsonCountAppGroupsVBS
    Var jsonCountAppsVBS

    ; Custom bundle UI handlers
    Var warningLabelInfoVBS
    Var warningInfoVBS
    Var trustCustomBundleCheckVBS
    Var trustCustomBundleInfoVBS

  !macroend

;--------------------------------
; UI elements displayed on the page creation

  ; Default bundle
  !macro AP_DEFINE_UI_VB_DEFAULT_CREATION

    ; The status is set when the download starts
    ${NSD_CreateLabel} 0% 28% 80% 12u ""
    Pop $downloadStatusInfoVBS

    ${NSD_CreateButton} 85% 28% 15% 12u "Retry"
    Pop $retryDownloadButtonVBS

    ; Create the progress bar of the bundle download
    ${NSD_CreateProgressBar} 0% 38% 100% 14u ""
    Pop $downloadProgressBarVBS

    ; Set the progress bar range from 0 to 100 (percentage)
    SendMessage $downloadProgressBarVBS ${PBM_SETRANGE32} 0 100

    ; JSON validation UI (starting on 50% in the Y axis)
    Push 50
    Call createJsonValidationUIVBS

    ; Disclaimer bold text
    ${NSD_CreateLabel} 0% 85% 15% 12u "Disclaimer: "
    Pop $disclaimerLabelInfoVBS
    SendMessage $disclaimerLabelInfoVBS ${WM_SETFONT} $boldFontText 0

    ${NSD_CreateLabel} 16% 85% 84% 20u "There is no intention \
      of appropriating any of the application executables used. \
      All the applications belong to their respective owners."
    Pop $disclaimerInfoVBS

  !macroend

  ; Custom bundle
  !macro AP_DEFINE_UI_VB_CUSTOM_CREATION

    ; JSON validation UI (starting on 28% in the Y axis)
    Push 28
    Call createJsonValidationUIVBS

    ; Warning bold text
    ${NSD_CreateLabel} 0% 65% 13% 12u "Warning: "
    Pop $warningLabelInfoVBS
    SendMessage $warningLabelInfoVBS ${WM_SETFONT} $boldFontText 0

    ${NSD_CreateLabel} 14% 65% 86% 26u "${PRODUCT_NAME} downloads \
      and executes the application setups specified in the custom \
      bundle. No security check is made to the links provided by the \
      JSON file and, hence, malicious code could be executed."
    Pop $warningInfoVBS

    ${NSD_CreateCheckBox} 14% 88% 4% 6% ""
    Pop $trustCustomBundleCheckVBS

    ${NSD_CreateLabel} 19% 88% 81% 12u "I trust the custom \
      bundle source"
    Pop $trustCustomBundleInfoVBS

  !macroend

;--------------------------------
; Functions

  !macro AP_DEFINE_UI_VALIDATE_BUNDLE_FUNC

    Function toggleVisibilityUIVBS

      ; Show (SW_SHOW) or hide (SW_HIDE) the UI components
      System::Store Sr0

      ; The UI that depends on the bundle selected
      ${If} $defaultBundleButtonStateCBP == ${BST_CHECKED}

        ShowWindow $downloadStatusInfoVBS $0
        ShowWindow $retryDownloadButtonVBS $0
        ShowWindow $downloadProgressBarVBS $0
        ShowWindow $disclaimerLabelInfoVBS $0
        ShowWindow $disclaimerInfoVBS $0

      ${ElseIf} $customBundleButtonStateCBP == ${BST_CHECKED}

        ShowWindow $warningLabelInfoVBS $0
        ShowWindow $warningInfoVBS $0
        ShowWindow $trustCustomBundleCheckVBS $0
        ShowWindow $trustCustomBundleInfoVBS $0

      ${EndIf}

      ; The JSON validation UI
      ShowWindow $jsonValidationBoxVBS $0
      ShowWindow $appGroupsLabelInfoVBS $0
      ShowWindow $appGroupsInfoVBS $0
      ShowWindow $appsLabelInfoVBS $0
      ShowWindow $appsInfoVBS $0
      ShowWindow $vLineValidation $0
      ShowWindow $validationStatusInfoVBS $0
      ShowWindow $validationMsgInfoVBS $0

      ; Restore the original values of the registers
      System::Store L

    FunctionEnd

    Function createJsonValidationUIVBS

      ; Get the position in the Y axis (percentage) of the UI
      ; group box, as a starting point for the rest of the elements
      Pop $0

      IntOP $1 $0 + 8
      IntOp $2 $0 + 18

      ${NSD_CreateGroupBox} 0% "$0%" 100% 30% ""
      Pop $jsonValidationBoxVBS

        ${NSD_CreateLabel} 5% "$1%" 15% 12u "App groups:"
        Pop $appGroupsLabelInfoVBS

        ${NSD_CreateLabel} 20% "$1%" 10% 12u ""
        Pop $appGroupsInfoVBS

        ${NSD_CreateLabel} 5% "$2%" 15% 12u "Apps:"
        Pop $appsLabelInfoVBS

        ${NSD_CreateLabel} 20% "$2%" 10% 12u ""
        Pop $appsInfoVBS

        ${NSD_CreateVLine} 35% "$1%" 0u 24u ""
        Pop $vLineValidation

        ${NSD_CreateLabel} 40% "$1%" 55% 12u ""
        Pop $validationStatusInfoVBS

        ${NSD_CreateLabel} 40% "$2%" 55% 12u ""
        Pop $validationMsgInfoVBS

    FunctionEnd
  
  !macroend
