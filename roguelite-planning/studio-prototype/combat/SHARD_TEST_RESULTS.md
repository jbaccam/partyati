# Crystal shard verification — September 22, 2026

## Cyan glow and light-blue aura

Added client-only Neon to the pale cyan facets, a small shadowless blue PointLight, and a low-opacity blue aura using Roblox's bundled smoke texture. Three real death drops were visually inspected together in Studio Play against bright grass: luminous tips, visible soft blue haze, readable dark-blue facets and no separate orb. Aura particles stay attached during movement and are children of the pickup model, so normal visual destruction removes them. At most 32 nearby emitters and 12 nearby lights are enabled per client. No global lighting setting or server pickup/economy code changed. Both Rojo builds passed. The Play session ended before a separate aura-specific pickup cleanup observation; that observation is not claimed.

## Bobbing and magnetic pickup refinement

This section supersedes the original static pickup and consolidation behavior below.

- Updated `ShardTests.luau`: **37 assertions passed** in Studio, including delayed credit, intermediate flight position, replay prevention, ownership/distance/occlusion checks, cancelled teleport pulls, environmental deaths, lethal-hit/Died deduplication, currency cap, and **140 deaths producing 140 distinct pickups**. The former server drop consolidation cap is gone.
- Actual client samples measured **0.279 studs** of idle vertical movement over one second (configured amplitude ±0.16 studs). The client renders bobbing and slow rotation each frame.
- Actual movement pickup: sampled crystal-to-player distance fell from **2.285 to 0.175 studs** during the pull. All 18 in-flight samples still showed **44 shards**; after arrival the balance was **46**, with zero remaining server markers and zero remaining client models.
- Random health-orb generation and collection code, plus its combat call, were removed. Tests confirmed no `PracticeHealthDrop` existed. PickupRadius and shop item descriptions were updated.
- Both Rojo builds passed. Final Studio console output was empty.
- `ShardMotion` is shared; `ShardVisuals` is a StarterPlayerScripts LocalScript. The server replicates lightweight invisible markers and magnetic state; clients animate at most the nearest 128 models, prioritizing active pulls. Every underlying drop retains its value and identity. No pickup remote is added.
- Real multi-client contention, high-latency animation timing and maximum-density mobile profiling remain unverified. No persistent currency or DataStore access was used.

## Original implementation verification

Synchronized into the open roguelite Studio place `107877054949326`. The original scripts were retained in `ServerStorage.BeforeCrystalShards_20260922` before source updates. Only the roguelite modules/UI were changed. Temporary verification scripts and runtime fixtures were removed by stopping Play.

- `ShopTests.luau`: **606 assertions passed** in a normal Studio server Script with the renamed shard schema. Covers currency bounds, prices, refunds, purchases, locks, replay rejection, capacities and wave transitions.
- `ShardTests.luau`: **26 assertions passed** on the final source in a fresh Play session. Covers one drop per death, no immediate balance credit, duplicate death suppression, distance/owner/line-of-sight rejection, successful collection, replay rejection, living mob and shop-phase rejection, environmental/public drops, lethal hit attribution, Died/direct-finish idempotency, wave banking, abort cleanup, model cap/value consolidation and currency cap.
- A lethal-hit test exposed negative transient Humanoid health on an overkill hit. The damage accounting now clamps the observed final health to zero, so the reported damage and lifesteal cannot exceed the victim's remaining health. The final lethal test reports 100 damage for a 100-health victim.
- Actual client shop click: purchasing an 18-shard item changed the visible balance from **60 to 42**, marked the offer sold and applied its stats.
- Actual client wave entry and combat: mobs died, blue faceted shard geometry appeared, and nearby pickups increased the shard balance. Inspected the drop close up in the arena; no shard aura, emitter, trail, beam or light is attached.
- Isolated client movement check: a real zombie template died at `(56, 6, 440)`; the client walked toward its shard. Server balance changed **60 → 62**, the one pickup disappeared, and the HUD displayed **62 SHARDS**. No client reward request was used.
- Corrected HUD placement after visual inspection so the shard balance does not overlap the Shop button. Shop currency uses a preview of the shard geometry, cyan balance text, and SHARDS on reroll/refund controls.
- Both `rojo build roguelite-planning/studio-prototype/combat/default.project.json -o build/RogueliteKatanaCombat.rbxlx` and root `rojo build -o build/CopyTheScene.rbxlx` passed.
- Final fresh Studio console check was empty. No DataStore or persistent reward operations were performed.

The live version uses the native 24-facet, 48-WedgePart shard model. Astra's textured 76-triangle single-mesh FBX/GLB exports are delivered but have not been uploaded/imported as a Roblox MeshPart. Maximum-density/mobile profiling and multiple real clients competing for public drops remain untested. No published-server verification is claimed.

For source synchronization, `CrystalShardVisual` maps from `../../crystal-shard/CrystalShardVisual.lua` into `ReplicatedStorage.RogueliteCombat`; `ShardDropService` maps into `ServerScriptService`. Existing Studio scripts are sandboxed: the new server module inherits CharacterService's Sandbox/Capabilities, and the visual module inherits WeaponPresentation's. Preserve the existing security configuration when synchronizing individual modules.
