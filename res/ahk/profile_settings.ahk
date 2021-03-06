Class Profile Extends CGUI
{

	__New(mainGui, owner = "")
	{
        this.AddControl("Text", "F", "x46 y11 w75 h13 ", "Name:")
        this.edtName := this.AddControl("Edit", "edtName", "x87 y6 w299 h23 ", "")
        this.radioBrowse := this.AddControl("Radio", "radioBrowse", "x33 y86 w329 h16 ", "Browse")
        this.radioSelect := this.AddControl("Radio", "radioSelect", "x33 y121 w327 h16 ", "Select from list")
        this.radioSelect := this.AddControl("Radio", "radioHotkey", "x33 y161 w327 h16 ", "Select with F12")
        this.AddControl("GroupBox", "X", "x6 y62 w380 h159 ", "Select Program Executable")
        this.edtExe := this.AddControl("Edit", "edtExe", "x55 y187 w278 h23 ", "")
        this.btnOK := this.AddControl("Button", "btnOK", "x148 y224 w75 h23 ", "OK")
        this.AddControl("Button", "btnCanel", "x229 y224 w75 h23 ", "Cancel")
        this.AddControl("Button", "btnHelp", "x310 y224 w75 h23 ", "Help")

        this.btnOK.Disable()

        this.gui := mainGui
        if (owner)
            this.Owner := owner, this.OwnerAutoClose := 1, this.MinimizeBox := 0

        this.Toolwindow := 1
		this.Title := "Profile Manager"pp
	}

    btnHelp_Click()
    {
        MsgBox, Name: Name of profile.`nProgram Executable: Exe of program for profile switching.
    }


    edtName_textChanged()
    {
        ; Making sure its a valid name.
        if (this.edtName.text && !RegExMatch(this.edtName.text, "[\\/\?\*\""""\:\<\>\|]") )
            this.btnOK.Enable()
        else
            this.btnOK.Disable()
    }

    radioBrowse_CheckedChanged()
    {
        this.OwnDialogs := 1 ; For file select dialog
        file := new CFileDialog(), file.FileMustExist := 1
        file.Filter := "Program (*.exe)"
        if ( file.show() )
            this.edtExe.Text := file.FileName
    }

    radioSelect_CheckedChanged()
    {
        this.gui.Windows.Load()
        this.Enabled := false
    }

    radioHotkey_CheckedChanged()
    {
        Hotkey, F12, SelectExe, On
        Hotkey, Escape, SelectExe, On
        SplashTextOn, 230, 50, Select Program, Activate the program and press F12`nPress Esc to cancel
    }

    btnCanel_Click()
    {
        this.Loaded := 0
        this.edtName.Text := "", this.edtExe.Text := ""
        this.gui.Enabled := true
        this.Hide()
        debug ? debug("Canceled profile creation")
    }

    btnOK_Click()
    {
        name := Trim(this.edtName.Text)
        if (name = "Default")
        {
            MsgBox, 48, , Profile name can not be "Default".
            return
        }
        else if (FileExist(A_ScriptDir . "\res\Profiles\" . name . ".xml")) ; Profile already exists.
        {
            MsgBox, 52, , Profile already exists.`nWould you like to overwrite it?
            IfMsgBox, No
                return
        }
        if (this.Loaded)
        {
            FileRead, xmlValue, % this.savedProfile
            FileDelete % this.savedProfile
        }

        currentXml := A_ScriptDir . "\res\Profiles\" . name . ".xml"
        if (xmlValue)
            FileAppend, % xmlValue, % currentXml

        xml := New Xml(currentXml)
        exe := this.edtExe.Text

        ; Update values in xml file.
        xml.Set("exe", exe)
        xml.Set("name", name)
        xml.Save(A_ScriptDir . "\res\Profiles\" . name . ".xml") ; Save xml file.

        ; Clear value from edit boxs.
        this.edtName.Text := "", this.edtExe.Text := "", this.Loaded := 0
        this.gui.Enabled := true
        this.Hide()
        debug ? debug("Created profile: " name)
        this.gui.LoadProfiles()
        Control, ChooseString, % name, % this.gui.drpProfiles.ClassNN, A
    }

    Load(profilePath)
    {
        SplitPath, profilePath, name
        this.savedProfile := profilePath
        this.edtName.Text := SubStr(name, 1, -4)
        this.edtExe.Text := xml.Get("exe")
        this.Loaded := 1
        debug ? debug("Loaded profile: " . name)
        this.Show()
    }

    PreClose() {
        this.gui.Enabled := true
    }

}

SelectExe:
    SplashTextOff
    if (A_ThisHotkey = "F12")
    {
        WinGet, exeName, ProcessPath , A
        gui.Profile.edtExe.Text := exeName
    }
    Hotkey, F12, Off
    Hotkey, Escape, Off
    WinActivate % "ahk_pid " . DllCall("GetCurrentProcessId")
return
