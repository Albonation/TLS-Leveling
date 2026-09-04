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
dofile(root .. "/src/scripts/RoomScanner.lua")
dofile(root .. "/src/scripts/Navigator.lua")
dofile(root .. "/src/scripts/Combat.lua")
BuffManager = {processBuffs = function() end}

local Scanner = Leveling.RoomScanner
local Navigator = Leveling.Navigator
local Combat = Leveling.Combat
local definitions = Leveling.areas.TrollocCamp.allowed_mobs
local bloodlordDescription = "A bloodlord stands here studying the ancient books of legend"
local bloodlordLine = "(M) (difficult) " .. bloodlordDescription
local trollLine = "(M) (even match) A trolloc soldier screams and attacks"

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
        local difficulty, description = string.match(line, "^%(M%) %((.-)%) (.+)$")
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

-- Verified live recovery: rejected w -> kill -> look/clear room -> same w -> n.
resetScenario()
Leveling.processStep()
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

print("Bloodlord live-output and west-step recovery checks passed")
