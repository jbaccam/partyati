# Mob impact and death effects

References: `slash and thrust.mp4`, `multiple weapons - rocket launcher - club - axe - shotgun - pistol.mp4`, and the three supplied Brotato screenshots. The second video is 679 frames at approximately 30.058 FPS (22.59 seconds); around 14.05–14.25 seconds the outward white spokes disappear first while separated red blobs continue spreading in an uneven round outline. The first video’s 0.4–0.8-second hit/death sequence shows the same separation of motion. Contact sheets are under `build/mob-fx-reference-*`; selected asset previews are `build/mob-fx-final-selection.png`.

## Composition

- Ordinary surviving hit: a distinct white-only burst of 6–8 outward needles, lasting 0.24–0.30 seconds with a longer bright hold. Repeated hits on the same mob are locally coalesced within 0.07 seconds. Red particles are reserved for the death composition.
- Secondary/status damage: a smaller white impact of three outward needles; there is no random chance to skip the effect.
- Death: 5–7 brief outward white needles, followed by 9–12 round red particles on randomized angles/radii around an uneven circular perimeter. Most are round droplets; about 20% use the selected irregular splat. White lasts 0.12–0.18 seconds; red lasts 0.29–0.43 seconds after a 0.025–0.065-second delay. No long red slashes, gold sprites, large slash clusters or starbursts.
- Particle size, angular offsets, radius and lifetime vary independently. White rays never receive arbitrary rotation: the angle driving the radial position also drives rotation after correcting the source sprite axis. Billboard rendering keeps the outward composition readable from different camera angles.

## Integration and bounds

`CombatEffectsService.Hit` appends effect position, lethal and secondary flags to the existing damage-number event. Lethal hits skip the ordinary hit burst; the idempotent `ZombieDeath` event owns the death burst. Damage numbers and the short living-mob white flash remain. `StatProjectiles.Shot` appends a mob-contact flag so the old bullet impact only runs on environment contacts, avoiding stacked mob effects. Damage/targeting rules are unchanged.

All visuals are client-only, noncolliding and detached from dead NPCs. Bursts are distance-culled at 120 studs, with separate budgets of 20 impacts and 28 deaths. Each category replaces only its own oldest burst, so deaths cannot consume all surviving-hit feedback. All sprites/anchors are removed after their lifetime, and the render connection disconnects if its visual container is removed. Maximum burst life is under half a second.

The source sheets are unchanged; ImageRect crop metadata and native-axis angles live in `assets/mob-fx-selection.json`. Asset provenance is in `../ASSETS.md`. Studio sources are synchronized with matching readback and a backup. The new module loads successfully in Edit and both Rojo builds pass. Gameplay/visual testing is left to the user; this is not claimed as a verified exact match.

## Surviving-hit visibility correction

The live client had the surviving-hit hook and confirmed hit count. The old hit billboard originated inside the living mob and used depth occlusion; small white streaks could be hidden until they faded. Death removed the occluding body. The impact billboard now tracks the short-lived contact location and is moved along the view direction just ahead of the mob bounding box's camera-facing support plane, recomputed as the camera moves. It keeps AlwaysOnTop=false so walls still occlude it. Death placement and red-ring composition are unchanged.

The impact/death presets are now visibly distinct, have separate budgets, and still use their existing nonlethal Hit and idempotent ZombiePopped event paths. Source synchronized and backed up in ServerStorage.BeforeSeparateVisibleHitImpact_20260922. Module load and both Rojo builds passed; no gameplay or visual playtest was run.

## Stronger hit impact tuning

At the user's request, surviving-hit rays are approximately 50% larger (1.25–1.75 studs), with 6–8 rays per regular hit, a 0.24–0.30-second lifetime and full opacity for the first half of that lifetime. They shrink less while spreading to 2.0–2.7 studs. Source aspect ratios and radial orientation are preserved. Secondary hits use three rays. Death parameters are unchanged. Source readback and both Rojo builds passed; no playtest. Backup: ServerStorage.BeforeStrongerHitImpacts_20260922.
