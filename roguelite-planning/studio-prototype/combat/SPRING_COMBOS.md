# Spring, combinations and overhead emphasis � September 23, 2026

This supersedes the earlier rapid melee timeline in WEAPON_BEHAVIOR_PASS.md.

## Extended reach for every downward weapon

The 25% Downward reach bonus now applies to all weapons using overhead combinations: pan, spatula, bat, cinder block, shovel, paint roller and Mjolnir. Matching timing and the longer grip sweep were already shared. Non-hybrid melee target acquisition now searches the extended range and selects Downward for targets outside ordinary swing range; close combinations are unchanged. Mjolnir retains its existing melee/throw selection. Horizontal/diagonal reach, cooldowns and damage are unchanged.

- Actual Studio Play: pan/spatula hit at 7.2 studs (new reach 7.5), bat/shovel at 9.6 (reach 10), block at 8.4 (reach 8.75), roller at 10.8 (reach 11.25). Each reported Downward at rate 1.8 and registered multiple contacts.
- All six equipped together rejected a target at twelve studs: no new attacks or damage. Runtime console was empty.
- SpringComboTests: 15,069 checks passed, including the range multiplier across base ranges and preserved close combinations. WeaponBehaviorTests: 19,905 passed. Both Rojo builds passed; final motion/server Edit sources matched the repository. Backups: ServerStorage.BeforeAllOverheadReach_20260923. Multiple real clients and latency were not tested.

## Matching swing rhythm and advancing overheads

This correction supersedes the slower overhead timing described below. All melee styles now share the 0.12 preparation / 0.46 strike-end / 0.90 recovery-end clock, without the previous 0.58 downward speed multiplier. At the usual 1.8 animation rate, horizontal, diagonal and downward motions each take 0.50 seconds (overheads previously took about 0.86). Weapon cooldowns and damage remain unchanged.

The overhead grip starts closer to the wielder and advances up to four studs, with the same modest hand-height change and handle-driven head arc. Mjolnir alone gets 25% more melee reach for Downward: ten base studs instead of eight, scaled by the normal range stat. The server selects the stroke before resolving melee versus throw, applies the same reach to hit validation and replicates it to the client. Horizontal/diagonal hammer reach stays eight; farther targets still trigger throws. Its corrected striking-face orientation and gentle flight rocking are retained.

- Actual Studio Play at five studs: horizontal, diagonal and downward reported rate 1.8 and full duration 0.50 seconds; all landed hits. Observed intervals remained about 2.4 seconds.
- At 9.5 studs, both mirrored downward attacks remained melee and landed hits. Rendered grip samples advanced from 4.07 to 8.06 studs relative to the attack root, while the head swept forward through the target. Horizontal/diagonal selections threw instead.
- At eleven studs, every style selected a ranged throw, including Downward. Runtime console was empty.
- SpringComboTests: 14,678 checks; WeaponBehaviorTests: 19,905; MeleeMotionTests: 20,024; WeaponFollowTests: 834 passed. Both Rojo packages built successfully. Final motion/server sources were verified against Edit. Backups: ServerStorage.BeforeOverheadRhythm_20260923. Multiplayer and latency scenarios remain untested.

## Mjolnir flight and striking-face correction

This later correction supersedes the fixed-orientation flight notes below. Mjolnir keeps its straight flight path and launch heading across the return, but now rocks and banks within small limits (9 degrees pitch, 5 yaw, 7 bank), smoothly introduced after launch. It does not accumulate a full spin. The downward grip turns 90 degrees around the handle so the modeled local +X end face leads the strike instead of the broad side panel. Server hit sampling and rendered melee use the same corrected pose. Other weapons and Mjolnir cooldown/damage are unchanged.

- SpringComboTests: 14,663 checks passed, including bounded, continuous flight rocking and leading hammer-face alignment for both overhead sides. WeaponBehaviorTests: 19,905 passed.
- Actual Studio Play: 64 flying-model samples across three returns showed up to 11.33 degrees of motion from the first sampled orientation. Both mirrored downward hammer strikes landed hits; 17 rendered strike samples had minimum end-face/travel alignment of 0.928.
- Runtime console was empty. Both Rojo packages built. All three edited modules matched the final Edit sources. Studio backups are under ServerStorage.BeforeHammerRock_20260923. Multiple real clients and latency scenarios were not tested.

## Earlier spring and combination changes

- Mjolnir has a straight outbound/return trajectory and keeps its launch orientation for the entire flight. No age-driven tumble or sudden return-facing flip. Return collision/damage policy is unchanged.
- Gloves idle horizontally, with their knuckles facing avatar-forward. The follower still supplies normal bob and motion lag. Each hand blends from its actual last rendered pose into its punch, then returns to an exact guard transform, preventing accumulated per-part drift.
- Normalized melee clock: 0�0.12 preparation, 0.12�0.46 active strike, 0.46�0.90 follow-through/recovery. Downward strikes lift until 0.22 and only damage from 0.22�0.46. Client preparation blends from the previous visible pose; server damage is disabled throughout preparation.
- Most melee runs at 1.8 before stat modifiers (0.5-second full motion), gloves at 2.1, nunchucks at 1.35. Downward styles multiply their rate by 0.58 (normally 1.044, about 0.86 seconds total). The server waits for recovery when necessary; cooldowns cannot interrupt an active combination.
- Overheads now pivot around the lower grip (42% of weapon length below its bounds center). The grip advances two studs and lowers only 0.65 studs during the strike, while the head rotates through a 170-degree forward/downward arc. This supersedes the rejected whole-object lift/drop. Mirrored overheads start on alternating sides; timing and recovery remain unchanged.
- Recovery carries slightly beyond the cut, then springs toward the moving idle slot with a small vertical arc. The added displacement is bounded and reaches zero at both endpoints. It is cosmetic after the active damage window.
- AttackSide alternates each server-owned attack. Horizontal, diagonal, slab/slap and overhead paths mirror both translation and rotation. Steak alternates right-side slaps and left-side diagonals. Cinder block cycles diagonal/horizontal/diagonal/overhead; shovel primarily slams with a diagonal variation. Pan, bat, spatula, roller and melee hammer use horizontal/diagonal/overhead variations against single targets and horizontal sweeps against groups. Katana retains its target-count style policy with alternating sides. Excalibur remains horizontal-only, alternating stroke direction.
- Nunchucks use mirrored figure-eight paths, with every third attack a forward-plane spin. Shared rigid-link FK continues to drive both the rendered bones and hit boxes. Each enemy is still damageable once per attack, even when a routine crosses it more than once.

## Rocket effect answer

Inspection of RocketVisuals and RocketExplosionVisuals: the flying RPG uses the existing mesh model; its trail uses code-created 3D sphere-cloud clusters; its explosion uses the user's uploaded image atlases in BillboardGui sprites. Those rocket effects do not currently use ParticleEmitters. The separate poison-cloud effect uses ParticleEmitters with Roblox's bundled smoke texture. No rocket effects or assets were changed in this pass.

## Validation

### Grip-driven overhead correction

- SpringComboTests: 13,697 checks passed. Replaced obsolete large-translation assertions with forward grip travel, limited grip drop, a curved head path and constant lever length. Mirroring, damage timing and smooth recovery checks still pass.
- WeaponBehaviorTests: 19,905; MeleeMotionTests: 20,024; WeaponFollowTests: 834 passed. The latter two initially used an incorrect test invocation; rerunning with their required module/template arguments passed.
- Actual Studio Play: both mirrored Downward shovel attacks registered contacts at five studs, at motion rate 1.044. Rendered head samples traveled from about 0.26 to 6.11 studs forward of the attack root before finishing at 5.76 studs forward and 1.40 studs below it. Corresponding grip samples advanced from about 1.81 to 3.80 studs forward, with only modest vertical movement.
- Both Rojo packages built successfully. Runtime console was empty. Final Edit WeaponMotion source matched the repository. Previous source is backed up under ServerStorage.BeforeGripSwing_20260923 and build/grip-swing-backup.

### Earlier spring/combo pass (before the overhead correction)

- SpringComboTests: 13,427 checks passed, including inactive windups, mirrored paths, full overhead translation, continuous recovery, chain hit-box bounds, Excalibur restriction and non-spinning hammer math.
- WeaponFollowTests: 834 checks passed at 20/30/60/144 FPS; MeleeMotionTests: 20,024; WeaponBehaviorTests: 19,905. The thrust endpoint assertion now samples the final strike time rather than the superseded rapid timeline.
- Actual Studio Play at five studs: shovel, block, steak, nunchucks, gloves and Excalibur each landed hits. Replicated combination sequences showed alternating sides; nunchucks used both FigureEight and Spin. Shovel rate was 1.044 on overheads and 1.8 on diagonals.
- Actual rendered shovel samples rose from Y=7.32 to Y=10.89 during its lift. The shared path checks verify a 7.7-stud downward sweep after the apex. Viewport inspected; final aesthetic acceptance remains subjective.
- Hammer: 47 moving-frame samples across a throw and return had minimum UpVector/RightVector alignment 1.0, confirming no rotation. Earlier testing caught a return-facing flip; fixed by retaining launch orientation for the entire modeled flight.
- Gloves: after multiple punches and leaving target range, exact guard-position error was zero and forward alignment was 1.0 for both meshes. Idle reset prevents per-hand drift.
- Both Rojo packages built successfully. Final runtime console was empty. Scripts synchronized to the open roguelite Edit data model, with backups under ServerStorage.BeforeSpringCombos_20260923 and local build/spring-combo-backup.

Multiple real clients, high latency, all stat/scale combinations and prolonged combat performance remain untested. No persistent currency, wins or DataStore tests were used. Temporary runtime player/test state is discarded on stopping Play.
