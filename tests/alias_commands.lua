local root = arg[1] or "."

local sent = {}
local output = {}

function send(command)
    table.insert(sent, command)
end

function cecho(message)
    table.insert(output, message)
end

function echo(message)
    table.insert(output, message)
end

Leveling = nil
dofile(root .. "/src/scripts/Leveling.lua")

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

Leveling.configurePrompt()
assertEqual(Leveling.PROMPT_SENTINEL, "[TLSLVL]", "prompt sentinel")
assertEqual(Leveling.DEFAULT_PROMPT, "<%h/%H hp %e/%E end> [TLSLVL]", "default prompt")
assertEqual(sent[1], "prompt <%h/%H hp %e/%E end> [TLSLVL]", "prompt command")
local confirmation = table.concat(output)
assertEqual(string.find(confirmation, "TLS-Leveling prompt configured.", 1, true) ~= nil, true,
    "prompt confirmation is printed")
assertEqual(string.find(confirmation, "[TLSLVL] marker is used", 1, true) ~= nil, true,
    "sentinel purpose is printed")

local trollocDefinitions = Leveling.areas["TrollocCamp"]["allowed_mobs"]
assertEqual(#trollocDefinitions, 7, "TrollocCamp has seven unique definitions")
local descriptionsSeen = {}
local soldierDefinitionFound = false
for _, mob in ipairs(trollocDefinitions) do
    assertEqual(descriptionsSeen[mob.description], nil, "TrollocCamp definition is unique")
    descriptionsSeen[mob.description] = true
    if mob.description == "A trolloc soldier screams and attacks" then
        soldierDefinitionFound = true
    end
end
assertEqual(soldierDefinitionFound, true, "TrollocCamp soldier description is spelled correctly")

local helpCalls = 0
Leveling.printHelp = function()
    helpCalls = helpCalls + 1
end
matches = {"leveling"}
dofile(root .. "/src/aliases/leveling.lua")
assertEqual(helpCalls, 1, "bare leveling displays help")

local configureCalls = 0
Leveling.configurePrompt = function()
    configureCalls = configureCalls + 1
end
dofile(root .. "/src/aliases/leveling_setprompt.lua")
assertEqual(configureCalls, 1, "setprompt alias delegates exactly once")

print("Alias command checks passed")
