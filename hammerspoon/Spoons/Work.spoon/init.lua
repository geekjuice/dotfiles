-- work

local utils = require 'utils'

local hotkey = {{'ctrl', 'alt'}, '0'}

local reset = 'empty'
local cloudflare = '1.1.1.1'

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
      hs.execute('networksetup -setdnsservers Ethernet ' .. cloudflare)
    else
      menubar:setIcon(icons .. '/home@2x.png')
      hs.execute('networksetup -setdnsservers Wi-Fi ' .. reset)
      hs.execute('networksetup -setdnsservers Ethernet ' .. reset)
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
