; File: APBundleLoad.nsh
; Author: Miguel Herrera

;--------------------------------
; Bundle Data

  ; TODO [v2.0]: Implement Composite pattern for nested items
  ; in the bundle file (Indentation will indicate the level)
  ; https://refactoring.guru/design-patterns/composite
  ; Linked-list for the array of bundle items

  ; Item type: int {0: appGroup, 1: app}
  ; Name: string
  ; Description: string
  ; Selected: int {0: false, 1: true}
  !macro __AP_BITEM_DATA iType iParams name outVar
    System::Call "*(i ${iType}, t '${name}', t '', i 0, ${iParams}) i .s"
    Pop "${outVar}"
  !macroend

  !define AP_BITYPE_AGRP 0
  !define AP_BIDATA_AGRP `!insertmacro __AP_BITEM_DATA ${AP_BITYPE_AGRP} ""`

  ; Setup URL: string
  !define AP_BITYPE_APP 1
  !define AP_BIDATA_APP `!insertmacro __AP_BITEM_DATA ${AP_BITYPE_APP} "t ''"`

  ;--------------------------------
  ; Getters

    !macro __AP_BITEM_GET_DATA iParam iData outVar
      System::Call "*${iData}${iParam}"
      Pop "${outVar}"
    !macroend

    !define AP_BITEM_GET_TYPE "!insertmacro __AP_BITEM_GET_DATA '(i .s, t, t, i)'"
    !define AP_BITEM_GET_NAME "!insertmacro __AP_BITEM_GET_DATA '(i, t .s, t, i)'"
    !define AP_BITEM_GET_DESC "!insertmacro __AP_BITEM_GET_DATA '(i, t, t .s, i)'"
    !define AP_BITEM_GET_SEL  "!insertmacro __AP_BITEM_GET_DATA '(i, t, t, i .s)'"

    !define AP_APP_GET_URL "!insertmacro __AP_BITEM_GET_DATA '(i, t, t, i, t .s)'"

    ;--------------------------------
    ; AP_BITEM_GET_INFOTIP

      !macro __CALL_AP_BITEM_GET_INFOTIP iData infoTip

        Push "${iData}"

        ${CallArtificialFunction} __AP_BITEM_GET_INFOTIP
        Pop "${infoTip}"

      !macroend

      !macro __AP_BITEM_GET_INFOTIP

        ; iData ($0)
        System::Store Sr0

        ; Get the item name and description
        System::Call "*$0(i, t .r1, t .r2, i)"

        ; Return the name if there is no description
        ${If} $2 == ""
          StrCpy $2 "$1"
        ${EndIf}

        Push $2
        System::Store L

      !macroend

      !define AP_BITEM_GET_INFOTIP "!insertmacro __CALL_AP_BITEM_GET_INFOTIP"

  ;--------------------------------
  ; Setters

    ;--------------------------------
    ; AP_BITEM_SET_PROP

      !macro __AP_CHECK_PROP expr prop key setData
        ${${expr}} "${prop}" == "${key}"
          System::Call "${setData}"
      !macroend
      !define __AP_IF_PROP "!insertmacro __AP_CHECK_PROP If"
      !define __AP_ELSE_IF_PROP "!insertmacro __AP_CHECK_PROP ElseIf"

      !macro AP_BITEM_SET_PROP iType iData key value

        Push "${iData}"
        Push "${key}"
        Push "${value}"

        ${CallArtificialFunction} __AP_${iType}_SET_PROP

      !macroend

      !macro __AP_AGRP_SET_PROP

        ; value ($2), key ($1) and iData ($0)
        System::Store Sr2r1r0

        StrCpy $3 "[OK] App group property '$1' with the value: $2"

        ; App group properties
        ${__AP_IF_PROP} $1 "groupDesc" "*$0(i, t, t r2, i)"
        ${Else}
          StrCpy $3 "[WARNING] Ignoring property '$1'. Only the app group \
            description can be specified with the groupDesc key"
        ${EndIf}

        Push $3
        System::Store L

      !macroend

      !macro __AP_APP_SET_PROP

        ; value ($2), key ($1) and iData ($0)
        System::Store Sr2r1r0

        StrCpy $3 "[OK] App property '$1' with the value: $2"

        ; App properties
        ${__AP_IF_PROP} $1 "description" "*$0(i, t, t r2, i, t)"
        ${__AP_ELSE_IF_PROP} $1 "setupURL" "*$0(i, t, t, i, t r2)"
        ${Else}
          StrCpy $3 "[WARNING] Ignoring property '$1'. Only the description \
            and setupURL keys are allowed when defining an app"
        ${EndIf}

        Push $3
        System::Store L

      !macroend

      !define AP_AGRP_SET_PROP "!insertmacro AP_BITEM_SET_PROP AGRP"
      !define AP_APP_SET_PROP "!insertmacro AP_BITEM_SET_PROP APP"

  ;--------------------------------
  ; AP_FREE_BDATA_ARRAY

    !macro __CALL_AP_FREE_BDATA_ARRAY arrayName

      Push "${arrayName}"

      ${CallArtificialFunction} __AP_FREE_BDATA_ARRAY

    !macroend

    !macro __AP_FREE_BDATA_ARRAY

      ; arrayName ($0)
      System::Store Sr0

      ${ForEachIn} $0 $1 $2
        ; Free the bundle item data
        System::Free $2
      ${Next}
      nsArray::Clear $0

      System::Store L

    !macroend

    !define AP_FREE_BDATA_ARRAY "!insertmacro __CALL_AP_FREE_BDATA_ARRAY"

;--------------------------------
; Bundle Load Helpers

  !define AP_BFILE_MAX_BYTES 10485760  ; 10 MB
  !define AP_ENC_GUESS_BYTES 512

  ; File encodings
  !macro __AP_BFILE_ENC_INFO id name boml bomv

    ; Public
    !define AP_BFILE_ENC_${id} "${name}"

    ; Private
    !define __AP_ENC_ID_${id} "${id}"
    !define __AP_ENC_BOML_${id} "${boml}"
    !define __AP_ENC_BOMV_${id} "${bomV}"

  !macroend

  !insertmacro __AP_BFILE_ENC_INFO UTF32_LE "UTF-32LE" 4 "25525400"   ; [0xFF, 0xFE, 0x00, 0x00]
  !insertmacro __AP_BFILE_ENC_INFO UTF32_BE "UTF-32BE" 4 "00254255"   ; [0x00, 0x00, 0xFE, 0xFF]
  !insertmacro __AP_BFILE_ENC_INFO UTF16_LE "UTF-16LE" 2 "255254"     ; [0xFF, 0xFE]
  !insertmacro __AP_BFILE_ENC_INFO UTF16_BE "UTF-16BE" 2 "254255"     ; [0xFE, 0xFF]
  !insertmacro __AP_BFILE_ENC_INFO UTF8     "UTF-8"    3 "239187191"  ; [0xEF, 0xBB, 0xBF]

  ; The bundle file is either binary or uses an unsupported text encoding
  !define AP_BFILE_ENC_INVALID "Non-text content"

  ; Code pages
  !define AP_BFILE_CP_ACP  0
  !define AP_BFILE_CP_UTF8 65001

  ;--------------------------------
  ; AP_BFILE_DETECT_ENC
  ; Check the beginning of the file for byte order marks (BOM)
  ; associated with the UTF-32 LE/BE, UTF-16 LE/BE and UTF-8
  ; encodings. In the absence of a BOM, the encoding is inferred
  ; from NUL byte patterns, if present, which could label the
  ; bundle file as non-text content (AP_BFILE_ENC_INVALID).
  ;
  ; - bFile: The bundle file handle.
  ; - fileEnc [out]: The name of the encoding detected.
  ; - bytesBOM [out]: Bytes of the encoding BOM, if any.

    !macro __AP_CHECK_BFILE_BOM encId fileBytes outEnc outBoml endCheck

      ${If} "${__AP_ENC_BOMV_${encId}}" == "${fileBytes}"

        StrCpy ${outEnc} "${AP_BFILE_ENC_${encId}}"
        StrCpy ${outBoml} "${__AP_ENC_BOML_${encId}}"
        ${endCheck}

      ${EndIf}

    !macroend

    !macro __CALL_AP_BFILE_DETECT_ENC bFile fileEnc bytesBOM

      Push "${bFile}"

      ${CallArtificialFunction} __AP_BFILE_DETECT_ENC
      Pop "${fileEnc}"
      Pop "${bytesBOM}"

    !macroend

    !macro __AP_BFILE_DETECT_ENC

      ; bFile ($0)
      System::Store Sr0

      ; Read several bytes from the file to detect the encoding
      FileSeek $0 0 SET
      System::Call "*(&i${AP_ENC_GUESS_BYTES}) i .R0"
      System::Call "kernel32::ReadFile(i r0, i R0, i ${AP_ENC_GUESS_BYTES}, *i .R1, i 0) i .r1"

      StrCpy $R2 ""  ; File encoding
      StrCpy $R3 0   ; Bytes of the BOM, if any

      ${If} $1 != 0
      ${AndIf} $R1 > 1

        ; Get the first 4 bytes
        System::Call "*$R0(b .r1, b .r2, b .r3, b .r4)"

        ; The BOM length is 2-4 bytes
        StrCpy $5 $R1
        ${IfThen} $5 > 4 ${|} StrCpy $5 4 ${|}

        ; Check the byte order mark (BOM)
        ; https://unicode.org/faq/utf_bom.html#BOM
        ${Switch} $5

          ; UTF-32 (4 bytes)
          ${Case} 4
            !insertmacro __AP_CHECK_BFILE_BOM ${__AP_ENC_ID_UTF32_LE} "$1$2$3$4" $R2 $R3 '${Break}'
            !insertmacro __AP_CHECK_BFILE_BOM ${__AP_ENC_ID_UTF32_BE} "$1$2$3$4" $R2 $R3 '${Break}'

          ; UTF-8 (3 bytes)
          ${Case} 3
            !insertmacro __AP_CHECK_BFILE_BOM ${__AP_ENC_ID_UTF8} "$1$2$3" $R2 $R3 '${Break}'

          ; UTF-16 (2 bytes)
          ${Case} 2
            !insertmacro __AP_CHECK_BFILE_BOM ${__AP_ENC_ID_UTF16_LE} "$1$2" $R2 $R3 '${Break}'
            !insertmacro __AP_CHECK_BFILE_BOM ${__AP_ENC_ID_UTF16_BE} "$1$2" $R2 $R3 '${Break}'

        ${EndSwitch}

        ; Try to detect UTF-16 without BOM
        ${If} $R2 == ""

          StrCpy $1 0  ; Odd NUL bytes (usually UTF-16LE)
          StrCpy $2 0  ; Even NUL bytes (usually UTF-16BE)

          IntOp $3 $R1 - 1
          ${ForEach} $4 0 $3 + 1

            System::Call "*$R0(&i$4, &i1 .r5)"  ; Read one byte
            ${If} $5 == 0

              ; Check where the NUL bytes are located
              IntOp $6 $4 % 2
              ${If} $6 == 0
                IntOp $2 $2 + 1  ; Even NUL byte (starting at zero)
              ${Else}
                IntOp $1 $1 + 1  ; Odd NUL byte
              ${EndIf}

            ${EndIf}

          ${Next}

          IntOp $3 $1 + $2
          ${If} $3 > 0

            ; Odd NUL bytes proportion
            ; A perfect proportion would be, for example:
            ; > 256 (odd NUL bytes) * 200 = 51200 / 512 (total bytes)
            ; > 100% of the possible odd bytes are NUL
            IntOp $1 $1 * 200
            IntOp $1 $1 / $R1

            ; Even NUL bytes proportion
            IntOp $2 $2 * 200
            IntOp $2 $2 / $R1

            ; UTF-16LE (e.g. [0]: 0x48 [1]: 0x00)
            ${If} $1 > 65     ; > 65% odd NUL bytes
            ${AndIf} $2 < 15  ; < 15% even NUL bytes
              StrCpy $R2 "${AP_BFILE_ENC_UTF16_LE}"

            ; UTF-16BE (e.g. [0]: 0x00 [1]: 0x48)
            ${ElseIf} $1 < 15  ; < 15% odd NUL bytes
            ${AndIf} $2 > 65   ; > 65% even NUL bytes
              StrCpy $R2 "${AP_BFILE_ENC_UTF16_BE}"

            ${Else}
              ; No text encoding was detected and the bundle
              ; contains NUL bytes
              StrCpy $R2 "${AP_BFILE_ENC_INVALID}"

            ${EndIf}

          ${EndIf}

        ${EndIf}

      ${EndIf}

      FileSeek $0 0 SET
      System::Free $R0

      Push $R3  ; bytesBOM
      Push $R2  ; fileEnc

      System::Store L

    !macroend

    !define AP_BFILE_DETECT_ENC "!insertmacro __CALL_AP_BFILE_DETECT_ENC"

  ;--------------------------------
  ; AP_BFILE_UTF8_TO_16LE
  ; Convert the data from the current pointer position [1] of a
  ; UTF-8 encoded file to UTF-16LE [2] (Unicode in Windows). If the
  ; conversion fails, then an attempt will be made with the system
  ; ANSI code page (usually Windows-1252 for English and most
  ; European languages) as a last resort. In the stack, 1 is
  ; returned providing that the UTF-16LE file has been successfully
  ; created and 0 otherwise.
  ;
  ; [1] The FileSeek instruction can be previously used to ignore
  ;     any possible file BOM during the conversion.
  ; [2] Surrogate pairs are supported (two 16-bit code units),
  ;     such as U+01F309. But some characters may not be displayed
  ;     in the UI because no font includes them, like U+0104A2.
  ;
  ; - bFile: The file handle to convert.
  ; - outFname: The path and name of the UTF-16LE file to create.

    !macro __AP_MULTIBYTE_TO_WCHAR codePage inBuf outBuf wCharSize

      ; MB_ERR_INVALID_CHARS = 0x0008
      System::Call "kernel32::MultiByteToWideChar(i ${codePage}, i 0x0008, i ${inBuf}, i -1, i 0, i 0) i .s"
      Pop "${wCharSize}"

      ${If} ${wCharSize} > 0

        ; The buffer of Unicode characters (UTF-16LE) with the file contents
        System::Call "*(&w${wCharSize}) i .s"
        Pop "${outBuf}"

        ; Convert the string to UTF-16LE
        System::Call "kernel32::MultiByteToWideChar(i ${codePage}, i 0, i ${inBuf}, i -1, i ${outBuf}, i ${wCharSize})"

      ${EndIf}

    !macroend

    !define __AP_UTF8_TO_16LE "!insertmacro __AP_MULTIBYTE_TO_WCHAR ${AP_BFILE_CP_UTF8}"
    !define __AP_ANSI_TO_16LE "!insertmacro __AP_MULTIBYTE_TO_WCHAR ${AP_BFILE_CP_ACP}"

    !macro __CALL_AP_BFILE_UTF8_TO_16LE bFile outFname

      Push "${bFile}"
      Push "${outFname}"

      ${CallArtificialFunction} __AP_BFILE_UTF8_TO_16LE

    !macroend

    !macro __AP_BFILE_UTF8_TO_16LE

      ; outFname ($1) and bFile ($0)
      System::Store Sr1r0

      StrCpy $R0 0  ; The output buffer
      StrCpy $R1 0  ; No. of 16-bit code units in the buffer

      ; Get the size in bytes of the bundle file
      System::Call "kernel32::GetFileSizeEx(i r0, *l .R2) i .r2"

      ; Conversion to UTF-16LE
      ${If} $2 != 0
      ${AndIf} $R2 L<= ${AP_BFILE_MAX_BYTES}

        System::Call "*(&i$R2, i 0) i .r2"  ; Include null terminator
        System::Call "kernel32::ReadFile(i r0, i r2, i R2, *i .r3, i 0) i .r4"

        ${If} $4 != 0

          ${__AP_UTF8_TO_16LE} $2 $R0 $R1
          ${IfThen} $R1 == 0 ${|} ${__AP_ANSI_TO_16LE} $2 $R0 $R1 ${|}

        ${EndIf}

        System::Free $2

      ${EndIf}

      ; Create a file with the data converted to UTF-16LE
      StrCpy $R3 0  ; Status code
      ${If} $R0 != 0

        FileOpen $2 $1 w
        ${IfNot} ${Errors}

          ; UTF-16LE BOM
          FileWriteByte $2 0xFF
          FileWriteByte $2 0xFE
          ClearErrors

          ; 16-bit code units to bytes
          IntOp $R1 $R1 - 1
          IntOp $R1 $R1 * 2

          ; Write bytes to the file
          System::Call "kernel32::WriteFile(i r2, i R0, i R1, *i .r3, i 0) i .r4"
          ${IfThen} $4 != 0 ${|} StrCpy $R3 1 ${|}
          FileClose $2

        ${Else}
          ClearErrors
        ${EndIf}

        System::Free $R0

      ${EndIf}

      Push $R3
      System::Store L

    !macroend

    !define AP_BFILE_UTF8_TO_16LE "!insertmacro __CALL_AP_BFILE_UTF8_TO_16LE"

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

        ; Format the h:min:s.ms timestamp
        IntFmt $5 "%0.2d" $5
        IntFmt $6 "%0.2d" $6
        IntFmt $7 "%0.2d" $7
        IntFmt $8 "%0.3d" $8

        ; Write the message in the logfile
        StrCpy $1 "$1" 950  ; Limit the input message
        FileWriteUTF16LE $0 "$2-$3-$4 $5:$6:$7.$8 - $1$\n"

        ; Error handling
        IfErrors 0 +3
        FileClose $0
        StrCpy $0 ""

      ${EndIf}

      Push $0
      System::Store L

    !macroend

    !define AP_WRITE_BUNDLE_LOG "!insertmacro __CALL_AP_WRITE_BUNDLE_LOG"
