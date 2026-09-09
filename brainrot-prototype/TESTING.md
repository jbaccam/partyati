# Verification — 2026-09-08

## Passed in the connected Studio place

- Play starts the existing R15 player as Tung Sahur.
- Actual keyboard W movement and Space jumping exercised Idle, Walk, Jump, Fall, and Land.
- Movement capture recorded about 31.9 studs of displacement; the hip bone rotated and the foot height varied by about 0.42 studs relative to the root.
- Screenshots inspected the transformed character, stepping pose, and airborne pose.
- Server checks: exactly one visual; mesh attached to the correct root; visual massless/unanchored; collision/touch/query disabled on the visual; original body hidden.
- T restores the avatar, removes the clone, and restores the original display name and transparency.
- A temporary accessory added after morphing was hidden and restored to its original 0.37 transparency.
- Invalid string/table payloads and extra arguments were rejected.
- Twenty repeated enable requests did not produce duplicate visuals.
- An immediate toggle following the artificial request burst was correctly rate-limited; a later toggle succeeded.
- Death followed by normal respawn restored the Tung character with 100 health and the camera following the new Humanoid.
- First-person fade tested by temporarily putting the camera at the head: visual LocalTransparencyModifier became 1; restoring the third-person camera returned it to 0.
- A temporary second server-created tagged character was discovered and bone-animated on the client. It was a fixture, **not a second real player**.
- Temporary accessory/observer fixtures were removed.
- Pose test at 0, 4, 8, 16, 24, and 32 studs/second plus sideways/backward movement, jumping, falling, landing, seated and death states: passed; transforms remained finite and reset to identity.
- `rojo build -o build/CopyTheScene.rbxlx`: passed.
- `rojo build brainrot-prototype/default.project.json -o build/TungSahurPrototype.rbxlx`: passed.

## Re-run the pose test

The file `tests/pose.spec.luau` returns a function accepting the Pose module and template Model. Run it in a Studio test context with:

```luau
local package = game.ReplicatedStorage.TungPrototype
local result = runPoseTests(require(package.Pose), package.Assets.TungSahur)
print(game.HttpService:JSONEncode(result))
```

Here `runPoseTests` is the function returned by the test file. It creates and destroys its own fixture and does not manipulate live players.

## Not yet verified

- Two or more real clients observing one another under network latency, including late join and streaming.
- Published experience asset permissions and behavior (published morph is disabled by default).
- Touch and controller input on real devices; the toggle uses TextButton.Activated and normal movement controls.
- R6 players, unusual avatar scales, terrain-aware foot placement, combat knockback, and other custom movement systems.
- Fresh-file loading of the serialized local model snapshot; the live clone of the original model was used for playtesting.
- Persistent data access: not used by this feature.

## Pre-existing place issues observed

Output contained missing Modules errors in imported Steal A Brainrot Base scripts, a Chatted nil error from Workspace.TungTungSahur.Script, an Animation_Ninja infinite yield, and denied access to animation 139702462244046. These came from existing place content. The new TungPrototype scripts did not produce errors in the observed playtest.

The existing double-jump LocalScript captures its initial character and is not rewritten by this prototype. Its behavior after respawn is outside these tests.

