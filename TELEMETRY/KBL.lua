KB_SCRIPT_HOME = "/SCRIPTS/TELEMETRY/KB"

-- DEFER ALL MODULE LOADING to reduce startup memory
local helper = nil
local widgets = nil
local telemetry_data = nil
local vtx = nil
local crsf = nil
local settings = nil

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
local function DrawTitleBar(receiver, txPower, vtxBand, vtxChan, vtxPower, otherData)
  modelname = model.getInfo()

  lcd.drawFilledRectangle(0, 0, screenWidth , titleBarHeight, ERASE)
  
  if modelname ~= nil and type(modelname) == "table" then
    lcd.drawText(2, 1, modelname["name"], SMLSIZE)
  end

  if vtxBand ~= nil then
    lcd.drawText(lcd.getLastRightPos() + 3, 1,  vtxBand .. vtxChan .. " > " .. vtxPower .. "mW", SMLSIZE)
  end

  if receiver ~= nil and txPower ~= nil then
    lcd.drawText(screenWidth-2, 1, receiver .. " " .. txPower .. "mW", SMLSIZE + RIGHT)
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
  -- SIMPLIFIED: Single column menu to save memory
  if type(items) ~= "table" then return end
  
  local itemHeight = math.floor(lcdHeight / #items)
  for i=1, #items do
    lcd.drawText(3, (i-1)*itemHeight + itemHeight / 2 - 3, items[i].name, SMLSIZE)
    if i == currentItem then
      lcd.drawFilledRectangle(0, (i-1)*itemHeight, screenWidth, itemHeight, GREY_DEFAULT)
    else
      lcd.drawRectangle(0, (i-1)*itemHeight, screenWidth, itemHeight)
    end
  end
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

  helper = loadScriptIfNeeded(helper, "/basics.luac")
  widgets = loadScriptIfNeeded(widgets, "/widgets.luac")
  telemetry_data = loadScriptIfNeeded(telemetry_data, "/telemetry.luac")

  telemetry_data.refreshTelemetryAndRecalculate()
  widgets.DrawBatteryLevel(1,13,25,47, telemetry_data.data.batteryPercent, telemetry_data.data.cellCount, telemetry_data.data.cellVoltage)
  
  -- Draw LQ (Link Quality) if available, otherwise draw RSSI
  if telemetry_data.data.lq ~= nil and telemetry_data.data.lq > 0 then
    widgets.DrawVerticalLq(telemetry_data.data.lq, screenWidth-28, 8, 2, 7, 17, 1.8)
  else
    widgets.DrawVerticalRssi3(telemetry_data.data.rssi, telemetry_data.data.rssi_text, screenWidth-28, 8, 2, 7, 17, 1.8)
  end

  widgets.DrawGpsFix(30, 12, 0, telemetry_data.data.gpslock, telemetry_data.data.satcount)
  widgets.DrawDistanceAndHeading(57,16, telemetry_data.telemetry.heading.value, telemetry_data.data.gps_hori_Distance, "m");
  widgets.DrawAltitudeSmall(lcd.getLastRightPos() + 6,14, telemetry_data.telemetry.alt.value, "m")
  widgets.DrawFlightModeChar(107, 49, telemetry_data.data.mode, telemetry_data.data.armed, 0)
  --widgets.DrawRescueMode(88,47, 0)
  --DrawFlightMode(97,54,"ACRO")
  
  -- draw coordinates
  if telemetry_data.telemetry.gps.value ~= nil and type(telemetry_data.telemetry.gps.value) == "table" then
    lcd.drawText(31, 27, "Lat " .. helper.round(telemetry_data.telemetry.gps.value["lat"], 4) .. " N ", SMLSIZE)
    lcd.drawText(31, 35, "Lon " .. helper.round(telemetry_data.telemetry.gps.value["lon"], 4) .. " E ", SMLSIZE)
    lcd.drawFilledRectangle(28,26,18,16)
  end

  widgets.drawTimer(33,48, telemetry_data.data.armedTimer, nil)

  if(telemetry_data.telemetry.mah.value ~= nil) then
    lcd.drawText(70, 27, telemetry_data.telemetry.mah.value, MIDSIZE)
    lcd.drawText(lcd.getLastRightPos(), 32, "mAh", SMLSIZE)
  end
  DrawTitleBar(telemetry_data.data.receiver, telemetry_data.telemetry.tpwr.value, nil, nil, nil)
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
  if telemetry_data ~= nil then
    telemetry_data.cleanup()
    telemetry_data = nil
  end
  collectgarbage()

  vtx = loadScriptIfNeeded(vtx, "/vtx.luac")

  if vtx ~= nil then
    local page = vtx.run(event)
  end

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

  if settings ~= nil then
    settings.drawVtxOptions(10,12,screen.yScrollPosition, event)
  end

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

  helper = loadScriptIfNeeded(helper, "/basics.luac")
  widgets = loadScriptIfNeeded(widgets, "/widgets.luac")
  telemetry_data = loadScriptIfNeeded(telemetry_data, "/telemetry.luac")

  telemetry_data.refreshTelemetryAndRecalculate()
  widgets.DrawBatteryLevel(2,13,25,47, telemetry_data.data.batteryPercent, telemetry_data.data.cellCount, telemetry_data.data.cellVoltage)
  
  -- Draw LQ (Link Quality) if available, otherwise draw RSSI
  if telemetry_data.data.lq ~= nil and telemetry_data.data.lq > 0 then
    widgets.DrawVerticalLq(telemetry_data.data.lq, screenWidth-36, 8, 2, 15, 17, 2)
  else
    widgets.DrawVerticalRssi3(telemetry_data.data.rssi, telemetry_data.data.rssi_text, screenWidth-36, 8, 2, 15, 17, 2)
  end

  widgets.DrawGpsFix(31, 12, 0, telemetry_data.data.gpslock, telemetry_data.data.satcount)
  widgets.DrawDistanceAndHeading(58,16, telemetry_data.telemetry.heading.value, telemetry_data.data.gps_hori_Distance, "m");
  widgets.DrawAltitudeSmall(lcd.getLastRightPos() + 6,14, telemetry_data.telemetry.alt.value, "m")
  widgets.DrawFlightMode(170, 53, telemetry_data.data.mode, telemetry_data.data.armed)
  --widgets.DrawRescueMode(88,47, 0)
  --DrawFlightMode(97,54,"ACRO")
  
  -- draw coordinates
  if telemetry_data.telemetry.gps.value ~= nil and type(telemetry_data.telemetry.gps.value) == "table" then
    lcd.drawText(33, 27, "Lat " .. helper.round(telemetry_data.telemetry.gps.value["lat"], 4) .. " N ", SMLSIZE)
    lcd.drawText(33, 35, "Lon " .. helper.round(telemetry_data.telemetry.gps.value["lon"], 4) .. " E ", SMLSIZE)
    lcd.drawFilledRectangle(30,26,18,16)
  end

  widgets.drawTimer(120,46, telemetry_data.data.armedTimer, nil, DBLSIZE)

  if(telemetry_data.telemetry.mah.value ~= nil) then
    lcd.drawText(31, 50, telemetry_data.telemetry.mah.value, MIDSIZE)
    lcd.drawText(lcd.getLastRightPos(), 55, "mAh", SMLSIZE)
  end
  DrawTitleBar(telemetry_data.data.cellCount, telemetry_data.telemetry.battsum.value, telemetry_data.data.cellVoltage, telemetry_data.telemetry.tpwr.value, nil, nil, nil)
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

-- local screen_vtx = {}
-- screen_vtx.name = "VTX"
-- screen_vtx.height = 64
-- screen_vtx.drawToScreen = screen_vtx_draw
-- screen_vtx.yScrollPosition = 0

-- local screen_settings = {}
-- screen_settings.name = "Settings"
-- screen_settings.height = 240
-- screen_settings.drawToScreen = screen_settings_draw
-- screen_settings.yScrollPosition = 0

local screen_tel_x9d = {}
screen_tel_x9d.name = "TELEMETRY"
screen_tel_x9d.height = 64
screen_tel_x9d.drawToScreen = screen_x9_draw
screen_tel_x9d.yScrollPosition = 0

-- local screen_crsf = {}
-- screen_crsf.name = "CROSSFIRE"
-- screen_crsf.height = 64
-- screen_crsf.drawToScreen = crsf_screen_draw
-- screen_crsf.yScrollPosition = 0


menu.items = { screen_tel_x7 } -- MINIMAL: Only telemetry screen to save memory

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