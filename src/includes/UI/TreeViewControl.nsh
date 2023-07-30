; File: TreeViewControl.nsh
; Author: Miguel Herrera

; UI support for the Win32 tree view. Commctrl.h header documentation:
; https://learn.microsoft.com/en-us/windows/win32/controls/tree-view-control-reference

; Styles
!define TVS_HASBUTTONS      0x0001
!define TVS_HASLINES        0x0002
!define TVS_LINESATROOT     0x0004
!define TVS_DISABLEDRAGDROP 0x0010
!define TVS_CHECKBOXES      0x0100

; Messages
!define TVM_INSERTITEM   0x1132 ; 0X1100 for ASCII
!define TVM_DELETEITEM   0x1101
!define TVM_EXPAND       0x1102
!define TVM_GETCOUNT     0x1105
!define TVM_SELECTITEM   0x110B
!define TVM_GETITEM      0x113E ; 0x110C for ASCII
!define TVM_GETITEMSTATE 0x1127

; Insert item types (TVINSERTSTRUCT)
!define TVI_ROOT  0xFFFF0000 ; As a root item
!define TVI_FIRST 0xFFFF0001 ; At the beginning of the list
!define TVI_LAST  0xFFFF0002 ; At the end of the list
!define TVI_SORT  0xFFFF0003 ; In alphabetical order

; Item flags that indicate the members of the TVITEM structure with valid data
!define TVIF_TEXT          0x0001 ; pszText and cchTextMax
!define TVIF_IMAGE         0x0002 ; iImage
!define TVIF_PARAM         0x0004 ; lParam
!define TVIF_STATE         0x0008 ; state and stateMask
!define TVIF_HANDLE        0x0010 ; hItem
!define TVIF_SELECTEDIMAGE 0x0020 ; iSelectedImage
!define TVIF_CHILDREN      0x0040 ; cChildren

;--------------------------------
; Interface

  !define __TVI_MAX_TEXT 128

  !define __TV_CLASS SysTreeView32
  !define __TV_DEF_STYLES ${WS_CHILD}|${WS_VISIBLE}|${WS_BORDER}|${WS_TABSTOP}|\
    ${TVS_HASBUTTONS}|${TVS_HASLINES}|${TVS_LINESATROOT}|${TVS_CHECKBOXES}|${TVS_DISABLEDRAGDROP}
  !define __TV_DEF_EXSTYLES 0

  ;--------------------------------
  ; TV_CREATE
  ; Create a tree view control with some default styles

    !define TV_CREATE "nsDialogs::CreateControl ${__TV_CLASS} ${__TV_DEF_STYLES} ${__TV_DEF_EXSTYLES}"

  ;--------------------------------
  ; TV_INSERT_ITEM

    !macro __TV_INSERT_ITEM hwndTV pszText

      StrCpy $0 "${pszText}" ${__TVI_MAX_TEXT}

      ; Allocate a TVINSERTSTRUCT structure which contains info for inserting a
      ; new item to the TV. The TVITEM parameter is required to specify the
      ; attributes of the TV item to add. As only the flag TVIF_TEXT is specified,
      ; just the pszText and cchTextMax members must be set in the structure.
      System::Call "*(i ${TVI_ROOT}, i ${TVI_SORT}, i ${TVIF_TEXT}, i, i, i, t r0, i ${__TVI_MAX_TEXT}, i, i, i, i) i .R0"

      ; Insert a new item to the tree view
      SendMessage ${hwndTV} ${TVM_INSERTITEM} 0 $R0 $0

      ; Free the TVINSERTSTRUCT structure allocated
      System::Free $R0

    !macroend

    !define TV_INSERT_ITEM "!insertmacro __TV_INSERT_ITEM"
