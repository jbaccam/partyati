# Hammer boss — reference rebuild

The current deliverable is **`finished/HammerBoss.blend`**. Earlier files in this folder and `reference-rebuild/` are authoring drafts, not the installed boss.

The rebuilt model is 11.92 studs tall, with a 9.05-stud handle. Carry grips are 5.33 studs apart; attack grips slide to 6.55 and 8.05 along the shaft, 1.50 studs apart near its end. It has a projecting belly, torn cream shirt, suspenders, charcoal trousers, rounded hips and seat, closed grips, and a beveled iron hammer. Enlarged traps/back blend into the unchanged shoulders. Green skin retains the Tank family palette; the boss now has its own modeled scarred brow, narrowed eye, and broken-tooth snarl. It is a reconstructed 3D interpretation of the supplied single view; hidden surfaces are authored rather than recovered from that image.

## Deliverables

The latest traps/arms revision raises and widens the trapezius and upper back into the unchanged shoulder caps. Biceps, triceps, and forearms have fuller shaped profiles with narrower elbow/wrist transitions. The shirt and suspenders are fitted by ray-casting onto the enlarged body surface rather than using an approximate torso outline. Prior grip geometry and hand orientation are retained.

- `finished/HammerBoss.blend`: editable meshes, 17-bone rig, packed textures, seven actions, review stage and camera.
- `finished/HammerBoss_Import.fbx`: textured static sections for Roblox import.
- `finished/Idle.fbx`, `Walk.fbx`, `Slam.fbx`, `Swing.fbx`, `Spin.fbx`, `Hit.fbx`, `Death.fbx`: rig and baked 30 FPS animation exports.
- `finished/textures/`: individual 1024 × 1024 maps for all 16 sections, including the new modeled face. The old `HammerBoss_Color.png` is superseded.
- `finished/HammerBoss_NPC.rbxmx`: installed Roblox template, including uploaded mesh and texture references, Humanoid and Motor6Ds.
- `finished/BossDataMain.luau` and `finished/clips/`: matching motion samples used by both client presentation and server collision. Clips are split to respect Studio's per-script source limit.
- `finished/studio-asset-manifest.json`: complete template properties and attributes, including uploaded asset IDs.
- `finished/LeftGrip_Front.png`, `LeftGrip_Under.png`, `LeftGrip_Contact.png`: close-up geometry/contact reviews; `HammerBoss_Back.png` shows the continuous back and fuller trousers.

## Studio integration

Installed in the authorized **roguelite place 107877054949326**. The template lives in `ServerStorage.RogueliteNPCs.HammerBoss_NPC`; the visible comparison is `Workspace.ZombieVariantPreviews.HammerBoss_Preview`, beside the Tank. Unrelated NPC templates and previews are retained. Modified pre-boss scripts are backed up under `ServerStorage.BeforeHammerBoss_20260923`; the prior boss model and motion modules are retained under `ServerStorage.BeforeHammerBossSkinGrip_20260923`.

The version immediately before this continuity revision is retained under `ServerStorage.BeforeHammerBossContinuity_20260923`. All 16 mesh sections use `SurfaceAppearance` color maps and Precise render fidelity. SurfaceAppearance avoids the dark atlas seams observed when the same textures were rendered through Humanoid/TextureID compositing. The saved template and installer both preserve this fix.

The encounter uses wave 20 by default; `ReplicatedStorage.RogueliteCombat.HammerBossWave` can override it. Wave completion waits while the boss is alive. Changing the normal enemy count preserves the boss. Stopping a wave removes it. Boss movement and hit decisions run on the server; clients display the matching poses, warning shapes and impact effects.

Each hand stays closed around the shaft while sliding into the paired attack grip. Both arms extend to more than 99% of their available reach during active strikes. The hammer's local Z striking end leads horizontal/spinning travel. A slam commits its direction before anticipation. Swing and spin collision sample the actual oriented head at 120 Hz during their active windows; each player can be hit once per attack. Warning shapes do not themselves deal damage.

Walk is a 1.6-second asymmetrical gait authored at 4.5 studs/second, with a lower dragging left step, longer right support, weight sway and 0.558 studs of authored hip bob. Client phase follows horizontal distance traveled. Planted feet move backward relative to the root at the matching speed, reducing sliding. The weapon lifts enough to clear the ground during the body drop.

In Studio, open **Stats / Test [P] → Zombies → Spawn boss / Remove boss**. These server-validated controls allow one practice boss, reject extra arguments and rapid requests, and grant no boss rewards. Set normal zombies to zero for an isolated fight. The HUD shows **HAMMER BRUTE** with the nearest living boss's HP; it hides after death/removal and resets for a new boss.

| Move | Warning begins | Active damage | Return to idle |
| --- | --- | --- | --- |
| Slam | frame 5 | frames 23–24 | frame 50 |
| Swing | frame 6 | frames 19–25 | frame 54 |
| Spin | frame 6 | frames 21–37 | frame 66 |

Frames use 30 FPS and start at zero in the design data; Blender's timeline starts at frame 1. Idle, walk, hit and death last 96, 48, 18 and 84 frames respectively.

`BossService.spawn(cframe, true)` creates a Studio-only practice boss. Practice death gives no shard drop. Death cancels attacks immediately, preserves the visible death pose for 2.9 seconds, then removes the model. No DataStore access is introduced.

## Validation

**September 23 wrist alignment revision:** Slam radius is 7 studs, double the previous radius and four times its area. Both the warning disc and impact debris use that radius. `wrist_motion.py` solves the paired grip, wrist roll around the shaft, elbow placement, and forearm twist together. The wrist cuff now follows the forearm instead of inheriting the hammer head's roll unchanged. The solver allows elbow flexion rather than forcing 99% extension, which was incompatible with the existing grip geometry; active hammer reach remains above 9 studs. This replaces the prior locked-elbow constraint.

`validate_wrists.py` checks every authored attack frame for wrist bend below 35 degrees, wrist joint closure below 0.001 studs, radial grip drift below 0.001 studs, and clearance from a conservative torso core. Maximum measured bends are 19.13 degrees for Slam, 31.83 for Swing, and 20.80 for Spin; joint gaps and radial grip drift are below 0.000007 studs. `validate_lever.py` still verifies contact at the handle end, the correct striking face, and exact slam ground contact. The walk's planted-foot and bob checks still pass. Native Blender side views are saved as `WristReview_*.png`. These are sampled geometric checks, not exhaustive mesh collision proof. Historical reports below refer to their stated revisions.

The wrist revision was installed into the open roguelite place and tested with one Studio client. Slam hit at 6.5 studs and missed at 7.5; all three attacks had zero early hits and exactly one active hit. Eighty-seven client pose samples, including both hands and forearms, matched the authored orientations (reported angular error zero) and positions within 0.003202 studs. A stationary swing pose was also inspected in Studio. The only captured output afterward was the connector restoring the temporary review camera. Both packages built. Native place save, exhaustive motion review, multi-client latency and published asset access are unverified. Backups are under `ServerStorage.BeforeHammerBossWrist_20260923`.

**September 23 motion polish:** Slam radius is now 3.5 studs (previously 2.35), with matching warning/impact spread. Spin uses 36 fps instead of 30 and continuous angular travel through its active revolution. Windup rotates around the held end; outward elbow poles and a paired-grip torso-clearance projection replace the unstable windup/recovery paths. Attack entry blends for 0.12 seconds, before damage can begin. `inspect_arm_motion.py` checks all exported idle/walk/attack frames against a conservative torso core and caps torso-relative elbow steps at 0.85 studs/frame; these are sampled checks, not exhaustive mesh collision proof. Active arm extension remains above 99.3% and both grips remain attached.

The installed revision passed all three single-client server attack tests with zero early hits and exactly one active hit. The slam test placed the player 3.2 studs from impact, outside the old radius. Walk travel was 18.024 studs in four seconds. All 87 actual client pose samples passed (maximum hand/hammer position error 0.003202 studs); Studio's output log was empty. Both Rojo builds passed. Blender windup and swing renders were inspected; exhaustive visual review of every angle and multi-client latency remain unverified. See `finished/polish-studio-test-results.json`. Previous Studio modules are retained in `ServerStorage.BeforeHammerBossPolish_20260923`.

**Current September 23 lever/heavy-walk revision:** `heavy-motion-checks.json` measures minimum active arm extension of 99.3%, zero leg overreach, planted-foot drift below 0.000001 studs/frame, and 0.558 studs of authored bob. `lever-motion-checks.json` measures grip drift below 0.000004 studs, correct leading striking faces, and slam ground contact within 0.000003 studs of the intended clearance. Finger tube frames were repaired to prevent collapsed circular holes.

`heavy-studio-test-results.json` records 87 actual client pose samples (maximum hand error 0.003016 studs, hammer error 0.000977), all three attacks with zero early hits and exactly one active hit, and 18.006 studs of travel in four seconds. A further 176 moving client samples showed 0.843 studs of rendered hip height variation including the locomotion transition. The HUD showed full/half health, hid on removal/death, and reset to full after respawn. New face and both shoulder textures were visually checked in Play and Edit. Several failed import maps were replaced by direct image uploads; raw-ID preload callbacks still reported failure despite visible rendering, so published asset access remains unverified. A temporary texture diagnostic caused a Plugin-capability error and was removed; no gameplay errors were observed. Both Rojo packages built successfully. Studio save was requested after returning to Edit.

The prior installed model/modules/scripts are preserved in `ServerStorage.BeforeHammerBossLever_20260923`. Reports below describe earlier revisions and are historical, not reruns of the latest implementation.

The current traps/arms revision passed 87 actual client pose samples across seven clips (maximum hand error 0.003015 studs, hammer error 0.000977 studs). All authored frames passed reach and grip checks. At rest, 7,680 shirt vertex/face-center samples had no body penetration, with minimum signed clearance 0.0966 studs; this sampling is not an exhaustive intersection proof. Front and rear views were inspected in Studio. Both Rojo packages rebuilt successfully. See `finished/traps-muscles-test-results.json` and `finished/garment-fit-checks.json`. The immediately preceding model and modules are retained in `ServerStorage.BeforeHammerBossTraps_20260923`.

The current continuity revision passed 87 actual client pose samples across all seven clips, with maximum hand error 0.002903 studs and weapon error 0.000977 studs. Authoring checks also passed every frame. Sixteen contact probes per hand measured maximum positive shaft clearance below 0.019 studs; slight negative clearances indicate contact/intersection. These probes are not an exhaustive collision proof. Final wrist and rear views were inspected in Studio after the surface rendering fix. See `continuity-test-results.json`, `grip-contact-checks.json`, and `fbx-roundtrip-checks.json` in `finished/`.

After the skin/grip revision, 87 actual client pose samples across all seven clips kept both hands and the hammer within 0.005 studs of their expected positions (largest hand error 0.002844 studs at the preview's world offset). All authored frames also passed the regenerated arm-reach checks. See `finished/skin-grip-test-results.json` and `finished/authoring-checks.json`. The gameplay checks below were performed before this visual revision; combat logic was unchanged. Revised template installation alignment error was 0.00000125 studs, and both Rojo packages built again successfully.

The rebuilt proportions, grip, front/three-quarter views, overhead windup, slam contact, swing, spin and collapsed death poses were inspected in Blender renders. Every authored frame passed arm-reach checks, and both grips use the same weapon transform throughout. These checks do not prove a perfect match to the reference or exhaustive absence of mesh intersections.

Single-client Studio Play testing verified all three attacks cause no damage before the active window, exactly one hit per attack, and no extra damage during recovery. Client warnings appeared as circle, arc and circle, and the client applied poses across 490 observed simulation frames. Actual post-defense damage in this test was 20.4, 15.3 and 18.7. Killing during anticipation cancelled damage, retained the death animation briefly, removed the boss afterward and generated zero practice drops. Results are saved in `finished/studio-test-results.json`.

The wave-20 regression verified automatic spawn, preservation across population changes, blocking timed wave completion while alive, and transition to the wave-21 shop after death. A separate movement check recorded 14.11 studs of travel in two seconds with an unanchored living boss. These final runs produced no runtime errors; their reports are saved beside the attack test results.

The last pose regression repeated slam and spin after the ground-contact adjustment and measured a 360-degree active spin sweep. Both retained their no-early-damage and no-repeat-damage guarantees, with no runtime errors.

Both the root CopyTheScene package and the roguelite combat package build successfully. Multi-client latency, published asset access, long-run balance, and exhaustive full-speed/half-speed review from every angle remain unverified.

## Rebuild and provenance

Run `reference_rebuild.py`, then `finish_reference.py` with Blender 5.2. `revise_motion.py` rebuilds motion and previews from the finished baked model without rebaking textures. The combat Rojo project includes the boss template and scripts.

The supplied image is preserved unchanged as `source/boss-reference.png`, SHA256 `B401488FE31019B7D2179CBCF652D17082BA92E1B5ED7AD2BF2D5A64736CA6F6`. Body, clothing, hands, facial features and hammer are authored Blender geometry. Clothing and weapon materials are procedural and baked. Skin uses the established local `baby-mutant-zombies/source-art/MutantTexture.png`; the face uses newly modeled features baked into its own map, rather than the Tank face tile. No Creator Store character or external character model was used. The impact uses Roblox's bundled `impact_explosion_03.mp3` and smoke particle texture.
