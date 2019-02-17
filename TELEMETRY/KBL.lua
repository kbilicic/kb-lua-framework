KB_SCRIPT_HOME = "/SCRIPTS/TELEMETRY/KB"

local helper = assert(loadScript(KB_SCRIPT_HOME.."/basics.luac"))()
local widgets = assert(loadScript(KB_SCRIPT_HOME.."/widgets.luac"))()
local frsky = assert(loadScript(KB_SCRIPT_HOME.."/telemetry.luac"))()
local vtx = nil

local function loadScriptIfNeeded(var, location)
  if var == nil then
    var = assert(loadScript(KB_SCRIPT_HOME..location))()
    return var
  else
    return var
  end
end

local lcdHeight = LCD_H
local screenWidth = LCD_W
local scrollBarHeight = 20
local yScrollSpeed = 5
local scrollBarWidth = 2
local titleBarHeight = 10
local yScrollPossition = 0
local vtxPowerOptionsList = {
  { 25 },
  { 25, 200 },
  { 25, 100, 200 },
  { 25, 200, 500 },
  { 25, 100, 200, 500 },
  { 25, 200, 400, 800 },
  { 25, 200, 400, 600, 800 },
  { 25, 200, 400, 800 },
  { 25, 200, 500, 800 }
}
local settings = {
  { 
    modelName = 'default',
    vtxPowerOptions = { 25, 200, 400, 600, 800 }
  }
}

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
local function DrawTitleBar(cellCount, battsum, cellVoltage)
  modelname = model.getInfo()
  lcd.drawFilledRectangle(0, 0, screenWidth , 9, ERASE)

  lcd.drawText(2, 1,  cellCount .. "S", SMLSIZE)
  lcd.drawText(lcd.getLastRightPos() + 3, 1,  helper.round(battsum,1) .. "V", SMLSIZE)

  if cellVoltage ~= nil and cellVoltage > 0 then
    lcd.drawText(lcd.getLastRightPos() + 3, 1,  cellVoltage .. "V", SMLSIZE)
  end
  if modelname ~= nil and type(modelname) == "table" then
    lcd.drawText(screenWidth-2, 1, modelname["name"], SMLSIZE + RIGHT)
  end

  --lcd.drawText(50, 1, "Imp: " .. radioSettings['imperial'], SMLSIZE)
  -- draw title bar background
  lcd.drawFilledRectangle(0, 0, screenWidth , 9)
end


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
function screen1(event)
  local screen = menu.items[menu.currentItem]

  if vtx ~= nil then
    vtx.cleanup()
    vtx = nil
  end
  collectgarbage()

  widgets = loadScriptIfNeeded(widgets, "/widgets.luac")
  frsky = loadScriptIfNeeded(frsky, "/telemetry.luac")

  frsky.refreshTelemetryAndRecalculate()

  widgets.DrawVerticalRssi2(frsky.telemetry.rssi.value, screenWidth-28, 8, 2, 7, 17, 1.9)
  widgets.DrawDistanceAndHeading(60,18, frsky.telemetry.heading.value, frsky.data.gps_hori_Distance, "m");
  widgets.DrawAltitude(58,26,helper.round(frsky.telemetry.galt.value), "m")
  --DrawFlightMode(97,54,"ACRO")
  widgets.DrawFlightModeChar(107, 49, "ACRO", false, 0)
  widgets.DrawRescueMode(88,47, 0)
  widgets.DrawGpsFix(frsky.data.gpslock, frsky.data.satcount)
  widgets.DrawBatteryLevel(1,13,25,47, frsky.data.batteryPercent, frsky.data.cellCount, frsky.data.cellVoltage)
  widgets.DrawVerticalRssi2(frsky.telemetry.rssi.value, screenWidth-28, 8, 2, 7, 17, 1.9)

  -- draw coordinates
  if frsky.telemetry.gps.value ~= nil and type(frsky.telemetry.gps.value) == "table" then
    lcd.drawText(30, 44, helper.round(frsky.telemetry.gps.value["lat"], 4) .. " N ", 0)
    lcd.drawText(30, 54, helper.round(frsky.telemetry.gps.value["lon"], 4) .. " E ", 0)
  end

  DrawTitleBar(frsky.data.cellCount, frsky.telemetry.battsum.value, frsky.data.cellVoltage)
end

-- ###############################################################
-- Draw screen 2
-- ###############################################################  
function screen2(event)
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

  vtx.run(event)

  --widgets.DrawFlightMode(60,44,"ACRO")

  DrawTitleBar(frsky.data.cellCount, frsky.telemetry.battsum.value, frsky.data.cellVoltage)
end

-- ###############################################################
-- Draw screen 3
-- ###############################################################  
function screen3(event)
  local screen = menu.items[menu.currentItem]

  drawYScrollBar(screen.height, screen.yScrollPosition)
  DrawTitleBar(frsky.data.cellCount, frsky.telemetry.battsum.value, frsky.data.cellVoltage)
end


function screen4(event)
  local screen = menu.items[menu.currentItem]

  drawYScrollBar(screen.height, screen.yScrollPosition)
  DrawTitleBar(frsky.data.cellCount, frsky.telemetry.battsum.value, frsky.data.cellVoltage)
end

-- to add new screen create a method and add new option to menu, equivalent to screen1, screen2 and screen3
-- EXAMPLE (screen no.5):
--
-- function screen5() 
--   "your code here"
-- end
-- local item5 = {}
-- item5.name = "My info"
-- item5.method = screen5


-- menu setup has to be AFTER screenX() drawing methods
local item1 = {}
item1.name = "GPS"
item1.height = 64
item1.drawToScreen = screen1
item1.yScrollPosition = 0

local item2 = {}
item2.name = "VTX"
item2.height = 64
item2.drawToScreen = screen2
item2.yScrollPosition = 0

local item3 = {}
item3.name = "Stats"
item3.height = 128
item3.drawToScreen = screen3
item3.yScrollPosition = 0

local item4 = {}
item4.name = "OPTIONS"
item4.height = 128
item4.drawToScreen = screen4
item4.yScrollPosition = 0

menu.items = { item1, item2, item3, item4 } -- item5 for screen no.4 should be added after item4

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
    if menu.currentItem ~= 4 then
      menu.previousItem = menu.currentItem
    end
    menu.currentMenu = 0
    longMenuPress = false
    return nil
  elseif menu.currentMenu == 1 and event == EVT_EXIT_BREAK then
    menu.currentItem = menu.previousItem
    menu.currentMenu = 0
    longMenuPress = false
  elseif menu.currentMenu == 0 and menu.currentItem == 4 and event == EVT_ENTER_BREAK then
    -- reset values to home position
    menu.currentItem = menu.previousItem 
    menu.currentMenu = 0
    longMenuPress = false
  elseif menu.currentMenu == 0 and menu.currentItem == 4 and event == EVT_EXIT_BREAK then
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