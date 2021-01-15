# Autoaccept
Counter-Strike: Global Offensive automatic accept button presser

## Usage
Download the latest executable from the Releases section and run the standalone app.

The utility can also be ran or imported as an AutoHotkey script. This allows the user to modify the program however they want and change the tray icon etc. Remember to also download the .ico with the script.
The exe can be used as-is, no other downloaded files needed. The executable is 64bit.

Pressing the activation hotkey starts a loop that clicks the Accept-button as soon as it notices one. Deactivation stops the loop and exit hotkey closes the program completely. You can make a cup of coffee and take a pee without worrying about your computer while queuing. Convenient.

## VAC
This utility will not trigger VAC. It finds the accept button based on the colour of pixels on your screen, and unless Valve for some bizarre reason specifically targets such behaviour, it's safe to use. However, I should and will not be held responsible in the event of having VAC trigger while using this utility or stumbling upon any other inconvenience.

## Settings
The script can launch CS:GO upon opening it and close itself after CS:GO is closed if configured to do so. To achieve this, right-click the tray icon and tick the items you want. You can also change the hotkeys used in the program. For more help with AutoHotkey hotkeys syntax visit https://autohotkey.com/docs/Hotkeys.htm

## Geekier stuff
If the script is to be imported, it should be noted that #singleinstance is set to force by this utility, so you might want set #singleinstance to ignore/off after the #include line. The script adds an entry named "Autoaccept" to the tray menu of the top-level script, from where settings can be tuned.
Example:
```
; Import from AHK global library on your machine.
#include <Autoaccept>
#singleinstance ignore

; Done! Feel free to add all your other hotkeys here.
```
