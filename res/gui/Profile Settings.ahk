Class Profile Extends CGUI
{

	__New(mainGui, owner = "")
	{   
        this.AddControl("Text", "F", "x46 y11 w75 h13 ", "Name:")
        this.edtName := this.AddControl("Edit", "edtName", "x87 y6 w299 h23 ", "")
        this.radioBrowse := this.AddControl("Radio", "radioBrowse", "x33 y86 w329 h16 ", "Browse")
        this.radioSelect := this.AddControl("Radio", "radioSelect", "x33 y121 w327 h16 ", "Select using F12")
        this.AddControl("GroupBox", "X", "x6 y62 w380 h159 ", "Select Game Executable")
        this.edtExe := this.AddControl("Edit", "edtExe", "x55 y187 w278 h23 ", "")
        this.AddControl("Text", "Q", "x55 y144 w323 h29 ", "Run the program as the foreground window, then press F12.")
        this.btnOK := this.AddControl("Button", "btnOK", "x148 y224 w75 h23 ", "OK")
        this.AddControl("Button", "btnCanel", "x229 y224 w75 h23 ", "Cancel")
        this.AddControl("Button", "Z", "x310 y224 w75 h23 ", "Help")
    
        this.btnOK.Disable()
        
        this.gui := mainGui
        if (owner)
            this.Owner := owner, this.OwnerAutoClose := 1, this.MinimizeBox := 0
        
        this.Toolwindow := 1
		this.Title := "Profile Manager"pp
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
        file.Filter := "Game (*.exe)"
        if ( file.show() )
            this.edtExe.Text := file.FileName
    }
    
    radioSelect_CheckedChanged()
    {
        SplashTextOn, 200, 50, , Press F12 to select game`nPress ESC to cancel
        ; Set up hotkeys for selecting executable.
        Hotkey, F12, SelectExe, On
        Hotkey, Esc, SelectExe, On
    }
    
    btnCanel_Click()
    {
        this.Loaded := 0
        this.edtName.Text := "", this.edtExe.Text := ""
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
        else if (FileExist(A_ScriptDir . "\Profiles\" . name . ".xml")) ; Profile already exists.
        {
            MsgBox, 52, , Profile already exists.`nWould you like to overwrite it?
            IfMsgBox, No
                return
        }
        else if (this.Loaded)
            FileDelete % this.savedProfile
        
        currentXml := A_ScriptDir . "\Profiles\" . name . ".xml"
        xml := New Xml(currentXml)
        exe := this.edtExe.Text
        
        ; Update values in xml file.
        xml.Set("exe", exe)
        xml.Set("name", name)
        xml.Save(A_ScriptDir . "\Profiles\", name) ; Save xml file.
        
        this.edtName.Text := "", this.edtExe.Text := "", this.Loaded := 0
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
    
}

SelectExe:
    SplashTextOff
    if (A_ThisHotkey = "F12")
    {
        WinGet, exeName, ProcessPath , A
        gui.edtExe.Text := exeName
    }
    Hotkey, F12, Off
    Hotkey, Esc, Off
    WinActivate % "ahk_pid " . DllCall("GetCurrentProcessId")
return