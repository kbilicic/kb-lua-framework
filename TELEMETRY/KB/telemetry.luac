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
--function TelemetryValue:new(name, label, calc)
function TelemetryValue:new(name, label)
  o = {}   -- create object if user does not provide one
  --o.calculated = false or calc
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
    telemetry.vfas    = TelemetryValue:new('VFAS', 'Batt voltage')
    telemetry.a4      = TelemetryValue:new('A4',   'Cell voltage')
    telemetry.current = TelemetryValue:new('Curr', 'Current')
    telemetry.mah     = TelemetryValue:new('mAh',  'mAh')
    telemetry.rssi    = TelemetryValue:new('RSSI', 'RSSI')
    telemetry.galt    = TelemetryValue:new('GAlt', 'GPS altitude')
    --telemetry.alt     = TelemetryValue:new('Alt',  'Altitude')
    telemetry.gspd    = TelemetryValue:new('GSpd', 'GPS speed')
    --telemetry.aspd    = TelemetryValue:new('ASpd', 'Speed')
    telemetry.gps     = TelemetryValue:new('GPS',  'GPS loc.')
    telemetry.heading = TelemetryValue:new('Hdg',  'Heading')
    --telemetry.tmp2    = TelemetryValue:new('Tmp2', 'Tmp2')
    --telemetry.tmp1    = TelemetryValue:new('Tmp1', 'Tmp1')
    --telemetry.rpm     = TelemetryValue:new('RPM',  'RPM')
    telemetry.rxbt    = TelemetryValue:new('RxBt',  'Rx voltage')
    --telemetry.accx    = TelemetryValue:new('AccX',  'G (x)')
    --telemetry.accy    = TelemetryValue:new('AccY',  'G (y)')
    --telemetry.accz    = TelemetryValue:new('AccZ',  'G (z)')
    
    -- ELRS specific sensors
    telemetry.rqly    = TelemetryValue:new('RQly', 'RF Quality')
    --telemetry.tqly    = TelemetryValue:new('TQly', 'TX Quality')
    telemetry.rsnr    = TelemetryValue:new('RSNR', 'RF SNR')
    --telemetry.rfmd    = TelemetryValue:new('RFMD', 'RF Mode')
    telemetry.tpwr    = TelemetryValue:new('TPWR', 'TX Power')
    telemetry.rssi1   = TelemetryValue:new('1RSS', 'RSSI 1')
    telemetry.rssi2   = TelemetryValue:new('2RSS', 'RSSI 2')
    --telemetry.rsnr1   = TelemetryValue:new('1SNR', 'SNR 1')
    --telemetry.rsnr2   = TelemetryValue:new('2SNR', 'SNR 2')
    --telemetry.ant     = TelemetryValue:new('ANT',  'Antenna')
    telemetry.sats    = TelemetryValue:new('Sats', 'Satellites')
    telemetry.batP    = TelemetryValue:new('Bat%', 'Battery %')
    
    -- Additional common sensors for modern setups
    telemetry.fuel    = TelemetryValue:new('Fuel', 'Fuel %')
    --telemetry.vspd    = TelemetryValue:new('VSpd', 'Vertical Speed')
    telemetry.dist    = TelemetryValue:new('Dist', 'Distance')
    --telemetry.a1      = TelemetryValue:new('A1',   'Analog 1')
    --telemetry.a2      = TelemetryValue:new('A2',   'Analog 2')
    --telemetry.a3      = TelemetryValue:new('A3',   'Analog 3')
    --telemetry.cells   = TelemetryValue:new('Cels', 'Cells')
    --telemetry.temp1   = TelemetryValue:new('T1',   'Temperature 1')
    --telemetry.temp2   = TelemetryValue:new('T2',   'Temperature 2')


local data = {}
    data.receiver = ""
    data.battery = 0
    data.rssi = 0
    data.rssi_text = ""
    data.lq = 0
    data.snr = 0;
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
    if telemetry.sats.value ~= nil then
      data.satcount = telemetry.sats.value
    else 
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
    if telemetry.Dist.value ~= nil then
      data.gps_hori_Distance = telemetry.Dist.value
    end

    if (type(telemetry.gps.value) == "table") then
      if telemetry.gps.value["lat"] ~= nil and telemetry.gps.value["lat"] ~= 0 and data.latHome==nil and telemetry.gps.value["lon"] ~= nil and telemetry.gps.value["lon"] ~= 0 and data.lonHome==nil then
          data.latHome = telemetry.gps.value["lat"]
          data.lonHome = telemetry.gps.value["lon"]
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
    if telemetry.vfas.value ~= nil then
      data.battery = helper.round(telemetry.vfas.value, 2)
    elseif telemetry.rxbt.value ~= nil then
      data.battery = helper.round(telemetry.rxbt.value, 2)
    end
    -- sanity check for calculated cell voltages
    if data.armed == false then
      data.battTypeCalculated = false
    end

    if data.battTypeCalculated == false then
      if data.battery ~= nil and data.battery > 9.9 and data.battery <= 13.05 then
        data.cellCount = 3  -- 3S
      elseif data.battery ~= nil and data.battery > 13.05 and data.battery <= 17.4 then
        data.cellCount = 4  -- 4S
      elseif data.battery ~= nil and data.battery > 17.4 and data.battery <= 21.5 then
        data.cellCount = 5  -- 5S
      elseif data.battery ~= nil and data.battery > 21.5 and data.battery <= 25.8 then
        data.cellCount = 6  -- 6S
      end
      -- calculate battery type only once, not during the flight while the voltage jumps around
      if data.cellCount ~= nil and data.cellCount > 2 then
        data.battTypeCalculated = true
      end
  
      data.maxVoltage = data.cellCount * 4.25
      data.minVoltage = data.cellCount * 3.5
    end

    if data.battery ~= nil and data.cellCount ~= nil and data.cellCount > 0 then
      data.cellVoltage = helper.round(data.battery / data.cellCount, 2)
      if telemetry.batP.value ~= nil then
        data.batteryPercent = telemetry.batP.value
      else
        data.batteryPercent = 100 * (data.battery - data.minVoltage) / (data.maxVoltage - data.minVoltage)
      end
      if data.batteryPercent < 0 then data.batteryPercent = 0 end
    end
  end



--###############################################################
-- Determine compass orientation based on heading data
--###############################################################
local function CalculateHeadingOrientation()
    if telemetry.heading.value ~= nil then
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

local function CalculateSignalData()
    -- Standard RSSI calculation
    if telemetry.rssi.value ~= nil then
      data.rssi = telemetry.rssi.value
      data.rssi_text = tostring(telemetry.rssi.value)
    end
    
    -- ELRS RSSI calculation (1RSS and 2RSS are typically negative values)
    local rss1_normalized = nil
    local rss2_normalized = nil
    
    if telemetry.rssi1.value ~= nil and telemetry.rssi1.value < 0 then
      -- Add 130 to negative RSSI and normalize to 0-100 scale
      rss1_normalized = math.min(100, math.max(0, telemetry.rssi1.value + 130))
      data.rssi1_text = tostring(telemetry.rssi1.value)
    end
    
    if telemetry.rssi2.value ~= nil and telemetry.rssi2.value < 0 then
      -- Add 130 to negative RSSI and normalize to 0-100 scale  
      rss2_normalized = math.min(100, math.max(0, telemetry.rssi2.value + 130))
      data.rssi2_text = tostring(telemetry.rssi2.value)
    end
    
    -- Use the higher of the two normalized RSSI values
    if rss1_normalized ~= nil and rss2_normalized ~= nil then
      data.rssi = rss1_normalized > rss2_normalized and rss1_normalized or rss2_normalized
      data.rssi_text = rss1_normalized > rss2_normalized and tostring(telemetry.rssi1.value) or tostring(telemetry.rssi2.value)
    elseif rss1_normalized ~= nil then
      data.rssi = rss1_normalized
      data.rssi_text = tostring(telemetry.rssi1.value)
    elseif rss2_normalized ~= nil then
      data.rssi = rss2_normalized
      data.rssi_text = tostring(telemetry.rssi2.value)
    end
    
    -- Calculate link quality and SNR for ELRS
    if telemetry.rqly.value ~= nil then
      data.lq = telemetry.rqly.value
    end
    if telemetry.rsnr.value ~= nil then
      data.snr = telemetry.rsnr.value
    end
end


local function refreshTelemetryAndRecalculate()
    CalculateSignalData()
    DetectResetTelemetryOrFlight()
    -- get new values
    RefreshTelemetryValues()
    -- calculations
    CalculateGpsLock()
    --CalculateGpsData()
    CalculateBatteryTypeAndStatus()
    --CalculateHeadingOrientation()
    CalculateModeArmedTimer()
    if telemetry.current.value ~= nil and telemetry.vfas.value ~= nil then
      data.power = helper.round(telemetry.current.value * telemetry.vfas.value)
      if data.power > data.maxpower then data.maxpower = data.power end
    end
    if telemetry.rqly.value ~= nil then
      data.receiver = "ELRS"
    else
      data.receiver = "FrSky"
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