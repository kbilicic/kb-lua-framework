  local function loadCrossfireIfNeeded(var)
    if var == nil then
      var = assert(loadScript('/CROSSFIRE/crossfire.luac'))()
      return var
    else
      return var
    end
  end


  crsf = loadCrossfireIfNeeded(crsf)



  --------------------------------------------------------------------------------
  -- BACKGROUND loop FUNCTION
  --------------------------------------------------------------------------------
  local function backgroundwork()

  end
  
  
  --------------------------------------------------------------------------------
  -- RUN loop FUNCTION
  --------------------------------------------------------------------------------
  local function run(event)
    
    crsf = loadCrossfireIfNeeded(crsf)
    crsf.run(event)
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