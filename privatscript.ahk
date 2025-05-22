; === GTA5RP Majestic Clicker with One-Time License Activation and HWID Lock ===
#Requires AutoHotkey v2.0
#SingleInstance Force

; === Конфигурация ===
workKey := "6"
exitKey := "Esc"
clickIntervalMin := 8
clickIntervalMax := 15
workDuration := 18000 ; 18 секунд
keysFile := "valid_keys.txt"
hwidFile := "activated_hwid.txt"

; === Глобальные переменные ===
global isRunning := false
global isPaused := false
global hudText, hudGui, animationTimer
global clickTimerRunning := false
global remainingTime := workDuration
global timerStartTime := 0

global thisHWID := GetHWID()

; === Авторизация по ключу и HWID ===
CheckLicense() {
    global keysFile, hwidFile, thisHWID

    if FileExist(hwidFile) {
        if InStr(FileRead(hwidFile), thisHWID) {
            return true ; уже активировано
        }
    }

    if !FileExist(keysFile) {
        MsgBox "❌ Файл с ключами не найден: " keysFile
        ExitApp()
    }

    validLines := StrSplit(FileRead(keysFile), "`n")
    result := InputBox("Введите ключ доступа:", "Авторизация")
    if result.Result != "OK" || result.Value = "" {
        MsgBox "⛔ Ключ не введён. Скрипт завершён."
        ExitApp()
    }
    key := Trim(result.Value)

    updatedLines := []
    found := false
    for line in validLines {
        parts := StrSplit(line, "|")
        if parts.Length >= 2 && Trim(parts[1]) = key && Trim(parts[2]) = "unused" {
            found := true
            updatedLines.Push(parts[1] "|" thisHWID)
        } else {
            updatedLines.Push(line)
        }
    }

    if !found {
        MsgBox "🚫 Неверный или уже использованный ключ!"
        ExitApp()
    }

    FileDelete(keysFile)
    FileAppend(StrJoin("`n", updatedLines*), keysFile)
    FileAppend(thisHWID "`n", hwidFile)
}

; === HWID генерация ===
GetHWID() {
    RunWait("cmd /c wmic csproduct get uuid > hwid.tmp", , "Hide")
    hwid := Trim(FileRead("hwid.tmp"))
    FileDelete("hwid.tmp")
    hwid := StrReplace(hwid, "UUID", "")
    return Trim(hwid)
}

; === Старт скрипта ===
CheckLicense()
StartScript()

StartScript() {
    global hudGui, hudText

    TraySetIcon("shell32.dll", 44)
    A_IconTip := "Кликер для Карьерщика - GTA5RP Majestic"

    hudGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner", "HUD")
    hudGui.BackColor := "Black"
    hudGui.SetFont("s12 Bold", "Segoe UI")
    hudText := hudGui.AddText("Center w200 h40 +Border", "ГОТОВ")
    WinSetTransparent(180, hudGui.Hwnd)
    hudGui.Show("x10 y10 NoActivate")

    Hotkey(workKey, ToggleClicking)
    Hotkey(exitKey, SafeExit)

    UpdateHUD("ГОТОВ", "00FF00")
}

ToggleClicking(*) {
    global isRunning, isPaused

    if !isRunning {
        StartClicking()
    } else if !isPaused {
        PauseClicking()
    } else {
        ResumeClicking()
    }
}

StartClicking() {
    global isRunning, isPaused, clickTimerRunning, remainingTime, timerStartTime

    isRunning := true
    isPaused := false
    remainingTime := workDuration
    timerStartTime := A_TickCount

    UpdateHUD("РАБОТАЕТ", "00FF00")
    SoundBeep(1000, 150)
    SetTimer(StopAfterTimeout, -remainingTime)
    StartHUDAnimation()

    if !clickTimerRunning {
        clickTimerRunning := true
        SetTimer(DoClick, Random(clickIntervalMin, clickIntervalMax))
    }
}

PauseClicking() {
    global isPaused, remainingTime, timerStartTime, clickTimerRunning

    isPaused := true
    remainingTime -= (A_TickCount - timerStartTime)

    UpdateHUD("НА ПАУЗЕ", "FFA500")
    StopHUDAnimation()
    SetTimer(StopAfterTimeout, 0)

    SetTimer(DoClick, 0)
    clickTimerRunning := false
    SoundBeep(400, 150)
}

ResumeClicking() {
    global isPaused, timerStartTime, clickTimerRunning

    isPaused := false
    timerStartTime := A_TickCount

    UpdateHUD("РАБОТАЕТ", "00FF00")
    StartHUDAnimation()
    SetTimer(StopAfterTimeout, -remainingTime)

    if !clickTimerRunning {
        clickTimerRunning := true
        SetTimer(DoClick, Random(clickIntervalMin, clickIntervalMax))
    }

    SoundBeep(1000, 150)
}

StopClicking() {
    global isRunning, isPaused, clickTimerRunning, remainingTime

    isRunning := false
    isPaused := false
    remainingTime := workDuration

    UpdateHUD("МИНИ-ИГРА", "FFFF00")
    StopHUDAnimation()
    SetTimer(StopAfterTimeout, 0)
    SetTimer(DoClick, 0)
    clickTimerRunning := false
    SoundBeep(600, 200)
}

StopAfterTimeout(*) {
    global isRunning
    if isRunning
        StopClicking()
}

DoClick(*) {
    global isRunning, clickTimerRunning
    if !isRunning {
        SetTimer(DoClick, 0)
        clickTimerRunning := false
        return
    }

    ClickMouse()
    SetTimer(DoClick, Random(clickIntervalMin, clickIntervalMax))
}

ClickMouse() {
    DllCall("mouse_event", "UInt", 0x02)
    Sleep(10)
    DllCall("mouse_event", "UInt", 0x04)
}

UpdateHUD(text, color) {
    global hudText
    hudText.Value := text
    hudText.SetFont("c" color)
}

StartHUDAnimation() {
    global animationTimer
    animationTimer := 0
    SetTimer(AnimateHUDColor, 200)
}

StopHUDAnimation() {
    SetTimer(AnimateHUDColor, 0)
}

AnimateHUDColor() {
    global animationTimer
    colors := ["00FF00", "00DD00", "00AA00", "00DD00"]
    index := Mod(animationTimer, colors.Length) + 1
    UpdateHUD("РАБОТАЕТ", colors[index])
    animationTimer += 1
}

SafeExit(*) {
    global hudGui
    SetTimer(AnimateHUDColor, 0)
    SetTimer(DoClick, 0)
    SetTimer(StopAfterTimeout, 0)
    hudGui.Destroy()
    ExitApp()
}

; === Функция объединения строк (StrJoin) ===
StrJoin(sep, args*) {
    result := ""
    for index, item in args {
        if (index > 1)
            result .= sep
        result .= item
    }
    return result
}
