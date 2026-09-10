# Library quality pass

LibraryQuality.server.luau runs after CornerPolish readiness. It replaces only named library block props, preserving other facility content, shelves, paper scatter, doors and traversal openings.

- Three static banker lamps with warm task lights.
- Four tinted, weathered spindle-back chairs with simple invisible collisions.
- One static CRT, keyboard and mouse set.
- Tiled worn carpet and damaged wallpaper; no additional floor overlay geometry.
- Bright edit view retained; no movement or upper-floor changes.

Validation: Rojo build succeeded. Inspected edit-time checkout, reading corner, close lamp, and a temporary night-lighting preview; restored bright edit settings afterward. Static templates have zero LuaSourceContainers. Live count: 3 lamps, 4 chairs, 1 computer set. Full client performance and multi-client play were not retested for this art-only pass.

Build: rojo build facility-blockout/default.project.json -o build/FacilityLayoutReview.rbxlx
