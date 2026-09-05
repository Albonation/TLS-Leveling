# TLS-Leveling

TLS-Leveling is a Mudlet package for automating leveling in The Last Sunrise. It follows a configured route one room at a time, recognizes eligible mobs in room output, initiates combat, performs configured tactical actions, and records kill and experience statistics. Persistent character/buff maintenance is not this package's responsibility.

## Installation and usage

Install the latest release from Mudlet with:

```lua
installPackage("https://github.com/Albonation/TLS-Leveling/releases/latest/download/TLS-Leveling.mpackage")
```

After installation, `leveling help` shows the available commands. Common commands include:

- `leveling` — show package help.
- `leveling start <area>` — start the selected route.
- `leveling stop` — stop navigation and combat automation.
- `leveling engage <action>` — set the engage action; `leveling init <action>` remains supported.
- `leveling duringcombat <rounds> <action>` — configure one tactical action at a positive integer round interval.
- `leveling duringcombat off` — disable the round action.
- `leveling pka <action>` — queue an action for the next individual kill, not the end of combat.
- `leveling setprompt` — configure the recommended TLS-Leveling prompt.
- `leveling areas` — list configured areas.
- `leveling status` — show engage action, during-combat action, and round interval.
- `leveling stats` — show current-session and total statistics.
- `leveling update` — install the latest released package.

Before starting a route, run:

```text
leveling setprompt
```

This sends `prompt <%h/%H hp %e/%E end> [TLSLVL]`. TLS-Leveling requires the literal `[TLSLVL]` marker somewhere in the player's MUD prompt so RoomScanner can recognize the end of command output. You may use any other prompt format as long as that marker remains present; TLS adds its own stance and status flags separately.

### Tactical action configuration

Ownership follows why an action runs, not whether it is a skill, weave, potion, or ordinary command. Engage actions, periodic combat actions, and on-kill actions belong to Combat. Keeping a character effect active belongs to separate character-maintenance automation. The previous maintenance commands (`buffs`, `haste`, `sanc`, `detects`, `fury`) and their triggers have been removed; nothing was moved into TLS-Misc or changed in personal profiles.

```text
leveling init bash;kill
leveling engage c 'opening weave'
leveling duringcombat 1 c 'primary weave'
leveling duringcombat 2 c 'targeted weave' {target}
leveling duringcombat off
```

The weave names above illustrate configuration syntax, not verified spell availability. Choose commands your character can actually use. Engage keeps its existing behavior: append the selected attack keyword to every semicolon-separated command. The during-combat configuration is one command sent literally, except that `{target}` is expanded only when a current target is known. It is not a rotation or a semicolon-splitting command sequence. After a kill or other target invalidation, template-dependent uses are skipped until a fresh known target and a subsequent round summary are available; literal actions can continue.

Intervals count the specified MUD `You hit <number> times for an average <number> damage.` summaries while leveling is running and Combat is engaged. No casting timers are used. Interval 2 issues one action on rounds 2, 4, 6, and so on. An individual kill does not reset the interval or imply combat ended. Stop clears the transient counter and disables the round trigger while preserving tactical configuration. See [combat actions and round policy](docs/combat-actions.md) for migration, targeting, and test details.

## Tooling and source layout

The package is written in Lua for [Mudlet](https://www.mudlet.org/) and assembled with [Muddler](https://github.com/demonnic/muddler). The root `mfile` contains package metadata. The JSON files alongside each source group define the Mudlet items included in the generated package.

- `src/aliases` contains user-command entry points and `aliases.json`.
- `src/scripts` contains the `Leveling` runtime and statistics, extracted `AreaRepository`, `Navigator`, `RoomScanner`, and `Combat` components, plus `scripts.json`.
- `src/scripts/AreaRepository.lua` holds all static area names, routes, mob definitions, and start/help descriptions.
- `src/triggers` contains MUD-output recognizers and `triggers.json`.
- `.github/workflows/main.yml` runs every Lua regression suite under Lua 5.1 before the unchanged Muddler build in CI.
- `build/` contains generated package artifacts when a build has been run; it is not the source of truth.

## Current architecture

The main `Leveling` table owns the active session. Its state is grouped conceptually as:

- Configuration: debug mode; tactical action configuration belongs to Combat.
- Session selection: `currentAreaName` is the configured area key; `currentArea` is the corresponding area table.
- Statistics: the current session and totals across completed route loops.

`Leveling.AreaRepository` owns the static definitions for Drones, KoreSprings, and TrollocCamp. `get(areaName)` returns a shared definition or `nil`; `list()` returns the shared name-to-definition table. Callers treat these values as read-only. Leveling performs area selection and passes the configured data to the runtime components. The old `Leveling.areas` field is cleared on script reload; internal callers use the repository accessors. `leveling areas` retains its existing `pairs()` iteration and output, with no guaranteed alphabetical ordering.

`Leveling.Navigator` is the sole owner of the copied active route, the index of the next unconfirmed step, the pending command, deferred-retry state, pause reason, and movement-attempt identity. Its explicit `idle` / `ready` / `moving` / `paused` states prevent repeated step initiation and stale movement callbacks. Navigator chooses and sends movement commands, requests the resulting scan through RoomScanner's public API, detects route completion, and hands completion back to `Leveling` for statistics and session looping. It does not select areas, restore buffs, select mobs, initiate combat, maintain ignores, or record statistics.

`Leveling.RoomScanner` holds the mob definitions supplied for its current scan configuration and owns temporary captured mobs, its delayed post-kill look timer, the three room-capture trigger names, and an explicit `idle` / `waiting-for-start` / `capturing` lifecycle. Its optional scan-start callback lets the requester associate a room response with one exact movement attempt; RoomScanner does not manipulate navigation state.

`Leveling.Combat` owns target selection from completed room snapshots, ignore filtering, `engageCombatAction`, `duringCombatAction`, `duringCombatActionRoundInterval`, the transient `combatRoundsSinceDuringCombatAction` counter, pending target and `idle` / `engaged` state, post-kill actions, and interpretation of round, kill, still-fighting, target-unavailable, and flee events. `leveling init`, `Leveling.setInit`, and `Combat:setInit` remain compatibility boundaries for the single authoritative engage configuration. Old init fields migrate and are removed rather than kept as independent copies. Combat does not capture room output, manipulate route state, or store statistics. It calls the narrow `Leveling.recordKill()` handoff for statistics and uses only RoomScanner and Navigator public methods for rescans and pauses.

The primary leveling flow is:

```text
Leveling session
    ↓
Leveling.Navigator
    ↓
movement command
    ↓
`[Exits: ...]` starts capture
    ↓
Leveling.RoomScanner
    ↓
mob lines are collected
    ↓
prompt containing `[TLSLVL]` completes capture
    ↓
completed room contents
    ↓
Leveling.Combat target decision
    ↓
combat command or next navigation step
    ↓
kill event → Leveling statistics + Combat post-kill actions
    ↓
RoomScanner delayed look/rescan
    ↓
Combat again or Navigator
```

User input follows this flow:

```text
User command
    ↓
Mudlet alias
    ↓
Leveling command/function
```

Starting an area remains a `Leveling` session responsibility. It resolves the definition through `AreaRepository:get()`, sets `currentAreaName`/`currentArea`, configures RoomScanner and Combat with the unchanged `allowed_mobs` entries, passes only `dirs` to Navigator, and requests the first step through the compatibility `Leveling.processStep()` wrapper. That wrapper guards stopped sessions and delegates route mechanics to Navigator; no character maintenance runs before movement. Script load order is Leveling, AreaRepository, RoomScanner, Navigator, then Combat; Leveling's immediate initialization does not perform an area lookup.

Navigator arms RoomScanner with a callback tied to the current movement-attempt number, then sends the selected route step. The `[Exits: ...]` trigger is the existing success signal: RoomScanner accepts it, Navigator advances its route index exactly once, and RoomScanner begins capture. Matching mob lines are collected until any prompt line containing the literal `[TLSLVL]` sentinel fires the finish trigger. RoomScanner deliberately ignores all surrounding prompt formatting. A movement failure keeps the same index and pauses with a deferred retry; as before, no movement retry timer exists, and the next combat/room progression signal requests the retry. Cancellation removes RoomScanner's callback and increments the attempt number, so an old callback cannot advance a stopped or replaced route. Combat and group-hold triggers pause Navigator and cancel the incomplete scan without sending another movement command.

The `[TLSLVL]` prompt-sentinel trigger finalizes one completed mob list. RoomScanner returns to idle before handing that list through `Leveling.handleRoomScanComplete()` to Combat, which attacks the last eligible captured occupant or advances the route when none remain. Duplicate attack keywords are retained because multiple actual occupants may share one keyword. Without the sentinel, RoomScanner intentionally remains in capture because it cannot safely infer where arbitrary prompt output ends. After the final confirmed step has been scanned and cleared, Navigator reports completion once through `Leveling.handleRouteComplete()`. Leveling preserves the existing status output, increments the completed-run statistic, and reloads the same area. Combat's ignore list persists across those same-area loops and resets only when a different area is selected or leveling stops.

Each experience line is a kill event, not proof that combat has ended. Combat records that event through Leveling, consumes queued post-kill actions, and asks RoomScanner for the existing delayed `look`. Additional enemies may have joined the same fight without another attack command. If the rescan sees a mob `fighting YOU!`, Combat keeps its engaged state and asks Navigator to pause, which cancels that scan and prevents movement. Later experience events repeat the statistics/look lifecycle until a completed clear-room scan lets Combat resume navigation. Stopping disables room and combat triggers, cancels the look timer, and clears transient state; cancelling a scan affects only RoomScanner's lifecycle.

The key development principle is:

> Triggers recognize MUD output. Aliases recognize user input. Lua modules/functions decide what that input means and what the package should do.

## Architectural direction

Refactoring should remain incremental and preserve Mudlet-facing behavior. Recommended next work, in priority order, is:

1. Reload/session consistency: coordinate retained session state with reset navigation, capture, engagement, and trigger state before extending automatic actions further.
2. Stats correctness/extraction, as a separate focused pass without mixing arithmetic changes into combat lifecycle work.
3. Trigger lifecycle cleanup and `Commands` only if concrete complexity warrants them; no general framework is assumed necessary.

AreaRepository, RoomScanner, Navigator, and Combat are now extracted components. The remaining names describe architectural direction, not components that already exist. `Leveling.processStep()`, `Leveling.redoLastStep()`, and the previous combat entry points remain as compatibility wrappers; they do not own duplicate subsystem state or logic. Prefer small tables and functions over framework or class layers.

Combat-specific triggers, including the round-complete trigger, follow the Combat start/reset lifecycle. Death, group-hold, and other utility trigger lifecycles remain unchanged. Future `afterCombatActions` would require a reliable MUD-authoritative combat-ended boundary: neither an experience line nor a scan without configured mobs supplies one. No after-combat hook is implemented here; existing movement-attempt/rejection/retry behavior remains authoritative.

## Contributing

Treat the JSON metadata as part of each alias, script, or trigger change: a Lua file that is not named by its group metadata is not included in the generated Mudlet package. Preserve trigger names used by `enableTrigger` and `disableTrigger`, and verify them against `triggers.json`. Routes, mob descriptions, trigger patterns, and user-visible commands are behavior-sensitive and should not be changed incidentally.
