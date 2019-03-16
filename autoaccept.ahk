__determine_imported_string__ := "ornskoldsvik This script (autoaccept) is imported ornskoldsvik" ; This line MUST BE the first line in this file
filereadline, first_line, %a_scriptfullpath%, 1
if (instr(first_line, __determine_imported_string__) || a_iscompiled)
    __script_imported__ := false
else
    __script_imported__ := true


#singleinstance force
#noenv


if (!__script_imported__)
    new Autoaccept() ; no need to save the reference anywhere for the script to work


/*
Autoaccept v1.1.0
author: Iikka Hämäläinen
Importable or runnable utility that lets the user press a hotkey and AFK afterwards, while still being able to
queue for a match in CS:GO and manage to accept the match(es).
*/
class Autoaccept
{
    /*
    Initialises the class and creates all menus and hotkeys.
    */
    __New()
    {
        global __script_imported__
        this.GUITITLE := "Autoaccept"
        this.CONF_PATH := a_scriptdir . "\autoacceptconf.ini"
        this.CONF_SECTION := "Basic"
        this.CONF_ACTIVATION_KEYNAME := "activation_bind"
        this.CONF_DEACTIVATION_KEYNAME := "deactivation_bind"
        this.CONF_EXIT_KEYNAME := "exit_bind"
        this.CONF_AUTOSTART_KEYNAME := "autostartcsgo"
        this.CONF_AUTOEXIT_KEYNAME := "autoexit"
        this.ICO_PATH := a_scriptdir . "\autoaccept.ico"
        this.CSGO_IDENTIFIER := "ahk_exe csgo.exe"
        this.PIXELS_AMOUNT := 50
        this.GREEN_MINIMUM := 100
        this.PIXELS_ERROR_MARGIN := 0.03
        this.GREEN_THRESHOLD_MULTIPLIER := 2.1
        this.AHK_HOTKEYS_PAGE := "https://autohotkey.com/docs/Hotkeys.htm"
        this.GITHUB_PAGE := "https://github.com/Lynxtickler/Autoaccept"
        this.AUTOSTART_ITEM := "Start CS:GO with script"
        this.AUTOEXIT_ITEM := "Exit script with CS:GO"
        this.ACTIVATE_KEY_ITEM := "Choose activate hotkey"
        this.DEACTIVATE_KEY_ITEM := "Choose deactivate hotkey"
        this.EXIT_KEY_ITEM := "Choose exit hotkey"
        this.HELP_SUBMENU := "HelpSubMenu"
        this.HELP_ITEM := "Help"
        this.HELP_DEFAULT_HOTKEY := "! Default activate hotkey is rctrl+a !"
        this.HELP_DOCS_ITEM := "GitHub page"
        this.HELP_HOTKEYS_ITEM := "Help with hotkeys"
        this.RELOAD_ITEM := "Reload this script"
        this.CHANGE_SUBMENU := "ChangeSubMenu"
        this.CHANGE_ITEM := "Change hotkeys"
        this.CHANGE_ACTIVATE_ITEM := "Change activation hotkey"
        this.CHANGE_DEACTIVATE_ITEM := "Change deactivation hotkey"
        this.RESET_ITEM := "Reset to default"
        this.CHANGE_EXIT_ITEM := "Change exit hotkey"
        this.EXIT_ITEM := __script_imported__ ? "Close autoaccept" : "Exit"
        this.MAIN_ITEM := "Autoaccept"
        this.main_submenu := "AutoacceptSubMenu"
        this.main_submenu_colon := ":" . this.main_submenu
        this.autoexit_func_reference := this.AutoExit
        this.AUTOEXIT_TIMER_FREQUENCY := 2000
        this.HOTKEYBOX_W := 330
        this.HOTKEYBOX_H := 130
        this.end_game_wait := false
        this.break_loop := false
        
        if __script_imported__
            msgbox,, % this.GUITITLE, Autoaccept utility started.
        this.CreateMenu()
        this.LoadConfig()
        this.EvaluateAllMenuItems()

        if (this.auto_exit && this.GameWaitLoop())
        {
            bound_function := this.WrapMethod(this.AutoExit)
            settimer, % bound_function, % this.AUTOEXIT_TIMER_FREQUENCY
        }
    }


    /*
    Waits for the game to launch to prevent the script from closing itself while changing settings or so.
    Returns true if CS:GO opened and false if the loop was broken externally by some other function.
    */
    GameWaitLoop()
    {
        csgo_found := false
        loop
        {
            if winexist(this.CSGO_IDENTIFIER)
            {
                csgo_found := true
                break
            }
            if this.end_game_wait
                break
        }
        this.end_game_wait := false
        return csgo_found
    }

    /*
    Binds the passed function so it can be used for hotkeys and returns reference to that bound function.
    Closes script if nonexistent function is passed.
    */
    WrapMethod(function)
    {
        if !isfunc(function)
        {
            msgbox,, % this.GUITITLE, Could not bind a nonexistent function.
            this.ExitUtility()
        }
        fun := function.Bind(this)
        return fun
    }

    /*
    Loads the configuration file, creates one if there's none present, and loads the settings.
    Also initialises hotkeys and launches CS:GO if config says so.
    */
    LoadConfig()
    {
        global instance, ExitWrapper
        instance := this
        if !fileexist(this.CONF_PATH)
        {
            if !this.WriteDefaultConf()
                this.ExitUtility()
            msgbox,, % this.GUITITLE, % "First time initialisation:`nplaced configuration file to path " . this.CONF_PATH
        }
        iniread, start_csgo, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_AUTOSTART_KEYNAME, 0
        iniread, auto_exit, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_AUTOEXIT_KEYNAME, 0
        iniread, activation_hotkey, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_ACTIVATION_KEYNAME, Error
        iniread, deactivation_hotkey, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_DEACTIVATION_KEYNAME, Error
        iniread, exit_hotkey, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_EXIT_KEYNAME, Error
        this.start_csgo := start_csgo
        this.auto_exit :=auto_exit
        this.activation_hotkey := activation_hotkey
        this.deactivation_hotkey := deactivation_hotkey
        this.exit_hotkey := exit_hotkey
        if (this.activation_hotkey = "Error" || this.deactivation_hotkey = "Error" || this.exit_hotkey = "Error")
        {
            msgbox,, % this.GUITITLE, Cannot read configuration. Using default settings.
            this.AssignDefaultConf()
        }
        this.CreateAllHotkeys()
        if (this.start_csgo && !winexist(this.CSGO_IDENTIFIER))
            run, steam://rungameid/730
    }

    
    /*
    Resets program default settings.
    */
    ResetToDefault()
    {
        this.DisableCurrentHotkeys()
        this.WriteDefaultConf()
        this.AssignDefaultVars()
        this.CreateAllHotkeys()
    }


    /*
    Disable all hotkeys within this utility
    */
    DisableCurrentHotkeys()
    {
        hotkey, % this.activation_hotkey, off
        hotkey, % this.deactivation_hotkey, off
        hotkey, % this.exit_hotkey, off
    }


    /*
    Writes default settings to config file.
    Returns whether succeeded or not.
    */
    WriteDefaultConf()
    {
        try
        {
            iniwrite, >^a, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_ACTIVATION_KEYNAME
            iniwrite, >^a, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_DEACTIVATION_KEYNAME
            iniwrite, ^q, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_EXIT_KEYNAME
            iniwrite, 0, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_AUTOSTART_KEYNAME
            iniwrite, 0, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_AUTOEXIT_KEYNAME
            return true
        }
        catch, e
        {
            msgbox,, % this.GUITITLE, Cannot write config`n%e%
            return false
        }
    }


    /*
    Changes class variables to the default ones.
    */
    AssignDefaultConf()
    {
        this.start_csgo := 0
        this.auto_exit := 0
        this.activation_hotkey := ">^a"
        this.deactivation_hotkey := ">^a"
        this.exit_hotkey := "^q"
    }


    /*
    Creates all script hotkeys.
    */
    CreateAllHotkeys()
    {
        bound_exit_func := this.WrapMethod(this.ExitUtility)
        bound_accept_func := this.WrapMethod(this.AcceptLoop)
        bound_kill_func := this.WrapMethod(this.KillLoop)
        hotkey, % this.exit_hotkey, % bound_exit_func, on
        hotkey, % this.activation_hotkey, % bound_accept_func, on
        if (this.activation_hotkey != this.deactivation_hotkey)
            hotkey, % this.deactivation_hotkey, % bound_kill_func, on t2
    }

    /*
    Creates tray menu and assigns the icon.
    */
    CreateMenu()
    {
        global __script_imported__
        ; Thanks to AutoHotkey's extraordinary OOP and "command" utilisation, function references had to be done this way
        submenu1 := ":" . this.HELP_SUBMENU
        submenu2 := ":" . this.CHANGE_SUBMENU
        func1 := this.WrapMethod(this.Useless)
        func2 := this.WrapMethod(this.OpenGitHub)
        func3 := this.WrapMethod(this.OpenHotkeysPage)
        func4 := this.WrapMethod(this.Reloader)
        func5 := this.WrapMethod(this.ToggleAutoStart)
        func6 := this.WrapMethod(this.ToggleAutoExit)
        func7 := this.WrapMethod(this.ChangeHotkey)
        func8 := this.WrapMethod(this.ResetToDefault)
        func9 := this.WrapMethod(this.ExitUtility)
        if !__script_imported__
        {
            this.main_submenu := "tray"
            menu, tray,                 tip, Autoaccept
            menu, tray,                 nostandard
            menu, tray,                 icon, % this.ICO_PATH
        }
        menu, % this.HELP_SUBMENU,      add, % this.HELP_DEFAULT_HOTKEY, % func1
        menu, % this.HELP_SUBMENU,      add, % this.HELP_DOCS_ITEM, % func2
        menu, % this.HELP_SUBMENU,      add, % this.HELP_HOTKEYS_ITEM, % func3
        menu, % this.main_submenu,      add, % this.HELP_ITEM, % submenu1
        menu, % this.main_submenu,      add, % this.RELOAD_ITEM, % func4
        menu, % this.main_submenu,      add, % this.AUTOSTART_ITEM, % func5
        menu, % this.main_submenu,      add, % this.AUTOEXIT_ITEM, % func6
        menu, % this.CHANGE_SUBMENU,    add, % this.CHANGE_ACTIVATE_ITEM, % func7
        menu, % this.CHANGE_SUBMENU,    add, % this.CHANGE_DEACTIVATE_ITEM, % func7
        menu, % this.CHANGE_SUBMENU,    add, % this.CHANGE_EXIT_ITEM, % func7
        menu, % this.main_submenu,      add, % this.CHANGE_ITEM, % submenu2
        menu, % this.main_submenu,      add, % this.RESET_ITEM, % func8
        menu, % this.main_submenu,      add, % this.EXIT_ITEM, % func9
        if __script_imported__
        {
            ;menu, tray,                 add
            menu, tray,                 add, % this.main_item, % this.main_submenu_colon
        }
    }


    /*
    Changes any of the program's hotkeys. On invalid user input asks again until cancelled or answered correctly.
    */
    ChangeHotkey()
    {
        if (a_thismenuitem = this.CHANGE_ACTIVATE_ITEM)
        {
            which_hotkey := 2
            target_setting := this.CONF_ACTIVATION_KEYNAME
            action_func := this.WrapMethod(this.AcceptLoop)
            current_hotkey := this.activation_hotkey
            opposite_hotkey := this.deactivation_hotkey
            opposite_action := this.WrapMethod(this.KillLoop)
        }
        else if (a_thismenuitem = this.CHANGE_DEACTIVATE_ITEM)
        {
            which_hotkey := 1
            target_setting := this.CONF_DEACTIVATION_KEYNAME
            action_func := this.WrapMethod(this.KillLoop)
            current_hotkey := this.deactivation_hotkey
            opposite_hotkey := this.activation_hotkey
            opposite_action := this.WrapMethod(this.AcceptLoop)
        }
        else if (a_thismenuitem = this.CHANGE_EXIT_ITEM)
        {
            which_hotkey := 0
            target_setting := this.CONF_EXIT_KEYNAME
            action_func := this.WrapMethod(this.ExitUtility)
            current_hotkey := this.exit_hotkey
        }
        else
            return
        loop
        {
            inputbox, user_input, % this.GUITITLE, %a_thismenuitem%,, % this.HOTKEYBOX_W, % this.HOTKEYBOX_H,,,,,%current_hotkey%
            if errorlevel
                return
            if (!which_hotkey && (user_input = this.activation_hotkey || user_input = this.deactivation_hotkey))
            {
                msgbox,, % this.GUITITLE, Hotkey already in use
                continue
            }
            try
            {
                if (which_hotkey = 2)
                    this.activation_hotkey := user_input
                else if (which_hotkey = 1)
                    this.deactivation_hotkey := user_input
                else if (which_hotkey = 0)
                    this.exit_hotkey := user_input
                additional_thread := (user_input = opposite_hotkey) ? "t2" : ""
                hotkey, % user_input, % action_func, on %additional_thread%
                if opposite_hotkey
                    hotkey, % opposite_hotkey, % opposite_action, on
                iniwrite, % user_input, % this.CONF_PATH, % this.CONF_SECTION, % target_setting
                break
            }
            catch, e
            {
                msgbox,, % this.GUITITLE, % "Error assigning hotkey. Check input validity from " . this.HELP_ITEM . " -> " . this.HELP_HOTKEYS_ITEM . ".`n" . e
                ; TODO: first time changing exit hotkey ends up here
            }
        }
    }


    Useless()
    {
        return ; not meant to do anything
    }


    Reloader()
    {
        reload
    }


    OpenGitHub()
    {
        run, % this.GITHUB_PAGE
    }


    OpenHotkeysPage()
    {
        run, % this.AHK_HOTKEYS_PAGE
    }


    /*
    Toggles CS:GO autostart and updates it to the menu and .ini file.
    */
    ToggleAutoStart()
    {
        this.start_csgo := !this.start_csgo
        this.EvaluateAutoStartMenuItem()
        iniwrite, % this.start_csgo, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_AUTOSTART_KEYNAME
    }


    /*
    Toggles script automatic termination on CS:GO closing, and updates it to the menu and .ini file.
    */
    ToggleAutoExit()
    {
        this.auto_exit := !this.auto_exit
        this.EvaluateAutoExitMenuItem()
        iniwrite, % this.auto_exit, % this.CONF_PATH, % this.CONF_SECTION, % this.CONF_AUTOEXIT_KEYNAME
        bound_function := this.WrapMethod(this.AutoExit)
        if this.auto_exit
        {
            if this.GameWaitLoop()
                settimer, % bound_function, % this.AUTOEXIT_TIMER_FREQUENCY
        }
        else
        {
            this.end_game_wait := true
            settimer, % bound_function, off
        }
    }


    /*
    Adds checkboxes to the options that should display one.
    */
    EvaluateAllMenuItems()
    {
        this.EvaluateAutoStartMenuItem()
        this.EvaluateAutoExitMenuItem()
    }


    /*
    Checks or unchecks autostart menu item.
    */
    EvaluateAutoStartMenuItem()
    {
        invert := this.start_csgo ? "" : "un"
        menu, % this.main_submenu, %invert%check, % this.AUTOSTART_ITEM
    }


    /*
    Checks or unchecks autoexit menu item.
    */
    EvaluateAutoExitMenuItem()
    {
        invert := this.auto_exit ? "" : "un"
        menu, % this.main_submenu, %invert%check, % this.AUTOEXIT_ITEM
    }


    /*
    The main accept button checking loop. Checks a defined amount of pixels towards left and right from the middle of the screen
    and if most of them are green and bright enough, clicks in the middle of the screen. The accept dialog and button are always
    located here in panorama UI, regardless of resolution so consistent and robust behaviour is to be expected.
    Returns immediately if CS:GO isn't active.
    */
    AcceptLoop()
    {
        if !winactive(this.CSGO_IDENTIFIER)
        {
            if (this.activation_hotkey = this.deactivation_hotkey)
            {
                bound_function := this.WrapMethod(this.AcceptLoop)
                hotkey, % this.activation_hotkey, % bound_function, on t2
            }
            this.break_loop := false
            return
        }
        break_loop := false
        if (this.activation_hotkey = this.deactivation_hotkey)
        {
            bound_function := this.WrapMethod(this.KillLoop)
            hotkey, % this.activation_hotkey, % bound_function, on t2
        }
        wingetpos, window_x, window_y, window_width, window_height, a
        tooltext =
        pixel_x := window_x + window_width / 2 - this.PIXELS_AMOUNT / 2
        pixel_y := floor(window_height / 2)
        loop
        {
            if this.break_loop
                break
            tooltip, % "Autoaccept running...`nDeactivate: " . this.deactivation_hotkey . "`nexit: " . this.exit_hotkey, %window_x%, %window_y%0
            if !winactive(CSGO_IDENTIFIER)
                continue
            subsequent_green_pixels := 0
            loop, % this.PIXELS_AMOUNT
            {
                px := pixel_x + a_index
                pixelgetcolor, pixelcolour, pixel_x + a_index, pixel_y
                pixelcolour := format("{1:X}", pixelcolour + 0)
                pixel_r := format("{1:d}", "0x" . substr(pixelcolour, 1, 2))
                pixel_g := format("{1:d}", "0x" . substr(pixelcolour, 3, 2))
                pixel_b := format("{1:d}", "0x" . substr(pixelcolour, 5, 2))
                
                if (pixel_g > this.GREEN_MINIMUM && pixel_g > pixel_r * this.GREEN_THRESHOLD_MULTIPLIER && pixel_g > pixel_b * this.GREEN_THRESHOLD_MULTIPLIER)
                {
                    subsequent_green_pixels++
                }
            }
            if (subsequent_green_pixels > this.PIXELS_AMOUNT - this.PIXELS_AMOUNT * this.PIXELS_ERROR_MARGIN)
            {
                clickx := window_x + window_width / 2
                clicky := pixel_y + 1
                click, %clickx%, %clicky%
            }
        }
        if (this.activation_hotkey = this.deactivation_hotkey)
        {
            bound_function := this.WrapMethod(this.AcceptLoop)
            hotkey, % this.activation_hotkey, % bound_function, on t2
        }
        this.break_loop := false
        tooltip
    }


    KillLoop()
    {
        this.break_loop := true
    }


    AutoExit()
    {
        if !winexist(this.CSGO_IDENTIFIER)
            this.ExitUtility()
    }


    /*
    Exit script if not imported, otherwise call a function that erases tray menus, hotkeys and memory associated with this utility
    */
    ExitUtility()
    {
        global __script_imported__
        if (__script_imported__)
            this.DestroyObject()
        else
            exitapp
    }
    

    /*
    Destroys hotkeys and tray menus, and frees the memory this utility is using
    */
    DestroyObject()
    {
        menu, tray, delete, % this.main_item
        this.DisableCurrentHotkeys()
        this.remove("", chr(255))
        this.setcapacity(0)
        this.base := ""
        msgbox,, % this.GUITITLE, Autoaccept utility closed.
    }
}
