# Autoaccept
Counter-Strike: Global Offensive automatic accept button presser

## Usage
Download the file(s) anywhere and run the program.

Can be ran as an AutoHotkey script. This allows the user to modify the program however they want and change the tray icon etc.
The exe can be used as-is, no other downloaded files needed. The executable is 64bit.

Pressing the activation hotkey starts a loop that clicks the Accept-button as soon as it notices one. Deactivation stops the loop and exit hotkey closes the program completely. You can make a cup of coffee and take a pee without worrying about your computer while queuing. Convenient.

## VAC
This will not trigger VAC unlike a memory reading solution possibly would. This program finds the accept button based on the colour of pixels on your screen, and unless Valve for some reason specifically targets such behaviour, is safe to use. However, I should and will not be held responsible in the event of having VAC trigger while using this utility or stumbling upon any other inconvenience.

## Settings
The script can launch CS:GO upon opening it and close itself after CS:GO is closed if configured to do so. To achieve this, right-click the tray icon and tick the items you want. You can also change the hotkeys used in the program. For more help with AutoHotkey hotkeys syntax visit https://autohotkey.com/docs/Hotkeys.htm

## Geekier stuff
If the script is to be imported, it should be noted that #include line can and should be located at the very top of the auto execute section. Also #singleinstance is set to force by this utility so it may be set to ignore/off after the #include line.
Example:
```
#include <Autoaccept>
#singleinstance ignore

^m::
Autoaccept.Execute()
return
```
