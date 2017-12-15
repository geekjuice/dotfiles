-- grid

local utils = require 'utils'

local hyper = {'ctrl', 'alt'}

local layouts = {
  bottom50={x=0, y=0.5, w=1, h=0.5},
  top50={x=0, y=0, w=1, h=0.5},
  left60={x=0, y=0, w=0.6, h=1},
  right40={x=0.6, y=0, w=0.4, h=1},
  center={x=0.05, y=0.05, w=0.9, h=0.9},
}

local actions = {
  {key='h', value=hs.layout.left50},
  {key='j', value=layouts.bottom50},
  {key='k', value=layouts.top50},
  {key='l', value=hs.layout.right50},
  {key='[', value=layouts.left60},
  {key=']', value=layouts.right40},
  {key='-', value=layouts.center},
  {key='=', value=hs.layout.maximized},
}

local spoon = {}

function spoon:init()
  hs.window.animationDuration = 0

  hs.fnutils.each(actions, function(entry)
    utils:remap({hyper, entry.key}, function()
      hs.window.focusedWindow():moveToUnit(entry.value)
    end)
  end)
end

return spoon
