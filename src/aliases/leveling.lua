local valid_options = {"start", "haste", "fury", "detects", "sanc", "pka", "init", "ignore"}
local valid_options_string = table.concat(valid_options, ", ")
local option = matches[2]
local value = matches[3]
if not option or option == "" then
    Leveling.printHelp()
    return
end

if not table.contains(valid_options, option) then
    cecho("I'm sorry but the available options are: " .. valid_options_string)
    Leveling.printHelp()
    return
end

if option == "start" then
    Leveling.loadArea(value)

elseif option == "haste" then
    Leveling.setHaste(value)

elseif option == "fury" then
    Leveling.setFury(value)

elseif option == "detects" then
    Leveling.setDetects(value)

elseif option == "sanc" then
    Leveling.setSanc(value)

elseif option == "pka" then
    Leveling.addPostKillAction(value)

elseif option == "init" then
    Leveling.setInit(value)

elseif option == "ignore" then
    Leveling.handleIgnoreAction(value)

else
    cecho("\nUnknown option: " .. option .. "\n")
end
