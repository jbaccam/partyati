# Brainrot Smash MVP

Latest feel pass: opening M1 hits use a short, reliable carry for chase combos; finishers have 1.5× their former force and ordinary abilities 1.4×, plus short horizontal follow-through that the Humanoid cannot immediately brake. Opening hits have a brief stagger with reduced repeat stagger. Damage and ultimate knockback are unchanged; sprint-reset timing still adds horizontal knockback without bonus damage. Keep stepping forward between opening hits rather than expecting stationary button spam to hold a victim indefinitely. See `shared/KnockbackRules.luau` for the bounded tuning.

Fighter combat and movement now use eight replacement Creator Store recordings (see `AUDIO_ASSETS.md`), with quiet distance-based footsteps, short jump/landing cues and voice limits. Default Roblox character sounds are muted only while morphed and restored afterward. Earlier audio descriptions below refer to the previous presentation pass. Final current checks: 25 server suites, client HUD/camera checks and Rojo build passed; subjective sound quality and multiplayer balance still need playtesting.

Five playable fighters with distinct skeleton animation, server-owned combat, a fighter selector, cartoon HUD, practice targets, and an optional four-stock ring-out island. This is a Studio prototype, not a published or multiplayer-balanced release.

## Controls

- **B:** open/close the fighter selector. Select a card to switch. Selection persists through respawns in the current session.
- **Shift:** sprint. **M1:** basic attack; holding repeats the combo, but does not repeatedly earn the sprint-strike bonus.
- Combat defaults to a centered-mouse shoulder lock, facing and aiming with the camera. Scroll inward for optional first person; scroll outward for third person. Shift remains sprint, not a lock toggle. The fighter selector and other open menus release the cursor.
- **Q / E:** character abilities. **R:** recovery. **F:** ultimate, after collecting a Core.
- Hover an ability to read its current description. Flight/glide display a remaining-time indicator; they are not unlimited movement modes.
- **Space:** jump, then press again while falling to use a remaining air jump.
- **G:** hold at a Core or a labeled practice entrance/exit to interact.
- **T:** development-only normal-avatar/morph toggle; not a combat escape.

Switching or leaving practice requires a living, grounded character outside recent combat, active attacks, stun and cooldowns. It cannot be used to refill health or escape a fight. The selector reports why a request was rejected.

## Initial roster

These are the effective MVP overrides in `shared/FighterDefinitions.luau`, not the older planning values earlier in that file. Speeds are studs/second; higher weight reduces knockback. Air jumps are additional jumps after the ground jump.

| Fighter | Role | HP | Walk / sprint | Jump impulse | Weight | Air jumps |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Tung Sahur | Bruiser | 115 | 20 / 28 | 52 | 1.12 | 1 |
| Tralalero Tralala | Melee pursuer | 100 | 24 / 33 | 60 | 0.94 | 1 |
| Chimpanzini Bananini | High-jump/glide trickster | 105 | 22 / 30 | 68 | 1.00 | 1 |
| Ballerina Cappuccina | Fragile fast duelist | 90 | 25 / 34 | 62 | 0.84 | 2 |
| Bombardiro Crocodilo | Slow artillery heavy | 130 | 16 / 24 | 42 | 1.25 | 1 |

Jump impulse is initial upward velocity, not jump height. These are initial matchup-tuning values, not proof that every matchup is balanced.

Ability figures below are base damage, before applicable passives; multi-hit totals require actually connecting each hit. Range, warnings, recovery, hitbox size and knockback matter alongside raw damage.

| Fighter | M1 combo | Q | E | R | F ultimate |
| --- | --- | --- | --- | --- | --- |
| Tung | Wooden Hands: 3 + 3 + 6 | Bat Beat: 10, outer sweet spot 13; 5s cooldown | Sahur Slam: landing attack, 12–30 based on drop; 8s | Dawn Call: 7; 8.5s | Midnight Alarm: four warned impacts, 54 total; 3.7s |
| Tralalero | Bite & Tail: two aimed bites (3 + 3), broad tail finisher (6) | Shark Torpedo: sustained 0.42s forward dash, 11; 5.5s | Tail Launcher: circular tail sweep pops enemies upward, 8; 7s | Porpoise Breach: 0.8s forward arc under normal gravity, 8; 9s | Feeding Frenzy: three warned bite bursts, 39 total; 2.4s |
| Chimpanzini | Peel Lash: two longer lashes (3 + 3), then a visible 13-stud banana (5) | Banana Boomerang: 7 outbound + 5 return, 64 studs/s; 5.5s | Peel Trap: visible floor peel, 8, arms after 0.5s, lasts 8s; 9s | Peel Glide: 1.25s rising, steerable flight, no contact damage; 8s | Banana Barrage: three projectile fans, at most one hit per target per fan, 36 total; 2.8s |
| Ballerina | Pointe Kicks: alternating narrow kicks (2 + 2), advancing finisher (5) | Pirouette: travel while spinning, 12 total; 5.5s | Pointe Counter: 0.4s one-hit block window; nearby visible attacker takes 9; 10.5s | Double Air Step: two short horizontal steps separated by a pause, 7; 7.5s | Grand Finale: four warned nearby dance hits, 36 total; 2.7s |
| Bombardiro | Croc Chomp: one heavy 7-damage bite; no three-hit combo | Croc Bomb: visible bomb projectile/explosion, 13; 6.5s | Carpet Run: 0.9s level flight dropping three traveled bombs, 4 damage each on impact; 11s | Afterburner Flight: 1.6s powered forward flight with a slow climb, no contact damage; 10s | Grand Bombardment: three warned line-of-sight blast zones, 42 total; 3.3s |

Tung builds Beat stacks for damage and movement. Tralalero gains 1 damage on airborne basic hits. Chimp ability hits prime a melee basic strike for 3 extra damage, expiring after four seconds; the traveling M1 peel is a separate basic-projectile context, so it cannot prime the passive or consume a later attack's sprint/passive charge. Ballerina's advantage is attack speed, small hitbox and two air jumps, paid for with low health/weight. Bombardiro trades ground mobility and attack speed for health and knockback resistance, and slows while firing. Other roster entries are planning data only and cannot be selected.

The basic attacks now have different hit geometry and timing as well as poses. Shark bites connect at 0.115s, with a wider tail finisher at 0.15s (0.30s recovery per swing). Chimp lashes connect at 0.12s and release the third peel at 0.16s (0.34s recovery). Ballerina kicks connect at 0.08s/0.08s/0.11s (0.23s recovery); the last steps forward. Every Bombardiro chomp has a 0.27s windup and 0.65s recovery, with the same heavy knockback rather than a combo counter.

## Skillful spacing, not unlimited flight

The sprint-strike mechanic is inspired by deliberate movement resets, not an exact Minecraft combat reproduction. Sprint forward until the HUD says the strike is ready. The next M1 attempt consumes that charge, even on a miss. A successful charged strike adds **20% horizontal knockback**, not extra damage or upward launch.

To prepare another charge, release movement for at least **0.12s**, then rebuild forward sprint for **0.18s**. There is a **0.7s** recharge floor. The server checks physical movement and facing; toggling Shift or spamming input messages alone does not grant charges. Each victim has **1s protection from repeated bonus amplification**, limiting bonus-knockback loops. Normal attacks and ability knockback still function during that protection.

Every fighter has a finite air-jump allowance and one R recovery per airtime, as well as its normal cooldown. Resetting requires real departure and landing; repeated grounded input cannot immediately refund recovery. No kit or ultimate grants indefinite flight. Projectiles have finite travel, collision and line-of-sight checks; melee fighters retain faster pursuit options and punishable ranged startup.

Ability movement uses bounded server-owned velocity constraints, not one-frame velocity jolts that the walking controller immediately erases. Torpedo pushes forward at 62 studs/s for 0.42s (about 26 studs of powered travel, with some momentum after release) and stops at solid cover. Tail Launcher hits at 0.32s and sends nearby enemies upward to set up an aerial chase; it is not a projectile.

Recovery identities are deliberately different: Tralalero makes a long ballistic arc; Chimp gets the strongest ordinary jump and 1.25s of rising Peel Glide; Ballerina gets two 0.22s air steps, with the second starting 0.40s after input, plus two normal air jumps; Bombardiro has a weaker ordinary jump but 1.6s of powered flight. Chimp's glide starts with 24 studs/s upward lift, then sustains 12 studs/s upward velocity for the remainder of its finite drive. Glide/flight release back to normal gravity when they end. They can turn gradually and allow attacks after startup; firing Q slows powered flight. Walls, interruption and expiry end the drive. These safeguards are not a claim that latency or every map edge case has been fully tested.

Chimp's third M1 is a real 5-damage banana projectile, not incidental yellow debris: it travels at 54 studs/s, ends at first contact or 13 studs, and cannot consume another melee swing's bonus. Boomerang now travels at 64 rather than 48 studs/s, taking 0.5s per unobstructed 32-stud leg. Carpet Run releases three independently tracked falling bombs; bombs already released still resolve their collision/impact after the flight action ends.

## Optional four-stock practice

In Studio, use **G at the green SMASH PRACTICE pad near the spawn/gallery**. The separate island contains cover, side platforms, a Core and a movable practice target. Death or falling below the ring-out threshold costs one stock. At zero, a new practice set starts after the reset delay; this is not a competitive winner/loser round system. Use its exit pad to return after combat/cooldowns finish.

The island is Studio-only and can be disabled before Play with `game.ReplicatedStorage.TungPrototype:SetAttribute("PracticeEnabled", false)`. It awards no wins, currency or persistent rewards and uses no DataStores.

The five gallery targets, original Tung practice dummy and island target all accept physical knockback. Four seconds without a new hit returns a target home, clears its velocity and restores health; another hit restarts that wait. Lethal hits or ring-outs rebuild a fresh target after one second. Only these explicitly designated training targets are managed; decorative source models are untouched.

## Animation and asset limits

All five use their own mapped bone structures, with bounded jump/landing follow-through and directional hit recoil. Shark tail/fins wiggle; Bombardiro's jaw, wings and tail react; Chimp's supported banana-base/tip chain flexes. Ballerina's limbs/wrists follow through. Tung's corrected authored combat arm poses are preserved.

The four non-Tung ultimates now have sustained articulated choreography: Shark jaw snaps and swimming limbs, Chimp body/peel whips, Ballerina extended arms/spins and a finishing kick, and Bombardiro wing/head recoil. Their effects distinguish water crests, banana fans, ballet ribbons and bomb smoke. Shark bite slashes are positioned beyond the visible head rather than at the controller capsule. Bananas use a curved, tapered silhouette; Peel Trap leaves a three-strip peel on the floor until it triggers, is replaced, or expires. Croc Bomb and Carpet Run use finned bomb silhouettes.

Combat audio uses five loaded Roblox built-in sound files with per-cue timing, pitch, volume and equalizer profiles, replacing the former swim/UI-slider cues. This is a mixed prototype sound palette, not a bespoke sound pack, recorded character voices, or subjective sound-quality approval.

The current Ballerina mesh has **no independent dress-hem bones**. Chimp's individual peel strips have **no verified independent controls**; his supported base/tip movement is not independent peel simulation. Face bones are deliberately left neutral instead of misusing them as cloth controls. Independent hem/peel motion requires additional bones and skin weights in the source asset. Chimp also has no humanoid arm/leg chains, so his basic attacks are banana-body/tip strikes, not fabricated human punches.

## Source and verification

The files under this `mvp` directory are the current authoritative brainrot implementation. `FighterDefinitions` supplies roster/HUD values; `TungCombatService` and `FighterCombatKits` execute attacks; `Pose`, `FighterPose` and the rig profiles handle presentation. `install-assets.luau` sanitizes/clones existing reviewed source geometry; it must not replace unrelated place content. Keep source changes synchronized with Studio. This is separate from the repository's root CopyTheScene project: **do not sync that root project into the brainrot place**.

### Packaging the brainrot overlay

From the repository root:

```powershell
rojo build brainrot-prototype/mvp/default.project.json -o build/BrainrotMVP.rbxlx
```

This build succeeded. `default.project.json` maps the brainrot shared/server/client source, `ServerStorage.BrainrotMVPTests`, six reviewed mesh assets and eight editable combat sequences. It maps **no Workspace content** and preserves unknown instances at its existing service/package/container boundaries. The result is a source overlay for the existing brainrot place, not a complete replacement place or the root game's map. No Rojo sync server was started during this export.

`assets/manifest.json` records the read-only live export. The build contains five character models, six MeshParts including the bat, **75 bones, two grip attachments (`WeaponGrip`, `BatGrip`), eight clips, 176 keyframes and 2,816 poses**. Mesh IDs/textures, native mesh dimensions, bind CFrames, identity pivot offsets, pose weights/easing and bat trail attributes are retained. Attributes use the explicit types documented in [Rojo's property format](https://rojo.space/docs/v7/properties/). Meshes/textures remain Roblox asset references, so asset access is still required. `export-reviewed-assets.luau` is the read-only serializer used; it refuses unreviewed classes or unexpected descendant attributes.

Packaging verification checked successful Rojo serialization and the resulting instance/property counts. **The exported build itself has not been reimported and visually verified in Studio**; do that in a separate test copy before treating this as an asset round-trip certification.

The final fresh-session regression passed **23 server suites and two live client suites**, including traveled projectiles, upward glide, dummy knockback/reset, projectile presentation, ultimate bone choreography, camera and HUD behavior. This resolves the prior non-rendering-session HUD check. A live gallery target took Tail Launcher's 8 damage, traveled about 6.24 studs and returned home at full health after the idle wait. Ballerina's ultimate was activated after collecting a Core through its normal prompt, and its articulated pose was observed. Final Rojo packaging passed; Studio was left stopped in Edit with temporary QA content cleared. Exact samples and the separation between current and historical evidence are in [VERIFICATION.md](VERIFICATION.md). These are single-session results, not complete visual QA or proof of multiplayer balance; nothing has been published by this work.

Before calling balance finished, run real two-player sets across every matchup, alternating pilots and map sides. Record wins, ring-outs, recovery success and damage opportunities. Specifically test melee pursuit against wall-aware ranged fire, Ballerina counter timing versus baited misses, sprint-strike spacing versus ordinary held combos, low-HP/high-knockback escapes, and lagged simultaneous hits. Tune one variable at a time rather than giving later unlocks automatic power advantages.
