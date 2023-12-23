; File: APBundleParser.nsh
; Author: Miguel Herrera

; States
!define ST_GEN_PROP 0
!define ST_NODE_PROP 1
!define ST_SUBNODE_PROP 2
!define ST_END_ERROR 3
!define ST_END_OK 4

; Event types
!define EV_INT_ACTIVITY 0
!define EV_TRANSITION 1

; Triggers that can cause a transition
!define TRIG_NODE "> "
!define TRIG_NODE_NCHARS 2
!define TRIG_SUBNODE ">> "
!define TRIG_SUBNODE_NCHARS 3

; Internal activity
!define INT_ACT_TAG ": "

;--------------------------------
; AP_FORMAT_LINE_READ
; Format a line read from the bundle file by removing the
; leading spaces/tabs and the trailing new lines.
;
; - lineStr: The string to format.
; - formattedStr [out]: The result of the formatted string.

  !macro __CALL_AP_FORMAT_LINE_READ lineStr formattedStr

    Push "${lineStr}"

    ${CallArtificialFunction} __AP_FORMAT_LINE_READ
    Pop "${formattedStr}"

  !macroend

  !macro __AP_FORMAT_LINE_READ

    ; lineStr ($0)
    System::Store Sr0

    ; Remove the new lines at the end (\r and \n)
    ${TrimNewLines} "$0" $0

    ; Identation with spaces or tabs is recommended for a more
    ; readable bundle file, but it is not required
    ${Do}
      StrCpy $1 "$0" 1

      ; Remove tabs (U+0009) and spaces at the beginning of the line
      ${If} $1 == " "
      ${OrIf} $1 == "$\t"
        StrCpy $0 "$0" "" 1
      ${Else}
        ${Break}
      ${EndIf}

    ${Loop}

    Push $0
    System::Store L

  !macroend

  !define AP_FORMAT_LINE_READ "!insertmacro __CALL_AP_FORMAT_LINE_READ"

;--------------------------------
; AP_CHECK_LINE_SKIP
; Check if the line read has to be ignored. In the stack,
; 1 is returned if the line is a comment or an empty string,
; and 0 otherwise.
;
; - lineStr: The string to check if it must be skipped.

  !macro __CALL_AP_CHECK_LINE_SKIP lineStr

    Push "${lineStr}"

    ${CallArtificialFunction} __AP_CHECK_LINE_SKIP

  !macroend

  !macro __AP_CHECK_LINE_SKIP

    ; lineStr ($0)
    System::Store Sr0

    StrLen $1 "$0"
    StrCpy $2 "$0" 1

    ; Ignore empty and comment lines
    ${If} $1 == 0
    ${OrIf} $2 == "#"
      Push 1
    ${Else}
      Push 0
    ${EndIf}

    System::Store L

  !macroend

  !define AP_CHECK_LINE_SKIP "!insertmacro __CALL_AP_CHECK_LINE_SKIP"

;--------------------------------
; AP_HANDLE_EVENT
; Handle the parser event of reading a line from the bundle
; file. In case a trigger is found, a transition happens
; and EV_TRANSITION (1) is returned in the stack. Otherwise,
; an internal activity takes place while within the current
; state and EV_INT_ACTIVITY (0) is returned.
;
; - currentState: The current parser state.
; - isEOF: 1 if there is an End Of File (EOF) trigger or
;   0 otherwise.
; - lineStr: The string to get a trigger, if any, that can
;   cause a transition.
; - nextState [out]: The next parser state.
; - trInfo [out]: Additional info from the transition.

  !macro __CALL_AP_HANDLE_EVENT currentState isEOF lineStr nextState trInfo

    Push "${currentState}"
    Push "${isEOF}"
    Push "${lineStr}"

    ${CallArtificialFunction} __AP_HANDLE_EVENT
    Pop "${nextState}"
    Pop "${trInfo}"

  !macroend

  !macro __AP_HANDLE_EVENT

    ; lineStr ($2), isEOF ($1) and currentState ($0)
    System::Store Sr2r1r0

    ; Event type
    StrCpy $3 "${EV_TRANSITION}"

    ; End Of File (EOF)
    ${If} $1 == 1

      ${If} $0 == ${ST_GEN_PROP}

        StrCpy $4 "There are no elements in the bundle."
        StrCpy $5 "${ST_END_ERROR}"

      ${Else}

        StrCpy $4 "Bundle loaded successfully."
        StrCpy $5 "${ST_END_OK}"

      ${EndIf}

    ${Else}

      ; Characters that define the trigger
      StrCpy $6 "$2" ${TRIG_NODE_NCHARS}
      StrCpy $7 "$2" ${TRIG_SUBNODE_NCHARS}

      ${If} $6 == "${TRIG_NODE}"

        ; Get the node name
        StrCpy $4 "$2" "" ${TRIG_NODE_NCHARS}
        StrCpy $5 "${ST_NODE_PROP}"

      ${ElseIf} $7 == "${TRIG_SUBNODE}"

        ${If} $0 == ${ST_GEN_PROP}

          StrCpy $4 "Every app must be associated to one group."
          StrCpy $5 "${ST_END_ERROR}"

        ${Else}

          ; Get the sub-node name
          StrCpy $4 "$2" "" ${TRIG_SUBNODE_NCHARS}
          StrCpy $5 "${ST_SUBNODE_PROP}"

        ${EndIf}

      ${Else}

        ; Trigger not found, so there is no transition
        StrCpy $3 "${EV_INT_ACTIVITY}"
        StrCpy $4 ""
        StrCpy $5 "$0"

      ${EndIf}

    ${EndIf}

    Push $3
    Push $4
    Push $5

    System::Store L

  !macroend

  !define AP_HANDLE_EVENT "!insertmacro __CALL_AP_HANDLE_EVENT"

;--------------------------------
; AP_INT_ACT_INFO
; Get the key-value pair to process the internal activity
; of the parser states. 1 is returned in the stack if the
; info could be retrieved and 0 otherwise.
;
; - lineStr: The string to get the internal activity info.
; - key [out]: The key, if found, that identifies a property.
; - value [out]: The value of the corresponding key.

  !macro __CALL_AP_INT_ACT_INFO lineStr key value

    Push "${lineStr}"

    ${CallArtificialFunction} __AP_INT_ACT_INFO
    Pop "${key}"
    Pop "${value}"

  !macroend

  !macro __AP_INT_ACT_INFO

    ; lineStr ($0)
    System::Store Sr0

    ; Get the key
    ClearErrors
    ${WordFind} "$0" "${INT_ACT_TAG}" "E+1{" $1

    ${If} ${Errors}

      ; WordFind returns an error in the following scenarios:
      ; - Delimiter not found
      ; - No such word number
      ; - Syntax error (Use: +1, -1}, #, *, /word, ...)
      Push 0
      Push ""
      Push ""
      ClearErrors

    ${Else}

      ; Get the value of the key found
      ${WordFind} "$0" "${INT_ACT_TAG}" "+1}" $2
      Push 1
      Push $2
      Push $1

    ${EndIf}

    System::Store L

  !macroend

  !define AP_INT_ACT_INFO "!insertmacro __CALL_AP_INT_ACT_INFO"
