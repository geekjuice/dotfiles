-- caffeine

local spoon = {}

local function dirname()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

function spoon:init()
  local caffeine = hs.menubar.new()
  local icons = dirname() .. "/icons"

  function setCaffeineDisplay(state)
    if state then
      caffeine:setIcon(icons .. "/active@2x.png")
    else
      caffeine:setIcon(icons .. "/inactive@2x.png")
    end
  end

  function caffeineClicked()
    setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
  end

  if caffeine then
    caffeine:setClickCallback(caffeineClicked)
    setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
  end
end

return spoon
