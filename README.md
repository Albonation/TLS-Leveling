# TLS-Leveling

TLS-Leveling is a Mudlet package for automating leveling in The Last Sunrise. It follows a configured route one room at a time, recognizes eligible mobs in room output, initiates combat, restores configured buffs, and records kill and experience statistics.

## Installation and usage

Install the latest release from Mudlet with:

```lua
installPackage("https://github.com/Albonation/TLS-Leveling/releases/latest/download/TLS-Leveling.mpackage")
```

After installation, `leveling help` shows the available commands. Common commands include:

- `leveling` — show package help.
- `leveling start <area>` — start the selected route.
- `leveling stop` — stop navigation and combat automation.
- `leveling setprompt` — configure the recommended TLS-Leveling prompt.
- `leveling areas` — list configured areas.
- `leveling status` — show configured combat and buff actions.
- `leveling stats` — show current-session and total statistics.
- `leveling update` — install the latest released package.

Before starting a route, run:

```text
leveling setprompt
```

This sends `prompt <%h/%H hp %e/%E end> [TLSLVL]`. TLS-Leveling requires the literal `[TLSLVL]` marker somewhere in the player's MUD prompt so RoomScanner can recognize the end of command output. You may use any other prompt format as long as that marker remains present; TLS adds its own stance and status flags separately.

## Tooling and source layout

The package is written in Lua for [Mudlet](https://www.mudlet.org/) and assembled with [Muddler](https://github.com/demonnic/muddler). The root `mfile` contains package metadata. The JSON files alongside each source group define the Mudlet items included in the generated package.

- `src/aliases` contains user-command entry points and `aliases.json`.
- `src/scripts` contains the `Leveling` runtime, extracted `Navigator` and `RoomScanner` components, area definitions, statistics, and `BuffManager`, plus `scripts.json`.
- `src/triggers` contains MUD-output recognizers and `triggers.json`.
- `.github/workflows/main.yml` runs the repository's Muddler build in CI.
- `build/` contains generated package artifacts when a build has been run; it is not the source of truth.

## Current architecture

The main `Leveling` table owns the active session. Its state is grouped conceptually as:

- Configuration: debug mode and the init, haste, fury, sanctuary, and detects actions.
- Session selection: `currentAreaName` is the configured area key; `currentArea` is the corresponding area table.
- Combat: ignored attack keywords and post-kill actions.
- Statistics: the current session and totals across completed route loops.

`Leveling.Navigator` is the sole owner of the copied active route, the index of the next unconfirmed step, the pending command, deferred-retry state, pause reason, and movement-attempt identity. Its explicit `idle` / `ready` / `moving` / `paused` states prevent repeated step initiation and stale movement callbacks. Navigator chooses and sends movement commands, requests the resulting scan through RoomScanner's public API, detects route completion, and hands completion back to `Leveling` for statistics and session looping. It does not select areas, restore buffs, select mobs, initiate combat, maintain ignores, or record statistics.

`Leveling.RoomScanner` owns the current area's mob definitions, temporary captured mobs, its delayed post-kill look timer, the three room-capture trigger names, and an explicit `idle` / `waiting-for-start` / `capturing` lifecycle. Its optional scan-start callback lets the requester associate a room response with one exact movement attempt; RoomScanner does not manipulate navigation state. `BuffManager` separately owns known buff state and the commands used to restore missing buffs. Area definitions currently remain in `Leveling.lua`; no repository layer has been introduced yet.

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
Leveling combat decision (future Combat component)
    ↓
Mudlet command or next navigation step
```

User input follows this flow:

```text
User command
    ↓
Mudlet alias
    ↓
Leveling command/function
```

Starting an area remains a `Leveling` session responsibility. It resolves the area definition, configures RoomScanner with the unchanged `allowed_mobs` entries, passes only `dirs` to Navigator, and requests the first step through the compatibility `Leveling.processStep()` wrapper. That wrapper retains the pre-movement BuffManager call, while Navigator owns all route mechanics.

Navigator arms RoomScanner with a callback tied to the current movement-attempt number, then sends the selected route step. The `[Exits: ...]` trigger is the existing success signal: RoomScanner accepts it, Navigator advances its route index exactly once, and RoomScanner begins capture. Matching mob lines are collected until any prompt line containing the literal `[TLSLVL]` sentinel fires the finish trigger. RoomScanner deliberately ignores all surrounding prompt formatting. A movement failure keeps the same index and pauses with a deferred retry; as before, no movement retry timer exists, and the next combat/room progression signal requests the retry. Cancellation removes RoomScanner's callback and increments the attempt number, so an old callback cannot advance a stopped or replaced route. Combat and group-hold triggers pause Navigator and cancel the incomplete scan without sending another movement command.

The `[TLSLVL]` prompt-sentinel trigger finalizes one completed mob list. RoomScanner returns to idle before handing that list to `Leveling.handleRoomScanComplete()`, where existing combat logic attacks an eligible mob or advances the route. Without the sentinel, RoomScanner intentionally remains in capture because it cannot safely infer where arbitrary prompt output ends. After the final confirmed step has been scanned and cleared, Navigator reports completion once through `Leveling.handleRouteComplete()`. Leveling preserves the existing status output, increments the completed-run statistic, and reloads the same area. The ignore list persists across those same-area loops and resets only when a different area is selected or leveling stops.

After a kill, RoomScanner owns the delayed `look` and arms the same capture lifecycle. Cancelling or stopping disables all three room triggers, cancels that timer, clears partial capture data, and returns the scanner to idle. A repeated scan request safely replaces an incomplete scan; unexpected line or end events cannot add persistent room data.

The key development principle is:

> Triggers recognize MUD output. Aliases recognize user input. Lua modules/functions decide what that input means and what the package should do.

## Architectural direction

Refactoring should remain incremental and preserve Mudlet-facing behavior. Likely future extractions, in current priority order, are:

1. `Combat`, to own completed-room consumption, target selection, ignore rules, initiation, and post-kill actions.
2. `TriggerManager`, to make non-room initial and running trigger states explicit.
3. `Stats`, `AreaRepository`, and `Commands` as their responsibilities grow.

RoomScanner and Navigator are now extracted components. The remaining names describe architectural direction, not components that already exist. `Leveling.processStep()` and `Leveling.redoLastStep()` remain as compatibility wrappers; they do not own duplicate navigation state or logic. Prefer small tables and functions over framework or class layers.

Some non-room triggers still intentionally rely on Muddler's default active state rather than the `Leveling` start/stop lifecycle. These include death, still-fighting/group-hold, buff, and utility triggers. Their intended profile-wide behavior is not yet explicit, so this pass retains it; a future trigger-lifecycle refactor should classify each one before changing when it runs.

## Contributing

Treat the JSON metadata as part of each alias, script, or trigger change: a Lua file that is not named by its group metadata is not included in the generated Mudlet package. Preserve trigger names used by `enableTrigger` and `disableTrigger`, and verify them against `triggers.json`. Routes, mob descriptions, trigger patterns, and user-visible commands are behavior-sensitive and should not be changed incidentally.
