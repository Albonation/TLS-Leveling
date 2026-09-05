Leveling = Leveling or {}

Leveling.PROMPT_SENTINEL = "[TLSLVL]"
Leveling.DEFAULT_PROMPT = "<%h/%H hp %e/%E end> " .. Leveling.PROMPT_SENTINEL

-- Discard the old static-data field when reloading a pre-extraction package.
Leveling.areas = nil

-- Retire only this package's old maintenance API on an in-place upgrade.
-- Never touch the unrelated global BuffManager or personal profile triggers.
if Leveling.BuffManager then Leveling.BuffManager:stop() end
for _, field in ipairs({
    "BuffManager", "hasteAction", "sancAction", "detectsAction", "furyAction",
    "setHaste", "setSanc", "setDetects", "setFury", "setCoreBuffs",
    "handleHaste", "handleSanc", "handleDetects", "handleFury",
    "buffMaintenanceOutsideCombat"
}) do
    Leveling[field] = nil
end

-- Mudlet trigger names are kept in one place so lifecycle calls can be checked
-- directly against src/triggers/triggers.json.
local TRIGGERS = {
    moveWhileFighting = "Leveling Move While Fighting",
    tooMuchWeight = "Leveling Too Much Weight"
}

local RUN_TRIGGERS = {
    TRIGGERS.moveWhileFighting,
    TRIGGERS.tooMuchWeight
}

local function normalizeAction(action)
    return string.trim(tostring(action or ""))
end

function Leveling.printDebug(message)
    if Leveling.debug == true then
        cecho("\n<red>DEBUG: " .. message .. "<reset>\n")
    end
end

--- Legacy user-facing name; Combat owns the authoritative engage action.
function Leveling.setInit(action)
    return Leveling.Combat:setInit(action)
end

function Leveling.setDuringCombat(configuration)
    return Leveling.Combat:configureDuringCombat(configuration)
end

--- Compatibility wrapper for Combat's ignore configuration.
function Leveling.handleIgnoreAction(mobToIgnore)
    return Leveling.Combat:handleIgnoreAction(mobToIgnore)
end

--- Compatibility wrapper for Combat's post-kill queue.
function Leveling.addPostKillAction(action)
    return Leveling.Combat:addPostKillAction(action)
end

--- Compatibility wrapper for integrations using the previous method name.
function Leveling.doPostKillActions()
    return Leveling.Combat:runPostKillActions()
end

--- Compatibility wrapper for integrations using the previous navigation API.
function Leveling.redoLastStep()
    return Leveling.Navigator:onMovementFailure("movement blocked")
end

--- Session guard and compatibility handoff; Navigator owns route mechanics.
function Leveling.processStep()
    if not Leveling.isRunning then return false end
    return Leveling.Navigator:processStep()
end

--- Receives Navigator's one-shot completion handoff. Statistics and selecting
--- the next loop remain Leveling session responsibilities.
function Leveling.handleRouteComplete()
    cecho("\n<yellow>No steps left to process.<reset>\n")
    Leveling.stats["total"]["num_runs"] = Leveling.stats["total"]["num_runs"] + 1
    Leveling.loadArea(Leveling.currentAreaName)
end

--- Selects an area, resets route-specific state, enables leveling triggers, and
--- sends the first movement command. Configuration actions persist across runs.
--- @param areaName string Canonical AreaRepository key, or "stop" for compatibility.
function Leveling.loadArea(areaName)
    areaName = normalizeAction(areaName)
    if areaName == "stop" then
        cecho("\n<red>Leveling script STOPPED.<reset>\n")
        Leveling.stop()
        return
    end

    cecho("<red>\nAttempting to load: '" .. areaName .. "'<reset>\n")
    local area = Leveling.AreaRepository:get(areaName)
    if not area then
        cecho("\n<red>Unknown area: " .. areaName .. ".<reset>\n")
        return
    end

    if Leveling.stats["total"]["time"] == 0 then
        Leveling.stats["total"]["time"] = os.time()
    end

    local preserveCombatIgnores = Leveling.currentAreaName == areaName

    -- Current leveling session
    Leveling.isRunning = true
    Leveling.currentAreaName = areaName
    Leveling.currentArea = area

    Leveling.RoomScanner:configure(area["allowed_mobs"])
    Leveling.Combat:configure(area["allowed_mobs"], preserveCombatIgnores)
    Leveling.Navigator:setRoute(area["dirs"])

    for _, triggerName in ipairs(RUN_TRIGGERS) do
        enableTrigger(triggerName)
    end

    cecho("<purple>Area loaded. Let's do this!<reset>\n")
    Leveling.stats["this_run"]["time"] = os.time()
    Leveling.processStep()
end

--- Records one observed kill while keeping statistics owned by Leveling.
--- @param expForKill string|number Experience captured by the Mudlet trigger.
function Leveling.recordKill(expForKill)
    local experience = tonumber(expForKill) or 0

    Leveling.stats["this_run"]["mobs_killed"] = Leveling.stats["this_run"]["mobs_killed"] + 1
    Leveling.stats["this_run"]["exp"] = Leveling.stats["this_run"]["exp"] + experience
    Leveling.stats["total"]["mobs_killed"] = Leveling.stats["total"]["mobs_killed"] + 1
    Leveling.stats["total"]["exp"] = Leveling.stats["total"]["exp"] + experience
end

--- Compatibility wrapper for the pre-extraction kill handler.
function Leveling.handleKill(expForKill)
    return Leveling.Combat:onKill(expForKill)
end

--- Compatibility entry point retained for integrations using the old handler name.
function Leveling.checkRoom(expForKill)
    return Leveling.Combat:onKill(expForKill)
end

--- Receives one completed room snapshot from RoomScanner and passes it to
--- Combat. This compatibility handoff keeps RoomScanner decoupled from policy.
--- @param roomMobs table Attack keywords found during the completed capture.
function Leveling.handleRoomScanComplete(roomMobs)
    return Leveling.Combat:onRoomScanned(roomMobs)
end

-- Compatibility wrappers preserve the room handler names exposed by the first
-- refactor while keeping all state and trigger coordination inside RoomScanner.
function Leveling.beginRoomScan()
    return Leveling.RoomScanner:onStart()
end

function Leveling.addRoomMob(description)
    return Leveling.RoomScanner:onLine(description)
end

function Leveling.finishRoomScan()
    return Leveling.RoomScanner:onFinish()
end

function Leveling.disableRoomScanTriggers()
    return Leveling.RoomScanner:cancel()
end

function Leveling.cancelLookAfterKillTimer()
    return Leveling.RoomScanner:cancelLookTimer()
end

function Leveling.pauseRoomScan()
    return Leveling.RoomScanner:cancel()
end

--- Compatibility wrapper for the pre-extraction targeting entry point.
function Leveling.tryKill(roomMobs)
    return Leveling.Combat:onRoomScanned(roomMobs)
end

--- Establishes all Leveling-owned state. This is also the one-time migration
--- path from the pre-refactor state layout when an installed package is updated.
function Leveling.initialize()
    -- Configuration
    Leveling.debug = false

    -- Current leveling session
    Leveling.isRunning = false
    Leveling.currentAreaName = nil
    Leveling.currentArea = nil
    -- Clear fields owned by Leveling before RoomScanner was extracted.
    Leveling.currentAreaMobs = nil
    Leveling.currentRoomMobs = nil
    Leveling.lookAfterKillTimerId = nil
    Leveling.remainingDirections = nil
    Leveling.lastDirection = nil

    -- Statistics retained across route loops; this_run is reset by stop().
    Leveling.stats = {
        ["total"] = {
            ["mobs_killed"] = 0,
            ["exp"] = 0,
            ["time"] = 0,
            ["num_runs"] = 0
        },
        ["this_run"] = {
            ["mobs_killed"] = 0,
            ["exp"] = 0,
            ["time"] = 0
        }
    }

    Leveling.initialized = true
    Leveling.stateVersion = 3
end

--- Stops navigation and combat automation, resets RoomScanner, disables run
--- triggers, prints the completed session, and resets run statistics.
function Leveling.stop()
    Leveling.Combat:reset()
    Leveling.Navigator:reset()
    Leveling.RoomScanner:reset()

    Leveling.isRunning = false
    Leveling.currentAreaName = nil
    Leveling.currentArea = nil
    for _, triggerName in ipairs(RUN_TRIGGERS) do
        disableTrigger(triggerName)
    end

    Leveling.printRunStats()
    Leveling.resetRunStats()
    echo("\nLeveling STOPPED\n")
end

function Leveling.resetRunStats()
    Leveling.stats["this_run"] = {
        ["mobs_killed"] = 0,
        ["exp"] = 0,
        ["time"] = 0
    }
end

--- Generic immediate-action compatibility helper. Timing is explicit: use
--- addPostKillAction for on-kill work, regardless of the command's first letter.
function Leveling.handleAction(action)
    action = normalizeAction(action)
    if action == "" then return end
    local actions = string.split(action, "%s*;%s*")
    sendAll(unpack(actions))
end

local function safeAverage(total, count)
    if count == 0 then
        return 0
    end
    return total / count
end

local function safePerMinute(total, startedAt, currentTime)
    if startedAt == 0 then
        return 0
    end

    local elapsedMinutes = math.floor((currentTime - startedAt) / 60)
    return total / math.max(elapsedMinutes, 1)
end

local function formatNumber(value)
    local formatted = tostring(math.floor(value))
    formatted = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    return formatted
end

function Leveling.printRunStats()
    local currentTime = os.time()
    local thisRun = Leveling.stats["this_run"]
    local total = Leveling.stats["total"]
    local runAverage = safeAverage(thisRun["exp"], thisRun["mobs_killed"])
    local totalAverage = safeAverage(total["exp"], total["mobs_killed"])
    local runExpPerMinute = safePerMinute(thisRun["exp"], thisRun["time"], currentTime)
    local totalExpPerMinute = safePerMinute(total["exp"], total["time"], currentTime)

    cecho("\n<yellow>              Leveling Stats<reset>\n\n")
    cecho("                Current Run | All Runs (" .. total["num_runs"] .. ")\n")
    cecho(string.format(" Mobs Killed:   <red>%12s<reset>| <red>%12s<reset>\n", thisRun["mobs_killed"], total["mobs_killed"]))
    cecho(string.format(" Total Exp:     <yellow>%12s<reset>| <yellow>%12s<reset>\n", formatNumber(thisRun["exp"]), formatNumber(total["exp"])))
    cecho(" -----------------------------------------\n")
    cecho(string.format(" Avg Per Kill:  <yellow>%12s<reset>| <yellow>%12s<reset>\n", formatNumber(runAverage), formatNumber(totalAverage)))
    cecho(string.format(" Exp Per Hour:  <yellow>%12s<reset>| <yellow>%12s<reset>\n\n", formatNumber(runExpPerMinute * 60), formatNumber(totalExpPerMinute * 60)))
end

--- Configures the documented TLS-Leveling prompt only when explicitly invoked.
--- The sentinel is a protocol marker; all other prompt formatting is user-owned.
function Leveling.configurePrompt()
    send("prompt " .. Leveling.DEFAULT_PROMPT)
    cecho("\n<green>TLS-Leveling prompt configured.<reset>\n")
    echo("The " .. Leveling.PROMPT_SENTINEL .. " marker is used to detect the end of room output.\n")
    echo("You may customize the rest of your prompt as long as " .. Leveling.PROMPT_SENTINEL .. " remains present.\n")
end

function Leveling.printHelp()
    cecho("\n         <red>Leveling Script<reset>\n\n")
    cecho(" <yellow>Usage:<reset>\n")
    cecho("   Start area:             'leveling start [area name]'\n")
    cecho("   Stop script:            'leveling stop'\n")
    cecho("   Stats:                  'leveling stats'\n")
    cecho("   Set recommended prompt: 'leveling setprompt'\n")
    cecho("   TLS-Leveling requires [TLSLVL] somewhere in your MUD prompt.\n")
    cecho("   You may customize the rest of the prompt freely.\n")
    cecho("  --------------------------------------------------------------------------\n")
    cecho("   Engage combat action:   'leveling engage [action]' ('init' also supported)\n")
    cecho("   Engage sequences use ; and append the target to each command.\n")
    cecho("   During combat:          'leveling duringcombat <rounds> <action>'\n")
    cecho("   Disable round action:   'leveling duringcombat off'\n")
    cecho("   Rounds must be a positive integer; optional {target} requires a known target.\n")
    cecho("   Add on-kill action:     'leveling pka [action]' (not after combat)\n")
    cecho("   List areas:             'leveling areas'\n\n")
end

function Leveling.printStatus()
    cecho("\n<red>      Current Leveling Status<reset>\n\n")
    cecho(" Engage combat action:        '" .. Leveling.Combat.engageCombatAction .. "'\n")
    cecho(" During-combat action:        '" .. Leveling.Combat.duringCombatAction .. "'\n")
    cecho(" During-combat round interval: " .. Leveling.Combat.duringCombatActionRoundInterval .. "\n")
end

function Leveling.printAreas()
    cecho("\n<red>        Leveling Areas:<reset>\n\n")

    for areaName, area in pairs(Leveling.AreaRepository:list()) do
        cecho("  * <yellow>" .. areaName .. "<reset>\n")
        cecho("      " .. area["description"] .. "\n")
    end
    cecho("\n")
end

if not Leveling.initialized or Leveling.stateVersion ~= 3 then
    Leveling.initialize()
end
