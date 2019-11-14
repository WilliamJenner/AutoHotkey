; ORIGINAL https://gist.github.com/obnoxint/84e86d08e1c01572c8ab
; Microsoft Natural Keyboard 4000
; based on code by users of this discussion:
; https://autohotkey.com/board/topic/36304-hidextended-input-devices-ms-natural-keyboard-4000-etc/

; The HID top level collection for the Natural Keyboard 4000 is:
;   Usage         1
;   Usage Page   12


; Replace any previous instance
#SingleInstance force

C(str) ; const container
{
return, (%str%)
static MS_SHORT := 2
static MS_DWORD := 4
static MS_PTR := 8 ;x64 specific

static SizeofRawInputDevice := MS_SHORT*2 + MS_DWORD + MS_PTR
/*
typedef struct tagRAWINPUTDEVICE {
  USHORT usUsagePage;
  USHORT usUsage;
  DWORD  dwFlags;
  HWND   hwndTarget;
} RAWINPUTDEVICE, *PRAWINPUTDEVICE, *LPRAWINPUTDEVICE;
*/

static SizeofRawInputDataHeader := MS_DWORD*2 + MS_PTR*2
/*
typedef struct tagRAWINPUTHEADER {
  DWORD  dwType;
  DWORD  dwSize;
  HANDLE hDevice;
  WPARAM wParam;
} RAWINPUTHEADER, *PRAWINPUTHEADER;
*/

static RIM_TYPEMOUSE := 0
static RIM_TYPEKEYBOARD := 1
static RIM_TYPEHID := 2

static RIDI_DEVICENAME := 0x20000007
static RIDI_DEVICEINFO := 0x2000000b

static RIDEV_INPUTSINK := 0x00000100 ; receive in foreground
static RID_INPUT       := 0x10000003 ; request header

; Keyboards are always Usage 6, Usage Page 1, Mice are Usage 2, Usage Page 1, 
; HID devices specify their top level collection in the info block   
static Usage := 1
static UsagePage := 12
}

HID_Input_Init:
{
DetectHiddenWindows, on
OnMessage(0x00FF, "InputMessage")

Gui, Show, Hide, NaturalCapture

HWND := WinExist("NaturalCapture")

VarSetCapacity(RawInputDevice, C("SizeofRawInputDevice"))
NumPut(C("UsagePage"), RawInputDevice, 0)
NumPut(C("Usage"), RawInputDevice, C("MS_SHORT"))
NumPut(C("RIDEV_INPUTSINK"), RawInputDevice, C("MS_SHORT")*2)
NumPut(HWND, RawInputDevice, C("MS_SHORT")*2 + C("MS_DWORD"))

Res := DllCall("RegisterRawInputDevices", "UInt", &RawInputDevice, UInt, 1, UInt, C("SizeofRawInputDevice"))
if (Res = 0)
    MsgBox, Failed to register for Natural Keyboard

return
}

InputMessage(wParam, lParam, msg, hwnd)
{
    Res := DllCall("GetRawInputData", UInt, lParam, UInt, C("RID_INPUT"), UInt, 0, "UInt *", Size, UInt, C("SizeofRawInputDataHeader"))

    VarSetCapacity(RawInputData, Size)

    Res := DllCall("GetRawInputData", UInt, lParam, UInt, C("RID_INPUT"), UInt, &RawInputData, "UInt *", Size, UInt, C("SizeofRawInputDataHeader"))

    SetFormat, Integer, Hex
    Type := NumGet(RawInputData, 0, "UInt")
    Size := NumGet(RawInputData, 1 * C("MS_DWORD"), "UInt")
    Handle := NumGet(RawInputData, 2 * C("MS_DWORD"), "UInt64") ; x64 specific

    if (Type = C("RIM_TYPEHID"))
    {
        SizeHid := NumGet(RawInputData, (C("SizeofRawInputDataHeader") + 0), "UInt")
        InputCount := NumGet(RawInputData, (C("SizeofRawInputDataHeader") + C("MS_DWORD")), "UInt")
        Loop %InputCount% {
            Addr := &RawInputData + C("SizeofRawInputDataHeader") + C("MS_DWORD")*2 + ((A_Index - 1) * SizeHid)
            BAddr := &RawInputData
            Input := Mem2Hex(Addr, SizeHid)
            if (IsLabel(Input))
            Gosub, %Input%
        }
    }
    else

    return
}

Scroll:
{
    if (ScrollDirection == 1)
    {
        Loop 4
        SendInput, {WheelUp}
    }
    else if (ScrollDirection == 2)
    {
        Loop 4
        SendInput, {WheelDown}
    }
    return
}

; --- Zoom --- 

; Zoom up
012D020000010000:
Send {Media_Next}
return

; Zoom down
012E020000010000:
Send {Media_Prev}
return

; --- Number pad keys ---

/*
;numpad=
0100006700000000:
0100006700010000:
return
;numpad(
010000B600000000:
010000B600010000:
return
;numpad)
010000B700000000:
010000B700010000:
return
*/

; --- Favorite keys ---

/*
; My Favorites
0182010000000000:
0182010000010000:
return
; Favorites 1
0100000000040000:
0100000000050000:
return
; Favorites 2
0100000000080000:
0100000000090000:
return
; Favorites 3
0100000000100000:
0100000000110000:
return
; Favorites 4
0100000000200000:
0100000000210000:
return
; Favorites 5
0100000000400000:
0100000000410000:
return
*/

; --- F-keys ---

/*
; F-lock - message alternates with each press (shifted / not shifted)
0100000000020000:
0100000000030000:
return
; F1 - Help
0195000000000000:
return
;F2 - Undo
011A020000000000:
return
;F3 - Redo
0179020000000000:
return
;F4 - New
0101020000000000:
return
;F5 - Open
0102020000000000:
return
;F6 - Close
0103020000000000:
return
;F7 - Reply
0189020000000000:
return
;F8 - Forward
018B020000000000:
return
;F9 - Spell Check
018C020000000000:
return
;F10 - Save
01AB010000000000:
return
;F11 - Print
0107020000000000:
return
;F12
0108020000000000:
return
*/

; --- Misc ---

/*
; Home
0123020000010000:
return
; Find
0121020000010000:
return
; Email
018A010000010000:
return
; Mute / Unmute
01E2000000010000:
return
; Volume down
01EA000000010000:
return
; Volume up
01E9000000010000:
return
; Play / Pause
01CD000000010000:
return
; Calculator
0192010000010000:
return
*/

Mem2Hex(pointer, len)
{
    A_FI := A_FormatInteger
    SetFormat, Integer, Hex
    Loop, %len% {
        Hex := *Pointer+0
        StringReplace, Hex, Hex, 0x, 0x0
        StringRight Hex, Hex, 2
        hexDump := hexDump . hex
        Pointer ++
    }
    SetFormat, Integer, %A_FI%
    StringUpper, hexDump, hexDump
    Return hexDump
}