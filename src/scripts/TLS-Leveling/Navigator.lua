Leveling.Navigator = Leveling.Navigator or {}

local Navigator = Leveling.Navigator

Navigator.states = {
    idle = "idle",
    ready = "ready",
    moving = "moving",
    paused = "paused"
}

local function copyRoute(route)
    local copiedRoute = {}
    for index, step in ipairs(route or {}) do
        copiedRoute[index] = step
    end
    return copiedRoute
end

--- Invalidates the current movement callback and clears its transient state.
--- The route index is deliberately retained so an unresolved step can retry.
function Navigator:clearMovementAttempt()
    self.attemptSerial = self.attemptSerial + 1
    self.activeAttemptId = nil
    self.pendingStep = nil
end

--- Cancels navigation and any scan waiting on its movement response.
--- The configured route remains available for inspection until reset/replaced.
function Navigator:cancel()
    self:clearMovementAttempt()
    self.retryPending = false
    self.pauseReason = nil
    self.state = self.states.idle
    Leveling.RoomScanner:cancel()
end

--- Clears all route and movement state, leaving Navigator predictably idle.
function Navigator:reset()
    self:cancel()
    self.route = {}
    self.routeIndex = 1
end

--- Replaces the active route and positions navigation at its first step.
--- @param route table Ordered movement command strings from the selected area.
function Navigator:setRoute(route)
    self:cancel()
    self.route = copyRoute(route)
    self.routeIndex = 1
    self.state = self.states.ready
end

--- Records that the pending movement produced a room and advances exactly once.
--- The attempt id prevents a late room-start callback from advancing a new route.
--- @param attemptId number Movement attempt captured when the scan was armed.
--- @return boolean accepted Whether the callback matched the active movement.
function Navigator:onMovementSuccess(attemptId)
    if self.state ~= self.states.moving or self.activeAttemptId ~= attemptId then
        return false
    end

    self.activeAttemptId = nil
    self.pendingStep = nil
    self.retryPending = false
    self.pauseReason = nil
    self.routeIndex = self.routeIndex + 1
    self.state = self.states.ready
    return true
end

--- Pauses after a rejected movement without advancing the active route step.
--- Existing behavior retries only when another progression trigger requests it;
--- there was no movement retry timer to preserve.
--- @param reason string|nil Diagnostic reason for the pause.
--- @return boolean accepted Whether an active movement was rejected.
function Navigator:onMovementFailure(reason)
    if self.state ~= self.states.moving then
        return false
    end

    Leveling.printDebug("Going back one step.")
    self:clearMovementAttempt()
    self.retryPending = true
    self.pauseReason = reason or "movement failed"
    self.state = self.states.paused
    Leveling.RoomScanner:cancel()
    return true
end

--- Pauses route progression for combat or group coordination.
--- A still-pending movement remains at the same index for a later safe retry.
--- @param reason string|nil Diagnostic reason for the pause.
function Navigator:pause(reason)
    if self.state == self.states.idle then
        return false
    end

    if self.state == self.states.moving then
        self:clearMovementAttempt()
        self.retryPending = true
    end

    self.pauseReason = reason or "paused"
    self.state = self.states.paused
    Leveling.RoomScanner:cancel()
    return true
end

--- Preserves the existing overweight recovery: drop coins, inspect the current
--- room, then retry the same route index when scan completion requests a step.
function Navigator:onTooMuchWeight()
    send("drop 2000 silver")
    local failureAccepted = self:onMovementFailure("carrying too much")
    if failureAccepted then
        Leveling.RoomScanner:expectScan()
    end

    send("look")
    return failureAccepted
end

--- Completes the route once, then hands broader loop/stat behavior to Leveling.
function Navigator:completeRoute()
    if self.state == self.states.idle then
        return false
    end

    self:clearMovementAttempt()
    self.retryPending = false
    self.pauseReason = nil
    self.state = self.states.idle
    Leveling.RoomScanner:cancel()
    Leveling.handleRouteComplete()
    return true
end

--- Sends the route's current step and asks RoomScanner to recognize its room.
--- Paused retries reuse the same route index; repeated calls while moving do not
--- send or advance a second step.
function Navigator:processStep()
    if self.state == self.states.idle or self.state == self.states.moving then
        return false
    end

    if self.routeIndex > #self.route then
        return self:completeRoute()
    end

    self.retryPending = false
    self.pauseReason = nil
    self.attemptSerial = self.attemptSerial + 1
    local attemptId = self.attemptSerial
    local step = self.route[self.routeIndex]
    self.activeAttemptId = attemptId
    self.pendingStep = step
    self.state = self.states.moving

    Leveling.RoomScanner:expectScan(function()
        return Leveling.Navigator:onMovementSuccess(attemptId)
    end)

    local commands = string.split(step, "%s*;%s*")
    sendAll(unpack(commands))
    return true
end

function Navigator:initialize()
    self.version = 1
    self.attemptSerial = 0
    self.route = {}
    self.routeIndex = 1
    self.activeAttemptId = nil
    self.pendingStep = nil
    self.retryPending = false
    self.pauseReason = nil
    self.state = self.states.idle
    self:reset()
end

Navigator:initialize()
