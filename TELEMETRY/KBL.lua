KB_SCRIPT_HOME = "/SCRIPTS/TELEMETRY/KB"

local helper = assert(loadScript(KB_SCRIPT_HOME.."/basics.luac"))()
local widgets = nil-- = assert(loadScript(KB_SCRIPT_HOME.."/widgets.luac"))()
local frsky = nil-- = assert(loadScript(KB_SCRIPT_HOME.."/telemetry.luac"))()
local vtx = nil
local crsf = nil

local function loadScriptIfNeeded(var, location)
  if var == nil then
    var = assert(loadScript(KB_SCRIPT_HOME..location))()
    return var
  else
    return var
  end
end

local function loadCrossfireIfNeeded(var)
  if var == nil then
    var = assert(loadScript('/CROSSFIRE/crossfire.luac'))()
    return var
  else
    return var
  end
end

local lcdHeight = LCD_H
local screenWidth = LCD_W
local scrollBarHeight = 20
local yScrollSpeed = 15
local scrollBarWidth = 2
local titleBarHeight = 8
local yScrollPossition = 0
--local settings = {
  --{ 
    --modelName = 'default',
    --vtxPowerOptions = { 25, 200, 400, 600, 800 }
  --}
--}

--local function getCurrentModelSettings(modelName) 
  --for
--end 


local menu = {}
menu.currentMenu = 0 -- 0 will display selected screen, 1 will display main menu
menu.currentItem = 1 -- main menu last selected item
menu.previousItem = 1 -- main menu previous selected item


-- ###############################################################
-- Page title bar
-- ###############################################################
local function DrawTitleBar(cellCount, battsum, cellVoltage, vtxBand, vtxChan, vtxPower, otherData)
  modelname = model.getInfo()

  lcd.drawFilledRectangle(0, 0, screenWidth , titleBarHeight, ERASE)
  
  if cellCount ~= nil then
    lcd.drawText(2, 1,  cellCount .. "S", SMLSIZE)
  end
  if battsum ~= nil then
    lcd.drawText(lcd.getLastRightPos() + 3, 1,  helper.round(battsum,1) .. "V", SMLSIZE)
  end
  if vtxBand ~= nil then
    lcd.drawText(lcd.getLastRightPos() + 3, 1,  vtxBand .. vtxChan .. " > " .. vtxPower .. "mW", SMLSIZE)
  end

  if modelname ~= nil and type(modelname) == "table" then
    lcd.drawText(screenWidth-2, 1, modelname["name"], SMLSIZE + RIGHT)
  end

  if otherData ~= nil then
    lcd.drawText(lcd.getLastRightPos()-2, 1, otherData, SMLSIZE + RIGHT)
  end

  --lcd.drawText(50, 1, "Imp: " .. radioSettings['imperial'], SMLSIZE)
  -- draw title bar background
  lcd.drawFilledRectangle(0, 0, screenWidth , titleBarHeight)
end


-- ###############################################################
-- Page title bar
-- ###############################################################
local function DrawTitleBar2(textLeft)
  modelname = model.getInfo()

  lcd.drawFilledRectangle(0, 0, LCD_W , 9, ERASE)
  
  if textLeft ~= nil then
    lcd.drawText(2, 1,  textLeft, SMLSIZE)
  end
 
  if modelname ~= nil and type(modelname) == "table" then
    lcd.drawText(LCD_W-2, 1, modelname["name"], SMLSIZE + RIGHT)
  end

  lcd.drawFilledRectangle(0, 0, LCD_W , 9)
end


-- ###############################################################
-- Page scrolbar
-- ###############################################################
local function drawYScrollBar(screenHeight, yScrollPos)
  local yScrollMax = screenHeight - lcdHeight + titleBarHeight
  lcd.drawFilledRectangle(screenWidth-scrollBarWidth, titleBarHeight + helper.round((yScrollPos / yScrollMax) * (lcdHeight-scrollBarHeight-titleBarHeight)), scrollBarWidth, scrollBarHeight, SOLID)
  yScrollMax = nil
end


--###############################################################
-- Draws main menu (on menu button press)
-- Menu content is defined by the items array and currentItem 
-- which represents selected item index
--###############################################################
local function DrawMainMenu(items, currentItem)
  local optionCount = 1
  if type(items) == "table" then
    optionCount = #items
  else
    return 
  end

  local rowCount = math.ceil(optionCount / 3)
  local itemWidth = math.ceil(screenWidth / math.ceil(optionCount / rowCount))
  local itemHeight = math.floor(lcdHeight / rowCount)
  local index = 1
  for i=1,rowCount do
    for j=1,math.ceil(optionCount/rowCount) do
      if index <= optionCount then
        lcd.drawText((j-1)*itemWidth + 3, (i-1)*itemHeight + itemHeight / 2 - 3, items[index].name, SMLSIZE)
        if index == currentItem then
          lcd.drawFilledRectangle((j-1)*itemWidth,(i-1)*itemHeight,itemWidth,itemHeight, GREY_DEFAULT)
        else
          lcd.drawRectangle((j-1)*itemWidth,(i-1)*itemHeight,itemWidth,itemHeight)
        end
      end
      index = index + 1
    end
  end

  rowCount = nil
  itemWidth = nil
  itemHeight = nil
  index = nil
end



-- ###############################################################
-- screenX() functions must be global (not local)
-- create a screenX() method for every entry in the menu
-- ###############################################################  

-- ###############################################################
-- Draw screen 1
-- ###############################################################  
function screen_x7_draw(event)
  local screen = menu.items[menu.currentItem]

  if vtx ~= nil then
    vtx.cleanup()
    vtx = nil
  end
  collectgarbage()

  widgets = loadScriptIfNeeded(widgets, "/widgets.luac")
  frsky = loadScriptIfNeeded(frsky, "/telemetry.luac")

  frsky.refreshTelemetryAndRecalculate()
  widgets.DrawBatteryLevel(1,13,25,47, frsky.data.batteryPercent, frsky.data.cellCount, frsky.data.cellVoltage)
  widgets.DrawVerticalRssi2(frsky.telemetry.rssi.value, screenWidth-28, 8, 2, 7, 17, 1.8)
  
  widgets.DrawGpsFix(30, 12, 0, frsky.data.gpslock, frsky.data.satcount)
  widgets.DrawDistanceAndHeading(57,16, frsky.telemetry.heading.value, frsky.data.gps_hori_Distance, "m");
  widgets.DrawAltitudeSmall(lcd.getLastRightPos() + 6,14, frsky.telemetry.alt.value, "m")
  widgets.DrawFlightModeChar(107, 49, frsky.data.mode, frsky.data.armed, 0)
  --widgets.DrawRescueMode(88,47, 0)
  --DrawFlightMode(97,54,"ACRO")
  
  -- draw coordinates
  if frsky.telemetry.gps.value ~= nil and type(frsky.telemetry.gps.value) == "table" then
    lcd.drawText(31, 47, "Lat " .. helper.round(frsky.telemetry.gps.value["lat"], 4) .. " N ", SMLSIZE)
    lcd.drawText(31, 55, "Lon " .. helper.round(frsky.telemetry.gps.value["lon"], 4) .. " E ", SMLSIZE)
    lcd.drawFilledRectangle(28,46,18,16)
  end

  widgets.drawTimer(33,27, frsky.data.armedTimer, nil)
  
  if(frsky.telemetry.mah.value ~= nil) then
    lcd.drawText(70, 27, frsky.telemetry.mah.value, MIDSIZE)
    lcd.drawText(lcd.getLastRightPos(), 32, "mAh", SMLSIZE)
  end
  DrawTitleBar(frsky.data.cellCount, frsky.telemetry.battsum.value, frsky.data.cellVoltage, nil, nil, nil)
end



-- ###############################################################
-- Draw screen 2
-- ###############################################################  
function screen_vtx_draw(event)
  local screen = menu.items[menu.currentItem]

  if widgets ~= nil then
    widgets.cleanup()
    widgets = nil
  end
  if frsky ~= nil then
    frsky.cleanup()
    frsky = nil
  end
  collectgarbage()

  vtx = loadScriptIfNeeded(vtx, "/vtx.luac")

  local page = vtx.run(event)

  DrawTitleBar2("VTX settings")
end


-- ###############################################################
-- Draw screen 2
-- ###############################################################  
function screen_settings_draw(event)
  local screen = menu.items[menu.currentItem]
  if widgets ~= nil then
    widgets.cleanup()
    widgets = nil
  end
  if frsky ~= nil then
    frsky.cleanup()
    frsky = nil
  end
  if vtx ~= nil then
    vtx.cleanup()
    vtx = nil
  end
  collectgarbage()
  settings = loadScriptIfNeeded(settings, "/settings.luac")

  settings.drawVtxOptions(10,12,screen.yScrollPosition, event)

  DrawTitleBar2("VTX power levels")
end

function crsf_screen_draw()

  local screen = menu.items[menu.currentItem]

  if widgets ~= nil then
    widgets.cleanup()
    widgets = nil
  end
  if frsky ~= nil then
    frsky.cleanup()
    frsky = nil
  end
  collectgarbage()

  crsf = loadCrossfireIfNeeded(crsf)
  if event == nil then
    event = EVT_DOWN_BREAK
  end

  local page = crsf.run(event)

  DrawTitleBar2("CROSSFIRE settings")
end


function screen_x9_draw()
  local screen = menu.items[menu.currentItem]

  if vtx ~= nil then
    vtx.cleanup()
    vtx = nil
  end
  collectgarbage()

  widgets = loadScriptIfNeeded(widgets, "/widgets.luac")
  frsky = loadScriptIfNeeded(frsky, "/telemetry.luac")

  frsky.refreshTelemetryAndRecalculate()
  widgets.DrawBatteryLevel(2,13,25,47, frsky.data.batteryPercent, frsky.data.cellCount, frsky.data.cellVoltage)
  widgets.DrawVerticalRssi2(frsky.telemetry.rssi.value, screenWidth-36, 8, 2, 15, 17, 2)
  
  widgets.DrawGpsFix(31, 12, 0, frsky.data.gpslock, frsky.data.satcount)
  widgets.DrawDistanceAndHeading(58,16, frsky.telemetry.heading.value, frsky.data.gps_hori_Distance, "m");
  widgets.DrawAltitudeSmall(lcd.getLastRightPos() + 6,14, frsky.telemetry.alt.value, "m")
  widgets.DrawFlightMode(170, 53, frsky.data.mode, frsky.data.armed)
  --widgets.DrawRescueMode(88,47, 0)
  --DrawFlightMode(97,54,"ACRO")
  
  -- draw coordinates
  if frsky.telemetry.gps.value ~= nil and type(frsky.telemetry.gps.value) == "table" then
    lcd.drawText(33, 27, "Lat " .. helper.round(frsky.telemetry.gps.value["lat"], 4) .. " N ", SMLSIZE)
    lcd.drawText(33, 35, "Lon " .. helper.round(frsky.telemetry.gps.value["lon"], 4) .. " E ", SMLSIZE)
    lcd.drawFilledRectangle(30,26,18,16)
  end

  widgets.drawTimer(120,46, frsky.data.armedTimer, nil, DBLSIZE)
  
  if(frsky.telemetry.mah.value ~= nil) then
    lcd.drawText(31, 50, frsky.telemetry.mah.value, MIDSIZE)
    lcd.drawText(lcd.getLastRightPos(), 55, "mAh", SMLSIZE)
  end
  DrawTitleBar(frsky.data.cellCount, frsky.telemetry.battsum.value, frsky.data.cellVoltage, nil, nil, nil)
end



-- to add new screen create a method and add new option to menu, equivalent to screen_flight_draw, screen_vtx_draw and screen3
-- EXAMPLE (screen no.5):
--
-- function screen5() 
--   "your code here"
-- end
-- local item5 = {}
-- item5.name = "My info"
-- item5.method = screen5


-- menu setup has to be AFTER screenX() drawing methods
local screen_tel_x7 = {}
screen_tel_x7.name = "TELEMETRY"
screen_tel_x7.height = 64
screen_tel_x7.drawToScreen = screen_x7_draw
screen_tel_x7.yScrollPosition = 0

local screen_vtx = {}
screen_vtx.name = "VTX"
screen_vtx.height = 64
screen_vtx.drawToScreen = screen_vtx_draw
screen_vtx.yScrollPosition = 0

local screen_settings = {}
screen_settings.name = "Settings"
screen_settings.height = 240
screen_settings.drawToScreen = screen_settings_draw
screen_settings.yScrollPosition = 0

local screen_tel_x9d = {}
screen_tel_x9d.name = "TELEMETRY"
screen_tel_x9d.height = 64
screen_tel_x9d.drawToScreen = screen_x9_draw
screen_tel_x9d.yScrollPosition = 0

local screen_crsf = {}
screen_crsf.name = "CROSSFIRE"
screen_crsf.height = 64
screen_crsf.drawToScreen = crsf_screen_draw
screen_crsf.yScrollPosition = 0


menu.items = { screen_tel_x9d, screen_crsf } -- item5 for screen no.4 should be added after item4

-- ###############################################################
-- Main draw method                      
-- ###############################################################  
function MainDraw(event)
  lcd.clear()
  if menu.currentMenu == 0 then
    -- draw selected screen
    menu.items[menu.currentItem].drawToScreen(event)
  elseif menu.currentMenu == 1 then 
    -- draw menu
    DrawMainMenu(menu.items, menu.currentItem)
  end
end

-- ###############################################################
-- Handles events and updates current menu state             
-- ###############################################################  
local longMenuPress = false
local function HandleEvents(event, menu)
  if event == EVT_MENU_LONG then 
    longMenuPress = true
    -------------------------------------------------
  elseif event == EVT_MENU_BREAK and longMenuPress == true then
    longMenuPress = false
  elseif event == EVT_MENU_BREAK and longMenuPress == false then --if menu key pressed long
    -- process menu key up only for short press
    if menu.currentMenu == 0 then 
      menu.currentMenu = 1
    else
      menu.currentMenu = 0
      menu.currentItem = menu.previousItem
    end
    longMenuPress = false
  elseif menu.currentMenu == 1 and (event == EVT_ROT_RIGHT or event == EVT_PLUS_FIRST) then
    menu.currentItem = menu.currentItem + 1
    if menu.currentItem == #menu.items + 1 then
      menu.currentItem = 1
    end
    longMenuPress = false
  elseif menu.currentMenu == 1 and (event == EVT_ROT_LEFT or event == EVT_MINUS_FIRST) then
    menu.currentItem = menu.currentItem - 1
    if menu.currentItem == 0 then
      menu.currentItem = #menu.items
    end
    longMenuPress = false
  elseif menu.currentMenu == 1 and event == EVT_ENTER_BREAK then
    menu.previousItem = menu.currentItem
    menu.currentMenu = 0
    longMenuPress = false
    return nil
  elseif menu.currentMenu == 1 and event == EVT_EXIT_BREAK then
    menu.currentItem = menu.previousItem
    menu.currentMenu = 0
    longMenuPress = false
  elseif menu.currentMenu == 0 and menu.currentItem == #menu.items and event == EVT_EXIT_BREAK then
    menu.currentItem = menu.previousItem
    menu.currentMenu = 0
    longMenuPress = false
  elseif menu.currentMenu == 0 and (event == EVT_ROT_RIGHT or event == EVT_PLUS_FIRST) then
    -- scroll current screen UP
    local screen = menu.items[menu.currentItem]
    screen.yScrollPosition = screen.yScrollPosition + yScrollSpeed
    yScrollMax = screen.height - lcdHeight + titleBarHeight
    if screen.yScrollPosition > yScrollMax then
      screen.yScrollPosition = yScrollMax
    end
    longMenuPress = false
  elseif menu.currentMenu == 0 and (event == EVT_ROT_LEFT or event == EVT_MINUS_FIRST) then
    -- scroll current screen DOWN
    local screen = menu.items[menu.currentItem]
    screen.yScrollPosition = screen.yScrollPosition - yScrollSpeed
    if screen.yScrollPosition < 0 then
      screen.yScrollPosition = 0
    end
    longMenuPress = false
  end

  return event
end




--------------------------------------------------------------------------------
-- BACKGROUND loop FUNCTION
--------------------------------------------------------------------------------
local function backgroundwork()
  collectgarbage()
end


--------------------------------------------------------------------------------
-- RUN loop FUNCTION
--------------------------------------------------------------------------------
local function run(event)
  
  local filteredEvent = HandleEvents(event, menu)

  MainDraw(filteredEvent)

  collectgarbage()

end

--------------------------------------------------------------------------------
-- run once on script load
--------------------------------------------------------------------------------
local function init()
  
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {init=init, run=run, background=backgroundwork}