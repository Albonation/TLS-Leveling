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
- `duringCombatActionDue`: one configured interval has been reached, but no automatic action has yet been safely sent.
- `duringCombatActionAwaitingCombatContinuation`: a kill occurred after the action became due, so the next prompt cannot establish whether combat ended.

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

The handler ignores events unless both the session is running and Combat is engaged. Otherwise it increments the completed-round counter. With no configured action it sends nothing. Before the interval is reached it sends nothing. At the interval, it resets the counter to zero and sets `duringCombatActionDue`; it **never sends the action**. A dedicated inactive-by-default `Combat Prompt` trigger recognizes the existing `[TLSLVL]` substring and delegates only to `Leveling.Combat:onPrompt()`.

In the normal case, that prompt arrives after all consequences of the due round have printed. If Combat is still engaged, the session is running, the action remains due, and no post-due kill ambiguity exists, `onPrompt()` sends exactly one action and clears due before sending. Repeated prompts cannot repeat it. Interval 2 therefore normally releases after summaries 2, 4, 6, etc., but release is intentionally later than recognition of those summaries.

If a kill occurs after the action becomes due, `onKill()` preserves all existing statistics, user post-kill work, rescan behavior, engagement, and cadence, while setting `duringCombatActionAwaitingCombatContinuation`. The immediately following prompt cannot release the automatic action. This prevents the live sequence `round summary → action → death → You aren't fighting anyone.` A later completed combat round is sufficient positive evidence that another fight round occurred and clears this ambiguity. If another kill follows that evidence before its prompt, ambiguity is set again. No opponent count, room guess, or timer is involved.

While an action is due, subsequent completed rounds keep exactly that one due action. They do not increment the counter or enqueue additional uses; their only special effect is proving continuation after a post-due kill. Once the prompt successfully releases the action, the next round begins a fresh interval from zero. This retains the normal interval cadence while preventing catch-up bursts after a delayed release.

An idle-to-attack transition starts a fresh interval and clears due/ambiguity from any prior engagement. Selecting another target while Combat remains engaged does not. Configure/reset/stop/flee/reload and explicit round-action configuration changes clear the counter, due, and ambiguity. **An individual kill never resets the ongoing cadence or due action.** The existing Combat `idle` state is an orchestration state, not proof that the MUD has no remaining opponents.

## Targets and multi-opponent uncertainty

A during-combat action without `{target}` is sent literally, without an appended target or semicolon splitting. Exactly one action is supported, not a rotation. The MUD/user's chosen command determines whether an implicit opponent is meaningful.

An action containing `{target}` substitutes the current `Combat.pendingTarget` attack keyword **at prompt release time**, with no target snapshot or second cache. Kill, target-unavailable, still-fighting uncertainty, and reset clear that known target. If it is unavailable, the prompt keeps the single action due and sends nothing; debug mode explains why. Once an attack establishes a fresh known target, a subsequent round proves continuation and its prompt can release the action using that new target. The original/dead target is never emitted, and skipped opportunities never create catch-up copies or timers. Literal actions use the same prompt/ambiguity boundary without needing a target.

Kills retain engagement and round cadence while invalidating the possibly dead target. Literal actions can therefore continue through auto-aggro/multi-opponent combat, while targeted actions wait for safe target knowledge. The existing post-kill look, still-fighting pause, resting-description behavior, target order, and movement rejection/retry remain unchanged. In particular, an empty configured-target scan is not repurposed as proof of combat ending.

User post-kill commands remain FIFO, preserve duplicates, and run on each individual kill even when opponents remain. **On-kill is not after-combat.** Future `afterCombatActions` require a reliable MUD-authoritative combat-ended event; neither experience received nor a scan without configured mobs is sufficient. No such hook is implemented here.

## Profile compatibility findings

Read-only searches of the saved Agamemnon, Suncutter, Zintruvius, and Kakarot TLS XML profiles found `Leveling.setInit` callers in installed Leveling aliases, legacy `initAction` usage in installed scripts, and old maintenance consumers. Zintruvius includes both TLS-Misc and TLS-Leveling scripts named/global `BuffManager`; the new package neither adopts nor overwrites that global. The sampled saved copies did not expose callers of the just-added namespaced manager or `leveling buffs` command. No historical channeler combat-log search was required or performed for this pass.

Personal maintenance remains independent and may continue issuing its own commands after TLS-Leveling stops. No profile file, personal trigger, or TLS-Misc source was modified. If a custom integration calls removed maintenance APIs, update that integration separately; do not silently reinterpret it as a tactical action.

## Regression coverage and verification

`tests/combat_rounds.lua` covers the original A–K tactical configuration/cadence behavior plus due/prompt A–L: interval becomes due without sending; single prompt release and duplicate-prompt suppression; kill-after-due ambiguity; later-round continuation; cadence across ordinary multi-opponent kills; non-accumulating due rounds; stop/flee/reset/new-engagement cleanup; release-time target change; literal release; and stopped-session guards. It exercises the real alias, round, and prompt adapters, skipped-target recovery without queued copies, explicit disable/reconfigure, v1/root migration, reload preservation, on-kill duplicates, generic immediate actions, removal cleanup, and foreign-global isolation.

The six non-buff suites remain: alias commands, AreaRepository, bloodlord live output, Combat lifecycle, Navigator lifecycle, and RoomScanner live output. Their area/target/recovery assertions remain intact; obsolete maintenance fixtures and old authoritative-field expectations were updated. The buff-only suite was removed. CI continues to run every `tests/*.lua` under Lua 5.1 before the unchanged Muddler build/upload.

Local verification passed: all seven suites under native Lua 5.1.5; Lua 5.1 parsing of 33 authored Lua files; four valid JSON metadata files including `mfile`; positive/negative round-regex and alias-reachability checks; Muddler 1.1.0 build and generated XML adapter/lifecycle checks; no unintended top-level globals; and `git diff --check`. Navigator, RoomScanner, AreaRepository, movement/group adapters, and Stats calculation/reporting functions were checked unchanged. The updated CI has not been executed on GitHub during this local pass.

Live checks should use a valid route starting room and `[TLSLVL]` prompt: (1) reach an interval on a non-kill round and confirm the action appears only after its prompt; (2) make the due round kill the final opponent and confirm its immediate prompt sends nothing; (3) make a due round kill one opponent while combat continues, then confirm the later round and prompt release exactly once; (4) repeat with `{target}` and confirm the replacement opponent's keyword is used; (5) stop after the due summary but before its prompt and confirm silence. No live MUD actions were issued during implementation.

## Recommended next pass

Reload/session consistency should come before Stats correctness/extraction. The new round trigger is locally gated/reset correctly, but the broader existing reload paths still independently retain session selection and reset navigation, capture, and engagement. Coordinating those owners is now more important with additional automatic tactical actions. Stats remains unchanged and should follow as its own focused correctness/extraction pass. Neither follow-up is implemented here.
