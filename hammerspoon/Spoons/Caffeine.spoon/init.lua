-- caffeine

local utils = require 'utils'

local hotkey = {{'ctrl', 'alt'}, '0'}

local function dirname()
  local str = debug.getinfo(2, 'S').source:sub(2)
  return str:match('(.*/)')
end

local spoon = {}

function spoon:init()
  local awake = true
  local menubar = hs.menubar.new()
  local icons = dirname() .. '/icons'

  local function toggleState()
    awake = not awake and true or false

    hs.caffeinate.set('displayIdle', awake)

    if awake then 
      menubar:setIcon(icons .. '/active@2x.png')
    else
      menubar:setIcon(icons .. '/inactive@2x.png')
    end
  end

  if menubar then
    menubar:setClickCallback(toggleState)
    toggleState()

    utils:remap(hotkey, function()
      toggleState()
    end)
  end
end

return spoon
