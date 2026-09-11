# Five-fighter MVP verification — 2026-09-10

## Latest visual correction: Bombardiro propeller hubs

The reviewed mesh's propeller bone origins are outward/below the visible blade hubs. Frozen near-orthographic front views identified a hub XY calibration of 13/15 of each propeller bind position. `FighterRigProfiles.PropellerHubScale` records this asset-specific calibration; `FighterPose:spinPropeller` conjugates rotation around that hub in bone-local space. This is rigid pivot compensation, not a skin/bone rescale. Existing wing animation, engine speed, flight and combat are unchanged. The original geometry and skin weights are untouched.

Visually checked rest, 45° and 180° phases, with hubs remaining over the engine centers. PropellerPivotTests passed 292 samples over four propellers, maximum mathematical hub drift 3.34e-8 studs. Both full animation/secondary suites, DistinctAnimationTests, UltimatePresentationTests and MidnightAlarmSwingTests passed. Existing no-joint-stretch tests now explicitly validate the fixed-hub invariant for these four rigid propellers rather than rejecting their necessary pivot-compensating translations. Rojo build passed. No Blender connection or EditableMesh permission was available; this fix uses existing bones and measured visual calibration, not a re-exported mesh.

## Latest: stronger regular knockback and replacement audio

`KnockbackRules` and `HitReaction` separate opening carry hits, finishers, abilities and ultimates. Opening hits use short horizontal carry (0.12s) and 0.12s stagger; finishers scale former force by 1.5 and abilities by 1.4, with bounded horizontal carry and gravity unchanged. Third and later rapid staggers shrink to 0.04s, leaving opportunities to defend. Damage, health/weight scaling and deliberate sprint-strike bonus remain; ultimate force uses the exact old formula, including Tralala's ultimate. Delayed ultimate projectiles carry an explicit ultimate context.

Unanchored physical fixtures measured approximately **2.91 studs** for a first M1, **11.64 studs** for the finisher and **13.46 studs** for an ordinary ability. A walking fixture connected the three-hit combo for 12.45 Tung damage including Beat scaling. Its initial failed chase was traced to the single-part fixture entering FallingDown; disabling that unsupported fixture state made the test valid. A separate playable Tung on clear floor connected all three hits using short forward steps between attacks: combos 1→2→3, 12.45 damage, with final separation about 7.79 studs. Continuous-forward automation on the crowded gallery entered Climbing/missed hits; this is not evidence of a guaranteed hold-forward combo. Real multiplayer/latency/edge scenarios still require playtesting.

Audio now uses eight actual ProSoundEffects Creator Store recordings, documented in `AUDIO_ASSETS.md`, not the previous Roblox falling/jump/footstep samples with EQ. All eight loaded successfully in the client. Default character movement Sounds were found under HumanoidRootPart at volume 0.65. Live replacement/restoration checked Running volume **0 while active → 0.65 unmorphed → 0 active again**. New footsteps follow travel distance at lower volume than attacks; jump, air-jump and landing cues are debounced; 24-voice bound and duplicate coalescing prevent uncontrolled layering. No subjective listening approval is claimed.

Final fresh-session aggregate: **25 server suites passed**, comprising the earlier 23 plus CombatAudioTests and KnockbackFeelTests. Client camera/first-person and HUD tests passed again; Rojo packaging passed. No publishing or persistent progression changes.

Implemented in the open **Jump Farther for Brainrots!** Studio place (98123023712304), not the unrelated root CopyTheScene project. No publishing, persistent rewards or DataStore access.

## Current presentation, projectile, camera and training-target correction

This revision addresses effects inside Tralalero's head, unclear banana debris, absent floor peels/bomb drops, descending-only Peel Glide, missing ultimate articulation, generic sound cues and anchored gallery targets. It also adds default shoulder-lock combat with optional first-person zoom. Shift remains sprint; menus release the mouse.

### Implemented behavior and current targeted evidence

- Shark bite curves now originate beyond the visible model's head bounds. `ProjectilePresentationTests` checks placement outside the head, not only outside the small character root.
- Actual Tralalero model-bound placement check: the jaw front was **4.581965 studs** ahead of the root and the closest slash center was **4.718772 studs** ahead, confirming the effect moved beyond the head in that sampled pose.
- Chimp's third M1 now presents a tapered, curved banana traveling at 54 studs/s, with a 13-stud limit and first-contact termination. `ProjectileGameplayTests` passed its real 5-damage hit check. It remains a separate basic-projectile context, not a particle or a source of extra melee bonuses.
- Banana Boomerang is 64 studs/s instead of 48; its 32-stud unobstructed outbound and return legs each take 0.5s. Peel Trap leaves a recognizable three-strip floor peel, with tested trigger/replacement/expiry cleanup.
- Peel Glide now climbs: initial lift 24, sustained vertical velocity 12, finite drive 1.25s. The revised unanchored `MotionPhysicsTests` sampled **11.4059 studs of rise at 0.8s**; expiration and return to gravity remain covered.
- Carpet Run drops three server-traveled bombs, 4 damage each, and already released bombs persist after the action ends. `ProjectileGameplayTests` passed three-bomb/12-total-damage checks. Croc Bomb and dropped bombs have a body/tail-fin silhouette.
- Initial visual captures exposed an unsuitable Ball-Part silhouette. The fruit/peel/bomb presentation was changed to elongated `SpecialMesh` sphere surfaces and recaptured. Presentation tests verify the curved banana, flat peel strips, synchronized falling bombs and cosmetic-only collision settings.
- `UltimatePresentationTests` passed for all four non-Tung rigs: articulated bones during more than 80% of sampled ultimate frames, fighter-specific hit/release poses, no joint stretching, protected Chimp face bones and return to rest. This is numerical choreography coverage, not certification of every skin deformation or camera angle.
- A playable Ballerina collected a Core through its normal prompt and activated F. The Core was consumed, four bones exceeded 0.25 radians of rotation in the sampled pose, and a rendered capture showed the open-arm/spinning presentation.
- All five combat audio files preloaded with `IsLoaded == true`. Cues use built-in assets with EQ/timing/pitch/volume mixing; no bespoke recorded voices or new sound pack was produced. Loading success does not establish subjective sound quality.
- `TrainingDummyTests` passed: the unanchored fixture traveled **2.605 studs** from its impulse; it stayed displaced during the four-second wait, a new hit postponed return, reset cleared momentum and healed, and lethal/void cases rebuilt living tagged targets.
- Actual gallery Tralalero target: E dealt **8 damage**, displaced it **6.236 studs**, then it returned exactly home and healed to **1000 HP** after four seconds without another hit. M1 also dealt its expected 3 damage. This checks a real gallery target, not only the isolated fixture.
- Live client `camera.spec` passed default lock, menu cursor release and optional first-person checks. Live `ui.spec` passed. The prior session's blank HUD/non-rendering issue is no longer the outstanding result for this revision.

### Final current regression and handoff

All **23 server suites** passed in the final fresh Studio session: the 19 from the previous distinct-kit revision plus `ProjectileGameplayTests`, `ProjectilePresentationTests`, `UltimatePresentationTests` and `TrainingDummyTests`. Both live client suites, `camera.spec` and `ui.spec`, passed again. The final Rojo overlay build passed.

Updated sources were installed in Edit mode, temporary QA content was cleared, and Studio was left stopped in Edit. Checked logs contained only the pre-existing denied imported animation asset **139702462244046**, with no new errors. Nothing was published.

These tests and captures cover targeted behavior, not full visual approval of every move, all matchups or multiplayer latency. The generated overlay still has not been reimported into a separate place for visual round-trip verification.

## Previous distinct-kit correction — historical evidence

The original basic attacks and recovery bursts were too similar, and the one-shot velocity approach did not produce reliable player travel. This pass replaces those behaviors with per-fighter basic hit shapes/timings and bounded, server-owned motion constraints. Tralalero now has jaw bites and a tail finisher; Chimp has extended lashes and a finite basic peel projectile; Ballerina has narrow kicks with an advancing finisher; Bombardiro has one slow heavy chomp rather than a three-hit combo. Recoveries are a porpoise arc, descending glide, two-part air step and timed powered flight, respectively.

Eight targeted modules initially passed in the current correction pass:

- `FighterCombatTests`
- `DistinctKitTests`
- `DistinctAnimationTests`
- `MotionPhysicsTests`
- `ui-distinct-effects.spec`
- `MidnightAlarmSwingTests`
- `TungFlowTests`
- `CombatTimingTests`

The kit tests check distinct basic timings/geometry, finite peel travel and motion requests. Animation tests check pose behavior and finite transforms; passing them does not certify that every animation looks good in actual play. Physical-motion tests use unanchored fixtures rather than only checking requested velocity numbers.

### Playable-character and physics samples from that revision

- Actual playable Tralalero: Shark Torpedo traveled **29.093 studs**, instead of only producing a small jolt. The powered segment is configured for 26.04 studs; sampled travel can include momentum after it ends.
- Actual Tail Launcher against the movable target: **130 → 122 HP**, with **5.2375 studs** of peak rise. This confirms the close-range upward launch, not just an effect or damage marker.
- Actual playable Bombardiro R: **15.269 studs of rise** and **44.286 studs of horizontal travel over 2.2s**. Q was fired during flight; `shootingDuringFlight` and flight expiry checks were true. The sample includes the finite powered phase and subsequent motion, not 2.2s of unlimited lift.
- Isolated unanchored physics fixture: Torpedo traveled **29.4355 studs**; the wall-stop check passed. Powered flight reached **12.6312 studs of rise at 1.3s**, then returned to gravity after expiry.

These are observed single-session samples, not guaranteed exact distances across different surfaces, frame rates or network conditions. Complete visual QA for all moves, real multiplayer balance and latency behavior remain unverified.

### Final regression and remaining client check

After the basic-projectile context correction, all **19 server suites** passed in a fresh Play session: the 15 historical suites named below, plus DistinctKitTests, DistinctAnimationTests, MotionPhysicsTests and ui-distinct-effects.spec. CombatTimingTests now explicitly proves delayed Chimp basic projectiles neither consume a later melee swing's sprint/passive bonuses nor prime the passive; ability hits still prime it.

Additional actual-character samples:

- Ballerina R produced two separate AirStep intervals (first observed through 0.24s, second at 0.48–0.64s), with approximately 34.78 studs total sampled travel including momentum. There was an unpowered gap between steps.
- Chimp R, staged airborne, entered Glide and gradually turned from +X toward +Z in response to heading intent. During the descending powered interval its height fell about 0.6 studs per 0.1s; the mode cleared, followed by a faster gravity-driven fall.

That revision's final client HUD smoke test did **not** pass: ability labels were still blank in that session. A direct diagnostic observed **zero RenderStepped events over 0.5s**, so the render-driven HUD had not updated; screenshot capture also did not complete. The current revision above subsequently passed live client HUD/camera tests and produced rendered captures. This resolves the earlier blocked check without implying full visual QA of every move.

The final Rojo overlay build passed. No publishing, persistent rewards, or unrelated place changes were performed.

## Earlier integration pass — historical evidence

The following results predate the distinct-kit correction. Old move names, speed figures and travel samples below describe that earlier version and are **not current tuning values**. Current values are in `README.md` and the effective overrides in `shared/FighterDefinitions.luau`.

All 15 modules passed: TungCombatTests, TungCombatIntegrationTests, TungCombatExtendedTests, TungFlowTests, TungSprintTests, TungHeightTests, TungSlamPresentationTests, MidnightAlarmTests, MidnightAlarmSwingTests, FighterCombatTests, FighterSelectionTests, CombatTimingTests, PracticeStockTests, animation.spec, animation-secondary.spec.

- Existing Tung damage/timings, movement, slam contact and corrected final ultimate arm path retained.
- Five distinct stats/kits, malformed input rejection, cover-blocked traveled projectiles, counter, firing penalty, Core requirement, finite jumps/recovery and health-preserving selection.
- Sprint-strike timing/intent rate limiting, physical-momentum requirement, whiff consumption, unchanged damage and vertical force, first-target-only horizontal bonus and victim amplification cooldown.
- 683,280 finite animation checks; 990 spring checks. No non-root joint translations; protected face bones and Tung authored attack arms.
- Client smoke checks: five cards, updated fighter/ability labels, close control, sprint control, server-ready feedback, conditional four-stock display.

## Earlier live client/server checks

- Clicked the fighter menu and Tralala card; selected all five through the actual selection remote. Correct models, health and HUD identities observed. Fixed the imported MeshPart pivot-offset rotation caught by screenshots.
- Verified real Shift/W input reaches sprint speed and server-authorized readiness. Automated exact charged-hit timing was not consistently reproduced through the input tool; the bonus's numeric effect is covered by the isolated server integration tests above.
- Tralala R: approximately 13.06 studs of rise and 7.96 studs of horizontal travel in the sampled unsteered run; recovery consumed and restored only after landing.
- Chimp projectile reached the movable target. Collected a Core through its prompt and pressed F: ultimate action/FX appeared and Core was consumed.
- Ballerina Q: 130 → 118 target HP. Bombardiro Q: 130 → 117 HP; firing movement speed 12, returning to 18 afterward.
- Hit a gallery Tralala: 1000 → 997 HP; server hit marker replicated and a nonzero damped bone recoil appeared (root peak about 0.0504 radians in that sample). Gallery rigs now use supporting-surface checks instead of incorrect permanent freefall poses.
- Entered the optional island via its G prompt; four-life HUD appeared.
- After the spawn-race correction, a single ring-out produced 4 → 3 stocks, still 3 after the new character appeared. Continued through 2 → 1 → 0, then a new four-stock practice set. Each respawn was alive and on the island.
- A lethally damaged sparring target was replaced after its delay by a fresh, tagged Humanoid at 130 HP in Running state.

## Earlier packaging and remaining limits

`rojo build brainrot-prototype/mvp/default.project.json -o build/BrainrotMVP.rbxlx` passed after the final client presentation fix. Asset/animation counts and properties were inspected as recorded in `assets/manifest.json`. The generated overlay has not been visually round-trip-tested by importing it into another place. Live Studio originals were the visual test source.

Independent Ballerina skirt hems and Chimp peel strips still need additional skinning; supported joints have secondary motion. First-person separate arms/viewmodels are unchanged. Real multiplayer matchups, simultaneous hits under latency, mobile/gamepad hardware, full competitive rounds and published-place behavior remain unverified. The current island is an optional Studio practice loop, not a production match service.

Existing unrelated imported content logs missing Modules and a denied animation asset (139702462244046). This work did not alter those scripts/assets. No new brainrot gameplay errors remained in the checked fresh-session logs.
