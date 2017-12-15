-- work

local utils = require 'utils'

local hotkey = {{'ctrl', 'alt'}, '9'}

local reset = 'empty'
local cloudflare = '8.8.8.8'

local function dirname()
  local str = debug.getinfo(2, 'S').source:sub(2)
  return str:match('(.*/)')
end

local spoon = {}

function spoon:init()
  local working = true
  local menubar = hs.menubar.new()
  local icons = dirname() .. '/icons'

  local function toggleState()
    working = not working and true or false

    if working then
      menubar:setIcon(icons .. '/work@2x.png')
      hs.execute('networksetup -setdnsservers Wi-Fi ' .. cloudflare)
    else
      menubar:setIcon(icons .. '/home@2x.png')
      hs.execute('networksetup -setdnsservers Wi-Fi ' .. reset)
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
