# Dead-target retargeting and early enemy tuning

September 22, 2026. Normal spawned zombies now have 40 HP instead of 100. The reusable stationary practice dummy retains 1,000 HP and resets. Weapon base damage and class modifiers are unchanged. A base 16-damage card volley therefore needs about three complete noncritical volleys, instead of seven, before class/modifier differences.

ProjectileTarget provides server-owned health/tag/world/range/line-of-sight checks. ArcProjectiles, StatProjectiles and RocketProjectile track their launch target. When it dies or is removed, they choose a reachable replacement from the projectile's current position. This works regardless of which weapon/player killed the mob. With no replacement, they cancel. Previous hits stay excluded; death retargeting preserves damage and bounce counts. All movement remains swept for collision. Time/travel budgets bound repeated redirects. ArcVisuals blends its current position into the new curve and RocketVisuals preserves its model on redirect.

RetargetTests.luau is excluded from the production Rojo tree. In Studio, 21 checks passed against the actual projectile modules with isolated targets: first-of-six cards kills the target and remaining cards from two decks hit the next; external kills redirect each of cards, mortar, bullets and rockets; no corpse hits; alive/zero-health, previous-hit, travel-range and wall rules; no hit when no replacement exists. Console remained empty. Both Rojo packages built successfully.

No multiplayer latency/ownership contention, published-server validation or maximal modifier stress is claimed. Melee follows its existing finite swing and reacquires on the next attack, rather than teleporting an active swing to a new enemy.
