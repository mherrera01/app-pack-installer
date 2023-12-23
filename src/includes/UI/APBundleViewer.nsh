; File: APBundleViewer.nsh
; Author: Miguel Herrera

;--------------------------------
; AP_RESTORE_BUNDLE

  !macro __CALL_AP_RESTORE_BUNDLE

    ${CallArtificialFunction} __AP_RESTORE_BUNDLE

  !macroend

  !macro __AP_RESTORE_BUNDLE
  !macroend

;--------------------------------
; AP_LOAD_BUNDLE_FILE

  !macro __CALL_AP_LOAD_BUNDLE_FILE filePath bundleProp bundleData treeViewUI

    Push "${filePath}"
    Push "${bundleProp}"
    Push "${bundleData}"
    Push "${treeViewUI}"

    ${CallArtificialFunction} __AP_LOAD_BUNDLE_FILE

  !macroend

  !macro __AP_LOAD_BUNDLE_FILE

    ; treeViewUI ($3), bundleData ($2), bundleProp ($1) and filePath ($0)
    System::Store Sr3r2r1r0

    ; Allocate a buffer to set the status info that will be
    ; returned in the stack
    System::Call "*(t '', t '', i 0, i 0) i .R0"

    ClearErrors
    FileOpen $R1 $0 r
    ${If} ${Errors}

      ; The bundle was not loaded correctly
      System::Call "*$R0(t 'ERROR', t 'The bundle file could not be opened.', i 0, i 0)"

      ClearErrors
      Goto endBundleLoad

    ${EndIf}

    ; Use Unicode plug-in and convert to UTF-16LE (default Windows) if
    ; required. Then, read that encoding with FileReadUTF16LE (line by line,
    ; maybe there is a problem with NSIS_MAX_STRLEN??)

    ; https://github.com/AutoItConsulting/text-encoding-detect/blob/master/README.md
    ; 1. Detect if there is a BOM --> unicode::UnicodeType returns "None"
    ; if there is no BOM.
    ; In UTF-16 is normal to have a BOM, to differentiate between LE and BE (Notepad++
    ; adds a BOM by default).
    ; Nevertheless, UTF-8 does not require a BOM (Notepad++ always creates a file in
    ; UTF-8 without BOM)
    ; 2. Now, the problem is to distinguish between Windows-1252 (ANSI by default in
    ; Windows) and UTF-8 without BOM. Nowadays, UTF-8 is the standard to allow
    ; unicode.
    ;
    ; MultiByteToWideChar --> From UTF-8 (CP_UTF8) or Windows-1252/ANSI (CP_ACP) to
    ; UTF-16LE (Default Unicode in Windows)
    ; WideCharToMultiByte --> From UTF-16LE to UTF-8 (CP_UTF8) or Windows-1252/ANSI (CP_ACP)

    ; Allocate a buffer to handle the parser:
    ; - Current state
    ; - Next state
    ; - Event type
    ; - Transition info
    ; System::Call "*(i ${ST_GEN_PROP}, i, i, t) i .R2"

    ; Store the current item (app or app group) properties
    ; that will be then added to the bundleData array:
    ; - Name
    ; - Description
    ; - Setup URL (empty for app groups)
    System::Call "*(t, t, t) i .R2"

    ; Initial values
    StrCpy $R3 0  ; Current AG TV handle
    StrCpy $R4 0  ; Line number
    StrCpy $R5 "${ST_GEN_PROP}"  ; Current parser state

    ${Do}

      ; Read a line in UTF-16LE encoding (unicode)
      FileReadUTF16LE $R1 $R6

      ; The error flag is set with EOF (End Of File)
      ${If} ${Errors}

        StrCpy $4 1
        ClearErrors

      ${Else}

        ; Set the current line number
        IntOp $R4 $R4 + 1

        ${AP_FORMAT_LINE_READ} "$R6" $R6
        ${AP_CHECK_LINE_SKIP} $R6
        Pop $4

        ${If} $4 == 1
          ${Continue}
        ${EndIf}

        StrCpy $4 0

      ${EndIf}

      ; $R7 = Next state
      ; $R8 = Transition info
      ${AP_HANDLE_EVENT} $R5 $4 $R6 $R7 $R8
      Pop $4

      ; Execute transition actions
      ${If} $4 == ${EV_TRANSITION}

        ; Exit actions (current state)
        ${Switch} $R5

          ${Case} ${ST_NODE_PROP}

            ; Get the app group properties
            System::Call "*$R2(t .r4, t .r5, t .r6)"

            ; App ID: 0
            ; Selected: 0 (default)
            System::Call "*(i 0, i 0, t r4, t r5, t r6) i .r7"

            ; Insert the app group to the tree view
            ${TV_INSERT_ITEM} $3 ${TVI_ROOT} $4 $7
            Pop $R3
            ${TV_SET_ITEM_CHECK} $3 $R3 0

            ; Increase the number of app groups
            System::Call "*$R0(t, t, i, i .r8)"
            IntOp $8 $8 + 1
            System::Call "*$R0(t, t, i, i r8)"

            ${Break}

          ${Case} ${ST_SUBNODE_PROP}

            ; Get the app properties
            System::Call "*$R2(t .r4, t .r5, t .r6)"

            ; Ignore app if there is no setup URL
            ${If} $6 == ""
              ; Print warning
            ${Else}

              ; Increase the number of apps
              System::Call "*$R0(t, t, i .r7, i)"
              IntOp $7 $7 + 1
              System::Call "*$R0(t, t, i r7, i)"

              ; App ID: The app location in the bundle
              ; Selected: 0 (default)
              System::Call "*(i r7, i 0, t r4, t r5, t r6) i .r8"

              ; Insert the app to the group in the tree view
              ${TV_INSERT_ITEM} $3 $R3 $4 $8
              Pop $4

            ${EndIf}

            ${Break}

        ${EndSwitch}

        ; Entry actions (next state)
        ${Switch} $R7

          ${Case} ${ST_NODE_PROP}

            ; Reset the app group handle
            StrCpy $R3 0

          ${Case} ${ST_SUBNODE_PROP}

            System::Call "*$R2(t R8, t '', t '')"
            ${Break}

          ${Case} ${ST_END_OK}

            System::Call "*$R0(t 'OK', t R8, i, i)"
            Goto endBundleLoad

          ${Case} ${ST_END_ERROR}

            System::Call "*$R0(t 'ERROR', t R8, i 0, i 0)"
            Goto endBundleLoad

        ${EndSwitch}

      ; Internal activities
      ${ElseIf} $4 == ${EV_INT_ACTIVITY}

        ; Get the key-value pair
        ${AP_INT_ACT_INFO} $R6 $4 $5
        Pop $6

        ${If} $6 == 1

          ; Within the current state
          ${Switch} $R5

            ${Case} ${ST_GEN_PROP}

              nsArray::Set $1 /key=$4 $5
              ${Break}

            ${Case} ${ST_NODE_PROP}

              ${If} $4 == "groupDesc"
                System::Call "*$R2(t, t r5, t)"
              ${EndIf}

              ${Break}

            ${Case} ${ST_SUBNODE_PROP}

              ${If} $4 == "description"
                System::Call "*$R2(t, t r5, t)"
              ${ElseIf} $4 == "setupURL"
                System::Call "*$R2(t, t, t r5)"
              ${EndIf}

              ${Break}

          ${EndSwitch}

        ${Else}

          ; Format error while parsing the bundle
          System::Call "*$R0(t 'ERROR', t 'Incorrect file format in line $R4.', i 0, i 0)"
          Goto endBundleLoad

        ${EndIf}

      ${EndIf}

      ; Update the current state
      StrCpy $R5 "$R7"

    ${Loop}

    endBundleLoad:

      FileClose $R1
      ; System::Free $R2
      Push $R0

    System::Store L

  !macroend

  !define AP_LOAD_BUNDLE_FILE "!insertmacro __CALL_AP_LOAD_BUNDLE_FILE"
