BuffManager = {}
BuffManager.buffs = {
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

function BuffManager.processBuffs()
  local anyFalse = false

  for buff, isApplied in pairs(BuffManager.buffs) do
    if not isApplied then
      local castCommand = BuffManager.getCastCommand(buff)
      if castCommand then
        send(castCommand)
      end
      
      anyFalse = true
      BuffManager.buffs[buff] = true -- Set the buff as applied
    end
  end

  -- Send "aff" command to check if any buffs were applied
  send("aff")

  return anyFalse -- Return whether any buffs were processed
end

function BuffManager.getCastCommand(buff)
  -- Get the cast command for the buff based on its key
  -- Return the cast command or nil if it doesn't exist
  -- You can define the mapping between buffs and cast commands here
  -- Example implementation:
  local castCommands = {
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

repeat
  local anyFalse = BuffManager.processBuffs()
until not anyFalse