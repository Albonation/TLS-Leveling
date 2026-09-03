# TLS-Leveling

TLS-Leveling is a Mudlet package for automating leveling in The Last Sunrise. It follows a configured route one room at a time, recognizes eligible mobs in room output, initiates combat, restores configured buffs, and records kill and experience statistics.

## Installation and usage

Install the latest release from Mudlet with:

```lua
installPackage("https://github.com/Albonation/TLS-Leveling/releases/latest/download/TLS-Leveling.mpackage")
```

After installation, `leveling help` shows the available commands. Common commands include:

- `leveling start <area>` — start the selected route.
- `leveling stop` — stop navigation and combat automation.
- `leveling areas` — list configured areas.
- `leveling status` — show configured combat and buff actions.
- `leveling stats` — show current-session and total statistics.
- `leveling update` — install the latest released package.

## Tooling and source layout

The package is written in Lua for [Mudlet](https://www.mudlet.org/) and assembled with [Muddler](https://github.com/demonnic/muddler). The root `mfile` contains package metadata. The JSON files alongside each source group define the Mudlet items included in the generated package.

- `src/aliases/TLS-Leveling` contains user-command entry points and `aliases.json`.
- `src/scripts/TLS-Leveling` contains the `Leveling` runtime, area definitions, statistics, and `BuffManager`, plus `scripts.json`.
- `src/triggers/TLS-Leveling` contains MUD-output recognizers and `triggers.json`.
- `.github/workflows/main.yml` runs the repository's Muddler build in CI.
- `build/` contains generated package artifacts when a build has been run; it is not the source of truth.

## Current architecture

The main `Leveling` table owns the active session. Its state is grouped conceptually as:

- Configuration: debug mode and the init, haste, fury, sanctuary, and detects actions.
- Session selection: `currentAreaName` is the configured area key; `currentArea` is the corresponding area table.
- Navigation: `remainingDirections` and `lastDirection`.
- Combat and room parsing: the current area's mob definitions, mobs captured in the current room, ignored attack keywords, and post-kill actions.
- Timers: `lookAfterKillTimerId`, including its cancellation lifecycle.
- Statistics: the current session and totals across completed route loops.

`BuffManager` separately owns known buff state and the commands used to restore missing buffs. Area definitions currently remain in `Leveling.lua`; no repository or module layer has been introduced yet.

MUD output follows this flow:

```text
MUD output
    ↓
Mudlet trigger
    ↓
Leveling or BuffManager handler
    ↓
Owned state and decision logic
    ↓
Mudlet command
```

User input follows this flow:

```text
User command
    ↓
Mudlet alias
    ↓
Leveling command/function
```

Starting an area resolves its name to an area definition, copies the route into runtime navigation state, enables the required triggers, and sends the first movement command. Room triggers collect eligible mobs until the prompt ends the scan. The leveling handler then attacks an eligible mob or advances the route. A kill updates statistics, runs deferred actions, and schedules a new `look`; stopping cancels that timer, clears session state, and disables run-specific triggers.

The key development principle is:

> Triggers recognize MUD output. Aliases recognize user input. Lua modules/functions decide what that input means and what the package should do.

## Architectural direction

Refactoring should remain incremental and preserve Mudlet-facing behavior. Likely future extractions, in current priority order, are:

1. `RoomScanner`, to own the three-trigger room-capture lifecycle and parsed room contents.
2. `Navigator`, to own route copies, last-direction retry behavior, and route completion.
3. `Combat`, to own target selection, ignore rules, initiation, and post-kill actions.
4. `TriggerManager`, to make initial and running trigger states explicit.
5. `Stats`, `BuffManager`, `AreaRepository`, and `Commands` as their responsibilities grow.

These names describe architectural direction, not components that all exist today. Prefer small tables and functions over framework or class layers.

Some triggers still intentionally rely on Muddler's default active state rather than the `Leveling` start/stop lifecycle. These include death, still-fighting/group-hold, buff, and utility triggers. Their intended profile-wide behavior is not yet explicit, so this pass retains it; a future trigger-lifecycle refactor should classify each one before changing when it runs.

## Contributing

Treat the JSON metadata as part of each alias, script, or trigger change: a Lua file that is not named by its group metadata is not included in the generated Mudlet package. Preserve trigger names used by `enableTrigger` and `disableTrigger`, and verify them against `triggers.json`. Routes, mob descriptions, trigger patterns, and user-visible commands are behavior-sensitive and should not be changed incidentally.
