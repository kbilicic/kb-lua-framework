local helper = assert(loadScript(KB_SCRIPT_HOME.."/basics.lua"))()


--###############################################################
-- Draw flight MODE string trimmed to 4 characters (black background)
--###############################################################
local function DrawFlightMode(x, y, mode)
  lcd.drawText(x, y, string.sub(mode,1,4), SMLSIZE)
  lcd.drawFilledRectangle(x-2, y-2, 23, 10)
end

local widgets = {}
widgets.DrawFlightMode = DrawFlightMode

return widgets