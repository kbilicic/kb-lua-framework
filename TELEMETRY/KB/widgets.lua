if helper == nil then
    helper = assert(loadScript(KB_SCRIPT_HOME.."/basics.luac"))()
end


local function drawLetterA(x,y)
  lcd.drawPoint(x+1,y)
  lcd.drawPoint(x,y+1)
  lcd.drawPoint(x,y+2)
  lcd.drawPoint(x,y+3)
  lcd.drawPoint(x+2,y+1)
  lcd.drawPoint(x+2,y+2)
  lcd.drawPoint(x+2,y+3)
  lcd.drawPoint(x+1,y+2)
end

local function drawLetterV(x,y)
  lcd.drawPoint(x,y)
  lcd.drawPoint(x,y+1)
  lcd.drawPoint(x,y+2)
  lcd.drawPoint(x+1,y+3)
  lcd.drawPoint(x+2,y+2)
  lcd.drawPoint(x+2,y+1)
  lcd.drawPoint(x+2,y)
end

local function drawPercent(x,y)
  lcd.drawPoint(x,y)
  lcd.drawLine(x,y+3,x+3,y,SOLID, FORCE)
  lcd.drawPoint(x+3,y+3)
end

local function drawLetterW(x,y)
  lcd.drawPoint(x,y)
  lcd.drawPoint(x,y+1)
  lcd.drawPoint(x,y+2)
  lcd.drawPoint(x+1,y+3)
  lcd.drawPoint(x+2,y+2)
  lcd.drawPoint(x+3,y+3)
  lcd.drawPoint(x+4,y+2)
  lcd.drawPoint(x+4,y+1)
  lcd.drawPoint(x+4,y)
end


local function clearTable(t)
    if type(t)=="table" then
        for i,v in pairs(t) do
            if type(v) == "table" then
                clearTable(v)
            end
            t[i] = nil
        end
    end
    collectgarbage()
    return t
end


-- ###############################################################
-- Helper method to draw a one pixel rounded corner rectangle
-- ###############################################################
local function drawFilledRoundedRectangleScrolled(x,y, width, height, yScrollPos)
    if yScrollPos == nil then yScrollPos = 0 end
    lcd.drawPoint(x,y - yScrollPos);
    lcd.drawPoint(x,y+height-1 - yScrollPos)
    lcd.drawPoint(x+width-1,y - yScrollPos)
    lcd.drawPoint(x+width-1,y+height-1 - yScrollPos)
    lcd.drawFilledRectangle(x, y - yScrollPos, width, height)
end


--###############################################################
-- Draw flight MODE string trimmed to 4 characters (black background)
--###############################################################
local function DrawFlightMode(x, y, mode)
  lcd.drawText(x, y, string.sub(mode,1,4), SMLSIZE)
  lcd.drawFilledRectangle(x-2, y-2, 23, 10)
end

-- ###############################################################
-- Draw Battery level
-- ###############################################################
local function DrawBatteryLevel(battBarX, battBarY, barWidth, battBarMax, batteryPercent, cellCount, cellVoltage)
    lcd.drawRectangle(battBarX, battBarY, barWidth, battBarMax + 2)
    lcd.drawFilledRectangle(battBarX + 4, battBarY - 2, barWidth-8 , 2)
    
    local batterStatusValue = nil
    if barWidth < 12 then
        batterStatusValue = nil
    elseif cellVoltage == nil then
        batterStatusValue = helper.round(batteryPercent) .. "%"
    else
        batterStatusValue = helper.round(cellVoltage, 2)
    end
  
    local battBarHeight = helper.round(battBarMax * batteryPercent / 100);
    if batteryPercent > 99.9 then
      lcd.drawText(battBarX + 2, battBarMax + battBarY + 2 - battBarHeight, "FULL", SMLSIZE)
    elseif batteryPercent > 20 and batterStatusValue ~= nil then
      lcd.drawText(battBarX + 2, battBarMax + battBarY + 2 - battBarHeight, batterStatusValue, SMLSIZE)
      if cellVoltage then 
        drawLetterV(lcd.getLastRightPos(), battBarMax + battBarY + 4 - battBarHeight)
      else
        drawPercent(lcd.getLastRightPos(), battBarMax + battBarY + 4 - battBarHeight)
      end
    elseif batterStatusValue ~= nil then
      lcd.drawText(battBarX + 2, battBarY + battBarMax - 6 - battBarHeight, batterStatusValue, SMLSIZE)
      if cellVoltage then 
        drawLetterV(lcd.getLastRightPos(), battBarY + battBarMax - 4 - battBarHeight)
      else
        drawPercent(lcd.getLastRightPos(), battBarY + battBarMax - 4 - battBarHeight)
      end
    end
    
    if cellCount ~= nil and battBarHeight > 20 then
      lcd.drawText(battBarX + 5, battBarMax + battBarY - 12,  cellCount .. "S", MIDSIZE)
    end
    lcd.drawFilledRectangle(battBarX + 1, battBarMax + battBarY + 1 - battBarHeight, barWidth-2, battBarHeight)
end


-- ###############################################################
-- Display vertical RSSI with exponential curve style
------------------------------------------------------------------
-- example call DrawVerticalRssi2(100, 8, 2, 7, 17, 1.9)
-- ###############################################################
local function DrawVerticalRssi2(rssi, rssiBarX, rssiBarY, oneBarHeight, minBarWidth, maxBars, curvePower)
    local bars = math.ceil(maxBars * rssi/100)
    if(rssi ~= nil and rssi < 85 ) then
      local offset = helper.round(math.pow(bars,curvePower) / 10) -- exponential offset
      lcd.drawText(rssiBarX + 20 - offset, rssiBarY + (oneBarHeight + 1)*(maxBars+1-bars)-7, rssi .. "db", SMLSIZE) 
    end
    local rightX = -1
    for i=maxBars + 1 - bars,maxBars do
      local offset = helper.round(math.pow(maxBars-i,curvePower) / 10) -- exponential offset
      local leftX = rssiBarX + 20 - offset
      local barWidth = minBarWidth + offset
      
      if rightX < 0 then 
        -- calcuate where is the right side of the chart
        rightX = leftX + barWidth
      else
        -- fix barWidth for all other bars
        barWidth = rightX - leftX
      end
      lcd.drawFilledRectangle(leftX, rssiBarY + (oneBarHeight+1)*i, barWidth, oneBarHeight, SOLID)
    end
    bars = nil
end


--###############################################################
-- Draw a mountain shape and altitude in meters
--###############################################################
local function DrawDistanceAndHeading(x, y, heading, distance, measure)
    local homeShape2 = {
      {0,-6,3,6},
      {3,6,0,3},
      {0,3,-3,6},
      {-3,6,0,-6}
    }
    if heading == nil then heading = 0 end
    helper.drawShape2(x, y, homeShape2, math.rad(heading), 0.7)
    if distance == nil then distance = "--" end
    lcd.drawText(x+6, y-2, distance .. measure, SMLSIZE)
    clearTable(homeShape2)
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
    if alt == nil then alt = 0 end
    helper.drawShape2Scrolled(x, y + 10, 0, mountainShape, 0, 1)
    lcd.drawText(x + 11, y, alt .. measure, MIDSIZE)
    clearTable(mountainShape)
end

--###############################################################
-- Draw a mountain shape and altitude in meters - small
--###############################################################
local function DrawAltitudeSmall(x, y, alt, measure)
  local mountainShape = {
    {-4, 0, -2, -4},
    {-2, -4, -1, -3},
    {-1, -3, 2, -9},
    {2, -9, 4, -6},
    {2,-4, 6,-7},
    {6,-7, 9,0},
    {2,0, -2, -4}
  }
  if alt == nil then 
    alt = 0
  else
    alt = helper.round(alt)
  end
  helper.drawShape2Scrolled(x, y+5, 0, mountainShape, 0, 0.7)
  lcd.drawText(x+8, y, alt .. measure, SMLSIZE)
  clearTable(mountainShape)
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
    clearTable(parashoot)
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
-- Draw GPS dish and number of satellites
-- number of satellites blink until a fix has been established
-- when a 2D or 3D fix is established, satellite number stops to blink
--###############################################################
local function DrawGpsFix(x, y, yScrollPos, gpslock, satcount)
  lcd.drawFilledRectangle(x, y-yScrollPos, 4, 3)
  lcd.drawFilledRectangle(x+4, y-1-yScrollPos, 4, 6)
  lcd.drawFilledRectangle(x+8, y-yScrollPos, 4, 3)
  lcd.drawLine(x+3, y+6-yScrollPos, x+8, y+6-yScrollPos, SOLID, FORCE)
  lcd.drawLine(x+2, y+8-yScrollPos, x+9, y+8-yScrollPos, SOLID, FORCE)
  
  --helper.drawShape2(30, 12, satelliteDish, 0, 2)
  if gpslock ~= nil and satcount ~= nil and gpslock > 1 then
    lcd.drawText(x+11, y+4-yScrollPos, satcount, SMLSIZE)
  else
    lcd.drawText(x+11, y+4-yScrollPos, satcount, SMLSIZE + BLINK)
  end

end




--###############################################################
-- Draw VTX band channel and power
--###############################################################
local function DrawVtxData(x,y, yScrollPos, band, channel, power, pit) 
  local tvShape = {
    -- disk
    {0,0,24,0},
    {24,0,24,20},
    {24,20,0,20},
    {0,20,0,0},
    {12,0,4,-5},
    {12,0,20,-5}
  }

  
  if band == nil then band = "-" end
  if channel == nil then channel = "-" end
  helper.drawShape(x, y - yScrollPos, tvShape, yScrollPos)
  lcd.drawText(x+4, y + 3 - yScrollPos, band .. " : " .. channel, SMLSIZE)
  if power == nil then power = 0 end
  lcd.drawText(x+2, y + 11 - yScrollPos, power .. "m", SMLSIZE)
  clearTable(tvShape)
end


--###############################################################
-- Draw current bar with increasing maximum
--###############################################################
local function DrawValueBar(x, y, yScrollPos, width, height, currentValue, valueMax, measure)
  if currentValue == nil then return end
  local valueMaxRound = valueMax --helper.round(valueMax / 20) * 20
  lcd.drawRectangle(x, y - yScrollPos, width, height)
  local currentValueHeight = helper.round(currentValue / valueMaxRound * (height - 2))
  local maxHeight = helper.round(valueMax / valueMaxRound * (height - 2))
  local lefttextOffset = width + 2
  if width > 15 then lefttextOffset = 1 end
  -- draw max
  --lcd.drawLine(x,y - 1 + height - maxHeight, x + width + lefttextOffset - 2, y - 1 + height - maxHeight, SOLID, FORCE)
  lcd.drawText(x+lefttextOffset, y - 9 + height - maxHeight, helper.round(valueMax), SMLSIZE)
  if measure == "A" then
    drawLetterA(lcd.getLastRightPos(), y - 7 + height - maxHeight)
  elseif measure == "V" then
    drawLetterV(lcd.getLastRightPos(), y - 7 + height - maxHeight)
  elseif measure == "W" then
    drawLetterW(lcd.getLastRightPos(), y - 7 + height - maxHeight)
  else
    lcd.drawText(lcd.getLastRightPos(), y - 7 + height - maxHeight, measure, SMLSIZE)
  end
  -- draw current value number
  if maxHeight - currentValueHeight > 10 then
    lcd.drawText(x+lefttextOffset, y - 8 + height - currentValueHeight, helper.round(currentValue), SMLSIZE)
  end
  -- draw current value bar
  lcd.drawFilledRectangle(x+1, y - 1 + height - currentValueHeight, width - 2, currentValueHeight)
end


--###############################################################
-- Draw timer
--###############################################################
local function drawTimer(x, y, timer, label)
  if label ~= nil then
    lcd.drawText(x+3, y+1, label, SMLSIZE)
    lcd.drawFilledRectangle(x, y, lcd.getLastRightPos() - x + 2, 8)
    lcd.drawText(x, y+8, timer, MIDSIZE)
  else
    lcd.drawText(x, y, timer, MIDSIZE)
  end
end




local widgets = {}

local function cleanup()
	clearTable(widgets)
	collectgarbage()
end

widgets.DrawFlightMode = DrawFlightMode
widgets.DrawBatteryLevel = DrawBatteryLevel
widgets.DrawVerticalRssi2 = DrawVerticalRssi2
widgets.DrawDistanceAndHeading = DrawDistanceAndHeading
widgets.DrawAltitude = DrawAltitude
widgets.DrawAltitudeSmall = DrawAltitudeSmall
widgets.DrawFlightModeChar = DrawFlightModeChar
widgets.DrawRescueMode = DrawRescueMode
widgets.DrawGpsFix = DrawGpsFix
widgets.DrawVtxData = DrawVtxData
widgets.cleanup = cleanup
widgets.DrawValueBar = DrawValueBar
widgets.drawTimer = drawTimer



return widgets