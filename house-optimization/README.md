# House performance cleanup — September 10, 2026

> **Door repair update:** `House.optimized.rbxm` now includes the working server door controller (25 tested door groups). Its current size is 1,178,620 bytes and it contains 10,590 descendants. The original cleanup inventory below and before/after JSON snapshots remain historical records from before the two controller instances were added. The door functionality gap documented below has been repaired; see [DOOR-REPAIRS.md](DOOR-REPAIRS.md).

Applied only to `game.Workspace.Folder.Folder.Folder.Folder.Folder.Folder.Folder.Folder.Folder.Folder.Folder.Folder.Folder.Folder.Folder.Folder.House` in **Host A Party!**, place ID 98380943666065. The main House instance and its enclosing folders remain in Studio. No other house or game settings were edited.

| Type | Before | After | Removed |
|---|---:|---:|---:|
| BaseParts | 10,014 | 6,889 | 3,125 |
| MeshParts | 665 | 331 | 334 |
| Models | 1,068 | 629 | 439 |
| Scripts | 55 | 0 | 55 |
| Sounds | 3 | 0 | 3 |
| Lights | 77 | 36 | 41 |
| Textures | 2,245 | 2,117 | 128 |
| Decals | 81 | 70 | 11 |
| SurfaceAppearances | 42 | 0 | 42 |

BaseParts include MeshParts, seats, wedges, and unions. Textures and Decals are counted separately by ClassName; Roblox's IsA("Decal") also counts Textures, so that combined value is not used here. Models exclude the main House itself. Total descendant instances fell from 15,002 to 10,588. Part count fell 31.2%; MeshParts fell 50.2%.

## Saved artifacts

- **House.optimized.rbxm**: native Roblox engine export of the finished House, 1,175,167 bytes. This is the authoritative optimized model asset.
- **House.before.rbxm**: native export of the original unmodified House, 1,606,514 bytes.
- **before.json / after.json**: inventories, property summaries, and exact class counts.
- **changes.json**: ordered removal, property, reparenting, restoration, and new-light records. Operation IDs refer to before.json, not after.json. This is an audit log, not a standalone replay script.

The open Studio place contains the edits; it was not published. The exports contain only this House and do not overwrite other Studio content. These assets are deliberately separate from the unrelated Copy The Scene Rojo project.

## Cleanup performed

- Removed reviewed foliage, flowers, palms, plant models, cups, jars, a decorative bottle, small accessories, a book, several small picture frames, bathroom dispensers, and complex ceiling decorations.
- Removed lamps, chandeliers, sconces, hanging fixtures, small bulbs, and many decorative light pieces. Replaced the original 77 lights with 36 PointLights on invisible 0.2-stud anchored Parts. Those Parts have collision, touch, query, and shadow casting disabled; the lights have shadows disabled and ranges capped at 23 studs.
- Removed all 55 non-door scripts: 53 empty/decompilation-placeholder seat/toilet scripts and two animated-water texture scripts. Removed 112 animations, three non-door sounds, two particle emitters, eight beams, and three unused toilet ClickDetectors.
- Removed 17 fully enclosed pieces using full oriented-box corner containment inside known opaque primitive blocks. This does not establish that every inaccessible piece in a complex union was found.
- Consolidated adjoining identical plain solid blocks while preserving their occupied shape. A final check restored three merged seating pieces and the dimensions of two remaining seats; all 119 original seats are present.
- Removed 834 sub-quarter-stud nonfunctional hardware/ornamental pieces. Main cabinet handles, door handles, furniture surfaces, and architecture remain.
- Removed unused textures parented beneath textures and redundant empty/single-child model containers. Removed 12 redundant static joints; all 506 retained welds belong to protected door assemblies.
- Disabled collision on 1,616 small retained-detail candidates before the final tiny-detail removal; some of those candidates were subsequently deleted. Retained eligible MeshParts use Automatic render fidelity.
- No vehicle assembly was identified inside the specified House. Cars and content belonging to other houses were outside scope and untouched.

## Preserved and ambiguous geometry

The exterior silhouette, room boundaries, floors, roofs, stairs, necessary rails, doors, main couches, beds, kitchen counters, tables, chairs, shelving/cabinets, TVs, pool, patio, umbrellas, and party pavilion remain. Visual checks covered front and rear exteriors, kitchen, living room, bedroom, and the separate party pavilion.

Large generic glass-tile assemblies, architectural trim, cabinet/appliance components, unusual generic furniture meshes, and complex union geometry were retained where purpose or interior visibility was uncertain. No broad size-only rule was applied to delete major structures or furniture. Union/mesh triangle counts were not inferred from their bounding boxes.

## Doors and validation

All **1,462 protected door-related instances** were retained with no recorded cleanup operations on them. This includes 25 ProximityPrompts, 506 welds, hinge parts, open/closed reference parts, state values, and configurations. The top-level door groups are 16 Door models, five SlidingDoor models, and one each of FrontDoor, GlassDoor, SlideDoor, and PantryDoor. One group includes an additional nested door setup; there are 25 prompts total.

**Existing functionality gap:** the original House had no door controller script. Source inspection found no external controller referencing its OpenPosition/SlidingDoor/PantryDoor setup. In a Studio client test, pressing E at the front door produced one server-side prompt event, but the door did not open. The door assembly was unchanged by cleanup. Door-opening functionality cannot be claimed as working. No replacement controller or purchase behavior was introduced.

Checks performed:
- Before/after inventory and protected-door operation audit passed.
- Protected door BasePart transforms, sizes, anchoring, and collision properties were compared against the baseline with no changes.
- Native serialization/deserialization matched the final instance counts; the final export contains 10,588 descendants.
- Final seating check: 119 seats retained.
- Client character placement and real keyboard prompt interaction were tested in Studio. Studio was returned to Edit mode.
- `rojo build -o build/CopyTheScene.rbxlx` passed for the existing repository. That build does not package this separate House asset and is not proof of the House's gameplay performance.

No multi-client neighborhood stress test, NPC navigation load test, low-end-device benchmark, nighttime lighting audit, or published DataStore test was performed. A single client rendering query at the front-door viewpoint reported 421,973 triangles and 344 draw calls for the loaded scene, including other content; it is not an isolated House metric or a before/after speed comparison.

## Remaining hotspots

The preserved mansion still has **6,889 BaseParts**, **733 UnionOperations**, **331 MeshParts**, and **2,117 Texture instances**. Its extensive glazing, repeated architectural detail, multi-part upholstered furniture, and preserved door assemblies remain the main density concerns. Several simultaneous copies plus NPCs/effects still require an actual neighborhood load test. Further substantial reductions would likely require mesh/texture baking or replacement geometry, beyond this cleanup's preservation constraints.

## Provenance

Both model exports come directly from the user-specified existing Studio House. No Creator Store assets or new third-party geometry were added. Existing embedded asset references were retained only as needed for the preserved model.
