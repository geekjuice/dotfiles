-- spoons
local spoons = {
  'Apps',
  'Mouse',
  'Vim',
  'Work'
}

for _, spoon in pairs(spoons) do
  hs.loadSpoon(spoon)
end

-- auto-reload
local configDir = os.getenv('HOME') .. '/.hammerspoon'
hs.pathwatcher.new(configDir, hs.reload):start()
