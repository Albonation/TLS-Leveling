local root = arg[1] or "."

local sent = {}
local enabledTriggers = {}
local completionCount = 0
local roomCompletionCount = 0

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
        completionCount = completionCount + 1
    end,
    handleRoomScanComplete = function()
        roomCompletionCount = roomCompletionCount + 1
    end
}

dofile(root .. "/src/scripts/TLS-Leveling/RoomScanner.lua")
dofile(root .. "/src/scripts/TLS-Leveling/Navigator.lua")

local Navigator = Leveling.Navigator
local RoomScanner = Leveling.RoomScanner

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function resetHarness()
    sent = {}
    enabledTriggers = {}
    completionCount = 0
    roomCompletionCount = 0
    RoomScanner:reset()
    Navigator:reset()
end

-- Normal movement: one command, one accepted success, then room capture.
resetHarness()
Navigator:setRoute({"north", "east"})
assertEqual(Navigator:processStep(), true, "normal movement starts")
assertEqual(Navigator:processStep(), false, "duplicate movement is rejected")
assertEqual(sent[1], "north", "first route step is sent")
assertEqual(#sent, 1, "only one movement command is sent")
assertEqual(Navigator.routeIndex, 1, "index waits for movement success")
assertEqual(RoomScanner:onStart(), true, "movement room starts capture")
assertEqual(Navigator.routeIndex, 2, "success advances once")
assertEqual(Navigator.state, Navigator.states.ready, "navigator is ready after success")
assertEqual(RoomScanner.state, RoomScanner.states.capturing, "room capture starts")

-- Deferred retry: failure retains the logical step and invalidates old success.
resetHarness()
Navigator:setRoute({"east"})
Navigator:processStep()
local staleRetryCallback = RoomScanner.onStartCallback
assertEqual(Navigator:onMovementFailure("blocked"), true, "failure is accepted")
assertEqual(Navigator.routeIndex, 1, "failed step is retained")
assertEqual(Navigator.retryPending, true, "retry is pending")
assertEqual(Navigator.state, Navigator.states.paused, "failure pauses navigation")
assertEqual(staleRetryCallback(), false, "old movement callback is stale")
assertEqual(Navigator.routeIndex, 1, "stale callback cannot advance")
assertEqual(Navigator:processStep(), true, "next progression signal retries")
assertEqual(sent[2], "east", "same logical movement is retried")
assertEqual(RoomScanner:onStart(), true, "retried movement succeeds")
assertEqual(Navigator.routeIndex, 2, "retry advances once")

-- Stop/reset during movement clears route state and invalidates its callback.
resetHarness()
Navigator:setRoute({"south"})
Navigator:processStep()
local stoppedCallback = RoomScanner.onStartCallback
Navigator:reset()
assertEqual(Navigator.state, Navigator.states.idle, "reset leaves navigator idle")
assertEqual(#Navigator.route, 0, "reset clears route")
assertEqual(RoomScanner.state, RoomScanner.states.idle, "reset cancels scan")
assertEqual(stoppedCallback(), false, "stopped callback cannot advance")
assertEqual(Navigator.routeIndex, 1, "stopped route index remains reset")

-- Replacing a route also invalidates the old movement and starts at index one.
resetHarness()
Navigator:setRoute({"old"})
Navigator:processStep()
local replacedCallback = RoomScanner.onStartCallback
Navigator:setRoute({"new"})
assertEqual(replacedCallback(), false, "replaced-route callback cannot advance")
assertEqual(Navigator.routeIndex, 1, "replacement route starts at index one")
Navigator:processStep()
assertEqual(sent[2], "new", "replacement sends only its own first step")

-- Route completion is emitted once and the Leveling handoff may start its loop.
resetHarness()
Leveling.handleRouteComplete = function()
    completionCount = completionCount + 1
    Navigator:setRoute({"south"})
end
Navigator:setRoute({"south"})
Navigator:processStep()
RoomScanner:onStart()
assertEqual(Navigator:processStep(), true, "route completion is handled")
assertEqual(completionCount, 1, "completion callback runs once")
assertEqual(Navigator.state, Navigator.states.ready, "completion handoff restarts route")
assertEqual(Navigator.routeIndex, 1, "restarted route begins at its first step")
assertEqual(Navigator:processStep(), true, "restarted route can move")
assertEqual(completionCount, 1, "completion remains one-shot")

-- Combat after a confirmed move pauses without sending another route step.
resetHarness()
Navigator:setRoute({"west", "north"})
Navigator:processStep()
RoomScanner:onStart()
Navigator:pause("combat")
assertEqual(Navigator.state, Navigator.states.paused, "combat pauses navigation")
assertEqual(Navigator.routeIndex, 2, "confirmed combat room stays advanced")
assertEqual(#sent, 1, "combat pause does not move unexpectedly")
assertEqual(RoomScanner.state, RoomScanner.states.idle, "combat cancels room capture")

-- A group pause before resolution retries the same step only when resumed.
resetHarness()
Navigator:setRoute({"up"})
Navigator:processStep()
Navigator:pause("groupmate not ready")
assertEqual(Navigator.routeIndex, 1, "group pause retains unresolved step")
assertEqual(Navigator.retryPending, true, "group pause marks a retry")
assertEqual(#sent, 1, "group pause sends nothing")
Navigator:processStep()
assertEqual(sent[2], "up", "explicit resume retries the group-paused step")
RoomScanner:onStart()
assertEqual(Navigator.routeIndex, 2, "group-paused retry advances normally")

print("Navigator lifecycle checks passed")
