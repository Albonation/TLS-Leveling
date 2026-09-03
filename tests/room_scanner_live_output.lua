local root = arg[1] or "."

local enabledTriggers = {}
local sent = {}
local completedRooms = {}

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
        table.insert(sent, (select(index, ...)))
    end
end

function killTimer()
end

function tempTimer()
    return 1
end

string.trim = function(value)
    return string.match(value, "^%s*(.-)%s*$")
end

string.split = function(value, separator)
    local parts = {}
    local startIndex = 1
    local separatorStart, separatorEnd = string.find(value, separator, startIndex)
    while separatorStart do
        table.insert(parts, string.sub(value, startIndex, separatorStart - 1))
        startIndex = separatorEnd + 1
        separatorStart, separatorEnd = string.find(value, separator, startIndex)
    end
    table.insert(parts, string.sub(value, startIndex))
    return parts
end

Leveling = {
    printDebug = function()
    end,
    handleRouteComplete = function()
    end,
    handleRoomScanComplete = function(roomMobs)
        table.insert(completedRooms, roomMobs)
    end
}

dofile(root .. "/src/scripts/RoomScanner.lua")
dofile(root .. "/src/scripts/Navigator.lua")

local Navigator = Leveling.Navigator
local RoomScanner = Leveling.RoomScanner
local sentinel = "[TLSLVL]"

local mobDefinitions = {
    {
        name = "troll",
        description = "A trolloc warrior stands here with a look of blood lust in his eyes"
    },
    {
        name = "troll",
        description = "A trolloc scout screams and attacks"
    },
    {
        name = "troll",
        description = "A trolloc soldier screams and attacks"
    }
}

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function dispatchPromptLine(line)
    if string.find(line, sentinel, 1, true) then
        return RoomScanner:onFinish()
    end
    return false
end

local function beginCapture()
    RoomScanner:configure(mobDefinitions)
    Navigator:setRoute({"north"})
    assertEqual(Navigator:processStep(), true, "movement starts")
    assertEqual(RoomScanner.state, RoomScanner.states.waitingForStart, "scanner waits for exits")
    assertEqual(enabledTriggers["Start Capture Room"], true, "start trigger is enabled while waiting")
    assertEqual(enabledTriggers["Room Capture Things"], false, "line trigger stays disabled while waiting")
    assertEqual(enabledTriggers["End Capture Room"], false, "finish trigger stays disabled while waiting")
    assertEqual(RoomScanner:onStart(), true, "live exits line begins capture")
    assertEqual(Navigator.routeIndex, 2, "movement success advances exactly once")
    assertEqual(RoomScanner.state, RoomScanner.states.capturing, "scanner captures after exits")
end

-- Package/runtime initialization leaves all transient scan triggers inactive.
assertEqual(enabledTriggers["Start Capture Room"], false, "start trigger initially inactive")
assertEqual(enabledTriggers["Room Capture Things"], false, "line trigger initially inactive")
assertEqual(enabledTriggers["End Capture Room"], false, "finish trigger initially inactive")

-- Actual observed TLS cavern output: one warrior, one scout, and two soldiers.
beginCapture()
RoomScanner:onLine("A trolloc warrior stands here with a look of blood lust in his eyes")
RoomScanner:onLine("A trolloc scout screams and attacks")
RoomScanner:onLine("A trolloc soldier screams and attacks")
RoomScanner:onLine("A trolloc soldier screams and attacks")

assertEqual(dispatchPromptLine("<34402/34402 hp 66877/66877 end> (O)(s)(h)(ck)(fv)"), false,
    "prompt-like text without sentinel does not finish")
assertEqual(RoomScanner.state, RoomScanner.states.capturing, "missing sentinel leaves capture active")
assertEqual(dispatchPromptLine("<34402/34402 hp 66877/66877 end> [TLSLVL]"), true,
    "default sentinel prompt finishes")
assertEqual(RoomScanner.state, RoomScanner.states.idle, "finished scanner returns idle")
assertEqual(#completedRooms, 1, "one room snapshot is handed off")
assertEqual(#completedRooms[1], 4, "all four live occupants are retained")
for index, mobName in ipairs(completedRooms[1]) do
    assertEqual(mobName, "troll", "captured occupant " .. index .. " uses attack keyword")
end
assertEqual(enabledTriggers["Start Capture Room"], false, "start trigger disabled after finish")
assertEqual(enabledTriggers["Room Capture Things"], false, "line trigger disabled after finish")
assertEqual(enabledTriggers["End Capture Room"], false, "finish trigger disabled after finish")

-- Sentinel matching is independent of every other visual prompt choice.
beginCapture()
assertEqual(dispatchPromptLine("HP 34402/34402 | END 66877/66877 | [TLSLVL] | whatever else"), true,
    "custom sentinel prompt finishes")
assertEqual(RoomScanner.state, RoomScanner.states.idle, "custom prompt returns scanner idle")

print("RoomScanner live-output checks passed")
