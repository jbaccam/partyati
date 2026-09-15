# Pale Watcher

Reference-inspired scary creature with an eyeless head, palm eyes, long black claws, draping skin, and grainy pale textures.

## Files

- `PaleWatcher.blend`: editable game mesh, higher-resolution sculpt source, packed textures, custom bone rig, idle action, preview camera and lights.
- `PaleWatcher_Rigged.fbx`: rigged mesh in its rest pose, embedded color/normal textures, no animation.
- `PaleWatcher_Idle.fbx`: same character with a 3-second looping idle sample (30 fps, frames 1–91).
- `textures/PaleWatcher_Color.png`: 4096 × 4096 color atlas with joint redness and mottling.
- `textures/PaleWatcher_Normal.png`: 4096 × 4096 tangent-space normal atlas baked from fine skin wrinkles and pores on the game mesh.
- `textures/PaleWatcher_Roughness.png`: 4096 × 4096 roughness atlas.
- `PaleWatcher_Preview.png`, `PaleWatcher_Detail.png`, `PaleWatcher_Side.png`, and `PaleWatcher_Back.png`: Blender renders.
- `SKIN_ANALYSIS.md`: observations from the user's references and revision 2 changes.
- `validation.json` and `export_validation.json`: measured geometry and export checks.

## Blender

Open `PaleWatcher.blend`; use the **PaleWatcher_Asset** scene. Select `PaleWatcher_Rig`, enter Pose Mode, and rotate the named bones. The root moves the whole character; torso, arms, legs, head, hands, and two bones per finger are available. Play frames 1–91 for the sample idle. The rig uses direct forward-kinematic bone controls; no IK control handles are included. Textures are packed into the file.

The saved camera and lighting are for preview only and excluded from FBX exports. The hidden **High resolution sculpt • editing source** collection is also excluded from exports and has no rig. Unhide it for sculpt editing; hide the game mesh while inspecting the source to avoid overlapping surfaces.

## Roblox import

1. Use Studio's **3D Importer** to select `PaleWatcher_Rigged.fbx`. Keep the rig/skinning data enabled.
2. Inspect the import preview, orientation, and scale before inserting. Source height is approximately 8.5 Blender units, authored with 0.28 m per unit; adjust the import scale for your NPC.
3. If textures are not assigned automatically, add a `SurfaceAppearance` to the mesh and assign the supplied Color PNG to **ColorMap**, Normal PNG to **NormalMap**, and Roughness PNG to **RoughnessMap**.
4. To use the sample motion, import `PaleWatcher_Idle.fbx` through the Animation Editor against the same bone hierarchy. Publish the animation to the appropriate experience owner and play it with an Animator under an AnimationController (or the NPC's Humanoid).

This is a **custom skinned NPC mesh**. It is not a drop-in R15 player avatar or a Marketplace-ready avatar body. NPC movement, collision proxy, AnimationController/Humanoid setup, and game behavior are separate from this art asset.

Official references: [general mesh and rig specifications](https://create.roblox.com/docs/art/modeling/specifications), [3D character import](https://create.roblox.com/docs/art/characters/import).

## Validation and limits

The export verifier reimports the FBX into a fresh Blender scene and checks the triangle budget, bone hierarchy, normalized weights, zero root influences, UVs, closed geometry, and finger deformation. See the JSON report for actual results. Roblox Studio import and animation playback have not been tested. The modeled likeness is an interpretation of the supplied images; it is not a scan or a production replica.

Rebuild with Blender's background Python runner and `build_character.py`; then run `validate_export.py`. Asset work does not modify gameplay or the existing Studio world.
