BuffManager = {}
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

function BuffManager.checkMissingBuffs()  
  local missingBuffs = {}  
  for buff, value in pairs(BuffManager.buffs) do
    if not value then
      table.insert(missingBuffs, buff)
    end
  end  
  return missingBuffs
end

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