-- grid

local spoon = {}

local hyper = {"ctrl", "alt"}

local actions = {
  {key="h", value=hs.layout.left50},
  {key="j", value=hs.layout.centered},
  {key="k", value=hs.layout.maximized},
  {key="l", value=hs.layout.right50}
}

function spoon:init()
  hs.window.animationDuration = 0
  hs.layout.centered = {x=0.1, y=0, w=0.8, h=0.9}

  hs.fnutils.each(actions, function(entry)
    hs.hotkey.bind(hyper, entry.key, function()
      hs.window.focusedWindow():moveToUnit(entry.value)
    end)
  end)
end

return spoon
