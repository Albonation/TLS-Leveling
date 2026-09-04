Leveling = Leveling or {}

Leveling.PROMPT_SENTINEL = "[TLSLVL]"
Leveling.DEFAULT_PROMPT = "<%h/%H hp %e/%E end> " .. Leveling.PROMPT_SENTINEL

-- Discard the old static-data field when reloading a pre-extraction package.
Leveling.areas = nil

-- Mudlet trigger names are kept in one place so lifecycle calls can be checked
-- directly against src/triggers/triggers.json.
local TRIGGERS = {
    fury = "Leveling Fury",
    haste = "Leveling Haste",
    detects = "Leveling Detects",
    sanc = "Leveling Sanc",
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

function Leveling.setHaste(action)
    Leveling.hasteAction = normalizeAction(action)

    if Leveling.hasteAction == "" then
        cecho("\nHaste action disabled.\n")
        disableTrigger(TRIGGERS.haste)
    else
        cecho("\nHaste action set to: " .. Leveling.hasteAction .. "\n")
        enableTrigger(TRIGGERS.haste)
    end
end

function Leveling.setFury(action)
    Leveling.furyAction = normalizeAction(action)

    if Leveling.furyAction == "" then
        cecho("\nFury disabled\n")
        disableTrigger(TRIGGERS.fury)
    else
        cecho("\nFury enabled\n")
        enableTrigger(TRIGGERS.fury)
    end
end

function Leveling.setDetects(action)
    Leveling.detectsAction = normalizeAction(action)

    if Leveling.detectsAction == "" then
        cecho("\nDetects disabled.\n")
        disableTrigger(TRIGGERS.detects)
    else
        cecho("\nDetects action set to: " .. Leveling.detectsAction .. "\n")
        enableTrigger(TRIGGERS.detects)
    end
end

function Leveling.setSanc(action)
    Leveling.sancAction = normalizeAction(action)

    if Leveling.sancAction == "" then
        cecho("\nSanc action disabled.\n")
        disableTrigger(TRIGGERS.sanc)
    else
        cecho("\nSanc action set to: " .. Leveling.sancAction .. "\n")
        enableTrigger(TRIGGERS.sanc)
    end
end

function Leveling.setInit(action)
    return Leveling.Combat:setInit(action)
end

function Leveling.handleHaste()
    Leveling.handleAction(Leveling.hasteAction)
end

function Leveling.handleFury()
    send("fury")
end

function Leveling.handleDetects()
    Leveling.handleAction(Leveling.detectsAction)
end

function Leveling.handleSanc()
    Leveling.handleAction(Leveling.sancAction)
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

--- Applies buffs before delegating all route mechanics to Navigator.
--- This wrapper remains because combat and existing integrations advance here.
function Leveling.processStep()
    BuffManager.processBuffs()
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

    -- Reapply configurable trigger state after stop() disabled it.
    Leveling.setFury(Leveling.furyAction)
    Leveling.setHaste(Leveling.hasteAction)
    Leveling.setSanc(Leveling.sancAction)
    Leveling.setDetects(Leveling.detectsAction)

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
    Leveling.hasteAction = ""
    Leveling.furyAction = ""
    Leveling.sancAction = ""
    Leveling.detectsAction = ""

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
    disableTrigger(TRIGGERS.haste)
    disableTrigger(TRIGGERS.fury)
    disableTrigger(TRIGGERS.detects)
    disableTrigger(TRIGGERS.sanc)

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

--- Runs an action immediately, except cast commands (those beginning with "c"),
--- which are deferred until the next observed kill event.
function Leveling.handleAction(action)
    action = normalizeAction(action)
    Leveling.printDebug("handleAction: " .. action)
    if action == "" then
        return
    end

    if string.starts(action, "c") then
        Leveling.printDebug("adding post kill action: " .. action)
        Leveling.Combat:queuePostKillAction(action)
    else
        local actions = string.split(action, "%s*;%s*")
        sendAll(unpack(actions))
    end
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
    cecho("   Set <yellow>haste<reset> action:       'leveling haste [quaff off|c haste]'\n")
    cecho("   Set <white>sanc<reset> action:        'leveling sanc [quaff sanc|c sanc]'\n")
    cecho("   Set <purple>detects<reset> action:     'leveling detects [quaff glit|c 'detect h']\n")
    cecho("   Add post kill action:   'leveling pka [action]'\n")
    cecho("   Set init action:        'leveling init [action]' - NOTE use | to separate commands, like dismis|call|order all kill\n")
    cecho("   List areas:             'leveling areas'\n\n")
end

function Leveling.printStatus()
    cecho("\n<red>      Current Leveling Status<reset>\n\n")
    cecho(" Haste action:   '" .. Leveling.hasteAction .. "'\n")
    cecho(" Sanc action:    '" .. Leveling.sancAction .. "'\n")
    cecho(" Detects action: '" .. Leveling.detectsAction .. "'\n")
    cecho(" Init action:    '" .. Leveling.Combat.initAction .. "'\n\n")
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
