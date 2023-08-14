-- mouse
local utils = require 'utils'

local hyper = {'fn', 'ctrl'}

local maps = {
  [2]='up',
  [3]='left',
  [4]='right',
}

local spoon = {}

function spoon:init()
  local handlers = hs.eventtap.event.types.otherMouseDown
  register = hs.eventtap.new({handlers}, function(e)
    local button = e:getProperty(
      hs.eventtap.event.properties['mouseEventButtonNumber']
    )
    if (maps[button]) then
      hs.eventtap.keyStroke(hyper, maps[button], 1000)
      return true
    end
  end)

  register:start()

end

return spoon

