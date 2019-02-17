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
local function DrawBatteryLevel(battBarX, battBarY, barWidth, battBarMax, batteryPercent, cellCount, cellVoltage)
    lcd.drawRectangle(battBarX, battBarY, barWidth, battBarMax + 2)
    lcd.drawFilledRectangle(battBarX + 4, battBarY - 2, barWidth-8 , 2)
    
    local batterStatusValue = nil
    if barWidth < 12 then
        batterStatusValue = nil
    elseif cellVoltage == nil then
        batterStatusValue = helper.round(batteryPercent) .. "%"
    else
        batterStatusValue = helper.round(cellVoltage, 2) .. "V"
    end
  
    local battBarHeight = helper.round(battBarMax * batteryPercent / 100);
    if batteryPercent > 99.9 then
      lcd.drawText(battBarX + 2, battBarMax + battBarY + 2 - battBarHeight, "FULL", SMLSIZE)
    elseif batteryPercent > 20 and batterStatusValue ~= nil then
      lcd.drawText(battBarX + 2, battBarMax + battBarY + 2 - battBarHeight, batterStatusValue, SMLSIZE)
    elseif batterStatusValue ~= nil then
      lcd.drawText(battBarX + 2, battBarY + battBarMax - 6 - battBarHeight, batterStatusValue, SMLSIZE)
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

    clearTable(satelliteDish)
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
widgets.DrawRescueMode = DrawRescueMode
widgets.DrawGpsFix = DrawGpsFix
widgets.cleanup = cleanup



return widgets