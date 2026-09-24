# Weapon behavior pass — September 23, 2026

## Motion and attack placement

Active melee attacks use a server-authored, replicated `AttackRoot` snapshot. Movement and jumping after launch no longer move the hit boxes or the visible cut away from their intended path. The attack plane uses the target height, so grounded enemies remain reachable while the player jumps. Recovery returns to the current moving weapon slot. Target eligibility, range and wall checks remain server-owned; the snapshot does not add homing or guarantee hits on enemies that move out of the strike.

Most melee uses a 2.1 animation rate before attack-speed modifiers: about 0.124 seconds of active cut and 0.276 seconds total. Nunchucks use 1.3 (about 0.2/0.446 seconds) and a 0.5-second base cooldown. Damage cadence is separate from animation speed, so high-cooldown heavy weapons strike quickly and then wait.

| Weapon | Behavior |
| --- | --- |
| Katana | Longer leftward, flatter diagonal follow-through, less inward rotation. Against one target, every third attack is a faster/deeper thrust; against groups, horizontal and diagonal cuts alternate. Thrust starts with the grip outside the avatar and carries the blade through the enemy. |
| Excalibur | Horizontal strikes only. |
| Gloves | Alternating left/right punches. A second nearby target enables the other fist against that target. Separate shared fist poses drive rendering and server hit boxes. Longer reach and faster extension. |
| Shovel | Top-down slam; 20 native knockback, combined with stat knockback and capped at 40. |
| Spatula | Retains horizontal strikes; 14 native knockback. |
| Steak | Melee slap; short impact-triggered wobble. |
| Cinder block | Heavy downward melee attack; 16 native knockback. |
| Pan / bat | Horizontal crowd attack; horizontal/downward variation against one target. |
| Kunai | Actual model flies straight, point-first. |
| Bowling ball | Actual ball thrown along a low arc, rotating in flight. |
| Eggs | Three visible reserve models; consecutive throws cycle through them. |
| Bowling pins | Three reserve models; slower 24-stud/s throws with vertical tumble, cycling through the reserves. |
| Boomerang | Spinning model, native rebounds to unhit targets, then return to the current weapon slot. Return flight causes no additional damage. |
| Mjolnir | Close horizontal melee within 8 base studs; modeled returning throw out to 32. Shared 2.4-second base cooldown; no new attack while the hammer is still in flight. |
| Rubber duck | Short flame stream with server-checked cone hits and wall blocking. |
| Molotov | Modeled, vertically tumbling throw; direct hits ignite through existing burn logic; impact leaves a 4.5-stud, 4-second fire area. |
| Fart gun | Small traveling green cloud/tail; impact creates a soft 5.5-stud, 5-second poison cloud with periodic damage. |

Range/speed/duration/area modifiers apply within caps. Fields tick every 0.4 seconds for 0.4 times resolved weapon damage; maximum three active fields per owner/weapon and 64 globally. Modeled flights are globally capped at 128 and expire after eight seconds. Bounces never revisit a hit enemy; damage falls to 65% on each rebound. Returning weapons do not damage on the way back. Flights and areas cancel if the owner dies, changes character, unequips the weapon, or disables weapons. No new client damage/target submission remote was added.

`SpecialMotion` is the shared throw trajectory/orientation module; `SpecialWeapons` owns collision, damage, redirects, returns and area ticks; `SpecialWeaponVisuals` renders existing templates and cosmetic effects. Existing card, Pandora, gun tracer, muzzle-flash and rocket systems retain their own paths.

## Validation

- `WeaponBehaviorTests`: 19,905 checks passed (classifications, cadence separation, Excalibur restriction, airborne attack plane, finite/continuous poses, recovery endpoints, thrust grip clearance/penetration, throw endpoints and behavior definitions).
- Updated `MeleeMotionTests`: 20,024 checks passed. `WeaponFollowTests`: 834 checks passed across 20/30/60/144 FPS.
- Actual single-client Studio Play: Excalibur, gloves, steak, block, shovel and close Mjolnir each produced hits with their expected melee styles.
- Single-target glove sequence: right/left/right/left, with no secondary fist target. Two-target check: alternating primary hands, separate second targets, and three secondary-target hits over 2.5 seconds.
- Movement regression: after strike start, moved the character nine studs sideways and six up; the attack frame stayed unchanged and still landed. Actual A/D/Space input also produced two katana hits during the movement observation.
- Actual modeled flight/hit checks passed for kunai, ball, egg, pin, boomerang, hammer and Molotov. Egg/pin equipped models each contain exactly three mesh instances. Boomerang hit a second target and emitted rebound/return segments. Final hammer return check observed two launches, one return and one completed flight within its observation window; the second was still active when observation ended.
- Duck check at six studs: five spray events and five hits over two seconds. Initial duck test at the edge of acquisition range produced no shots; rerun within range passed.
- Molotov fire and poison areas produced repeated practice hits. On a temporary non-practice 10,000-HP target, Molotov applied burn and six additional damage after 1.2 seconds. Shovel imparted 20 studs/s horizontal velocity with stat knockback set to zero. First knockback test retained anchored limb parts and was invalid; all-part-unanchored rerun passed. The temporary target survived and was destroyed after the test, without death rewards.
- Soft poison smoke and the actual client effects were inspected visually. Disabling weapons left no modeled flights, areas or transient puffs after cleanup. Final console was empty.
- Both the combat package and root CopyTheScene Rojo package built successfully. Changed Studio script sources were synchronized from repository files. Runtime test targets, camera/UI states and player positions are discarded when Play stops.

Multiple real clients, latency, published asset permissions, every stat combination, every avatar scale, crowded-map performance and final balance remain untested. Tests used Studio practice, not persistent rewards or DataStores. Original reference sheets/model assets are unchanged.
