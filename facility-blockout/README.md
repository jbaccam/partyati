# Facility movement blockout — version 5

## Corner shelving, trim and readability (latest)

LibraryCorner.server.luau extends the upright-only wall shelves into an L around the reading corner, rebuilds plaster with butt-jointed corners and inward-facing skirting on all four walls (door openings retained), and adds corner trim, 12 noncolliding scattered papers with faded print, 16 restrained local fill lights and two reading lamps. LibraryFinish now marks Ready for deterministic dependency order. Lining backups and preview duplicates are archived in ServerStorage. No player-control changes or new external assets.

Inspected nighttime aisle/corner previews, then added task lamps for the darker reading area. Non-jumping pathfinding passed the library-to-reading route and south entrance. Rojo build passed. Bright edit state restored. Mobile readability and performance still need device testing; this pass does not claim uniform darkness elimination on every display.

## Checkout and reading-area dressing (latest)

LibraryFinish.server.luau replaces the broken case with damaged versions of the reviewed cabinet/book asset family, with backing/crown and selected upper shelf pieces missing. The aisle remains blocked. Checkout greybox becomes cabinets, counter, CRT, keyboard, paper and warm task lamp; its center retains a 10-wide/3-high slide opening. Existing secondary underpass receives matching wood and books without reducing clearance. Added two study desks, four chairs total, a few noncolliding floor books, and a single south-wall bookcase filled with upright-only book clusters. No controls, slide implementation, objective scripts or new rooms added. Previous geometry preserved in timestamped ServerStorage.Library_PreFinish.

Rojo build passed; inspected checkout and wall-bookcase screenshots. Runtime collision sweeps test low and standing checkout clearance, existing underpass and dead-end obstruction; non-jumping pathfinding checks passage through the library into reading area. Bright editor mode restored after Play. No claim of finished game logic or mobile performance. Existing Creator Store provenance/permission caveat remains.

## Whole-library book variations (latest)

User authorized detailed shelf reuse throughout the library. BookshelfSample.server.luau now builds six deterministic variants from the reviewed static BookshelfBay asset and replaces all 26 main cases. Each cabinet face independently shuffles occupied compartments, chooses upright/horizontal book clusters, leaves gaps and applies restrained tint differences. Clusters stay intact; world-aligned bounds fit them between shelves without relying on differing mesh axes. All three leaning transformations and the separate broken-shelf dead end are retained. Original shelves and first sizing draft are recoverable in timestamped ServerStorage backups. Asset rights caveat in ASSETS.md remains unresolved before publication.

Verified corrected closeup screenshot and real Play count: 26 detailed shelves, three leaning, all six variants in use, broken dead-end case present. Non-jumping radius-2/height-5 library north-to-south path succeeded. Rojo build passed; bright editing state restored. This was not a mobile performance, multiplayer, or actual-character chase test; optimize/profile before further repeated detail expansion.

## Reusable bookshelf quality sample (latest)

Searched Creator Store and automatic user-inventory/Store scope for bookshelves, inspected two static candidates, and chose bradyocon's Bookshelf (With Books) 9914694425 for one sample. See ASSETS.md for provenance and unverified underlying-rights caveat. Eight repeated bays make one darkened, double-sided master with detailed textured book clusters, page edges and horizontal stacks. Master is assembled from the local static BookshelfBay.rbxmx asset without runtime marketplace loads. One upright shelf at (108,7,-212) is replaced; the other shelves and all leaning/blocked arrangements remain unchanged pending approval.

Validation: no embedded scripts in reviewed candidates or assembled master; anchored static geometry; 241 geometry Parts in master including one collision proxy; dimensions approximately 3.2 x 11.71 x 24 studs. Rebuilt master with assembly script and matching dimensions/count. Rojo packaging passed. Inspected front/oblique sample screenshots. No performance, mobile, or published asset-permission verification yet. Prior upright sample retained in ServerStorage. Bright Edit mode remains active.

## Third, reverse-leaning shelf (latest)

Converted the north row's upright case originally at (172,7,-212) to a 45-degree left lean against the neighboring case at x=156, opposite the two existing right leans. Three leaning cases total, one per full row. Previous upright case preserved in ServerStorage.Bookshelf_PreReverseLean timestamped backup. Source and Studio synchronized; Rojo build passed; inspected closeup and verified count three. No movement or lighting changes; no chase test this revision.

## Broken bookshelf obstruction (latest)

Replaced JammedBackingPanel and both BrokenPanelBrace parts with BrokenAisleBookshelf: open-backed cabinet sides, shelf boards, split/sagging upper shelves, snapped divider, wedged plank and dislodged books. No broad wall panel remains. The same aisle remains a dead end. Prior panel parts are preserved under timestamped ServerStorage.RemovedAislePanel. Source matches Studio; Rojo build passed; inspected frontal screenshot and confirmed a standing-size collision sweep hits the broken case. No movement or lighting changes.

## Leaning-shelf route revision (latest)

Both fallen shelf models now lean 45 degrees with their heel on the floor and their upper corner braced against the adjacent upright case. Added a dislodged wooden backing panel to cap one aisle, creating a north-entry dead end rather than uninterrupted zigzag circulation. Source and live Studio match. LibraryArt backup is in timestamped ServerStorage.LibraryArt_PreLean.

Verified eye-level geometry screenshot, Rojo build, a standing-agent collision sweep hitting JammedBackingPanel, and a non-jumping pathfinding detour out of the capped aisle (18 waypoints, Success). This is not a chase or actual-avatar vault test. Bright edit mode restored after Play/Stop. Player movement unchanged.

## Editor visibility correction (latest)

Separated gameplay lighting into Lighting.server.luau so it applies in Play even when LibraryArt already exists. Current Place1 edit state is bright daylight, ambient 100/100/100, disabled FacilityArtGrade and 85% transparent library ceiling for overhead editing. Play restores the opaque ceiling and night mood, with raised ambient (27/29/31), exposure +0.15, reduced contrast 0.07, and working lights increased from brightness 2.8/range 32 to 3.3/range 40. Stop naturally restores the edit state. No movement or geometry changes.

Validated a real Play/Stop cycle: runtime clock 0, exposure .15 and opaque ceiling; after Stop clock 14.5, bright ambient, translucent ceiling and disabled grade restored. Rojo build passed. These are settings/state tests, not mobile readability validation.

## Library art sample (latest)

Movement work explicitly paused. LibraryArt.server.luau waits for architectural cleanup, then replaces 26 shelf blocks with 24 upright, 4-stud-deep wooden shelves and two genuinely knocked-over shelf models, crossing selected aisle routes. Carpet uses dark green Fabric; shelf frames use Wood; plaster uses Concrete with sparse damp marks. Black ceiling and four operating/three dead fixtures create localized illumination. This is the first room style sample; no other interiors or upper area added. Built-in material grain only, not custom texture maps or a film-grain overlay.

Pre-art geometry preserved in timestamped ServerStorage.FacilityLayoutReview_PreArt. Global lighting original values stored as FacilityBefore_* attributes on Lighting. Night/exposure changes affect the rest of the place too, although new local fixtures and material work are confined to the library. Live Studio still uses Soft LightingStyle because the property is script-protected; the Rojo package specifies Realistic. For sharper local shadows in the current Place1, manually set Lighting > LightingStyle to Realistic in Properties. Reference: https://create.roblox.com/docs/environment/lighting .

Validation: inspected an eye-level library preview; counted 26 shelf models including exactly two Fallen=true. Rojo build passed. Non-jumping radius-2/height-5 pathfinding and actual client navigation passed from north aisle to the southern library area after a repositioned test start. Returned to Edit with eye-level camera. No mobile performance or multiplayer tests, and no claim of completed texture production/optimization. See ASSETS.md. No save/publish action performed.

## Dense library revision (latest)

User requested claustrophobic stacks. Replaced seven standing shelf blocks with 26 taller blocks: eight columns across three full rows, plus a two-shelf fourth row. Long aisles are 8 studs clear and cross aisles 10 studs. Removed the old separate hiding screen/return, now redundant with dense stacks, and moved the hurdle to the south edge. Slide and fallen-shelf bays remain reserved. No detailed shelf art or lighting pass. Studio backup: timestamped FacilityLayoutReview_PreDenseStacks in ServerStorage.

Verification: Rojo build passed; inspected overview; zero positive-volume overlaps among library props. Actual client navigation passed down an 8-stud aisle, across a 10-stud cross aisle, and down a second aisle, from a repositioned library start. Returned to Edit. Multiple-player passing, sprint chase balance, and monster clearance remain untested.

## Library prop fix and movement baseline (current)

The remaining flicker came from library prop intersections, not architecture: two south standing shelves occupied the slide/fallen-shelf bays, and the hiding screen intersected a west standing shelf. Removed the two conflicting standing shelves and shortened/repositioned the hiding screen/return. All library prop positive-volume overlap pairs now test zero. Geometry changes are mirrored in Layout.server.luau; previous Studio model is retained in timestamped FacilityLayoutReview_PreLibraryFix backup.

Next incremental stage begun: a library movement-test layout with weaving aisles, isolated slide/underpass bays, and one 3-stud hurdle. Movement.server.luau and Movement.client.luau add a review-only sprint baseline: hold LeftShift or controller L3; touch button toggles. Server accepts only a boolean and chooses fixed speeds 16/24 for a living character. This is not a production anti-cheat or stamina system. No slide/vault controller or animation, enemy AI, rewards, or art expansion yet.

Verification: Rojo build passed; inspected library overview. Real keyboard Shift input changed server Humanoid.WalkSpeed to 24, character navigation across the library succeeded, and release restored 16. Collision sweeps passed a 3-wide/2.5-high test box through the slide gap and fallen shelf; a 5-high test box hit the slide beam. These are geometric clearance checks, not successful avatar sliding tests. Touch/controller, respawn/focus behavior, multiplayer, and chase balance are not tested. Returned Studio to Edit, with no publication.

## V5 geometry cleanup (current)

Read the full user-supplied game description. Main floor and basement only: explicitly exclude the proposed partial upper level. Treat other gameplay ideas as context, not authorization to implement all systems now.

Fixed corridor fill overwriting room cells, which had created recessed/protruding courtyard thresholds. Removed duplicate upstairs prototype framing (door leaves/prompts retained). Enclosed empty grid pockets are solid structural infill, not misleading inaccessible floorless rooms; exterior gaps remain exterior and stair openings remain functional. Cleanup.server.luau builds an exact compressed-coordinate union of architectural volumes into non-overlapping ordinary Parts, squaring wall junctions and removing coincident faces. Temporary review billboards are disabled to avoid occluding geometry. No texture/art pass or new upper area was added.

Prior Studio geometry is recoverable from timestamped ServerStorage.FacilityLayoutReview_PreCleanup models. Source scripts and separate Rojo package are synchronized. V5 verification: build passed; 276 generated architecture Parts with zero positive-volume overlaps in a pairwise check; inspected courtyard overview and prop-surface closeup. Non-jumping radius-2/height-5 paths passed Storage, Courtyard, both stair routes, basement cross-route, Pump, and Washroom. Actual client navigation from spawn into Courtyard passed. Returned to Edit. Door inputs, multiplayer and enemy chase balance were not re-tested; no save/publish action performed.

## V4 room boundaries and corridor revision

All contiguous ground-floor room/hall interfaces now have wall runs and a centered 12-stud framed opening; exterior walls remain intact. Doorways do not all have operable door leaves yet: the three existing working prototypes remain. Storage is enclosed instead of merging into the hall. Basement north/south halls are approximately 20 studs wide, outer sides 16 studs and intermediate passages 20 studs. Enclosed north service voids retain separate 16-stud stair connectors. Basement floor is now 512 by 164 studs. Generator, pump, and washroom rooms retain two framed entrances. The V3 Studio model is archived under a timestamped FacilityLayoutReview_V3 name in ServerStorage.

Room intent, not implemented objectives: generator hall = power/sabotage; switchgear = restricted power control; pump room = utility repair objective candidate; records = optional risky search; washrooms = sightline-breaking escape route. Review labels distinguish proposed objectives. Keys, loot, repair tasks, and enemy sensing are not implemented.

V4 verification: Rojo build passed. Inspected Storage and basement screenshots, restored upper-floor visibility. Non-jumping radius-2/height-5 paths passed both stair connections, north cross-route, south loop, pump/washroom north-to-south routes, and Entry to Storage. An initial Storage target was inside the crate bank (NoPath); a clear target passed. Actual client walking passed east stairs through the new bottom threshold and Entry to Storage. No new multiplayer, door-interaction, or chase-balance test this revision. Returned Studio to Edit; not published. Previous sections below describe historical revisions.

## Basement revision

V3 adds Basement.server.luau and Doors.server.luau to the existing V2 generator. Place1 contains matching scripts and edit-time geometry. V2 is recoverable from ServerStorage.FacilityLayoutReview_V2; unrelated game content is untouched. The template Baseplate remains in Workspace with collision disabled and transparency 1 so stairways can cross its volume; previous values are stored on its FacilityPrevious attributes.

Generators are now 40 studs below the ground floor. The old generator area is a service hall. Two 15-stud stair runs connect opposite sides to a 512-by-192-stud basement with a generator hall, pump room, repeated washroom screens, and optional locked electrical/records alcoves. North/south circulation and room entrances form alternate routes. Rooms remain open-topped for layout review, with crude obstacle silhouettes only; ceiling, dressing, and atmosphere are deferred. Stair shafts and door treatment are prototypes, not a finished architectural pass.

Three upstairs framed door prototypes use E to open/close, with server distance/alive checks, debounce, and a player-overlap check before closing. Electrical and records doors stay locked: no key acquisition/unlocking progression is implemented. Other thresholds remain open intentionally; this is not an all-door conversion. Sliding/vaulting and enemies remain deferred.

Validation 2026-09-09: Rojo packaging passed. Inspected an overhead basement screenshot with upper-floor local visibility temporarily hidden and then restored. Non-jumping radius-2/height-5 pathfinding passed east descent, west ascent, the basement north cross-route, and generator north-to-south traversal. Actual client walking passed east descent and west ascent (each test started by repositioning the character). Actual E input opened and closed Security Door, verified on the server with matching collision changes. E input at Electrical Switchgear left it locked/closed/collidable. Multiplayer, anti-trapping behavior, every room route, chase balance, sprint/slide/vault, and performance are not yet tested. Returned Studio to Edit. Not published or saved to a user place file.

Outlast reference images inform connectivity and institutional room variety only; no external assets, franchise geometry, or themes were copied. Next checkpoint is user review of basement size, circulation, and room choices before detailed art or key progression.

## Current review

Version 2 supersedes the compact courtyard layout described in the historical notes below. Installed in Place1 as Workspace.FacilityLayoutReview with matching ServerScriptService.FacilityLayout source. V1 is preserved in ServerStorage.FacilityLayoutReview_V1 and LayoutV1.luau.disabled. No other game content was removed.

The new footprint is approximately 513 x 497 studs including boundary walls, with 32-stud main corridors, several connected loops, and nine distinct zones. Simple library shelves, admin desk blocks, medical screens, residential partitions, generator obstacles, and cover pockets establish movement decisions. Two 10-wide/3-high slide openings, a low shelf underpass, and a window sill are traversal prototypes. Their amber parts and review labels are temporary design markers. No sprint, slide, vault controller or monster AI is implemented. Clearance, speed, stamina, enemy turning behavior, and shortcut advantages need tuning together before art production.

Validation on 2026-09-09: Rojo packaging passed; an overhead Studio screenshot was inspected. Server PathfindingService found non-jumping routes from Entry to all eight other zones for radius 2/height 5 agents. The first courtyard test destination was inside a planter and correctly returned NoPath; a clear courtyard destination passed. Actual client character-navigation calls passed from Entry through the southern connection, Storage, west passage, and into Courtyard at normal walking speed. This does not establish sprint/slide/vault functionality or multiple-enemy chase balance. Studio was returned to Edit mode for user review.

Reference images informed route variety and alternate connections; neither reference map was copied. The pasted Scream And Run article was treated as inspiration, not verified evidence for its claimed speeds, success rates, AI behavior, or map statistics.

Next review is the movement layout. No detailed textures, finished furniture, sound, or darkness pass yet. Test a representative movement controller and chase route before polishing art.

## Historical version 1 notes

Separate draft for the horror facility. The root Copy The Scene Rojo project is unchanged.

The layout is installed in the confirmed Place1 Studio window, under Workspace.FacilityLayoutReview, and is visible in Edit mode. ServerScriptService.FacilityLayout contains the matching source and skips generation when the layout already exists. The blank template spawn is retained but disabled so Play starts in the entry room. The blockout is raised one stud above the template baseplate to avoid overlapping floor surfaces.

Alternatively, open `build/FacilityLayoutReview.rbxlx` as a separate Studio place and press Play to generate the layout. In that generated package, Stop returns to the empty edit scene; the source script remains available for revisions.

This draft proposes an approximately 184-by-184-stud ground floor: eight empty room shells surrounding a 64-by-64 courtyard and a 12-stud-wide corridor loop. Room walls are 12 studs tall, with 8-by-10-stud door openings. Roofs are intentionally deferred so the layout is visible from above. No external assets, textures, furniture, creatures, detailed lighting, or gameplay systems are included.

North: admin and medical. West: residential rooms. East: library and storage. South: entry and security. The courtyard has three entrances. This is a proposed layout, not an approved final floor plan. Basement, generator room, and vertical connections are deferred until ground-floor circulation is reviewed.

Review: walk from entry around both sides of the loop; enter each room; cross the courtyard; assess room sizes and whether the loop feels too simple, wide, or short. Chase dynamics and monster clearance remain untested because enemy dimensions and movement are not yet established.

Next steps, only after feedback:
1. Revise the coarse layout and connections.
2. Finish one short corridor and one adjoining room to establish the visual style.
3. Expand the approved assets and lighting room by room.
4. Add props, sound, and power-state effects in later passes.

Research: Roblox's environmental-art curriculum recommends greyboxing playable areas, repeatedly playtesting, and then producing polished assets: https://create.roblox.com/docs/tutorials/curriculums/environmental-art/greybox-your-environment

Build: `rojo build facility-blockout/default.project.json -o build/FacilityLayoutReview.rbxlx`

Validation on 2026-09-09: installed in Place1, inspected an overhead Studio screenshot, and started a real Studio Play session. The client spawned at the entry with normal Humanoid WalkSpeed 16. Character-navigation calls succeeded from the entry through the south, west, north, and east halls, into and out of Medical, and through the east and south courtyard doorways. These are sampled traversal checks, not an exhaustive room-by-room test or a test of combat, chase gameplay, mobile readability, multiplayer, or performance. Art approval and user layout review are pending. No assets were uploaded and the place was not published.
