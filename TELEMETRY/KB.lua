KB_SCRIPT_HOME = "/SCRIPTS/TELEMETRY/KB"

local helper = assert(loadScript(KB_SCRIPT_HOME.."/basics.luac"))()
local widgets = assert(loadScript(KB_SCRIPT_HOME.."/widgets.luac"))()
local vtx = nil


--###############################################################
-- TelemtryValue class
--###############################################################
--local getValue = getValue --faster 
local globalTelemetryMap = {}
TelemetryValue = { id = -1 }
function TelemetryValue.getTelemetryId(name)
  field = getFieldInfo(name)
  if getFieldInfo(name) then return field.id end
  return -1
end

function TelemetryValue:refreshValue()
  if(self.id ~= nil and self.id > 0 and not(calc)) then
    self.value = getValue(self.id)
  else
    self.value = nil
  end
end

function TelemetryValue:new(name, label, calc)
  o = {}   -- create object if user does not provide one
  o.calculated = false or calc
  setmetatable(o, self)
  self.__index = self
  o.name = name
  o.label = label
  o.id = TelemetryValue.getTelemetryId(o.name)
  o.value = nil
  o.maxValue = nil
  o.minValue = nil
  if(o.id ~= nil and o.id > 0) then
    o.value = getValue(o.id)
    if type(o.value) ~= "table" then
      if o.minValue == nil or o.value < o.minValue then o.minValue = o.value end
      if o.maxValue == nil or o.value > o.maxValue then o.maxValue = o.value end
    end 
  else
    o.value = nil
  end
  globalTelemetryMap[#globalTelemetryMap+1] = o;
  return o
end
--############################################################### 



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


local telemetry = {}
telemetry.battsum = TelemetryValue:new('VFAS', 'Battery')
telemetry.a4      = TelemetryValue:new('A4',   'Cell voltage')
telemetry.current = TelemetryValue:new('Curr', 'Current')
telemetry.rssi    = TelemetryValue:new('RSSI', 'RSSI')
telemetry.galt    = TelemetryValue:new('GAlt', 'GPS altitude')
telemetry.alt     = TelemetryValue:new('Alt',  'Altitude')
telemetry.gspd    = TelemetryValue:new('GSpd', 'GPS speed')
telemetry.gps     = TelemetryValue:new('GPS',  'GPS loc.')
telemetry.heading = TelemetryValue:new('Hdg',  'Heading')
telemetry.tmp2    = TelemetryValue:new('Tmp2', 'Tmp2')
telemetry.tmp1    = TelemetryValue:new('Tmp1', 'Tmp1')


local menu = {}
menu.currentMenu = 0 -- 0 will display selected screen, 1 will display main menu
menu.currentItem = 1 -- main menu last selected item
menu.previousItem = 1 -- main menu previous selected item

local data = {}
  data.cellCount =  0
  data.maxVoltage = 0
  data.cellVoltage =0
  data.headingOrt = 0
  data.satcount   = 0
  data.gpslock    = 0
  data.showBattType = false
  data.battTypeCalculated = false

local gps_hori_Distance=0.0
--local radioSettings = getGeneralSettings()



local function drawYScrollBar(screenHeight, yScrollPos)
  local yScrollMax = screenHeight - lcdHeight + titleBarHeight
  lcd.drawFilledRectangle(screenWidth-scrollBarWidth, titleBarHeight + helper.round((yScrollPos / yScrollMax) * (lcdHeight-scrollBarHeight-titleBarHeight)), scrollBarWidth, scrollBarHeight, SOLID)
  yScrollMax = nil
end


-- ###############################################################
-- Helper method to draw a one pixel rounded corner rectangle
-- ###############################################################
local function drawFilledRoundedRectangleScrolled(x,y, width, height, yScrollPos)
  if yScrollPos == nil then yScrollPos = 0 end
  lcd.drawPoint(x,y - yScrollPos);
  lcd.drawPoint(x,y+height-1 - yScrollPos);
  lcd.drawPoint(x+width-1,y - yScrollPos);
  lcd.drawPoint(x+width-1,y+height-1 - yScrollPos);
  lcd.drawFilledRectangle(x, y - yScrollPos, width, height)
end



local function drawShape2Scrolled(x, y, shape, rotation, scale)
  sinShape = math.sin(rotation)
  cosShape = math.cos(rotation)
  for index, point in pairs(shape) do
    lcd.drawLine(
      x + scale * math.floor(point[1] * cosShape - point[2] * sinShape + 0.5),
      y - yScrollPossition + scale * math.floor(point[1] * sinShape + point[2] * cosShape + 0.5),
      x + scale * math.floor(point[3] * cosShape - point[4] * sinShape + 0.5),
      y - yScrollPossition + scale * math.floor(point[3] * sinShape + point[4] * cosShape + 0.5),
      SOLID, FORCE
    )
  end
end


--###############################################################
-- function Get new Telemetry Values
--###############################################################
local function RefreshTelemetryValues()
  for telIndex = 1, #globalTelemetryMap do
    globalTelemetryMap[telIndex]:refreshValue()
  end
end



--###############################################################
-- calculate gps lock and satelite count
--###############################################################
local function CalculateGpsLock() 
  if telemetry.tmp2.value ~= nil and telemetry.tmp2.value > 1000 then
    data.satcount = telemetry.tmp2.value % 1000
    data.gpslock = helper.round((telemetry.tmp2.value - data.satcount) / 1000)
  elseif telemetry.tmp2.value ~= nil and telemetry.tmp2.value > 0 then
    data.satcount = telemetry.tmp2.value
  else
    data.satcount = 0
    data.gpslock = 0
  end
end


--###############################################################
-- functions calc current GPS Distance from home
--###############################################################
local function CalculateGpsData()
  if (type(telemetry.gps.value) == "table") then
    if telemetry.gps.value["lat"] ~= nil and telemetry.gps.value["lat"] ~= 0 and data.latHome==nil and telemetry.gps.value["lon"] ~= nil and telemetry.gps.value["lon"] ~= 0 and data.lonHome==nil then
        data.latHome = telemetry.gps.value["lat"]
        data.lonHome = telemetry.gps.value["lon"]
    elseif data.latHome ~= nil and data.lonHome ~= nil then
      local sin=math.sin--locale are faster
      local cos=math.cos
      local radius = 6371008  -- in meters

      local dlat = math.rad(data.latHome - telemetry.gps.value["lat"])
      local dlon = math.rad(data.lonHome - telemetry.gps.value["lon"])
      local a = (math.sin(dlat / 2) * math.sin(dlat / 2) +
          math.cos(math.rad(telemetry.gps.value["lat"])) * math.cos(math.rad(data.latHome)) *
          math.sin(dlon / 2) * math.sin(dlon / 2))
      local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
      gps_hori_Distance = helper.round(radius * c)
      sin = nil
      cos = nil
      radius = nil
      dlat = nil
      dlon = nil
      a = nil
      c = nil
      collectgarbage()
    end      
  end
end


--###############################################################
-- Calculate battery's number of cells
-----------------------------------------------------------------
-- The idea is to calculate the number of cells once telemetry data comes in
-- and do NOT calculate on every loop iteration to avoid change of battery type
-- during the flight due to voltage swings
--###############################################################
local function CalculateBatteryTypeAndStatus()
  if data.battTypeCalculated == false then
    if telemetry.battsum.value > 10 and telemetry.battsum.value <= 12.75 then
      data.cellCount = 3  -- 3S
    elseif telemetry.battsum.value > 12.75 and telemetry.battsum.value <= 17 then
      data.cellCount = 4  -- 4S
    elseif telemetry.battsum.value > 17 and telemetry.battsum.value <= 21 then
      data.cellCount = 5  -- 5S
    elseif telemetry.battsum.value > 21 and telemetry.battsum.value <= 25.8 then
      data.cellCount = 6  -- 6S
    end
    -- calculate battery type only once, not during the flight while the voltage jumps around
    if data.cellCount ~= nil and data.cellCount > 2 then
      data.battTypeCalculated = true
    end

    data.maxVoltage = data.cellCount * 4.25
    data.minVoltage = data.cellCount * 3.4
  end

  if not data.cellCount == nil then
    data.cellVoltage = helper.round(telemetry.battsum.value / data.cellCount, 2)
  end
  data.batteryPercent = helper.round(100 * (telemetry.battsum.value - data.minVoltage) / (data.maxVoltage - data.minVoltage), 2)
end



--###############################################################
-- Determine compass orientation based on heading data
--###############################################################
local function CalculateHeadingOrientation()
  if telemetry.heading.value < 0 or telemetry.heading.value > 360 then data.headingOrt="Err"  
    elseif telemetry.heading.value <  22.5  then data.headingOrt="N"     
    elseif telemetry.heading.value <  67.5  then data.headingOrt="NE" 
    elseif telemetry.heading.value <  112.5 then data.headingOrt="E"  
    elseif telemetry.heading.value <  157.5 then data.headingOrt="SE" 
    elseif telemetry.heading.value <  202.5 then data.headingOrt="S"  
    elseif telemetry.heading.value <  247.5 then data.headingOrt="SW"    
    elseif telemetry.heading.value <  292.5 then data.headingOrt="W"     
    elseif telemetry.heading.value <  337.5 then data.headingOrt="NW"    
    elseif telemetry.heading.value <= 360.0 then data.headingOrt="N"    
  end
end
    

-- ###############################################################
-- Page title bar
-- ###############################################################
local function DrawTitleBar()
  modelname = model.getInfo()
  lcd.drawFilledRectangle(0, 0, screenWidth , 9, ERASE)

  lcd.drawText(2, 1,  data.cellCount .. "S", SMLSIZE)
  lcd.drawText(lcd.getLastRightPos() + 3, 1,  helper.round(telemetry.battsum.value,1) .. "V", SMLSIZE)

  if data.cellVoltage ~= nil and data.cellVoltage > 0 then
    lcd.drawText(lcd.getLastRightPos() + 3, 1,  data.cellVoltage .. "V", SMLSIZE)
  end
  if modelname ~= nil and type(modelname) == "table" then
    lcd.drawText(screenWidth-2, 1, modelname["name"], SMLSIZE + RIGHT)
  end

  --lcd.drawText(50, 1, "Imp: " .. radioSettings['imperial'], SMLSIZE)
  -- draw title bar background
  lcd.drawFilledRectangle(0, 0, screenWidth , 9)
end


-- ###############################################################
-- Draws long text on the screen
-- ###############################################################
local function drawLongTextScrolled(text, yScrollPos)
  -- draw long text on a the screen
  local index = 3
  local row = 0
  for i = 1, #text do
    local c = string.sub(text,i,i)
    lcd.drawText(index, row*8 + 12 - yScrollPos, c, 0, SMLSIZE) 
    index = lcd.getLastRightPos()
    if index > (screenWidth - 7) then
      index = 3
      row = row + 1
    end
  end
end



--###############################################################
-- Draw a mountain shape and altitude in meters
--###############################################################
local function DrawDistanceAndHeading(x, y, value, measure)
  local homeShape2 = {
    { 0, -6, -5,  0},
    {-5,  0,  -2,  0},
    {-2,  0,  -2,  6},
    { -2,  6,  2,  6},
    { 2,  6,  2, 0},
    { 2,  0,  5, 0},
    { 5,  0,  0, -6}
  }
  helper.drawShape(x, y, homeShape2, math.rad(telemetry.heading.value))
  lcd.drawText(x+8, y-5, value .. measure, MIDSIZE)
  homeShape2 = nil
end

--###############################################################
-- Draw a mountain shape and altitude in meters
--###############################################################
local function DrawAltitude(x, y, alt, measure)
  local mountainShape = {
    {-4, 0, -2, -4},
    {-2, -4, -1, -3},
    {-1, -3, 2, -9},
    {2, -9, 4, -6},
    {2,-4, 6,-7},
    {6,-7, 9,0},
    {2,0, -2, -4}
  }
  helper.drawShape(x, y + 10, mountainShape, 0)
  lcd.drawText(x + 11, y, alt .. measure, MIDSIZE)
  mountainShape = nil
end



--###############################################################
-- Draw GPS dish and number of satellites
-- number of satellites blink until a fix has been established
-- when a 2D or 3D fix is established, satellite number stops to blink
--###############################################################
local function DrawGpsFix(gpslock, satcount)
  local satelliteDish = {
    -- disk
    {2,-8,1,-11},
    {1,-11,1,-15},
    {1,-15,2,-16},
    {2,-16,3,-17},
    {3,-17,4,-18},
    {4,-18,5,-19},
    {5,-19,6,-19},
    {6,-19,7,-18},
    {7,-18,8,-18},
    {8,-18,9,-17},
    {9,-17,10,-17},
    {10,-17,11,-16},
    {16,-11,17,-9},
    {17,-9,17,-5},
    {17,-5,16,-4},
    {16,-4,14,-3},
    {14,-3,12,-3},
    {12,-3,11,-2},
    {11,-2,6,-4},
    {6,-4,2,-8},
    {16,-4,10,-5},
    {10,-5,6,-7},
    {6,-7,4,-11},
    {4,-11,3,-16},
    {8,-2,7,-2},
    --base
    {3,-1,14,-1},
    {3,0,14,0},
    -- reciever
    {7,-14,13,-14},
    {8,-10,13,-14},
    {12,-8,13,-14},
    {13,-13,14,-13},
    {14,-13,14,-14},
    {14,-14,13,-14},
    {13,-14,13,-13},
    {13,-15,12,-15}
  }

  helper.drawShape(28, 35, satelliteDish, 0)
  if gpslock > 1 then
    lcd.drawText(43, 15, satcount, SMLSIZE)
  else
    lcd.drawText(43, 15, satcount, SMLSIZE + BLINK)
  end

  satelliteDish = nil
end


--###############################################################
-- Draw flight MODE string trimmed to 4 characters (black background)
--###############################################################
local function DrawFlightMode(x, y, mode)
  lcd.drawText(x, y, string.sub(mode,1,4), SMLSIZE)
  lcd.drawFilledRectangle(x-2, y-2, 23, 10)
end


--###############################################################
-- Draw flight MODE initial character (black background)
--###############################################################
local function DrawFlightModeChar(x, y, mode, blink, yScrollPossition)
  if blink then
    lcd.drawText(x, y, string.sub(mode,1,1), MIDSIZE + BLINK)
  else
    lcd.drawText(x, y, string.sub(mode,1,1), MIDSIZE)
  end
  drawFilledRoundedRectangleScrolled(x-3, y-2, 14, 15, yScrollPosition)
  screen = nil
end


--###############################################################
-- Draw rescue MODE / return to home (black background)
-- parashoot icon
--###############################################################
local function DrawRescueMode(x, y, yScrollPosition)
  local parashoot = {
    {6,0,12,-6},
    {12,-6,11,-9},
    {11,-9,10,-10},
    {10,-10,6,-11},
    {6,-11,2,-10},
    {2,-10,1,-9},
    {1,-9,0,-6},
    {0,-6,6,0},
    {0,-6,12,-6},
    {6,0,4,-6},
    {6,0,8,-6}
  }

  helper.drawShape(x+1, y+12, parashoot, 0)
  drawFilledRoundedRectangleScrolled(x, y, 15, 15, yScrollPosition)

  screen = nil
  parashoot = nil
end


--###############################################################
-- Draw all telemetry raw values in a table
--###############################################################
local function DrawAllTelemetryValues()
  local rowHeight = 9 
  local screen = menu.items[menu.currentItem]
  for index=1,#globalTelemetryMap do
    helper.drawLineScrolled(0, index*rowHeight + rowHeight - 1, screenWidth, index*rowHeight + rowHeight - 1, SOLID, FORCE, screen.yScrollPosition)
    helper.drawTextScrolled(5, index*rowHeight + 1, globalTelemetryMap[index].label, SMLSIZE, screen.yScrollPosition)
    if globalTelemetryMap[index].value ~= nil  and type(globalTelemetryMap[index].value) ~= "table"  then
      helper.drawTextScrolled(screenWidth - 5, index*rowHeight + 1, helper.round(globalTelemetryMap[index].value, 2), SMLSIZE + RIGHT, screen.yScrollPosition)
    elseif globalTelemetryMap[index].value ~= nil  and type(globalTelemetryMap[index].value) == "table" and globalTelemetryMap[index].value["lat"] ~= nil and globalTelemetryMap[index].value["lon"] ~= nil  then
      helper.drawTextScrolled(screenWidth - 5, index*rowHeight + 1, globalTelemetryMap[index].value["lat"] .. ", " .. globalTelemetryMap[index].value["lon"], SMLSIZE + RIGHT, screen.yScrollPosition)
    else
      helper.drawTextScrolled(screenWidth - 5, index*rowHeight + 1, "n/a", SMLSIZE + RIGHT, screen.yScrollPosition)
    end
  end
  rowHeight = nil
  screen = nil
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
  if widgets == nil then
    vtx = nil
    collectgarbage()
    widgets = assert(loadScript(KB_SCRIPT_HOME.."/widgets.luac"))()
  end
  if type(telemetry.gps.value) == "table" then
    lcd.drawText(30, 44, helper.round(telemetry.gps.value["lat"], 4) .. " N ", 0) 
    lcd.drawText(30, 54, helper.round(telemetry.gps.value["lon"], 4) .. " E ", 0) 
  end

  local screen = menu.items[menu.currentItem]

  DrawDistanceAndHeading(60,18, gps_hori_Distance, "m");
  DrawAltitude(58,26,helper.round(telemetry.galt.value), "m")
  --DrawFlightMode(97,54,"ACRO")
  DrawFlightModeChar(107, 49, "ACRO", false, screen.yScrollPosition)
  DrawRescueMode(88,47, screen.yScrollPosition)
  DrawGpsFix(data.gpslock, data.satcount)
  DrawTitleBar()
  widgets.DrawBatteryLevel(1,13,23,47, data.batteryPercent, data.cellCount)
  widgets.DrawVerticalRssi2(telemetry.rssi.value, screenWidth-28, 8, 2, 7, 17, 1.9)
end

-- ###############################################################
-- Draw screen 2
-- ###############################################################  
function screen2(event)
  if vtx == nil then
    widgets = nil
    collectgarbage()
    vtx =  assert(loadScript("/SCRIPTS/TELEMETRY/vtx.luac"))()
  end
  vtx.run(event)

  --widgets.DrawFlightMode(60,44,"ACRO")

  DrawTitleBar()
end

-- ###############################################################
-- Draw screen 3
-- ###############################################################  
function screen3(event)
  if widgets == nil then
    vtx = nil
    collectgarbage()
    --helper = assert(loadScript(KB_SCRIPT_HOME.."/basics.luac"))()
    widgets = assert(loadScript(KB_SCRIPT_HOME.."/widgets.luac"))()
  end

  local screen = menu.items[menu.currentItem]
  -- send screen3 height
  DrawAllTelemetryValues()

  drawYScrollBar(screen.height, screen.yScrollPosition)
  DrawTitleBar()
end


function screen4(event)
  if widgets == nil then
    vtx = nil
    collectgarbage()
    widgets = assert(loadScript(KB_SCRIPT_HOME.."/widgets.luac"))()
  end

  local screen = menu.items[menu.currentItem]
  
  local text = "Reset all data to home location values? (altitude, distance from home, GPS home location)"
  drawLongTextScrolled(text, screen.yScrollPosition)
  drawYScrollBar(screen.height, screen.yScrollPosition)
  DrawTitleBar()
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


local function refreshTelemetryAndRecalculate()
  if vtx ~= nil then
    if vtx.lastMenuEvent == nil then
      vtx.lastMenuEvent = 0
      vtx.MENU_TIMESLICE = 100
    end
    --background work for betaflight VTX
    if menu.currentItem == 2 and menu.currentMenu == 0 and vtx.lastMenuEvent + vtx.MENU_TIMESLICE < vtx.getTime() then
      vtx.background()
    end
  else
    -- get new values
    RefreshTelemetryValues()
    -- calculations
    CalculateGpsLock()
    CalculateGpsData()
    CalculateBatteryTypeAndStatus()
    CalculateHeadingOrientation()
    collectgarbage()
  end
end


local function init()

end

--------------------------------------------------------------------------------
-- BACKGROUND loop FUNCTION
--------------------------------------------------------------------------------
local function backgroundwork()
  refreshTelemetryAndRecalculate()
end


--------------------------------------------------------------------------------
-- RUN loop FUNCTION
--------------------------------------------------------------------------------
local function run(event)
  
  local filteredEvent = HandleEvents(event, menu)
  
  refreshTelemetryAndRecalculate()

  MainDraw(filteredEvent)

  collectgarbage()

end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {init=init, run=run, background=backgroundwork}