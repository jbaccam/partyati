# Facility production pass — 2026-09-09

## Scope and current status

The survival-horror map is isolated in `facility-blockout/` and `Workspace.FacilityLayoutReview`. The unrelated CopyTheScene project was not modified by this map pass. This is a map/art pass, **not a completed game or a claim that every area is approved**. Subsequent user feedback prioritized basement stair repairs, reducing bedside searches, and kitchen furnishing over gameplay implementation.

## Original assets authored and imported

All six assets were authored in Blender through the connected MCP, exported as reusable FBX meshes and imported into Studio. Repeated placements share asset IDs. One original 512×512 color/grain atlas is shared; there are no photorealistic scanned materials.

| Asset | Triangles | Roblox mesh |
|---|---:|---|
| DiningBenchSet | 1,404 | 80642487527387 |
| ChainLink | 448 | 105048691594122 |
| VentGrille | 1,472 | 116662143016157 |
| LeafyShrub | 2,484 | 102026128059449 |
| CourtyardTree | 9,576 | 86599017374966 |
| MedicalGurney | 1,468 | 73842215016302 |

Shared texture: `90048524793309`. The four-asset representative batch was imported and inspected before the tree/gurney expansion. Studio interpreted the FBX units at 28× scale; template sizes were normalized by 1/28, with bottom-center pivots. The authored convention is one Blender geometry unit per Roblox stud. Foliage is double-sided, and detailed meshes use simple native collision proxies where appropriate.

Sources: `blender/build_kit.py`, `blender/expand_kit.py`, `blender/Facility_ModularKit.blend`; export files are in `exports/`. Static Studio templates are serialized in `../assets/FacilityProductionTemplates.rbxmx`. Existing reviewed bed/chair/library models remain attributed in `../ASSETS.md`.

## Map changes

- Six long attached-bench dining sets; enclosed kitchen with serving windows and a swing door, stainless workstations, cooking/washing/prep/cold-storage areas, dish carts and partly stocked dry racks.
- Sixteen residential beds and twelve medical beds; bedside furniture, central linen cover islands. All repetitive bedside search prompts removed; only selected bed hiding points remain. Two visible supply cases are placed on medical work trays.
- Four storage rows with partially empty bays, not completely filled racks.
- Grass Terrain courtyard, concrete approaches aligned to the three actual doorways (west Z=-40, east Z=-8, south X=-24), a connected well plaza, six bench alcoves, two branching leafy trees, twelve shrub instances and eight path lights. The superseded centered cross was removed recoverably. Paving is a non-overlapping rectangle union; Terrain Ground masking follows its footprint.
- `Readability.server.luau` removes 125 remaining empty/duplicate search prompts. Nine fixed supplies remain, each with a visible native 3D item, an explicit label and a short Take interaction. Empty shelf spaces remain silent authoring markers. Reception has an in-world supply directory; storage has tool-location signage. Existing server inventory, distance/hold validation and route gates are preserved.
- More reception seating/tables; hallway medical gurneys, trays, scattered paperwork and original stylized archive pictures.
- Individually addressable thick 3D chain links and a padlock; louvered staff vent with screws and a steel throat.
- Two stair shafts relocated into service strips at X=-144 and X=96. Main-floor entry at Z=16; basement exit at Z=124. Removed old room stair boxes, restored floor cuts, wrapped structural wall materials, removed decorative layers blocking lower portals and old noticeboard/trim across the east upper doorway. Continuous sloping stair ceiling, closed transition header, lower landing ceiling and relocated lights.
- Shadow-casting fixture-local fill light improves powered-room visibility. Circuit ownership remains on the existing prototype.

## Actual validation evidence

- Courtyard correction: five downward paving samples across each of the three doorway widths passed (15/15). Live Edit state contains nine supply prompts, all nine marked visible, and zero empty search prompts. Packaging passed. This correction was not followed by a new character playtest or multiplayer pickup test.
- Restored the Edit camera from Scriptable to Fixed after the previous inspection left it locked. All 18,304 pre-correction map parts were inspected as unlocked; Anchored does not prevent Studio editing. No desktop controls were used for this correction.
- Rojo packaging succeeded after the production scripts and shared mesh templates were added.
- Initial graybox character navigation passed both descending stair routes, ward aisle, storage aisle and cafeteria aisle. This did **not** prove the subsequently furnished stair geometry was correct.
- Furnished-map normal-character tests (avatar approximately 5.49 studs tall) passed cafeteria main aisle, kitchen work lane, ward longitudinal aisle, storage aisle and courtyard path.
- Kitchen door opening was observed in authoritative server state and the character passed through it.
- A later upward stair test exposed an old hallway floor tile above the flight. User screenshots exposed decorative wall skins covering basement exits, a floating soffit edge and the east entry's old noticeboard. These were corrected in `MapFinish.server.luau` and in Edit geometry.
- Final geometry rays confirmed both upper and lower openings clear at multiple character-body heights. Eleven headroom samples per stair measured approximately 9.07–15.70 studs along the covered route. Direct Studio captures were inspected at upper and lower portals.
- Early post-fix `MoveToFinished` attempts were interrupted by changing Play sessions and were not counted. A subsequent isolated, temporary R15 test character (5.457 studs tall, WalkSpeed 16, server-owned physics) completed **both stair routes in both directions**, including the upper hallway entrances and the lower basement exits. No teleport was used along a tested route; repositioning occurred only between the west and east test starts. The temporary character was removed after testing.
- Earlier Studio client total memory snapshot: approximately 2,497 MB. This includes Studio overhead; it is not a published-client performance benchmark. No final FPS/mobile/multiplayer benchmark has passed.

## Remaining limitations

- User approval and a final uninterrupted walkthrough are still needed; do not label the whole map fully polished based only on this report.
- Full sprint-slide/crawl movement, monster AI, police arrival/chase behavior, production inventory balance and multiplayer escape validation remain separate gameplay work. Existing search/escape/power code is a session prototype without persistent rewards or DataStores.
- Hiding enter/leave was attempted but not verified successfully in this pass; do not claim it passed.
- Some direct offscreen Studio captures rendered local lights inconsistently; dark captures are not proof that lighting passed. Powered/outage contrast needs a final live-player review.
- Blender assets were imported into the current account. A different published universe owner must verify asset permissions.
- Superseded map geometry was moved into scoped ServerStorage backup folders for recovery. It was not permanently deleted.
- Rojo project/source files and live Script sources are maintained together, but this pass does not claim an active Studio Rojo plugin connection without observing one.
