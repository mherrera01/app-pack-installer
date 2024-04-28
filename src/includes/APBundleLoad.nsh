; File: APBundleLoad.nsh
; Author: Miguel Herrera

;--------------------------------
; Bundle Data

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

  ; File encodings
  !define AP_BFILE_ENC_UTF32_LE "UTF-32LE"
  !define AP_BFILE_ENC_UTF32_BE "UTF-32BE"
  !define AP_BFILE_ENC_UTF16_LE "UTF-16LE"
  !define AP_BFILE_ENC_UTF16_BE "UTF-16BE"
  !define AP_BFILE_ENC_UTF8     "UTF-8"

  ; Code pages
  !define AP_BFILE_CP_ACP  0
  !define AP_BFILE_CP_UTF8 65001

  ;--------------------------------
  ; AP_SKIP_BFILE_BOM
  ; Set the file pointer position just behind the BOM of the
  ; different encodings: UTF-32 LE/BE, UTF-16 LE/BE, UTF-8.
  ; If none is detected, then the pointer is kept at the
  ; beggining of the file.
  ;
  ; - fp: The bundle file.
  ; - fileEnc [out]: The encoding detected by the BOM.
  ; - bytesBOM [out]: The number of bytes skipped.

    !macro __CALL_AP_SKIP_BFILE_BOM fp fileEnc bytesBOM

      Push "${fp}"

      ${CallArtificialFunction} __AP_SKIP_BFILE_BOM
      Pop "${fileEnc}"
      Pop "${bytesBOM}"

    !macroend

    !macro __AP_SKIP_BFILE_BOM

      ; fp ($0)
      System::Store Sr0

      ; Read 4 bytes for checking the byte order mark (BOM) 
      System::Call "*(&i4) i .R0"
      System::Call "kernel32::ReadFile(i r0, i R0, i 4, *i .R1, i 0) i .r1"

      StrCpy $R2 ""
      StrCpy $R3 0

      ${If} $1 != 0

        ; Detect the file encoding with the BOM
        System::Call "*$R0(b .r1, b .r2, b .r3, b .r4)"

        ${Switch} $R1

          ${Case} 4

            ; UTF-32LE
            ${If} $1 = 0xFF
            ${AndIf} $2 = 0xFE
            ${AndIf} $3 = 0
            ${AndIf} $4 = 0
              StrCpy $R2 "${AP_BFILE_ENC_UTF32_LE}"
              StrCpy $R3 4
              ${Break}

            ; UTF-32BE
            ${ElseIf} $1 = 0
            ${AndIf} $2 = 0
            ${AndIf} $3 = 0xFE
            ${AndIf} $4 = 0xFF
              StrCpy $R2 "${AP_BFILE_ENC_UTF32_BE}"
              StrCpy $R3 4
              ${Break}
            ${EndIf}

          ${Case} 3

            ; UTF-8
            ${If} $1 = 0xEF
            ${AndIf} $2 = 0xBB
            ${AndIf} $3 = 0xBF
              StrCpy $R2 "${AP_BFILE_ENC_UTF8}"
              StrCpy $R3 3
              ${Break}
            ${EndIf}

          ${Case} 2

            ; UTF-16LE
            ${If} $1 = 0xFF
            ${AndIf} $2 = 0xFE
              StrCpy $R2 "${AP_BFILE_ENC_UTF16_LE}"
              StrCpy $R3 2
              ${Break}

            ; UTF-16BE
            ${ElseIf} $1 = 0xFE
            ${AndIf} $2 = 0xFF
              StrCpy $R2 "${AP_BFILE_ENC_UTF16_BE}"
              StrCpy $R3 2
              ${Break}
            ${EndIf}

        ${EndSwitch}

      ${EndIf}

      FileSeek $0 $R3 SET
      System::Free $R0

      Push $R3
      Push $R2

      System::Store L

    !macroend

    !define AP_SKIP_BFILE_BOM "!insertmacro __CALL_AP_SKIP_BFILE_BOM"

  ;--------------------------------
  ; AP_BFILE_TO_UNICODE
  ; Convert the bundle file to the UTF-16LE encoding (Unicode for
  ; Windows). If no character set is specified, then it will be
  ; assumed that the file is UTF-8 or ANSI (Windows Code Pages).
  ; In the stack, the output buffer size is returned, which
  ; corresponds to the number of 16-bit code units including the
  ; null terminator.
  ;
  ; * Note: Surrogate pairs are supported (two 16-bit code units),
  ;   such as U+01F309. But some characters may not be displayed
  ;   in the UI because no font includes them, like U+0104A2.
  ;
  ; - bFile: The file to convert.
  ; - fileEnc: The encoding of the bundle file (empty for default).
  ; - convBuf [out]: The buffer with the data converted to UTF-16LE.

    !macro __AP_MULTIBYTE_TO_WCHAR codePage inBuf outBuf wCharSize

      System::Call "kernel32::MultiByteToWideChar(i ${codePage}, i 0, i ${inBuf}, i -1, i 0, i 0) i .s"
      Pop "${wCharSize}"
      ; MessageBox MB_OK "${wCharSize}"

      ${If} ${wCharSize} > 0

        ; The buffer of Unicode characters (UTF-16LE) with the file contents
        System::Call "*(&w${wCharSize}) i .s"
        Pop "${outBuf}"

        ; Convert the string to UTF-16LE
        System::Call "kernel32::MultiByteToWideChar(i ${codePage}, i 0, i ${inBuf}, i -1, i ${outBuf}, i ${wCharSize})"

      ${EndIf}

    !macroend

    !define __AP_UTF8_TO_UNICODE "!insertmacro __AP_MULTIBYTE_TO_WCHAR ${AP_BFILE_CP_UTF8}"
    !define __AP_ANSI_TO_UNICODE "!insertmacro __AP_MULTIBYTE_TO_WCHAR ${AP_BFILE_CP_ACP}"

    !macro __CALL_AP_BFILE_TO_UNICODE bFile fileEnc convBuf

      Push "${bFile}"
      Push "${fileEnc}"

      ${CallArtificialFunction} __AP_BFILE_TO_UNICODE
      Pop "${convBuf}"

    !macroend

    !macro __AP_BFILE_TO_UNICODE

      ; fileEnc ($1) and bFile ($0)
      System::Store Sr1r0

      StrCpy $R0 0  ; The output buffer
      StrCpy $R1 0  ; No. of 16-bit code units in the buffer

      ; Get the size in bytes of the bundle file
      System::Call "kernel32::GetFileSizeEx(i r0, *l .R2) i .r2"

      ${If} $2 != 0
      ${AndIf} $R2 L<= ${AP_BFILE_MAX_BYTES}

        System::Call "*(&i$R2, i 0) i .R3"  ; Include null terminator
        System::Call "kernel32::ReadFile(i r0, i R3, i R2, *i .r2, i 0) i .r3"

        ${If} $3 != 0

          ${Select} $1

            ${Case} "${AP_BFILE_ENC_UTF16_BE}"

              IntOp $R1 $2 / 2
              IntOp $R1 $R1 + 1
              System::Call "*(&w$R1) i .R0"

              ; Swap the 2-byte pairs
              IntOp $2 $2 - 2
              ${ForEach} $3 0 $2 + 2

                System::Call "*$R3(&i$3, &i1 .r4, &i1 .r5)"
                System::Call "*$R0(&i$3, &i1 r5, &i1 r4)"

              ${Next}

            ${Case} "${AP_BFILE_ENC_UTF8}"
              ${__AP_UTF8_TO_UNICODE} $R3 $R0 $R1

            ${Case} ""
              ${__AP_UTF8_TO_UNICODE} $R3 $R0 $R1
              ${IfThen} $R1 == 0 ${|} ${__AP_ANSI_TO_UNICODE} $R3 $R0 $R1 ${|}

          ${EndSelect}

        ${EndIf}

        System::Free $R3

      ${EndIf}

      Push $R1
      Push $R0
      System::Store L

    !macroend

    !define AP_BFILE_TO_UNICODE "!insertmacro __CALL_AP_BFILE_TO_UNICODE"

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
