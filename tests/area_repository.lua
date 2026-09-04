local root = arg[1] or "."
local sent = {}
local output = {}
local enabledTriggers = {}

unpack = unpack or table.unpack

function enableTrigger(name)
    enabledTriggers[name] = true
end

function disableTrigger(name)
    enabledTriggers[name] = false
end

function send(command)
    table.insert(sent, command)
end

function sendAll(...)
    for index = 1, select("#", ...) do
        send((select(index, ...)))
    end
end

function cecho(message)
    table.insert(output, message)
end

echo = cecho

function killTimer()
end

string.trim = function(value)
    return string.match(value, "^%s*(.-)%s*$")
end

string.split = function(value, separator)
    local parts = {}
    local startIndex = 1
    local first, last = string.find(value, separator, startIndex)
    while first do
        table.insert(parts, string.sub(value, startIndex, first - 1))
        startIndex = last + 1
        first, last = string.find(value, separator, startIndex)
    end
    table.insert(parts, string.sub(value, startIndex))
    return parts
end

table.contains = function(values, value)
    for _, candidate in ipairs(values) do
        if candidate == value then
            return true
        end
    end
    return false
end

local function assertEqual(actual, expected, message)
    assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- Leveling initializes before the repository exists; old embedded data is retired.
Leveling = {areas = {obsolete = {}}}
dofile(root .. "/src/scripts/Leveling.lua")
assertEqual(Leveling.areas, nil, "obsolete area owner is cleared on upgrade")
assertEqual(Leveling.isRunning, false, "initialization does not start a session")
dofile(root .. "/src/scripts/AreaRepository.lua")
assertEqual(#sent, 0, "loading static data sends no commands")
assertEqual(#output, 0, "repository does not format output")
assertEqual(next(enabledTriggers), nil, "repository does not manage triggers")
assertEqual(Leveling.currentArea, nil, "repository does not select an area")
dofile(root .. "/src/scripts/RoomScanner.lua")
dofile(root .. "/src/scripts/Navigator.lua")
dofile(root .. "/src/scripts/Combat.lua")
dofile(root .. "/src/scripts/BuffManager.lua")

local Repository = Leveling.AreaRepository
local Navigator = Leveling.Navigator
local Combat = Leveling.Combat
local Scanner = Leveling.RoomScanner
local descriptions = {
    Drones = "Start at the hole in the wall, where you go just 1 down for drones.",
    KoreSprings = "From just south of the entrance to Kore Springs",
    TrollocCamp = "Start 1 east of the trolloc camp, in the blight."
}

local areaCount = 0
for name, area in pairs(Repository:list()) do
    areaCount = areaCount + 1
    assertEqual(area.description, descriptions[name], "area listing/help description")
    assertEqual(Repository:get(name), area, "lookup and listing share one definition")
    assert(#area.dirs > 0 and #area.allowed_mobs > 0, "known area has routes and mobs")
end
assertEqual(areaCount, 3, "exactly three configured areas")
for name in pairs(descriptions) do
    assert(Repository:get(name), "known area is available: " .. name)
end
assertEqual(Repository:get("unknown"), nil, "unknown lookup returns nil")
assertEqual(Repository:get("trolloccamp"), nil, "canonical name matching remains case sensitive")

-- Listing retains the old pairs traversal and exact presentation, without sorting.
local expectedOutput = "\n<red>        Leveling Areas:<reset>\n\n"
for name in pairs(Repository:list()) do
    expectedOutput = expectedOutput .. "  * <yellow>" .. name .. "<reset>\n"
        .. "      " .. descriptions[name] .. "\n"
end
expectedOutput = expectedOutput .. "\n"
dofile(root .. "/src/aliases/leveling_areas.lua")
assertEqual(table.concat(output), expectedOutput, "areas alias preserves listing text and pairs order")

output = {}
Leveling.loadArea("unknown")
assertEqual(table.concat(output), "<red>\nAttempting to load: 'unknown'<reset>\n"
    .. "\n<red>Unknown area: unknown.<reset>\n", "invalid-area output is preserved")
assertEqual(Leveling.isRunning, false, "invalid area does not start a session")
assertEqual(Navigator.state, Navigator.states.idle, "invalid area does not start navigation")
assertEqual(#sent, 0, "invalid area sends nothing")

local trolloc = Repository:get("TrollocCamp")
local routeBefore = table.concat(trolloc.dirs, ",")
local expectedMobs = {
    ["A trolloc warrior stands here with a look of blood lust in his eyes"] = "troll",
    ["A trolloc scout screams and attacks"] = "troll",
    ["A trolloc soldier screams and attacks"] = "troll",
    ["A bloodlord stands here studying the ancient books of legend"] = "bloodlord",
    ["A dreadlord stands here studying the books of knowledge"] = "dreadlord",
    ["A darkhound is standing here"] = "darkhound",
    ["A trolloc chieftain stands here with a wicked toothy grin"] = "chief"
}
assertEqual(#trolloc.allowed_mobs, 7, "TrollocCamp retains seven definitions")
local seen = {}
for _, mob in ipairs(trolloc.allowed_mobs) do
    assertEqual(mob.name, expectedMobs[mob.description], "exact mob description and attack keyword")
    assertEqual(seen[mob.description], nil, "no duplicate target definition")
    seen[mob.description] = true
end

-- The actual start alias uses the repository through Leveling orchestration.
for buff in pairs(BuffManager.buffs) do
    BuffManager.buffs[buff] = true
end
BuffManager.buffs.quickness = false
Leveling.setHaste("quaff off")
matches = {"leveling start TrollocCamp", "start", "TrollocCamp"}
dofile(root .. "/src/aliases/leveling.lua")
assertEqual(Leveling.currentAreaName, "TrollocCamp", "session owns the chosen canonical name")
assertEqual(Leveling.currentArea, trolloc, "session refers to the repository definition")
assertEqual(Scanner.mobDefinitions, trolloc.allowed_mobs, "Leveling configures scanner definitions")
assertEqual(Combat.mobDefinitions, trolloc.allowed_mobs, "Leveling configures combat definitions")
assertEqual(table.concat(Navigator.route, ","), routeBefore, "full configured route reaches Navigator unchanged")
assert(Navigator.route ~= trolloc.dirs, "Navigator retains its own execution copy")
assertEqual(table.concat(sent, ","), "quickness,aff,w", "buff restoration still precedes the first route step")
assertEqual(enabledTriggers["Leveling Haste"], true, "configured buff trigger remains active")
BuffManager.buffs.quickness = true
Leveling.handleIgnoreAction("bloodlord")
local activeAttempt = Navigator.activeAttemptId
local commandsBefore = #sent
Leveling.loadArea("unknown")
assertEqual(#sent, commandsBefore, "invalid selection during a run sends nothing")
assertEqual(Leveling.currentArea, trolloc, "invalid selection keeps the current area")
assertEqual(Navigator.activeAttemptId, activeAttempt, "invalid selection preserves pending movement")
assertEqual(Combat:isIgnored("bloodlord"), true, "invalid selection preserves ignores")

-- Exercise Leveling's completion callback, not Navigator's already-tested mechanics.
local runsBefore = Leveling.stats.total.num_runs
Leveling.handleRouteComplete()
assertEqual(Leveling.stats.total.num_runs, runsBefore + 1, "loop completion records one run")
assertEqual(Leveling.currentArea, trolloc, "same-area loop reuses its definition")
assertEqual(Combat:isIgnored("bloodlord"), true, "same-area loop preserves ignores")
assertEqual(Navigator.routeIndex, 1, "same-area loop starts at the first route step")
assertEqual(table.concat(Navigator.route, ","), routeBefore, "loop reload preserves every route command")
assertEqual(sent[#sent], "w", "same-area loop requests the first movement")

for _, name in ipairs({"Drones", "KoreSprings"}) do
    Leveling.loadArea(name)
    local area = Repository:get(name)
    assertEqual(Leveling.currentAreaName, name, "area switch updates session selection")
    assertEqual(Leveling.currentArea, area, "area switch uses repository definition")
    assertEqual(Scanner.mobDefinitions, area.allowed_mobs, "area switch reconfigures scanner")
    assertEqual(Combat.mobDefinitions, area.allowed_mobs, "area switch reconfigures combat")
    assertEqual(#Combat.ignoredMobNames, 0, "area switch clears ignores")
    assertEqual(table.concat(Navigator.route, ","), table.concat(area.dirs, ","), "area switch loads its full route")
    assertEqual(sent[#sent], area.dirs[1], "area switch requests its first movement")
end
assertEqual(table.concat(trolloc.dirs, ","), routeBefore, "navigation and switching do not mutate static route data")
Leveling.stop()
assertEqual(Leveling.currentArea, nil, "stop clears session selection")
assertEqual(Repository:get("TrollocCamp"), trolloc, "stop preserves static area data")

print("AreaRepository lookup, listing, route handoff, and session integration checks passed")
