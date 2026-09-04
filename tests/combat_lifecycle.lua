local root = arg[1] or "."

local sent = {}
local enabledTriggers = {}
local recordedKills = {}
local processStepCalls = 0
local lookRequests = 0
local navigatorPauses = 0
local navigatorResets = 0
local scannerResets = 0
local stopCalls = 0
local lookPending = false

unpack = unpack or table.unpack

function enableTrigger(name)
    enabledTriggers[name] = true
end

function disableTrigger(name)
    enabledTriggers[name] = false
end

function sendAll(...)
    for index = 1, select("#", ...) do
        table.insert(sent, (select(index, ...)))
    end
end

function cecho()
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
    initAction = "bash;kill",
    ignoredMobNames = {"rat"},
    postKillActions = {"stand"},
    printDebug = function()
    end,
    processStep = function()
        processStepCalls = processStepCalls + 1
    end,
    recordKill = function(experience)
        table.insert(recordedKills, tonumber(experience) or 0)
    end,
    RoomScanner = {
        requestLook = function(_, delay)
            if delay ~= 3 then
                error("post-kill look delay changed")
            end
            lookRequests = lookRequests + 1
            lookPending = true
        end,
        reset = function()
            scannerResets = scannerResets + 1
            lookPending = false
        end
    },
    Navigator = {
        pause = function(_, reason)
            if reason ~= "combat" then
                error("unexpected navigation pause reason")
            end
            navigatorPauses = navigatorPauses + 1
            return true
        end,
        reset = function()
            navigatorResets = navigatorResets + 1
        end
    }
}

dofile(root .. "/src/scripts/Combat.lua")

local Combat = Leveling.Combat

function Leveling.stop()
    stopCalls = stopCalls + 1
    Combat:reset()
    Leveling.Navigator:reset()
    Leveling.RoomScanner:reset()
end

local mobDefinitions = {
    {
        name = "troll",
        description = "A trolloc soldier screams and attacks"
    },
    {
        name = "troll",
        description = "A trolloc scout screams and attacks"
    },
    {
        name = "troll",
        description = "A trolloc warrior stands here with a look of blood lust in his eyes"
    }
}

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function resetScenario()
    sent = {}
    recordedKills = {}
    processStepCalls = 0
    lookRequests = 0
    navigatorPauses = 0
    navigatorResets = 0
    scannerResets = 0
    stopCalls = 0
    lookPending = false
    Combat:reset()
    Combat:setInit("kill")
    Combat:configure(mobDefinitions, false)
end

-- Existing user configuration/state migrates once and loses its old owner.
assertEqual(Combat.initAction, "bash;kill", "legacy init action migrates")
assertEqual(Combat.ignoredMobNames[1], "rat", "legacy ignore migrates")
assertEqual(Combat.postKillActions[1], "stand", "legacy post-kill action migrates")
assertEqual(Leveling.initAction, nil, "legacy init owner is cleared")
assertEqual(Leveling.ignoredMobNames, nil, "legacy ignore owner is cleared")
assertEqual(Leveling.postKillActions, nil, "legacy queue owner is cleared")

-- A. Empty room resumes navigation exactly once.
resetScenario()
for _, triggerName in pairs(Combat.triggerNames) do
    assertEqual(enabledTriggers[triggerName], true, triggerName .. " enabled for a configured session")
end
assertEqual(Combat:onRoomScanned({}), false, "empty room has no attack")
assertEqual(processStepCalls, 1, "empty room advances once")
assertEqual(Combat.state, Combat.states.idle, "empty room leaves combat idle")

-- B. One target initiates combat without moving.
resetScenario()
assertEqual(Combat:onRoomScanned({"troll"}), true, "one target attacks")
assertEqual(sent[1], "kill troll", "default init command targets occupant")
assertEqual(#sent, 1, "one target sends one attack")
assertEqual(processStepCalls, 0, "attack does not navigate")
assertEqual(Combat.state, Combat.states.engaged, "attack marks combat engaged")

-- C. Duplicate live occupants are preserved; each fresh scan selects only one.
resetScenario()
local liveRoom = {"troll", "troll", "troll", "troll"}
Combat:onRoomScanned(liveRoom)
assertEqual(#liveRoom, 3, "one occupant is consumed, not deduplicated")
assertEqual(#sent, 1, "first live snapshot initiates once")
Combat:onKill(5)
Combat:onRoomScanned({"troll", "troll", "troll"})
assertEqual(#sent, 2, "fresh post-kill scan initiates the next target once")

-- D/E. One initiated fight may produce multiple kills and a still-fighting look.
-- Representative TLS events include "You receive 5 experience points." and
-- "(M) (even match) a trolloc warrior is here, fighting YOU!".
resetScenario()
Combat:onRoomScanned({"troll", "troll", "troll", "troll"})
Combat:onKill("5")
assertEqual(#recordedKills, 1, "first experience event is recorded once")
assertEqual(lookRequests, 1, "first kill schedules a look")
assertEqual(#sent, 1, "kill event does not initiate another attack")
assertEqual(Combat.state, Combat.states.engaged, "kill does not assume combat ended")
Combat:onStillFighting()
assertEqual(navigatorPauses, 1, "active opponent pauses navigation")
assertEqual(processStepCalls, 0, "still fighting does not navigate")
Combat:onKill("7")
assertEqual(#recordedKills, 2, "second experience event is recorded once")
assertEqual(recordedKills[1] + recordedKills[2], 12, "experience values are preserved")
assertEqual(lookRequests, 2, "each kill requests the existing rescan")
assertEqual(#sent, 1, "auto-aggro kills do not duplicate attack initiation")

-- Post-kill actions retain insertion order and run on the next kill event.
resetScenario()
Combat:addPostKillAction("stand")
Combat:addPostKillAction("get coins;wear cloak")
Combat:onKill(5)
assertEqual(sent[1], "stand", "first queued action runs first")
assertEqual(sent[2], "get coins", "second queued sequence begins in order")
assertEqual(sent[3], "wear cloak", "second queued sequence completes")
assertEqual(#Combat.postKillActions, 0, "post-kill queue is consumed")

-- Init command sequences continue appending the same target to each command.
resetScenario()
Combat:setInit("bash;kill")
Combat:onRoomScanned({"troll"})
assertEqual(sent[1], "bash troll", "first init command receives target")
assertEqual(sent[2], "kill troll", "second init command receives target")

-- F. Ignore filtering skips every duplicate keyword and obeys area boundaries.
resetScenario()
Combat:handleIgnoreAction("soldier")
assertEqual(Combat.ignoredMobNames[1], "troll", "description toggles attack keyword")
Combat:onRoomScanned({"troll", "troll", "troll", "troll"})
assertEqual(#sent, 0, "ignored duplicate occupants are all skipped")
assertEqual(processStepCalls, 1, "all ignored targets resume navigation once")
Combat:configure(mobDefinitions, true)
assertEqual(Combat.ignoredMobNames[1], "troll", "same-area loop preserves ignores")
Combat:configure(mobDefinitions, false)
assertEqual(#Combat.ignoredMobNames, 0, "area switch clears ignores")

-- G/H. Kill stealing and missing targets abandon stale state exactly once.
resetScenario()
Combat:onRoomScanned({"troll"})
assertEqual(Combat:onTargetUnavailable(), true, "target failure is handled")
assertEqual(processStepCalls, 1, "target failure recovers once")
assertEqual(Combat.pendingTarget, nil, "stale target is cleared")
assertEqual(Combat:onTargetUnavailable(), false, "duplicate stale failure is ignored")
assertEqual(processStepCalls, 1, "duplicate failure cannot advance twice")

-- I. Flee interpretation retains the existing full-session stop behavior.
resetScenario()
Combat:onRoomScanned({"troll"})
Combat:onFlee()
assertEqual(stopCalls, 1, "flee stops the session")
assertEqual(Combat.state, Combat.states.idle, "flee resets combat")

-- J. Stop during combat clears all subsystem and deferred state.
resetScenario()
Combat:handleIgnoreAction("troll")
Combat:addPostKillAction("stand")
Combat:setInit("bash;kill")
Combat:attack("troll")
lookPending = true
Leveling.stop()
assertEqual(Combat.state, Combat.states.idle, "stop leaves combat idle")
assertEqual(Combat.pendingTarget, nil, "stop clears pending target")
assertEqual(#Combat.ignoredMobNames, 0, "stop clears ignores")
assertEqual(#Combat.postKillActions, 0, "stop clears deferred actions")
assertEqual(#Combat.mobDefinitions, 0, "stop clears area combat definitions")
assertEqual(Combat.initAction, "bash;kill", "stop preserves init configuration")
assertEqual(navigatorResets, 1, "stop resets Navigator")
assertEqual(scannerResets, 1, "stop resets RoomScanner")
assertEqual(lookPending, false, "stop cancels pending look through RoomScanner")
for _, triggerName in pairs(Combat.triggerNames) do
    assertEqual(enabledTriggers[triggerName], false, triggerName .. " disabled after stop")
end

print("Combat lifecycle checks passed")
