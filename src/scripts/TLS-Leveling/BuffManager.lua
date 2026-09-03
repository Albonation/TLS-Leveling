BuffManager = {}

-- Buff parsing state. A true value means the latest affects output confirmed
-- that the buff is active; expiration triggers mark the value false again.
BuffManager.buffs =
{
  quickness = false,
  hide = false,
  sneak = false,
  precision = false,
  sunburst = false,
  cloaking = false,
  fortitude = false,
  flamevoid = false,
  divine_grace = false,
  rage = false,
  brute_strength = false,
  ancient_knowledge = false
}

--- Marks a configured buff active using the display name captured from `aff`.
--- @param mudBuffName string Name printed by the MUD, such as "divine grace".
--- @return boolean recognized Whether the captured name is managed here.
function BuffManager.markActive(mudBuffName)
  local buffName = string.lower(tostring(mudBuffName or "")):gsub(" ", "_")
  if BuffManager.buffs[buffName] == nil then
    return false
  end

  BuffManager.buffs[buffName] = true
  return true
end

--- Marks a configured buff missing after an expiration/failure trigger fires.
--- @param buffName string Internal key in BuffManager.buffs.
--- @return boolean recognized Whether the buff name is managed here.
function BuffManager.markMissing(buffName)
  if BuffManager.buffs[buffName] == nil then
    return false
  end

  BuffManager.buffs[buffName] = false
  return true
end

--- Returns the internal names of every buff not currently confirmed active.
--- @return table missingBuffs
function BuffManager.checkMissingBuffs()  
  local missingBuffs = {}  
  for buff, value in pairs(BuffManager.buffs) do
    if not value then
      table.insert(missingBuffs, buff)
    end
  end  
  return missingBuffs
end

--- Sends each missing buff's cast command, then requests `aff` so triggers can
--- refresh BuffManager.buffs. Called before Leveling sends a route direction.
function BuffManager.processBuffs()
  local missingBuffs = BuffManager.checkMissingBuffs()
  if next(missingBuffs) then
    for _, buff in ipairs(missingBuffs) do
      local castCommand = BuffManager.getCastCommand(buff)
      if castCommand then
        send(castCommand)
      end
    end
    send("aff")
  end
end

--- Resolves an internal buff name to the corresponding MUD command.
--- @param buff string Internal key in BuffManager.buffs.
--- @return string|nil castCommand
function BuffManager.getCastCommand(buff)
  local castCommands =
  {
    quickness = "quickness",
    hide = "hide",
    sneak = "sneak",
    precision = "precision",
    sunburst = "sunburst",
    cloaking = "cloak",
    fortitude = "fortitude",
    flamevoid = "flamevoid",
    divine_grace = "divine",
    rage = "rage",
    brute_strength = "brute",
    ancient_knowledge = "ancient"
  }  
  return castCommands[buff]
end
