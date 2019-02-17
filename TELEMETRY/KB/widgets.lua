if helper == nil then
    helper = assert(loadScript(KB_SCRIPT_HOME.."/basics.luac"))()
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
    lcd.drawPoint(x,y+height-1 - yScrollPos);
    lcd.drawPoint(x+width-1,y - yScrollPos);
    lcd.drawPoint(x+width-1,y+height-1 - yScrollPos);
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
local function DrawBatteryLevel(battBarX, battBarY, barWidth, battBarMax, batteryPercent, cellCount)
    lcd.drawRectangle(battBarX, battBarY, barWidth, battBarMax + 2)
    lcd.drawFilledRectangle(battBarX + 4, battBarY - 2, barWidth-8 , 2)
  
    local battBarHeight = helper.round(battBarMax * batteryPercent / 100);
    if batteryPercent > 99.9 then
      lcd.drawText(battBarX + 2, battBarMax + battBarY + 2 - battBarHeight, "FULL", SMLSIZE)
    elseif batteryPercent > 20 and batteryPercent ~= nil then
      lcd.drawText(battBarX + 2, battBarMax + battBarY + 2 - battBarHeight, helper.round(batteryPercent).."%", SMLSIZE)
    elseif batteryPercent ~= nil then
      lcd.drawText(battBarX + 2, battBarY + battBarMax - 6 - battBarHeight, helper.round(batteryPercent).."%", SMLSIZE)
    end
    
    --if data.showBattType == true then
      --lcd.drawText(battBarX + 5, battBarMax + battBarY - 18,  cellCount .. "S", DBLSIZE)
    --end
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
      { 0, -6, -5,  0},
      {-5,  0,  -2,  0},
      {-2,  0,  -2,  6},
      { -2,  6,  2,  6},
      { 2,  6,  2, 0},
      { 2,  0,  5, 0},
      { 5,  0,  0, -6}
    }
    helper.drawShape(x, y, homeShape2, math.rad(heading))
    lcd.drawText(x+8, y-5, distance .. measure, MIDSIZE)
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
    helper.drawShape(x, y + 10, mountainShape, 0)
    lcd.drawText(x + 11, y, alt .. measure, MIDSIZE)
    clearTable(mountainShape)
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
widgets.DrawFlightModeChar = DrawFlightModeChar
widgets.cleanup = cleanup



return widgets