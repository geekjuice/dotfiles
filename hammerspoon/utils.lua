-- utils

local utils = {}

function utils:json(map)
   if type(map) == 'table' then
      local json = '{ '
      for key,value in pairs(map) do
         if type(key) ~= 'number' then key = '"' .. key .. '"' end
         json = json .. '[' .. key .. '] = ' .. utils:json(value) .. ','
      end
      return json .. '} '
   else
      return tostring(map)
   end
end

function utils:concat(first, second)
  local merged = {}
  for _, value in ipairs(first) do
    table.insert(merged, value)
  end
  for _, value in ipairs(second) do
    table.insert(merged, value)
  end
  return merged
end

function utils:press(map)
  local modded = map[2] ~= nil
  local key = modded and map[2] or map[1]
  local mods = modded and map[1] or {}
	return function()
    hs.eventtap.keyStroke(mods, key, 1000)
  end
end

function utils:remap(map, fn)
	hs.hotkey.bind(map[1], map[2], fn, nil, fn)	
end

return utils
