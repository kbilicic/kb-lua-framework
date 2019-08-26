if helper == nil then
    helper = assert(loadScript(KB_SCRIPT_HOME.."/basics.luac"))()
end

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
    if type(self.value) ~= "table" then
      if self.minValue == nil or self.value < self.minValue then self.minValue = self.value end
      if self.maxValue == nil or self.value > self.maxValue then self.maxValue = self.value end
      --print(self.name .. ": " .. self.value .. ",   max: " .. self.maxValue)
    end
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
    globalTelemetryMap[#globalTelemetryMap+1] = o;
  else
    o.value = nil
  end
  
  return o
end
--############################################################### 

local telemetry = {}
    telemetry.battsum = TelemetryValue:new('RxBt', 'Batt voltage')
    telemetry.a4      = TelemetryValue:new('A4',   'Cell voltage')
    telemetry.current = TelemetryValue:new('Curr', 'Current')
    telemetry.mah     = TelemetryValue:new('mAh',  'mAh')
    telemetry.rssi    = TelemetryValue:new('RSSI', 'RSSI')
    telemetry.galt    = TelemetryValue:new('GAlt', 'GPS altitude')
    telemetry.alt     = TelemetryValue:new('Alt',  'Altitude')
    telemetry.gspd    = TelemetryValue:new('GSpd', 'GPS speed')
    telemetry.aspd    = TelemetryValue:new('ASpd', 'Speed')
    telemetry.gps     = TelemetryValue:new('GPS',  'GPS loc.')
    telemetry.heading = TelemetryValue:new('Hdg',  'Heading')
    telemetry.tmp2    = TelemetryValue:new('Tmp2', 'Tmp2')
    telemetry.tmp1    = TelemetryValue:new('Tmp1', 'Tmp1')
    telemetry.rpm     = TelemetryValue:new('RPM',  'RPM')
    telemetry.accx     = TelemetryValue:new('AccX',  'G (x)')
    telemetry.accy     = TelemetryValue:new('AccY',  'G (y)')
    telemetry.accz     = TelemetryValue:new('AccZ',  'G (z)')


local data = {}
    data.armed = false
    data.armedAtMs = nil
    data.disarmedAtMs = nil
    data.armedTimer = "00:00"
    data.power = 0
    data.maxpower = 0
    data.mode = "-"
    data.cellCount =  0
    data.maxVoltage = 0
    data.cellVoltage =0
    data.headingOrt = 0
    data.satcount   = 0
    data.gpslock    = 0
    data.showBattType = false
    data.battTypeCalculated = false
    data.gps_hori_Distance = 0


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
-- calculate gps lock and satelite count
--###############################################################
local function CalculateModeArmedTimer()
  local previousState = data.armed
  if telemetry.tmp1.value ~= nil then
    local status = telemetry.tmp1.value % 10
    data.armed = status == 5 
    status = helper.round((telemetry.tmp1.value - 1) / 10) % 1000
    if status == 0 then
      data.mode = "ACRO"
    elseif status == 1 then
      data.mode = "STAB"
    elseif status == 2 then
      data.mode = "HOVER"
    end
  else
    data.armed = false
    data.mode = "-"
  end
  if data.armed and previousState == false then
    data.armedAtMs = getTime()
  end
  if data.armed then
    local seconds = (getTime() - data.armedAtMs) * 0.01
    data.armedTimer = string.format("%02d:%02d",math.floor(seconds / 60), seconds % 60)
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
        data.gps_hori_Distance = helper.round(radius * c)
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
    -- sanity check for calculated cell voltages
    if data.armed == false then
      data.battTypeCalculated = false
    end

    if data.battTypeCalculated == false then
      if telemetry.battsum.value > 9.9 and telemetry.battsum.value <= 13.05 then
        data.cellCount = 3  -- 3S
      elseif telemetry.battsum.value > 13.05 and telemetry.battsum.value <= 17.4 then
        data.cellCount = 4  -- 4S
      elseif telemetry.battsum.value > 17.4 and telemetry.battsum.value <= 21.5 then
        data.cellCount = 5  -- 5S
      elseif telemetry.battsum.value > 21.5 and telemetry.battsum.value <= 25.8 then
        data.cellCount = 6  -- 6S
      end
      -- calculate battery type only once, not during the flight while the voltage jumps around
      if data.cellCount ~= nil and data.cellCount > 2 then
        data.battTypeCalculated = true
      end
  
      data.maxVoltage = data.cellCount * 4.25
      data.minVoltage = data.cellCount * 3.5
    end
  
    data.cellVoltage = helper.round(telemetry.battsum.value / data.cellCount, 2)
    data.batteryPercent = 100 * (telemetry.battsum.value - data.minVoltage) / (data.maxVoltage - data.minVoltage)
    if data.batteryPercent < 0 then data.batteryPercent = 0 end
  end



--###############################################################
-- Determine compass orientation based on heading data
--###############################################################
local function CalculateHeadingOrientation()
    if telemetry.heading.value ~= nil and telemetry.heading.value < 0 or telemetry.heading.value > 360 then data.headingOrt="Err"  
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

local function DetectResetTelemetryOrFlight()
  --print("tmp1: " .. telemetry.tmp1.value)
  if telemetry.tmp1.value ~= nil and telemetry.tmp1.value == 0 then
    -- telemetry or flight have been reset
    data.battTypeCalculated = false
    return true
  else
    return false
  end 
end


local function refreshTelemetryAndRecalculate()
    DetectResetTelemetryOrFlight()
    -- get new values
    RefreshTelemetryValues()
    -- calculations
    CalculateGpsLock()
    --CalculateGpsData()
    CalculateBatteryTypeAndStatus()
    --CalculateHeadingOrientation()
    CalculateModeArmedTimer()
    if telemetry.current.value ~= nil and telemetry.battsum.value ~= nil then
      data.power = helper.round(telemetry.current.value * telemetry.battsum.value)
      if data.power > data.maxpower then data.maxpower = data.power end
    end
    collectgarbage()
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

local function cleanup()
    clearTable(data)
    clearTable(telemetry)
    clearTable(globalTelemetryMap)
    collectgarbage()
end


local frsky = {}
    frsky.telemetry = telemetry
    frsky.globalTelemetryMap = globalTelemetryMap
    frsky.data = data
    frsky.refreshTelemetryAndRecalculate = refreshTelemetryAndRecalculate
    frsky.cleanup = cleanup

return frsky