-- apps

local utils = require 'utils'

local hyper = {'alt'}

local arc = 'company.thebrowser.Browser'
local cursor = 'com.todesktop.230313mzl4w4u92'
local spark = 'com.readdle.smartemail-Mac'
local spotify = 'com.spotify.client'
local slack = 'com.tinyspeck.slackmacgap'

local maps = {
  {'b', arc},
  {'c', cursor},
  {'e', spark},
  {'m', spotify},
  {'s', slack},
}

local toggles = {
  {',' , {arc, cursor}},
  {'.' , {spark, slack}},
}

local spoon = {}

function spoon:init()
  hs.fnutils.each(maps, function(map)
    utils:remap({hyper, map[1]}, function()
      hs.application.launchOrFocusByBundleID(map[2])
    end)
  end)

  hs.fnutils.each(toggles, function(toggle)
    utils:remap({hyper, toggle[1]}, function()
      local focused = hs.window.focusedWindow()
      if focused == nil or focused:application():bundleID() == toggle[2][2] then
        hs.application.launchOrFocusByBundleID(toggle[2][1])
      else
        hs.application.launchOrFocusByBundleID(toggle[2][2])
      end
    end)
  end)
end

return spoon
