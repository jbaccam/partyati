# Facility objective prototype — September 9, 2026

This pass furnishes the remaining map and adds server-owned cooperative objective logic. It is not the completed round/monster game. No DataStores, currency or wins are awarded. User requested manual testing; no playtests or multiplayer checks were run for this pass.

## Six power sectors

| Generator | Served rooms / corridor circuits |
| --- | --- |
| G01 | Medical, residential, northwest main hall |
| G02 | Administration, reception, security, southeast main hall |
| G03 | Library, cafeteria/kitchen, northeast main hall |
| G04 | Storage, records alcove, southwest main hall |
| G05 | Washrooms, pumps, drainage tunnels, western basement hall |
| G06 | Generator hall, electrical alcove, north/south/east basement halls, both stairs |

Generators start on. Restoration requires a three-second nearby interaction. Essential power restoration does not consume a finite fuse supply, preventing permanent soft locks. Occasional fixture flickers are visual dips, not full-sector outages.

`ServerStorage.FacilitySabotageSector:Invoke(player, sectorNumber)` is a **server-only integration point**, created in play. It requires the server-assigned `FacilityRole == "Initiator"`, a living nearby player, an active generator, a 45-second cooldown and at most three uses per player per session. It records sector/time evidence. There is no client-accessible sabotage remote or role assignment in this pass. The eventual round controller must own role assignment and reset charges/state per round.

## Five three-stage escape routes

| Route | Stage 1 | Stage 2 | Stage 3 |
| --- | --- | --- | --- |
| Front entrance | Find storage key in administration; unlock stores | Find bolt cutters in storage; cut entrance chain | Restore G02 if needed and release security latch |
| Bathroom maintenance | Replace pump valve from pump-room cabinet; power G05 | Use bolt cutters on women's bathroom manhole | Follow maintenance tunnel to outfall |
| Courtyard well | Cut well-grate fastenings | Restore drainage pump / G05 | Descend and reach courtyard outfall |
| Staff emergency | Find screwdriver in storage; open administration staff vent | Retrieve staff badge from enclosed staff office | Use badge at security's east emergency exit |
| Police response | Repair security relay with a radio relay; power G02 | Call from reception phone | Survive 90 powered seconds and return to phone |

Hatches and staff vent use bounded server-controlled transitions to explicitly modeled destinations. These are not seamless first-person crawl animations. Gates have physical apertures and collision leaves. Escape marks the player's session state and moves them to the front safe approach.

The phone sets `ObjectiveState.AlarmActive`, `PoliceHoldoutActive` and `PoliceHoldoutRemaining`. **Monster spawning/pursuit and visible police responders are not implemented.** The holdout clock pauses during G02 outages. This is a timer/objective integration hook, not evidence that an AI holdout has been implemented or tested.

## Search and concealment

Drawers, cabinets, utility racks, pantry supplies and medical trays contain search prompts. Designated tools are deterministic for review; empty compartments contain flavor feedback. Searches/inventory ownership, capacity, cooldowns, hold time, health, proximity and wall occlusion are handled on the server. Search state is per-player for this prototype, not the final scarce shared-loot round system.

Medical/residential beds have hide/leave interactions and server-owned `FacilityHidden` state. Enemy perception must still consume that state. Generator/pump fences have 3.15-stud low service openings and separate full-height routes. Existing movement remains the sprint baseline: a full sprint-slide/vault/stamina controller and camera bobbing are **not** part of this pass.

## Manual review still needed

- Actual client traversal: stair headroom, restored upper landings, doorway collision, all room and cage loops.
- Nighttime powered visibility, flicker and outages, wall occlusion on different graphics settings.
- Each escape route end-to-end, invalid/remote prompt activation, inventory ownership and respawn behavior.
- Multi-client generator repair/sabotage concurrency, role assignment, holdout timing and shared escape progress.
- Imported bed/stove availability and appearance on a published client; static source packaging does not prove delivery permissions.
- Performance/mobile budgets; this detailed kit is not yet mesh-consolidated or profiled.

Previous hallway geometry and replaced room blockout props remain in named ServerStorage backup folders. Unrelated Studio content and the root CopyTheScene project are untouched.
