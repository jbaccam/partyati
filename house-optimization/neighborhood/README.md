# Neighborhood cleanup

Native Studio models in this directory are the authoritative exports for this cleanup. `house-NN.before.rbxm` files are reversible backups; `house-NN.optimized.rbxm` files contain the finished house at its existing position. Do not insert both versions together. The index-to-house mapping and exact counts are in `audit.json`.

Scope: the eleven inspected neighborhood roots, including the previously optimized nested House. No changes to CopyTheSceneWorld, game services, global lighting, or unrelated repository gameplay source.

Removed redundant audio, fire/particle/beam effects, vehicle objects, books/bookshelves, vegetation, toys, clothing/towels, dishes, small counter/desk clutter, decorative light fixtures, and non-door scripts. Generic fixtures were identified by original light positions and compact model bounds. Major furniture, rooms, stairs, doors, pool and yard structures remain. The cabin's multi-part shutters and floor vents are now simple panels of the same size and color.

The nice house also shed unused import values/configurations, redundant texture overlays, invisible import markers, excess crown/rail trim, and redundant containers. Identical adjoining solid blocks were consolidated without filling gaps. Small decorative parts had collision/touch/shadows disabled. New illumination uses spaced invisible anchored parts with shadowless lights.

Ambiguous geometry retained: generic paneled doors, the 419-part tiled shower, large dressers/cabinets, structural posts, roof wedges, floor assemblies, and major entertainment centers. The large generic house still has dense primitive/detail geometry; the nice house remains the largest asset and should not be treated as performance-certified for multiple simultaneous copies.

Working door scripts, panel assemblies and triggers were protected. The earlier 25-door anchored runtime and seven repaired mansion sliders remain; slider audio references were removed along with their sounds. Other pre-existing door/garage motor scripts remain. Imported static door geometry is not a newly implemented interactive door system.

Validation details and counts are recorded in audit.json. Multiplayer load testing and published-device performance are not verified. The unrelated Rojo world is not the source of these imported houses.
