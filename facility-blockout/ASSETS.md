# Facility assets

## Unified library kit and first washroom bay

Current reviewed static templates:
- Office chair: 15127777861, seG1as. Two mesh components; seat, scripts, animation and collision wrapper removed. Muted finish applied.
- CRT: 91649828171312, ZeroSaberStealth. Three meshes plus indicator; no imported scripts. Muted cabinet finish applied.
- Keyboard: 9031074046, PsychSka. Static keys retained; one union return key replaced with an ordinary keycap.
- Toilet mesh: 5154007432, iNoa_h.
- Bathroom sink: 490512671, brightdani. Pedestal mesh retained; black texture removed for a consistent ceramic finish.

Library task lamps are locally authored articulated geometry with hollow CSG shades, not the rejected brass lamp assets. Old furnishings are recoverable in Library_PreUnifiedFurniture. CoherentKitTemplates.rbxmx and WashroomTemplates.rbxmx contain only static geometry; no runtime InsertService imports. Store listing is provenance, not a guarantee of third-party rights.

Rejected inspection candidates (not shipped): 111780070229314, 1744217931, 341944851 lamps; 1501261998 and 5072566859 sinks; 14375791882 stall. Imported executable/interactive content was stripped in ServerStorage before preview.

## Library refinement — supersedes the first quality pass

- Institutional padded metal-frame chair: Creator Store 13857744922, AquaRise realistic office/school chair, BlueFace1239D. Two MeshParts; weld removed; no scripts found. Static source: assets/InstitutionChair.rbxmx.
- Fine gray carpet: Creator Store 1587302690, Yuvha; resolved image 1587302687.
- Subtle plaster grain: Creator Store 762795531, yumahap; resolved image 762795527.
- These were listed free; the same authorship/rights caveat below applies.
- Previous farmhouse chairs, damaged wallpaper textures and segmented carpet floors are backed up in ServerStorage.Library_PreSurfaceRefinement. They are not the current library appearance.

LibraryFinish uses the reviewed BookshelfBay book meshes for floor/desk books, upright wall stacks and damaged cabinet. LibraryQuality replaces the original block CRT, lamps and chairs. Desk/counter cabinetry remains procedural.

## Library quality pass — 2026-09-09

Static templates are checked into assets/LibraryPropTemplates.rbxmx. Imported scripts, modules, interactions, sound, cameras and other non-static objects were removed in ServerStorage before preview/use. No imported code is included or executed by the generated build.

| Used asset | Creator Store ID | Listed creator |
|---|---|---|
| Banker's Lamp | 6743657757 | aIwaysproper |
| Old Chair Gaming Office Fabric Chair Aesthetic RP (actual geometry: weathered spindle chair) | 115288887743380 | XzLionBKClawYzX57 |
| Vintage Retro Computer Old PC Mesh Model | 70955330116768 | WarphNStormChas3rv18 |
| Dirty-Grey-Color-Carpet-Texture | 7851491041 (image 7851491033) | cttiiv |
| Worn Ripped Wallpaper | 71806713335546 (image 71812035749325) | ToTheTreeTops |

Links use https://create.roblox.com/store/asset/ followed by the asset ID. Assets were listed free at selection. Creator Store availability does not verify authorship or make these copyright-free; provenance/rights still require review before publication. Branded computer tower omitted; only monitor, keyboard and mouse used. Originals and rejected samples remain in ServerStorage, outside the playable scene. New lamps use locally authored lighting, not asset scripts. Old block props are recoverable in ServerStorage.LibraryBlockProps_PreQuality.

Rejected preview candidates: CRT 74799278485366, wallpaper 344409941 and 89701446610074. Not shipped in source templates.

## Reviewed Creator Store bookshelf sample

Update: the user approved library-wide reuse. Six arrangement variants now populate all 26 main cases, using the same reviewed book/frame assets. No new external assets were introduced. Prior one-sample-only notes below are historical. Variations do not resolve the underlying-source permission caveat.

Chosen sample: Bookshelf (With Books), creator bradyocon, Roblox model ID 9914694425. Source: https://create.roblox.com/store/asset/9914694425 . Retrieved as a free Creator Store model via Studio search/insert. No user-inventory bookshelf was found. Compared against Bookshelf by InabaTwi (9333354309); that candidate was rejected as too stylized. Search also returned other candidates that were not used.

Both inspected models contained no LuaSourceContainer instances. Only reviewed Parts, MeshParts, SpecialMeshes, Decals and Models are included in the reusable asset. Welds and other instance types were stripped; all geometry anchored. Raw candidates and comparison previews are kept in ServerStorage for review, outside Workspace. No third-party scripts are run or shipped.

Local asset assets/BookshelfBay.rbxmx preserves the selected static bay's mesh/texture references. BookshelfMaster.server.luau assembles eight bays into one double-sided 24-stud master (241 geometry Parts including one collision proxy). BookshelfSample.server.luau replaces only the northwestern upright shelf for visual approval. Cabinet wood and book textures are tinted darker. Remaining library shelves and tilted arrangements remain original procedural versions. This is a review sample, not approval to mass-replace or an optimized final asset.

The selected model includes mesh IDs 474373754, 474372876 and 1808618091 and texture references 474373233, 1808597508 plus book decals from the model. Store listing is provenance, NOT verification of original ownership, public-domain status or all underlying image rights. Review source permissions before publication; do not describe this asset as copyright-free.

LibraryArt.server.luau creates original procedural shelf frames, book-volume groups, spine bands, plaster linings, damp streaks, fixtures and a ceiling. Uses Roblox built-in Wood, Fabric, Concrete, Metal, Glass and Neon materials; no imported images, Creator Store models, franchise assets, or third-party scripts. User screenshots were visual references only. No screen-space film grain or custom PBR maps yet.

This is a style-review prototype (~4,000 descendants in LibraryArt), not an optimized final mesh library. Books and spine bands are noncolliding and do not cast shadows. Mesh consolidation and mobile profiling are required before repeating this level of detail across the map.
## Hallway kit — current

Hallways.server.luau uses original locally authored static geometry for institutional slatted benches, tubular frames, radiators, linen carts, service cabinets, noticeboards, ceiling fixtures, stair enclosure/rails and architectural finishes. Reuses the already reviewed plaster grain image 762795527 (listing 762795531, yumahap) at low opacity. No additional Creator Store assets or imported scripts were introduced. Notice text is original. No franchise meshes/textures were copied from reference games. Source and Studio geometry are synchronized.

## Remaining-room kit — September 9, 2026

- Hospital Bed, DrannaddReven, model 13571090371: https://create.roblox.com/store/asset/13571090371 . Two static MeshParts, meshes 3032700474 and 3032696379, texture 3032697899. Added original blanket/pillow and separate hide markers. Stored in assets/FacilityRoomTemplates.rbxmx.
- Stove, Kutekatkupkakke, model 10154852647: https://create.roblox.com/store/asset/10154852647 . Twenty-three static Parts; neon heating strips changed to inert metal. Stored in the same template file.
- Both listings were free at retrieval. Only flattened anchored BaseParts were exported; no third-party scripts, constraints, interactions or package links are shipped. Initial edit preview was inspected; published-client mesh delivery and rights clearance remain outstanding. A free listing is not proof of underlying authorship or redistribution rights.
- Generator 11213000926 (picat27) and Telephone 8342265329 (Guest13O20) were quarantined and stripped of scripts but **not used or exported**. Their raw static review candidates remain in ServerStorage.FacilityAssetReview.
- RoomKit.luau / Rooms.server.luau create original cabinets, shelving, carts, tables, generator enclosures/panels/exhausts, pump vessels, fencing, telephone, vent duct, well, exit chains, doors and finishes. They reuse the already reviewed coordinated chair/CRT/keyboard templates. No Outlast, DOORS or Scream And Run franchise assets were imported.

## Original Blender production kit — September 9, 2026

Six original static meshes were authored through Blender MCP, exported as FBX, imported into the current Roblox account, and serialized in `assets/FacilityProductionTemplates.rbxmx`: DiningBenchSet (80642487527387), ChainLink (105048691594122), VentGrille (116662143016157), LeafyShrub (102026128059449), CourtyardTree (86599017374966), MedicalGurney (73842215016302). Shared original palette/grain texture: 90048524793309. No downloaded geometry or franchise art is contained in this kit. Repeated objects share mesh IDs; collision is supplied separately with native Parts. Blender sources, unit conversion, triangle counts and actual validation are documented in `production/DELIVERY.md`. Concept boards influenced the restrained green/cream palette and readable silhouettes, not photorealistic rendering. Asset ownership permissions must be checked for any other publishing account/universe.
