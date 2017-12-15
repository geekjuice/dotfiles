-- spoons
local spoons = {
  "Caffeine",
  "Grid",
  "Spotify",
  "Vim"
}

for _, spoon in pairs(spoons) do
  hs.loadSpoon(spoon)
end

-- auto-reload
local config = os.getenv("HOME") .. "/.hammerspoon/init.lua"
hs.pathwatcher.new(config, hs.reload):start()
