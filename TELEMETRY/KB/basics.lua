
--###############################################################
-- rounds a number to specif decimal point
--############################################################### 
local function round(num, idp)
  local temp = 10^(idp or 0)
  if num >= 0 then 
    return math.floor(num * temp + 0.5) / temp
  else
    return math.ceil(num * temp - 0.5) / temp 
  end

  temp = nil
  collectgarbage()
end

--###############################################################
-- prints table content to a string for debugging
-- supports nested tables
--############################################################### 
local function tableToString(t)
  if type(t) ~= "table" then return t
  else
    local st = "[ "
    for i=1,#t do
      if t[i] ~= nil then
        if st ~= "[ " then st = st .. ", " end
        if type(t[i]) == "table" then
          st = st .. tableToString(t[i])
        else
          st = st .. t[i]
        end
      end
    end
    return st .. " ]"
  end
end

--###############################################################
-- Metrics conversion 
--###############################################################
SPEED = { KMH=1, MPS=0.277778, KNOT=0.539957, MPH=0.621371 }
DISTANCE = { KM=1, M=1000, FEET=3280.84, MILE=0.621371 }

local function convert(value, fromMetric, toMetric)
  return value*toMetric / fromMetric
end


-- ###############################################################
-- Helper method to draw a shape
-- Shape is an array of lines
-- line is an array of 4 numbers that represent two coordinates (start and end point for the line)
-- ###############################################################
local function drawShape(x, y, shape, rotation)
    sinShape = math.sin(rotation)
    cosShape = math.cos(rotation)
    for index, point in pairs(shape) do
      lcd.drawLine(
        x + math.floor(point[1] * cosShape - point[2] * sinShape + 0.5),
        y + math.floor(point[1] * sinShape + point[2] * cosShape + 0.5),
        x + math.floor(point[3] * cosShape - point[4] * sinShape + 0.5),
        y + math.floor(point[3] * sinShape + point[4] * cosShape + 0.5),
        SOLID, FORCE
      )
    end
end


local function drawShape2(x, y, shape, rotation, scale)
  sinShape = math.sin(rotation)
  cosShape = math.cos(rotation)
  for index, point in pairs(shape) do
    lcd.drawLine(
      x + scale * math.floor(point[1] * cosShape - point[2] * sinShape + 0.5),
      y + scale * math.floor(point[1] * sinShape + point[2] * cosShape + 0.5),
      x + scale * math.floor(point[3] * cosShape - point[4] * sinShape + 0.5),
      y + scale * math.floor(point[3] * sinShape + point[4] * cosShape + 0.5),
      SOLID, FORCE
    )
  end
end

local function drawShape2Scrolled(x, y, yScrollPos, shape, rotation, scale)
  sinShape = math.sin(rotation)
  cosShape = math.cos(rotation)
  for index, point in pairs(shape) do
    lcd.drawLine(
      x + scale * math.floor(point[1] * cosShape - point[2] * sinShape + 0.5),
      y - yScrollPos + scale * math.floor(point[1] * sinShape + point[2] * cosShape + 0.5),
      x + scale * math.floor(point[3] * cosShape - point[4] * sinShape + 0.5),
      y - yScrollPos + scale * math.floor(point[3] * sinShape + point[4] * cosShape + 0.5),
      SOLID, FORCE
    )
  end
end


  local function drawLineScrolled(x,y,x2,y2,pattern, flags, yScrollPos)
    lcd.drawLine(x, y - yScrollPos, x2, y2 - yScrollPos, pattern, flags)
  end
  
  local function drawTextScrolled(x,y,text, options, yScrollPos)
    lcd.drawText(x, y - yScrollPos, text, options)
  end


  local helper = {}

  helper.round = round
  helper.drawShape = drawShape
  helper.drawShape2 = drawShape2
  helper.drawShape2Scrolled = drawShape2Scrolled
  helper.drawLineScrolled = drawLineScrolled
  helper.drawTextScrolled = drawTextScrolled

  return helper