local root = arg[1] or "."
local sent, output, enabled = {}, {}, {}
local timerCalls = 0
unpack = unpack or table.unpack

function send(command) table.insert(sent, command) end
function sendAll(...)
    for index = 1, select("#", ...) do send((select(index, ...))) end
end
function cecho(message) table.insert(output, message) end
echo = cecho
function enableTrigger(name) enabled[name] = true end
function disableTrigger(name) enabled[name] = false end
function killTimer() end
function tempTimer() timerCalls = timerCalls + 1; return timerCalls end
string.trim = function(value) return value:match("^%s*(.-)%s*$") end
string.split = function(value, separator)
    local parts, start = {}, 1
    local first, last = value:find(separator, start)
    while first do
        table.insert(parts, value:sub(start, first - 1))
        start = last + 1
        first, last = value:find(separator, start)
    end
    table.insert(parts, value:sub(start))
    return parts
end
table.contains = function(values, wanted)
    for _, value in ipairs(values) do if value == wanted then return true end end
    return false
end
local function equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function commands(expected, label) equal(table.concat(sent, ","), expected, label) end
local function alias(option, value)
    matches = {"leveling", option, value}
    dofile(root .. "/src/aliases/leveling.lua")
end
local function round()
    matches = {">You hit 20 times for an average 584 damage.", "20", "584"}
    dofile(root .. "/src/triggers/Combat_Round_Complete.lua")
end

-- In-place removal decommissions only the package's old owner/API. No foreign
-- global gets adopted, overwritten, or disabled; generic tactical helpers stay.
local retiredStops = 0
local retired = {stop = function() retiredStops = retiredStops + 1 end}
BuffManager = {personal = true}
local personal = BuffManager
Leveling = {BuffManager = retired, hasteAction = "old", setHaste = function() end}
local globals = {}
for key in pairs(_G) do globals[key] = true end
for _, file in ipairs({"Leveling", "AreaRepository", "RoomScanner", "Navigator", "Combat"}) do
    dofile(root .. "/src/scripts/" .. file .. ".lua")
end
equal(retiredStops, 1, "old package manager deactivated before removal")
equal(Leveling.BuffManager, nil, "no package maintenance owner remains")
equal(Leveling.hasteAction, nil, "old maintenance configuration retired")
equal(Leveling.setHaste, nil, "old maintenance setter retired")
equal(BuffManager, personal, "foreign global remains untouched")
for key in pairs(_G) do assert(globals[key], "unintended top-level global: " .. key) end

local Combat, Scanner, Navigator = Leveling.Combat, Leveling.RoomScanner, Leveling.Navigator
local function setup(action, interval)
    Leveling.stop()
    Combat:setInit("kill")
    Combat:disableDuringCombatAction()
    if action then assert(Combat:setDuringCombatAction(action, interval)) end
    Scanner:configure({})
    Combat:configure({}, false)
    Navigator:setRoute({"w", "n"})
    Leveling.isRunning = true
    sent, output = {}, {}
end

-- A: real aliases and compatibility APIs all configure one authoritative field.
setup()
alias("init", "bash;kill")
equal(Combat.engageCombatAction, "bash;kill", "init alias configures engage action")
equal(Combat.initAction, nil, "no duplicate init field")
Combat:attack("troll")
commands("bash troll,kill troll", "legacy per-command target append preserved")
Leveling.setInit("c 'opening weave'")
sent = {}
Combat:attack("bloodlord")
commands("c 'opening weave' bloodlord", "weave remains a valid engage command")
alias("engage", "kick")
equal(Combat.engageCombatAction, "kick", "clearer engage alias shares configuration")
Leveling.setInit("")
equal(Combat.engageCombatAction, "kill", "empty init preserves default kill behavior")

-- B: no during action; completed rounds count, but never issue a command.
setup()
Combat:attack("troll")
sent = {}
round()
round()
commands("", "unset during action sends nothing")
equal(Combat.combatRoundsSinceDuringCombatAction, 2, "only round events increment count")

-- C/J: one literal action per completed round, without appended target/timers.
setup("c 'primary weave'", 1)
Combat:attack("troll")
sent = {}
local timersBefore = timerCalls
round()
commands("c 'primary weave'", "interval one first round")
round()
commands("c 'primary weave',c 'primary weave'", "identical consecutive summaries are separate rounds")
equal(Combat.combatRoundsSinceDuringCombatAction, 0, "successful use consumes interval")
equal(timerCalls, timersBefore, "round actions introduce no timer")

-- D: exact 1/2/3/4 cadence.
setup("kick", 2)
Combat:attack("troll")
sent = {}
round()
commands("", "interval two round one")
round()
commands("kick", "interval two round two")
round()
commands("kick", "interval two round three")
round()
commands("kick,kick", "interval two round four")

-- E: an idle -> attack engagement resets the count, not every target callback.
round()
equal(Combat.combatRoundsSinceDuringCombatAction, 1, "partial old interval")
Combat:onTargetUnavailable()
Combat:attack("bloodlord")
equal(Combat.combatRoundsSinceDuringCombatAction, 0, "new engagement starts fresh")
sent = {}
round()
commands("", "new engagement needs its first full interval")
round()
commands("kick", "new engagement second round")

-- F: kill/auto-aggro/still-fighting/fresh target selection do not reset the
-- continuing interval or issue a periodic action from a non-round callback.
setup("c 'primary weave'", 2)
Combat:attack("troll")
sent = {}
round()
Combat:onKill(5)
equal(Combat.combatRoundsSinceDuringCombatAction, 1, "individual kill preserves count")
equal(Combat.state, Combat.states.engaged, "individual kill retains engagement")
equal(Combat.pendingTarget, nil, "dead target not retained")
Combat:onStillFighting()
equal(Combat.combatRoundsSinceDuringCombatAction, 1, "still-fighting callback preserves count")
commands("", "kill and still-fighting callbacks do not send periodic actions")
round()
commands("c 'primary weave'", "literal action continues after auto-aggro kill")
round()
Combat:onRoomScanned({"bloodlord"})
equal(Combat.combatRoundsSinceDuringCombatAction, 1, "next opponent within engagement preserves interval")
sent = {}
round()
commands("c 'primary weave'", "next opponent continues the same cadence")

-- I: target templates use only the known current attack keyword. A due action
-- with no target is skipped, with no stale fallback, queued copies, or timer.
setup("c 'targeted weave' {target}", 2)
Combat:attack("troll")
sent = {}
round()
round()
commands("c 'targeted weave' troll", "known target expansion")
round()
Combat:onKill(5)
sent = {}
round()
round()
commands("", "no dead/stale target emitted after kill")
equal(Combat.combatRoundsSinceDuringCombatAction, 3, "skipped opportunity does not claim an action was sent")
Combat:attack("bloodlord")
sent = {}
commands("", "target callback alone cannot release due round action")
round()
commands("c 'targeted weave' bloodlord", "next summary sends one action, without catch-up copies")
equal(Combat.combatRoundsSinceDuringCombatAction, 0, "eventual use resets interval")
Combat:onStillFighting()
sent = {}
round()
round()
commands("", "uncertain still-fighting target is not guessed")
Combat:onTargetUnavailable()
round()
commands("w", "target failure resumes existing movement without a stale cast")

-- Literal really means literal: no target appended, no semicolon splitting or
-- command-prefix classification for the one during-combat action.
setup("say {literal};look", 1)
Combat:attack("troll")
sent = {}
round()
commands("say {literal};look", "one configured during-combat action is sent literally")
equal(#sent, 1, "during action is not converted to a rotation/sequence")

-- G/H: stopped and idle gates; configuration remains after stop/reset.
setup("kick", 2)
round()
equal(Combat.combatRoundsSinceDuringCombatAction, 0, "idle round ignored")
commands("", "idle summary cannot send")
Combat:attack("troll")
round()
Leveling.stop()
equal(Combat.combatRoundsSinceDuringCombatAction, 0, "stop clears round state")
equal(Combat.pendingTarget, nil, "stop clears target")
equal(Combat.duringCombatAction, "kick", "stop preserves during action")
equal(Combat.duringCombatActionRoundInterval, 2, "stop preserves interval")
equal(enabled["Combat Round Complete"], false, "stop disables round trigger")
sent = {}
round()
commands("", "late summary after stop cannot send")
Combat.state = Combat.states.engaged
round()
equal(Combat.combatRoundsSinceDuringCombatAction, 0, "session guard applies even if engagement flag remains")
commands("", "stopped session does not trust engaged flag alone")

-- K: malformed edits, including missing intervals/actions, are atomic.
setup("kick", 2)
Combat:attack("troll")
round()
for _, value in ipairs({"0 c weave", "-1 c weave", "1.5 c weave", "two c weave", "c weave", "", "2", "2   ", "off extra"}) do
    equal(Leveling.setDuringCombat(value), false, "reject invalid configuration " .. value)
    equal(Combat.duringCombatAction, "kick", "invalid edit preserves action")
    equal(Combat.duringCombatActionRoundInterval, 2, "invalid edit preserves interval")
    equal(Combat.combatRoundsSinceDuringCombatAction, 1, "invalid edit preserves partial interval")
end
equal(Combat:setDuringCombatAction("kick", nil), false, "API rejects missing interval")
equal(Combat:setDuringCombatAction("kick", math.huge), false, "API rejects infinite interval")
equal(Combat:setDuringCombatAction("kick", 0 / 0), false, "API rejects NaN interval")
alias("duringcombat", "3 c 'primary weave'")
equal(Combat.duringCombatAction, "c 'primary weave'", "actual alias configures action")
equal(Combat.duringCombatActionRoundInterval, 3, "actual alias configures interval")
equal(Combat.combatRoundsSinceDuringCombatAction, 0, "accepted edit starts a fresh interval")
alias("duringcombat", "off")
equal(Combat.duringCombatAction, "", "off disables action")
equal(Combat.duringCombatActionRoundInterval, 3, "off retains interval preference")
sent = {}
round()
commands("", "off stops periodic commands")

-- Explicit on-kill behavior is unchanged, including user duplicates while
-- other opponents remain. Generic immediate support does not guess from 'c'.
setup("kick", 2)
Combat:attack("troll")
sent = {}
round()
alias("pka", "c 'on-kill weave';stand")
alias("pka", "c 'on-kill weave';stand")
Combat:onKill(5)
commands("c 'on-kill weave',stand,c 'on-kill weave',stand", "on-kill queue keeps duplicates and order")
equal(Combat.state, Combat.states.engaged, "post-kill is not after-combat")
equal(Combat.combatRoundsSinceDuringCombatAction, 1, "user queue does not alter cadence")
round()
equal(sent[#sent], "kick", "round action still due after on-kill work")
sent = {}
Leveling.handleAction("c 'immediate weave';climb")
commands("c 'immediate weave',climb", "generic immediate helper does not classify c as maintenance")
equal(#Combat.postKillActions, 0, "immediate helper does not silently enqueue commands")

-- Real help/status describe the new owner/configuration, not maintenance.
output = {}
alias(nil)
local help = table.concat(output)
assert(help:find("leveling duringcombat", 1, true) and help:find("init", 1, true), "bare leveling help documents tactical configuration")
assert(not help:find("leveling buffs", 1, true), "removed maintenance absent from help")
output = {}
Leveling.printStatus()
local status = table.concat(output)
assert(status:find("Engage combat action", 1, true), "status has engage action")
assert(status:find("During-combat action", 1, true), "status has during action")
assert(status:find("During-combat round interval", 1, true), "status has interval")

-- Upgrade migration preserves the latest configured init action before any
-- initialization can overwrite it, and retains v1 user queue/ignore state.
Leveling.stop()
Leveling.Combat = {version = 1, initAction = "c 'legacy opening'", ignoredMobNames = {"rat"}, postKillActions = {"stand"}}
dofile(root .. "/src/scripts/Combat.lua")
Combat = Leveling.Combat
equal(Combat.engageCombatAction, "c 'legacy opening'", "v1 Combat init migrates")
equal(Combat.initAction, nil, "v1 field removed, not aliased as separate storage")
equal(Combat.ignoredMobNames[1], "rat", "v1 ignores retained")
equal(Combat.postKillActions[1], "stand", "v1 user queue retained")
equal(Combat.duringCombatAction, "", "upgrade leaves round action disabled")
equal(Combat.duringCombatActionRoundInterval, 1, "fresh interval default")
assert(Combat:setDuringCombatAction("kick", 3))
Combat.combatRoundsSinceDuringCombatAction = 2
Combat.pendingTarget = "stale"
Combat.state = Combat.states.engaged
Combat.initAction = "stale legacy copy"
Leveling.initAction = "even older copy"
dofile(root .. "/src/scripts/Combat.lua")
equal(Leveling.Combat, Combat, "same Combat owner on reload")
equal(Combat.engageCombatAction, "c 'legacy opening'", "canonical action takes precedence on reload")
equal(Combat.initAction, nil, "stale v1 field discarded")
equal(Leveling.initAction, nil, "stale root field discarded")
equal(Combat.duringCombatAction, "kick", "reload retains valid during configuration")
equal(Combat.duringCombatActionRoundInterval, 3, "reload retains interval configuration")
equal(Combat.combatRoundsSinceDuringCombatAction, 0, "reload clears transient round count")
equal(Combat.pendingTarget, nil, "reload clears uncertain target")
Leveling.Combat = nil
Leveling.initAction = "bash;kill"
dofile(root .. "/src/scripts/Combat.lua")
equal(Leveling.Combat.engageCombatAction, "bash;kill", "pre-extraction root init migrates")
equal(Leveling.initAction, nil, "pre-extraction owner removed")
equal(BuffManager, personal, "all tactical configuration leaves personal manager untouched")

print("Combat rounds A-K, migration, aliases, literal/templates, multi-opponent cadence, and stop checks passed")
