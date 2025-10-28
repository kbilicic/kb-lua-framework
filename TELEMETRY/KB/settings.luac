KB_SCRIPT_HOME = "/SCRIPTS/TELEMETRY/KB"

local configuration = nil
local vtxAllPowerOptions = {"PIT", 25, 50, 100, 200, 400, 500, 600, 700, 800, 1000, 1200, 1500, 2000}
local vtxPowerOptionsSel = {false,false,false,false,false,false,false,false,false,false,false,false,false,false}
local currentSelected = 1
local changesSaved = false

local indent = ""
local function outputTable (tbl)
    if not (type(tbl)=="table") then 
    return tbl
    end
    indent=indent .. "   "
    local res= "\n" .. indent .. "{\n" 
    for k, v in pairs(tbl) do
    if type(k) == "number" then
        k="[" .. k .. "]"
    end
    if type(v) == "table" then
        res=res .. indent .. k .. " = " .. outputTable(v) .. ",\n" 
    elseif type(v) == "function" then
    elseif type(v) == "string" then
        res=res .. indent .. k .. " = '" .. v .. "',\n" 
    elseif type(v) == "boolean" then
        if v then res=res .. indent .. k .. " = true,\n"
        else res=res .. indent .. k .. " = false,\n"
        end
    else
        res=res .. indent .. k .. " = " .. v .. ",\n" 
    end
    end
    res = res ..   indent .. "}"
    indent=string.sub(indent,4) 
    return res 
end  



local function drawCheckOption(x,y, yScrollPos, name, checked, selected)
    lcd.drawText(x, y+2-yScrollPos, name, SMLSIZE)
    local newX = lcd.getLastRightPos() + 5
    if checked then
        lcd.drawLine(newX+1, y-yScrollPos+4, newX+2, y-yScrollPos+6, SOLID, FORCE)
        lcd.drawLine(newX+3, y-yScrollPos+6, newX+6, y-yScrollPos+3, SOLID, FORCE)
    end
    if selected then
        lcd.drawFilledRectangle(newX, y - yScrollPos, 8, 8)
    else
        lcd.drawRectangle(newX, y - yScrollPos, 8, 8)
    end
end

local function getSelectedPowerTable()
    local selectedPowerTable = {}
    local index = 1
    for i=2, #vtxAllPowerOptions do
        if vtxPowerOptionsSel[i] then
            selectedPowerTable[index] = vtxAllPowerOptions[i]
            index = index + 1
        end
    end
    index = nil
    collectgarbage()
    return selectedPowerTable
end


local function loadSettings()
    local modelInfo = model.getInfo()
    local modelName = modelInfo["name"]
    if modelName == "" then modelName = "default" end

    if configuration == nil then
        -- Initialize with default configuration for now
        configuration = {
            models = {
                default = {
                    modelName = "default",
                    vtxPower = { 25, 200, 400 },
                    vtxPit = true
                }
            }
        }
    end

    if configuration.models == nil then
        configuration.models = {}
    end

    if configuration.models["default"] == nil then
        local defaultModel = {}
        defaultModel.modelName = "default"
        defaultModel.vtxPower = { 25 }
        defaultModel.vtxPit = false
        configuration.models["default"] = defaultModel
        defaultModel = nil
    end

    if changesSaved == false or currentModelConfig == nil or currentModelConfig ~= nil and currentModelConfig.modelName ~= modelName then
        -- set power options on UI on first load OR when model is changed
        if configuration.models ~= nil and configuration.models[modelName] ~= nil and configuration.models[modelName].vtxPower ~= nil then
            for i=1, #configuration.models[modelName].vtxPower do
                local index = 2
                for j=1, #vtxAllPowerOptions do
                    if configuration.models[modelName].vtxPower[i] == vtxAllPowerOptions[j] then
                        vtxPowerOptionsSel[j] = true
                        break
                    end
                    index = index + 1
                end
            end
            vtxPowerOptionsSel[1] = configuration.models[modelName].vtxPit
        end

        currentModelConfig = configuration.models[modelName]
    end
    
    
    collectgarbage()
end


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


local function saveSettings()
    changesSaved = true
    loadSettings()
    local modelInfo = model.getInfo()
    local modelName = modelInfo["name"]
    if modelName == "" then modelName = "default" end
    --modelName = modelName:gsub(" ", "")
    print("model name: " .. modelName)
    -- initialize current model settings if they don't exist
    if configuration == nil then
        configuration = {}
    end
    if configuration.models == nil then
        configuration.models = {}
    end
    if configuration.models["default"] == nil then
        local defaultModel = {}
        defaultModel.modelName = "default"
        defaultModel.vtxPower = { 25 }
        defaultModel.vtxPit = false
        configuration.models["default"] = defaultModel
        defaultModel = nil
    end
    if configuration.models[modelName] == nil then
        local thisModel = {}
        thisModel.modelName = modelName
        thisModel.vtxPower = getSelectedPowerTable()
        thisModel.vtxPit = vtxPowerOptionsSel[1]
        configuration.models[modelName] = thisModel
        thisModel = nil
    end
    configuration.models[modelName].vtxPower = getSelectedPowerTable()
    configuration.models[modelName].vtxPit = vtxPowerOptionsSel[1]
    currentModelConfig = configuration.models[modelName]
    if currentModelConfig and currentModelConfig.vtxPower then
        print(tableToString(currentModelConfig.vtxPower))
    end
    -- File writing disabled for now to avoid I/O issues
    -- local f = io.open(KB_SCRIPT_HOME .. "/settings.config", "w")        
    -- io.write(f, "return " .. outputTable(configuration))
    -- io.close(f)
    modelName = nil
    collectgarbage()
end


-- ###############################################################
-- ###############################################################
local function drawVtxOptions(x,y, yScrollPos, event)
    loadSettings()

    -- handle events
    if event == EVT_ENTER_BREAK then
        vtxPowerOptionsSel[currentSelected] = not(vtxPowerOptionsSel[currentSelected])

        saveSettings()

    elseif (event == EVT_ROT_RIGHT or event == EVT_PLUS_FIRST) then
        currentSelected = currentSelected + 1
    elseif (event == EVT_ROT_LEFT or event == EVT_MINUS_FIRST) then
        currentSelected = currentSelected - 1
    end

    if currentSelected > #vtxAllPowerOptions then
        currentSelected = 1
    end
    if currentSelected < 1 then
        currentSelected = #vtxAllPowerOptions
    end

    yScrollPos = y + currentSelected*12 - 15

    local metric = ""
    for i=1, #vtxAllPowerOptions do
        if i > 1 then metric = "mW" end
        drawCheckOption(x,y + i*12,yScrollPos, vtxAllPowerOptions[i]..metric, vtxPowerOptionsSel[i], i == currentSelected)
    end

    collectgarbage()
end



local settings = {}
settings.drawVtxOptions = drawVtxOptions
settings.getSelectedPowerTable = getSelectedPowerTable
settings.currentModelConfig = currentModelConfig
settings.saveSettings = saveSettings
settings.loadSettings = loadSettings

return settings