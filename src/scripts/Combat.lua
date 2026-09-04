Leveling.Combat = Leveling.Combat or {}

local Combat = Leveling.Combat

Combat.states = {
    idle = "idle",
    engaged = "engaged"
}

-- These are the combat-specific triggers controlled with the leveling session.
-- Movement failures, room capture, death, and buff triggers have other owners.
Combat.triggerNames = {
    killedMonster = "killed monster",
    stillFighting = "Still Fighting",
    flee = "Leveling Flee",
    targetUnavailable = "Leveling Kill Stealing"
}

local function normalizeAction(action)
    return string.trim(tostring(action or ""))
end

local function copyList(values)
    local copied = {}
    for index, value in ipairs(values or {}) do
        copied[index] = value
    end
    return copied
end

function Combat:enableTriggers()
    for _, triggerName in pairs(self.triggerNames) do
        enableTrigger(triggerName)
    end
end

function Combat:disableTriggers()
    for _, triggerName in pairs(self.triggerNames) do
        disableTrigger(triggerName)
    end
end

--- Clears transient and per-session combat state while preserving initAction.
function Combat:reset()
    self:disableTriggers()
    self.state = self.states.idle
    self.pendingTarget = nil
    self.mobDefinitions = {}
    self.ignoredMobNames = {}
    self.postKillActions = {}
end

--- Configures combat for an area and activates its triggers. Same-area route
--- loops preserve ignores; selecting a different area clears them.
--- @param mobDefinitions table Existing area allowed_mobs entries.
--- @param preserveIgnores boolean Whether this is a same-area route loop.
function Combat:configure(mobDefinitions, preserveIgnores)
    self.state = self.states.idle
    self.pendingTarget = nil
    self.mobDefinitions = mobDefinitions or {}
    if not preserveIgnores then
        self.ignoredMobNames = {}
    end
    self:enableTriggers()
end

--- Sets the command sequence used to initiate combat.
--- @param action string Semicolon-delimited command sequence.
function Combat:setInit(action)
    self.initAction = normalizeAction(action)
    if self.initAction == "" then
        self.initAction = "kill"
    else
        cecho("\nInit action set to " .. self.initAction)
    end
end

--- Toggles every configured attack keyword selected by exact name or by a
--- description fragment. Ignore entries remain attack keywords, not occupants.
--- @param mobToIgnore string User-supplied name or description fragment.
function Combat:handleIgnoreAction(mobToIgnore)
    local query = string.lower(normalizeAction(mobToIgnore))
    if query == "" then
        return
    end

    local matchingNames = {}
    local namesSeen = {}
    for _, mob in ipairs(self.mobDefinitions) do
        local mobName = string.lower(tostring(mob.name or ""))
        local description = string.lower(tostring(mob.description or ""))
        if (mobName == query or string.find(description, query, 1, true)) and not namesSeen[mobName] then
            table.insert(matchingNames, mobName)
            namesSeen[mobName] = true
        end
    end

    for _, mobName in ipairs(matchingNames) do
        local removed = false
        for index = #self.ignoredMobNames, 1, -1 do
            if self.ignoredMobNames[index] == mobName then
                table.remove(self.ignoredMobNames, index)
                removed = true
            end
        end

        if removed then
            cecho("\nRemoved from ignore list: " .. mobName .. "\n")
        else
            table.insert(self.ignoredMobNames, mobName)
            cecho("\nAdded to ignore list: " .. mobName .. "\n")
        end
    end
end

function Combat:isIgnored(mobName)
    for _, ignoredName in ipairs(self.ignoredMobNames) do
        if ignoredName == mobName then
            return true
        end
    end
    return false
end

--- Adds a command for the next kill event. Actions are consumed in insertion
--- order, preserving the existing behavior even if other opponents remain.
--- @param action string Command or semicolon-delimited command sequence.
--- @param announce boolean|nil Whether to print the user-facing confirmation.
function Combat:queuePostKillAction(action, announce)
    action = normalizeAction(action)
    if action == "" then
        return false
    end

    table.insert(self.postKillActions, 1, action)
    if announce then
        cecho("\nAdded a new post kill action: " .. action .. "\n")
    end
    return true
end

function Combat:addPostKillAction(action)
    return self:queuePostKillAction(action, true)
end

--- Executes and clears actions deferred until the next observed kill.
function Combat:runPostKillActions()
    local numActions = #self.postKillActions
    Leveling.printDebug("runPostKillActions: numActions=" .. numActions)

    for _ = 1, numActions do
        local action = table.remove(self.postKillActions)
        local actions = string.split(action, "%s*;%s*")
        sendAll(unpack(actions))
    end
end

--- Consumes one completed room snapshot, selecting the last eligible occupant
--- exactly as before. Duplicate occupant keywords are deliberately preserved.
--- @param roomMobs table|nil Completed attack keywords from RoomScanner.
function Combat:onRoomScanned(roomMobs)
    roomMobs = roomMobs or {}
    while #roomMobs > 0 do
        local target = table.remove(roomMobs)
        if not self:isIgnored(target) then
            return self:attack(target)
        end
    end

    self.state = self.states.idle
    self.pendingTarget = nil
    Leveling.processStep()
    return false
end

--- Applies every configured init command to one attack keyword.
function Combat:attack(target)
    self.state = self.states.engaged
    self.pendingTarget = target
    cecho("<yellow>\nFound a match, kill it good.\n<reset>")

    local actions = string.split(self.initAction, "%s*;%s*")
    for index, action in ipairs(actions) do
        actions[index] = action .. " " .. target
    end
    sendAll(unpack(actions))
    return true
end

--- Handles each experience event independently. A kill does not imply combat
--- ended: auto-aggro opponents may remain, so engagement lasts until a clear
--- completed room scan or another explicit recovery event.
function Combat:onKill(expForKill)
    self.state = self.states.engaged
    self.pendingTarget = nil
    Leveling.recordKill(expForKill)
    self:runPostKillActions()
    Leveling.RoomScanner:requestLook(3)
end

--- A post-kill look found an opponent actively fighting the player. Navigator
--- performs the public pause/cancel operation so movement cannot resume.
function Combat:onStillFighting()
    self.state = self.states.engaged
    self.pendingTarget = nil
    return Leveling.Navigator:pause("combat")
end

--- Preserves existing kill-steal/target-missing recovery by abandoning the
--- stale target and requesting the next navigation step exactly once.
function Combat:onTargetUnavailable()
    if self.state ~= self.states.engaged and not self.pendingTarget then
        return false
    end

    self.state = self.states.idle
    self.pendingTarget = nil
    Leveling.processStep()
    return true
end

--- Flee remains an overall session stop; Combat only interprets the event.
function Combat:onFlee()
    self.state = self.states.idle
    self.pendingTarget = nil
    Leveling.stop()
end

--- One-time transfer from the pre-extraction Leveling fields. Assignment is
--- removed after copying so Combat remains the sole authoritative state owner.
function Combat:migrateLegacyState()
    if Leveling.initAction ~= nil then
        self.initAction = normalizeAction(Leveling.initAction)
        if self.initAction == "" then
            self.initAction = "kill"
        end
    end
    if Leveling.ignoredMobNames ~= nil then
        self.ignoredMobNames = copyList(Leveling.ignoredMobNames)
    end
    if Leveling.postKillActions ~= nil then
        self.postKillActions = copyList(Leveling.postKillActions)
    end

    Leveling.initAction = nil
    Leveling.ignoredMobNames = nil
    Leveling.postKillActions = nil
end

function Combat:initialize()
    self.version = 1
    self.initAction = "kill"
    self.ignoredMobNames = {}
    self.postKillActions = {}
    self.mobDefinitions = {}
    self.pendingTarget = nil
    self.state = self.states.idle
    self:disableTriggers()
end

if Combat.version ~= 1 then
    Combat:initialize()
else
    -- Script reloads preserve configuration but not an uncertain engagement.
    Combat.state = Combat.states.idle
    Combat.pendingTarget = nil
    Combat:disableTriggers()
end

Combat:migrateLegacyState()

-- Preserve a running session during a package upgrade without making this the
-- normal area-data dependency; Leveling.loadArea() configures future sessions.
if Leveling.isRunning and Leveling.currentArea then
    Combat:configure(Leveling.currentArea["allowed_mobs"], true)
end
