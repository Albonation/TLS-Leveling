local valid_options = {"start", "engage", "duringcombat", "pka", "init", "ignore"}
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

elseif option == "duringcombat" then
    Leveling.setDuringCombat(value)

elseif option == "pka" then
    Leveling.addPostKillAction(value)

elseif option == "init" or option == "engage" then
    Leveling.setInit(value)

elseif option == "ignore" then
    Leveling.handleIgnoreAction(value)

else
    cecho("\nUnknown option: " .. option .. "\n")
end
