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
; AP_SHOW_BUNDLE

  !macro __CALL_AP_SHOW_BUNDLE bundleFile logFile bundleProp bundleData treeViewUI

    Push "${treeViewUI}"
    Push "${bundleProp}"
    Push "${bundleData}"

    Push "${bundleFile}"
    Push "${logFile}"

    ${CallArtificialFunction} __AP_SHOW_BUNDLE

  !macroend

  !macro __AP_SHOW_BUNDLE

    ; logFile ($4), bundleFile ($3), bundleData ($2), bundleProp ($1) and treeViewUI ($0)
    System::Store Sr4r3r2r1r0

    ; Status code: string {OK, ERROR}
    ; Status message: string
    ; Number of app groups: int
    ; Number of apps: int
    ; Logfile available: int {0: false, 1: true}
    System::Call "*(t '', t '', i 0, i 0, i 0) i .R0"

    ; Open the bundle file to load
    ClearErrors
    FileOpen $R1 $3 r

    ${If} ${Errors}

      ClearErrors
      System::Call "*$R0(t 'ERROR', t 'The bundle file could not be opened.', i, i, i)"
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

    ; Create, or overwrite if it already exists, a log to record
    ; the parser operations
    FileOpen $R2 $4 w

    ; TODO: Write a line to the logfile about STARTING LOADING OF BUNDLE $name ...

    ; Check if the logfile has been created
    IfErrors +3

    ; Write UTF-16LE BOM at the beginning of the logfile
    FileWriteByte $R2 0xFF
    FileWriteByte $R2 0xFE

    ; Clear the arrays
    nsArray::Clear $1
    ${AP_FREE_BDATA_ARRAY} $2

    ; The error flag is set if an array does not exist
    ClearErrors

    ; TODO: Remove the elements in the treeview

    ; Initial values
    StrCpy $R3 0  ; Current bundle item
    StrCpy $R4 0  ; Current app group TV handle
    StrCpy $R5 0  ; Line number
    StrCpy $R6 "${ST_GEN_PROP}"  ; Current parser state
    StrCpy $R7 0  ; Number of app groups
    StrCpy $R8 0  ; Number of apps

    ${Do}

      ; Read a line in UTF-16LE encoding (unicode)
      FileReadUTF16LE $R1 $3

      ; The error flag is set with EOF (End Of File)
      ${If} ${Errors}

        StrCpy $4 1
        ClearErrors

      ${Else}

        ; Set the current line number
        IntOp $R5 $R5 + 1

        ${AP_FORMAT_LINE_READ} "$3" $3
        ${AP_CHECK_LINE_SKIP} $3
        Pop $4

        ${If} $4 == 1
          ${Continue}
        ${EndIf}

        StrCpy $4 0

      ${EndIf}

      ; $5 = Next state
      ; $6 = Transition info
      ${AP_HANDLE_EVENT} $R6 $4 $3 $5 $6
      Pop $4

      ; Execute transition actions
      ${If} $4 == ${EV_TRANSITION}

        ; Exit actions (current state)
        ${Switch} $R6

          ${Case} ${ST_NODE_PROP}

            ; Get the app group name
            ${AP_BITEM_GET_NAME} $R3 $7
            nsArray::Set $2 $R3

            ; Insert the app group to the tree view
            ${TV_INSERT_ITEM} $0 ${TVI_ROOT} $7 $R3
            Pop $R4
            ${TV_SET_ITEM_CHECK} $0 $R4 0

            ; Increase the number of app groups
            IntOp $R7 $R7 + 1
            ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] App group '$7' loaded correctly"

            ${Break}

          ${Case} ${ST_SUBNODE_PROP}

            ; Get the app properties
            System::Call "*$R3(i, t .r7, t, i, t .r8)"

            ; Ignore app if there is no setup URL
            ${If} $8 == ""
              ${AP_WRITE_BUNDLE_LOG} $R2 "[WARNING] Ignoring app '$7' as it does not have a setup URL"
            ${Else}

              nsArray::Set $2 $R3

              ; Insert the app to the group in the tree view
              ${TV_INSERT_ITEM} $0 $R4 $7 $R3
              Pop $8

              ; Increase the number of apps
              IntOp $R8 $R8 + 1
              ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] App '$7' loaded correctly"

            ${EndIf}

            ${Break}

        ${EndSwitch}

        ; Entry actions (next state)
        ${Switch} $5

          ${Case} ${ST_NODE_PROP}

            ${AP_BIDATA_AGRP} $6
            Pop $R3
            StrCpy $R4 0  ; Reset the app group handle
            ${Break}

          ${Case} ${ST_SUBNODE_PROP}

            ${AP_BIDATA_APP} $6
            Pop $R3
            ${Break}

          ${Case} ${ST_END_OK}

            ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] $6"
            System::Call "*$R0(t 'OK', t r6, i R7, i R8, i)"
            ${ExitDo}

          ${Case} ${ST_END_ERROR}

            ${AP_WRITE_BUNDLE_LOG} $R2 "[ERROR] $6"
            System::Call "*$R0(t 'ERROR', t r6, i 0, i 0, i)"
            ${ExitDo}

        ${EndSwitch}

      ; Internal activities
      ${ElseIf} $4 == ${EV_INT_ACTIVITY}

        ; Get the key-value pair
        ${AP_INT_ACT_INFO} $3 $7 $8
        Pop $4

        ${If} $4 == 1

          ; Within the current state
          ${Switch} $R6

            ${Case} ${ST_GEN_PROP}

              nsArray::Set $1 /key=$7 $8
              StrCpy $9 "[OK] General property '$7' with the value: $8"
              ${Break}

            ${Case} ${ST_NODE_PROP}

              ${AP_SET_AGRP_PROP} $R3 $7 $8
              Pop $9
              ${Break}

            ${Case} ${ST_SUBNODE_PROP}

              ${AP_SET_APP_PROP} $R3 $7 $8
              Pop $9
              ${Break}

          ${EndSwitch}

          ${AP_WRITE_BUNDLE_LOG} $R2 "$9"

        ${Else}

          ; Format error while parsing the bundle
          ${AP_WRITE_BUNDLE_LOG} $R2 "[ERROR] Incorrect file format in line $R5."
          System::Call "*$R0(t 'ERROR', t 'Incorrect file format in line $R5.', i 0, i 0, i)"

          System::Free $R3
          ${ExitDo}

        ${EndIf}

      ${EndIf}

      ; Update the current state
      StrCpy $R6 "$5"

    ${Loop}

    ; TODO: Store -2 for fopen error and -1 for fwrite >= 0 OK
    ${If} $R2 != ""
      FileClose $R2
      System::Call "*$R0(t, t, i, i, i 1)"
    ${EndIf}

    FileClose $R1

    endBundleLoad:

      Push $R0
      System::Store L

  !macroend

  !define AP_SHOW_BUNDLE "!insertmacro __CALL_AP_SHOW_BUNDLE"
