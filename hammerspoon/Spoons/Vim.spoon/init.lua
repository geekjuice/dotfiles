-- vim mode

local utils = require 'utils'

local hyper = {'alt'}

local maps = {
  {'h', 'left'},
  {'j', 'down'},
  {'k', 'up'},
  {'l', 'right'},
}

local mods = {
  {},
  {'cmd'},
  {'shift'},
  {'cmd', 'shift'},
}

local spoon = {}

function spoon:init()
  hs.fnutils.each(mods, function(mod)
    hs.fnutils.each(maps, function(map)
      local from = {utils:concat(hyper, mod), map[1]};
      local to = {mod, map[2]}
      utils:remap(from, utils:press(to))
    end)
  end)

  utils:remap({'ctrl', '['}, utils:press({'escape'}))
end

return spoon
