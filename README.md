# kb-lua-framework

This is a OpenTX LUA framework that enables everyone to create their own lua screens and menus to switch between the screens.
It's even possible to load ANY script to a desired screen, this is demonstrated by loading a betaflight VTX settings page as a separate screen.


![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/demo%2019.2.2019.gif)

COPY TO TARANIS
1. Download all files
2. Unzip and copy to your taranis SD card Location: /SCRIPTS/TELEMETRY/
3. Open your model settings on your Taranis and select KBL as a script on one of your screens

Main file in this script is KBL.lua. That file contact entire UI and all the screens which you can modify to your needs.
Currently we have 4 screens which you can select by short-pressing menu button and using plus/minus or rotary button and then activate by pressing enter.


You can edit screen title, vertical scroll size and rendering method:

![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/screen_config_example.JPG)


