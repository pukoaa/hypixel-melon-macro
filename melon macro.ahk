; ====================================================================
; Game Movement Automation Script
; Description: Toggles between W+A and W+D movement patterns
; Author: pukoaa
; ====================================================================

#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%

; ====================================================================
; GLOBAL VARIABLES
; ====================================================================
isRunning := false
currentPhase := 1  ; 1 = W+A, 2 = W+D
phaseStartTime := 0
scriptStartTime := 0
pausedElapsedTime := 0  ; Time elapsed in current phase when paused
phaseDuration := 75000  ; 1 minute 15 seconds in milliseconds
overlayGui := ""

; ====================================================================
; INITIALIZATION
; ====================================================================
; Create the overlay GUI on startup
CreateOverlay()
UpdateOverlay()

; ====================================================================
; HOTKEYS
; ====================================================================

; O Key - Toggle Script On/Off (Pause/Resume)
o::
    if (isRunning) {
        PauseScript()
    } else {
        ResumeScript()
    }
return

; Middle Mouse Button - Emergency Stop
MButton::
    EmergencyStop()
return

; ====================================================================
; MAIN FUNCTIONS
; ====================================================================

StartScript() {
    global
    isRunning := true
    currentPhase := 1
    scriptStartTime := A_TickCount
    phaseStartTime := A_TickCount
    pausedElapsedTime := 0  ; Reset pause time for fresh start
    
    ; Start with W+A movement + left click
    Send, {w down}{a down}{LButton down}
    
    ; Play start sound (system sound)
    SoundPlay, *48  ; Asterisk sound
    
    ; Start the timer for phase checking
    SetTimer, CheckPhase, 100
    
    ; Update overlay
    UpdateOverlay()
    
    ; Show tooltip for feedback
    ToolTip, Movement Script STARTED, 50, 50
    SetTimer, RemoveTooltip, 2000
}

PauseScript() {
    global
    isRunning := false
    
    ; Calculate elapsed time in current phase before pausing
    currentTime := A_TickCount
    pausedElapsedTime := (currentTime - phaseStartTime) + pausedElapsedTime
    
    ; Release all keys including left click
    Send, {w up}{a up}{d up}{LButton up}
    
    ; Stop timer
    SetTimer, CheckPhase, Off
    
    ; Play pause sound
    SoundPlay, *16  ; Hand sound
    
    ; Update overlay
    UpdateOverlay()
    
    ; Show tooltip for feedback
    ToolTip, Movement Script PAUSED, 50, 50
    SetTimer, RemoveTooltip, 2000
}

ResumeScript() {
    global
    isRunning := true
    
    ; Resume with adjusted start time to account for pause
    phaseStartTime := A_TickCount - pausedElapsedTime
    
    ; Resume with current phase keys + left click
    if (currentPhase == 1) {
        Send, {w down}{a down}{LButton down}
    } else {
        Send, {w down}{d down}{LButton down}
    }
    
    ; Play resume sound
    SoundPlay, *48  ; Asterisk sound
    
    ; Restart the timer for phase checking
    SetTimer, CheckPhase, 100
    
    ; Update overlay
    UpdateOverlay()
    
    ; Show tooltip for feedback
    ToolTip, Movement Script RESUMED, 50, 50
    SetTimer, RemoveTooltip, 2000
}

StopScript() {
    global
    isRunning := false
    
    ; Reset everything for a complete stop
    pausedElapsedTime := 0
    currentPhase := 1
    
    ; Release all keys including left click
    Send, {w up}{a up}{d up}{LButton up}
    
    ; Stop timer
    SetTimer, CheckPhase, Off
    
    ; Play stop sound
    SoundPlay, *16  ; Hand sound
    
    ; Update overlay
    UpdateOverlay()
    
    ; Show tooltip for feedback
    ToolTip, Movement Script STOPPED, 50, 50
    SetTimer, RemoveTooltip, 2000
}

EmergencyStop() {
    global
    ; Immediately release all keys including left click
    Send, {w up}{a up}{d up}{LButton up}
    
    if (isRunning) {
        isRunning := false
        SetTimer, CheckPhase, Off
        UpdateOverlay()
        
        ; Play emergency sound
        SoundPlay, *64  ; Critical Stop sound
        
        ToolTip, EMERGENCY STOP ACTIVATED, 50, 50
        SetTimer, RemoveTooltip, 3000
    }
}

CheckPhase() {
    global
    if (!isRunning)
        return
    
    currentTime := A_TickCount
    elapsedInPhase := currentTime - phaseStartTime
    
    ; Update overlay every check
    UpdateOverlay()
    
    ; Check if it's time to switch phases
    if (elapsedInPhase >= phaseDuration) {
        SwitchPhase()
    }
}

SwitchPhase() {
    global
    
    ; Release current keys but keep left click held
    Send, {w up}{a up}{d up}
    
    ; Small delay for smooth transition
    Sleep, 50
    
    ; Switch to next phase (left click stays down throughout)
    if (currentPhase == 1) {
        currentPhase := 2
        Send, {w down}{d down}  ; W+D movement (LButton still held)
    } else {
        currentPhase := 1
        Send, {w down}{a down}  ; W+A movement (LButton still held)
    }
    
    ; Reset phase timer and paused time
    phaseStartTime := A_TickCount
    pausedElapsedTime := 0
    
    ; Play direction switch sound
    SoundPlay, *32  ; Question sound
    
    ; Update overlay immediately
    UpdateOverlay()
}

; ====================================================================
; OVERLAY GUI FUNCTIONS
; ====================================================================

CreateOverlay() {
    global
    
    ; Create GUI with specific options
    Gui, Add, Text, x10 y10 w200 h20 vStatusText, Status: STOPPED
    Gui, Add, Text, x10 y35 w200 h20 vPhaseText, Phase: ---
    Gui, Add, Text, x10 y60 w200 h20 vTimeRemainingText, Time Remaining: ---
    Gui, Add, Text, x10 y85 w200 h20 vTotalRuntimeText, Total Runtime: 00:00
    Gui, Add, Text, x10 y110 w200 h40 vControlsText, Controls:`nO Key: Pause/Resume | MButton: Emergency Stop
    
    ; Configure GUI properties
    Gui, +LastFound +AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox +Resize
    Gui, Color, 0x2D2D30  ; Dark gray background
    Gui, Font, s9 cWhite, Segoe UI
    
    ; Make GUI semi-transparent and draggable
    WinSet, Transparent, 220
    WinSet, ExStyle, +0x20  ; Click-through prevention
    
    ; Show GUI
    Gui, Show, x10 y10 w220 h160, Movement Automation Overlay
    
    ; Make it draggable
    OnMessage(0x201, "WM_LBUTTONDOWN")
}

UpdateOverlay() {
    global
    
    ; Update status
    if (isRunning) {
        GuiControl,, StatusText, Status: RUNNING
        
        ; Update current phase
        if (currentPhase == 1) {
            GuiControl,, PhaseText, Phase: W+A+Click (Forward Left)
        } else {
            GuiControl,, PhaseText, Phase: W+D+Click (Forward Right)
        }
        
        ; Calculate and update time remaining
        currentTime := A_TickCount
        elapsedInPhase := currentTime - phaseStartTime
        remainingTime := phaseDuration - elapsedInPhase
        
        if (remainingTime < 0)
            remainingTime := 0
            
        remainingSeconds := Floor(remainingTime / 1000)
        remainingMinutes := Floor(remainingSeconds / 60)
        remainingSeconds := Mod(remainingSeconds, 60)
        
        remainingSecondsFormatted := Format("{:02d}", remainingSeconds)
        GuiControl,, TimeRemainingText, Time Remaining: %remainingMinutes%:%remainingSecondsFormatted%
        
        ; Calculate and update total runtime
        totalRuntime := currentTime - scriptStartTime
        totalSeconds := Floor(totalRuntime / 1000)
        totalMinutes := Floor(totalSeconds / 60)
        totalSecondsDisplay := Mod(totalSeconds, 60)
        
        totalSecondsFormatted := Format("{:02d}", totalSecondsDisplay)
        GuiControl,, TotalRuntimeText, Total Runtime: %totalMinutes%:%totalSecondsFormatted%
        
    } else {
        GuiControl,, StatusText, Status: PAUSED
        GuiControl,, PhaseText, Phase: ---
        GuiControl,, TimeRemainingText, Time Remaining: ---
        GuiControl,, TotalRuntimeText, Total Runtime: 00:00
    }
}

; Make GUI draggable
WM_LBUTTONDOWN() {
    PostMessage, 0xA1, 2
}

; Remove tooltip timer function
RemoveTooltip:
    ToolTip
    SetTimer, RemoveTooltip, Off
return

; ====================================================================
; CLEANUP ON EXIT
; ====================================================================
GuiClose:
ExitApp

OnExit:
    ; Ensure all keys are released when script exits
    Send, {w up}{a up}{d up}{LButton up}
ExitApp

; ====================================================================
; SCRIPT INFO DISPLAY
; ====================================================================
; Show script info on startup
ToolTip, Game Movement Script Loaded`nPress O to start/pause/resume`nMiddle Mouse for emergency stop, 100, 100

SetTimer, RemoveTooltip, 4000
