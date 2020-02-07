#singleinstance force


/*
Autoaccept v2.0.4
author: Iikka Hämäläinen
Importable or runnable utility that lets the user press a hotkey and AFK afterwards, while still being able to
queue for a match in CS:GO and manage to accept the match(es).
*/
class Autoaccept
{
    static initialised := false

    /*
    Starts the autoaccept loop
    */
    Execute()
    {
        if !Autoaccept.initialised
        {
            Autoaccept.Initialise()
            ;msgbox,, % Autoaccept.GUITITLE, Autoaccept not initialised. Call 'Autoaccept.Initialise()' to manually initialise the class.
        }
        Autoaccept.AcceptLoop()
    }


    /*
    Initialises the class and creates all menus and hotkeys.
    */
    Initialise()
    {
        global __script_imported__

        if (a_scriptfullpath = a_linefile or a_iscompiled)
            __script_imported__ := false
        else
            __script_imported__ := true

        Autoaccept.LOG_PATH := a_iscompiled ? a_scriptfullpath : a_scriptdir . "\log.txt"
        Autoaccept.GUITITLE := "Autoaccept"
        Autoaccept.ICO_PATH := a_iscompiled ? a_scriptfullpath : a_scriptdir . "\autoaccept.ico"
        Autoaccept.CONF_PATH := a_scriptdir . "\autoacceptconf.ini"
        Autoaccept.CONF_SECTION := "Basic"
        Autoaccept.CONF_ACTIVATION_KEYNAME := "activation_bind"
        Autoaccept.CONF_DEACTIVATION_KEYNAME := "deactivation_bind"
        Autoaccept.CONF_EXIT_KEYNAME := "exit_bind"
        Autoaccept.CONF_AUTOSTART_KEYNAME := "autostartcsgo"
        Autoaccept.CONF_AUTOEXIT_KEYNAME := "autoexit"
        Autoaccept.CONF_SHOW_DIALOGS := "startdialog"

        Autoaccept.DEFAULT_ACTIVATION_HOTKEY := ">^a"
        Autoaccept.DEFAULT_DEACTIVATION_HOTKEY := ">^a"
        Autoaccept.DEFAULT_EXIT_HOTKEY := "^q"
        Autoaccept.DEFAULT_SHOW_DIALOGS := 1
        Autoaccept.DEFAULT_START_CSGO := 0
        Autoaccept.DEFAULT_AUTO_EXIT := 0

        Autoaccept.CSGO_IDENTIFIER := "ahk_exe csgo.exe"
        Autoaccept.PIXELS_AMOUNT := 50
        Autoaccept.GREEN_MINIMUM := 150
        Autoaccept.PIXELS_ERROR_MARGIN := 0.03
        Autoaccept.GREEN_MULTIPLIER_THRESHOLD := 2.0
        Autoaccept.BUTTON_OFFSET_LIMIT_PERCENTAGE := 0.08

        Autoaccept.AHK_HOTKEYS_PAGE := "https://autohotkey.com/docs/Hotkeys.htm"
        Autoaccept.GITHUB_PAGE := "https://github.com/Lynxtickler/Autoaccept"
        Autoaccept.AUTOSTART_ITEM := "Start CS:GO with script"
        Autoaccept.AUTOEXIT_ITEM := "Exit script with CS:GO"
        Autoaccept.SHOW_DIALOG_ITEM := "Show dialogs on utility start/exit"
        Autoaccept.ACTIVATE_KEY_ITEM := "Choose activate hotkey"
        Autoaccept.DEACTIVATE_KEY_ITEM := "Choose deactivate hotkey"
        Autoaccept.EXIT_KEY_ITEM := "Choose exit hotkey"
        Autoaccept.HELP_SUBMENU := "aa_HelpSubMenu"
        Autoaccept.HELP_ITEM := "Help"
        Autoaccept.HELP_DEFAULT_HOTKEY := "Default activate hotkey is rctrl+a"
        Autoaccept.HELP_DOCS_ITEM := "GitHub page"
        Autoaccept.HELP_HOTKEYS_ITEM := "Help with hotkeys"
        Autoaccept.RELOAD_ITEM := "Reload this script"
        Autoaccept.CHANGE_SUBMENU := "aa_ChangeSubMenu"
        Autoaccept.CHANGE_ITEM := "Change hotkeys"
        Autoaccept.CHANGE_ACTIVATE_ITEM := "Change activation hotkey"
        Autoaccept.CHANGE_DEACTIVATE_ITEM := "Change deactivation hotkey"
        Autoaccept.RESET_ITEM := "Reset to default"
        Autoaccept.CHANGE_EXIT_ITEM := "Change exit hotkey"
        Autoaccept.EXIT_ITEM := __script_imported__ ? "Close autoaccept" : "Exit"
        Autoaccept.MAIN_ITEM := "Autoaccept"
        Autoaccept.HELP_BASE := "Activate hotkey is "
        Autoaccept.help_hotkey := ""

        Autoaccept.AUTOEXIT_TIMER_FREQUENCY := 2000
        Autoaccept.HOTKEYBOX_W := 330
        Autoaccept.HOTKEYBOX_H := 130
        Autoaccept.main_submenu := "aa_AutoacceptSubMenu"
        Autoaccept.main_submenu_colon := ":" . Autoaccept.main_submenu
        Autoaccept.autoexit_func_reference := Autoaccept.AutoExit
        Autoaccept.end_game_wait := false
        Autoaccept.break_loop := false
        Autoaccept.loop_active := false
        Autoaccept.running := true
        Autoaccept.LoadConfig()
        Autoaccept.CreateAllHotkeys()
        if (Autoaccept.start_csgo && !winexist(Autoaccept.CSGO_IDENTIFIER))
            run, steam://rungameid/730
        if Autoaccept.show_dialogs
            msgbox,, % Autoaccept.GUITITLE, Autoaccept utility started.
        Autoaccept.CreateMenu()
        Autoaccept.initialised := true
        if (!__script_imported__ && Autoaccept.auto_exit && Autoaccept.GameWaitLoop())
        {
            bound_function := Autoaccept.WrapMethod(Autoaccept.AutoExit)
            settimer, % bound_function, % Autoaccept.AUTOEXIT_TIMER_FREQUENCY
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
            if winexist(Autoaccept.CSGO_IDENTIFIER)
            {
                csgo_found := true
                break
            }
            if Autoaccept.end_game_wait
                break
        }
        Autoaccept.end_game_wait := false
        return csgo_found
    }

    /*
    Binds the passed function so it can be used for hotkeys and returns reference to that bound function.
    Closes script if nonexistent function is passed.
    */
    WrapMethod(function)
    {
        global __script_imported__
        if !isfunc(function)
        {
            msgbox,, % Autoaccept.GUITITLE, Could not bind a nonexistent function.
            if !__script_imported__
                Autoaccept.ExitUtility()
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
        global __script_imported__, ExitWrapper
        if !fileexist(Autoaccept.CONF_PATH)
        {
            if !Autoaccept.WriteDefaultConf()
                Autoaccept.ExitUtility()
            msgbox,, % Autoaccept.GUITITLE, % "First time initialisation:`nplaced configuration file to path " . Autoaccept.CONF_PATH
        }
        iniread, start_csgo,            % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_AUTOSTART_KEYNAME, 0
        iniread, auto_exit,             % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_AUTOEXIT_KEYNAME, 0
        iniread, activation_hotkey,     % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_ACTIVATION_KEYNAME, Error
        iniread, deactivation_hotkey,   % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_DEACTIVATION_KEYNAME, Error
        iniread, show_dialogs,          % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_SHOW_DIALOGS, 1
        if !__script_imported__
        {
            iniread, exit_hotkey,           % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_EXIT_KEYNAME, Error
            Autoaccept.exit_hotkey := exit_hotkey
        }
        Autoaccept.help_hotkey := Autoaccept.HELP_BASE . activation_hotkey
        Autoaccept.start_csgo := start_csgo
        Autoaccept.auto_exit := auto_exit
        Autoaccept.activation_hotkey := activation_hotkey
        Autoaccept.deactivation_hotkey := deactivation_hotkey
        Autoaccept.show_dialogs := show_dialogs
        if (Autoaccept.activation_hotkey = "Error" || Autoaccept.deactivation_hotkey = "Error" || Autoaccept.exit_hotkey = "Error")
        {
            msgbox,, % Autoaccept.GUITITLE, Cannot read configuration. Using default settings.
            Autoaccept.AssignDefaultConf()
        }
    }

    /*
    Resets program default settings.
    */
    ResetToDefault()
    {
        Autoaccept.DisableCurrentHotkeys()
        Autoaccept.WriteDefaultConf()
        Autoaccept.AssignDefaultConf()
        Autoaccept.CreateAllHotkeys()
        Autoaccept.EvaluateAllMenuItems()
    }

    /*
    Disable all hotkeys within this utility.
    */
    DisableCurrentHotkeys()
    {
        global __script_imported__
        hotkey, % Autoaccept.activation_hotkey, off
        hotkey, % Autoaccept.deactivation_hotkey, off
        if !__script_imported__
            hotkey, % Autoaccept.exit_hotkey, off
    }

    /*
    Writes default settings to config file.
    Returns whether succeeded or not.
    */
    WriteDefaultConf()
    {
        global __script_imported__
        try
        {
            iniwrite, % Autoaccept.DEFAULT_ACTIVATION_HOTKEY, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_ACTIVATION_KEYNAME
            iniwrite, % Autoaccept.DEFAULT_DEACTIVATION_HOTKEY, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_DEACTIVATION_KEYNAME
            iniwrite, % Autoaccept.DEFAULT_SHOW_DIALOGS, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_SHOW_DIALOGS
            if !__script_imported__
            {
                iniwrite, % Autoaccept.DEFAULT_EXIT_HOTKEY, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_EXIT_KEYNAME
                iniwrite, % Autoaccept.DEFAULT_START_CSGO, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_AUTOSTART_KEYNAME
                iniwrite, % Autoaccept.DEFAULT_AUTO_EXIT, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_AUTOEXIT_KEYNAME
            }
            return true
        }
        catch, e
        {
            msgbox,, % Autoaccept.GUITITLE, Cannot write config`n%e%
            return false
        }
    }

    /*
    Changes class variables to the default ones.
    */
    AssignDefaultConf()
    {
        global __script_imported__
        Autoaccept.help_hotkey := ""
        Autoaccept.activation_hotkey := Autoaccept.DEFAULT_ACTIVATION_HOTKEY
        Autoaccept.deactivation_hotkey := Autoaccept.DEFAULT_DEACTIVATION_HOTKEY
        Autoaccept.show_dialogs := Autoaccept.DEFAULT_SHOW_DIALOGS
        if !__script_imported__
        {
            Autoaccept.start_csgo := Autoaccept.DEFAULT_START_CSGO
            Autoaccept.exit_hotkey := Autoaccept.DEFAULT_EXIT_HOTKEY
            Autoaccept.auto_exit := Autoaccept.DEFAULT_AUTO_EXIT
        }
    }

    /*
    Creates all script hotkeys.
    */
    CreateAllHotkeys()
    {
        global __script_imported__
        bound_exit_func := Autoaccept.WrapMethod(Autoaccept.ExitUtility)
        bound_accept_func := Autoaccept.WrapMethod(Autoaccept.Execute)
        bound_kill_func := Autoaccept.WrapMethod(Autoaccept.KillLoop)
        if !__script_imported__
            hotkey, % Autoaccept.exit_hotkey, % bound_exit_func, on
        hotkey, % Autoaccept.activation_hotkey, % bound_accept_func, on
        if (Autoaccept.activation_hotkey != Autoaccept.deactivation_hotkey)
            hotkey, % Autoaccept.deactivation_hotkey, % bound_kill_func, on t2
    }

    /*
    Creates tray menu and assigns the icon.
    */
    CreateMenu()
    {
        global __script_imported__
        ; Thanks to AutoHotkey's extraordinary behaviour function references had to be done this way
        submenu1 := ":" . Autoaccept.HELP_SUBMENU
        submenu2 := ":" . Autoaccept.CHANGE_SUBMENU
        func1 := Autoaccept.WrapMethod(Autoaccept.Useless)
        func2 := Autoaccept.WrapMethod(Autoaccept.OpenGitHub)
        func3 := Autoaccept.WrapMethod(Autoaccept.OpenHotkeysPage)
        func4 := Autoaccept.WrapMethod(Autoaccept.Reloader)
        func5 := Autoaccept.WrapMethod(Autoaccept.ToggleAutoStart)
        func6 := Autoaccept.WrapMethod(Autoaccept.ToggleAutoExit)
        func7 := Autoaccept.WrapMethod(Autoaccept.ChangeHotkey)
        func8 := Autoaccept.WrapMethod(Autoaccept.ResetToDefault)
        func9 := Autoaccept.WrapMethod(Autoaccept.ExitUtility)
        func10 := Autoaccept.WrapMethod(Autoaccept.ToggleShowDialogs)
        if !__script_imported__
        {
            Autoaccept.main_submenu := "tray"
            menu, tray,                 tip, Autoaccept
            menu, tray,                 nostandard
            if fileexist(Autoaccept.ICO_PATH)
                menu, tray,             icon, % Autoaccept.ICO_PATH
        }
        menu, % Autoaccept.HELP_SUBMENU,      add, % Autoaccept.HELP_DEFAULT_HOTKEY, % func1
        menu, % Autoaccept.HELP_SUBMENU,      add, % Autoaccept.HELP_DOCS_ITEM, % func2
        menu, % Autoaccept.HELP_SUBMENU,      add, % Autoaccept.HELP_HOTKEYS_ITEM, % func3
        menu, % Autoaccept.main_submenu,      add, % Autoaccept.HELP_ITEM, % submenu1
        menu, % Autoaccept.main_submenu,      add, % Autoaccept.RELOAD_ITEM, % func4
        if !__script_imported__
        {
            menu, % Autoaccept.main_submenu,  add, % Autoaccept.AUTOSTART_ITEM, % func5
            menu, % Autoaccept.main_submenu,  add, % Autoaccept.AUTOEXIT_ITEM, % func6
        }
        menu, % Autoaccept.main_submenu,      add, % Autoaccept.SHOW_DIALOG_ITEM, % func10
        menu, % Autoaccept.CHANGE_SUBMENU,    add, % Autoaccept.CHANGE_ACTIVATE_ITEM, % func7
        menu, % Autoaccept.CHANGE_SUBMENU,    add, % Autoaccept.CHANGE_DEACTIVATE_ITEM, % func7
        if !__script_imported__
            menu, % Autoaccept.CHANGE_SUBMENU,add, % Autoaccept.CHANGE_EXIT_ITEM, % func7
        menu, % Autoaccept.main_submenu,      add, % Autoaccept.CHANGE_ITEM, % submenu2
        menu, % Autoaccept.main_submenu,      add, % Autoaccept.RESET_ITEM, % func8
        if !__script_imported__
            menu, % Autoaccept.main_submenu,  add, % Autoaccept.EXIT_ITEM, % func9
        else
            menu, tray,                       add, % Autoaccept.main_item, % Autoaccept.main_submenu_colon
        Autoaccept.EvaluateAllMenuItems()
    }

    /*
    Changes any of the program's hotkeys. On invalid user input asks again until cancelled or answered correctly.
    */
    ChangeHotkey()
    {
        if (a_thismenuitem = Autoaccept.CHANGE_ACTIVATE_ITEM)
        {
            which_hotkey := 2
            target_setting := Autoaccept.CONF_ACTIVATION_KEYNAME
            action_func := Autoaccept.WrapMethod(Autoaccept.AcceptLoop)
            current_hotkey := Autoaccept.activation_hotkey
            opposite_hotkey := Autoaccept.deactivation_hotkey
            opposite_action := Autoaccept.WrapMethod(Autoaccept.KillLoop)
        }
        else if (a_thismenuitem = Autoaccept.CHANGE_DEACTIVATE_ITEM)
        {
            which_hotkey := 1
            target_setting := Autoaccept.CONF_DEACTIVATION_KEYNAME
            action_func := Autoaccept.WrapMethod(Autoaccept.KillLoop)
            current_hotkey := Autoaccept.deactivation_hotkey
            opposite_hotkey := Autoaccept.activation_hotkey
            opposite_action := Autoaccept.WrapMethod(Autoaccept.AcceptLoop)
        }
        else if (a_thismenuitem = Autoaccept.CHANGE_EXIT_ITEM)
        {
            which_hotkey := 0
            target_setting := Autoaccept.CONF_EXIT_KEYNAME
            action_func := Autoaccept.WrapMethod(Autoaccept.ExitUtility)
            current_hotkey := Autoaccept.exit_hotkey
        }
        else
            return
        loop
        {
            inputbox, user_input, % Autoaccept.GUITITLE, %a_thismenuitem%,, % Autoaccept.HOTKEYBOX_W, % Autoaccept.HOTKEYBOX_H,,,,,%current_hotkey%
            if errorlevel
                return
            if (!which_hotkey && (user_input = Autoaccept.activation_hotkey || user_input = Autoaccept.deactivation_hotkey))
            {
                msgbox,, % Autoaccept.GUITITLE, Hotkey already in use
                continue
            }
            try
            {
                if (which_hotkey = 2)
                {
                    Autoaccept.activation_hotkey := user_input
                    Autoaccept.help_hotkey := Autoaccept.HELP_BASE . user_input
                    Autoaccept.UpdateHelpItem()
                }
                else if (which_hotkey = 1)
                    Autoaccept.deactivation_hotkey := user_input
                else if (which_hotkey = 0)
                    Autoaccept.exit_hotkey := user_input
                additional_thread := (user_input = opposite_hotkey) ? "t2" : ""
                hotkey, % user_input, % action_func, on %additional_thread%
                if opposite_hotkey
                    hotkey, % opposite_hotkey, % opposite_action, on
                iniwrite, % user_input, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % target_setting
                break
            }
            catch, e
            {
                msgbox,, % Autoaccept.GUITITLE, % "Error assigning hotkey. Check input validity from " . Autoaccept.HELP_ITEM . " -> " . Autoaccept.HELP_HOTKEYS_ITEM . ".`n" . e
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
        run, % Autoaccept.GITHUB_PAGE
    }

    OpenHotkeysPage()
    {
        run, % Autoaccept.AHK_HOTKEYS_PAGE
    }

    /*
    Toggles CS:GO autostart and updates it to the menu and .ini file.
    */
    ToggleAutoStart()
    {
        Autoaccept.start_csgo := !Autoaccept.start_csgo
        Autoaccept.EvaluateMenuItem(Autoaccept.start_csgo, Autoaccept.AUTOSTART_ITEM)
        iniwrite, % Autoaccept.start_csgo, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_AUTOSTART_KEYNAME
    }

    /*
    Toggles script automatic termination on CS:GO closing, and updates it to the menu and .ini file.
    */
    ToggleAutoExit()
    {
        Autoaccept.auto_exit := !Autoaccept.auto_exit
        Autoaccept.EvaluateMenuItem(Autoaccept.auto_exit, Autoaccept.AUTOEXIT_ITEM)
        iniwrite, % Autoaccept.auto_exit, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_AUTOEXIT_KEYNAME
        bound_function := Autoaccept.WrapMethod(Autoaccept.AutoExit)
        if Autoaccept.auto_exit
        {
            if Autoaccept.GameWaitLoop()
                settimer, % bound_function, % Autoaccept.AUTOEXIT_TIMER_FREQUENCY
        }
        else
        {
            Autoaccept.end_game_wait := true
            settimer, % bound_function, off
        }
    }

    /*
    Toggles the setting that determines if imported script shows a messagebox upon starting and closing.
    */
    ToggleShowDialogs()
    {
        Autoaccept.show_dialogs := !Autoaccept.show_dialogs
        Autoaccept.EvaluateMenuItem(Autoaccept.show_dialogs, Autoaccept.SHOW_DIALOG_ITEM)
        iniwrite, % Autoaccept.show_dialogs, % Autoaccept.CONF_PATH, % Autoaccept.CONF_SECTION, % Autoaccept.CONF_SHOW_DIALOGS
    }

    /*
    Adds checkboxes to the options that should display one.
    */
    EvaluateAllMenuItems()
    {
        global __script_imported__
        item_pairs := {Autoaccept.show_dialogs: Autoaccept.SHOW_DIALOG_ITEM}
        if !__script_imported__
        {
            item_pairs[Autoaccept.start_csgo] := Autoaccept.AUTOSTART_ITEM
            item_pairs[Autoaccept.auto_exit] := Autoaccept.AUTOEXIT_ITEM
        }
        for var, menu_item in item_pairs
            Autoaccept.EvaluateMenuItem(var, menu_item)
        Autoaccept.UpdateHelpItem()
    }

    /*
    Checks or unchecks a menu item based on the passed variable.
    */
    EvaluateMenuItem(check_var, byref menu_item)
    {
        invert := check_var ? "" : "un"
        menu, % Autoaccept.main_submenu, %invert%check, % menu_item
    }

    /*
    Updates help item on the tray menu.
    */
    UpdateHelpItem()
    {
        new_text := Autoaccept.help_hotkey ? Autoaccept.help_hotkey : Autoaccept.HELP_DEFAULT_HOTKEY
        menu, % Autoaccept.HELP_SUBMENU, rename, 1&, % new_text
    }

    /*
    The main accept button checking loop. Checks a defined amount of pixels towards left and right from near the middle of the screen
    and if most of them are green and bright enough, clicks in the middle of the screen. The accept dialog and button are always
    located here in panorama UI, regardless of resolution so consistent and robust behaviour is to be expected. Thresholds and other
    values regarding pixel inspection are assigned to class variables.

    Returns immediately if CS:GO isn't active.
    */
    AcceptLoop()
    {
        global __script_imported__
        Autoaccept.loop_active := true
        if !winactive(Autoaccept.CSGO_IDENTIFIER)
        {
            if (Autoaccept.activation_hotkey = Autoaccept.deactivation_hotkey)
            {
                bound_function := Autoaccept.WrapMethod(Autoaccept.AcceptLoop)
                hotkey, % Autoaccept.activation_hotkey, % bound_function, on t2
            }
            Autoaccept.break_loop := false
            Autoaccept.loop_active := false
            return
        }
        active_coordmodepixel := a_coordmodepixel
        active_coordmodetooltip := a_coordmodetooltip
        active_coordmodemouse := a_coordmodemouse
        coordmode, pixel, window
        coordmode, tooltip, window
        coordmode, mouse, window
        break_loop := false
        if (Autoaccept.activation_hotkey = Autoaccept.deactivation_hotkey)
        {
            bound_function := Autoaccept.WrapMethod(Autoaccept.KillLoop)
            hotkey, % Autoaccept.activation_hotkey, % bound_function, on t2
        }
        tooltext =
        wingetpos, window_x, window_y, window_width, window_height, a
        pixel_x := floor(window_width / 2 - Autoaccept.PIXELS_AMOUNT / 2)
        pixel_y := floor(window_height / 2)
        vertical_check_limit := pixel_y + pixel_y * Autoaccept.BUTTON_OFFSET_LIMIT_PERCENTAGE
        loop
        {
            if Autoaccept.break_loop or !winactive(CSGO_IDENTIFIER)
                break
            tooladdition := ""
            tooltext := "Autoaccept running...`nDeactivate: " . Autoaccept.deactivation_hotkey . tooladdition
            if !__script_imported__
                tooltext := tooltext . "`nexit: " . Autoaccept.exit_hotkey
            tooltip, % tooltext, 1, 1
            green_pixels := 0
            if Autoaccept.IsPixelGreenEnough(pixel_x, pixel_y)
            {
                loop, % Autoaccept.PIXELS_AMOUNT
                {
                    if Autoaccept.IsPixelGreenEnough(pixel_x, pixel_y, a_index)
                        green_pixels++
                }
            }
            if (green_pixels > Autoaccept.PIXELS_AMOUNT - Autoaccept.PIXELS_AMOUNT * Autoaccept.PIXELS_ERROR_MARGIN)
            {
                click, %pixel_x%, %pixel_y%
            }
            if pixel_y + 0 < vertical_check_limit
                pixel_y++
            else
                pixel_y := floor(window_height / 2)
        }

        if (Autoaccept.activation_hotkey = Autoaccept.deactivation_hotkey)
        {
            bound_function := Autoaccept.WrapMethod(Autoaccept.AcceptLoop)
            hotkey, % Autoaccept.activation_hotkey, % bound_function, on t2
        }
        coordmode, pixel, % active_coordmodepixel
        coordmode, tooltip, % active_coordmodetooltip
        coordmode, mouse, % active_coordmodemouse
        Autoaccept.break_loop := false
        tooltip
        Autoaccept.loop_active := false
    }

    /*
    Checks if pixel in given coordinates is green enough to qualify as part of the accept button.
    */
    IsPixelGreenEnough(pixel_x, pixel_y, index:=0)
    {
        pixelgetcolor, pixelcolour, % pixel_x + index, % pixel_y, rgb
        ; tooladdition := "`n" . pixelcolour . "`n" . pixel_x + index . ":" . pixel_y
        tooltext := "Autoaccept running...`nDeactivate: " . Autoaccept.deactivation_hotkey
        ; . tooladdition
        tooltip, % tooltext, 1, 1
        ;mousemove, % pixel_x, % pixel_y
        pixelcolour := format("{1:X}", pixelcolour + 0)
        pixel_r := format("{1:d}", "0x" . substr(pixelcolour, 1, 2))
        pixel_g := format("{1:d}", "0x" . substr(pixelcolour, 3, 2))
        pixel_b := format("{1:d}", "0x" . substr(pixelcolour, 5, 2))

        if (pixel_g > Autoaccept.GREEN_MINIMUM && pixel_g > pixel_r * Autoaccept.GREEN_MULTIPLIER_THRESHOLD && pixel_g > pixel_b * Autoaccept.GREEN_MULTIPLIER_THRESHOLD)
            return true
        return false
    }

    KillLoop()
    {
        Autoaccept.break_loop := true
    }

    AutoExit()
    {
        if !winexist(Autoaccept.CSGO_IDENTIFIER)
        {
            ; Workaround to prevent standalone utility from closing unexpectedly.
            sleep, 3000
            if !winexist(Autoaccept.CSGO_IDENTIFIER)
            {
                sleep, 200
                hwnd := winexist(Autoaccept.CSGO_IDENTIFIER)
                if !hwnd
                {
                    Autoaccept.SaveLog({"CSGO hwnd": hwnd})
                    Autoaccept.ExitUtility()
                }
            }
        }
    }

    /*
    Exit script if not imported, otherwise call a function that erases tray menus, hotkeys and memory associated with this utility
    */
    ExitUtility()
    {
        global __script_imported__
        Autoaccept.KillLoop()
        sleep, 10
        while Autoaccept.loop_active
        {
            sleep, 5
        }
        if Autoaccept.show_dialogs
            msgbox,, % Autoaccept.GUITITLE, Autoaccept utility closed.
        if !__script_imported__
            exitapp
    }

    SaveLog(pairs:=false)
    {
        local
        global Autoaccept
        logtext := ""
        if pairs
        {
            for key, value in pairs
            {
                logtext .= key . ": " . value . "`n"
            }
        }
        winget, cscount, count, Counter
        logtext .= "Number of windows with 'Counter' in title: " . cscount
        filedelete, % Autoaccept.LOG_PATH
        fileappend, % Autoaccept.LOG_PATH, logtext, utf-8
    }
}


/*
Fancy way to make the script work when ran or imported, shoutout to GeekDude on AHK forums.
*/
AutoacceptInit()
{
    static dummy := AutoacceptInit()
    Autoaccept.Initialise()
}
