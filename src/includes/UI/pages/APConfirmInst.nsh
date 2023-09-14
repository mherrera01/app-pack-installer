; File: APConfirmInst.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_CONFIRM_INST_PAGE

  ;--------------------------------
  ; CIP (Confirm Installation Page) variables

    Var dialogCIP

    Var nDrivesCIP
    Var firstDriveDetectedCIP
    Var drivesDropListCIP

    Var diskDriveIconCIP
    Var diskDriveTypeCIP
    Var driveSpaceBarCIP
    Var usedSpacePctInfoCIP
    Var freeSpaceInfoCIP
    Var totalSpaceInfoCIP

    Var impNoteIconCIP
    Var driveSpaceNoteCIP
    Var driveSpaceInfoCIP

    Var instTypeCheckCIP
    Var instTypeCheckStateCIP
    Var instTypeInfoCIP
    Var infoBoxIconCIP
    Var silentModeBoxCIP
    Var silentModeInfoCIP
    Var silentModeLinkButtonCIP

  ;--------------------------------
  ; Main functions triggered on custom page creation and disposal

    Function confirmInstPage

      !insertmacro MUI_HEADER_TEXT "Confirm Installation" "Confirm the \
        installation of the apps selected."

      ; As it is the last page before MUI_PAGE_INSTFILES, the next
      ; button text is automatically changed to 'Install'
      nsDialogs::Create 1018
      Pop $dialogCIP

      ${If} $dialogCIP == "error"
        Call .onGuIEnd
        Quit
      ${EndIf}

      ; Clear the error flag as it is set by the nsArray functions
      ClearErrors

      ; The back button performs the same operation as the leave
      ; function, due to the page disposal
      ${NSD_OnBack} confirmInstPageLeave

      ${NSD_CreateGroupBox} 0% 0% 100% 42% "Storage information"
      Pop $0

      ;--------------------------------
      ; Drive space UI

        ${NSD_CreateLabel} 3% 12% 20% 10u "HDD:"
        Pop $0

        ${NSD_CreateDropList} 3% 20% 20% 0u ""
        Pop $drivesDropListCIP
        ${NSD_OnChange} $drivesDropListCIP onChooseDriveCIP

        ; Set the number of items visible in the drop down list before
        ; showing a vertical scroll bar
        SendMessage $drivesDropListCIP ${CB_SETMINVISIBLE} 4 0

        ; Get all the hard disk drives of the computer
        StrCpy $nDrivesCIP 0
        StrCpy $firstDriveDetectedCIP ""
        ${GetDrives} "HDD" getDrivesInfoCIP

        ; Initialize an array to store the bytes conversion parameters
        nsArray::SetList bytesConversionArray \
          /key=KB 1024 /key=MB 1048576 /key=GB 1073741824 /key=TB 1099511627776 /end

        ${AP_CREATE_ICON_UI_ELEM} 28% 6% 5% 10% 0 "disk-drive.ico" 28 $diskDriveIconCIP
        Pop $diskDriveTypeCIP

        ${NSD_CreateLabel} 35% 11% 40% 12u ""
        Pop $totalSpaceInfoCIP

        ${NSD_CreateProgressBar} 28% 20% 69% 8% ""
        Pop $driveSpaceBarCIP

        ; The default visual styles of the progress bar must be disabled,
        ; so that the bar and background colors can be changed
        System::Call "uxtheme::SetWindowTheme(i $driveSpaceBarCIP, t '', t '')"
        SendMessage $driveSpaceBarCIP ${PBM_SETBARCOLOR} 0 0x00DAA026
        SendMessage $driveSpaceBarCIP ${PBM_SETBKCOLOR} 0 0x00FFFFFF

        ; Set the drive space range from 0 to 100 (percentage)
        SendMessage $driveSpaceBarCIP ${PBM_SETRANGE32} 0 100

        ${NSD_CreateLabel} 83% 11% 14% 12u ""
        Pop $usedSpacePctInfoCIP
        ${NSD_AddStyle} $usedSpacePctInfoCIP ${SS_RIGHT}

        ${NSD_CreateLabel} 28% 31% 13% 12u "Free space:"
        Pop $0

        ${NSD_CreateLabel} 42% 31% 33% 12u ""
        Pop $freeSpaceInfoCIP

        ; Select the first drive found in the drop down list
        SendMessage $drivesDropListCIP ${CB_SETCURSEL} 0 0
        Push $firstDriveDetectedCIP
        Call setDriveSpaceUICIP

      ${NSD_CreateLabel} 2% 48% 86% 20u "AppPack cannot verify how much \
        drive space each application requires, so make sure there is enough \
        storage for all of them."
      Pop $driveSpaceInfoCIP

      ${AP_CREATE_ICON_UI_ELEM} 91% 47% 5% 10% 0 "important-note.ico" 28 $impNoteIconCIP
      Pop $driveSpaceNoteCIP

      ${NSD_CreateHLine} 0% 65% 100% 0u ""
      Pop $0

      ;--------------------------------
      ; Installation type UI

        ${NSD_CreateCheckBox} 2% 70% 4% 6% ""
        Pop $instTypeCheckCIP
        ${NSD_OnClick} $instTypeCheckCIP onInstTypeClickCIP

        ${NSD_CreateLabel} 7% 70% 93% 12u "Enable silent mode to install \
          the apps without any user interaction"
        Pop $instTypeInfoCIP

        ${AP_CREATE_ICON_UI_ELEM} 1% 82% 5% 10% 0 "info-box.ico" 28 $infoBoxIconCIP
        Pop $silentModeBoxCIP

        ${NSD_CreateLabel} 10% 82% 70% 20u "Some applications may not support \
          silent mode, in which case manual intervention will be required."
        Pop $silentModeInfoCIP

        ${NSD_CreateButton} 80% 83% 18% 12u "More info"
        Pop $silentModeLinkButtonCIP
        ${NSD_OnClick} $silentModeLinkButtonCIP onSilentModeMoreInfoCIP

      nsDialogs::Show

    FunctionEnd

    Function confirmInstPageLeave

      ; Clear the bytes conversion array
      nsArray::Clear bytesConversionArray

      ; Free the icons loaded
      System::Call "user32::DestroyIcon(i $diskDriveIconCIP)"
      System::Call "user32::DestroyIcon(i $impNoteIconCIP)"
      System::Call "user32::DestroyIcon(i $infoBoxIconCIP)"

    FunctionEnd

  ;--------------------------------
  ; Helper functions

    Function getDrivesInfoCIP

      ; Add the drive letter to the drop list
      ${NSD_CB_AddString} $drivesDropListCIP "$9"

      ${If} $nDrivesCIP == 0
        StrCpy $firstDriveDetectedCIP "$9"
      ${EndIf}

      ; Increase the number of drives detected
      IntOp $nDrivesCIP $nDrivesCIP + 1
	    Push $0

    FunctionEnd

    Function displayBytesCIP

      Pop $0

      ; Set a limit. No more than 1000 TB will be shown.
      ${If} $0 L> 1099511627776000
        Push "> 1000 TB"
        Return
      ${EndIf}

      ; Get the unit conversion for the bytes to display
      ${ForEachIn} bytesConversionArray $1 $2

        System::Int64Op $2 * 1000
        Pop $3

        ${If} $0 L< $3
          ${ExitFor}
        ${EndIf}

      ${Next}

      ; Shift the decimal point two places to the right
      System::Int64Op $0 * 100
      Pop $0
      System::Int64Op $0 / $2
      Pop $0

      ; Add leading zeros if needed
      StrLen $2 $0
      ${DoUntil} $2 > 2
        StrCpy $0 "0$0"
        IntOp $2 $2 + 1
      ${Loop}

      ; Get the integer and decimal parts
      StrCpy $3 $0 -2
      StrCpy $4 $0 "" -2

      Push "$3.$4 $1"

    FunctionEnd

    Function setDriveSpaceUICIP

      Pop $0

      ; Call directly the system function as the DriveSpace macro
      ; in the FileFunc header file does not consider the decimals.
      ; The values returned are 64-bit integers, so the math
      ; operations must be performed with Int64Op (System.dll):
      ; a L= b; a L<> b; a L< b; a L>= b; a L> b; a L<= b
      System::Call "kernel32::GetDiskFreeSpaceEx(t r0, *l .R0, *l .R1, *l) i .s"
      Pop $0

      ; If GetDiskFreeSpaceEx fails, the return value is 0
      ${If} $0 = 0

      ; Int64Op handles signed integers, and hence, the most
      ; significant bit is used. The bytes from GetDiskFreeSpaceEx
      ; (unsigned) could be considered as a negative number.
      ${OrIf} $R1 L< 0

        ; Set the error state in the drive space UI
        StrCpy $R0 "???"
        StrCpy $R1 "???"
        StrCpy $R2 0

      ${Else}

        ; Occupied space
        System::Int64Op $R1 - $R0
        Pop $0

        ; Occupied space in percentage
        System::Int64Op $0 * 100
        Pop $0
        System::Int64Op $0 / $R1
        Pop $R2

        ; Free bytes conversion
        Push $R0
        Call displayBytesCIP
        Pop $R0

        ; Total bytes conversion
        Push $R1
        Call displayBytesCIP
        Pop $R1

      ${EndIf}

      ; Set the percentage of the occupied drive space
      SendMessage $driveSpaceBarCIP ${PBM_SETPOS} $R2 0
      ${NSD_SetText} $usedSpacePctInfoCIP "$R2%"

      ; Edit the free/total space labels
      ${NSD_SetText} $freeSpaceInfoCIP "$R0"
      ${NSD_SetText} $totalSpaceInfoCIP "$R1"

    FunctionEnd

  ;--------------------------------
  ; Event functions

    Function onChooseDriveCIP

      ; Get the handler of the item selected in the drop down list
      Pop $0

      ; Display the space info of the drive chosen
      ${NSD_GetText} $0 $1
      Push $1
      Call setDriveSpaceUICIP

    FunctionEnd

    Function onInstTypeClickCIP

      ; Empty the stack and store the checkbox state
      Pop $0
      ${NSD_GetState} $instTypeCheckCIP $instTypeCheckStateCIP

    FunctionEnd

    Function onSilentModeMoreInfoCIP

      ; Open a URL in a browser to provide more info about
      ; the silent mode
      ExecShell "open" "${SILENT_MODE_README_LINK}"

    FunctionEnd

!macroend
