-- String from the MUD
local mudString = matches[2]

-- Iterate over BuffManager.buffs table
for buff, _ in pairs(BuffManager.buffs) do
  -- Replace spaces with underscores in mudString
  local formattedMudString = mudString:gsub(" ", "_")
  
  -- Check if formattedMudString matches the buff name
  if formattedMudString == buff then
    -- Set the corresponding key to true
    BuffManager.buffs[buff] = true
    break  -- Exit the loop if a match is found (optional)
  end
end