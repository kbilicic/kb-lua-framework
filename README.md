# kb-lua-framework

This is a my OpenTX LUA framework that enables everyone to create their own lua screens. Menu to switch between the screens is automatically updated. It's even possible to load ANY script to a desired screen. I'll post instructions on how to do this yourself later, but if you are not a coder, I probably can't teach you how to do it, sorry :(

X7 and X9 version - download [HERE!](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/DOWNLOADS/KBL.rar)
![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/x9d.gif)


# HOW TO USE IT

1. Download all files
2. Unzip and copy to your taranis (SD card Location: /SCRIPTS/TELEMETRY/) all files from TELEMETRY folder
3. Open your model settings on your Taranis and select KBL as a script on one of your screens

# Video instructions on how to set it up on X7, same goes for X9

![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/x7_setup.gif)

Watch on youtube here: https://www.youtube.com/embed/2RAJuoX65tA


# HOW IT WORKS.... AND HOW TO MODIFY IT

Main file in this script is KBL.lua. That file contact entire UI and all the screens which you can modify to your needs.
Currently we have 4 screens which you can select by short-pressing menu button and using plus/minus or rotary button and then activate by pressing enter.


You can edit screen title, vertical scroll size and rendering method:

![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/screen_config_example.JPG)

item1 is a screen object where we can change name, height and render method used for drawing this screen content. yScrollPosition stores scroll position, set this to 0.

* **name** - set the name to your liking, keep in mind that if you assign some large name, it might bleed into another screen

* **height** - this is the screen height, set this to your screen height, X7 and X9 have screen height of 64 pixels...
         You can set this to be LARGER than your screen size, if you do that, you will be able to scroll the screen content using your X7          know, or + and - buttons on X9
         
* **drawToScreen** - this is a method name used for drawing this screen
               keep in mind that this method has to exist AND it has to located BEFORE this line
               

![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/screen1_code.JPG)

Here you can see how screen1 (GPS in menu) is rendered/constructed. 

Lines

`widgets = loadScriptIfNeeded(widgets, "/widgets.luac")` 

and

`frsky = loadScriptIfNeeded(frsky, "/telemetry.luac")`

are loading widgets and telemetry libraries we need for this screen.

## Using widgets

### BATTERY WIDGET

Next line shows how we can draw battery widget on the screen with all of its parameters

`widgets.DrawBatteryLevel(1,13,25,47, frsky.data.batteryPercent, frsky.data.cellCount, frsky.data.cellVoltage)`

which are in order:

* X 
* Y
* width
* height
* battery percent value - we pass that value from frsky library data structure
* battery cell count - we pass that value from frsky library data structure
* average cell voltage - we pass that value from frsky library data structure

frsky data structure holds calculated telemetry data, this is refreshed on every screen render by calling a method:

`frsky.refreshTelemetryAndRecalculate()`

it refreshed ALL telemetry data and recalculates all calculated values, such as battery percentage and average cell voltage.

You can modify location and size of the widget to place it whereever you like.


### RSSI WIDGET

Rssi widget is drawn ba calling this method:

`widgets.DrawVerticalRssi2(frsky.telemetry.rssi.value, screenWidth-28, 8, 2, 7, 17, 1.8)`

Parameters are in order:

* rssi value - we pass that value from frsky library telemetry structure
* rssiBarX - x location of top most bar when rssi has maximum value
* rssiBarY - this is desired y location where top most bar will be drawn on the screen.
* oneBarHeight - height of each bar drawn
* minBarWidth - width of minimum value bar, lowest bar on the screen
* maxBars - number of bars for maximum value
* curvePower - exponential cooficient that represents bar curvature to the left side



# FUTURE VERSIONS - not yet available
Our Taranis radios have very limited memory available to LUA scripts and out of memory can happen... there's not much you can do about it EXCEPT keep your script small. I've spent a lot of time on trying to use Betaflight VTX script on one of my screens, but, no matter how much I tried cleaning the memory, I still manage to get out of memory error (sometimes)

![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/menu1.JPG)

![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/gps_screen1.JPG)

![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/vtx_settings.JPG)

Since VTX remote control, or smartaudio, presumes you have 4 power levels: 25, 200, 500, 800 you will always see these 4 options no matter which VTX you use. Sooooooo I created a settings screen where you can choose your VTX power settings, so when you change powerlevels, you only get the actual levels that exist.
Some VTX devices have 5 power levels, this is still not supported by BF, however, I heard it might be available from version 4.2 (not 4.0.2, but 4.2) - so far, it's just a rumor

If I don't manage to incorporate VTX into one of my screens without memory creash, I'll probably release a new script that will be used just for that. We'll see...


