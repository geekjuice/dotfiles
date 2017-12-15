-- vim mode

local spoon = {}

local hyper = {"alt"}

local actions = {
  {key="h", value="left"},
  {key="j", value="down"},
  {key="k", value="up"},
  {key="l", value="right"}
}

local function keyCode(key)
  return function()
    local event = hs.eventtap.event
    event.newKeyEvent({}, string.lower(key), true):post()
    event.newKeyEvent({}, string.lower(key), false):post()
  end
end

function spoon:init()
  hs.fnutils.each(actions, function(entry)
    hs.hotkey.bind(hyper, entry.key, keyCode(entry.value), nil, keyCode(entry.value))
  end)
end

return spoon
