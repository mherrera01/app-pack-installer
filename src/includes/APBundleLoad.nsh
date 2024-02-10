; File: APBundleLoad.nsh
; Author: Miguel Herrera

;--------------------------------
; Bundle Data

  ; Item type: int {0: appGroup, 1: app}
  ; Name: string
  ; Description: string
  ; Selected: int {0: false, 1: true}
  !macro __AP_BITEM_DATA iType iParams name
    System::Call "*(i ${iType}, t '${name}', t '', i 0, ${iParams}) i .s"
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

    ;--------------------------------
    ; AP_BITEM_GET_INFOTIP

    !macro __CALL_AP_BITEM_GET_INFOTIP iData outVar

        Push "${iData}"

        ${CallArtificialFunction} __AP_BITEM_GET_INFOTIP
        Pop "${outVar}"

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
  ; AP_SET_BITEM_PROP

    !macro __AP_CHECK_PROP type prop key setData
      ${${type}} "${prop}" == "${key}"
        System::Call "${setData}"
    !macroend
    !define __AP_IF_PROP "!insertmacro __AP_CHECK_PROP If"
    !define __AP_ELSE_IF_PROP "!insertmacro __AP_CHECK_PROP ElseIf"

    !macro AP_SET_BITEM_PROP iType iData key value

      Push "${iData}"
      Push "${key}"
      Push "${value}"

      ${CallArtificialFunction} __AP_SET_${iType}_PROP

    !macroend

    !macro __AP_SET_AGRP_PROP

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

    !macro __AP_SET_APP_PROP

      ; value ($2), key ($1) and iData ($0)
      System::Store Sr2r1r0

      StrCpy $3 "[OK] App property '$1' with the value: $2"

      ${__AP_IF_PROP} $1 "description" "*$0(i, t, t r2, i, t)"
      ${__AP_ELSE_IF_PROP} $1 "setupURL" "*$0(i, t, t, i, t r2)"
      ${Else}
        StrCpy $3 "[WARNING] Ignoring property '$1'. Only the description \
          and setupURL keys are allowed when defining an app"
      ${EndIf}

      Push $3
      System::Store L

    !macroend

    !define AP_SET_AGRP_PROP "!insertmacro AP_SET_BITEM_PROP AGRP"
    !define AP_SET_APP_PROP "!insertmacro AP_SET_BITEM_PROP APP"

;--------------------------------
; Bundle Load Helpers

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
        IfErrors 0 +2
        StrCpy $0 ""

      ${EndIf}

      Push $0
      System::Store L

    !macroend

    !define AP_WRITE_BUNDLE_LOG "!insertmacro __CALL_AP_WRITE_BUNDLE_LOG"
