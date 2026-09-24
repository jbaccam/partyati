# Shop UI and weapon tiers — validation, September 22, 2026

## Delivered

- Taller content-sized offer cards; common, blue, purple and red tier fills and borders.
- Separate inset icon well, price plus crystal image inside each offer, and Lock below the card.
- Shop/wave left, crystal balance near the center, reroll with price and crystal on the right.
- Sold offers disappear; owned items/weapons pack without unused slot outlines.
- Selection dims the background and anchors the detail panel above the chosen owned icon. Detail contents scroll on short screens. Combine, recycle and cancel use the server snapshot and copy identity.
- 35 supplied PNGs used in shop, owned inventory and creative inventory. Glock has no supplied image and retains its model preview. Existing nonweapon item illustration library remains in use.
- Distinct stats for 36 weapons, four tiers, bounded native projectile traits, server combining and linear enemy wave growth (see `../combat/WEAPON_BALANCE.md`).

## Evidence

Tested in the connected roguelite Studio place, 107877054949326. All changes target the existing roguelite scripts; unrelated map and game content were preserved. HTTP was temporarily enabled for local source synchronization and restored to its previous value. No DataStore setting changed.

- `WeaponBalanceTests.luau`: passed 571 assertions.
- `ShopTests.luau`: passed 630 assertions, including malformed/stale requests, phase restrictions, same-ID/same-tier manual combine, full-slot automatic combine, tier cap and price/refund conservation.
- `CharacterStatsTests.luau`: passed 2,314 assertions. Legacy test fixtures corrected for explicit Practice-only builds and current slow baseline.
- `StatProjectileTests.luau`: passed eight groups / 12 hit callbacks, including native tier piercing/rebounds, damage falloff, unique targets, walls, size/speed and rocket splash. Targets are isolated from enemy-spawn cleanup.
- `ShopLayoutTests.luau`: passed actual rendered bounds and TextFits checks at 1920x1080, 1440x900, 1280x720, 1024x768, 800x600, 640x360 and 390x844. These are resized client UI surfaces, not claims of physical-device testing.
- Actual mouse input: two common Katanas combined into one tier-2 Katana and an empty second slot; no currency charge; selection closed. The detail bottom was 12 pixels above its inventory icon.
- Actual mouse input: bought a tier-2 Shotgun, locked an offer, rerolled, and confirmed the locked token survived and inventory/currency changed on the server.
- Actual Start button and keyboard movement: combat activated with weapons/zombies enabled; the session subsequently returned to Shop with earned run XP and shards. Studio practice did not write persistent rewards.
- Both `rojo build -o build/CopyTheScene.rbxlx` and the roguelite combat project build passed. Rojo serve was run for the roguelite project; final changed source strings were also verified against the files through the Studio connection.

Temporary fixtures and test scripts were confined to Play and removed on restart. Final preview is a normal fresh shop session.

## Limits

Multiple real clients, published DataStores, physical mobile/gamepad interaction and long-run balance were not tested. Wave HP/damage uses the supplied Brotato reference; player stats, movement and population retain this game's existing tuning, so equal overall difficulty is not claimed. The 35 supplied PNGs omit Glock and nonweapon item art.

## September 23 visual refinement

The shop now uses 3.5-pixel tier outlines, saturated blue/purple/red fills, darker common cards, Fredoka One headings/buttons, and heavier Source Sans body text. Stat labels use colons with cream labels and colored values. Price text and the crystal form one centered group; dark buttons have visible 2.5-pixel outlines and hover/focus feedback. Owned icon backgrounds are tinted more strongly by tier. Stats heading is centered, the active stat tab is highlighted, and bottom navigation matches the shop.

Clipping was fixed by reserving six pixels around the root and scrolling contents for border strokes. Narrow layouts put Reroll on its own row. Currency text uses measured bounds without a minimum-size constraint that previously prevented correct scaling. Header/price placement, no empty inventory slots, and server action contracts are preserved.

Validation: actual rendered ShopLayoutTests passed all seven existing resolutions (390x844 through 1920x1080), including new checks for left/right card border visibility, minimum border thickness, centered complete currency groups and price bounds. Focused weapon panel was clicked and visually inspected in Studio. No UI errors appeared in Studio output. Both Rojo builds passed. Gameplay logic was not changed in this refinement. Physical devices and controller interaction were not tested.
