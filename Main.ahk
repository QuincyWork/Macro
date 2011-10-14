#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
#SingleInstance, Force
; #NoTrayIcon

SetBatchLines, -1
ListLines, Off
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

global xml, currentXml, version, debug, AhkScript, defaultScript, ScriptThread, AhkSender, Ini

args := arg()
debug := 1 ;args[1]
debugFile := args[2]
version := 0.4

if (!FileExist(A_ScriptDir . "\res"))
    Gosub, Install

currentXml := A_ScriptDir . "\Profiles\Default.xml"
xml := new Xml(currentXml)
xml.Save(A_ScriptDir . "\Profiles", "Default")

Ini := new Ini(A_ScriptDir . "\res\settings.ini")
ahkDll := A_ScriptDir . "\res\dll\AutoHotkey.dll"

AhkRecorder := AhkDllThread(ahkDll)
AhkSender := AhkDllThread(ahkDll)
AhkScript := AhkDllThread(ahkDll)
AhkSender.ahkTextDll("")

OnMessage(0x404, "AHK_NOTIFYICON") ; Detect clicks on tray icon

PID := DllCall("GetCurrentProcessId")
if (Ini.Settings.ProfileSwitching)
    SetTimer, ProfileSwitcher, % Ini.Settings.ProfileDelay
gui := new Main()
return

ProfileSwitcher:
    IfWinActive, ahk_pid %PID%
        return
    WinGet, proccessExe, ProcessPath, A
    if (proccessExe = lastExe)
        return
    debug ? debug("Checking for different profile.")
    Loop % A_ScriptDir . "\Profiles\*.xml"
    {
        if (A_LoopFileName = "Default.xml")
            Continue
        FileRead, text, % A_LoopFileLongPath
        RegExMatch(text, "`am)\<exe\>(.*)?\<", exe)

        if (proccessExe = exe1)
        {
            debug ? debug("Found exe: " . SubStr(A_LoopFileName, 1, -4))
            if (currentXml != A_LoopFileLongPath)
            {
                Control, ChooseString, % SubStr(A_LoopFileName, 1, -4), % gui.drpProfiles.ClassNN, % "ahk_id " . gui.hwnd
                switchedProfile := 1
            }
            break
        }
    }
    if (currentXml != A_ScriptDir . "\Profiles\Default.xml" && !switchedProfile)
        Control, ChooseString, Default, % gui.drpProfiles.ClassNN, % "ahk_id " . gui.hwnd
    lastExe := proccessExe, switchedProfile := 0
Return

Pressed:
    hotkey := Trim(RegExReplace(A_ThisHotkey, "([\$\*\<\>\~]|(?<!_)Up)"))
    debug ? debug(hotkey . " pressed")

    ; get all the info for the hotkey
    type := xml.Get("key", hotkey, "type")
    value := xml.Get("key", hotkey, "value")
    repeat := xml.Get("key", hotkey, "repeat")


    if (type = "textblock")
        delay := xml.Get("textblock", value, "delay")
    else if (type = "script")
        AhkScript.ahkFunction("OnEvent", hotkey, "Pressed", A_TimeSinceThisHotkey, currentXml)

    if (repeat = "toggle")
    {
        toggle := !toggle
        if (!toggle)
            return
        while (toggle)
        {
            sleep, 10
            HandleKey(type, value, delay)
        }
        toggle := false
        return
    }
    else if (type != "script")
        HandleKey(type, value, delay)

    if (type != "script" && repeat = "None")
        KeyWait % Hotkey
    else if (type = "script")
    {
        While (GetKeyState(hotkey, "P") )
            AhkScript.ahkFunction("OnEvent", hotkey, "Down", A_TimeSinceThisHotkey, currentXml)
        AhkScript.ahkFunction("OnEvent", hotkey, "Released", A_TimeSinceThisHotkey, currentXml)
    }
Return

Hotkeys(disable = 0) {
    debug ? debug("Turning " . (disable ? "off" : "on") . " hotkeys")
    keys := xml.List("keys", "|")
    Loop, Parse, keys, |
        if (A_LoopField)
        {
            ; Turn (on|off) the key
            options := xml.GetAttribute(A_LoopField)
            repeat := xml.Get("key", hotkey, "repeat")
            Hotkey, % "$" . options, % (disable ? "Off" : "Pressed"), % (disable ? "Off" : "On T" . ((repeat = "toggle") + 1))
        }
}

HandleKey(type, value, delay = -1) {
    text := xml.Get(type, value, "value")

    if (type = "macro")
    {
        if (InStr(text, "Sleep"))
        {
            text := RegExReplace(text, "(\{\w*?\s(?:Down|Up)\})", "Send, $1")
            StringReplace, text, text, ``n, `n, all
        }
        else
        {
            text := "Send, " . text
            StringReplace, text, text, ``n, , all
        }

        AhkSender.ahkExec(text) ; Send macro in a new thread.
    }
    else if (type = "textblock")
    {
        StringReplace, text, text, ``n, `n, all
        SetKeyDelay % delay
        SendRaw % text
        SetKeyDelay, -1
    }
}

GetProfiles() {
    Loop, % A_ScriptDir . "\Profiles\*.xml"
        profiles .= A_LoopFileName . "|"
    return profiles
}


AHK_NOTIFYICON(wParam, lParam) {
    global gui
    if lParam = 0x201 ; WM_LBUTTONUP
        return
    else if lParam = 0x203 ; WM_LBUTTONDBLCLK
        gui.Show()

}

Install:
    debug ? debug("Installing files")
    FileCreateDir, % A_ScriptDir . "\res"
    FileCreateDir, % A_ScriptDir . "\res\scripts"
    FileCreateDir, % A_ScriptDir . "\profiles"
    FileInstall, res\AutoHotkey.dll, res\AutoHotkey.dll
    FileInstall, res\Recorder.ahk, res\Recorder.ahk
return


#include <CGUI>
#include <Xml>
#include <ini>
#include <Debug>

#Include, %A_ScriptDir%\res\gui\macro recorder.ahk
#Include, %A_ScriptDir%\res\gui\profile settings.ahk
#Include, %A_ScriptDir%\res\gui\textBlock.ahk
#Include, %A_ScriptDir%\res\gui\settings.ahk
#Include, %A_ScriptDir%\res\gui\main.ahk
#Include, %A_ScriptDir%\res\gui\settings.ahk