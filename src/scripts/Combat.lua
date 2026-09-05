Leveling.Combat = Leveling.Combat or {}

local Combat = Leveling.Combat
local previousEngageAction = Combat.engageCombatAction or Combat.initAction or Leveling.initAction

Combat.states = {
    idle = "idle",
    engaged = "engaged"
}

-- These are the combat-specific triggers controlled with the leveling session.
-- Movement failures, room capture, and death triggers have other owners.
Combat.triggerNames = {
    killedMonster = "killed monster",
    stillFighting = "Still Fighting",
    flee = "Leveling Flee",
    targetUnavailable = "Leveling Kill Stealing",
    roundComplete = "Combat Round Complete"
}

local function normalizeAction(action)
    return string.trim(tostring(action or ""))
end

local function normalizeRoundInterval(value)
    local interval = tonumber(value)
    if not interval or interval < 1 or interval >= math.huge or interval ~= math.floor(interval) then
        return nil
    end
    return interval
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

--- Clears transient/per-session state while preserving tactical configuration.
function Combat:reset()
    self:disableTriggers()
    self.state = self.states.idle
    self.pendingTarget = nil
    self.combatRoundsSinceDuringCombatAction = 0
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
    self.combatRoundsSinceDuringCombatAction = 0
    self.mobDefinitions = mobDefinitions or {}
    if not preserveIgnores then
        self.ignoredMobNames = {}
    end
    self:enableTriggers()
end

--- Sets the command sequence used to initiate combat.
--- @param action string Semicolon-delimited command sequence.
function Combat:setEngageCombatAction(action)
    self.engageCombatAction = normalizeAction(action)
    if self.engageCombatAction == "" then
        self.engageCombatAction = "kill"
    else
        cecho("\nEngage combat action set to " .. self.engageCombatAction)
    end
end

--- Public compatibility name; no second initAction configuration is stored.
function Combat:setInit(action)
    return self:setEngageCombatAction(action)
end

--- Configures one literal/template command, not a rotation or command queue.
--- Invalid edits are atomic. A valid change starts a fresh interval.
function Combat:setDuringCombatAction(action, roundInterval)
    local interval = normalizeRoundInterval(roundInterval)
    action = normalizeAction(action)
    if not interval or action == "" then
        return false, "During-combat actions require a positive integer round interval and a nonempty action."
    end
    self.duringCombatAction = action
    self.duringCombatActionRoundInterval = interval
    self.combatRoundsSinceDuringCombatAction = 0
    return true
end

function Combat:disableDuringCombatAction()
    self.duringCombatAction = ""
    self.combatRoundsSinceDuringCombatAction = 0
end

--- Thin command-configuration boundary shared by the Leveling alias/wrapper.
function Combat:configureDuringCombat(configuration)
    configuration = normalizeAction(configuration)
    if configuration == "off" then
        self:disableDuringCombatAction()
        cecho("\nDuring-combat action disabled.\n")
        return true
    end
    local rounds, action = configuration:match("^(%d+)%s+(.+)$")
    local accepted, reason = self:setDuringCombatAction(action, rounds)
    if not accepted then
        cecho("\n" .. reason .. " Use: leveling duringcombat <rounds> <action>, or off.\n")
        return false
    end
    cecho("\nDuring-combat action set to " .. self.duringCombatAction
        .. " every " .. self.duringCombatActionRoundInterval .. " completed round(s).\n")
    return true
end

--- Only this MUD-output event advances the round interval. Kills and other
--- callbacks neither advance it nor issue the periodic action.
function Combat:onCombatRoundComplete()
    if not Leveling.isRunning or self.state ~= self.states.engaged then return false end
    self.combatRoundsSinceDuringCombatAction = self.combatRoundsSinceDuringCombatAction + 1
    if self.duringCombatAction == ""
        or self.combatRoundsSinceDuringCombatAction < self.duringCombatActionRoundInterval then
        return false
    end

    local action = self.duringCombatAction
    if action:find("{target}", 1, true) then
        -- pendingTarget is invalidated on kill, target failure, still-fighting
        -- uncertainty, and reset. Never retain a second/stale target cache.
        if not self.pendingTarget or self.pendingTarget == "" then
            Leveling.printDebug("Skipping during-combat action: no current target is known.")
            return false
        end
        action = action:gsub("{target}", function() return self.pendingTarget end)
    end
    -- Consume the interval before send. Skipped target-dependent uses do not
    -- accumulate queued copies: a later eligible summary sends at most one.
    self.combatRoundsSinceDuringCombatAction = 0
    send(action)
    return true
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

--- Applies every configured engage command to one attack keyword. Selecting
--- another opponent while still engaged does not start a fresh round interval.
function Combat:attack(target)
    if self.state ~= self.states.engaged then self.combatRoundsSinceDuringCombatAction = 0 end
    self.state = self.states.engaged
    self.pendingTarget = target
    cecho("<yellow>\nFound a match, kill it good.\n<reset>")

    local actions = string.split(self.engageCombatAction, "%s*;%s*")
    for index, action in ipairs(actions) do
        actions[index] = action .. " " .. target
    end
    sendAll(unpack(actions))
    return true
end

--- Handles each experience event independently. A kill does not imply combat
--- ended: auto-aggro opponents may remain. Preserve the ongoing round interval.
--- The existing scan/progression recovery is not an after-combat guarantee.
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
function Combat:migrateLegacyState(engageAction)
    self.engageCombatAction = normalizeAction(engageAction or self.engageCombatAction)
    if self.engageCombatAction == "" then self.engageCombatAction = "kill" end
    if Leveling.ignoredMobNames ~= nil then
        self.ignoredMobNames = copyList(Leveling.ignoredMobNames)
    end
    if Leveling.postKillActions ~= nil then
        self.postKillActions = copyList(Leveling.postKillActions)
    end

    Leveling.initAction = nil
    self.initAction = nil
    Leveling.ignoredMobNames = nil
    Leveling.postKillActions = nil
end

function Combat:initialize()
    self.version = 2
    self.engageCombatAction = "kill"
    self.duringCombatAction = ""
    self.duringCombatActionRoundInterval = 1
    self.combatRoundsSinceDuringCombatAction = 0
    self.ignoredMobNames = {}
    self.postKillActions = {}
    self.mobDefinitions = {}
    self.pendingTarget = nil
    self.state = self.states.idle
    self:disableTriggers()
end

if Combat.version ~= 1 and Combat.version ~= 2 then
    Combat:initialize()
else
    -- Script reloads preserve configuration but not an uncertain engagement.
    Combat.state = Combat.states.idle
    Combat.pendingTarget = nil
    Combat.combatRoundsSinceDuringCombatAction = 0
    Combat:disableTriggers()
end

Combat.version = 2
Combat.duringCombatAction = normalizeAction(Combat.duringCombatAction)
Combat.duringCombatActionRoundInterval = normalizeRoundInterval(Combat.duringCombatActionRoundInterval) or 1
Combat:migrateLegacyState(previousEngageAction)

-- Preserve a running session during a package upgrade without making this the
-- normal area-data dependency; Leveling.loadArea() configures future sessions.
if Leveling.isRunning and Leveling.currentArea then
    Combat:configure(Leveling.currentArea["allowed_mobs"], true)
end
