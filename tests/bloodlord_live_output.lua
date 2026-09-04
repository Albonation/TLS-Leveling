local root = arg[1] or "."
local sent = {}
local enabledTriggers = {}
local timers = {}
local nextTimerId = 0
local snapshots = {}
local consumedRoom

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

function cecho()
end

function tempTimer(delay, callback)
    assert(delay == 3, "post-kill look retains its three-second delay")
    nextTimerId = nextTimerId + 1
    timers[nextTimerId] = callback
    return nextTimerId
end

function killTimer(id)
    timers[id] = nil
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

Leveling = nil
dofile(root .. "/src/scripts/Leveling.lua")
dofile(root .. "/src/scripts/AreaRepository.lua")
dofile(root .. "/src/scripts/RoomScanner.lua")
dofile(root .. "/src/scripts/Navigator.lua")
dofile(root .. "/src/scripts/Combat.lua")
BuffManager = {processBuffs = function() end}

local Scanner = Leveling.RoomScanner
local Navigator = Leveling.Navigator
local Combat = Leveling.Combat
local definitions = Leveling.AreaRepository:get("TrollocCamp").allowed_mobs
local bloodlordDescription = "A bloodlord stands here studying the ancient books of legend"
local bloodlordLine = "(M) (difficult) " .. bloodlordDescription
local trollLine = "(M) (even match) A trolloc soldier screams and attacks"
local scoutLine = "(M) (even match) A trolloc scout screams and attacks"
local dreadlordLine = "(F) (difficult) A dreadlord stands here studying the books of knowledge"
local darkhoundLine = "(M) (even match) A darkhound is standing here"
local chiefLine = "(M) (difficult) A trolloc chieftain stands here with a wicked toothy grin"

local function assertEqual(actual, expected, message)
    assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- Observe the snapshot before the real Leveling -> Combat handoff consumes it.
local handoff = Leveling.handleRoomScanComplete
Leveling.handleRoomScanComplete = function(room)
    local copy = {}
    for index, keyword in ipairs(room) do
        copy[index] = keyword
    end
    table.insert(snapshots, copy)
    consumedRoom = room
    return handoff(room)
end

local function trigger(name, file, captures)
    assert(enabledTriggers[name], "fixture expects enabled trigger: " .. name)
    matches = captures
    dofile(root .. "/src/triggers/" .. file .. ".lua")
end

-- Mock Mudlet's capture delivery for the representative live lines; the real
-- trigger adapters, scanner, combat, session handoff, and navigator run below.
local function roomOutput(occupants)
    trigger("Start Capture Room", "Start_Capture_Room", {"[Exits: north east west]"})
    for _, line in ipairs(occupants) do
        local difficulty, description = string.match(line, "^%([^()]+%) %((.-)%) (.+)$")
        assert(description, "invalid room fixture")
        trigger("Room Capture Things", "Room_Capture_Things", {line, difficulty, description})
    end
    trigger("End Capture Room", "End_Capture_Room", {"<...> [TLSLVL] ..."})
end

local function afterKill()
    trigger("killed monster", "killed_monster", {"You receive 5 experience points.", "5"})
    local id = Scanner.lookTimerId
    local callback = timers[id]
    assert(callback, "kill schedules a look")
    timers[id] = nil
    assert((loadstring or load)(callback))()
    assertEqual(sent[#sent], "look", "scheduled callback sends look")
end

local function resetScenario()
    Combat:reset()
    Navigator:reset()
    Scanner:configure(definitions)
    Combat:configure(definitions, false)
    Navigator:setRoute({"w", "n"})
    enableTrigger("Leveling Move While Fighting")
    sent = {}
    snapshots = {}
    Scanner:expectScan()
end

local count = 0
for _, mob in ipairs(definitions) do
    if mob.name == "bloodlord" then
        count = count + 1
        assertEqual(mob.description, bloodlordDescription, "bloodlord description matches live output")
    end
end
assertEqual(count, 1, "exactly one bloodlord definition exists")
assertEqual(Combat.initAction, "kill", "default init action")

-- Pin the complete intended roster by exact description, allowing the three
-- distinct trolloc definitions to share their attack keyword.
local expectedDefinitions = {
    ["A trolloc warrior stands here with a look of blood lust in his eyes"] = "troll",
    ["A trolloc scout screams and attacks"] = "troll",
    ["A trolloc soldier screams and attacks"] = "troll",
    [bloodlordDescription] = "bloodlord",
    ["A dreadlord stands here studying the books of knowledge"] = "dreadlord",
    ["A darkhound is standing here"] = "darkhound",
    ["A trolloc chieftain stands here with a wicked toothy grin"] = "chief"
}
assertEqual(#definitions, 7, "TrollocCamp has exactly seven intended definitions")
local descriptionsSeen = {}
for _, mob in ipairs(definitions) do
    assertEqual(mob.name, expectedDefinitions[mob.description], "only intended description/keyword pairs exist")
    assertEqual(descriptionsSeen[mob.description], nil, "target definition is not duplicated")
    descriptionsSeen[mob.description] = true
end
for description in pairs(expectedDefinitions) do
    assertEqual(descriptionsSeen[description], true, "every intended target is configured")
end

-- Each new live line passes through the same capture/Combat path, including F.
for _, target in ipairs({
    {line = dreadlordLine, keyword = "dreadlord"},
    {line = darkhoundLine, keyword = "darkhound"},
    {line = chiefLine, keyword = "chief"}
}) do
    resetScenario()
    roomOutput({target.line})
    assertEqual(table.concat(snapshots[1], ","), target.keyword, "alone snapshot selects " .. target.keyword)
    assertEqual(table.concat(sent, ","), "kill " .. target.keyword, "alone target sends exactly one attack")
    assertEqual(Navigator.routeIndex, 1, "alone target does not advance route")
    assertEqual(Navigator.state, Navigator.states.ready, "alone target does not attempt movement")
end

-- The word darkhound inside a different occupant description is not a match.
for _, line in ipairs({
    "(M) (even match) A mutated rat the size of a darkhound",
    "(M) (even match) A cook stands here his eyes have seen things most men could not bare to see"
}) do
    resetScenario()
    roomOutput({line})
    assertEqual(#snapshots[1], 0, "unconfigured occupant is not a target")
    assertEqual(table.concat(sent, ","), "w", "unconfigured occupant allows movement without an attack")
end

-- Fresh rescans select the last remaining occupant without target priorities.
resetScenario()
local remaining = {scoutLine, darkhoundLine, dreadlordLine, chiefLine}
for index, keyword in ipairs({"chief", "dreadlord", "darkhound", "troll"}) do
    roomOutput(remaining)
    assertEqual(#snapshots[index], #remaining, "all remaining configured occupants stay eligible")
    assertEqual(sent[#sent], "kill " .. keyword, "mixed room preserves last-occupant order")
    assertEqual(Navigator.state, Navigator.states.ready, "mixed targets prevent movement attempts")
    table.remove(remaining)
    afterKill()
end
roomOutput({})
assertEqual(table.concat(sent, ","),
    "kill chief,look,kill dreadlord,look,kill darkhound,look,kill troll,look,w",
    "all mixed targets are attacked across fresh rescans before navigation resumes")

resetScenario()
roomOutput({bloodlordLine})
assertEqual(table.concat(snapshots[1], ","), "bloodlord", "alone snapshot contains bloodlord")
assertEqual(table.concat(sent, ","), "kill bloodlord", "alone bloodlord attacks without navigation")
assertEqual(Navigator.routeIndex, 1, "bloodlord does not advance route")

resetScenario()
roomOutput({bloodlordLine, bloodlordLine})
assertEqual(table.concat(snapshots[1], ","), "bloodlord,bloodlord", "scanner retains duplicate occupants")
assertEqual(#consumedRoom, 1, "combat consumes only one duplicate occupant")
assertEqual(table.concat(sent, ","), "kill bloodlord", "duplicate room initiates one attack")
afterKill()
roomOutput({bloodlordLine})
assertEqual(table.concat(sent, ","), "kill bloodlord,look,kill bloodlord", "remaining duplicate is attacked after rescan")

resetScenario()
roomOutput({trollLine, bloodlordLine, trollLine})
assertEqual(table.concat(snapshots[1], ","), "troll,bloodlord,troll", "mixed snapshot retains order")
assertEqual(sent[1], "kill troll", "last occupant remains first selected")
afterKill()
roomOutput({trollLine, bloodlordLine})
assertEqual(sent[#sent], "kill bloodlord", "last occupant selection applies to mixed rescan")
afterKill()
roomOutput({bloodlordLine})
assertEqual(table.concat(sent, ","), "kill troll,look,kill bloodlord,look,kill bloodlord",
    "bloodlord remaining after other mobs die stays eligible without movement")
assertEqual(Navigator.routeIndex, 1, "mixed combat preserves route index")

-- A resting mob is not a static target or a pause condition. The MUD may still
-- reject the attempted movement: rejected w -> kill -> look -> same w -> n.
resetScenario()
roomOutput({"(M) (even match) a trolloc warrior is resting on the ground."})
assertEqual(#snapshots[1], 0, "temporary resting description is not a static target")
assertEqual(Navigator.state, Navigator.states.moving, "resting mob does not pause navigation")
assertEqual(Navigator.pauseReason, nil, "resting mob creates no pause reason")
assertEqual(table.concat(sent, ","), "w", "resting mob allows the next movement attempt")
local rejectedSuccess = Scanner.onStartCallback
trigger("Leveling Move While Fighting", "Leveling_Move_While_Fighting",
    {"No way!  You are still fighting!"})
assertEqual(Navigator.routeIndex, 1, "rejected west does not advance route")
assertEqual(Navigator.retryPending, true, "rejected west remains pending for retry")
assertEqual(rejectedSuccess(), false, "rejected movement callback cannot advance route")
assertEqual(table.concat(sent, ","), "w", "rejection does not immediately resend movement")
afterKill()
roomOutput({})
assertEqual(table.concat(sent, ","), "w,look,w", "clear rescan retries the same west step")
assertEqual(Navigator.routeIndex, 1, "retry waits for confirmed movement")
local retrySuccess = Scanner.onStartCallback
roomOutput({})
assertEqual(Navigator.routeIndex, 2, "successful west retry advances exactly once")
assertEqual(retrySuccess(), false, "duplicate success callback is ignored")
assertEqual(Navigator.routeIndex, 2, "duplicate success does not advance again")
assertEqual(table.concat(sent, ","), "w,look,w,n", "next route direction remains aligned")

print("TrollocCamp roster, bloodlord live-output, negative matching, and west-step recovery checks passed")
