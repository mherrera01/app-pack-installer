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

      ; The back button performs the same operation as the leave
      ; function, due to the page disposal
      ${NSD_OnBack} confirmInstPageLeave

      ${NSD_CreateGroupBox} 0% 0% 100% 45% "Storage information"
      Pop $0

      ;--------------------------------
      ; Drive space UI

        ${NSD_CreateLabel} 3% 12% 20% 10u "HDD:"
        Pop $0

        ${NSD_CreateDropList} 3% 20% 20% 14u ""
        Pop $drivesDropListCIP
        ${NSD_OnChange} $drivesDropListCIP onChooseDriveCIP

        ; Set the number of items visible in the drop down list before
        ; showing a vertical scroll bar
        SendMessage $drivesDropListCIP ${CB_SETMINVISIBLE} 4 0

        ; Get all the hard disk drives of the computer
        StrCpy $nDrivesCIP 0
        StrCpy $firstDriveDetectedCIP ""
        ${GetDrives} "HDD" getDrivesInfoCIP

        System::Call "user32::LoadImage(i, t '$PLUGINSDIR\icons\disk-drive.ico', \
          i ${IMAGE_ICON}, i 28, i 28, i ${LR_LOADFROMFILE}) i .s"
        Pop $diskDriveIconCIP

        ${NSD_CreateIcon} 28% 7% 5% 10% ""
        Pop $diskDriveTypeCIP
        SendMessage $diskDriveTypeCIP ${STM_SETICON} $diskDriveIconCIP 0

        ${NSD_CreateLabel} 35% 12% 40% 12u ""
        Pop $totalSpaceInfoCIP

        ${NSD_CreateProgressBar} 28% 21% 69% 11u ""
        Pop $driveSpaceBarCIP

        ; The default visual styles of the progress bar must be disabled,
        ; so that the bar and background colors can be changed
        System::Call "uxtheme::SetWindowTheme(i $driveSpaceBarCIP, t '', t '')"
        SendMessage $driveSpaceBarCIP ${PBM_SETBARCOLOR} 0 0x00DAA026
        SendMessage $driveSpaceBarCIP ${PBM_SETBKCOLOR} 0 0x00FFFFFF

        ; Set the drive space range from 0 to 100 (percentage)
        SendMessage $driveSpaceBarCIP ${PBM_SETRANGE32} 0 100

        ${NSD_CreateLabel} 83% 12% 14% 12u ""
        Pop $usedSpacePctInfoCIP
        ${NSD_AddStyle} $usedSpacePctInfoCIP ${SS_RIGHT}

        ${NSD_CreateLabel} 28% 32% 13% 12u "Free space:"
        Pop $0

        ${NSD_CreateLabel} 42% 32% 32% 12u ""
        Pop $freeSpaceInfoCIP

        ; Select the first drive found in the drop down list
        SendMessage $drivesDropListCIP ${CB_SETCURSEL} 0 0
        Push $firstDriveDetectedCIP
        Call setDriveSpaceUICIP

      ${NSD_CreateLabel} 0% 48% 88% 20u "Note about disk space"
      Pop $driveSpaceInfoCIP

      System::Call "user32::LoadImage(i, t '$PLUGINSDIR\icons\important-note.ico', \
        i ${IMAGE_ICON}, i 28, i 28, i ${LR_LOADFROMFILE}) i .s"
      Pop $impNoteIconCIP

      ${NSD_CreateIcon} 90% 48% 5% 10% ""
      Pop $driveSpaceNoteCIP
      SendMessage $driveSpaceNoteCIP ${STM_SETICON} $impNoteIconCIP 0

      nsDialogs::Show

    FunctionEnd

    Function confirmInstPageLeave

      ; Free the icons loaded
      System::Call "user32::DestroyIcon(i $diskDriveIconCIP)"

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

      ; Shift the decimal point two places to the right
      System::Int64Op $0 * 100
      Pop $0
      System::Int64Op $0 / 1073741824
      Pop $0

      ; Get the integer part
      System::Int64Op $0 / 100
      Pop $1

      ; Get the decimal part
      System::Int64Op $0 % 100
      Pop $2

      StrCpy $0 "$1.$2 GB"
      Push $0

    FunctionEnd

    Function setDriveSpaceUICIP

      Pop $0

      ; Call directly the system function as the DriveSpace macro
      ; in the FileFunc header file does not consider the decimals.
      ; The values returned are large integers, so the math operations
      ; must be performed with Int64Op
      System::Call "kernel32::GetDiskFreeSpaceEx(t r0, *l .R0, *l .R1, *l) i .s"
      Pop $0

      ${If} $0 == 0

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

        ; Free bytes to GB
        Push $R0
        Call displayBytesCIP
        Pop $R0

        ; Total bytes to GB
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

!macroend
