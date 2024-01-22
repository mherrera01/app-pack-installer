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

  ;--------------------------------
  ; AP_WRITE_BUNDLE_LOG

    !macro __CALL_AP_WRITE_BUNDLE_LOG fp msg

      Push "${fp}"
      Push "${msg}"

      ${CallArtificialFunction} __AP_WRITE_BUNDLE_LOG
      Pop "${fp}"

    !macroend

    !macro __AP_WRITE_BUNDLE_LOG

      ; msg ($1) and fp ($0)
      System::Store Sr1r0

      ${If} $0 != ""

        ; Get the timestamp
        System::Call "*(&i2, &i2, &i2, &i2, &i2, &i2, &i2, &i2) i .R0"
        System::Call "kernel32::GetLocalTime(i R0)"
        System::Call "*$R0(&i2 .r2, &i2 .r3, &i2, &i2 .r4, &i2 .r5, &i2 .r6, &i2 .r7, &i2 .r8)"
        System::Free $R0

        ; Write the message in the logfile
        FileWriteUTF16LE $0 "$2-$3-$4 $5:$6:7.$8 - $1$\n"
        IfErrors 0 +2
        StrCpy $0 ""

      ${EndIf}

      Push $0
      System::Store L

    !macroend

    !define AP_WRITE_BUNDLE_LOG "!insertmacro __CALL_AP_WRITE_BUNDLE_LOG"

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
    System::Call "*(t '', t '', i 0, i 0, t '') i .R0"

    ; Open the bundle file to load
    ClearErrors
    FileOpen $R1 $0 r

    ${If} ${Errors}

      ClearErrors
      System::Call "*$R0(t 'ERROR', t 'The bundle file could not be opened.', i 0, i 0, t)"
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
    StrCpy $4 "$PLUGINSDIR\bundleLoad.log"
    FileOpen $R2 $4 w

    ; Check if the logfile has been created
    IfErrors +4
    System::Call "*$R0(t, t, i, i, t r4)"

    ; Write UTF-16LE BOM at the beginning of the logfile
    FileWriteByte $R2 0xFF
    FileWriteByte $R2 0xFE

    ; Clear the bundleProp array
    nsArray::Clear $1

    ; Clear and free the info from the bundleData array
    ${ForEachIn} $2 $4 $5
      System::Free $5
    ${Next}
    nsArray::Clear $2

    ; The error flag is set if an array does not exist
    ClearErrors

    ; Allocate a buffer to handle the parser:
    ; - Current state
    ; - Next state
    ; - Event type
    ; - Transition info
    ; System::Call "*(i ${ST_GEN_PROP}, i, i, t) i .R3"

    ; Store the current item (app or app group) properties
    ; that will be then added to the bundleData array:
    ; - Name
    ; - Description
    ; - Setup URL (empty for app groups)
    System::Call "*(t, t, t) i .R3"

    ; Initial values
    StrCpy $R4 0  ; Current app group TV handle
    StrCpy $R5 0  ; Line number
    StrCpy $R6 "${ST_GEN_PROP}"  ; Current parser state

    ${Do}

      ; Read a line in UTF-16LE encoding (unicode)
      FileReadUTF16LE $R1 $R7

      ; The error flag is set with EOF (End Of File)
      ${If} ${Errors}

        StrCpy $4 1
        ClearErrors

      ${Else}

        ; Set the current line number
        IntOp $R5 $R5 + 1

        ${AP_FORMAT_LINE_READ} "$R7" $R7
        ${AP_CHECK_LINE_SKIP} $R7
        Pop $4

        ${If} $4 == 1
          ${Continue}
        ${EndIf}

        StrCpy $4 0

      ${EndIf}

      ; $R8 = Next state
      ; $R9 = Transition info
      ${AP_HANDLE_EVENT} $R6 $4 $R7 $R8 $R9
      Pop $4

      ; Execute transition actions
      ${If} $4 == ${EV_TRANSITION}

        ; Exit actions (current state)
        ${Switch} $R6

          ${Case} ${ST_NODE_PROP}

            ; Get the app group properties
            System::Call "*$R3(t .r4, t .r5, t .r6)"

            ; App ID: 0
            ; Selected: 0 (default)
            System::Call "*(i 0, i 0, t r4, t r5, t r6) i .r7"

            ; Insert the app group to the tree view
            ${TV_INSERT_ITEM} $3 ${TVI_ROOT} $4 $7
            Pop $R4
            ${TV_SET_ITEM_CHECK} $3 $R4 0

            ; Increase the number of app groups
            System::Call "*$R0(t, t, i, i .r8, t)"
            IntOp $8 $8 + 1
            System::Call "*$R0(t, t, i, i r8, t)"

            ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] App group '$4' loaded correctly"

            ${Break}

          ${Case} ${ST_SUBNODE_PROP}

            ; Get the app properties
            System::Call "*$R3(t .r4, t .r5, t .r6)"

            ; Ignore app if there is no setup URL
            ${If} $6 == ""
              ${AP_WRITE_BUNDLE_LOG} $R2 "[WARNING] Ignoring app '$4' as it does not have a setup URL"
            ${Else}

              ; Increase the number of apps
              System::Call "*$R0(t, t, i .r7, i, t)"
              IntOp $7 $7 + 1
              System::Call "*$R0(t, t, i r7, i, t)"

              ; App ID: The app location in the bundle
              ; Selected: 0 (default)
              System::Call "*(i r7, i 0, t r4, t r5, t r6) i .r8"

              ; Insert the app to the group in the tree view
              ${TV_INSERT_ITEM} $3 $R4 $4 $8
              Pop $5

              ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] App '$4' loaded correctly"

            ${EndIf}

            ${Break}

        ${EndSwitch}

        ; Entry actions (next state)
        ${Switch} $R8

          ${Case} ${ST_NODE_PROP}

            ; Reset the app group handle
            StrCpy $R4 0

          ${Case} ${ST_SUBNODE_PROP}

            System::Call "*$R3(t R9, t '', t '')"
            ${Break}

          ${Case} ${ST_END_OK}

            ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] $R9"
            System::Call "*$R0(t 'OK', t R9, i, i, t)"
            Goto endBundleLoad

          ${Case} ${ST_END_ERROR}

            ${AP_WRITE_BUNDLE_LOG} $R2 "[ERROR] $R9"
            System::Call "*$R0(t 'ERROR', t R9, i 0, i 0, t)"
            Goto endBundleLoad

        ${EndSwitch}

      ; Internal activities
      ${ElseIf} $4 == ${EV_INT_ACTIVITY}

        ; Get the key-value pair
        ${AP_INT_ACT_INFO} $R7 $4 $5
        Pop $6

        ${If} $6 == 1

          StrCpy $6 "[OK] Property '$4' with the value: $5"

          ; Within the current state
          ${Switch} $R6

            ${Case} ${ST_GEN_PROP}

              nsArray::Set $1 /key=$4 $5
              ${Break}

            ${Case} ${ST_NODE_PROP}

              ${If} $4 == "groupDesc"
                System::Call "*$R3(t, t r5, t)"
              ${Else}
                StrCpy $6 "[WARNING] Ignoring property '$4'. Only the app group \
                  description can be specified with the groupDesc key"
              ${EndIf}

              ${Break}

            ${Case} ${ST_SUBNODE_PROP}

              ${If} $4 == "description"
                System::Call "*$R3(t, t r5, t)"
              ${ElseIf} $4 == "setupURL"
                System::Call "*$R3(t, t, t r5)"
              ${Else}
                StrCpy $6 "[WARNING] Ignoring property '$4'. Only the description \
                  and setupURL keys are allowed when defining an app"
              ${EndIf}

              ${Break}

          ${EndSwitch}

          ${AP_WRITE_BUNDLE_LOG} $R2 "$6"

        ${Else}

          ; Format error while parsing the bundle
          StrCpy $4 "Incorrect file format in line $R5."
          ${AP_WRITE_BUNDLE_LOG} $R2 "[ERROR] $4"
          System::Call "*$R0(t 'ERROR', t r4, i 0, i 0, t)"

          Goto endBundleLoad

        ${EndIf}

      ${EndIf}

      ; Update the current state
      StrCpy $R6 "$R8"

    ${Loop}

    endBundleLoad:

      FileClose $R1
      FileClose $R2
      System::Free $R3

      Push $R0

    System::Store L

  !macroend

  !define AP_LOAD_BUNDLE_FILE "!insertmacro __CALL_AP_LOAD_BUNDLE_FILE"
