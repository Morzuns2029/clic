#Requires AutoHotkey v2.0
#SingleInstance Force

workKey := "6"
exitKey := "Esc"
clickIntervalMin := 8
clickIntervalMax := 15
workDuration := 18000
hwidFile := "activated_hwid.txt"
settingsFile := "settings.ini"
clickerScriptFile := "clicker.ahk"
clickerScriptURL := "https://raw.githubusercontent.com/Morzuns2029/clic/main/privatscript.ahk"

global isRunning := false
global isPaused := false
global hudText, hudGui, animationTimer
global clickTimerRunning := false
global remainingTime := workDuration
global timerStartTime := 0
global thisHWID := GetHWID()

JoinLines(arr) {
    result := ""
    for item in arr
        result .= item "`n"
    return RTrim(result, "`n")
}

ShowAdminPanel() {
    panel := Gui("+AlwaysOnTop", "Панель пользователя")

    activated := false
    if FileExist(hwidFile) {
        if InStr(FileRead(hwidFile), thisHWID)
            activated := true
    }

    panel.AddText(, "Добро пожаловать!")

    if !activated {
        panel.AddText(, "Введите ключ для активации:")
        keyInput := panel.AddEdit("w200")
        panel.AddButton("w200", "✅ Активировать").OnEvent("Click", (*) => ActivateKey(keyInput.Value, panel))
    }

    panel.AddButton("w200", "🚀 Запустить скрипт").OnEvent("Click", (*) => LaunchScript(panel))
    panel.AddButton("w200", "♻ Сбросить HWID").OnEvent("Click", (*) => (panel.Destroy(), ResetHWID(), ShowAdminPanel()))
    panel.AddButton("w200", "⚙ Настройки").OnEvent("Click", (*) => (panel.Destroy(), ShowSettingsPanel()))
    panel.AddButton("w200", "❌ Выход").OnEvent("Click", (*) => ExitApp())
    panel.Show("w230")
}

ActivateKey(key, panel) {
    key := Trim(key)
    if key = "" {
        MsgBox "Введите ключ!"
        return
    }

    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", "https://raw.githubusercontent.com/Morzuns2029/clic/main/valid_keys.txt", false)
        http.Send()
        if (http.Status != 200) {
            MsgBox "❌ Ошибка загрузки ключей! Код: " http.Status
            return
        }
        keyList := http.ResponseText
    } catch {
        MsgBox "❌ Не удалось загрузить ключи."
        return
    }

    validLines := StrSplit(keyList, "`n")
    updatedLines := []
    found := false
    for line in validLines {
        parts := StrSplit(Trim(line), "|")
        if parts.Length = 2 && Trim(parts[0]) = key && Trim(parts[1]) = "unused" {
            found := true
            updatedLines.Push(parts[0] "|" thisHWID)
        } else {
            updatedLines.Push(Trim(line))
        }
    }

    if !found {
        MsgBox "🚫 Неверный или уже использованный ключ!"
        return
    }

    FileAppend(thisHWID "`n", hwidFile)

    MsgBox "✅ Ключ активирован."
    panel.Destroy()
    ShowAdminPanel()
}

LaunchScript(panel) {
    if FileExist(hwidFile) && InStr(FileRead(hwidFile), thisHWID) {
        panel.Destroy()
        try {
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("GET", clickerScriptURL, false)
            http.Send()
            if (http.Status != 200) {
                MsgBox "❌ Ошибка загрузки кликера! Код: " http.Status
                return
            }
            file := FileOpen(clickerScriptFile, "w")
            file.Write(http.ResponseText)
            file.Close()
            if !FileExist(clickerScriptFile) {
                MsgBox "❌ Ошибка: файл не создан."
                return
            }
        } catch {
            MsgBox "❌ Не удалось скачать файл: " clickerScriptURL
            return
        }

        Run clickerScriptFile
        ExitApp
    } else {
        MsgBox "🔐 Скрипт не активирован. Введите ключ для запуска."
    }
}

ResetHWID() {
    if !FileExist(hwidFile) {
        MsgBox "Файл HWID не найден."
        return
    }
    lines := StrSplit(FileRead(hwidFile), "`n")
    newLines := []
    for line in lines {
        if Trim(line) != thisHWID
            newLines.Push(line)
    }
    FileDelete(hwidFile)
    FileAppend(JoinLines(newLines), hwidFile)
    MsgBox "✅ HWID сброшен. Повторная активация потребуется."
}

ShowSettingsPanel() {
    settingsGui := Gui("+AlwaysOnTop", "Настройки")
    settingsGui.AddText(, "Клавиша запуска/паузы:")
    workInput := settingsGui.AddEdit("w150", workKey)
    settingsGui.AddText(, "Клавиша выхода:")
    exitInput := settingsGui.AddEdit("w150", exitKey)
    settingsGui.AddButton("w100", "Сохранить").OnEvent("Click", SaveSettings)
    settingsGui.AddButton("w100", "Назад").OnEvent("Click", (*) => (settingsGui.Destroy(), ShowAdminPanel()))
    settingsGui.Show()

    SaveSettings(*) {
        IniWrite(workInput.Value, settingsFile, "Keys", "Work")
        IniWrite(exitInput.Value, settingsFile, "Keys", "Exit")
        MsgBox "Настройки сохранены. Перезапустите скрипт."
        settingsGui.Destroy()
        ExitApp()
    }
}

LoadSettings() {
    if FileExist(settingsFile) {
        workKey := IniRead(settingsFile, "Keys", "Work", workKey)
        exitKey := IniRead(settingsFile, "Keys", "Exit", exitKey)
    }
}

GetHWID() {
    RunWait("cmd /c wmic csproduct get uuid > hwid.tmp", , "Hide")
    hwid := Trim(FileRead("hwid.tmp"))
    FileDelete("hwid.tmp")
    hwid := StrReplace(hwid, "UUID", "")
    return Trim(hwid)
}

LoadSettings()
ShowAdminPanel()
