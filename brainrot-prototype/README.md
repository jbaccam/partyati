# Playable Tung Sahur prototype

A character movement prototype for a brainrot arena fighter. This is separate from the repository's Copy The Scene project.

The proposed 12-character combat roster is documented in `FIGHTER_ROSTER.md`; its machine-readable values live in `src/shared/FighterDefinitions.luau`.

## Current result

In the connected Studio place, Play starts the player as Tung Sahur. Normal Roblox movement, jumping, camera controls, character collision, and respawning remain driven by the player's existing Humanoid character. The avatar is hidden and Tung Sahur's reviewed visual is welded to its root.

- **WASD / normal movement controls:** move.
- **Space / normal jump control:** jump.
- **T or the bottom-center button:** switch between Tung Sahur and your avatar.
- **Mouse / normal camera controls:** look around and zoom.

The existing place's sprint/double-jump scripts are separate from this package. This prototype does not implement attacks, damage, knockback, lives, matchmaking, or character abilities.

## Motion

`Pose.luau` drives the existing skeleton directly, including breathing, alternating stepping, knee bends, level feet during stance, swing-foot lift, arm swing, jump/fall tuck, landing compression, and a death pose. It also handles seated/swimming/climbing fallback poses.

The walk uses a two-bone leg solver and adjusts cadence with measured horizontal speed. It is a procedural prototype, not a set of artist-authored or uploaded Animation assets. Its feet target a flat plane relative to the character; terrain-aware foot placement and finished combat animation are later work. Very high movement speeds are capped in the animation to avoid extreme motion.

Each client animates all tagged replicated Tung visuals, because Bone.Transform itself is not replicated. The server controls the morph, clones the asset, hides/restores avatar appearance, and accepts only a rate-limited boolean request for the sender's own character. No client bone or arbitrary character/asset data is accepted.

## Studio components

- `ReplicatedStorage.TungPrototype`: Config, Pose, Assets.TungSahur; RequestMorph is created by the server.
- `ServerScriptService.TungPrototypeServer`
- `StarterPlayer.StarterPlayerScripts.TungPrototypeClient`
- Runtime character child: `TungSahurVisual`
- Runtime UI: `PlayerGui.TungPrototypeControls`

The existing source model and other place content are preserved. The prototype is enabled automatically in Studio. `Config.EnablePublished` is false by default; change it deliberately when ready for published testing. There are no DataStores, persistent rewards, or purchase advantages in this package.

## Local build and sync

From the repository root:

```powershell
rojo build brainrot-prototype/default.project.json -o build/TungSahurPrototype.rbxlx
rojo serve brainrot-prototype/default.project.json
```

Connect the Studio Rojo plugin to that separate project. Do not use the root Copy The Scene project to sync this brainrot place. The brainrot project maps only its named components and preserves other service children.

The generated rbxlx is a package verification artifact with the character system and model; it does not include the user's full world or a standalone arena. The assets directory retains the reviewed model's geometry references and bone hierarchy. See ASSETS.md.

## Verification

See TESTING.md for observed Studio results and remaining multiplayer/device checks. Tests and screenshots were performed against the installed source-model clone. The local serialized model snapshot was checked for packaging; a fresh-file asset-loading round trip remains untested.
