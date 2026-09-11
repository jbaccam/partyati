# Live combat tuning — 2026-09-08

## Five-character punching gallery — 2026-09-10

BuildMVPFighterGallery.luau maps to ServerStorage.BuildMVPFighterGallery. It creates Workspace.MVPFighterGallery behind the original practice pad, with five normal-color model copies on labeled platforms. It refuses to overwrite an existing gallery. MVPFighterGalleryServer.server.luau maps to ServerScriptService.MVPFighterGalleryServer and manages the identical 1,000-HP training targets, resetting them after four seconds without damage or when below 100 HP. The gallery is removed at startup outside Studio. No rewards, currency, unlocks, or persistent data were added.

These are punchable, stationary inspection targets, not newly playable fighters or punch-animation demos. Targets use the existing BrainrotCombatTarget opt-in tag and common training collision rules. No Tung-specific animation tag is applied to the other skeletons. All four other source models have bones, but their different limb layouts need mapping, animation, skinning checks, and combat movement integration before player use.

Verified actual client M1 damage on all five: 1000 -> 997 / 996.91 / 993.64 / 996.73 / 996.73 respectively (differences are Tung combo/Beat progression, not target stats). Subsequently verified all five reset to 1000. All nine existing regression suites passed. Desktop screenshot confirmed the full lineup and non-overlapping labels. Real multiplayer/published behavior and individual bone skinning are not tested.

## Faster MVP baseline — 2026-09-09

Tung's base WalkSpeed is now 20 (was 18), sprint 28 (was 26). Server speed and client prediction match; Beat retains its 4% per-stack movement bonus. Sprint regression expectations updated for 29.12 with one stack and 20.8 on release, while normal-avatar restoration stays 16. All nine suites passed in fresh Play; actual client sprint/release measured 28/20 at zero Beat stacks. Attack, jump, and slam timings unchanged. The four proposed MVP additions are documented in ../MVP_ROSTER_PROPOSAL.md but are not implemented or balance-tested.

## Final-swing skinning correction — 2026-09-09

The endpoint-only check missed the twisted arm deformation shown by the user. Replaced the final swing's inverse-kinematics arm targets with direct joint rotations: a shoulder-driven arc, fixed 0.25-radian outward spread, single-axis elbow bend limited to 0.20–0.35 radians, and constant -0.30-radian wrist bend. The final recovery also uses these simple joint rotations instead of returning to an IK hand target. Earlier ultimate strikes and the shared grip are unchanged; the previous clip is backed up by the builder.

Visual QA used three isolated skinned-mesh previews at 2.93, 3.04, and 3.15 seconds, including a close side view of the halfway pose. ArmClearance was applied exactly as in gameplay and did not alter the right arm. Temporary preview clones were removed. The expanded MidnightAlarmSwingTests checks elbow hinge direction/bend limit, fixed wrist, and absence of runtime constraint rewrites, in addition to 121 continuous downward/forward path samples. All nine suites passed in a fresh Play server. A complete client Core-pickup/F cast produced all four warnings and four impacts and returned to an empty action. User acceptance and real multiplayer visual observation remain unverified.

## Cartoon HUD and forward ultimate swing — 2026-09-09

TungCombatClient and TungPrototypeClient now use flat cream/ink ability cards, rounded Fredoka labels, hand-built monochrome ability icons, teal health, amber Beat indicators, outlined buttons with shallow pressed offsets, and keyboard/gamepad/touch-specific help text. No gradients or external image assets. All five abilities retain their original activation handlers; ready/cooldown/Core states still reflect server attributes. Actual client Q test changed READY to 4.7s; all visible labels reported TextFits, and the full desktop HUD was screenshot-checked. Phone/gamepad device behavior is not verified.

Final-swing correction: BuildMidnightAlarm now keeps a consistent lateral orientation while the club changes from pointing up to pointing down, and uses a forward/outward elbow pole. The former cross-product basis flipped direction and twisted the whole arm. Intermediate poses at 3.00 and 3.08 seconds guide the club forward before its 3.15-second ground strike; a 3.5-second recovery pose guides it back. Keyframes before 2.55 seconds are preserved when rebuilding, including any hand edits. Existing WeaponGrip, damage, timings, and earlier attacks remain unchanged. Previous F is retained under a unique MidnightAlarmBackup_* name in ServerStorage.

MidnightAlarmSwingTests.luau maps to ServerStorage.MidnightAlarmSwingTests. All nine suites pass in fresh Play. The new test samples 121 interpolated poses from 2.93 to 3.15 seconds, checking that elbow/hand/club stay forward of the torso, the hand stays outside it, the tip moves downward without reversal, and the final tip reaches ground level. Mesh-surface intersection and arbitrary avatar scaling are not proven by this skeletal test; visual/user acceptance and real multiplayer testing remain necessary.

## Midnight Alarm rework — 2026-09-09

Replaced the six-second pulling-wave ultimate with a 3.7-second club sequence. Impacts at 0.65/1.25/2.05/3.15 seconds: two body-drum booms (8 damage each), resonant sweep (14), final ground-style slam (24). Effective radii 10/12/14/20; knockback 8/12/26/82. Every impact is independently server-validated for range, line of sight, protection, and living targets. The cast still consumes one Core, retains movement control, and stops on death. Beat bonuses remain active; the stationary four-hit fixture takes 57.24 damage from zero starting stacks. This is provisional balance, not multiplayer-tuned.

FighterDefinitions is the timing/damage source. CombatEffects.luau maps to ReplicatedStorage.TungPrototype.CombatEffects and now presents stationary-radius pre-impact warnings, layered outward shockwaves, timed arcs, local camera impulses, and pitch-shifted built-in impact sounds. No new external audio assets were imported. TungCombatClient renders the existing WoodenBat during F using the unchanged editable weapon grip; its trail is limited to impact windows and removed after the cast.

BuildMidnightAlarm.luau maps to ServerStorage.BuildMidnightAlarm and builds 16 editable keyframes in ReplicatedStorage.TungPrototype.CombatAnimations.F. It uses two-bone arm targeting for drum/overhead poses and samples the existing Q clip for the sweeping strike. The original six-second F sequence is preserved as ServerStorage.MidnightAlarmBeforeRework, and the first revision as MidnightAlarmFirstPass. Do not rerun the builder merely to sync source: it replaces F and makes another backup.

All eight suites passed in a fresh Play server, including new MidnightAlarmTests (Core requirement, pre-hit timing, four warnings/four impacts, total damage, no repeated damage, wall rejection, range rejection, death cancellation). Existing Extended tests were updated to the new timings/damage. Actual client Core pickup and F remote input produced AlarmWarn/AlarmBeat twice, AlarmWarn/AlarmStrike, AlarmWarn/AlarmFinal in order; the bat was absent after recovery. In-Studio screenshots checked the club/body pose and warning ring; a follow-up lowered the chest-strike target. Full motion aesthetics, real multi-client play, published asset/audio behavior, and competitive balance still require user testing. No Blender work was required and no unrelated place content was overwritten.

## Softer slam descent — 2026-09-09

Reduced the slam's forced initial downward velocity from -72 to -48 studs/second. World gravity, normal jumps, the 58-stud/second hop impulse, early dive timing, and contact-based landing presentation remain unchanged. TungFlowTests.luau maps to ServerStorage.TungFlowTests and now expects the softer impulse while still asserting horizontal steering is preserved. All seven suites passed in a fresh Play server. Actual client E input showed descent around -51 to -64 studs/second before ground contact and transition into SlamLand; no apex hold was added. Multiplayer and user acceptance remain unverified.

## Sprint emphasis — 2026-09-09

Sprint is now 26 studs/second (previously 24), with matching server and client prediction. Base walk remains 18; Beat scaling remains 4% per stack. Pose.luau maps to ReplicatedStorage.TungPrototype.Pose and TungCombatClient.luau maps to StarterPlayer.StarterPlayerScripts.TungCombatClient. These preserve the current Studio sources, including changes predating this tuning. Sprint blends in an additional approximately 11.46 degrees of forward spine lean, counterbalances the head, strengthens arm swing and elbow bend, and adds a small crouch/foot lift. Grounded movement weighting suppresses these additions in the air and while stationary. Combat clips retain control during attacks.

All seven existing combat/presentation suites passed after the change. An isolated cloned-visual pose test measured the 11.46-degree hunch and successful blend-out; actual client sprint/release measured 26/18. Multiplayer and subjective visual acceptance remain unverified. First-person behavior was diagnosed but not changed: TungPrototypeClient hides the entire single mesh near the head while independently created combat FX remain visible. Visible first-person arms require a dedicated presentation setup rather than showing the head/body inside the camera.

These source snapshots match the modified scripts in the open Jump Farther for Brainrots! place. TungCombatService maps to ServerScriptService.TungCombatService; TungSprintTests maps to ServerStorage.TungSprintTests. FighterDefinitions lives in ../src/shared and maps to ReplicatedStorage.TungPrototype.FighterDefinitions.

The existing prototype Rojo project does not package the newer Studio-only combat dependencies. Do not full-sync that older prototype over the live place. These snapshots preserve the changed combat source without overwriting unrelated Studio work.

Changes: Tung base WalkSpeed 16 -> 18; sprint remains 24. Slam dive begins at 0.16 seconds for grounded hops (previously 0.26), 0.08 for aerial casts (previously 0.18). Original 0.25-second server landing guard retained. Bat grip and animation assets unchanged.

Verification: all six Studio suites passed in a fresh Play server: TungCombatTests, TungCombatIntegrationTests, TungCombatExtendedTests, TungFlowTests, TungSprintTests, TungHeightTests. Sprint expectations updated for the new base speed; normal-avatar restoration remains 16. Actual client remote-input test measured upward velocity +19 then downward -79 at roughly 0.23 seconds after input, without the previous near-zero apex samples. Client WalkSpeed measured 18, sprint 24, release 18. Height scaling, damage cap, one-impact damage, recovery chaining, and horizontal steering covered by existing suites. Prototype Rojo packaging passed; it is not a complete live combat build.

Not verified: multiplayer latency, published play, visual animation quality.

## Landing-pose follow-up

Subsequent hop-height tuning: grounded Sahur Slam launch velocity increased from 48 to 58 studs/second. The 0.16-second dive transition, aerial casts, regular jumps, and movement speed remain unchanged. All seven Studio suites passed again; actual client input measured about 6.43 studs of rise and a successful downward dive in a fresh Play session.

CombatPose.luau maps to ReplicatedStorage.TungPrototype.CombatPose. It now starts SlamLand on observed humanoid ground contact after an airborne phase, instead of retaining the tucked airborne pose until server confirmation. Confirmation retains the original presentation start time so the landing does not play twice. New casts and other actions clear this local state. Damage, physics, cooldowns, movement speed, bat grip, and server FX remain unchanged.

TungSlamPresentationTests.luau maps to ServerStorage.TungSlamPresentationTests. Its isolated regression fixture passed: no grounded-startup false landing, no timed landing on a high fall, immediate contact transition, no confirmation replay, and action cleanup. All six existing combat suites also passed in a fresh Play server. In the actual client animation loop, MotionState reported SlamLand by 0.346 seconds after input while the replicated CombatAction remained E until 0.582 seconds; physical contact was observed at 0.312 seconds. MotionState diagnostics update only every 0.1 seconds. Before this fix the visual pose waited for server confirmation roughly a quarter-second after physical contact. User visual acceptance and multiplayer observation remain unverified.
