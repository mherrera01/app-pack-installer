; File: APConfirmInst.nsh
; Author: Miguel Herrera

!macro AP_DEFINE_UI_CONFIRM_INST_PAGE

  ;--------------------------------
  ; CIP (Confirm Installation Page) variables

    Var dialogCIP

    Var nDrivesCIP
    Var firstDriveDetectedCIP
    Var drivesDropListCIP

    Var driveSpaceBarCIP
    Var freeSpaceInfoCIP
    Var totalSpaceInfoCIP

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

      ${NSD_CreateDropList} 0% 0% 20% 14u ""
      Pop $drivesDropListCIP
      ${NSD_OnChange} $drivesDropListCIP onChooseDriveCIP

      ; Set the number of items visible in the drop down list before
      ; showing a vertical scroll bar
      SendMessage $drivesDropListCIP ${CB_SETMINVISIBLE} 5 0

      ; Get all the hard disk drives of the computer
      StrCpy $nDrivesCIP 0
      StrCpy $firstDriveDetectedCIP ""
      ${GetDrives} "HDD" getDrivesInfoCIP

      ${NSD_CreateProgressBar} 25% 0% 74% 14u ""
      Pop $driveSpaceBarCIP

      ; The default visual styles of the progress bar must be disabled,
      ; so that the bar and background colors can be changed
      System::Call "uxtheme::SetWindowTheme(i $driveSpaceBarCIP, t '', t '')"
      SendMessage $driveSpaceBarCIP ${PBM_SETBARCOLOR} 0 0x00C77E35
      SendMessage $driveSpaceBarCIP ${PBM_SETBKCOLOR} 0 0x00FFFFFF

      ; Set the drive space range from 0 to 100 (percentage)
      SendMessage $driveSpaceBarCIP ${PBM_SETRANGE32} 0 100

      ${NSD_CreateLabel} 25% 15% 75% 20u "Free space:"
      Pop $0

      ${NSD_CreateLabel} 40% 15% 65% 20u ""
      Pop $freeSpaceInfoCIP

      ${NSD_CreateLabel} 25% 25% 75% 20u "Total space:"
      Pop $0

      ${NSD_CreateLabel} 40% 25% 65% 20u ""
      Pop $totalSpaceInfoCIP

      ; Select the first drive found in the drop down list
      SendMessage $drivesDropListCIP ${CB_SETCURSEL} 0 0
      Push $firstDriveDetectedCIP
      Call setDriveSpaceUICIP

      nsDialogs::Show

    FunctionEnd

    Function confirmInstPageLeave

      ; Free the memory allocated for the drives space info
      ${ForEachIn} drivesSpaceInfo $0 $1
        System::Free $1
      ${Next}

      ; Clears the array
      nsArray::Clear drivesSpaceInfo

    FunctionEnd

  ;--------------------------------
  ; Helper functions

    Function getDrivesInfoCIP

      ${DriveSpace} "$9" "/D=F /S=G" $R0
      ${If} ${Errors}
        ClearErrors
        Return
      ${EndIf}

      ; TODO: DriveSpace does not consider the decimals
      ; https://stackoverflow.com/questions/76249777/nsis-round-disk-size-to-nearest-decimal-place
      ${DriveSpace} "$9" "/D=T /S=G" $R1
      ${If} ${Errors}
        ClearErrors
        Return
      ${EndIf}

      IntOp $R2 $R1 - $R0
      IntOp $R2 $R2 * 100
      IntOp $R2 $R2 / $R1

      StrCpy $R0 "$R0.00 GB"
      StrCpy $R1 "$R1.00 GB"

      ; Allocate a buffer to store the occupied, free and total drive space:
      ; - occupiedSpace is a percentage value
      ; - freeSpace and totalSpace are text values representing a number of
      ; two decimals
      System::Call "*(i R2, t R0, t R1) i .R3"
      nsArray::Set drivesSpaceInfo /key=$9 "$R3"

      ; Add the drive letter to the drop list
      ${NSD_CB_AddString} $drivesDropListCIP "$9"

      ${If} $nDrivesCIP == 0
        StrCpy $firstDriveDetectedCIP "$9"
      ${EndIf}

      IntOp $nDrivesCIP $nDrivesCIP + 1
	    Push $0

    FunctionEnd

    Function setDriveSpaceUICIP

      Pop $0

      ; Get the space info
      nsArray::Get drivesSpaceInfo $0
      Pop $1

      ${If} ${Errors}

        ; Set the error state in the drive space UI
        ClearErrors
        StrCpy $R0 0
        StrCpy $R1 "???"
        StrCpy $R2 "???"

      ${Else}
        System::Call "*$1(i .R0, t .R1, t .R2)"
      ${EndIf}

      ; Set the percentage of the occupied drive space
      SendMessage $driveSpaceBarCIP ${PBM_SETPOS} $R0 0

      ; Edit the free/total space labels
      ${NSD_SetText} $freeSpaceInfoCIP "$R1"
      ${NSD_SetText} $totalSpaceInfoCIP "$R2"

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
