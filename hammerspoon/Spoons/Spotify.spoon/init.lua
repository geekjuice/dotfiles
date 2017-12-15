-- spotify

local spoon = {}

local hyper = {"ctrl", "alt"}

local actions = {
  {key="h", value="previous"},
  {key="j", value="playpause"},
  {key="k", value="pause"},
  {key="l", value="next"}
}

local exits = {
  {modifier={"ctrl", "alt"}, key="p"},
  {modifier={"ctrl"}, key="c"},
  {modifier={}, key="escape"}
}

function spoon:init()
  local spotify = hs.hotkey.modal.new(hyper, "p")
  local menubar = hs.menubar.new()

  function spotify:entered()
    menubar:setTitle("♫")
    menubar:returnToMenuBar()
  end

  function spotify:exited()
    menubar:setTitle("")
    menubar:removeFromMenuBar()
  end

  hs.fnutils.each(actions, function(entry)
    spotify:bind({}, entry.key, function()
      if hs.spotify.isRunning() then
        hs.spotify[entry.value]()
      end
    end)
  end)

  hs.fnutils.each(exits, function(entry)
    spotify:bind(entry.modifier, entry.key, function()
      spotify:exit()
    end)
  end)
end

return spoon
