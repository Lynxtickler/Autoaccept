#singleinstance force
#noenv


CONF_PATH := a_scriptdir . "\conf.ini"
CONF_SECTION := "Basic"
ICO_PATH := a_scriptdir . "\autoaccept.ico"
CSGO_IDENTIFIER := "ahk_exe csgo.exe"
PIXELS_AMOUNT := 50
GREEN_MINIMUM := 100
PIXELS_ERROR_MARGIN := 0.03
GREEN_THRESHOLD_MULTIPLIER := 2.1
BREAK_LOOP := false
AHK_HOTKEYS_PAGE := "https://autohotkey.com/docs/Hotkeys.htm"
GITHUB_PAGE := "https://github.com/Lynxtickler/Autoaccept"
AUTOSTART_ITEM := "Start CS:GO with script"
AUTOEXIT_ITEM := "Exit script with CS:GO"
ACTIVATE_KEY_ITEM := "Choose activate hotkey"
DEACTIVATE_KEY_ITEM := "Choose deactivate hotkey"
EXIT_KEY_ITEM := "Choose exit hotkey"
HELP_SUBMENU := "HelpSubMenu"
HELP_ITEM := "Help"
HELP_DEFAULT_HOTKEY := "! Default activate hotkey is RCtrl+a !"
HELP_DOCS_ITEM := "GitHub page"
HELP_HOTKEYS_ITEM := "Help with hotkeys"
RELOAD_ITEM := "Reload this script"
CHANGE_SUBMENU := "ChangeSubMenu"
CHANGE_ITEM := "Change hotkeys"
CHANGE_ACTIVATE_ITEM := "Change activation hotkey"
CHANGE_DEACTIVATE_ITEM := "Change deactivation hotkey"
CHANGE_EXIT_ITEM := "Change exit hotkey"
EXIT_ITEM := "Exit"
AUTOEXIT_TIMER_FREQUENCY := 2000
HOTKEYBOX_W := 330
HOTKEYBOX_H := 130


gosub, CreateMenu
gosub, LoadConfig
gosub, EvaluateAllMenuItems

if auto_exit
{
    loop
    {
        if winexist(CSGO_IDENTIFIER)
            break
    }
    settimer, AutoExitLabel, %AUTOEXIT_TIMER_FREQUENCY%
}
return

; end of auto-execute section

/*
Loads the configuration file, creates one if there's none present, and loads the settings.
Also initialises hotkeys and launches CS:GO if config says so.
*/
LoadConfig:
if !fileexist(CONF_PATH)
{
    iniwrite, >^a, %CONF_PATH%, %CONF_SECTION%, activation_bind
    iniwrite, >^a, %CONF_PATH%, %CONF_SECTION%, deactivation_bind
    iniwrite, ^q, %CONF_PATH%, %CONF_SECTION%, exit_bind
    iniwrite, 0, %CONF_PATH%, %CONF_SECTION%, autostartcsgo
    iniwrite, 0, %CONF_PATH%, %CONF_SECTION%, autoexit
    
}
iniread, start_csgo, %CONF_PATH%, %CONF_SECTION%, autostartcsgo, 0
iniread, auto_exit, %CONF_PATH%, %CONF_SECTION%, autoexit, 0
iniread, activation_hotkey, %CONF_PATH%, %CONF_SECTION%, activation_bind, Error
iniread, deactivation_hotkey, %CONF_PATH%, %CONF_SECTION%, deactivation_bind, Error
iniread, exit_hotkey, %CONF_PATH%, %CONF_SECTION%, exit_bind, Error
if (activation_hotkey = "Error" || deactivation_hotkey = "Error" || exit_hotkey = "Error")
{
    msgbox, Cannot read configuration. Using default settings.
    start_csgo := 0
    auto_exit := 0
    activation_hotkey := ">^a"
    deactivation_hotkey := ">^a"
    exit_hotkey := "^q"
}
hotkey, %exit_hotkey%, ExitLabel, on
hotkey, %activation_hotkey%, AcceptLoop, on
if (activation_hotkey != deactivation_hotkey)
    hotkey, %deactivation_hotkey%, KillLoop, on t2
if (start_csgo && !winexist(CSGO_IDENTIFIER))
    run, steam://rungameid/730

return


/*
Creates tray menu and assigns the icon.
*/
CreateMenu:
menu, tray, nostandard
menu, tray, icon, %ICO_PATH%
menu, %HELP_SUBMENU%,   add, %HELP_DEFAULT_HOTKEY%, Useless
menu, %HELP_SUBMENU%,   add, %HELP_DOCS_ITEM%, OpenGitHub
menu, %HELP_SUBMENU%,   add, %HELP_HOTKEYS_ITEM%, OpenHotkeysPage
menu, tray,             add, %HELP_ITEM%, :%HELP_SUBMENU%
menu, tray,             add, %RELOAD_ITEM%, Reloader
menu, tray,             add, %AUTOSTART_ITEM%, ToggleAutoStart
menu, tray,             add, %AUTOEXIT_ITEM%, ToggleAutoExit
menu, %CHANGE_SUBMENU%, add, %CHANGE_ACTIVATE_ITEM%, ChangeHotkey
menu, %CHANGE_SUBMENU%, add, %CHANGE_DEACTIVATE_ITEM%, ChangeHotkey
menu, %CHANGE_SUBMENU%, add, %CHANGE_EXIT_ITEM%, ChangeHotkey
menu, tray,             add, %CHANGE_ITEM%, :%CHANGE_SUBMENU%
menu, tray,             add, %EXIT_ITEM%, ExitLabel
return


/*
Changes any of the program's hotkeys. On invalid user input asks again until cancelled or answered correctly.
*/
ChangeHotkey:
if (a_thismenuitem = CHANGE_ACTIVATE_ITEM)
{
    target_setting := "activation_bind"
    action_label := "AcceptLoop"
    current_hotkey := activation_hotkey
}
else if (a_thismenuitem = CHANGE_DEACTIVATE_ITEM)
{
    target_setting := "deactivation_bind"
    action_label := "KillLoop"
    current_hotkey := deactivation_hotkey
}
else if (a_thismenuitem = CHANGE_EXIT_ITEM)
{
    target_setting := "exit_bind"
    action_label := "ExitLabel"
    current_hotkey := exit_hotkey
}
else
    return
loop
{
    inputbox, user_input, Autoaccept, %a_thismenuitem%,, %HOTKEYBOX_W%, %HOTKEYBOX_H%,,,,,%current_hotkey%
    if errorlevel
        return
    try
    {
        additional_thread := (current_hotkey = activation_hotkey || current_hotkey = deactivation_hotkey) ? "t2" : ""
        hotkey, %user_input%, %action_label%, on %additional_thread%
        iniwrite, %user_input%, %CONF_PATH%, %CONF_SECTION%, %target_setting%
        break
    }
    catch
    {
        msgbox, Error assigning hotkey. Check input validity from %HELP_ITEM% -> %HELP_HOTKEYS_ITEM%.
    }
}
return


Useless:
; not meant to do anything
return


Reloader:
reload
return


OpenGitHub:
run, %GITHUB_PAGE%
return


OpenHotkeysPage:
run, %AHK_HOTKEYS_PAGE%
return


/*
Toggles CS:GO autostart and updates it to the menu and .ini file.
*/
ToggleAutoStart:
start_csgo := !start_csgo
gosub, EvaluateAutoStartMenuItem
iniwrite, %start_csgo%, %CONF_PATH%, %CONF_SECTION%, autostartcsgo
return


/*
Toggles script automatic termination on CS:GO closing, and updates it to the menu and .ini file.
*/
ToggleAutoExit:
auto_exit := !auto_exit
gosub, EvaluateAutoExitMenuItem
iniwrite, %auto_exit%, %CONF_PATH%, %CONF_SECTION%, autoexit
if auto_exit
    settimer, AutoExitLabel, %AUTOEXIT_TIMER_FREQUENCY%
else
    settimer, AutoExitLabel, off
return


EvaluateAllMenuItems:
gosub, EvaluateAutoStartMenuItem
gosub, EvaluateAutoExitMenuItem
return

/*
Checks or unchecks autostart menu item.
*/
EvaluateAutoStartMenuItem:
invert := start_csgo ? "" : "un"
menu, tray, %invert%check, %AUTOSTART_ITEM%
return


/*
Checks or unchecks autoexit menu item.
*/
EvaluateAutoExitMenuItem:
invert := auto_exit ? "" : "un"
menu, tray, %invert%check, %AUTOEXIT_ITEM%
return


/*
The main accept button checking loop. Checks a defined amount of pixels towards left and right from the middle of the screen
and if most of them are green and bright enough, clicks in the middle of the screen. The accept dialog and button are always
located here in panorama UI, regardless of resolution so consistent and robust behaviour is to be expected.
Returns immediately if CS:GO isn't active.
*/
AcceptLoop:
if (activation_hotkey = deactivation_hotkey)
    hotkey, %activation_hotkey%, KillLoop, on t2
if !winactive(CSGO_IDENTIFIER)
{
    if (activation_hotkey = deactivation_hotkey)
        hotkey, %activation_hotkey%, AcceptLoop, on t2
    BREAK_LOOP := false
    return
}
wingetpos, window_x, window_y, window_width, window_height, a
tooltext =
pixel_x := window_x + window_width / 2 - PIXELS_AMOUNT / 2
pixel_y := floor(window_height / 2)
loop
{
    subsequent_green_pixels := 0
    loop, %PIXELS_AMOUNT%
    {
        px := pixel_x + a_index
        pixelgetcolor, pixelcolour, pixel_x + a_index, pixel_y
        pixelcolour := format("{1:X}", pixelcolour + 0)
        tooltip, Autoaccept running...`nDeactivate: %deactivation_hotkey%`nexit: %exit_hotkey%, %window_x%, %window_y%
        pixel_r := format("{1:d}", "0x" . substr(pixelcolour, 1, 2))
        pixel_g := format("{1:d}", "0x" . substr(pixelcolour, 3, 2))
        pixel_b := format("{1:d}", "0x" . substr(pixelcolour, 5, 2))
        
        if (pixel_g > GREEN_MINIMUM && pixel_g > pixel_r * GREEN_THRESHOLD_MULTIPLIER && pixel_g > pixel_b * GREEN_THRESHOLD_MULTIPLIER)
        {
            subsequent_green_pixels++
        }
    }
    if (subsequent_green_pixels > PIXELS_AMOUNT - PIXELS_AMOUNT * PIXELS_ERROR_MARGIN)
    {
        clickx := window_x + window_width / 2
        clicky := pixel_y + 1
        click, %clickx%, %clicky%
    }
    if BREAK_LOOP
        break
}
if (activation_hotkey = deactivation_hotkey)
    hotkey, %activation_hotkey%, AcceptLoop, on t2
BREAK_LOOP := false
tooltip
return


KillLoop:
BREAK_LOOP := true
return


AutoExitLabel:
if !winexist(CSGO_IDENTIFIER)
    exitapp
return


ExitLabel:
exitapp
return