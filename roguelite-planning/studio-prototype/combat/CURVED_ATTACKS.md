# Curved attacks and stationary practice target

Implemented September 22, 2026, in the roguelite prototype (not Copy The Scene).

- Normal zombies move at 12 studs/second, down from 13.5 (about 11% slower).
- Deck of Cards launches the three actual levitating card meshes in a staggered, spinning fan. Left, center and right paths curve toward the target; the resting cards disappear during their flight and replenish afterward. No bullet tracers. Base volley damage remains 16 split among three hits; prototype cooldown is 0.95 seconds. Extra-projectile, piercing and bouncing modifiers are supported.
- Pandora's Box opens its existing skinned lid hinge, launches after a 0.24-second opening, then closes. A pale-purple placeholder ball with a fading trail travels on a high mortar arc and bursts on impact. Replace `ReplaceableProjectile` in `ArcVisuals` when the skeleton-head asset is ready. Prototype blast tuning: 40 damage, 1.5-second cooldown, 50-stud targeting range, 7-stud blast radius.
- The existing `Workspace.Zombie_R15_ProvidedTextures_Studio` becomes a stationary Studio-only practice target. Walk within weapon range with weapons enabled; zombie spawning can remain off. It takes hit feedback, resets its 1,000 health on a lethal hit, and never grants shards, death rewards or life-steal healing. It does not attack the player. No new zombie asset is imported or substituted.

`ArcMotion` is shared path math. `ArcProjectiles` sweeps server-side collision along the curve, checks living ownership/equipment and walls, and owns damage. `ArcVisuals` clones the reviewed card meshes and renders flight, spin and the mortar trail locally. Client visuals never authorize hits. Active curved projectiles are capped at 192. Existing unrelated scene content is preserved.

## Verification

Card-route follow-up: each flight and bounce receives server-randomized hook width, lift and S-curve bend. Parameters are transmitted to clients, so render and collision use the same chosen route; randomness is never re-rolled per frame. Ordinary zombies now have 40 HP (reduced from 100); only the resettable practice target retains 1,000 HP.

Death retargeting: every in-flight card, Pandora mortar, regular projectile and rocket validates its target's health, tag and workspace membership. If any attack kills that target, surviving projectiles redirect from their current positions to the nearest live, unobstructed target within range, excluding prior hits. No suitable target means cancellation, not continued corpse targeting. Retargeting does not add damage, renew lifetime or spend bounce charges. Curved shots have a bounded two-times-range travel allowance, 10-second lifetime and at most eight death redirects; rockets and bullets retain remaining travel range. Client redirect packets keep the visible projectile instead of spawning an extra one. Melee keeps its existing swept swing and reacquires on its next attack.

Follow-up verification: 335 assertions passed, including 100 randomized endpoint/bounds samples and the prior gameplay regressions. The live client received 87 card flights with 87 unique route parameter sets; 85 had bend magnitude above 0.1. Studio console was empty and both Rojo builds passed. Temporary test scripts were removed by stopping the Play session.

`ArcAttackTests.luau` is a disposable Studio server-test script, intentionally not mapped into the production Rojo tree. Run with the same sandbox capabilities as CharacterService in a fresh single-player Play session with the existing display zombie. It verifies curve endpoints, raised midpoints, speed scaling, fanning, lid timing, five weapon types hitting with spawning off, harmless/no-reward practice, health reset, disabled weapons and wall-blocked acquisition.

Live client instrumentation additionally checks three flying cards, a mortar ball, its trail and a 90-degree lid opening. Visual inspection checks the existing lid mesh actually opens, not just its bone values. Multiplayer latency, published servers, max-modifier stress and skeleton-head art are not validated by these tests.

Observed single-client results on September 22: **33 assertions passed**. Practice hits by weapon during the sample: cards 9, Pandora 1, Glock 5, rocket 2, katana 6. Shards remained 60; no shard drops were created. Client probe saw three simultaneous flying cards, one mortar ball, the trail, a 1.5708-radian lid rotation and an apex above 15 studs. The open lid and launch were visually inspected in the Studio client. Both root and roguelite Rojo packages built successfully. Initial practice setup tried to set appearance properties unavailable to its sandbox; those optional assignments were removed without widening permissions.
