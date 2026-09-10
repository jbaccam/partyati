# Brainrot fighter roster

This roster adapts the strongest ideas from Super Smash Mobs into an original Roblox combat system: four lives, distinct weight and mobility, universal air jumps, short ability cooldowns, a recovery move for every fighter, and a contested ultimate pickup. Every fighter has a clear strength, a punishable weakness, and at least one combo route.

The numeric values are an initial balance target. They should be tuned from real four-player matches, not treated as permanent.

## Shared combat rules

- **Lives:** 4 per player. Falling outside the arena or reaching 0 health loses one life.
- **Health:** Restored fully after each respawn. Missing health increases received knockback, so damaged fighters become easier to launch.
- **Knockback:** `move knockback × (1 + missing-health-percent × 1.1) ÷ Weight`. Direction, attack charge, and temporary effects apply afterward.
- **Respawn:** 2 seconds of invulnerability, removed immediately when the player attacks.
- **Basic attack:** M1 performs a three-hit combination. The combo resets after 0.8 seconds without another input.
- **Abilities:** Q and E are signature tools. R is always the fighter's recovery move. F activates the ultimate after collecting the arena's Brainrot Core.
- **Air jumps:** Space can be used the listed number of times after leaving the ground. Landing restores all air jumps and the once-per-airtime recovery flag.
- **Activity:** After 12 seconds without dealing or receiving damage, a player is revealed to opponents. After 18 seconds, they take 2 damage per second until they re-enter combat.
- **Combat geometry:** Damage and hit detection use server-owned capsules and cast shapes. The visual mesh never determines reach or hurtbox size.
- **Standard hitboxes:** Small = 3.5 × 5.5 × 3.5 studs; Medium = 4 × 6 × 4 studs; Large = 4.75 × 6.5 × 4.75 studs.
- **Fairness:** Clients send input intent and aim direction. The server validates phase, ownership, cooldown, range, line of sight, targets, damage, and knockback.

## Roster overview

| Fighter | Role | HP | Speed | Jump | Air control | Weight | Air jumps | Difficulty |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Tung Sahur | All-rounder bruiser | 115 | 20 | 52 | 0.85 | 1.12 | 1 | Easy |
| Tralalero Tralala | Aerial rushdown | 95 | 18.5 | 58 | 1.15 | 0.88 | 2 | Medium |
| Ballerina Cappuccina | Technical duelist | 92 | 19.5 | 60 | 1.20 | 0.82 | 2 | Hard |
| Bombardiro Crocodilo | Artillery heavy | 108 | 14 | 48 | 0.70 | 1.15 | 1 | Medium |
| Chimpanzini Bananini | Trickster | 100 | 18 | 56 | 1.00 | 0.95 | 2 | Medium |
| Cappuccino Assassino | Assassin | 88 | 20.5 | 57 | 1.10 | 0.80 | 2 | Hard |
| Brr Brr Patapim | Ground controller | 110 | 15 | 50 | 0.75 | 1.14 | 1 | Medium |
| Lirili Larila | Defensive grappler | 118 | 15 | 50 | 0.75 | 1.20 | 1 | Easy |
| Frigo Camelo | Tank zoner | 130 | 13.5 | 47 | 0.65 | 1.28 | 1 | Easy |
| La Vacca Saturno Saturnita | Space controller | 112 | 15.5 | 54 | 0.95 | 1.10 | 2 | Hard |
| Orangutini Ananassini | Power grappler | 122 | 16.5 | 51 | 0.80 | 1.18 | 1 | Medium |
| Cocofanto Elefanto | Defensive zoner | 116 | 14.5 | 49 | 0.72 | 1.20 | 1 | Medium |

`Jump` is the desired upward velocity in studs per second. `Weight` divides received knockback; values above 1 are harder to launch.

## Fighter kits

### Tung Sahur — all-rounder bruiser

- **M1 — Wooden Hands:** 3 + 3 + 6 damage. Two palm strikes into a broad uppercut.
- **Q — Bat Beat:** 10 damage, 38 knockback, 5-second cooldown. Wide club swing; the outer edge deals 13 damage and 46 knockback.
- **E — Sahur Slam:** 12 damage, 42 knockback, 8-second cooldown. Ground pound with a 9-stud landing ring.
- **R — Dawn Call:** 7 damage, 28 knockback, 8.5-second cooldown. Upward-forward launch used for recovery.
- **Passive — Keep the Beat:** Quick successive hits build three stacks; each gives 3% damage and 4% speed.
- **F — Midnight Alarm:** Two club-on-body sonic booms (8 + 8), a resonant sweep (14), and a final club slam (24) over 3.7 seconds. Expanding effective radii: 10/12/14/20 studs. Each impact has a short warning; final knockback 82. Requires one Core. Total base damage 54 before Beat bonuses, if all four hits connect.
- **Game plan:** Easy fundamentals fighter. Bat Beat catches movement, Slam punishes landings, and Beat stacks reward staying active.

### Tralalero Tralala — aerial rushdown

- **M1 — Fin Flurry:** 2.5 + 2.5 + 5 damage with quick recovery.
- **Q — Shark Torpedo:** 11 damage, 39 knockback, 6-second cooldown. A steerable 15-stud rush.
- **E — Sonar Snap:** 4 damage, 10-second cooldown. Marks the nearest enemy in a cone for 4 seconds; Tralalero launches that target 15% farther.
- **R — Wave Breach:** 8 damage, 30 knockback, 9-second cooldown. Ride a wave up and forward.
- **Passive — Blood in the Water:** Traveling 20 airborne studs adds 4 damage to the next hit.
- **F — Feeding Frenzy:** Seven seconds of fast aerial swimming with three bite rushes and a final tail launch.
- **Game plan:** Chase above and beyond ledges, then use the second air jump or Wave Breach to return.

### Ballerina Cappuccina — technical duelist

- **M1 — Ribbon Combination:** 2 + 2 + 5 damage; fastest basic recovery in the roster.
- **Q — Pirouette:** 11 total damage, 35 knockback, 5.5-second cooldown. Four light spin hits into a kick.
- **E — Pointe Counter:** 9 damage, 36 knockback, 10.5-second cooldown. A 0.4-second melee counter that also deflects projectiles.
- **R — Grand Jete:** 7 damage, 25 knockback, 7.5-second cooldown. Fast aimed leap and kick.
- **Passive — Perfect Tempo:** Using different attacks builds Tempo; three stacks speed up the next ability's startup by 20%.
- **F — Grand Finale:** A spotlight pulls enemies through a rapid dance sequence before the launching final pose.
- **Game plan:** Win through timing and move variety. Lowest durability makes missed counters costly.

### Bombardiro Crocodilo — artillery heavy

- **M1 — Wing Bash:** 4 + 4 + 7 damage with long reach and slow recovery.
- **Q — Croc Bomb:** 12 damage, 44 knockback, 6.5-second cooldown. Lob at the cursor; close explosions recoil Bombardiro safely.
- **E — Carpet Run:** 12 potential damage, 11-second cooldown. Fly forward and drop three small bombs.
- **R — Afterburner:** 6 damage, 24 knockback, 10-second cooldown. Upward-forward boost with a damaging trail.
- **Passive — Payload:** An airborne bomb hit removes 1.5 seconds from Afterburner's cooldown once per cast.
- **F — Grand Bombardment:** Five warned impact circles appear in sequence before bombs strike.
- **Game plan:** Control landings and lanes. Wide visual and slow movement make careless hovering punishable.

### Chimpanzini Bananini — trickster

- **M1 — Fruit Fists:** 3 + 3 + 5 damage.
- **Q — Banana Boomerang:** 7 damage going out and 5 returning, 5.5-second cooldown.
- **E — Peel Trap:** 8 damage, 28 knockback, 9-second cooldown. One active peel lasts 8 seconds and pops the victim upward.
- **R — Vine Grapple:** 5 damage, 7.5-second cooldown. Grapple terrain to swing or an enemy to pull both fighters together.
- **Passive — Top Banana:** An ability hit gives the next M1 a short lunge and 3 extra damage.
- **F — Banana Stampede:** Three warned waves of banana apes charge through alternating lanes.
- **Game plan:** Place a peel, force movement with the boomerang, then grapple into the trap or a powered M1.

### Cappuccino Assassino — assassin

- **M1 — Spoon Work:** 3 + 3 + 6 damage with narrow reach and very fast recovery.
- **Q — Espresso Dash:** 9 damage, 30 knockback, 4.5-second cooldown. A successful hit permits one immediate recast.
- **E — Saucer Parry:** 10 damage, 38 knockback, 11-second cooldown. Reflect a projectile or move behind a melee attacker and strike.
- **R — Steam Step:** Two short directional bursts, 9-second cooldown. Both charges return on landing.
- **Passive — Caffeine Rush:** Three ability hits within 6 seconds grant 15% speed and 25% faster cooldown ticking for 4 seconds.
- **F — Final Serving:** Three clearly telegraphed target dashes followed by a launching final cut.
- **Game plan:** Convert one opening into a rapid combo and escape. Lowest health and weight punish failed approaches.

### Brr Brr Patapim — ground controller

- **M1 — Branch Bash:** 4 + 4 + 6 damage with broad coverage.
- **Q — Root Line:** 8 damage, 7-second cooldown. Roots travel 32 studs over connected ground and hold the first target for 0.55 seconds.
- **E — Acorn Guard:** 25-health shield, 12-second cooldown. Lasts 2.5 seconds and bursts for 6 damage when it ends.
- **R — Canopy Bounce:** 6 damage, 25 knockback, 9-second cooldown. Spring upward from a leaf platform.
- **Passive — Seed Trail:** Ground movement grows up to two temporary seeds; nearby casts consume one for 15% more range.
- **F — Ancient Stampede:** Forest spirits charge through three marked lanes, followed by an upward tree burst.
- **Game plan:** Shape the ground fight while continuing to move and plant seeds.

### Lirili Larila — defensive grappler

- **M1 — Trunk and Tusk:** 4 + 4 + 7 damage, ending in a lifting tusk swing.
- **Q — Trunk Snatch:** 7 damage, 6.5-second cooldown. Pull the first target within 16 studs into close range.
- **E — Cactus Brace:** 10-second cooldown. Take 50% less damage for 1.2 seconds; contact attackers take 4 damage and bounce away.
- **R — Desert Geyser:** 6 damage, 28 knockback, 9-second cooldown. Blast water underneath to rise and push nearby fighters aside.
- **Passive — Water Reserve:** Damage taken fills a meter; at 100, the next ability gains 25% size and knockback.
- **F — Oasis Crash:** Select a visible landing circle, leap, and crash down for 24 damage and 86 knockback.
- **Game plan:** Pull fragile enemies close, absorb their retaliation, and spend the reserve on a decisive launch.

### Frigo Camelo — tank zoner

- **M1 — Fridge Door:** 5 + 5 + 8 damage; strongest and slowest basic combination.
- **Q — Ice Tray:** Three ice cubes deal 3 damage each, 6-second cooldown, and slow movement 20% for 1.5 seconds.
- **E — Cold Storage:** 12.5-second cooldown. Move slowly with 40% damage reduction for 1.5 seconds, then release a 6-damage chill burst.
- **R — Freezer Eject:** Fire an 8-damage ice block and recoil the opposite way; aim down to recover upward.
- **Passive — Deep Freeze:** Four ability hits within their stack windows freeze a target for 0.45 seconds, followed by 5 seconds of Frost immunity.
- **F — Power Outage:** A seven-second cold field slows enemies while five warned icicles fall.
- **Game plan:** Survive pressure, slow faster fighters, and use recoil to compensate for poor natural mobility.

### La Vacca Saturno Saturnita — space controller

- **M1 — Horn Orbit:** 3 + 4 + 6 damage.
- **Q — Orbit Ring:** 7 damage outbound and returning, 6-second cooldown.
- **E — Gravity Well:** 8 total damage, 12-second cooldown. A warned 3-second sphere pulls enemies toward its center.
- **R — Saturn Slingshot:** 7 damage, 9-second cooldown. Orbit an aimed point briefly, then launch along the tangent.
- **Passive — Low Gravity:** Holding jump reduces fall speed 35% for up to 1.2 seconds; attacking cancels it.
- **F — Event Horizon:** Pull fighters toward a black hole for 4 seconds, then launch them outward.
- **Game plan:** Bend enemy movement around the ring and gravity well, then slingshot to a safer orbit.

### Orangutini Ananassini — power grappler

- **M1 — Pineapple Pummel:** 4 + 4 + 8 damage with long ape-arm reach.
- **Q — Pineapple Pound:** 13 damage, 48 knockback, 6.5-second cooldown. An armored overhead smash that resists light knockback during startup.
- **E — Peel and Throw:** 9 damage, 44 knockback, 9.5-second cooldown. Grab at close range and choose a horizontal throw direction.
- **R — Canopy Clamber:** 6 damage, 8.5-second cooldown. An upward arm pull followed by a forward pull.
- **Passive — Heavy Hands:** Landing an aerial hit gives the next grounded M1 finisher 25% more knockback for 4 seconds.
- **F — Jungle Rumble:** Eight seconds of improved speed, resistance to light flinches, and empowered warned ground pounds.
- **Game plan:** Read defensive movement, grab shields and braces, then turn aerial hits into dangerous grounded finishes.

### Cocofanto Elefanto — defensive zoner

- **M1 — Husk and Tusk:** 4 + 4 + 7 damage with broad frontal protection.
- **Q — Coconut Cannon:** Charge from 6 damage/24 knockback to 14 damage/48 knockback, 6.5-second cooldown.
- **E — Shell Shelter:** Block up to 30 projectile damage for 2 seconds, 12-second cooldown; reopening pushes nearby enemies for 5 damage.
- **R — Trunk Jet:** 6 damage, 25 knockback, 9.5-second cooldown. Spray water downward for rising, steerable recovery.
- **Passive — Thick Husk:** After 8 seconds without taking damage, the next hit deals 20% less damage and 30% less knockback.
- **F — Tropical Monsoon:** A seven-second moving storm surrounds Cocofanto with rotating coconuts and water bursts.
- **Game plan:** Win slow projectile exchanges and force opponents to approach the shell on Cocofanto's terms.

## Recommended implementation order

1. **Tung Sahur:** establish server hitboxes, damage, knockback, cooldowns, lives, input, and UI on the existing animated prototype.
2. **Tralalero Tralala:** prove aerial movement, multiple air jumps, and ledge recovery.
3. **Bombardiro Crocodilo:** prove projectiles, warned area attacks, and self-recoil.
4. **Frigo Camelo:** prove status effects, damage reduction, and heavyweight balance.
5. Add Ballerina and Cappuccino after counters, deflection, and rapid movement are reliable.
6. Add Chimpanzini, Patapim, and Saturnita after grapples, traps, and placed zones are reliable.
7. Add Lirili, Orangutini, and Cocofanto after grabs and defensive states are reliable.

The first four form a useful alpha roster: balanced bruiser, fast aerial fighter, ranged heavy, and defensive tank. They exercise the combat engine without requiring every complex mechanic at once.

## Balance targets

- A complete M1 string should deal 9–18 damage and remain escapable unless set up by another move.
- Ordinary abilities should deal 5–14 damage. High damage requires clear startup, short range, or a long cooldown.
- Hard control should usually last 0.35–0.6 seconds. A target gets temporary immunity after repeated control.
- A fighter should need roughly 7–12 clean neutral wins to remove a full-health stock without an early ledge launch.
- Every recovery must have a visible route, limited steering, and a punishable ending.
- Ultimates may swing a fight but should not guarantee a stock against a healthy, correctly positioned opponent.
- No purchase may improve damage, cooldowns, mobility, health, weight, lives, or ultimate access.

The canonical machine-readable numbers are in `src/shared/FighterDefinitions.luau`.
