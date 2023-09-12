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
!define TVS_INFOTIP         0x0800
!define TVS_FULLROWSELECT   0x1000

; Messages
!define TVM_INSERTITEM   0x1132 ; 0X1100 for ASCII
!define TVM_EXPAND       0x1102
!define TVM_GETCOUNT     0x1105
!define TVM_SELECTITEM   0x110B
!define TVM_SETITEM      0x113F ; 0x110D for ASCII
!define TVM_GETITEM      0x113E ; 0x110C for ASCII
!define TVM_GETITEMSTATE 0x1127

; Notifications
!define NM_TVSTATEIMAGECHANGING -24
!define TVN_GETINFOTIP          -414 ; -413 for ASCII
!define TVN_SELCHANGED          -451 ; -402 for ASCII

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

; Item states (state and stateMask parameters of the TVITEM structure)
!define TVIS_SELECTED       0x0002
!define TVIS_BOLD           0x0010
!define TVIS_EXPANDED       0x0020
!define TVIS_OVERLAYMASK    0x0F00
!define TVIS_UNCHECKED      0x1000
!define TVIS_CHECKED        0x2000
!define TVIS_STATEIMAGEMASK 0xF000

!define TVGN_ROOT            0x0000
!define TVGN_NEXT            0x0001
!define TVGN_PREVIOUS        0x0002
!define TVGN_PARENT          0x0003
!define TVGN_CHILD           0x0004
!define TVGN_FIRSTVISIBLE    0x0005
!define TVGN_NEXTVISIBLE     0x0006
!define TVGN_PREVIOUSVISIBLE 0x0007
!define TVGN_DROPHILITE      0x0008
!define TVGN_CARET           0x0009

;--------------------------------
; Interface

  !define __TVI_MAX_TEXT 48
  !define /math __TVI_MAX_TEXT_NT ${__TVI_MAX_TEXT} + 1

  !define __TV_CLASS SysTreeView32
  !define __TV_DEF_STYLES ${WS_CHILD}|${WS_VISIBLE}|${WS_BORDER}|${WS_TABSTOP}|${WS_CLIPSIBLINGS}|\
    ${TVS_HASBUTTONS}|${TVS_HASLINES}|${TVS_LINESATROOT}|${TVS_DISABLEDRAGDROP}|${TVS_INFOTIP}
  !define __TV_DEF_EXSTYLES 0

  ;--------------------------------
  ; TV_CREATE
  ; Create a tree view control with some default styles.

    !define TV_CREATE "nsDialogs::CreateControl ${__TV_CLASS} ${__TV_DEF_STYLES} ${__TV_DEF_EXSTYLES}"

  ;--------------------------------
  ; TV_INSERT_ITEM
  ; The handle of the item inserted is returned in the stack.

    !macro __CALL_TV_INSERT_ITEM hwndTV parentItem name lparam

      Push "${hwndTV}"
      Push "${parentItem}"
      Push "${name}"
      Push "${lparam}"

      ${CallArtificialFunction} __TV_INSERT_ITEM

    !macroend

    !macro __TV_INSERT_ITEM

      ; It is first stored the $0-$9 and $R0-$R9 registers to the System's
      ; private stack, so that the original data is not overriden.
      ; Then, the arguments are popped from the global stack, which are
      ; lparam ($3), name ($2), parentItem ($1) and hwndTV ($0).
      System::Store Sr3r2r1r0

      ; Set the maximum length of the item name
      StrCpy $2 $2 ${__TVI_MAX_TEXT}

      ; Allocate a TVINSERTSTRUCT structure which contains info for inserting a
      ; new item to the TV. The TVITEM parameter is required to specify the
      ; attributes of the TV item to add. As only the flags TVIF_TEXT and
      ; TVIF_PARAM are specified, just the pszText, cchTextMax and lParam members
      ; must be set in the structure.
      System::Call "*(i r1, i ${TVI_SORT}, i ${TVIF_TEXT}|${TVIF_PARAM}, i, i, i, t r2, i ${__TVI_MAX_TEXT_NT}, i, i, i, i r3) i .R0"

      ; Insert a new item to the tree view and push the handle
      SendMessage $0 ${TVM_INSERTITEM} 0 $R0 $4
      Push $4

      ; Free the TVINSERTSTRUCT structure allocated
      System::Free $R0

      ; Restore the original values of the registers
      System::Store L

    !macroend

    !define TV_INSERT_ITEM "!insertmacro __CALL_TV_INSERT_ITEM"

  ;--------------------------------
  ; TV_GET_ITEM_TEXT
  ; The text of the item handle given is returned in the stack.

    !macro __CALL_TV_GET_ITEM_TEXT hwndTV item

      Push "${hwndTV}"
      Push "${item}"

      ${CallArtificialFunction} __TV_GET_ITEM_TEXT

    !macroend

    !macro __TV_GET_ITEM_TEXT

      ; item ($1) and hwndTV ($0)
      System::Store Sr1r0

      ; Allocate a buffer to store the item text
      System::Call "*(&t${__TVI_MAX_TEXT_NT}) i .R0"

      ; A TVITEM structure where the item handle is specified
      System::Call "*(i ${TVIF_TEXT}|${TVIF_HANDLE}, i r1, i, i, i R0, i ${__TVI_MAX_TEXT_NT}, i, i, i, i) i .R1"

      ; Send the TVM_GETITEM message to get the pszText parameter
      SendMessage $0 ${TVM_GETITEM} 0 $R1
      System::Free $R1

      ; Copy the contents of the string to the stack
      System::Call "kernel32::lstrcpy(t .s, i R0)"
      System::Free $R0

      ; Restore the original values of the registers
      System::Store L

    !macroend

    !define TV_GET_ITEM_TEXT "!insertmacro __CALL_TV_GET_ITEM_TEXT"

  ;--------------------------------
  ; TV_SELECT_ITEM

    !macro __CALL_TV_SELECT_ITEM hwndTV item

      Push "${hwndTV}"
      Push "${item}"

      ${CallArtificialFunction} __TV_SELECT_ITEM

    !macroend

    !macro __TV_SELECT_ITEM

      ; item ($1) and hwndTV ($0)
      System::Store Sr1r0

      SendMessage $0 ${TVM_SELECTITEM} ${TVGN_CARET} $1

      ; Restore the original values of the registers
      System::Store L

    !macroend

    !define TV_SELECT_ITEM "!insertmacro __CALL_TV_SELECT_ITEM"

  ;--------------------------------
  ; TV_SET_ITEM_CHECK

    !macro __CALL_TV_SET_ITEM_CHECK hwndTV item checkState

      Push "${hwndTV}"
      Push "${item}"
      Push "${checkState}"

      ${CallArtificialFunction} __TV_SET_ITEM_CHECK

    !macroend

    !macro __TV_SET_ITEM_CHECK

      ; checkState ($2), item ($1) and hwndTV ($0)
      System::Store Sr2r1r0

      ; A TVITEM structure where the item handle is specified
      System::Call "*(i ${TVIF_STATE}|${TVIF_HANDLE}, i r1, i r2, i ${TVIS_STATEIMAGEMASK}, t, i, i, i, i, i) i .R0"

      ; Set the new check state to the item
      SendMessage $0 ${TVM_SETITEM} 0 $R0
      System::Free $R0

      ; Restore the original values of the registers
      System::Store L

    !macroend

    !define TV_SET_ITEM_CHECK "!insertmacro __CALL_TV_SET_ITEM_CHECK"

  ;--------------------------------
  ; TV_GET_COUNT
  ; The number of tree view items is returned in the stack.

    !macro __CALL_TV_GET_COUNT hwndTV

      Push "${hwndTV}"

      ${CallArtificialFunction} __TV_GET_COUNT

    !macroend

    !macro __TV_GET_COUNT

      ; hwndTV ($0)
      System::Store Sr0

      ; Count of the items in the tree view control
      SendMessage $0 ${TVM_GETCOUNT} 0 0 $1
      Push $1

      ; Restore the original values of the registers
      System::Store L

    !macroend

    !define TV_GET_COUNT "!insertmacro __CALL_TV_GET_COUNT"
