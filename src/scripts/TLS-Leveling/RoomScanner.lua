Leveling.RoomScanner = Leveling.RoomScanner or {}

local RoomScanner = Leveling.RoomScanner

RoomScanner.states = {
    idle = "idle",
    waitingForStart = "waiting-for-start",
    capturing = "capturing"
}

-- These are the only triggers RoomScanner owns. Their names must match
-- src/triggers/TLS-Leveling/triggers.json exactly.
RoomScanner.triggerNames = {
    start = "Start Capture Room",
    line = "Room Capture Things",
    finish = "End Capture Room"
}

--- Disables every trigger in the room-capture lifecycle.
function RoomScanner:disableTriggers()
    disableTrigger(self.triggerNames.start)
    disableTrigger(self.triggerNames.line)
    disableTrigger(self.triggerNames.finish)
end

--- Cancels the delayed post-kill look when a scan is superseded or interrupted.
function RoomScanner:cancelLookTimer()
    if self.lookTimerId then
        killTimer(self.lookTimerId)
        self.lookTimerId = nil
    end
end

--- Cancels an incomplete scan while retaining the current area's mob definitions.
--- Stop, combat interruption, and duplicate scan requests all converge here.
function RoomScanner:cancel()
    self:cancelLookTimer()
    self:disableTriggers()
    self.state = self.states.idle
    self.capturedMobs = {}
end

--- Resets all scanner state, including the area-specific mob definitions.
function RoomScanner:reset()
    self:cancel()
    self.mobDefinitions = {}
end

--- Selects the mob definitions used for subsequent room-line matching.
--- @param mobDefinitions table Existing area allowed_mobs entries.
function RoomScanner:configure(mobDefinitions)
    self:cancel()
    self.mobDefinitions = mobDefinitions or {}
end

--- Arms the start-marker trigger for the next movement or look response.
--- Calling this again safely discards any incomplete scan and starts fresh.
function RoomScanner:expectScan()
    self:cancel()
    self.state = self.states.waitingForStart
    enableTrigger(self.triggerNames.start)
end

--- Arms a scan and schedules the post-kill look that will produce its output.
--- @param delaySeconds number Delay passed to Mudlet's tempTimer.
function RoomScanner:requestLook(delaySeconds)
    self:expectScan()
    self.lookTimerId = tempTimer(delaySeconds, [[Leveling.RoomScanner:onLookTimer()]])
end

--- Timer callback kept on the component so timer state is cleared before sending.
function RoomScanner:onLookTimer()
    self.lookTimerId = nil
    if self.state == self.states.waitingForStart then
        send("look")
    end
end

--- Handles the exits line that begins room capture.
--- @return boolean started Whether the scanner accepted the transition.
function RoomScanner:onStart()
    if self.state ~= self.states.waitingForStart then
        self:cancel()
        return false
    end

    disableTrigger(self.triggerNames.start)
    enableTrigger(self.triggerNames.line)
    enableTrigger(self.triggerNames.finish)
    self.state = self.states.capturing
    return true
end

--- Matches one captured room line against the current area's existing mob data.
--- Lines received outside the capture phase are ignored without changing state.
--- @param description string Captured MUD room line.
--- @return boolean accepted Whether the line belonged to an active capture.
function RoomScanner:onLine(description)
    if self.state ~= self.states.capturing then
        return false
    end

    description = string.trim(tostring(description or ""))
    for _, mob in ipairs(self.mobDefinitions) do
        if string.trim(tostring(mob.description)) == description then
            table.insert(self.capturedMobs, string.lower(mob.name))
        end
    end
    return true
end

--- Finalizes a valid capture and hands its mob-name list to Leveling combat logic.
--- RoomScanner returns to idle before the callback, keeping the coupling one-way
--- at the handoff point and allowing combat/navigation to request another scan.
--- @return boolean finished Whether an active capture was completed.
function RoomScanner:onFinish()
    if self.state ~= self.states.capturing then
        self:cancel()
        return false
    end

    local completedMobs = self.capturedMobs
    self.capturedMobs = {}
    self:cancelLookTimer()
    self:disableTriggers()
    self.state = self.states.idle
    Leveling.handleRoomScanComplete(completedMobs)
    return true
end

function RoomScanner:initialize()
    self.version = 1
    self.lookTimerId = nil
    self.mobDefinitions = {}
    self.capturedMobs = {}
    self.state = self.states.idle
    self:disableTriggers()
end

if RoomScanner.version ~= 1 then
    RoomScanner:initialize()
else
    -- Script/package reloads must not preserve a partial capture.
    RoomScanner:cancel()
end
