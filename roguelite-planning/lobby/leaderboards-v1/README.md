# Lobby leaderboards V1 — Top Kills, Highest Wave, Time Played

2026-09-29. Three matching boards on the empty north edge of the main island, just behind the lobby spawn,
facing spawn. Built from the same painted-atlas craft as the Collection and Quests stations: oak posts on
dressed stone footings, iron collars and pegs, a front-gabled slate-blue roof (like Collection), a lantern
on each post, a title plaque and a large framed blue panel that carries the live top-10 list.

| Board (left to right from spawn) | Title | Gable emblem |
| --- | --- | --- |
| `Leaderboard_Wave` | HIGHEST WAVE | Heater shield with three stacked chevrons |
| `Leaderboard_Kills` | TOP KILLS | Crossed swords |
| `Leaderboard_Time` | TIME PLAYED | Hourglass |

## Files

- `build_leaderboards.py`: self-contained generator (Blender 5.2). The painted-atlas helpers are a copy
  of `cohesion-v6/collection/art_helpers.py`, not an `exec` of it. Authored at final stud size; fronts -Y,
  ground Z=0, origin = board pivot.
  `"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python build_leaderboards.py -- --render`
- `package_kit.py`: packs the six meshes into `exports/fbx/Lobby_Leaderboards_V1.fbx` for one 3D Importer pass.
- `metadata.json`: per-mesh centre/size/triangles plus the display, sign, emblem and lantern contract.
- `work/*.mesh.json`: triangle soup of each mesh (for EditableMesh look-dev; not needed for install).
- `InstallLeaderboards.luau`: Studio Edit-mode installer (re-runnable).
- `local_server.py`: loopback server on 127.0.0.1:8803 so Studio can fetch the installer and scripts.
- `renders/`: real Blender renders (`Leaderboards_Overview.png`, `_Center.png`, `_Emblem_*.png`).

Meshes (one texture each, no zero-area triangles): `LB_Frame_Timber` 2,088 tris, `LB_Frame_Details` 2,424,
`LB_Frame_Roof` 770 (shared by all three boards), `LB_Emblem_Kills` 832, `LB_Emblem_Wave` 784,
`LB_Emblem_Time` 848.

## Textures

The generator's Timber/Details/Roof atlases are byte-identical to the Collection and Quests V6 atlases
(SHA256 `c991ac6e…` Timber, `7bfa99d1…` Details, `71f24a8a…` Roof), so the installer reuses the uploaded
QuestsV6 texture IDs on `MeshPart.TextureID` and nothing new is uploaded. No SurfaceAppearance is used
(those render blank in Play for MCP-uploaded images).

## Install (Studio, Edit mode)

1. Studio 3D Importer: `exports/fbx/Lobby_Leaderboards_V1.fbx`, Upload to Roblox on, scale 1.
2. `python local_server.py`, then run `InstallLeaderboards.luau`. It finds the imported meshes, works out
   the importer's quarter-turn from the part layout, builds `Workspace.RogueliteLobby.Leaderboards`
   (tag `RogueliteLeaderboard`, attribute `LeaderboardStat`), keeps the kit as
   `ServerStorage.LobbyLeaderboardsKitV1`, and moves the flowers/grass under the plinths to
   `ServerStorage.Lobby_BeforeLeaderboards_<timestamp>`.
3. `studio-prototype/combat/LeaderboardService.server.luau` goes in ServerScriptService as the Script
   `LeaderboardService` (unsandboxed, like RogueliteMeta: it needs DataStores; requiring the sandboxed
   ShopService/ZombieDeath/AdminConfig from an unsandboxed script is allowed).

Each board model: `Visuals` (4 MeshParts), `Collision` (invisible plinth, posts, board, roof),
`Extras` (two Neon `WarmLens` lantern glows), `Title` (clone of the station sign plane), `Display`
(transparent 7.7 x 5.7 plane; the service builds its `Ranking` SurfaceGui).

## Stats (LeaderboardService)

- **Kills**: +1 when an enemy the player last damaged dies during a real run's Combat phase. Hooked by
  wrapping `ZombieDeath.onDeath` after ShopService sets it (ShopService is not edited). If anything later
  replaces `onDeath` outright, kill counting stops silently.
- **Highest wave**: the run wave while the player is alive in its combat (die on wave 12 → 12).
- **Time played**: seconds in the server, lobby included.
- Admin test runs record no kills or waves (added by another session via `AdminConfig.isTestRun`).
- Saved in `RogueliteLeaderboardStats_v1` (`UpdateAsync`, every field only goes up), ranked in the
  OrderedDataStores `RogueliteTopKills_v1`, `RogueliteTopWave_v1`, `RogueliteTopTime_v1`; boards refresh every
  60 s. Studio keeps everything in memory (unless `EnableStudioDataStores`), and the boards list the
  players in the test server, refreshing every 3 s.

## Verified

- Blender: generator, renders and packaging run clean; atlas hashes match the QuestsV6 atlases.
- Studio: `LeaderboardService` source compiles (`loadstring` in Edit).
- Not yet verified: the published game (OrderedDataStore ranking across servers) and a multi-player
  server. Neither can be tested in Studio without enabling real DataStores.
