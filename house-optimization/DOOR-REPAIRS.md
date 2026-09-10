# Door and console repairs

Applied to the open Host A Party! Studio place on September 10, 2026. The user's follow-up expanded scope to the specific failing systems in other houses and the local selection plugin.

## Changes

- Added `DoorRuntime` ModuleScript and `Doors` server Script inside the optimized House. They use `script.Parent`, so moving or cloning the House does not depend on its enclosing Folder depth.
- Bound all 25 existing door prompts. E toggles open/close with a 0.55-second eased animation. Existing hinge targets and welded panel membership determine motion, including double and multi-panel doors. Doors start closed. Anchored parts move together without adding physics constraints, sounds, or purchase requirements.
- Kept the two slider triggers that were welded to moving panels stationary at their doorways, so the close interaction stays accessible.
- Server validation checks the actual player, living character, distance, prompt enabled state, door/house lock attributes, an optional door OwnerUserId, and per-door animation debounce. No client-supplied transform or door target is accepted.
- Fixed seven GEOHOMES Mansion sliding-door scripts that connected an undefined Button2. Both buttons are now optional and checked before connecting. Existing Button1 clicks work, with a server distance check.
- Cleared eleven inaccessible TV SoundId references to asset 1326291650. The named Sound instances remain so existing TV scripts can reference them without nil errors. This removes the inaccessible audio rather than suppressing console messages.
- Fixed the local `Roblox/Plugins/Script.rbxmx` selection plugin: removed its obsolete four-Folder House lookup, kept House models protected by name/type, and guarded against running the editor tool during play. Both original and fixed plugin XML files are saved here.

## Verification

- Studio front-door E interaction opened and closed the door.
- All 25 configured House doors passed runtime open/close tests, moving-panel offset checks, nil-player rejection, distance rejection, lock rejection, and rapid-input rejection. Final check confirmed every hinge returned to its closed reference transform.
- A GEOHOMES sliding door was tested with real mouse clicks: opened 6.30006 studs and returned exactly to its starting position. The other six identical source fixes were verified at startup, not individually mouse-clicked.
- The final fresh Studio playtest recorded zero server errors/warnings and zero client errors/warnings. The Studio console tool returned an empty log. This is an observed clean test run, not a guarantee against future errors from unrelated content or changed asset permissions.
- Native serialization/deserialization verified the repaired export and controller source. The export has 10,590 descendants; it adds two script instances and no BaseParts to the optimized House.
- Rojo packaging passed for the separate existing Copy The Scene repository project. This House is distributed as the standalone model asset, not through that Rojo project.
- Studio returned to Edit mode. No publication or multi-client stress test was performed.

## Files

- `House.optimized.rbxm`: updated native model, including working doors.
- `DoorRuntime.luau`, `Doors.server.luau`: authoritative controller source.
- `LegacySlidingDoor.server.luau`: repaired source used by the seven GEOHOMES systems.
- `SelectionPlugin.before.rbxmx`, `SelectionPlugin.fixed.rbxmx`: plugin backup and repaired version.
- `door-repair-audit.json`: original legacy script/sound records and observed test results.
- `DoorRuntimeQA.server.luau`: Studio-only validation harness. It was inserted only in the temporary play session and is not present in the exported House. It moves the test player's character; do not deploy it as game code.
