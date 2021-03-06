PlayMacro(macro) {
    global currentXml
    static oXML := ComObjCreate("MSXML2.DOMDocument")
    oXML.async := False
    oXML.Load(currentXml)

    text := oXml.selectSingleNode("/profile/macros/" . macro . "/value").text
    StringReplace, text, text, ``n, `n, all

    Loop, Parse, text, `n
    {
        if (!A_LoopField)
            Continue
        else if (InStr(A_LoopField, "MouseMove"))
        {
            RegExMatch(A_LoopField, "O)MouseMove, (\d*?), (\d*)", match)
            MouseMove, % match.1, % match.2, 1
        }
        else if (InStr(A_LoopField, "Sleep,"))
        {
            Send % sendString
            sendString := ""
            Sleep % SubStr(A_LoopField, 8)
        }
        else
            sendString .= A_LoopField
    }
    Send % sendString
}

