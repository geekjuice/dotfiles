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
local spoons = os.getenv('HOME') .. '/.hammerspoon'
hs.pathwatcher.new(spoons, hs.reload):start()
