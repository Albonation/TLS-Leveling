# Combat-owned tactical actions

## Ownership and removal

TLS-Leveling performs actions because the leveling/combat lifecycle calls for them. It no longer maintains persistent character buffs. A command's spelling or type does not determine ownership: an opening weave, periodic offensive weave, or on-kill command can all be tactical actions. Keeping Sunburst, quickness, haste, sanctuary, detects, or Fury active belongs to separate maintenance automation.

Removed from this package: the BuffManager script and metadata entry; twelve core maintenance triggers; affects parsing and gagging; the positive buff-response trigger; four optional maintenance triggers; the `buffs`, `haste`, `sanc`, `detects`, and `fury` alias options; maintenance configuration/runtime state and APIs; maintenance help/status and progression hooks; the buff lifecycle suite and buff-reliability document. An upgrade deactivates and drops the old namespaced manager and obsolete package fields. It never changes the unrelated global `BuffManager`, TLS-Misc, or personal `keepSpellsUp` triggers.

The previous buff pass was uncommitted in this checkout when removal began. A recovery snapshot was saved outside the package in `C:/Users/senor/AppData/Local/Temp/tls-leveling-buff-recovery-20260904`: `tracked-changes.patch` plus the then-untracked buff response adapter, lifecycle suite, and reliability document. The patch is relative to the pre-pass Git HEAD; restore in a separate checkout to inspect the previous implementation. No new commit or TLS-Misc implementation was created.

## Configuration and compatibility

Combat owns these fields:

- `engageCombatAction`: the opening command/sequence. Default `kill`.
- `duringCombatAction`: one periodic tactical command. Default empty/disabled.
- `duringCombatActionRoundInterval`: positive integer completed-round interval. Default 1.
- `combatRoundsSinceDuringCombatAction`: transient count since the last periodic use or interval reset.

User syntax:

```text
leveling init bash;kill
leveling engage c 'opening weave'
leveling duringcombat 1 c 'primary weave'
leveling duringcombat 2 c 'targeted weave' {target}
leveling duringcombat off
leveling pka get coins;stand
leveling status
```

Weave names are illustrative, not claims about actual TLS spell names or availability. Warriors can leave the during-combat action disabled. Commands are not classified by a `c` prefix.

`leveling init`, `Leveling.setInit(action)`, and `Leveling.Combat:setInit(action)` delegate to `setEngageCombatAction(action)`. Existing target behavior is unchanged: every semicolon-separated engage command gets the same selected attack keyword appended. Use `;`, not `|`, for those existing sequences. Engage does not introduce `{target}` expansion.

Migration captures existing configuration before initialization. Precedence is an existing canonical `engageCombatAction`, then legacy `Combat.initAction`, then pre-extraction `Leveling.initAction`, then `kill`. Empty engage configuration keeps the existing `kill` default. Legacy fields are cleared; no duplicated configuration or metatable alias is retained. v1 Combat ignore/post-kill state is preserved by the upgrade. Valid during-combat configuration survives stop and script reload, while transient rounds/target state reset. This is not a whole-package reload-consistency redesign or a new disk-persistence mechanism.

The alias accepts `leveling duringcombat <positive whole-number rounds> <nonempty action>`, or `off`. Zero, negative, fractional, missing, or malformed intervals/actions reject the edit without changing the previous configuration or partial interval. A valid edit starts the interval at zero. `off` clears the action and counter, retaining the interval preference. Lua integrations can call `Combat:setDuringCombatAction(action, interval)` or `Combat:disableDuringCombatAction()`.

`Leveling.handleAction(action)` remains a generic immediate semicolon-sequence helper. It no longer guesses timing from the first letter: `c ...` and `climb` are both immediate there. Use `Leveling.addPostKillAction`/`leveling pka` when on-kill timing is intended.

## Round boundary and execution

`Combat Round Complete` starts inactive and is enabled/disabled with the other Combat triggers. Its regex is:

```regex
^>?You hit ([0-9]+) times for an average ([0-9]+(?:\.[0-9]+)?) damage\.\s*$
```

It accepts integer hit counts, integer or decimal average damage, an optional `>` prefix, and trailing whitespace. The adapter contains only:

```lua
Leveling.Combat:onCombatRoundComplete()
```

Only this specified summary boundary counts. Dodge/opponent summaries, experience lines, and alternative zero-hit wording are not additional round signals. Identical summary text in successive rounds is valid and is not deduplicated by text. No timer defines combat cadence.

The handler ignores events unless both the session is running and Combat is engaged. Otherwise it increments the completed-round counter. With no configured action it sends nothing. Before the interval is reached it sends nothing. At the interval, it sends exactly one configured action and resets the counter before sending. Thus interval 2 fires on summaries 2, 4, 6, etc.; other callbacks do not issue additional periodic actions.

An idle-to-attack transition starts a fresh interval. Selecting another target while Combat remains engaged does not. Configure/reset/stop/reload and explicit round-action configuration changes clear the counter. **An individual kill never resets it.** The existing Combat `idle` state is an orchestration state, not proof that the MUD has no remaining opponents.

## Targets and multi-opponent uncertainty

A during-combat action without `{target}` is sent literally, without an appended target or semicolon splitting. Exactly one action is supported, not a rotation. The MUD/user's chosen command determines whether an implicit opponent is meaningful.

An action containing `{target}` substitutes the current `Combat.pendingTarget` attack keyword, with no second target cache. Kill, target-unavailable, still-fighting uncertainty, and reset clear that known target. If it is unavailable, the due use is skipped; debug mode explains why. The counter stays due because no action was sent. Once an attack establishes a fresh known target, only a subsequent summary can issue the action, at most once; skipped opportunities never create catch-up copies or timers.

Kills retain engagement and round cadence while invalidating the possibly dead target. Literal actions can therefore continue through auto-aggro/multi-opponent combat, while targeted actions wait for safe target knowledge. The existing post-kill look, still-fighting pause, resting-description behavior, target order, and movement rejection/retry remain unchanged. In particular, an empty configured-target scan is not repurposed as proof of combat ending.

User post-kill commands remain FIFO, preserve duplicates, and run on each individual kill even when opponents remain. **On-kill is not after-combat.** Future `afterCombatActions` require a reliable MUD-authoritative combat-ended event; neither experience received nor a scan without configured mobs is sufficient. No such hook is implemented here.

## Profile compatibility findings

Read-only searches of the saved Agamemnon, Suncutter, Zintruvius, and Kakarot TLS XML profiles found `Leveling.setInit` callers in installed Leveling aliases, legacy `initAction` usage in installed scripts, and old maintenance consumers. Zintruvius includes both TLS-Misc and TLS-Leveling scripts named/global `BuffManager`; the new package neither adopts nor overwrites that global. The sampled saved copies did not expose callers of the just-added namespaced manager or `leveling buffs` command. No historical channeler combat-log search was required or performed for this pass.

Personal maintenance remains independent and may continue issuing its own commands after TLS-Leveling stops. No profile file, personal trigger, or TLS-Misc source was modified. If a custom integration calls removed maintenance APIs, update that integration separately; do not silently reinterpret it as a tactical action.

## Regression coverage and verification

`tests/combat_rounds.lua` covers A–K: engage compatibility; unset action; intervals 1 and 2; fresh engagement reset; continuing multi-opponent cadence across kills; stop and idle guards; safe target expansion; literal commands; and atomic invalid-interval rejection. It also exercises the real alias/round adapters, skipped-target recovery without queued copies, explicit disable/reconfigure, v1/root migration, reload preservation, on-kill duplicates, generic immediate actions, removal cleanup, and foreign-global isolation.

The six non-buff suites remain: alias commands, AreaRepository, bloodlord live output, Combat lifecycle, Navigator lifecycle, and RoomScanner live output. Their area/target/recovery assertions remain intact; obsolete maintenance fixtures and old authoritative-field expectations were updated. The buff-only suite was removed. CI continues to run every `tests/*.lua` under Lua 5.1 before the unchanged Muddler build/upload.

Local verification passed: all seven suites under native Lua 5.1.5; Lua 5.1 parsing of 33 authored Lua files; four valid JSON metadata files including `mfile`; positive/negative round-regex and alias-reachability checks; Muddler 1.1.0 build and generated XML adapter/lifecycle checks; no unintended top-level globals; and `git diff --check`. Navigator, RoomScanner, AreaRepository, movement/group adapters, and Stats calculation/reporting functions were checked unchanged. The updated CI has not been executed on GitHub during this local pass.

Live checks should use a valid route starting room and `[TLSLVL]` prompt: confirm legacy init behavior; verify interval 1 and interval 2 on actual matching summaries; keep fighting through an individual kill and check cadence; repeat with a `{target}` action and confirm no dead-target fallback; stop mid-interval and confirm silence from the package. No live MUD actions were issued during implementation.

## Recommended next pass

Reload/session consistency should come before Stats correctness/extraction. The new round trigger is locally gated/reset correctly, but the broader existing reload paths still independently retain session selection and reset navigation, capture, and engagement. Coordinating those owners is now more important with additional automatic tactical actions. Stats remains unchanged and should follow as its own focused correctness/extraction pass. Neither follow-up is implemented here.
