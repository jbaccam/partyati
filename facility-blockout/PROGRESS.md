# Facility progress

## All hallways — current completed environment pass

Hallways.server.luau finishes all 277 main-floor Hall/ServiceHall floor cells, all eight basement perimeter/connecting corridor rectangles, and both stairways. Includes continuous concrete/linoleum-like floors, muted plaster above painted green-gray wainscot, skirting/chair rails, acoustic drop ceilings, recovered doorway surrounds, location signs, 134 shadow-casting fluorescent fixtures, and sparse wall-mounted/parked furniture. Reusable original bench, radiator, noticeboard, service cabinet and linen-trolley kits form roughly 74 placement groups. Stair shafts have enclosed upper roofs/sides and landing transitions, tubular handrails and anti-slip tread nosings. Bathroom interiors and their complete male/female separation remain unchanged.

Hallways.PowerZones contains independent server-owned corridor/stair circuits with Powered and FlickerEnabled attributes. Selected fixtures dip briefly and infrequently; most remain steady. Live Studio now uses Realistic lighting, matching the source project. Current hall source is synchronized to FacilityHallways in Studio. Edit-time visual inspection was used during authoring, but no playtests, client navigation, automated gameplay checks, or performance tests were run for this pass, per user instruction. User will manually test. Other named room interiors are not part of the all-hallways request and remain separate work.

Prior intermediate hallway geometry remains recoverable in ServerStorage.Hallways_PreThresholdFinish. The remaining bathroom dead-space dressing/slide-gap proposal has not been implemented; do not claim it is complete.

## Full washroom environment pass (latest)

WashroomCompletion now finishes the whole basement washroom: six matching ceramic toilets and sinks total, four open shower bays with exposed plumbing, three slatted benches total, tiled service screens/lower walls, full drop ceiling, working and dead fluorescent fixtures, drains, dispensers, ventilation and exit markers. The library was not changed. Earlier partial ceiling and remaining basin placeholders are recoverable in ServerStorage.WashroomCompletion_Backup.

Verification: Rojo packaging passes. Studio play mode loaded the completion stage successfully. Three no-jump pathfinding routes (central entrance-to-entrance, western aisle and eastern aisle) returned Success with 27/19/19 waypoints. The actual client navigated from the north entrance to the south entrance, ending at (-159.29, -36.00, 227.60). Edit previews inspected the central aisle and shower side; a temporary nighttime preview inspected tile/lighting and bright edit settings were restored. This is not a multiplayer/performance test. Stall leaves remain static ajar scenery; interactive hinges and running water are not implemented. Other wings remain blockout; the adjoining hall is next.

## Latest correction/detail pass

Library now has two intended entrances: west Z=-184 and south X=168. The user-rejected west Z=-120 doorway, leaf and frame were removed to ServerStorage.Library_PreFinalCorrections and replaced with a continuous matching wall/skirting. South doorway now has matching dark trim.

All three leaning shelves have their downward-facing book clusters removed to the same backup. Reviewed horizontal book meshes form stacked piles underneath, with stack-sized collision proxies. Low longitudinal blockcasts at all three shelves hit blocking geometry; upward-facing books remain. This intentionally closes these under-shelf crawl routes per the user's latest request.

Next-area work advanced: first washroom bay now has tile splashback, dispensers, drain/grille, vent louvers, and a slatted bench outside the stall aisle. Visual checks performed; Rojo packaging passes. Full client movement/playtest remains outstanding.

## Current pass

- Library west structure rebuilt with actual 12-stud openings centered at Z=-184 and -120; lining and structure now agree. Only west library span replaced; adjoining wall spans retained. Door frames added. Existing door leaf at -120 retained. Original geometry stored in Library_PreEntranceAlignment.
- Coordinated library furniture: four muted padded chairs, simple CRT and keyboard, three matte articulated task lamps. Mouse and prior glossy models removed to recoverable storage.
- First basement washroom fixture bay: three toilets/stalls, three pedestal sinks/mirrors, local drop ceiling and task lighting. Washroom tile substrate spans the existing room; remaining fixture bays are not complete. Stall leaves are static ajar geometry, not an implemented interaction system.
- Geometry checks: avatar-sized west entry blockcast is clear at -184; -120 hits the intended existing door leaf. No wall behind the entry reported by the opening overlap check. Visual checks at library desk/chair height and both washroom views; mirror depth and grout lift corrected.
- Packaging: rojo build facility-blockout/default.project.json -o build/FacilityLayoutReview.rbxlx.

## Still required

Play-test door operation and traversal; validate nighttime washroom visibility and client performance. Expand washroom fixture bays and finish its walls, plumbing, benches, dispensers and alternate-route clearance. Then one adjoining hall with a consistent institutional kit. Other wings remain largely blockout. No upper floor. Movement/AI/sabotage implementation remains separate.
# September 9, 2026 — remaining-map pass (current)

This section supersedes the older incremental status entries below.

- Corrected hallway light placement to corridor cross-section centers. Thin light frames, rods and trim no longer cast the oversized diagonal/linear shadows; structural occluders and real lights retain shadows.
- Removed old vault-window blockout crossing the west stair entrance. Restored landings, flooring behind stairs, entrance enclosure/header and southern wall. Removed overlapping temporary stair lids after room ceilings were installed.
- Added completed environment dressing for medical, residential, administration, reception, security, storage, cafeteria/kitchen, courtyard, generator hall, pumps, electrical and records alcoves. Approved library/washroom layouts retained, with bathroom linen storage and maintenance hatch added.
- Six numbered diesel generator models, three partial service cages, separate low fence service openings, utility benches and clear central/perimeter lanes. Six room-power sectors, repair prompts and a server-only validated sabotage integration point.
- Five three-stage escape prototypes, searchable containers/supplies, server inventory, under-bed hide/leave interactions, physical front/staff gate apertures, reception telephone and underground exit destinations.
- Static reviewed hospital-bed/stove assets exported to source; other room furniture and utility/escape models are original geometry or existing reviewed coordinated templates.
- Source scripts and edit-time world synchronized. Rojo packaging succeeded. No gameplay, pathfinding, client walkthrough or multiplayer tests were run in this pass, per user request. An initial asset edit preview was inspected; later broad-room screenshot requests did not return and were abandoned.
- Monster pursuit/round control, police responder visuals, full sprint-slide/vault/stamina and camera bobbing are **not implemented by this map pass**. The phone exposes alarm/holdout state for future AI. Hatch transitions are bounded server transfers, not seamless animated crawling. See ESCAPE-ROUTES.md for exact behavior and manual review needs.
