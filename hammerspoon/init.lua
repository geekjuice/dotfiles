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
local dir = os.getenv('HOME') .. '/.hammerspoon'
hs.pathwatcher.new(dir, hs.reload):start()
