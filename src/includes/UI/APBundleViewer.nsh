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

    ; Define a unique ID for the labels used in the macro
    !define LABEL_ID ${__LINE__}

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
      System::Call "*$R0(t 'ERROR', t 'The bundle file could not be opened.')"
      Goto endBundleLoad_${LABEL_ID}

    ${EndIf}

    ${AP_SKIP_BFILE_BOM} $R1 $5 $6
    ${Switch} $5

      ; UTF-32 not supported
      ${Case} "${AP_BFILE_ENC_UTF32_LE}"
      ${Case} "${AP_BFILE_ENC_UTF32_BE}"

      ; UTF-16BE could be converted to UTF-16LE by swapping
      ; the 2-byte pairs. However, such operation with the
      ; System plugin is very slow, even when the bundle file
      ; is just 100KB.
      ${Case} "${AP_BFILE_ENC_UTF16_BE}"

        System::Call "*$R0(t 'ERROR', t 'The $5 encoding is not supported.')"
        FileClose $R1
        Goto endBundleLoad_${LABEL_ID}

      ${Case} ""  ; UTF-8 by default if no BOM is detected
        StrCpy $5 "UTF-8 (inferred)"

      ${Case} "${AP_BFILE_ENC_UTF8}"

        StrCpy $6 "$PLUGINSDIR\temp_bfile_unicode.txt"

        ; Convert the file to UTF-16LE
        ${AP_BFILE_UTF8_TO_16LE} $R1 $6
        Pop $7
        IntCmp $7 0 failUnicodeConv_${LABEL_ID}

        ; Open the UTF-16LE file in read mode
        FileOpen $7 $6 r
        IfErrors failUnicodeConv_${LABEL_ID}

        ; The new file will be now parsed
        FileClose $R1
        StrCpy $R1 $7
        ${Break}

        failUnicodeConv_${LABEL_ID}:

          System::Call "*$R0(t 'ERROR', t 'The bundle file could not be loaded as Unicode.')"
          FileClose $R1
          Goto endBundleLoad_${LABEL_ID}

    ${EndSwitch}

    ; Create, or overwrite if it already exists, a log to record
    ; the parser operations
    FileOpen $R2 $4 w

    ; Check if the logfile has been created
    ${IfNot} ${Errors}

      ; Write UTF-16LE BOM at the beginning of the logfile
      FileWriteByte $R2 0xFF
      FileWriteByte $R2 0xFE
      ClearErrors

      ; Info message with the file name and encoding
      ${GetFileName} $3 $6
      ${AP_WRITE_BUNDLE_LOG} $R2 "Encoding: $5 | Loading the bundle file $6..."

    ${EndIf}

    ; Clear the arrays
    nsArray::Clear $1
    ${AP_FREE_BDATA_ARRAY} $2

    ; Ignore error flag
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

      ; Read a line in UTF-16LE encoding (Unicode)
      ${AP_READ_BFILE_LINE} $R1 $3
      Pop $4

      ; Check EOF (End Of File)
      ${If} $4 == 0

        ; Set the current line number
        IntOp $R5 $R5 + 1

        ${AP_FORMAT_LINE_READ} "$3" $3
        ${AP_CHECK_LINE_SKIP} $3
        Pop $5

        ${If} $5 == 1
          ${Continue}
        ${EndIf}

      ${EndIf}

      ; $5 = Next state
      ; $6 = Transition info
      ${AP_HANDLE_EVENT} $R6 $4 $3 $5 $6
      Pop $4

      ; Execute transition actions
      ${If} $4 == ${EV_TRANSITION}

        ; Exit actions (current state)
        ${Select} $R6

          ${Case} ${ST_NODE_PROP}

            ; Get the app group name
            ${AP_BITEM_GET_NAME} $R3 $7
            nsArray::Set $2 $R3

            ; Insert the app group to the tree view
            ${TV_INSERT_ITEM} $0 ${TVI_ROOT} $7 $R3
            Pop $R4

            ${TV_SET_ITEM_CHECK} $0 $R4 0
            StrCpy $R3 0

            ; Increase the number of app groups
            IntOp $R7 $R7 + 1
            ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] App group '$7' loaded correctly"

          ${Case} ${ST_SUBNODE_PROP}

            ; Get the app properties
            ${AP_BITEM_GET_NAME} $R3 $7
            ${AP_APP_GET_URL} $R3 $8

            ; Ignore app if there is no setup URL
            ${If} $8 == ""
              ${AP_WRITE_BUNDLE_LOG} $R2 "[WARNING] Ignoring app '$7' as it does not have a setup URL"
            ${Else}

              nsArray::Set $2 $R3

              ; Insert the app to the group in the tree view
              ${TV_INSERT_ITEM} $0 $R4 $7 $R3
              Pop $8
              StrCpy $R3 0

              ; Increase the number of apps
              IntOp $R8 $R8 + 1
              ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] App '$7' loaded correctly"

            ${EndIf}

        ${EndSelect}

        ; Entry actions (next state)
        ${Select} $5

          ${Case} ${ST_NODE_PROP}

            ${AP_BIDATA_AGRP} $6 $R3
            StrCpy $R4 0  ; Reset the app group handle

          ${Case} ${ST_SUBNODE_PROP}

            ${AP_BIDATA_APP} $6 $R3

          ${Case} ${ST_END_OK}

            ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] $6"
            System::Call "*$R0(t 'OK', t r6, i R7, i R8, i)"
            ${ExitDo}

          ${Case} ${ST_END_ERROR}

            ${AP_WRITE_BUNDLE_LOG} $R2 "[ERROR] $6"
            System::Call "*$R0(t 'ERROR', t r6)"
            ${ExitDo}

        ${EndSelect}

      ; Internal activities
      ${ElseIf} $4 == ${EV_INT_ACTIVITY}

        ; Get the key-value pair
        ${AP_INT_ACT_INFO} $3 $7 $8
        Pop $4

        ${If} $4 == 1

          ; Within the current state
          ${Select} $R6

            ${Case} ${ST_GEN_PROP}

              nsArray::Set $1 /key=$7 $8
              ${AP_WRITE_BUNDLE_LOG} $R2 "[OK] General property '$7' with the value: $8"

            ${Case} ${ST_NODE_PROP}

              ${AP_AGRP_SET_PROP} $R3 $7 $8
              Pop $9
              ${AP_WRITE_BUNDLE_LOG} $R2 "$9"

            ${Case} ${ST_SUBNODE_PROP}

              ${AP_APP_SET_PROP} $R3 $7 $8
              Pop $9
              ${AP_WRITE_BUNDLE_LOG} $R2 "$9"

          ${EndSelect}

        ${Else}

          ; Format error while parsing the bundle
          ${AP_WRITE_BUNDLE_LOG} $R2 "[ERROR] Incorrect file format in line $R5"
          System::Call "*$R0(t 'ERROR', t 'Incorrect file format in line $R5.')"
          ${ExitDo}

        ${EndIf}

      ${EndIf}

      ; Update the current state
      StrCpy $R6 "$5"

    ${Loop}

    ; Check if the logfile was loaded without errors
    ${If} $R2 != ""
      FileClose $R2
      System::Call "*$R0(t, t, i, i, i 1)"
    ${EndIf}

    System::Free $R3
    FileClose $R1

    endBundleLoad_${LABEL_ID}:

      Push $R0
      System::Store L

      !undef LABEL_ID

  !macroend

  !define AP_SHOW_BUNDLE "!insertmacro __CALL_AP_SHOW_BUNDLE"
