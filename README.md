# kb-lua-framework

This is a OpenTX LUA framework that enables everyone to create their own lua screens and menus to switch between the screens.
It's even possible to load ANY script to a desired screen, this is demonstrated by loading a betaflight VTX settings page as a separate screen.


![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/demo%2019.2.2019.gif)

COPY TO TARANIS
1. Download all files
2. Unzip and copy to your taranis SD card Location: /SCRIPTS/TELEMETRY/
3. Open your model settings on your Taranis and select KBL as a script on one of your screens


HO IT WORKS.... AND HOW TO MODIFY IT
Main file in this script is KBL.lua. That file contact entire UI and all the screens which you can modify to your needs.
Currently we have 4 screens which you can select by short-pressing menu button and using plus/minus or rotary button and then activate by pressing enter.


You can edit screen title, vertical scroll size and rendering method:

![](https://raw.githubusercontent.com/kbilicic/kb-lua-framework/master/IMAGES/screen_config_example.JPG)

item1 is a screen object where we can change name, height and render method used for drawing this screen content.

name - set the name to your liking, keep in mind that if you assign some large name, it might bleed into another screen

height - this is the screen height, set this to your screen height, X7 and X9 have screen height of 64 pixels...
         You can set this to be LARGER than your screen size, if you do that, you will be able to scroll the screen content using your X7          know, or + and - buttons on X9
         
drawToScreen - this is a method name used for drawing this screen
               keep in mind that this method has to exist AND it has to located BEFORE this line
               
