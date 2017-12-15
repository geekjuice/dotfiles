-- mouse

local spoon = {}

local hyper = {'fn', 'ctrl'}

local maps = {
  [2]='up',
  [3]='left',
  [4]='right',
}

function spoon:init()
  local handlers = hs.eventtap.event.types.otherMouseDown
  local register = hs.eventtap.new({handlers}, function(e)
    local button = e:getProperty(
      hs.eventtap.event.properties['mouseEventButtonNumber']
    )
    if (maps[button]) then
      hs.eventtap.keyStroke(hyper, maps[button], 1000)
    end
  end)

  register:start()
end

return spoon
