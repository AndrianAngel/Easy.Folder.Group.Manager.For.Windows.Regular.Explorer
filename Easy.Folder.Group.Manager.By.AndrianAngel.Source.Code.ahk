#NoEnv
#SingleInstance Force
OnMessage(0x0133, "WM_CTLCOLOREDIT")
SetBatchLines, -1
SetWorkingDir %A_ScriptDir%
;Author: AndrianAngel (Github) Copyright @2026

; ============================================
; EASY FOLDER GROUP MANAGER
; ============================================

; Global Variables
Global IniFile := A_ScriptDir . "\FolderGroups.ini"
Global LogFile := A_ScriptDir . "\FolderHistory.txt"
Global Groups := {}
Global GuiVisible := False
Global MinimizedStack := []  ; Stack for minimize/restore
Global GuiHwnd := 0
Global MaxGroups := 8
Global QuickLauncherHotkey := "+F12"
Global ToggleSettingsHotkey := "^F11"
Global RemoveLauncherTitlebar := 0
Global RemoveSettingsTitlebar := 0
Global RemoveTimerTitlebar := 0

; Timer System Variables
Global TimerHotkey := "^F10"  ; Default hotkey for quick timer
Global TimerStates := {}      ; 1=running, 2=paused, 0=stopped
Global TimerRemaining := {}   ; Seconds remaining for each timer
Global TimerDefaults := {}    ; Default times for reset
Global TimerNames := {}       ; Display names for timers
Global TimerStartTick := {}   ; When timer started
Global TimerPausedRemaining := {} ; Time left when paused
Global TimerMode := {}        ; 1=minutes (left), 2=seconds (right)
Global TimerVisible := False  ; Track if timer GUI is visible
Global FlashCount := {}       ; For flashing when timer ends
Global FlashState := {}       ; Flash state
; Custom colors Variables
Global TimerColors := {}  ; Store color codes for timers (1-32)
Global DefaultTimerColor := "FFFFFF"  ; Default white color
Global ColorPickerColors := []
Global ColorPickerControl := ""

; Named color palette (20 colors)
Global ColorNames := ["Red", "Sky Blue", "Blue Light", "Blue Dogde", "Green yellow", "Turquoise", "Purple Light", "Lime", "Green light", "White", "Spring Green", "Pink Light", "Yellow", "Sand Brown", "Cyan", "Gold", "Light Brown", "Aquamarine", "Tomato", "Fuchsia Medium"]
Global ColorHexValues := ["FF0000", "28C9FF", "5770FE", "397DFA", "AFF10B", "3BF7A5", "AA88FF", "00FF21", "00FF00", "FFFFFF", "00FFAE", "F96AD3", "FCFF00", "FBA86D", "00FFFF", "FFD700", "DBA671", "74FBFB", "F34E4E", "FE4FFE"]
Global PresetColors := ["98FB98", "FFFF99", "87CEEB", "FFB6C1", "DDA0DD", "FF6B6B", "ADFF2F", "00FFFF", "D2B48C", "FF7F7F"]

; Global variable to track bold state
Global TimerFontBold := false  ; false = Normal, true = Bold

; Timer control variables
Global TimerDisp1, TimerDisp2, TimerDisp3, TimerDisp4, TimerDisp5, TimerDisp6, TimerDisp7, TimerDisp8
Global TimerDisp9, TimerDisp10, TimerDisp11, TimerDisp12, TimerDisp13, TimerDisp14, TimerDisp15, TimerDisp16
Global TimerDisp17, TimerDisp18, TimerDisp19, TimerDisp20, TimerDisp21, TimerDisp22, TimerDisp23, TimerDisp24
Global TimerDisp25, TimerDisp26, TimerDisp27, TimerDisp28, TimerDisp29, TimerDisp30, TimerDisp31, TimerDisp32

; Timer button control variables
Global StartBtn1, StartBtn2, StartBtn3, StartBtn4, StartBtn5, StartBtn6, StartBtn7, StartBtn8
Global StartBtn9, StartBtn10, StartBtn11, StartBtn12, StartBtn13, StartBtn14, StartBtn15, StartBtn16
Global StartBtn17, StartBtn18, StartBtn19, StartBtn20, StartBtn21, StartBtn22, StartBtn23, StartBtn24
Global StartBtn25, StartBtn26, StartBtn27, StartBtn28, StartBtn29, StartBtn30, StartBtn31, StartBtn32

Global PauseBtn1, PauseBtn2, PauseBtn3, PauseBtn4, PauseBtn5, PauseBtn6, PauseBtn7, PauseBtn8
Global PauseBtn9, PauseBtn10, PauseBtn11, PauseBtn12, PauseBtn13, PauseBtn14, PauseBtn15, PauseBtn16
Global PauseBtn17, PauseBtn18, PauseBtn19, PauseBtn20, PauseBtn21, PauseBtn22, PauseBtn23, PauseBtn24
Global PauseBtn25, PauseBtn26, PauseBtn27, PauseBtn28, PauseBtn29, PauseBtn30, PauseBtn31, PauseBtn32

Global ResumeBtn1, ResumeBtn2, ResumeBtn3, ResumeBtn4, ResumeBtn5, ResumeBtn6, ResumeBtn7, ResumeBtn8
Global ResumeBtn9, ResumeBtn10, ResumeBtn11, ResumeBtn12, ResumeBtn13, ResumeBtn14, ResumeBtn15, ResumeBtn16
Global ResumeBtn17, ResumeBtn18, ResumeBtn19, ResumeBtn20, ResumeBtn21, ResumeBtn22, ResumeBtn23, ResumeBtn24
Global ResumeBtn25, ResumeBtn26, ResumeBtn27, ResumeBtn28, ResumeBtn29, ResumeBtn30, ResumeBtn31, ResumeBtn32

Global ResetBtn1, ResetBtn2, ResetBtn3, ResetBtn4, ResetBtn5, ResetBtn6, ResetBtn7, ResetBtn8
Global ResetBtn9, ResetBtn10, ResetBtn11, ResetBtn12, ResetBtn13, ResetBtn14, ResetBtn15, ResetBtn16
Global ResetBtn17, ResetBtn18, ResetBtn19, ResetBtn20, ResetBtn21, ResetBtn22, ResetBtn23, ResetBtn24
Global ResetBtn25, ResetBtn26, ResetBtn27, ResetBtn28, ResetBtn29, ResetBtn30, ResetBtn31, ResetBtn32

; Color Buttons
Global ColorBtn1, ColorBtn2, ColorBtn3, ColorBtn4, ColorBtn5, ColorBtn6, ColorBtn7, ColorBtn8
Global ColorBtn9, ColorBtn10, ColorBtn11, ColorBtn12, ColorBtn13, ColorBtn14, ColorBtn15, ColorBtn16
Global ColorBtn17, ColorBtn18, ColorBtn19, ColorBtn20

Global TimerPinned := 0  ; 0 = not pinned, 1 = pinned

; Initialize
LoadSettings()
CreateTrayMenu()
SetupHotkeys()
StartScheduler()
Return

; ============================================
; UTILITY FUNCTIONS
; ============================================

FormatMinutes(totalSeconds) {
    if (totalSeconds <= 0)
        return "00:00"
    
    minutes := totalSeconds // 60
    seconds := Mod(totalSeconds, 60)
    
    ; Format with leading zeros
    formattedMinutes := Format("{:02d}", minutes)
    formattedSeconds := Format("{:02d}", seconds)
    
    return formattedMinutes . ":" . formattedSeconds
}

; ============================================
; COLOR PICKER FUNCTIONS
; ============================================

; Use colored text that acts like a button
ShowColorPicker(controlName) {
    Global ColorNames, ColorHexValues, ColorPickerColors, ColorPickerControl
    
    GuiControlGet, currentColor, Main:, %controlName%
    
    ; Store control name for later use
    ColorPickerControl := controlName
    
    ; Create color picker dialog
    Gui, ColorPicker:New
    Gui, ColorPicker:Color, 1E1E1E
    Gui, ColorPicker:Font, s10 cFFFFFF Bold
    
    Gui, ColorPicker:Add, Text, x10 y10, Select Color:
    
    ; Reset color picker colors array
    ColorPickerColors := []
    
    ; Add 20 named color "buttons" as colored text (4 rows of 5 each)
    Loop, 20 {
        colorName := ColorNames[A_Index]
        hexValue := ColorHexValues[A_Index]
        
        ; Calculate position (5 columns x 4 rows)
        col := Mod(A_Index - 1, 5)
        row := Floor((A_Index - 1) / 5)
        xPos := 10 + (col * 120)
        yPos := 40 + (row * 50)
        
		; Create colored text with border that looks like a button
		Gui, ColorPicker:Font, s9 Bold c%hexValue%
		Gui, ColorPicker:Add, Text, x%xPos% y%yPos% w110 h40 +0x200 +Border gColorPickerButtonClick Center vColorBtn%A_Index%, %colorName%
		Gui, ColorPicker:Font, s10 cFFFFFF Bold  ; Reset

		; Store button info
		ColorPickerColors.Push({index: A_Index, color: hexValue, name: colorName})
    }
    
    ; Custom color input section
    Gui, ColorPicker:Font, s10 cFFFFFF Normal
    Gui, ColorPicker:Add, Text, x10 y250, Custom Hex (RRGGBB):
    Gui, ColorPicker:Add, Edit, x10 y275 w150 vCustomColorInput, %currentColor%
    
	Gui, ColorPicker:Add, Button, x170 y275 w80 h25 gApplyCustomColor HwndHBtn3, Apply
    Gui, ColorPicker:Add, Button, x10 y310 w100 h30 gCancelColorPicker HwndHBtn4, Cancel
	
	DllCall("UxTheme\SetWindowTheme", "Ptr", hBtn3, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("UxTheme\SetWindowTheme", "Ptr", hBtn4, "Str", "DarkMode_Explorer", "Ptr", 0)
    
    Gui, ColorPicker:Show, w620 h360, Select Color
}


ColorPickerButtonClick:
    ; Get the control that was clicked
    clickedControl := A_GuiControl
    
    ; Extract index from control name (e.g., "ColorBtn5" -> 5)
    if (RegExMatch(clickedControl, "i)ColorBtn(\d+)", match)) {
        btnIndex := match1
        
        ; Get color info
        hexValue := ColorHexValues[btnIndex]
        colorName := ColorNames[btnIndex]
        
        ; Update the hex field in Main GUI
        GuiControl, Main:, %ColorPickerControl%, %hexValue%
        
        ; Update the color name display with colored text
        UpdateColorNameDisplay(ColorPickerControl, hexValue)
        
        ; Also update timer color if this is a timer color control
        UpdateTimerColorFromControl(ColorPickerControl, hexValue)
        
        ; Update timer GUI colors immediately
        UpdateTimerGuiColors()
        
        ; Close color picker
        Gui, ColorPicker:Destroy
    }
Return


ApplyCustomColor:
    Gui, ColorPicker:Submit, NoHide
    
    ; Validate hex format (6 characters, valid hex)
    if (RegExMatch(CustomColorInput, "^[0-9A-Fa-f]{6}$")) {
        ; Update the main control
        GuiControl, Main:, %ColorPickerControl%, %CustomColorInput%
        GuiControl, Main:Text, %ColorPickerControl%, %CustomColorInput%
        
        ; Update the color name display
        UpdateColorNameDisplay(ColorPickerControl, CustomColorInput)
        
		; Update timer GUI colors immediately
		UpdateTimerGuiColors()
	
        ; Close color picker
        Gui, ColorPicker:Destroy
    } else {
        MsgBox, 16, Invalid Color, Please enter a valid 6-digit hex color (e.g., FF0000)
    }
Return

CancelColorPicker:
    Gui, ColorPicker:Destroy
Return

SelectPresetColor:
Return

UseCustomColor:
Return

CancelColor:
    Gui, ColorPicker:Destroy
Return

; Update color name display with colored text
UpdateColorNameDisplay(controlName, hexValue) {
    Global
    
    ; Clean the hex value
    cleanHex := RegExReplace(hexValue, "^(#|0x)", "")
    cleanHex := Format("{:U}", cleanHex)
    
    ; Get color name
    colorName := GetColorName(cleanHex)
    
    ; Debug: Show what control we're updating
    ; MsgBox, Control: %controlName%`nHex: %cleanHex%`nColor Name: %colorName%
    
    ; Determine which timer this is for
    if (RegExMatch(controlName, "i)OpenAfterColor(\d+)", match)) {
        index := match1
        nameControl := "OpenAfterColorName" . index
        
        ; Update text with color name
        GuiControl, Main:, %nameControl%, %colorName%
        
        ; Update text color and make it bold
        Gui, Main:Font, s10 Bold c%cleanHex%
        GuiControl, Main:Font, %nameControl%
        Gui, Main:Font, s10 Normal cFFFFFF  ; Reset font
    }
    else if (RegExMatch(controlName, "i)CloseAfterColor(\d+)", match)) {
        index := match1
        nameControl := "CloseAfterColorName" . index
        
        ; Update text with color name
        GuiControl, Main:, %nameControl%, %colorName%
        
        ; Update text color and make it bold
        Gui, Main:Font, s10 Bold c%cleanHex%
        GuiControl, Main:Font, %nameControl%
        Gui, Main:Font, s10 Normal cFFFFFF  ; Reset font
    }
    else if (RegExMatch(controlName, "i)OpenAfterSecsColor(\d+)", match)) {
        index := match1
        nameControl := "OpenAfterSecsColorName" . index
        
        ; Debug
        ; MsgBox, SECONDS Open control: %controlName%`nIndex: %index%`nName Control: %nameControl%
        
        ; Update text with color name
        GuiControl, Main:, %nameControl%, %colorName%
        
        ; Update text color and make it bold
        Gui, Main:Font, s10 Bold c%cleanHex%
        GuiControl, Main:Font, %nameControl%
        Gui, Main:Font, s10 Normal cFFFFFF  ; Reset font
    }
    else if (RegExMatch(controlName, "i)CloseAfterSecsColor(\d+)", match)) {
        index := match1
        nameControl := "CloseAfterSecsColorName" . index
        
        ; Debug
        ; MsgBox, SECONDS Close control: %controlName%`nIndex: %index%`nName Control: %nameControl%
        
        ; Update text with color name
        GuiControl, Main:, %nameControl%, %colorName%
        
        ; Update text color and make it bold
        Gui, Main:Font, s10 Bold c%cleanHex%
        GuiControl, Main:Font, %nameControl%
        Gui, Main:Font, s10 Normal cFFFFFF  ; Reset font
    }
    else {
        ; Debug for unknown control
        MsgBox, Unknown control type: %controlName%
    }
}

ColorPickerGuiClose:
    Gui, ColorPicker:Destroy
Return


; Determine if text should be black or white based on background color
GetContrastColor(hexColor) {
    ; Remove any prefix
    hexColor := RegExReplace(hexColor, "^(#|0x)", "")
    
    ; Extract RGB components
    r := "0x" . SubStr(hexColor, 1, 2)
    g := "0x" . SubStr(hexColor, 3, 2)
    b := "0x" . SubStr(hexColor, 5, 2)
    
    ; Calculate relative luminance
    luminance := (0.299 * r + 0.587 * g + 0.114 * b)
    
    ; Return white for dark colors, black for light colors
    return (luminance < 128) ? "FFFFFF" : "000000"
}

; Get color name from hex value
GetColorName(hexValue) {
    Global ColorNames, ColorHexValues
    
    ; Remove any prefix
    hexValue := RegExReplace(hexValue, "^(#|0x)", "")
    
    ; Make uppercase for comparison
    hexValue := Format("{:U}", hexValue)
    
    Loop, % ColorHexValues.Length() {
        if (ColorHexValues[A_Index] = hexValue)
            return ColorNames[A_Index]
    }
    return "Custom"
}


; Update color preview in main GUI
UpdateColorPreview(controlName, color) {
    Global
    
    ; Update hex field
    GuiControl, Main:, %controlName%, %color%
    
    ; Update color name display
    UpdateColorNameDisplay(controlName, color)
    
    ; Also update timer color if this is a timer color control
    UpdateTimerColorFromControl(controlName, color)
}

; Update timer color in the TimerColors array
UpdateTimerColorFromControl(controlName, color) {
    Global TimerColors
    
    if (RegExMatch(controlName, "OpenAfterColor(\d+)", match)) {
        index := match1
        timerIndex := index  ; Timer 1-8 (minutes - open)
        TimerColors[timerIndex] := color
    }
    else if (RegExMatch(controlName, "CloseAfterColor(\d+)", match)) {
        index := match1
        timerIndex := index + 8  ; Timer 9-16 (minutes - close)
        TimerColors[timerIndex] := color
    }
    else if (RegExMatch(controlName, "OpenAfterSecsColor(\d+)", match)) {
        index := match1
        timerIndex := index + 16  ; Timer 17-24 (seconds - open)
        TimerColors[timerIndex] := color
    }
    else if (RegExMatch(controlName, "CloseAfterSecsColor(\d+)", match)) {
        index := match1
        timerIndex := index + 24  ; Timer 25-32 (seconds - close)
        TimerColors[timerIndex] := color
    }
    
    ; DEBUG: Show which timer got updated
    ; MsgBox, Control: %controlName%`nTimer Index: %timerIndex%`nColor: %color%
}

; Update timer display in Timer GUI when color changes
UpdateTimerGuiColors() {
    Global TimerVisible, TimerColors, DefaultTimerColor
    
    if (!TimerVisible)
        Return
    
    Loop, 32 {
        timerColor := TimerColors[A_Index] ? TimerColors[A_Index] : DefaultTimerColor
        GuiControl, TimerGUI:+c%timerColor%, TimerDisp%A_Index%
    }
}



; ============================================
; HOTKEY DEFINITIONS
; ============================================

ShowQuickLauncher() {
    Global Groups, MaxGroups, LauncherVisible, RemoveLauncherTitlebar
    
    ; Determine caption style
    captionStyle := RemoveLauncherTitlebar ? "-Caption" : ""
    
    Gui, Launcher:New, +AlwaysOnTop %captionStyle% +ToolWindow
    Gui, Launcher:Color, 1E1E1E
    Gui, Launcher:Font, s11 cFFFFFF Bold, Segoe UI
    
    Gui, Launcher:Add, Text, x10 y10 w280 h30 Center, Quick Group Launcher
    
    yPos := 50
    Loop, %MaxGroups% {
        if (Groups[A_Index].Name != "" && Groups[A_Index].IsPaused != 1) {
            groupName := Groups[A_Index].Name
            Gui, Launcher:Add, Button, x10 y%yPos% w280 h35 gLaunchGroup%A_Index% HwndHList7, %groupName%
            DllCall("UxTheme\SetWindowTheme", "Ptr", hList7, "Str", "DarkMode_Explorer", "Ptr", 0)
            yPos += 40
        }
    }
    
    Gui, Launcher:Show, w300 Center, Quick Launcher
}

LauncherGuiClose:
    Gui, Launcher:Destroy
    LauncherVisible := False
Return

LaunchGroup1:
    OpenGroup(1)
    Gui, Launcher:Destroy
Return
LaunchGroup2:
    OpenGroup(2)
    Gui, Launcher:Destroy
Return
LaunchGroup3:
    OpenGroup(3)
    Gui, Launcher:Destroy
Return
LaunchGroup4:
    OpenGroup(4)
    Gui, Launcher:Destroy
Return
LaunchGroup5:
    OpenGroup(5)
    Gui, Launcher:Destroy
Return
LaunchGroup6:
    OpenGroup(6)
    Gui, Launcher:Destroy
Return
LaunchGroup7:
    OpenGroup(7)
    Gui, Launcher:Destroy
Return
LaunchGroup8:
    OpenGroup(8)
    Gui, Launcher:Destroy
Return

; Start Timer Labels
StartTimer1:
    StartIndividualTimer(1)
Return

StartTimer2:
    StartIndividualTimer(2)
Return

StartTimer3:
    StartIndividualTimer(3)
Return

StartTimer4:
    StartIndividualTimer(4)
Return

StartTimer5:
    StartIndividualTimer(5)
Return

StartTimer6:
    StartIndividualTimer(6)
Return

StartTimer7:
    StartIndividualTimer(7)
Return

StartTimer8:
    StartIndividualTimer(8)
Return

StartTimer9:
    StartIndividualTimer(9)
Return

StartTimer10:
    StartIndividualTimer(10)
Return

StartTimer11:
    StartIndividualTimer(11)
Return

StartTimer12:
    StartIndividualTimer(12)
Return

StartTimer13:
    StartIndividualTimer(13)
Return

StartTimer14:
    StartIndividualTimer(14)
Return

StartTimer15:
    StartIndividualTimer(15)
Return

StartTimer16:
    StartIndividualTimer(16)
Return

StartTimer17:
    StartIndividualTimer(17)
Return

StartTimer18:
    StartIndividualTimer(18)
Return

StartTimer19:
    StartIndividualTimer(19)
Return

StartTimer20:
    StartIndividualTimer(20)
Return

StartTimer21:
    StartIndividualTimer(21)
Return

StartTimer22:
    StartIndividualTimer(22)
Return

StartTimer23:
    StartIndividualTimer(23)
Return

StartTimer24:
    StartIndividualTimer(24)
Return

StartTimer25:
    StartIndividualTimer(25)
Return

StartTimer26:
    StartIndividualTimer(26)
Return

StartTimer27:
    StartIndividualTimer(27)
Return

StartTimer28:
    StartIndividualTimer(28)
Return

StartTimer29:
    StartIndividualTimer(29)
Return

StartTimer30:
    StartIndividualTimer(30)
Return

StartTimer31:
    StartIndividualTimer(31)
Return

StartTimer32:
    StartIndividualTimer(32)
Return

; Pause Timer Labels
PauseTimer1:
    PauseIndividualTimer(1)
Return

PauseTimer2:
    PauseIndividualTimer(2)
Return

PauseTimer3:
    PauseIndividualTimer(3)
Return

PauseTimer4:
    PauseIndividualTimer(4)
Return

PauseTimer5:
    PauseIndividualTimer(5)
Return

PauseTimer6:
    PauseIndividualTimer(6)
Return

PauseTimer7:
    PauseIndividualTimer(7)
Return

PauseTimer8:
    PauseIndividualTimer(8)
Return

PauseTimer9:
    PauseIndividualTimer(9)
Return

PauseTimer10:
    PauseIndividualTimer(10)
Return

PauseTimer11:
    PauseIndividualTimer(11)
Return

PauseTimer12:
    PauseIndividualTimer(12)
Return

PauseTimer13:
    PauseIndividualTimer(13)
Return

PauseTimer14:
    PauseIndividualTimer(14)
Return

PauseTimer15:
    PauseIndividualTimer(15)
Return

PauseTimer16:
    PauseIndividualTimer(16)
Return

PauseTimer17:
    PauseIndividualTimer(17)
Return

PauseTimer18:
    PauseIndividualTimer(18)
Return

PauseTimer19:
    PauseIndividualTimer(19)
Return

PauseTimer20:
    PauseIndividualTimer(20)
Return

PauseTimer21:
    PauseIndividualTimer(21)
Return

PauseTimer22:
    PauseIndividualTimer(22)
Return

PauseTimer23:
    PauseIndividualTimer(23)
Return

PauseTimer24:
    PauseIndividualTimer(24)
Return

PauseTimer25:
    PauseIndividualTimer(25)
Return

PauseTimer26:
    PauseIndividualTimer(26)
Return

PauseTimer27:
    PauseIndividualTimer(27)
Return

PauseTimer28:
    PauseIndividualTimer(28)
Return

PauseTimer29:
    PauseIndividualTimer(29)
Return

PauseTimer30:
    PauseIndividualTimer(30)
Return

PauseTimer31:
    PauseIndividualTimer(31)
Return

PauseTimer32:
    PauseIndividualTimer(32)
Return

; Resume Timer Labels
ResumeTimer1:
    ResumeIndividualTimer(1)
Return

ResumeTimer2:
    ResumeIndividualTimer(2)
Return

ResumeTimer3:
    ResumeIndividualTimer(3)
Return

ResumeTimer4:
    ResumeIndividualTimer(4)
Return

ResumeTimer5:
    ResumeIndividualTimer(5)
Return

ResumeTimer6:
    ResumeIndividualTimer(6)
Return

ResumeTimer7:
    ResumeIndividualTimer(7)
Return

ResumeTimer8:
    ResumeIndividualTimer(8)
Return

ResumeTimer9:
    ResumeIndividualTimer(9)
Return

ResumeTimer10:
    ResumeIndividualTimer(10)
Return

ResumeTimer11:
    ResumeIndividualTimer(11)
Return

ResumeTimer12:
    ResumeIndividualTimer(12)
Return

ResumeTimer13:
    ResumeIndividualTimer(13)
Return

ResumeTimer14:
    ResumeIndividualTimer(14)
Return

ResumeTimer15:
    ResumeIndividualTimer(15)
Return

ResumeTimer16:
    ResumeIndividualTimer(16)
Return

ResumeTimer17:
    ResumeIndividualTimer(17)
Return

ResumeTimer18:
    ResumeIndividualTimer(18)
Return

ResumeTimer19:
    ResumeIndividualTimer(19)
Return

ResumeTimer20:
    ResumeIndividualTimer(20)
Return

ResumeTimer21:
    ResumeIndividualTimer(21)
Return

ResumeTimer22:
    ResumeIndividualTimer(22)
Return

ResumeTimer23:
    ResumeIndividualTimer(23)
Return

ResumeTimer24:
    ResumeIndividualTimer(24)
Return

ResumeTimer25:
    ResumeIndividualTimer(25)
Return

ResumeTimer26:
    ResumeIndividualTimer(26)
Return

ResumeTimer27:
    ResumeIndividualTimer(27)
Return

ResumeTimer28:
    ResumeIndividualTimer(28)
Return

ResumeTimer29:
    ResumeIndividualTimer(29)
Return

ResumeTimer30:
    ResumeIndividualTimer(30)
Return

ResumeTimer31:
    ResumeIndividualTimer(31)
Return

ResumeTimer32:
    ResumeIndividualTimer(32)
Return

; Reset Timer Labels
ResetTimer1:
    ResetIndividualTimer(1)
Return

ResetTimer2:
    ResetIndividualTimer(2)
Return

ResetTimer3:
    ResetIndividualTimer(3)
Return

ResetTimer4:
    ResetIndividualTimer(4)
Return

ResetTimer5:
    ResetIndividualTimer(5)
Return

ResetTimer6:
    ResetIndividualTimer(6)
Return

ResetTimer7:
    ResetIndividualTimer(7)
Return

ResetTimer8:
    ResetIndividualTimer(8)
Return

ResetTimer9:
    ResetIndividualTimer(9)
Return

ResetTimer10:
    ResetIndividualTimer(10)
Return

ResetTimer11:
    ResetIndividualTimer(11)
Return

ResetTimer12:
    ResetIndividualTimer(12)
Return

ResetTimer13:
    ResetIndividualTimer(13)
Return

ResetTimer14:
    ResetIndividualTimer(14)
Return

ResetTimer15:
    ResetIndividualTimer(15)
Return

ResetTimer16:
    ResetIndividualTimer(16)
Return

ResetTimer17:
    ResetIndividualTimer(17)
Return

ResetTimer18:
    ResetIndividualTimer(18)
Return

ResetTimer19:
    ResetIndividualTimer(19)
Return

ResetTimer20:
    ResetIndividualTimer(20)
Return

ResetTimer21:
    ResetIndividualTimer(21)
Return

ResetTimer22:
    ResetIndividualTimer(22)
Return

ResetTimer23:
    ResetIndividualTimer(23)
Return

ResetTimer24:
    ResetIndividualTimer(24)
Return

ResetTimer25:
    ResetIndividualTimer(25)
Return

ResetTimer26:
    ResetIndividualTimer(26)
Return

ResetTimer27:
    ResetIndividualTimer(27)
Return

ResetTimer28:
    ResetIndividualTimer(28)
Return

ResetTimer29:
    ResetIndividualTimer(29)
Return

ResetTimer30:
    ResetIndividualTimer(30)
Return

ResetTimer31:
    ResetIndividualTimer(31)
Return

ResetTimer32:
    ResetIndividualTimer(32)
Return

ShowTimerGUI() {
    Global TimerVisible, TimerNames, TimerMode, TimerRemaining
    Global RemoveTimerTitlebar, TimerFontBold, TimerPinned
    
    ; Initialize TimerPinned if not set
    if (TimerPinned = "")
        TimerPinned := 0
    
    ; Calculate GUI height
    guiHeight := 80 + (16 * 45) + 20 + 50
    
    captionStyle := RemoveTimerTitlebar ? "-Caption" : ""
    
    ; Add +AlwaysOnTop if pinned
    alwaysOnTopStyle := TimerPinned ? "+AlwaysOnTop" : ""
    Gui, TimerGUI:New, %alwaysOnTopStyle% %captionStyle% +ToolWindow
    Gui, TimerGUI:Color, 1E1E1E
    Gui, TimerGUI:Font, s10 cFFFFFF, Segoe UI
    
    ; Title
    Gui, TimerGUI:Font, s11 Bold cLime
    Gui, TimerGUI:Add, Text, x230 y10 w300 h30 Center, 32-TIMER CONTROL PANEL
    Gui, TimerGUI:Font, s10 Bold cYellow
    Gui, TimerGUI:Add, Text, x160 y40 w450 Center, Left: Minutes (1-60) | Right: Seconds (1-60) | Double-click time to edit
    Gui, TimerGUI:Font, s10 Normal cFFFFFF
    
    ; Create timer sections
    Loop, 16 {
        ; Left column (Minutes - Group Open/Close After)
        CreateTimerSection(A_Index, "x20 y" . (80 + (A_Index-1) * 45), 1)
        
        ; Right column (Seconds - Group Open/Close After Sec)
        CreateTimerSection(A_Index + 16, "x400 y" . (80 + (A_Index-1) * 45), 2)
    }
    
    ; Global controls at bottom
    yPos := 80 + (16 * 45) + 20
    Gui, TimerGUI:Add, Button, x165 y%yPos% w100 h30 gStartAllTimers HwndHList1, Start All
    Gui, TimerGUI:Add, Button, x+10 w100 h30 gPauseAllTimers HwndHList2, Pause All
    Gui, TimerGUI:Add, Button, x+10 w100 h30 gResumeAllTimers HwndHList3, Resume All
    Gui, TimerGUI:Add, Button, x+10 w100 h30 gResetAllTimers HwndHList4, Reset All   
    
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList1, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList2, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList3, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList4, "Str", "DarkMode_Explorer", "Ptr", 0)
    
    Gui, TimerGUI:Show, w765 h%guiHeight%, Timer Control Panel
    TimerVisible := True
    
    ; Update all button states
    Loop, 32 {
        UpdateTimerButtonStates(A_Index)
    }
    
    ; Initialize global button states
    UpdateGlobalTimerButtons()
    
    ; Start update timer
    SetTimer, UpdateAllCountdowns, 1000
    
    ; Apply current font style to all timer displays
    ApplyTimerFontStyle()
}

CreateTimerSection(index, position, mode) {
    Global TimerNames, TimerMode, TimerRemaining, TimerStates, TimerFontBold
    
    ; Group box
    modeText := (mode = 1) ? "Min" : "Sec"
    Gui, TimerGUI:Font, s10 cFFFFFF
    Gui, TimerGUI:Add, GroupBox, %position% w345 h35 cWhite, % TimerNames[index] . " (" . modeText . ")"
    
    ; Timer display
    yPos := RegExReplace(position, ".*y(\d+).*", "$1") + 22
    if (TimerMode[index] = 1) {
        timeStr := FormatMinutes(TimerRemaining[index])
    } else {
        timeStr := TimerRemaining[index]
    }
    
    ; Create the control with global variable
    style := "+0x200 +0x1"
    
    ; Set font style BEFORE creating the control
    if (TimerFontBold) {
        Gui, TimerGUI:Font, s10 Bold cWhite
    } else {
        Gui, TimerGUI:Font, s10 Normal cWhite
    }
    
    ; Create the control WITHOUT "Bold" or "Normal" in the style string
    Gui, TimerGUI:Add, Text, % "vTimerDisp" index " gOnTimerClick xp+10 y" yPos " w60 h20 Center Background303030 " style, % timeStr
    
    ; Reset font to normal for subsequent controls
    Gui, TimerGUI:Font, s10 Normal cFFFFFF
    
    ; Control buttons - use different state initialization based on timer status
    Gui, TimerGUI:Add, Button, % "gStartTimer" index " x+10 yp-3 w60 h24 HwndHList7 vStartBtn" index, Start
    Gui, TimerGUI:Add, Button, % "gPauseTimer" index " x+5 yp w60 h24 HwndHList8 vPauseBtn" index " Disabled", Pause
    Gui, TimerGUI:Add, Button, % "gResumeTimer" index " x+5 yp w60 h24 HwndHList9 vResumeBtn" index " Disabled", Resume
    Gui, TimerGUI:Add, Button, % "gResetTimer" index " x+5 yp w60 h24 HwndHList10 vResetBtn" index, Reset
    
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList7, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList8, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList9, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList10, "Str", "DarkMode_Explorer", "Ptr", 0)
    
    ; Set initial button states based on timer status
    UpdateTimerButtonStates(index)
}

; Save pin state to INI
SaveTimerPinState() {
    Global TimerPinned, IniFile
    IniWrite, %TimerPinned%, %IniFile%, AdditionalSettings, TimerPinned
}

; Save font state to INI
SaveTimerFontState() {
    Global TimerFontBold, IniFile
    IniWrite, %TimerFontBold%, %IniFile%, AdditionalSettings, TimerFontBold
}

; ============================================
; APPLY TIMER FONT STYLE FUNCTION
; ============================================

ApplyTimerFontStyle() {
    Global TimerFontBold, TimerRemaining, TimerMode
    
    Loop, 32 {
        if (TimerMode[A_Index] = 1) {
            timeStr := FormatMinutes(TimerRemaining[A_Index])
        } else {
            timeStr := TimerRemaining[A_Index]
        }
        
        ; Update the display text
        GuiControl, TimerGUI:, TimerDisp%A_Index%, %timeStr%
        
        ; Apply font style - Set the font FIRST, then apply to control
        if (TimerFontBold) {
            Gui, TimerGUI:Font, s10 Bold
            GuiControl, TimerGUI:Font, TimerDisp%A_Index%
        } else {
            Gui, TimerGUI:Font, s10 Normal
            GuiControl, TimerGUI:Font, TimerDisp%A_Index%
        }
    }
    
    ; Reset font to normal for other controls
    Gui, TimerGUI:Font, s10 Normal cFFFFFF
}

UpdateTimerButtonStates(index) {
    Global TimerStates, TimerDefaults
    
    if (TimerStates[index] = 0) {  ; Stopped
        if (TimerDefaults[index] > 0) {
            GuiControl, TimerGUI:Enable, StartBtn%index%
        } else {
            GuiControl, TimerGUI:Disable, StartBtn%index%
        }
        GuiControl, TimerGUI:Disable, PauseBtn%index%
        GuiControl, TimerGUI:Disable, ResumeBtn%index%
        GuiControl, TimerGUI:Enable, ResetBtn%index%
    } else if (TimerStates[index] = 1) {  ; Running
        GuiControl, TimerGUI:Disable, StartBtn%index%
        GuiControl, TimerGUI:Enable, PauseBtn%index%
        GuiControl, TimerGUI:Disable, ResumeBtn%index%
        GuiControl, TimerGUI:Enable, ResetBtn%index%
    } else if (TimerStates[index] = 2) {  ; Paused
        GuiControl, TimerGUI:Disable, StartBtn%index%
        GuiControl, TimerGUI:Disable, PauseBtn%index%
        GuiControl, TimerGUI:Enable, ResumeBtn%index%
        GuiControl, TimerGUI:Enable, ResetBtn%index%
    }
}

UpdateGlobalTimerButtons() {
    Global TimerStates, TimerDefaults
    
    ; Check if any timer is running
    anyRunning := false
    anyPaused := false
    anyWithTime := false
    
    Loop, 32 {
        ; Check if timer has any time (default > 0)
        if (TimerDefaults[A_Index] > 0) {
            anyWithTime := true
        }
        
        ; Check if timer is running
        if (TimerStates[A_Index] = 1) {
            anyRunning := true
        } 
        ; Check if timer is paused
        else if (TimerStates[A_Index] = 2) {
            anyPaused := true
        }
    }
    
    ; Enable/disable buttons based on overall state
    if (anyRunning) {
        ; At least one timer is running
        GuiControl, TimerGUI:Enable, Start All      ; Keep Start All enabled
        GuiControl, TimerGUI:Enable, Pause All
        GuiControl, TimerGUI:Disable, Resume All
        GuiControl, TimerGUI:Enable, Reset All
    } else if (anyPaused) {
        ; At least one timer is paused, none are running
        GuiControl, TimerGUI:Enable, Start All      ; Keep Start All enabled
        GuiControl, TimerGUI:Disable, Pause All
        GuiControl, TimerGUI:Enable, Resume All
        GuiControl, TimerGUI:Enable, Reset All
    } else {
        ; No timers running or paused
        if (anyWithTime) {
            ; Some timers have time
            GuiControl, TimerGUI:Enable, Start All
            GuiControl, TimerGUI:Disable, Pause All
            GuiControl, TimerGUI:Disable, Resume All
            GuiControl, TimerGUI:Enable, Reset All
        } else {
            ; All timers are at 0
            GuiControl, TimerGUI:Disable, Start All
            GuiControl, TimerGUI:Disable, Pause All
            GuiControl, TimerGUI:Disable, Resume All
            GuiControl, TimerGUI:Enable, Reset All
        }
    }
}


UpdateAllTimerButtonStates() {
    Loop, 32 {
        UpdateTimerButtonStates(A_Index)
    }
}

GetGroupFromTimerIndex(index) {
    if (index <= 16) {
        ; Minute timers
        return Mod(index-1, 8) + 1
    } else {
        ; Second timers
        return Mod(index-17, 8) + 1
    }
}

GetTimerTypeFromIndex(index) {
    if (index <= 8 || (index > 16 && index <= 24)) {
        return "Open"
    } else {
        return "Close"
    }
}

; Timer click handler (for editing)
OnTimerClick:
    if (A_GuiEvent = "DoubleClick") {
        ; Debug: Show what control was clicked
        ;MsgBox, Debug Info:`n`nControl: %A_GuiControl%`nEvent: %A_GuiEvent%
        
        ; Check if it's a TimerDisp control
        if (InStr(A_GuiControl, "TimerDisp")) {
            ; Extract index from "TimerDispX"
            index := SubStr(A_GuiControl, 10)
            
            ; Convert to number
            index := index + 0
            
            ; Make sure it's a valid index (1-32)
            if (index >= 1 && index <= 32) {
                ShowTimerEditDialog(index)
            }
        }
    }
Return

ShowTimerEditDialog(index) {
    Global TimerRemaining, TimerMode, TimerNames
    
    currentValue := TimerRemaining[index]
    
    ; Debug: Check current values
    ; MsgBox Index: %index%`nValue: %currentValue%`nMode: %TimerMode[index]%
    
    Gui, TimerEdit:New, +AlwaysOnTop -Caption +ToolWindow
    Gui, TimerEdit:Color, 1E1E1E
    Gui, TimerEdit:Font, s10 cFFFFFF
    
    if (TimerMode[index] = 1) {
        ; Minutes mode
        minutes := currentValue // 60
        seconds := Mod(currentValue, 60)
        
        Gui, TimerEdit:Add, Text, x10 y10, % TimerNames[index]
        Gui, TimerEdit:Add, Text, x10 y40, Minutes:
        Gui, TimerEdit:Add, Edit, x70 y37 w60 vEditMinutes, %minutes%
        Gui, TimerEdit:Add, Text, x10 y70, Seconds:
        Gui, TimerEdit:Add, Edit, x70 y67 w60 vEditSeconds, %seconds%
    } else {
        ; Seconds mode
        Gui, TimerEdit:Add, Text, x10 y10, % TimerNames[index]
        Gui, TimerEdit:Add, Text, x10 y40, Seconds (0-60):
        Gui, TimerEdit:Add, Edit, x10 y60 w120 vEditSeconds, %currentValue%
    }
    
    Gui, TimerEdit:Add, Button, x10 y100 w50 gSaveTimerEdit HwndHBtn1, OK
    Gui, TimerEdit:Add, Button, x70 y100 w50 gCancelTimerEdit HwndHBtn2, Cancel
	
	DllCall("UxTheme\SetWindowTheme", "Ptr", hBtn1, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("UxTheme\SetWindowTheme", "Ptr", hBtn2, "Str", "DarkMode_Explorer", "Ptr", 0)
    
    ; Store the index in a global variable
    Global EditingTimerIndex := index
    
    Gui, TimerEdit:Show, w140 h140, Edit Timer %index%
}

SaveTimerEdit:
    Gui, TimerEdit:Submit, NoHide
    
    ; Make sure we have a valid index
    if (!EditingTimerIndex) {
        MsgBox Error: No timer index!
        Gui, TimerEdit:Destroy
        Return
    }
    
    index := EditingTimerIndex
    
    if (TimerMode[index] = 1) {
        ; Validate inputs
        if (EditMinutes = "" || EditSeconds = "")
            EditMinutes := 0, EditSeconds := 0
            
        totalSeconds := (EditMinutes * 60) + EditSeconds
    } else {
        if (EditSeconds = "")
            EditSeconds := 0
            
        totalSeconds := EditSeconds
    }
    
    ; Debug: Show what we're saving
    ; MsgBox Saving:`nIndex: %index%`nTotal Seconds: %totalSeconds%
    
    ; Update timer values
    TimerRemaining[index] := totalSeconds
    TimerDefaults[index] := totalSeconds
    
    ; Force immediate display update
    if (TimerMode[index] = 1) {
        timeStr := FormatMinutes(totalSeconds)
    } else {
        timeStr := totalSeconds
    }
    
    ; Update the GUI control - use proper control name
    GuiControl, TimerGUI:, TimerDisp%index%, %timeStr%
    
    ; Update group setting
    UpdateGroupFromTimer(index, totalSeconds)
    
    ; Clear the global variable
    Global EditingTimerIndex := 0
    
    Gui, TimerEdit:Destroy
Return

CancelTimerEdit:
    Global EditingTimerIndex := 0
    Gui, TimerEdit:Destroy
Return


StartIndividualTimer(index) {
    Global TimerStates, TimerRemaining, TimerStartTick, TimerDefaults
    
    if (TimerStates[index] = 0) {
        ; Check if timer has any time
        if (TimerRemaining[index] <= 0 && TimerDefaults[index] <= 0) {
            return
        }
        
        ; If timer is at 0, reset to default first
        if (TimerRemaining[index] <= 0) {
            TimerRemaining[index] := TimerDefaults[index]
        }
        
        ; Start the timer
        TimerStartTick[index] := A_TickCount
        TimerStates[index] := 1
        
        ; Update button states
        UpdateTimerButtonStates(index)
        
        ; Update global buttons
        UpdateGlobalTimerButtons()
        
        ; Stop flashing
        FlashCount[index] := 0
        FlashState[index] := 0
        timerColor := TimerColors[index] ? TimerColors[index] : DefaultTimerColor
		GuiControl, TimerGUI:+c%timerColor%, TimerDisp%index%
    }
}

PauseIndividualTimer(index) {
    Global TimerStates, TimerRemaining, TimerStartTick, TimerPausedRemaining, TimerDefaults
    
    if (TimerStates[index] = 1) {
        elapsed := (A_TickCount - TimerStartTick[index]) // 1000
        remaining := TimerDefaults[index] - elapsed
        TimerPausedRemaining[index] := remaining > 0 ? remaining : 0
        TimerStates[index] := 2
        
        ; Update button states
        UpdateTimerButtonStates(index)
        UpdateGlobalTimerButtons()
    }
}

ResumeIndividualTimer(index) {
    Global TimerStates, TimerPausedRemaining, TimerRemaining, TimerStartTick, TimerDefaults
    
    if (TimerStates[index] = 2) {
        TimerRemaining[index] := TimerPausedRemaining[index]
        TimerDefaults[index] := TimerPausedRemaining[index]
        TimerStartTick[index] := A_TickCount
        TimerStates[index] := 1
        
        ; Update button states
        UpdateTimerButtonStates(index)
        UpdateGlobalTimerButtons()
    }
}

ResetIndividualTimer(index) {
    Global TimerStates, TimerRemaining, TimerDefaults, TimerMode
    
    TimerStates[index] := 0
    
    ; Set to default values
    if (index <= 16) {
        TimerRemaining[index] := 300
        TimerDefaults[index] := 300
    } else {
        TimerRemaining[index] := 30
        TimerDefaults[index] := 30
    }
    
    ; Update display
    if (TimerMode[index] = 1) {
        timeStr := FormatMinutes(TimerDefaults[index])
    } else {
        timeStr := TimerDefaults[index]
    }
    GuiControl, TimerGUI:, TimerDisp%index%, %timeStr%
    
    ; Update button states
    UpdateTimerButtonStates(index)
    UpdateGlobalTimerButtons()
    
    ; Stop flashing
    FlashCount[index] := 0
    FlashState[index] := 0
    timerColor := TimerColors[index] ? TimerColors[index] : DefaultTimerColor
	GuiControl, TimerGUI:+c%timerColor%, TimerDisp%index%
}


; Sync timer values to group settings
UpdateGroupFromTimer(timerIndex, value) {
    Global Groups, MaxGroups
    
    groupNum := GetGroupFromTimerIndex(timerIndex)
    timerType := GetTimerTypeFromIndex(timerIndex)
    isSeconds := (timerIndex > 16)
    
    if (groupNum > MaxGroups || Groups[groupNum].Name = "")
        Return
    
    if (timerType = "Open") {
        if (isSeconds) {
            Groups[groupNum].OpenAfterSecs := value
            Groups[groupNum].OpenAfterSecsEnabled := (value > 0) ? 1 : 0
        } else {
            Groups[groupNum].OpenAfterMins := value // 60
            Groups[groupNum].OpenAfterEnabled := (value > 0) ? 1 : 0
        }
    } else {
        if (isSeconds) {
            Groups[groupNum].CloseAfterSecs := value
            Groups[groupNum].CloseAfterSecsEnabled := (value > 0) ? 1 : 0
        } else {
            Groups[groupNum].CloseAfterMins := value // 60
            Groups[groupNum].CloseAfterEnabled := (value > 0) ? 1 : 0
        }
    }
    
    ; Save to INI
    SaveGroupToIni(groupNum)
}


UpdateAllCountdowns:
    globalStateChanged := false
    
    Loop, 32 {
        if (TimerStates[A_Index] = 1) {  ; Running
            elapsed := (A_TickCount - TimerStartTick[A_Index]) // 1000
            remaining := TimerDefaults[A_Index] - elapsed
            
            if (remaining <= 0) {
                ; Timer finished
                TimerStates[A_Index] := 0
                remaining := 0
                globalStateChanged := true
                
                ; Trigger group action
                TriggerTimerAction(A_Index)
                
                ; Start flashing
                FlashCount[A_Index] := 10
				
				; Update the display with color
				UpdateTimerDisplay(A_Index)
                
                ; Update button states for this timer
                UpdateTimerButtonStates(A_Index)
            }
            
            ; Update the display
            if (TimerMode[A_Index] = 1) {
                timeStr := FormatMinutes(remaining)
            } else {
                timeStr := remaining
            }
            GuiControl, TimerGUI:, TimerDisp%A_Index%, %timeStr%
            
            ; Apply custom color for running timers
            timerColor := TimerColors[A_Index] ? TimerColors[A_Index] : DefaultTimerColor
            GuiControl, TimerGUI:+c%timerColor%, TimerDisp%A_Index%
        }
    }
    
    ; Update global buttons if any timer finished
    if (globalStateChanged) {
        UpdateGlobalTimerButtons()
    }
Return

TriggerTimerAction(timerIndex) {
    Global Groups
    
    groupNum := GetGroupFromTimerIndex(timerIndex)
    timerType := GetTimerTypeFromIndex(timerIndex)
    
    if (groupNum <= MaxGroups && Groups[groupNum].Name != "") {
        if (timerType = "Open") {
            OpenGroup(groupNum)
        } else {
            CloseGroupFolders(groupNum)
        }
    }
}


UpdateTimerDisplay(index) {
    Global TimerRemaining, TimerMode, TimerColors, DefaultTimerColor, TimerFontBold
    
    if (TimerMode[index] = 1) {
        timeStr := FormatMinutes(TimerRemaining[index])
    } else {
        timeStr := TimerRemaining[index]
    }
    
    ; Update the display text
    GuiControl, TimerGUI:, TimerDisp%index%, %timeStr%
    
    ; Apply color if timer is stopped (0) or has a custom color
    if (TimerStates[index] = 0) {
        color := TimerColors[index] ? TimerColors[index] : DefaultTimerColor
        GuiControl, TimerGUI:+c%color%, TimerDisp%index%
        GuiControl, TimerGUI:+Background303030, TimerDisp%index%
    } 
    else if (TimerStates[index] = 1) {  ; Running
        ; Use white for running timers
        GuiControl, TimerGUI:+cFFFFFF, TimerDisp%index%
    }
    else if (TimerStates[index] = 2) {  ; Paused
        ; Use a different color for paused (e.g., yellow)
        GuiControl, TimerGUI:+cFFFF00, TimerDisp%index%
    }
    
    ; Apply font style
    if (TimerFontBold) {
        GuiControl, TimerGUI:Font, TimerDisp%index%
        Gui, TimerGUI:Font, s10 Bold
        GuiControl, TimerGUI:Font, TimerDisp%index%
        Gui, TimerGUI:Font, s10 Normal  ; Reset
    } else {
        GuiControl, TimerGUI:Font, TimerDisp%index%
        Gui, TimerGUI:Font, s10 Normal
        GuiControl, TimerGUI:Font, TimerDisp%index%
        Gui, TimerGUI:Font, s10 Normal  ; Reset
    }
}

StartAllTimers:
    Loop, 32 {
        ; Skip timers that are at 0
        if (TimerDefaults[A_Index] <= 0) {
            Continue
        }
        
        ; If timer is at 0, reset to default first
        if (TimerRemaining[A_Index] <= 0) {
            TimerRemaining[A_Index] := TimerDefaults[A_Index]
        }
        
        ; Start if stopped
        if (TimerStates[A_Index] = 0) {
            TimerStartTick[A_Index] := A_TickCount
            TimerStates[A_Index] := 1
            UpdateTimerButtonStates(A_Index)
        } 
        ; Resume if paused
        else if (TimerStates[A_Index] = 2) {
            ResumeIndividualTimer(A_Index)
        }
        
        ; Stop any flashing
        FlashCount[A_Index] := 0
        FlashState[A_Index] := 0
        timerColor := TimerColors[A_Index] ? TimerColors[A_Index] : DefaultTimerColor
		GuiControl, TimerGUI:+c%timerColor%, TimerDisp%A_Index%
    }
    
    UpdateGlobalTimerButtons()
Return

PauseAllTimers:
    Loop, 32 {
        if (TimerStates[A_Index] = 1) {
            PauseIndividualTimer(A_Index)
        }
    }
Return

ResumeAllTimers:
    Loop, 32 {
        if (TimerStates[A_Index] = 2) {
            ResumeIndividualTimer(A_Index)
        }
    }
Return

ResetAllTimers:
    Loop, 32 {
        ResetIndividualTimer(A_Index)
    }
Return

; ============================================
; TRAY MENU
; ============================================


CreateTrayMenu() {
    Menu, Tray, NoStandard
    Menu, Tray, Add, Open Settings, OpenGuiFromTray
    Menu, Tray, Add, Quick Launcher, ShowQuickLauncher
	Menu, Tray, Add, Quick Timer, ShowQuickTimerFromTray
    Menu, Tray, Add,
    Menu, Tray, Add, Reload Script, ReloadScript
    Menu, Tray, Add, Exit, ExitScript
    Menu, Tray, Tip, Easy Folder Group Manager
}

ShowQuickTimerFromTray:
    ShowTimerGUI()
Return


OpenGuiFromTray:
    ToggleGui()
Return

ReloadScript:
    Reload
Return

ExitScript:
    ExitApp
Return

;---------WM_CTLCOLOREDIT----------

WM_CTLCOLOREDIT(wParam, lParam) {
    DllCall("SetTextColor", "Ptr", wParam, "UInt", 0xFFFFFF)
    DllCall("SetBkColor", "Ptr", wParam, "UInt", 0x2E2E2E)
    Return DllCall("CreateSolidBrush", "UInt", 0x2E2E2E, "Ptr")
}

; ============================================
; GUI FUNCTIONS
; ============================================

CreateGui() {
    Global
	; Remove white title bar using DllCall
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", WinExist(), "UInt", 20, "Int*", 1, "UInt", 4)
    
    ; Dark theme colors
    BgColor := "1E1E1E"
    
    ; Dark theme colors
    BgColor := "1E1E1E"
    TextColor := "FFFFFF"
	
	captionStyle := RemoveSettingsTitlebar ? "-Caption" : ""
    
	Gui, Main:New, %captionStyle%
	Gui, Main:+LastFound
	GuiHwnd := WinExist()
	
    Gui, Main:Color, %BgColor%
    Gui, Main:Font, s10 c%TextColor%, Segoe UI
    
    ; Create Tabs
    Gui, Main:Add, Tab3, x10 y10 w980 h820 vMainTabs gTabChanged, GENERAL|GROUP BEHAVIOUR|ADVANCED OPTIONS|SCHEDULING|ADDITIONAL SETTINGS
    
    ; ============================================
    ; TAB 1: GENERAL
    ; ============================================
    Gui, Main:Tab, 1

	Gui, Main:Font, s10 Bold cLime, Segoe UI
	Gui, Main:Add, Text, x20 y50 w960 h30 Center, MAIN SETTING - DASHBOARD
	Gui, Main:Font, s10 Normal cFFFFFF, Segoe UI

	;------------Add single note--------------

	Gui, Main:Font, s10 Bold cLime, Segoe UI
	Gui, Main:Add, Text, x40 y770 w600 h60 Center, NOTE: Click EDIT button to customize - Click DEFAULT button to delete configuration
	Gui, Main:Font, s10 Normal cFFFFFF, Segoe UI
		

	; Load groups into ListView
	LoadGroupsIntoListView()
    
    ; ============================================
    ; TAB 2: GROUP BEHAVIOUR
    ; ============================================
    Gui, Main:Tab, 2

    Gui, Main:Font, s10 Bold cLime, Segoe UI
	Gui, Main:Add, Text, x260 y50 w100 h30, STACK
	Gui, Main:Add, Text, x440 y50 w100 h30, MINIMIZE
	Gui, Main:Add, Text, x690 y50 w100 h30, RESIZE
	
	Gui, Main:Font, s10 Normal cFFFFFF, Segoe UI
	
	;------------Add single note--------------

	Gui, Main:Font, s10 Bold cLime, Segoe UI
	Gui, Main:Add, Text, x20 y770 w350 h60 Center, NOTE: Stack - Minimize - Resize can be combined ACTION PER GROUP
	Gui, Main:Font, s10 Normal cFFFFFF, Segoe UI

    yPos := 90
    Loop, %MaxGroups% {
        groupName := Groups[A_Index].Name
        if (groupName = "")
            Continue
            
        Gui, Main:Add, Text, x20 y%yPos% w200, Name: %groupName%
        
        checkY := yPos + 5
        Gui, Main:Add, Checkbox, x230 y%checkY% vStackFolders%A_Index%, Stack Folders
        Gui, Main:Add, Checkbox, x400 y%checkY% vMinimizeAll%A_Index%, Minimize All Folders
        Gui, Main:Add, Checkbox, x600 y%checkY% vSpecificSize%A_Index%, Choose a specific size for all folders
        
        sizeY := yPos + 30
        Gui, Main:Add, Text, x630 y%sizeY%, WIDTH
        Gui, Main:Add, Edit, x690 y%sizeY% w60 vFolderWidth%A_Index% +0x200, % Groups[A_Index].Width
        Gui, Main:Add, Text, x760 y%sizeY%, X HEIGHT
        Gui, Main:Add, Edit, x830 y%sizeY% w60 vFolderHeight%A_Index% +0x200, % Groups[A_Index].Height
        
        ; Set checkbox states
        GuiControl, Main:, StackFolders%A_Index%, % Groups[A_Index].StackFolders
        GuiControl, Main:, MinimizeAll%A_Index%, % Groups[A_Index].MinimizeAll
        GuiControl, Main:, SpecificSize%A_Index%, % Groups[A_Index].SpecificSize
        
        yPos += 70
    }

    ; ============================================
    ; TAB 3: ADVANCED OPTIONS
    ; ============================================
    Gui, Main:Tab, 3
	
    Gui, Main:Font, s10 Bold cLime, Segoe UI
    Gui, Main:Add, Text, x20 y50 w960 h30 Center, ADVANCED OPTIONS : DISPLAY AND LOG
	Gui, Main:Font, s10 Normal cFFFFFF, Segoe UI
	
	;------------Add single note--------------

	Gui, Main:Font, s10 Bold cLime, Segoe UI
	Gui, Main:Add, Text, x40 y770 w590 h60 Center, NOTE: - You can use dual display vertical or horizontal if there is only two folders in the group - Choose between dual display vertical or horizontal but not both
	Gui, Main:Font, s10 Normal cFFFFFF, Segoe UI
    
    yPos := 90
    Loop, %MaxGroups% {
        groupName := Groups[A_Index].Name
        if (groupName = "")
            Continue
            
        Gui, Main:Add, Text, x20 y%yPos% w200, Name: %groupName%
        
        checkY := yPos + 5
        Gui, Main:Add, Checkbox, x230 y%checkY% vDualVertical%A_Index%, Open in dual display vertical (2 Folders only in the group)
        
        checkY2 := yPos + 25
        Gui, Main:Add, Checkbox, x230 y%checkY2% vDualHorizontal%A_Index%, Open in dual display horizontal if there is two folders only
                
        checkY3 := yPos + 45
        Gui, Main:Add, Checkbox, x230 y%checkY3% vHistoryLog%A_Index%, History log in TXT files to store last opened group with all its folders
        
        ; Set checkbox states
        GuiControl, Main:, DualVertical%A_Index%, % Groups[A_Index].DualVertical
        GuiControl, Main:, DualHorizontal%A_Index%, % Groups[A_Index].DualHorizontal
        GuiControl, Main:, HistoryLog%A_Index%, % Groups[A_Index].HistoryLog
        
        yPos += 75
    }
    
	; ============================================
	; TAB 4: SCHEDULING
	; ============================================
	Gui, Main:Tab, 4
		
	Gui, Main:Font, s10 Bold cLime, Segoe UI
	Gui, Main:Add, Text, x20 y50 w460 h30 Center, MINUTES TIMERS
	Gui, Main:Add, Text, x500 y50 w460 h30 Center, SECONDS TIMERS
	Gui, Main:Font, s10 Normal cFFFFFF, Segoe UI

	;------------Add single note--------------
	Gui, Main:Font, s10 Bold cLime, Segoe UI
	Gui, Main:Add, Text, x40 y770 w470 h60 Center, NOTE: Set custom colors for timer displays in Quick Timer panel. Format: RRGGBB (e.g., FF0000=Red, 00FF00=Green)
	Gui, Main:Font, s10 Normal cFFFFFF, Segoe UI

	; Create two columns: Minutes on left, Seconds on right
	yPosMinutes := 90
	yPosSeconds := 90

	Loop, %MaxGroups% {
		groupName := Groups[A_Index].Name
		if (groupName = "")
			Continue
			
		; Get timer indices for this group
		minOpenTimer := A_Index
		minCloseTimer := A_Index + 8
		secOpenTimer := A_Index + 16
		secCloseTimer := A_Index + 24
		
		; Get current colors
		openAfterColor := TimerColors[minOpenTimer] ? TimerColors[minOpenTimer] : DefaultTimerColor
		closeAfterColor := TimerColors[minCloseTimer] ? TimerColors[minCloseTimer] : DefaultTimerColor
		openAfterSecsColor := TimerColors[secOpenTimer] ? TimerColors[secOpenTimer] : DefaultTimerColor
		closeAfterSecsColor := TimerColors[secCloseTimer] ? TimerColors[secCloseTimer] : DefaultTimerColor
		
		GuiControl, Main:+Background%openAfterColor%, OpenAfterPrev%A_Index%
        GuiControl, Main:, OpenAfterPrev%A_Index%, 100
        
        GuiControl, Main:+Background%closeAfterColor%, CloseAfterPrev%A_Index%
        GuiControl, Main:, CloseAfterPrev%A_Index%, 100
        
        GuiControl, Main:+Background%openAfterSecsColor%, OpenAfterSecsPrev%A_Index%
        GuiControl, Main:, OpenAfterSecsPrev%A_Index%, 100
        
        GuiControl, Main:+Background%closeAfterSecsColor%, CloseAfterSecsPrev%A_Index%
        GuiControl, Main:, CloseAfterSecsPrev%A_Index%, 100
		
		; ===== LEFT COLUMN: MINUTES TIMERS =====
		Gui, Main:Add, Text, x20 y%yPosMinutes% w200, %groupName% (Minutes):
		
		; Open After (Minutes)
		checkY := yPosMinutes + 25
		Gui, Main:Add, Text, x40 y%checkY%, Open After:
		Gui, Main:Add, Edit, x120 y%checkY% w80 vOpenAfterColor%A_Index% +0x200, %openAfterColor%

		; Colored text button for Open After Color - FIXED: White text
		Gui, Main:Font, s9 Bold cFFFFFF  ; WHITE TEXT
		Gui, Main:Add, Text, x210 y%checkY% w60 h24 +0x200 +Border gSelectColorHandler vColorTextOpenAfter%A_Index% Center, Color
		Gui, Main:Font, s10 Normal cFFFFFF  ; Reset font

		; Color name display (bold and colored)
		openColorName := GetColorName(openAfterColor)
		Gui, Main:Add, Text, x280 y%checkY%+2 w100 vOpenAfterColorName%A_Index%, %openColorName%
		; Apply the color to the text
		cleanOpenHex := RegExReplace(openAfterColor, "^(#|0x)", "")
		Gui, Main:Font, s10 Bold c%cleanOpenHex%
		GuiControl, Main:Font, OpenAfterColorName%A_Index%
		Gui, Main:Font, s10 Normal cFFFFFF

		; Close After (Minutes)
		checkY2 := yPosMinutes + 50
		Gui, Main:Add, Text, x40 y%checkY2%, Close After:
		Gui, Main:Add, Edit, x120 y%checkY2% w80 vCloseAfterColor%A_Index% +0x200, %closeAfterColor%

		; Colored text button for Close After Color - FIXED: White text
		Gui, Main:Font, s9 Bold cFFFFFF  ; WHITE TEXT
		Gui, Main:Add, Text, x210 y%checkY2% w60 h24 +0x200 +Border gSelectColorHandler vColorTextCloseAfter%A_Index% Center, Color
		Gui, Main:Font, s10 Normal cFFFFFF

		; Color name display (bold and colored)
		closeColorName := GetColorName(closeAfterColor)
		Gui, Main:Font, s10 Bold c%closeAfterColor%
		Gui, Main:Add, Text, x280 y%checkY2%+2 w100 vCloseAfterColorName%A_Index%, %closeColorName%
		Gui, Main:Font, s10 Normal cFFFFFF

		; ===== RIGHT COLUMN: SECONDS TIMERS =====
		Gui, Main:Add, Text, x500 y%yPosSeconds% w200, %groupName% (Seconds):

		; Open After (Seconds)
		checkY3 := yPosSeconds + 25
		Gui, Main:Add, Text, x520 y%checkY3%, Open After:
		Gui, Main:Add, Edit, x620 y%checkY3% w80 vOpenAfterSecsColor%A_Index% +0x200, %openAfterSecsColor%

		; Colored text button for Open After Secs Color - FIXED: White text
		Gui, Main:Font, s9 Bold cFFFFFF  ; WHITE TEXT
		Gui, Main:Add, Text, x710 y%checkY3% w60 h24 +0x200 +Border gSelectColorHandler vColorTextOpenAfterSecs%A_Index% Center, Color
		Gui, Main:Font, s10 Normal cFFFFFF

		; Color name display (bold and colored)
		openSecsColorName := GetColorName(openAfterSecsColor)
		Gui, Main:Font, s10 Bold c%openAfterSecsColor%
		Gui, Main:Add, Text, x780 y%checkY3%+2 w100 vOpenAfterSecsColorName%A_Index%, %openSecsColorName%
		Gui, Main:Font, s10 Normal cFFFFFF

		; Close After (Seconds)
		checkY4 := yPosSeconds + 50
		Gui, Main:Add, Text, x520 y%checkY4%, Close After:
		Gui, Main:Add, Edit, x620 y%checkY4% w80 vCloseAfterSecsColor%A_Index% +0x200, %closeAfterSecsColor%

		; Colored text button for Close After Secs Color - FIXED: White text
		Gui, Main:Font, s9 Bold cFFFFFF  ; WHITE TEXT
		Gui, Main:Add, Text, x710 y%checkY4% w60 h24 +0x200 +Border gSelectColorHandler vColorTextCloseAfterSecs%A_Index% Center, Color
		Gui, Main:Font, s10 Normal cFFFFFF

		; Color name display (bold and colored)
		closeSecsColorName := GetColorName(closeAfterSecsColor)
		Gui, Main:Font, s10 Bold c%closeAfterSecsColor%
		Gui, Main:Add, Text, x780 y%checkY4%+2 w100 vCloseAfterSecsColorName%A_Index%, %closeSecsColorName%
		Gui, Main:Font, s10 Normal cFFFFFF
		
		; Increment positions for next group
		yPosMinutes += 85
		yPosSeconds += 85
	}
	
	
	; ============================================
	; TAB 5: ADDITIONAL SETTINGS
	; ============================================
    Gui, Main:Tab, 5

    Gui, Main:Font, s10 Bold cLime, Segoe UI
    Gui, Main:Add, Text, x20 y50 w960 h30 Center, ADDITIONAL SETTINGS
    Gui, Main:Font, s10 Normal cFFFFFF, Segoe UI

    ; Quick Launcher Hotkey
    Gui, Main:Add, Text, x20 y100, Quick Launcher Hotkey:
    Gui, Main:Add, Edit, x250 y95 w150 vQuickLauncherHotkey, %QuickLauncherHotkey%
    Gui, Main:Font, s8 cGray
    Gui, Main:Add, Text, x410 y100, (e.g., !i = Alt+I, ^!q = Ctrl+Alt+Q)
    Gui, Main:Font, s10 cFFFFFF

    ; Toggle Settings Hotkey
    Gui, Main:Add, Text, x20 y140, Toggle Setting Hotkey:
    Gui, Main:Add, Edit, x250 y135 w150 vToggleSettingsHotkey, %ToggleSettingsHotkey%
    Gui, Main:Font, s8 cGray
    Gui, Main:Add, Text, x410 y140, (e.g., ^F11 = Ctrl+F11, ^!s = Ctrl+Alt+S)
    Gui, Main:Font, s10 cFFFFFF

    ; Quick Timer Hotkey
    Gui, Main:Add, Text, x20 y180, Quick Timer Hotkey:
    Gui, Main:Add, Edit, x250 y175 w150 vTimerHotkey, %TimerHotkey%
    Gui, Main:Font, s8 cGray
    Gui, Main:Add, Text, x410 y180, (e.g., !F10 = Alt+F10)
    Gui, Main:Font, s10 cFFFFFF

    ; Titlebar removal checkboxes
    Gui, Main:Add, Checkbox, x20 y220 vRemoveLauncherTitlebar, Remove title bar from quick launcher
    GuiControl, Main:, RemoveLauncherTitlebar, %RemoveLauncherTitlebar%

    Gui, Main:Add, Checkbox, x20 y260 vRemoveSettingsTitlebar, Remove titlebar from setting window
    GuiControl, Main:, RemoveSettingsTitlebar, %RemoveSettingsTitlebar%

    Gui, Main:Add, Checkbox, x20 y300 vRemoveTimerTitlebar, Remove titlebar from quick timer
    GuiControl, Main:, RemoveTimerTitlebar, %RemoveTimerTitlebar%

    ; Timer options
    Gui, Main:Add, Checkbox, x20 y340 vTimerAlwaysOnTop, Make quick timer always on top
    GuiControl, Main:, TimerAlwaysOnTop, %TimerPinned%

    Gui, Main:Add, Checkbox, x20 y380 vTimerBoldFont, Make timer text bold
    GuiControl, Main:, TimerBoldFont, %TimerFontBold%

    ; Open Logs Folder button
    Gui, Main:Add, Button, x20 y420 w200 h35 gOpenLogsFolder HwndHList10, Open Logs Folder
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList10, "Str", "DarkMode_Explorer", "Ptr", 0)

    ; Note about hotkeys
    Gui, Main:Font, s10 Bold cLime
    Gui, Main:Add, Text, x40 y480 w600, NOTE: After changing hotkeys, click "Save Settings" to apply changes.
    Gui, Main:Font, s10 Normal cFFFFFF
	
    ; Save Settings button with copyright (outside tabs)
    Gui, Main:Tab
    
    ; Add copyright text
    Gui, Main:Font, s10 Bold c00FFFF  ; Cyan color, bold, size 14
    Gui, Main:Add, Text, x20 y850 w350 h35, Copyright : AndrianAngel (Github) 2026
    Gui, Main:Font, s10 Normal cFFFFFF  ; Reset font
    
    ; Save Settings button
    Gui, Main:Add, Button, x410 y840 w120 h35 gSaveSettings HwndHList3, Save Settings
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList3, "Str", "DarkMode_Explorer", "Ptr", 0)
	
    Gui, Main:Show, w1000 h890, Easy Folder Group Manager
}

OpenLogsFolder:
    Global LogFile
    SplitPath, LogFile, , logDir
    if (FileExist(logDir))
        Run, explorer.exe "%logDir%"
    else
        Run, explorer.exe "%A_ScriptDir%"
Return


; ============================================
; TOGGLE GUI VISIBILITY
; ============================================

ToggleGui() {
    Global GuiVisible
    
    if (GuiVisible) {
        Gui, Main:Destroy
        GuiVisible := False
    } else {
        CreateGui()
        GuiVisible := True
    }
}

; ============================================
; LABELS
; ============================================

TabChanged:
    ; This label is called when tabs are switched
    ; You can add tab-specific logic here if needed
Return


PauseGroupContext:
    Groups[CurrentContextGroup].IsPaused := 1
    ; Refresh GUI to show PAUSED status
    if (GuiVisible) {
        Gui, Main:Destroy
        CreateGui()
    }
Return

ResumeGroupContext:
    Groups[CurrentContextGroup].IsPaused := 0
    ; Refresh GUI to show ACTIVE status
    if (GuiVisible) {
        Gui, Main:Destroy
        CreateGui()
    }
Return

DeleteGroupContext:
    DeleteSelectedGroup()
Return

; ============================================
; DARK THEME INPUT FIELDS
; ============================================

MakeDarkEdit(GuiName, ControlVar) {
    GuiControlGet, hwnd, %GuiName%:Hwnd, %ControlVar%
    DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
}

; ============================================
; Group Dialog Function
; ============================================

ShowAddGroupDialog() {
    Global Groups, MaxGroups, IniFile
    
    ; Find first empty slot
    emptySlot := 0
    Loop, %MaxGroups% {
        if (Groups[A_Index].Name = "") {
            emptySlot := A_Index
            Break
        }
    }
    
    if (emptySlot = 0) {
        MsgBox, Maximum number of groups reached (%MaxGroups%)!
        Return
    }
    
    ; Create dialog with dark theme
    Gui, AddGroup:New
    Gui, AddGroup:Color, 1E1E1E
    Gui, AddGroup:Font, s10 cFFFFFF, Segoe UI
    
    Gui, AddGroup:Add, Text, x20 y20 w200, Group Name:
    Gui, AddGroup:Add, Edit, x20 y45 w360 h30 vNewGroupName Background2E2E2E cFFFFFF
    
    Gui, AddGroup:Add, Text, x20 y80 w200, Hotkey (e.g., ^!F1):
    Gui, AddGroup:Add, Edit, x20 y105 w360 h30 vNewGroupHotkey Background2E2E2E cFFFFFF
    
    Gui, AddGroup:Add, Text, x20 y140 w360, Folders (one per line):
    Gui, AddGroup:Add, Edit, x20 y165 w360 h150 vNewGroupFolders Multi Background2E2E2E cFFFFFF
    
    Gui, AddGroup:Add, Button, x20 y325 w100 h30 gBrowseFolder, Browse...
    Gui, AddGroup:Add, Button, x150 y370 w100 h30 gSaveNewGroup, Save
    Gui, AddGroup:Add, Button, x260 y370 w100 h30 gCancelAddGroup, Cancel
    
    Gui, AddGroup:Show, w400 h420, Add New Group
}

BrowseFolder:
    ; Modern folder picker
    Shell := ComObjCreate("Shell.Application")
    Folder := Shell.BrowseForFolder(0, "Select a folder to add", 0x50, 0)
    
    if (Folder) {
        SelectedFolder := Folder.Self.Path
        GuiControlGet, currentFolders, AddGroup:, NewGroupFolders
        if (currentFolders != "")
            currentFolders .= "`n"
        currentFolders .= SelectedFolder
        GuiControl, AddGroup:, NewGroupFolders, %currentFolders%
    }
Return

; ============================================
; Save New Group Function
; ============================================

SaveNewGroup:
    Global Groups, MaxGroups, IniFile, GuiVisible
    
    Gui, AddGroup:Submit, NoHide
    
    ; Validate input
    if (NewGroupName = "") {
        MsgBox, Please enter a group name!
        Return
    }
    
    if (NewGroupFolders = "") {
        MsgBox, Please add at least one folder!
        Return
    }
    
    ; Find empty slot
    emptySlot := 0
    Loop, %MaxGroups% {
        if (Groups[A_Index].Name = "") {
            emptySlot := A_Index
            Break
        }
    }
    
    ; Parse folders
    folders := []
    Loop, Parse, NewGroupFolders, `n, `r
    {
        if (A_LoopField != "")
            folders.Push(Trim(A_LoopField))
    }
    
    ; Create new group
    Groups[emptySlot] := {Name: NewGroupName
        , Hotkey: NewGroupHotkey
        , Folders: folders
        , Width: 800
        , Height: 600
        , StackFolders: 0
        , MinimizeAll: 0
        , SpecificSize: 0
        , DualVertical: 0
        , DualHorizontal: 0
        , HistoryLog: 0
        , OpenAfterEnabled: 0
        , OpenAfterMins: 0
        , CloseAfterEnabled: 0
        , CloseAfterMins: 0
        , LastOpenTime: ""}
    
    ; Save to INI
    IniWrite, %NewGroupName%, %IniFile%, Group%emptySlot%, Name
    IniWrite, %NewGroupHotkey%, %IniFile%, Group%emptySlot%, Hotkey
    
    folderList := ""
    for idx, folder in folders
        folderList .= folder . "|"
    IniWrite, %folderList%, %IniFile%, Group%emptySlot%, Folders
    
    ; Write default values
    IniWrite, 800, %IniFile%, Group%emptySlot%, Width
    IniWrite, 600, %IniFile%, Group%emptySlot%, Height
    IniWrite, 0, %IniFile%, Group%emptySlot%, StackFolders
    IniWrite, 0, %IniFile%, Group%emptySlot%, MinimizeAll
    IniWrite, 0, %IniFile%, Group%emptySlot%, SpecificSize
    IniWrite, 0, %IniFile%, Group%emptySlot%, DualVertical
    IniWrite, 0, %IniFile%, Group%emptySlot%, DualHorizontal
    IniWrite, 0, %IniFile%, Group%emptySlot%, HistoryLog
    IniWrite, 0, %IniFile%, Group%emptySlot%, OpenAfterEnabled
    IniWrite, 0, %IniFile%, Group%emptySlot%, OpenAfterMins
    IniWrite, 0, %IniFile%, Group%emptySlot%, CloseAfterEnabled
    IniWrite, 0, %IniFile%, Group%emptySlot%, CloseAfterMins
    
    ; Setup hotkey
    SetupHotkeys()
    
    ; Close dialog
    Gui, AddGroup:Destroy
    
    ; Refresh main GUI if visible
    if (GuiVisible) {
        Gui, Main:Destroy
        CreateGui()
    }
    
    MsgBox, Group "%NewGroupName%" added successfully!
Return

SaveGroupToIni(groupNum) {
    Global Groups, IniFile
    
    if (Groups[groupNum].Name = "")
        Return
    
    group := Groups[groupNum]
    
    ; Save all group properties to INI
    IniWrite, % group.Name, %IniFile%, Group%groupNum%, Name
    IniWrite, % group.Hotkey, %IniFile%, Group%groupNum%, Hotkey
    
    ; Save folders
    folderList := ""
    for idx, folder in group.Folders
        folderList .= folder . "|"
    IniWrite, %folderList%, %IniFile%, Group%groupNum%, Folders
    
    ; Save other properties
    IniWrite, % group.Width, %IniFile%, Group%groupNum%, Width
    IniWrite, % group.Height, %IniFile%, Group%groupNum%, Height
    IniWrite, % group.StackFolders, %IniFile%, Group%groupNum%, StackFolders
    IniWrite, % group.MinimizeAll, %IniFile%, Group%groupNum%, MinimizeAll
    IniWrite, % group.SpecificSize, %IniFile%, Group%groupNum%, SpecificSize
    IniWrite, % group.DualVertical, %IniFile%, Group%groupNum%, DualVertical
    IniWrite, % group.DualHorizontal, %IniFile%, Group%groupNum%, DualHorizontal
    IniWrite, % group.HistoryLog, %IniFile%, Group%groupNum%, HistoryLog
    IniWrite, % group.OpenAfterEnabled, %IniFile%, Group%groupNum%, OpenAfterEnabled
    IniWrite, % group.OpenAfterMins, %IniFile%, Group%groupNum%, OpenAfterMins
    IniWrite, % group.CloseAfterEnabled, %IniFile%, Group%groupNum%, CloseAfterEnabled
    IniWrite, % group.CloseAfterMins, %IniFile%, Group%groupNum%, CloseAfterMins
    IniWrite, % group.OpenAfterSecs, %IniFile%, Group%groupNum%, OpenAfterSecs
    IniWrite, % group.CloseAfterSecs, %IniFile%, Group%groupNum%, CloseAfterSecs
    IniWrite, % group.OpenAfterSecsEnabled, %IniFile%, Group%groupNum%, OpenAfterSecsEnabled
    IniWrite, % group.CloseAfterSecsEnabled, %IniFile%, Group%groupNum%, CloseAfterSecsEnabled
    IniWrite, % group.IsPaused, %IniFile%, Group%groupNum%, IsPaused
}


;Cancel Button Handler

CancelAddGroup:
    Gui, AddGroup:Destroy
Return

AddGroupGuiClose:
    Gui, AddGroup:Destroy
Return

;Delete Group Functionality

DeleteSelectedGroup() {
    Global Groups, IniFile, GuiVisible
    
    Gui, Main:Default
    RowNumber := LV_GetNext(0)
    
    if (RowNumber = 0) {
        MsgBox, Please select a group to delete!
        Return
    }
    
    LV_GetText(groupName, RowNumber, 1)
    
    MsgBox, 4, Delete Group, Are you sure you want to delete "%groupName%"?
    IfMsgBox No
        Return
    
    ; Find the group index
    Loop, %MaxGroups% {
        if (Groups[A_Index].Name = groupName) {
            ; Clear from memory
            Groups[A_Index] := {Name: "", Hotkey: "", Folders: [], Width: 800, Height: 600
                , StackFolders: 0, MinimizeAll: 0, SpecificSize: 0
                , DualVertical: 0, DualHorizontal: 0, HistoryLog: 0
                , OpenAfterEnabled: 0, OpenAfterMins: 0
                , CloseAfterEnabled: 0, CloseAfterMins: 0
                , LastOpenTime: ""}
            
            ; Delete from INI
            IniDelete, %IniFile%, Group%A_Index%
            
            Break
        }
    }
    
    ; Setup hotkeys again
    SetupHotkeys()
    
    ; Refresh GUI
    if (GuiVisible) {
        Gui, Main:Destroy
        CreateGui()
    }
}

LoadGroupsIntoListView() {
    Global
    
    Gui, Main:Default
    yPos := 90
    
    Loop, %MaxGroups% {
        groupNum := A_Index
        
        ; Skip if group has no name (not configured)
        if (Groups[groupNum].Name = "")
            Continue
        
        groupName := Groups[groupNum].Name
        folderCount := Groups[groupNum].Folders.MaxIndex()
        if (folderCount = "")
            folderCount := 0
        
        hotkey := Groups[groupNum].Hotkey != "" ? Groups[groupNum].Hotkey : "(NO)"
        isPaused := Groups[groupNum].IsPaused
        
        ; Determine status and color
        if (isPaused) {
            status := "PAUSED"
            statusColor := "cRed"
        } else if (Groups[groupNum].Hotkey != "") {
            status := "ACTIVE"
            statusColor := "cLime"
        } else {
            status := "NULL"
            statusColor := "cWhite"
        }
        
        ; Determine hotkey color
        hotkeyColor := (hotkey = "(NO)") ? "cWhite" : "cYellow"
        
        ; Determine group name color
        defaultName := "GROUP " . Chr(64 + groupNum)
        nameColor := (groupName = defaultName) ? "cWhite" : "c00BFFF"  ; Sky blue
        
        ; Create info box
        Gui, Main:Font, s14 Bold, Arial Black
                
        Gui, Main:Font, s14 Bold, Arial Black
        Gui, Main:Add, Text, x20 y%yPos% w180 h35 Center Background333333 %nameColor%, %groupName%
        
        Gui, Main:Font, s14 Bold, Arial Black
        folderColor := (folderCount = 0) ? "cWhite" : "cFFB6C1"  ; Light pink if folders exist
		Gui, Main:Add, Text, x220 y%yPos% w150 h35 Center Background333333 %folderColor%, %folderCount% FOLDERS
        
        Gui, Main:Font, s14 Bold, Arial Black
        Gui, Main:Add, Text, x380 y%yPos% w180 h35 Center Background333333 %hotkeyColor%, HOTKEY: %hotkey%
        
        Gui, Main:Font, s14 Bold, Arial Black
        Gui, Main:Add, Text, x545 y%yPos% w140 h35 Center Background333333 %statusColor%, %status%
		
        
        Gui, Main:Font, s10 Normal, Segoe UI
        
        ; Edit , Pause and Default buttons
		
		pauseText := (Groups[groupNum].IsPaused) ? "Resume" : "Pause"
		pauseColor := (Groups[groupNum].IsPaused) ? "cLime" : "cRed"
		Gui, Main:Add, Button, x690 y%yPos% w80 h35 gTogglePauseBtn%groupNum% vPauseBtn%groupNum% HwndHPause%groupNum% %pauseColor%, %pauseText%
		DllCall("UxTheme\SetWindowTheme", "Ptr", hPause%groupNum%, "Str", "DarkMode_Explorer", "Ptr", 0)
		
        Gui, Main:Add, Button, x780 y%yPos% w80 h35 gEditGroupBtn vEditBtn%groupNum% HwndHList1, Edit
        DllCall("UxTheme\SetWindowTheme", "Ptr", hList1, "Str", "DarkMode_Explorer", "Ptr", 0)
        
		Gui, Main:Add, Button, x870 y%yPos% w80 h35 gDefaultGroupBtn vDefaultBtn%groupNum% HwndHDefault%groupNum%, Default
		DllCall("UxTheme\SetWindowTheme", "Ptr", hDefault%groupNum%, "Str", "DarkMode_Explorer", "Ptr", 0)
		 
		yPos += 71
		
    }
}

TogglePauseBtn1:
    TogglePause(1)
Return
TogglePauseBtn2:
    TogglePause(2)
Return
TogglePauseBtn3:
    TogglePause(3)
Return
TogglePauseBtn4:
    TogglePause(4)
Return
TogglePauseBtn5:
    TogglePause(5)
Return
TogglePauseBtn6:
    TogglePause(6)
Return
TogglePauseBtn7:
    TogglePause(7)
Return
TogglePauseBtn8:
    TogglePause(8)
Return

TogglePause(index) {
    Global Groups, GuiVisible
    Groups[index].IsPaused := !Groups[index].IsPaused
    if (GuiVisible) {
        Gui, Main:Destroy
        CreateGui()
    }
}

SaveSettings() {
    Global IniFile, Groups, MaxGroups, TimerColors, TimerPinned, TimerFontBold

    Gui, Main:Submit, NoHide

    Loop, %MaxGroups% {
        if (Groups[A_Index].Name != "") {
            IniWrite, % Groups[A_Index].Name,   %IniFile%, Group%A_Index%, Name
            IniWrite, % Groups[A_Index].Hotkey, %IniFile%, Group%A_Index%, Hotkey

            folderList := ""
            for idx, folder in Groups[A_Index].Folders
                folderList .= folder . "|"
            IniWrite, %folderList%, %IniFile%, Group%A_Index%, Folders

            ; Read GUI controls with Main: prefix
            GuiControlGet, stack,        Main:, StackFolders%A_Index%
            GuiControlGet, minimize,     Main:, MinimizeAll%A_Index%
            GuiControlGet, specificSize, Main:, SpecificSize%A_Index%
            GuiControlGet, wEdit,        Main:, FolderWidth%A_Index%
            GuiControlGet, hEdit,        Main:, FolderHeight%A_Index%

            GuiControlGet, openAfterEn,  Main:, OpenAfterEnabled%A_Index%
            GuiControlGet, openAfterMin, Main:, OpenAfterMins%A_Index%
            GuiControlGet, closeAfterEn, Main:, CloseAfterEnabled%A_Index%
            GuiControlGet, closeAfterMin, Main:, CloseAfterMins%A_Index%

            GuiControlGet, dualV,        Main:, DualVertical%A_Index%
            GuiControlGet, dualH,        Main:, DualHorizontal%A_Index%
            GuiControlGet, histLog,      Main:, HistoryLog%A_Index%
			
			GuiControlGet, openAfterSec, Main:, OpenAfterSecs%A_Index%
			GuiControlGet, closeAfterSec, Main:, CloseAfterSecs%A_Index%
			
			GuiControlGet, qLauncherHK, Main:, QuickLauncherHotkey
			GuiControlGet, tSettingsHK, Main:, ToggleSettingsHotkey
			GuiControlGet, removeTitlebar, Main:, RemoveLauncherTitlebar
			GuiControlGet, removeSettingsTB, Main:, RemoveSettingsTitlebar
			GuiControlGet, removeTimerTB, Main:, RemoveTimerTitlebar
			
			GuiControlGet, qTimerHK, Main:, TimerHotkey
			
			GuiControlGet, timerAlwaysOnTop, Main:, TimerAlwaysOnTop
			GuiControlGet, timerBoldFont, Main:, TimerBoldFont
			
			; Save timer colors
			GuiControlGet, openAfterCol, Main:, OpenAfterColor%A_Index%
			GuiControlGet, closeAfterCol, Main:, CloseAfterColor%A_Index%
			GuiControlGet, openAfterSecsCol, Main:, OpenAfterSecsColor%A_Index%
			GuiControlGet, closeAfterSecsCol, Main:, CloseAfterSecsColor%A_Index%

			; Update color previews in GUI
			GuiControl, Main:+Background%openAfterCol%, OpenAfterPrev%A_Index%
			GuiControl, Main:+Background%closeAfterCol%, CloseAfterPrev%A_Index%
			GuiControl, Main:+Background%openAfterSecsCol%, OpenAfterSecsPrev%A_Index%
			GuiControl, Main:+Background%closeAfterSecsCol%, CloseAfterSecsPrev%A_Index%

            ; Write to INI
            IniWrite, % stack,        %IniFile%, Group%A_Index%, StackFolders
            IniWrite, % minimize,     %IniFile%, Group%A_Index%, MinimizeAll
            IniWrite, % specificSize, %IniFile%, Group%A_Index%, SpecificSize
            IniWrite, % wEdit,        %IniFile%, Group%A_Index%, Width
            IniWrite, % hEdit,        %IniFile%, Group%A_Index%, Height

            IniWrite, % dualV,        %IniFile%, Group%A_Index%, DualVertical
            IniWrite, % dualH,        %IniFile%, Group%A_Index%, DualHorizontal
            IniWrite, % histLog,      %IniFile%, Group%A_Index%, HistoryLog

            IniWrite, % openAfterEn,  %IniFile%, Group%A_Index%, OpenAfterEnabled
            IniWrite, % openAfterMin, %IniFile%, Group%A_Index%, OpenAfterMins
            IniWrite, % closeAfterEn, %IniFile%, Group%A_Index%, CloseAfterEnabled
            IniWrite, % closeAfterMin,%IniFile%, Group%A_Index%, CloseAfterMins
			
			IniWrite, % openAfterSec, %IniFile%, Group%A_Index%, OpenAfterSecs
			IniWrite, % closeAfterSec, %IniFile%, Group%A_Index%, CloseAfterSecs
			
			IniWrite, %qLauncherHK%, %IniFile%, AdditionalSettings, QuickLauncherHotkey
			IniWrite, %tSettingsHK%, %IniFile%, AdditionalSettings, ToggleSettingsHotkey
			IniWrite, %removeTitlebar%, %IniFile%, AdditionalSettings, RemoveLauncherTitlebar
			IniWrite, %removeSettingsTB%, %IniFile%, AdditionalSettings, RemoveSettingsTitlebar
			IniWrite, %removeTimerTB%, %IniFile%, AdditionalSettings, RemoveTimerTitlebar

			IniWrite, % openAfterSecsEn, %IniFile%, Group%A_Index%, OpenAfterSecsEnabled
			IniWrite, % closeAfterSecsEn, %IniFile%, Group%A_Index%, CloseAfterSecsEnabled
			IniWrite, %qTimerHK%, %IniFile%, AdditionalSettings, TimerHotkey
			
			; Save colors
            IniWrite, %openAfterCol%, %IniFile%, Group%A_Index%, OpenAfterColor
            IniWrite, %closeAfterCol%, %IniFile%, Group%A_Index%, CloseAfterColor
            IniWrite, %openAfterSecsCol%, %IniFile%, Group%A_Index%, OpenAfterSecsColor
            IniWrite, %closeAfterSecsCol%, %IniFile%, Group%A_Index%, CloseAfterSecsColor

			IniWrite, %timerAlwaysOnTop%, %IniFile%, AdditionalSettings, TimerPinned
			IniWrite, %timerBoldFont%, %IniFile%, AdditionalSettings, TimerFontBold			

            ; Update in-memory
            Groups[A_Index].StackFolders      := stack
            Groups[A_Index].MinimizeAll       := minimize
            Groups[A_Index].SpecificSize      := specificSize
            Groups[A_Index].Width             := wEdit
            Groups[A_Index].Height            := hEdit
            Groups[A_Index].DualVertical      := dualV
            Groups[A_Index].DualHorizontal    := dualH
            Groups[A_Index].HistoryLog        := histLog
            Groups[A_Index].OpenAfterEnabled  := openAfterEn
            Groups[A_Index].OpenAfterMins     := openAfterMin
            Groups[A_Index].CloseAfterEnabled := closeAfterEn
            Groups[A_Index].CloseAfterMins    := closeAfterMin
			Groups[A_Index].OpenAfterSecs := openAfterSec
			Groups[A_Index].CloseAfterSecs := closeAfterSec
			Groups[A_Index].OpenAfterSecsEnabled := openAfterSecsEn
			Groups[A_Index].CloseAfterSecsEnabled := closeAfterSecsEn
			
			; Update TimerColors array
			minOpenTimer := A_Index
			minCloseTimer := A_Index + 8
			secOpenTimer := A_Index + 16
			secCloseTimer := A_Index + 24

			TimerColors[minOpenTimer] := openAfterCol
			TimerColors[minCloseTimer] := closeAfterCol
			TimerColors[secOpenTimer] := openAfterSecsCol
			TimerColors[secCloseTimer] := closeAfterSecsCol
			
			QuickLauncherHotkey := qLauncherHK
			ToggleSettingsHotkey := tSettingsHK
			RemoveLauncherTitlebar := removeTitlebar
			RemoveSettingsTitlebar := removeSettingsTB
			
			TimerHotkey := qTimerHK
			RemoveTimerTitlebar := removeTimerTB
			
			TimerPinned := timerAlwaysOnTop
			TimerFontBold := timerBoldFont
			
			; Update timer GUI if visible
			if (TimerVisible) {
				if (TimerPinned) {
					Gui, TimerGUI:+AlwaysOnTop
				} else {
					Gui, TimerGUI:-AlwaysOnTop
				}
				ApplyTimerFontStyle()
			}
			
			; Update timer GUI colors if visible
			if (TimerVisible) {
				UpdateTimerGuiColors()
			}
			
			; Reapply hotkeys with new settings
			SetupHotkeys()
        }
    }

    MsgBox, Settings saved successfully!
}

MainGuiClose:
    Gui, Main:Destroy
    GuiVisible := False
Return

; Force update timer displays if timer GUI is visible
if (TimerVisible) {
    UpdateTimerDisplay(minOpenTimer)
    UpdateTimerDisplay(minCloseTimer)
    UpdateTimerDisplay(secOpenTimer)
    UpdateTimerDisplay(secCloseTimer)
}

;--------------------------Buttons-----------------------------------

EditGroupBtn:
    GuiControlGet, btnName, Name, %A_GuiControl%
    groupIndex := RegExReplace(btnName, "\D")
    ShowEditGroupDialog(groupIndex)
Return

DefaultGroupBtn:
    GuiControlGet, btnName, Name, %A_GuiControl%
    groupIndex := RegExReplace(btnName, "\D")
    ResetGroupToDefault(groupIndex)
Return

ResetGroupToDefault(index) {
    Global Groups, IniFile, GuiVisible
    
    groupName := Groups[index].Name
    
    MsgBox, 4, Reset Group, Are you sure you want to reset "%groupName%" to default?
    IfMsgBox No
        Return
    
    defaultName := "GROUP " . Chr(64 + index)
    
    ; Reset to defaults
    Groups[index] := {Name: defaultName, Hotkey: "", Folders: [], Width: 800, Height: 600
        , StackFolders: 0, MinimizeAll: 0, SpecificSize: 0
        , DualVertical: 0, DualHorizontal: 0, HistoryLog: 0
        , OpenAfterEnabled: 0, OpenAfterMins: 0, OpenAfterSecs: 0
        , CloseAfterEnabled: 0, CloseAfterMins: 0, CloseAfterSecs: 0
        , OpenAfterSecsEnabled: 0, CloseAfterSecsEnabled: 0
        , LastOpenTime: "", IsPaused: 0}
    
    ; Write defaults to INI
    IniWrite, %defaultName%, %IniFile%, Group%index%, Name
	IniWrite, % "", %IniFile%, Group%index%, Hotkey
	IniWrite, % "", %IniFile%, Group%index%, Folders
    IniWrite, 800, %IniFile%, Group%index%, Width
    IniWrite, 600, %IniFile%, Group%index%, Height
    IniWrite, 0, %IniFile%, Group%index%, StackFolders
    IniWrite, 0, %IniFile%, Group%index%, MinimizeAll
    IniWrite, 0, %IniFile%, Group%index%, SpecificSize
    
    SetupHotkeys()
    
    if (GuiVisible) {
        Gui, Main:Destroy
        CreateGui()
    }
}

ShowEditGroupDialog(groupIndex) {
    Global Groups, IniFile
    
    group := Groups[groupIndex]
    
    Gui, EditGroup:New
    Gui, EditGroup:Color, 1E1E1E
    Gui, EditGroup:Font, s10 cFFFFFF, Segoe UI
    
    Gui, EditGroup:Add, Text, x20 y20 w200, Editing Group %groupIndex%
	
    Gui, EditGroup:Add, Text, x20 y50 w200, Group Name:
    Gui, EditGroup:Add, Edit, x20 y75 w360 h30 vEditGroupName Background2E2E2E cFFFFFF, % group.Name
    
    Gui, EditGroup:Add, Text, x20 y110 w200, Hotkey (e.g., ^!F1):
    Gui, EditGroup:Add, Edit, x20 y135 w360 h30 vEditGroupHotkey Background2E2E2E cFFFFFF, % group.Hotkey
    
    Gui, EditGroup:Add, Text, x20 y170 w360, Folders (one per line):
    
    folderText := ""
    for idx, folder in group.Folders
        folderText .= folder . "`n"
    
    Gui, EditGroup:Add, Edit, x20 y195 w360 h150 vEditGroupFolders Multi Background2E2E2E HwndHList8 cFFFFFF, %folderText%
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList8, "Str", "DarkMode_Explorer", "Ptr", 0)
	
    Gui, EditGroup:Add, Button, x20 y355 w100 h30 gBrowseFolderEdit HwndHList6, Browse...
	DllCall("UxTheme\SetWindowTheme", "Ptr", hList6, "Str", "DarkMode_Explorer", "Ptr", 0)
	
	Gui, EditGroup:Add, Button, x130 y355 w100 h30 gPasteFoldersEdit HwndHList9, PASTE
	DllCall("UxTheme\SetWindowTheme", "Ptr", hList9, "Str", "DarkMode_Explorer", "Ptr", 0)
	
    Gui, EditGroup:Add, Button, x20 y400 w100 h30 gSaveEditedGroup HwndHList4, Save
	DllCall("UxTheme\SetWindowTheme", "Ptr", hList4, "Str", "DarkMode_Explorer", "Ptr", 0)
	
    Gui, EditGroup:Add, Button, x130 y400 w100 h30 gCancelEditGroup HwndHList5, Cancel
    DllCall("UxTheme\SetWindowTheme", "Ptr", hList5, "Str", "DarkMode_Explorer", "Ptr", 0)
	
    EditingGroupIndex := groupIndex
    
    Gui, EditGroup:Show, w400 h450, Edit Group %groupIndex%
}

BrowseFolderEdit:
    Shell := ComObjCreate("Shell.Application")
    Folder := Shell.BrowseForFolder(0, "Select a folder", 0x50, 0)
    
    if (Folder) {
        SelectedFolder := Folder.Self.Path
        GuiControlGet, currentFolders, EditGroup:, EditGroupFolders
        if (currentFolders != "")
            currentFolders .= "`n"
        currentFolders .= SelectedFolder
        GuiControl, EditGroup:, EditGroupFolders, %currentFolders%
    }
Return

PasteFoldersEdit:
    clipboardContent := Clipboard
    GuiControlGet, currentFolders, EditGroup:, EditGroupFolders
    if (currentFolders != "")
        currentFolders .= "`n"
    currentFolders .= clipboardContent
    GuiControl, EditGroup:, EditGroupFolders, %currentFolders%
Return

SaveEditedGroup:
    Global Groups, IniFile, GuiVisible, EditingGroupIndex
    
    Gui, EditGroup:Submit, NoHide
    
    folders := []
    Loop, Parse, EditGroupFolders, `n, `r
    {
        if (A_LoopField != "")
            folders.Push(Trim(A_LoopField))
    }
    
    Groups[EditingGroupIndex].Name := EditGroupName
    Groups[EditingGroupIndex].Hotkey := EditGroupHotkey
    Groups[EditingGroupIndex].Folders := folders
    
    IniWrite, %EditGroupName%, %IniFile%, Group%EditingGroupIndex%, Name
    IniWrite, %EditGroupHotkey%, %IniFile%, Group%EditingGroupIndex%, Hotkey
    
    folderList := ""
    for idx, folder in folders
        folderList .= folder . "|"
    IniWrite, %folderList%, %IniFile%, Group%EditingGroupIndex%, Folders
    
    SetupHotkeys()
    Gui, EditGroup:Destroy
    
    if (GuiVisible) {
        Gui, Main:Destroy
        CreateGui()
    }
Return

CancelEditGroup:
    Gui, EditGroup:Destroy
Return

EditGroupGuiClose:
    Gui, EditGroup:Destroy
Return

; ============================================
; SETTINGS MANAGEMENT
; ============================================


LoadSettings() {
    Global IniFile, MaxGroups, Groups
    
    ; Initialize all groups with default names
    Loop, %MaxGroups% {
        defaultName := "GROUP " . Chr(64 + A_Index)  ; A=65, so GROUP A, GROUP B, etc.
        Groups[A_Index] := {Name: defaultName, Hotkey: "", Folders: [], Width: 800, Height: 600
            , StackFolders: 0, MinimizeAll: 0, SpecificSize: 0
            , DualVertical: 0, DualHorizontal: 0, HistoryLog: 0
            , OpenAfterEnabled: 0, OpenAfterMins: 0
            , CloseAfterEnabled: 0, CloseAfterMins: 0
            , LastOpenTime: "", IsPaused: 0}
		Groups[A_Index] := {Name: defaultName, Hotkey: "", Folders: [], Width: 800, Height: 600
			, StackFolders: 0, MinimizeAll: 0, SpecificSize: 0
			, DualVertical: 0, DualHorizontal: 0, HistoryLog: 0
			, OpenAfterEnabled: 0, OpenAfterMins: 0, OpenAfterSecs: 0
			, CloseAfterEnabled: 0, CloseAfterMins: 0, CloseAfterSecs: 0
			, LastOpenTime: "", IsPaused: 0}
    }
    
    ; Check if INI file exists and override with saved data
    IfNotExist, %IniFile%
        Return
    
    ; Rest of your existing INI reading code...
    ; Only override the Name if it exists in INI
    Loop, %MaxGroups% {
        IniRead, groupName, %IniFile%, Group%A_Index%, Name, ERROR
        
        if (groupName != "ERROR" && groupName != "") {
            IniRead, hotkey,           %IniFile%, Group%A_Index%, Hotkey, ""
            IniRead, folderList,       %IniFile%, Group%A_Index%, Folders, ""
            IniRead, width,            %IniFile%, Group%A_Index%, Width, 800
            IniRead, height,           %IniFile%, Group%A_Index%, Height, 600

            ; --- Advanced flags ---
            IniRead, stackFolders,     %IniFile%, Group%A_Index%, StackFolders, 0
            IniRead, minimizeAll,      %IniFile%, Group%A_Index%, MinimizeAll, 0
            IniRead, specificSize,     %IniFile%, Group%A_Index%, SpecificSize, 0
            IniRead, dualVertical,     %IniFile%, Group%A_Index%, DualVertical, 0
            IniRead, dualHorizontal,   %IniFile%, Group%A_Index%, DualHorizontal, 0
            IniRead, historyLog,       %IniFile%, Group%A_Index%, HistoryLog, 0

            ; --- Scheduling ---
            IniRead, openAfterEnabled, %IniFile%, Group%A_Index%, OpenAfterEnabled, 0
            IniRead, openAfterMins,    %IniFile%, Group%A_Index%, OpenAfterMins, 0
            IniRead, closeAfterEnabled,%IniFile%, Group%A_Index%, CloseAfterEnabled, 0
            IniRead, closeAfterMins,   %IniFile%, Group%A_Index%, CloseAfterMins, 0
			
			; --- Load Additional Settings ---
			IniRead, QuickLauncherHotkey, %IniFile%, AdditionalSettings, QuickLauncherHotkey, +F12
			IniRead, ToggleSettingsHotkey, %IniFile%, AdditionalSettings, ToggleSettingsHotkey, ^F11
			IniRead, RemoveLauncherTitlebar, %IniFile%, AdditionalSettings, RemoveLauncherTitlebar, 0
			IniRead, RemoveSettingsTitlebar, %IniFile%, AdditionalSettings, RemoveSettingsTitlebar, 0
			IniRead, RemoveTimerTitlebar, %IniFile%, AdditionalSettings, RemoveTimerTitlebar, 0
			IniRead, StackDelayMs, %IniFile%, AdditionalSettings, StackDelayMs, 300   
			IniRead, TimerHotkey, %IniFile%, AdditionalSettings, TimerHotkey, ^F10
			
			; Load TimerPinned setting
			IniRead, TimerPinned, %IniFile%, AdditionalSettings, TimerPinned, 0
			
			; Load TimerFontBold setting
			IniRead, TimerFontBold, %IniFile%, AdditionalSettings, TimerFontBold, 0
			
            ; Parse folders
            folders := []
            Loop, Parse, folderList, |
                if (A_LoopField != "")
                    folders.Push(A_LoopField)

            Groups[A_Index] := {Name: groupName
                , Hotkey: hotkey
                , Folders: folders
                , Width: width
                , Height: height
                , StackFolders: stackFolders
                , MinimizeAll: minimizeAll
                , SpecificSize: specificSize
                , DualVertical: dualVertical
                , DualHorizontal: dualHorizontal
                , HistoryLog: historyLog
                , OpenAfterEnabled: openAfterEnabled
                , OpenAfterMins: openAfterMins
                , CloseAfterEnabled: closeAfterEnabled
                , CloseAfterMins: closeAfterMins
                , LastOpenTime: ""}
        } else {
            Groups[A_Index] := {Name: "", Hotkey: "", Folders: [], Width: 800, Height: 600}
        }
		
		; Initialize timer states
		Loop, %MaxGroups% {
			TimerStates[A_Index] := {SecRunning: false, MinRunning: false, SecElapsed: 0, MinElapsed: 0}
		}
		
		    ; Initialize timer colors
		Loop, 32 {
			; Try to load saved colors, otherwise use default
			if (A_Index <= 16) {
				; Minute timers
				if (A_Index <= 8) {
					groupNum := A_Index
					IniRead, color, %IniFile%, Group%groupNum%, OpenAfterColor, %DefaultTimerColor%
				} else {
					groupNum := A_Index - 8
					IniRead, color, %IniFile%, Group%groupNum%, CloseAfterColor, %DefaultTimerColor%
				}
			} else {
				; Second timers
				if (A_Index <= 24) {
					groupNum := A_Index - 16
					IniRead, color, %IniFile%, Group%groupNum%, OpenAfterSecsColor, %DefaultTimerColor%
				} else {
					groupNum := A_Index - 24
					IniRead, color, %IniFile%, Group%groupNum%, CloseAfterSecsColor, %DefaultTimerColor%
				}
			}
			TimerColors[A_Index] := color
		}
		
		; Initialize timers (32 timers: 1-16 minutes, 17-32 seconds)
		Loop, 32 {
			TimerStates[A_Index] := 0
			TimerRemaining[A_Index] := (A_Index <= 16) ? 300 : 30
			TimerDefaults[A_Index] := (A_Index <= 16) ? 300 : 30 ; 5min/30sec defaults
			TimerStartTick[A_Index] := 0
			TimerPausedRemaining[A_Index] := 0
			TimerMode[A_Index] := (A_Index <= 16) ? 1 : 2
			FlashCount[A_Index] := 0
			FlashState[A_Index] := 0
			
			; Set names based on group associations
			if (A_Index <= 16) {
				; Minute timers (1-8: open after, 9-16: close after)
				if (A_Index <= 8) {
					groupNum := A_Index
					TimerNames[A_Index] := "Grp " . groupNum . " Open After"
				} else {
					groupNum := A_Index - 8
					TimerNames[A_Index] := "Grp " . groupNum . " Close After"
				}
			} else {
				; Second timers (17-24: open after, 25-32: close after)
				if (A_Index <= 24) {
					groupNum := A_Index - 16
					TimerNames[A_Index] := "Grp " . groupNum . " Open After"
				} else {
					groupNum := A_Index - 24
					TimerNames[A_Index] := "Grp " . groupNum . " Close After"
				}
			}
		}
    }
}

; ============================================
; HOTKEY MANAGEMENT
; ============================================

SetupHotkeys() {
    Global MaxGroups, Groups, QuickLauncherHotkey, ToggleSettingsHotkey
    
    ; Disable all existing hotkeys first
    Loop, %MaxGroups% {
        if (Groups[A_Index].Hotkey != "")
            Hotkey, % Groups[A_Index].Hotkey, Off, UseErrorLevel
    }
    
    ; Disable previous custom hotkeys
    Hotkey, %QuickLauncherHotkey%, Off, UseErrorLevel
    Hotkey, %ToggleSettingsHotkey%, Off, UseErrorLevel
    
    ; Create new hotkeys for groups
    Loop, %MaxGroups% {
        hk := Groups[A_Index].Hotkey
        if (Groups[A_Index].Name != "" && hk != "") {
            Hotkey, %hk%, OpenFolderGroup, On UseErrorLevel
        }
    }
    
    ; Set custom hotkeys
    Hotkey, %QuickLauncherHotkey%, QuickLauncherHotkeyLabel, On UseErrorLevel
    Hotkey, %ToggleSettingsHotkey%, ToggleGuiHotkeyLabel, On UseErrorLevel
	
	; Timer hotkey
    Hotkey, %TimerHotkey%, TimerHotkeyLabel, On UseErrorLevel
}

TimerHotkeyLabel:
    if (TimerVisible) {
        Gui, TimerGUI:Destroy
        TimerVisible := False
    } else {
        ShowTimerGUI()
    }
Return

QuickLauncherHotkeyLabel:
    if (LauncherVisible) {
        Gui, Launcher:Destroy
        LauncherVisible := False
    } else {
        ShowQuickLauncher()
        LauncherVisible := True
    }
Return

ToggleGuiHotkeyLabel:
    ToggleGui()
Return
    
OpenFolderGroup:
    ; Find which group was triggered
    Loop, %MaxGroups% {
        if (A_ThisHotkey = Groups[A_Index].Hotkey) {
            OpenGroup(A_Index)
            Break
        }
    }
Return

;-------Minimiwze & Restore From Stack Function---------

MinimizeToStack(hwnd) {
    Global MinimizedStack, GuiHwnd
    
    if (!hwnd || hwnd = GuiHwnd)
        return false
    
    if (!WinExist("ahk_id " hwnd))
        return false
    
    WinGet, MinMax, MinMax, ahk_id %hwnd%
    if (MinMax != -1) {
        MinimizedStack.Push(hwnd)
        WinMinimize, ahk_id %hwnd%
        return true
    }
    return false
}

RestoreFromStack() {
    Global MinimizedStack
    
    if (MinimizedStack.Length() = 0)
        return 0
    
    hwnd := MinimizedStack.Pop()
    if (!WinExist("ahk_id " hwnd))
        return 0
    
    WinGet, MinMax, MinMax, ahk_id %hwnd%
    if (MinMax = -1) {
        WinRestore, ahk_id %hwnd%
        return hwnd
    }
    return 0
}

OpenGroup(index) {
    Global
    
    if (Groups[index].IsPaused = 1) {
        MsgBox, This group is currently paused. Please resume it first.
        Return
    }
    
    group := Groups[index]
    groupName := group.Name
    
    if (groupName = "")
        Return
    
    if (group.LastOpenTime != "") {
        timeSinceOpen := A_TickCount - group.LastOpenTime
        if (timeSinceOpen < 2000)
            Return
    }
    
    Groups[index].LastOpenTime := A_TickCount
    
    if (group.HistoryLog = 1) {
        FormatTime, currentTime, , yyyy-MM-dd HH:mm:ss
        FileAppend, [%currentTime%] Opened: %groupName%`n, %LogFile%
    }
    
    folderCount := group.Folders.MaxIndex()
    if (folderCount = "")
        folderCount := 0
    
    ; STEP 1: Minimize ALL existing Explorer windows to stack
    WinGet, id, List, ahk_class CabinetWClass
    Loop, %id% {
        MinimizeToStack(id%A_Index%)
        Sleep, 50
    }
    
    ; STEP 2: Track window handles BEFORE opening
    beforeWindows := []
    WinGet, id, List, ahk_class CabinetWClass
    Loop, %id% {
        beforeWindows.Push(id%A_Index%)
    }
    
    ; STEP 3: Open folders ONE AT A TIME with better tracking
    newWindows := []
    
    for idx, folder in group.Folders {
        if (FileExist(folder)) {
            ; Get count BEFORE opening
            WinGet, beforeCount, Count, ahk_class CabinetWClass
            
            ; Open folder
            Run, explorer.exe "%folder%"
            
            ; Wait for the NEW window to appear (max 3 seconds)
            timeout := A_TickCount + 3000
            Loop {
                WinGet, afterCount, Count, ahk_class CabinetWClass
                if (afterCount > beforeCount) {
                    ; Find the newest window
                    WinGet, id, List, ahk_class CabinetWClass
                    newHwnd := id1  ; Most recent is first in list
                    
                    ; Verify it's truly new
                    isNew := true
                    for i, oldWin in beforeWindows {
                        if (newHwnd = oldWin) {
                            isNew := false
                            Break
                        }
                    }
                    
                    if (isNew) {
                        newWindows.Push(newHwnd)
                        Break
                    }
                }
                
                if (A_TickCount > timeout)
                    Break
                    
                Sleep, 50
            }
            
            ; Wait for window to stabilize
            Sleep, 300
        }
    }
    
    ; Additional stabilization wait
    Sleep, 1500
    
    ; STEP 4: Get ONLY the NEW windows
    newWindows := []
    WinGet, id, List, ahk_class CabinetWClass
    Loop, %id% {
        thisWin := id%A_Index%
        isNew := true
        for idx, oldWin in beforeWindows {
            if (thisWin = oldWin) {
                isNew := false
                Break
            }
        }
        if (isNew)
            newWindows.Push(thisWin)
    }
    
    ; STEP 5: Restore all windows first
    for idx, winId in newWindows {
        WinRestore, ahk_id %winId%
        Sleep, 100
    }
    
    Sleep, %StackDelayMs%
    
    ; STEP 6: Apply behaviors based on settings
    ; Check which behaviors are active
    minimizeEnabled := group.MinimizeAll = 1
    stackEnabled := group.StackFolders = 1
    resizeEnabled := group.SpecificSize = 1
    
    ; Apply stacking if enabled
    if (stackEnabled) {
        SysGet, Mon1, MonitorWorkArea, 1
        offsetX := 30
        offsetY := 30
        startX := Mon1Left + 50
        startY := Mon1Top + 50
        
        Loop, % newWindows.MaxIndex() {
            idx := A_Index
            winId := newWindows[idx]
            xPos := startX + ((idx - 1) * offsetX)
            yPos := startY + ((idx - 1) * offsetY)
            WinMove, ahk_id %winId%, , xPos, yPos
            Sleep, 100
        }
        
        Sleep, %StackDelayMs%
    }
    
    ; Apply resizing if enabled
    if (resizeEnabled) {
        Loop, % newWindows.MaxIndex() {
            idx := A_Index
            winId := newWindows[idx]
            WinMove, ahk_id %winId%, , , , group.Width, group.Height
            Sleep, 100
        }
        
        Sleep, %StackDelayMs%
    }
    
    ; STEP 7: Apply dual display (for exactly 2 folders) - ONLY if not minimizing
    if (!minimizeEnabled && folderCount = 2 && newWindows.MaxIndex() = 2) {
        win1 := newWindows[1]
        win2 := newWindows[2]
        
        SysGet, Mon1, MonitorWorkArea, 1
        
        if (group.DualVertical = 1) {
            halfWidth := (Mon1Right - Mon1Left) // 2
            WinMove, ahk_id %win1%, , Mon1Left, Mon1Top, halfWidth, Mon1Bottom - Mon1Top
            Sleep, 150
            WinMove, ahk_id %win2%, , Mon1Left + halfWidth, Mon1Top, halfWidth, Mon1Bottom - Mon1Top
        }
        else if (group.DualHorizontal = 1) {
            halfHeight := (Mon1Bottom - Mon1Top) // 2
            WinMove, ahk_id %win1%, , Mon1Left, Mon1Top, Mon1Right - Mon1Left, halfHeight
            Sleep, 150
            WinMove, ahk_id %win2%, , Mon1Left, Mon1Top + halfHeight, Mon1Right - Mon1Left, halfHeight
        }
    }
    
    ; STEP 8: Finally minimize if that option is enabled
    if (minimizeEnabled) {
        for idx, winId in newWindows {
            WinMinimize, ahk_id %winId%
            Sleep, 50
        }
    }
}

; ============================================
; SCHEDULER
; ============================================


StartScheduler() {
    SetTimer, CheckSchedules, 60000
}

CheckSchedules:
Return


PauseGroupHandler:
    Global Groups, GuiVisible, CurrentContextGroup
    Groups[CurrentContextGroup].IsPaused := 1
    if (GuiVisible) {
        Gui, Main:Destroy
        CreateGui()
    }
Return

ResumeGroupHandler:
    Global Groups, GuiVisible, CurrentContextGroup
    Groups[CurrentContextGroup].IsPaused := 0
    if (GuiVisible) {
        Gui, Main:Destroy
        CreateGui()
    }
Return

; Dynamic close timers for each group

CloseGroup1:
    CloseGroupFolders(1)
Return

CloseGroup2:
    CloseGroupFolders(2)
Return

CloseGroup3:
    CloseGroupFolders(3)
Return

CloseGroup4:
    CloseGroupFolders(4)
Return

CloseGroup5:
    CloseGroupFolders(5)
Return

CloseGroup6:
    CloseGroupFolders(6)
Return

CloseGroup7:
    CloseGroupFolders(7)
Return

CloseGroup8:
    CloseGroupFolders(8)
Return

CloseGroup9:
    CloseGroupFolders(9)
Return

CloseGroup10:
    CloseGroupFolders(10)
Return

CloseGroup11:
    CloseGroupFolders(11)
Return

CloseGroup12:
    CloseGroupFolders(12)
Return

CloseGroup13:
    CloseGroupFolders(13)
Return

CloseGroup14:
    CloseGroupFolders(14)
Return

CloseGroup15:
    CloseGroupFolders(15)
Return

CloseGroup16:
    CloseGroupFolders(16)
Return

CloseGroup17:
    CloseGroupFolders(17)
Return

CloseGroup18:
    CloseGroupFolders(18)
Return

CloseGroup19:
    CloseGroupFolders(19)
Return

CloseGroup20:
    CloseGroupFolders(20)
Return

CloseGroupFolders(index) {
    Global
    group := Groups[index]
    
    ; Close all explorer windows for this group's folders
    for idx, folder in group.Folders {
        WinGet, id, List, ahk_class CabinetWClass
        Loop, %id% {
            thisID := id%A_Index%
            WinGetTitle, title, ahk_id %thisID%
            ; Check if window title contains folder name
            if (InStr(title, folder)) {
                WinClose, ahk_id %thisID%
			}
			if (Groups[index].HistoryLog = 1) {
				FormatTime, currentTime, , yyyy-MM-dd HH:mm:ss
				groupName := Groups[index].Name
				FileAppend, [%currentTime%] Closed: %groupName% (%folder%)`n, %LogFile%
            }
        }
    }
}

; ============================================
; COLOR SELECTION HANDLER
; ============================================

SelectColorHandler:
    ; Get which colored text was clicked
    clickedControl := A_GuiControl
    
    ; Debug: Show what control was clicked
    ; MsgBox, Clicked: %clickedControl%
    
    ; Map the colored text control to the actual color control
    if (RegExMatch(clickedControl, "ColorTextOpenAfter(\d+)", match)) {
        ; For Open After (Minutes) color
        ShowColorPicker("OpenAfterColor" . match1)
    }
    else if (RegExMatch(clickedControl, "ColorTextCloseAfter(\d+)", match)) {
        ; For Close After (Minutes) color
        ShowColorPicker("CloseAfterColor" . match1)
    }
    else if (RegExMatch(clickedControl, "ColorTextOpenAfterSecs(\d+)", match)) {
        ; For Open After (Seconds) color
        ShowColorPicker("OpenAfterSecsColor" . match1)
    }
    else if (RegExMatch(clickedControl, "ColorTextCloseAfterSecs(\d+)", match)) {
        ; For Close After (Seconds) color
        ShowColorPicker("CloseAfterSecsColor" . match1)
    }
    else {
        ; Debug: Show what control wasn't recognized
        MsgBox, Unknown color control: %clickedControl%
    }
Return