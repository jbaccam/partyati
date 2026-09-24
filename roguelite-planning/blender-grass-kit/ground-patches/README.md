# Broad ground grass patches

Four original low meadow meshes, created from scratch in Blender using the user's reference as inspiration. Includes continuous irregular ground-cover surfaces and short blades, separate from the previous upright tuft kit. Shared original GrassPalette.png; no third-party assets.

GroundGrassPatches.fbx contains all four meshes arranged in a lineup. Individual FBX and GLB exports have ground-center origins. The blend file contains the editable preview. Rebuild with ../build_ground_patches.py in background Blender.

Intended sizes: approximately 9 x 6, 13 x 10, 19 x 12, and 23 x 9 studs, all below 1 stud tall. Blender FBX units may import at a different scale in Studio; fit against these bounds before use. Set anchored=true, CanCollide=false, CanTouch=false. Keep the lower edge slightly above terrain to prevent flicker; these meshes assume fairly flat ground.

FBX round-trip checks passed: one mesh/material per individual asset, UVs present, ground origin, no vertices below ground, under 10,000 triangles each. Import triangle counts differ from source by less than 0.5%; both counts are recorded in validation.json. Preview was visually inspected. Roblox Studio import and edit-mode appearance were verified on September 23, 2026. The four GLB exports imported at their intended stud dimensions with the shared palette texture. The reusable originals are in `ServerStorage.RogueliteGrassKit.GroundPatches` in roguelite place 107877054949326; IDs are in `../studio-asset-manifest.json`. They are anchored with collision, touch, and query disabled. A temporary Studio lineup was inspected and removed. In-game placement and performance are not yet tested.

Status: imported and saved in Studio as reusable templates, and all four added to the installed Brushtool 2.1 Brush list on September 23, 2026; not placed in the arena.
