Leveling = Leveling or {}

Leveling.areas = {
    ["KoreSprings"] = {
        ["dirs"] = {
            "n","n","n","n","n","n","n","n","n","n","n",
            "n","n","n","s","s","s","e","e","e","e","e",
            "e","e","n","s","s","e","n","n","n","n","e",
            "e","e","e","s","e","s","s","s","s","w","s",
            "w","w","w","w","n","n","n","e","n","s","s",
            "e","n","n","s","e","e","n","s","w","w","w",
            "w","w","w","w","w","w","w","w","w","s","s",
            "s","s","s","s","s","s","s","s","s"
        },
        ["allowed_mobs"] =
        {
            {
                name = "retainer",
                description = "One of the lord's retainers is here keeping an eye on the lord's lands.",
            },
            {
                name = "joni",
                description = "Joni Shagrin, once Senior Bannerman of the Guards, is here with a blood stained bandage around his temple.",
            },
            {
                name = "soldier",
                description = "A grey haired experienced soldier stands here next to a saddled horse holding a long, steel-tipped lance.",
            },
            {
                name = "squadman",
                description = "A former squadman straightens his sword belt.",
            },
            {
                name = "lord",
                description = "A bluff faced, stocky man with thick gray hair sits at a writing table.",
            },
            {
                name = "horse",
                description = "A saddled horse looks prepared for a campaign.",
            }
        },
        ["description"] = "From just south of the entrance to Kore Springs",
    },
    ["TrollocCamp"] = {
        ["dirs"] = {
            "w","n","s","s","n","w","n","s","s","n","w",
            "n","s","s","n","w","n","s","w","n","s","s",
            "n","w","s","n","n","n","n","e","s","n","e",
            "s","n","e","s","n","e","s","n","e","s","n",
            "w","w","w","w","w","s","s","s","e","n","s",
            "e","s","s","e","w","s","e","w","w","n","s",
            "w","n","s","s","s","s","n","e","n","s","e",
            "n","s","e","w","s","e","w","w","e","s","w",
            "e","s","s","n","e","n","s","s","n","e","n",
            "s","s","n","e","s","s","s","w","n","s","w",
            "n","s","w","n","s","w","n","s","w","n","n",
            "e","w","s","s","e","e","e","e","e","n","n",
            "n","n","n","w","e","n","w","e","n","w","e",
            "n","w","e","n","w"
        },
        ["allowed_mobs"] =
        {
            {
                name = "troll",
                description = "A trolloc scout screams and attacks",
            },
            {
                name = "troll",
                description = "A trolloc warrior stands here with a look of blood lust in his eyes",
            },
            {
                name = "troll",
                description = "A trolloc solider screams and attacks",
            },
            {
                name = "troll",
                description = "A trolloc warrior stands here with a look of blood lust in his eyes",
            }
        },
        ["description"] = "Start 1 east of the trolloc camp, in the blight.",
    },
    ["Drones"] = {
        ["dirs"] = {
            "down", "east", "east", "east", "north", "north", "north", "north",
            "west", "north", "east", "east", "south", "west", "south", "south",
            "south", "south", "west", "west", "west", "south", "south", "south",
            "east", "east", "east", "east", "south", "south", "east", "east", "east",
            "south", "south", "east", "north", "west", "north", "west", "west", "west",
            "south", "south", "south", "west", "west", "west", "west", "south", "north",
            "north", "north", "west", "south", "south", "south", "west", "north", "north",
            "north", "west", "south", "south", "south", "west", "north", "north", "north",
            "south", "east", "north", "north", "north", "north", "west", "west", "west",
            "west", "west", "west", "west", "west", "north", "north", "north", "west",
            "north", "south", "east", "east", "north", "south", "west", "south", "south", "south", "east",
            "east", "south", "south", "south", "south", "south", "south", "south", "south",
            "west", "west", "west", "west", "west", "north", "north", "north", "north",
            "north", "south", "south", "south", "south", "south", "south", "south", "south",
            "south", "south", "west", "north", "north", "north", "north", "north", "north",
            "north", "north", "north", "north", "west",  "south", "south", "south", "south",
            "south", "south", "south", "south", "south", "south", "east", "east", "north",
            "north", "north", "north", "north", "east", "east", "east", "east", "east",
            "north", "north", "north", "north", "north", "north", "north", "north", "east",
            "east", "east", "east", "east", "east", "east", "east", "east", "north", "north",
            "north", "up"
        },
        ["allowed_mobs"] = {
            {
                name = "drone",
                description = "a face-hugger parasite is here, fighting YOU!",
            },
            {
                name = "drone",
                description = "This alien drone hasn't yet reached full adulthood",
            },
            {
                name = "alien",
                description = "Long, spindly legs are slowly emerging from this open egg!",
            },
            {
                name = "drone",
                description = "An alien drone moves subtly along the darkended walls",
            },
            {
                name = "drone",
                description = "A vicious alien drone spaps its double-jaws",
            },
            {
                name = "drone",
                description = "An abnormally large alien drone looms over you",
            },
            {
                name = "drone",
                description = "An alien drone races across the ceiling.",
            },
            {
                name = "marine",
                description = "This marine opens fire on anything that moves!",
            }
        },
        ["description"] = "Start at the hole in the wall, where you go just 1 down for drones.",
    }
}

-- Mudlet trigger names are kept in one place so lifecycle calls can be checked
-- directly against src/triggers/TLS-Leveling/triggers.json.
local TRIGGERS = {
    killedMonster = "killed monster",
    flee = "Leveling Flee",
    fury = "Leveling Fury",
    haste = "Leveling Haste",
    killStealing = "Leveling Kill Stealing",
    detects = "Leveling Detects",
    sanc = "Leveling Sanc",
    moveWhileFighting = "Leveling Move While Fighting",
    tooMuchWeight = "Leveling Too Much Weight"
}

local RUN_TRIGGERS = {
    TRIGGERS.killedMonster,
    TRIGGERS.flee,
    TRIGGERS.killStealing,
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
    Leveling.initAction = normalizeAction(action)

    if Leveling.initAction == "" then
        Leveling.initAction = "kill"
    else
        cecho("\nInit action set to " .. Leveling.initAction)
    end
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

--- Toggles every current-area mob whose name exactly matches the query or whose
--- description contains it. The ignore list stores attack keywords, not area data.
--- @param mobToIgnore string User-supplied mob name or description fragment.
function Leveling.handleIgnoreAction(mobToIgnore)
    local query = string.lower(normalizeAction(mobToIgnore))
    if query == "" then
        return
    end

    local matchingNames = {}
    local namesSeen = {}
    local areaMobs = Leveling.currentArea and Leveling.currentArea["allowed_mobs"] or {}
    for _, mob in ipairs(areaMobs) do
        local mobName = string.lower(tostring(mob.name or ""))
        local description = string.lower(tostring(mob.description or ""))
        if (mobName == query or string.find(description, query, 1, true)) and not namesSeen[mobName] then
            table.insert(matchingNames, mobName)
            namesSeen[mobName] = true
        end
    end

    for _, mobName in ipairs(matchingNames) do
        local removed = false
        for index = #Leveling.ignoredMobNames, 1, -1 do
            if Leveling.ignoredMobNames[index] == mobName then
                table.remove(Leveling.ignoredMobNames, index)
                removed = true
            end
        end

        if removed then
            cecho("\nRemoved from ignore list: " .. mobName .. "\n")
        else
            table.insert(Leveling.ignoredMobNames, mobName)
            cecho("\nAdded to ignore list: " .. mobName .. "\n")
        end
    end
end

--- Queues a command to run after combat. Actions are consumed in insertion order.
--- @param action string Command or semicolon-delimited command sequence.
--- @return boolean added Whether a non-empty action was queued.
function Leveling.addPostKillAction(action)
    action = normalizeAction(action)
    if action == "" then
        return false
    end

    table.insert(Leveling.postKillActions, 1, action)
    cecho("\nAdded a new post kill action: " .. action .. "\n")
    return true
end

--- Executes and clears commands deferred until the current fight ended.
function Leveling.doPostKillActions()
    local numActions = #Leveling.postKillActions
    Leveling.printDebug("doPostKillActions: numActions=" .. numActions)

    for _ = 1, numActions do
        local action = table.remove(Leveling.postKillActions)
        local actions = string.split(action, "%s*;%s*")
        sendAll(unpack(actions))
    end
end

--- Requeues the last movement command after Mudlet reports that movement failed.
--- The command is not sent here; the next trigger-driven step processes it.
function Leveling.redoLastStep()
    if Leveling.lastDirection ~= "" then
        Leveling.printDebug("Going back one step.")
        table.insert(Leveling.remainingDirections, 1, Leveling.lastDirection)
    end
end

--- Sends the next route direction and arms room capture. Completing a route
--- reloads the selected area so leveling continues without changing routes.
function Leveling.processStep()
    BuffManager.processBuffs()

    if #Leveling.remainingDirections > 0 then
        Leveling.RoomScanner:expectScan()

        local direction = table.remove(Leveling.remainingDirections, 1)
        Leveling.lastDirection = direction
        local commands = string.split(direction, "%s*;%s*")
        sendAll(unpack(commands))
    else
        cecho("\n<yellow>No steps left to process.<reset>\n")
        Leveling.stats["total"]["num_runs"] = Leveling.stats["total"]["num_runs"] + 1
        Leveling.loadArea(Leveling.currentAreaName)
    end
end

--- Selects an area, resets route-specific state, enables leveling triggers, and
--- sends the first movement command. Configuration actions persist across runs.
--- @param areaName string Key in Leveling.areas, or "stop" for compatibility.
function Leveling.loadArea(areaName)
    areaName = normalizeAction(areaName)
    if areaName == "stop" then
        cecho("\n<red>Leveling script STOPPED.<reset>\n")
        Leveling.stop()
        return
    end

    cecho("<red>\nAttempting to load: '" .. areaName .. "'<reset>\n")
    local area = Leveling.areas[areaName]
    if not area then
        cecho("\n<red>Unknown area: " .. areaName .. ".<reset>\n")
        return
    end

    if Leveling.stats["total"]["time"] == 0 then
        Leveling.stats["total"]["time"] = os.time()
    end

    if Leveling.currentAreaName ~= areaName then
        Leveling.ignoredMobNames = {}
    end

    -- Current leveling session
    Leveling.isRunning = true
    Leveling.currentAreaName = areaName
    Leveling.currentArea = area

    -- Navigation state
    Leveling.remainingDirections = table.deepcopy(area["dirs"])
    Leveling.lastDirection = ""
    Leveling.RoomScanner:configure(area["allowed_mobs"])

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

--- Handles the experience line emitted after a kill: updates statistics, runs
--- deferred actions, resets room parsing, and schedules a fresh look command.
--- @param expForKill string|number Experience captured by the Mudlet trigger.
function Leveling.handleKill(expForKill)
    local experience = tonumber(expForKill) or 0

    Leveling.stats["this_run"]["mobs_killed"] = Leveling.stats["this_run"]["mobs_killed"] + 1
    Leveling.stats["this_run"]["exp"] = Leveling.stats["this_run"]["exp"] + experience
    Leveling.stats["total"]["mobs_killed"] = Leveling.stats["total"]["mobs_killed"] + 1
    Leveling.stats["total"]["exp"] = Leveling.stats["total"]["exp"] + experience

    Leveling.doPostKillActions()
    Leveling.RoomScanner:requestLook(3)
end

--- Compatibility entry point retained for integrations using the old handler name.
function Leveling.checkRoom(expForKill)
    Leveling.handleKill(expForKill)
end

--- Receives one completed room snapshot from RoomScanner and passes it to the
--- existing combat decision. This is the scanner's only callback into Leveling.
--- @param roomMobs table Attack keywords found during the completed capture.
function Leveling.handleRoomScanComplete(roomMobs)
    Leveling.tryKill(roomMobs)
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

--- Attacks the last eligible mob in a completed room snapshot, or advances the
--- route when no eligible mobs remain. RoomScanner owns capture, not this choice.
--- @param roomMobs table|nil Completed attack keywords from RoomScanner.
function Leveling.tryKill(roomMobs)
    roomMobs = roomMobs or {}
    if #roomMobs == 0 then
        Leveling.processStep()
        return
    end

    local toKill = table.remove(roomMobs)
    if table.contains(Leveling.ignoredMobNames, toKill) then
        Leveling.tryKill(roomMobs)
        return
    end

    cecho("<yellow>\nFound a match, kill it good.\n<reset>")
    local actions = string.split(Leveling.initAction, "%s*;%s*")
    for index, action in ipairs(actions) do
        actions[index] = action .. " " .. toKill
    end
    sendAll(unpack(actions))
end

--- Establishes all Leveling-owned state. This is also the one-time migration
--- path from the pre-refactor state layout when an installed package is updated.
function Leveling.initialize()
    -- Configuration
    Leveling.debug = false
    Leveling.initAction = "kill"
    Leveling.hasteAction = ""
    Leveling.furyAction = ""
    Leveling.sancAction = ""
    Leveling.detectsAction = ""

    -- Current leveling session
    Leveling.isRunning = false
    Leveling.currentAreaName = nil
    Leveling.currentArea = nil
    -- Navigation state
    Leveling.remainingDirections = {}
    Leveling.lastDirection = ""

    -- Combat state
    Leveling.ignoredMobNames = {}
    Leveling.postKillActions = {}

    -- Clear fields owned by Leveling before RoomScanner was extracted.
    Leveling.currentAreaMobs = nil
    Leveling.currentRoomMobs = nil
    Leveling.lookAfterKillTimerId = nil

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
    Leveling.stateVersion = 2
end

--- Stops navigation and combat automation, resets RoomScanner, disables run
--- triggers, prints the completed session, and resets run statistics.
function Leveling.stop()
    Leveling.RoomScanner:reset()

    Leveling.isRunning = false
    Leveling.currentAreaName = nil
    Leveling.currentArea = nil
    Leveling.remainingDirections = {}
    Leveling.lastDirection = ""
    Leveling.ignoredMobNames = {}
    Leveling.postKillActions = {}

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
--- which are deferred until combat ends to avoid interfering with a fight.
function Leveling.handleAction(action)
    action = normalizeAction(action)
    Leveling.printDebug("handleAction: " .. action)
    if action == "" then
        return
    end

    if string.starts(action, "c") then
        Leveling.printDebug("adding post kill action: " .. action)
        table.insert(Leveling.postKillActions, 1, action)
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

function Leveling.printHelp()
    cecho("\n         <red>Leveling Script<reset>\n\n")
    cecho(" <yellow>Usage:<reset>\n")
    cecho("   Start area:             'leveling start [area name]'\n")
    cecho("   Stop script:            'leveling stop'\n")
    cecho("   Stats:                  'leveling stats'\n")
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
    cecho(" Init action:    '" .. Leveling.initAction .. "'\n\n")
end

function Leveling.printAreas()
    cecho("\n<red>        Leveling Areas:<reset>\n\n")

    for areaName in pairs(Leveling.areas) do
        cecho("  * <yellow>" .. areaName .. "<reset>\n")
        cecho("      " .. Leveling.areas[areaName]["description"] .. "\n")
    end
    cecho("\n")
end

if not Leveling.initialized or Leveling.stateVersion ~= 2 then
    Leveling.initialize()
end
