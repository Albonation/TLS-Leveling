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

function Leveling.printDebug(string)
    if Leveling.debug == true then
        cecho("\n<red>DEBUG: " .. string .. "<reset>\n")
    end
end

function Leveling.setHaste(string)
    Leveling.hasteAction = string

    if string == "" then
        cecho("\nHaste action disabled.\n")
        disableTrigger("Leveling Haste")
    else
        cecho("\nHaste action set to: " .. Leveling.hasteAction .. "\n")
        enableTrigger("Leveling Haste")
    end
end

function Leveling.setFury(string)
    Leveling.fury = string

    if string == "" then
        cecho("\nFury disabled\n")
        disableTrigger("Levleing Fury")
    else
        cecho("\nFury enabled\n")
        enableTrigger("Leveling Fury")
    end
end

function Leveling.setDetects(string)
    Leveling.detectsAction = string

    if string == "" then
        cecho("\nDetects disabled.\n")
        disableTrigger("Leveling Detects")
    else
        cecho("\nDetects action set to: " .. Leveling.detectsAction .. "\n")
        enableTrigger("Leveling Detects")
    end
end

function Leveling.setSanc(string)
    Leveling.sancAction = string

    if string == "" then
        cecho("\nSanc action disabled.\n")
        disableTrigger("Leveling Sanc")
    else
        cecho("\nSanc action set to: " .. Leveling.sancAction .. "\n")
        enableTrigger("Leveling Sanc")
    end
end

function Leveling.setInit(string)
    Leveling.initAction = string

    if string == "" then
        Leveling.initAction = "kill"
    else
        cecho("\nInit action set to ".. string)
    end
end

function Leveling.handleHaste()
    Leveling.handleAction(Leveling.hasteAction)
end

function Leveling.handleDetects()
    Leveling.handleAction(Leveling.detectsAction)
end

function Leveling.handleSanc()
    Leveling.handleAction(Leveling.sancAction)
end

function Leveling.handleIgnoreAction(mobToIgnore)
    local match = {}
    mobToIgnore = string.lower(mobToIgnore)
    for k,v in pairs(Leveling.allowedMobs) do
        if mobToIgnore == k then
            match = {k}
            break
        elseif string.find(string.lower(v),mobToIgnore) then
            table.insert(match,k)
        end
    end

    for k,v in ipairs(match) do
        if table.contains(Leveling.ignoreList,v) then
            Leveling.ignoreList = table.n_complement(Leveling.ignoreList,v)
            cecho("\nRemoved from ignore list: " .. Leveling.allowedMobs[v] .. "\n")
        else
            table.insert(Leveling.ignoreList,v)
            cecho("\nAdded to ignore list: " ..Leveling.allowedMobs[v] .. "\n")
        end
    end
end

function Leveling.doPostKillActions()
    local numActions = #Leveling.postKillActions
    Leveling.printDebug("doPostKillActions: numAction=" .. numActions)
    
    if numActions > 0 then
        for ndx=1, numActions, 1 do
            local action = table.remove(Leveling.postKillActions)
            local actions = string.split(action,"%s*;%s*")
            sendAll(unpack(actions))
        end
    end
end

function Leveling.redoLastStep()
    if Leveling.lastStep ~= "" then
        Leveling.printDebug("Going back one step.")
        table.insert(Leveling.directions, 1, Leveling.lastStep)
    end
end

function Leveling.processStep()
    --get any missing buffs back
  BuffManager.processBuffs()
      
    if #Leveling.directions > 0 then
        enableTrigger("Start Capture Room")
        Leveling.mobsInRoom = {}
        --Leveling.mobsToCheck = 0

        local dir = table.remove(Leveling.directions,1)
        Leveling.lastStep = dir
        local dirs = string.split(dir,"%s*;%s*")
        sendAll(unpack(dirs))
    else
        cecho("\n<yellow>No steps left to process.<reset>\n")
        Leveling.stats["total"]["num_runs"] = Leveling.stats["total"]["num_runs"] + 1
        Leveling.loadArea(Leveling.theCurrentArea)
    end
end

function Leveling.addRoomMob(str)
    str = string.trim(str)

    for index,mob in ipairs(Leveling.allowedMobs) do
        mob.description = tostring(mob.description)
        if string.trim(mob.description) == str then
            --Leveling.mobsToCheck = Leveling.mobsToCheck + 1
            table.insert(Leveling.mobsInRoom, mob.name)
        end
    end
end

function Leveling.loadArea(areaName)
    if areaName == "stop" then
        cecho("\n<red>Leveling script STOPPED.<reset>\n")
        Leveling.stop()
    else
        cecho("<red>\nAttempting to load: '" .. areaName .. "'<reset>\n")

        if Leveling.areas[areaName] then
            if Leveling.stats["total"]["time"] == 0 then
                Leveling.stats["total"]["time"] = os.time()
            end

            Leveling.directions = {}
            Leveling.mobsInRoom = {}
            --Leveling.mobsToCheck = 0
            if Leveling.currentArea ~= areaName then
                Leveling.ignoreList = {}
            end
            Leveling.started = true
            local area = Leveling.areas[areaName]
            Leveling.currentArea = area
            Leveling.allowedMobs = area["allowed_mobs"]
            -- force all mob name keywords to lower case
            for k,v in pairs(Leveling.allowedMobs) do
                if not string.lower(k) == k then
                    Leveling.allowedMobs[string.lower(k)] = v
                    Leveling.allowedMobs[k] = nil
                end
            end
            Leveling.directions = table.deepcopy(area["dirs"])
            enableTrigger("kill monster")
            enableTrigger("Leveling Flee")
            enableTrigger("Leveling Move While Fighting")
            enableTrigger("Leveling Too Much Weight")
            enableTrigger("Leveling Kill Stealing")
            -- use the helper functions to re-enable the triggers if we should
            Leveling.setFury(Leveling.fury)
            Leveling.setHaste(Leveling.hasteAction)
            Leveling.setSanc(Leveling.sancAction)
            Leveling.setDetects(Leveling.detectsAction)
            cecho("<purple>Area loaded. Let's do this!<reset>\n")
            Leveling.stats["this_run"]["time"] = os.time()
            Leveling.processStep()
        else
            cecho("\n<red>Unknown area: " .. areaName .. ".<reset>\n")
        end
    end
end

function Leveling.checkRoom(expForKill)
    -- updating stats
    Leveling.stats["this_run"]["mobs_killed"] = Leveling.stats["this_run"]["mobs_killed"] + 1
    Leveling.stats["this_run"]["exp"] = Leveling.stats["this_run"]["exp"] + expForKill
    Leveling.stats["total"]["mobs_killed"] = Leveling.stats["total"]["mobs_killed"] + 1
    Leveling.stats["total"]["exp"] = Leveling.stats["total"]["exp"] + expForKill
    -- Before we kill things, see if we need to do any post combat actions
    Leveling.doPostKillActions()

    enableTrigger("Start Capture Room")
    Leveling.mobsInRoom = {}
    --Leveling.mobsToCheck = 0

    lookAfterKill = tempTimer(3, [[ send("look") ]])
end

function Leveling.tryKill()
    if #Leveling.mobsInRoom == 0 then
        Leveling.processStep()
    else
        local toKill = table.remove(Leveling.mobsInRoom)
        if not table.contains(Leveling.ignoreList, toKill) then
            cecho("<yellow>\nFound a match, kill it good.\n<reset>")
            local actions = string.split(Leveling.initAction,"%s*;%s*")
            for k,v in ipairs(actions) do
                actions[k] = v .. " " .. toKill
            end
            sendAll(unpack(actions))
        else
            Leveling.tryKill()
        end
    end
end

function Leveling.initialize()
    Leveling.initialized = true
    Leveling.allowedMobs = {}
    --Leveling.mobsToCheck = 0
    Leveling.started = false
    Leveling.postKillActions = {}
    Leveling.directions = {}
    Leveling.initAction = "kill"
    Leveling.hasteAction = ""
    Leveling.sancAction = ""
    Leveling.detectsAction = ""
    Leveling.berserk = ""
    Leveling.fury = ""
    Leveling.detectsAction = ""
    Leveling.previousStep = ""
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
    Leveling.debug = false
end

function Leveling.stop()
    Leveling.directions = {}
    Leveling.mobsInRoom = {}
    Leveling.postKillActions = {}
    --Leveling.mobsToCheck = 0
    Leveling.started = false
    Leveling.allowedMobs = {}
    Leveling.previousStep = ""
    Leveling.theCurrentArea = ""
    disableTrigger("kill monster")
    disableTrigger("Start Capture Room")
    disableTrigger("End Capture Room")
    disableTrigger("Room Capture Things")
    disableTrigger("Leveling Flee")
    disableTrigger("Leveling Kill Stealing")
    disableTrigger("Leveling Haste")
    disableTrigger("Leveling Fury")
    disableTrigger("Leveling Detects")
    disableTrigger("Leveling Sanc")
    disableTrigger("Leveling Move While Fighting")
    disableTrigger("Leveling Too Much Weight")
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

function Leveling.handleAction(action)
    Leveling.printDebug("handleAction: " .. action)
    if action ~= "" then
        if string.starts(action, "c") then
            Leveling.printDebug("adding post kill action: " .. action)
            table.insert(Leveling.postKillActions, 1, action)
        else
            local actions = string.split(action,"%s*;%s*")
            sendAll(unpack(actions))
        end
    end
end

function Leveling.printRunStats()
    local expThisRun = Leveling.stats["this_run"]["exp"]
    local avg = expThisRun / Leveling.stats["this_run"]["mobs_killed"]
    local currentTime = os.time()
    local minutesSinceStart = math.floor((currentTime - Leveling.stats["this_run"]["time"]) / 60)
    local expPerMinute = expThisRun / minutesSinceStart

    local totalExp = Leveling.stats["total"]["exp"]
    local totalAvg = totalExp / Leveling.stats["total"]["mobs_killed"]
    local minutesSinceTotalStart = math.floor((currentTime - Leveling.stats["total"]["time"]) / 60)
    local totalExpPerMinute = totalExp / minutesSinceTotalStart
    
    local format = function (val) return string.gsub(math.floor(val), "^(-?%d+)(%d%d%d)", '%1,%2') end
    
    cecho("\n<yellow>              Leveling Stats<reset>\n\n")
    cecho("                Current Run | All Runs (" .. Leveling.stats["total"]["num_runs"] .. ")\n")
    cecho(string.format(" Mobs Killed:   <red>%12s<reset>| <red>%12s<reset>\n", Leveling.stats["this_run"]["mobs_killed"], Leveling.stats["total"]["mobs_killed"]))
    cecho(string.format(" Total Exp:     <yellow>%12s<reset>| <yellow>%12s<reset>\n", format(expThisRun), format(totalExp)))
    cecho(" -----------------------------------------\n")
    cecho(string.format(" Avg Per Kill:  <yellow>%12s<reset>| <yellow>%12s<reset>\n", format(avg), format(totalAvg)))
    cecho(string.format(" Exp Per Hour:  <yellow>%12s<reset>| <yellow>%12s<reset>\n\n", format(expPerMinute * 60), format(totalExpPerMinute * 60)))
end

function Leveling.printHelp()
    cecho("\n         <red>Leveling Script<reset>\n\n")
    cecho(" <yellow>Usage:<reset>\n")
   --cecho("   Update script:          'leveling update'\n")
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

    for ndx,val in pairs(Leveling.areas) do
        cecho("  * <yellow>" .. ndx .. "<reset>\n")
        cecho("      " .. Leveling.areas[ndx]["description"] .. "\n")
    end
    cecho("\n")
end

if not Leveling.initialized then
    Leveling.initialize()
end