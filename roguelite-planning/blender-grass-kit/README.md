# Original meadow grass kit

Six original low-poly grass meshes modeled procedurally in Blender. The user-provided arena image was used only as visual inspiration; no geometry or textures were extracted from it.

Each numbered asset is provided as FBX and GLB, with one mesh, one matte material, an embedded original palette texture, and its origin at ground height. GrassPalette.png is also supplied separately. GrassKit.blend contains the editable lineup and preview lighting. build_grass.py recreates all outputs using background Blender.

Small / tall / wide tufts: 154 / 242 / 286 triangles. Meadow clump / large patch / spreading patch: 572 / 1100 / 1320 triangles. Exact bounds and counts are in manifest.json. Models are static, not rigged or wind animated.

Imported into roguelite place 107877054949326 on September 23, 2026 as reusable templates in `ServerStorage.RogueliteGrassKit.GrassTufts`. Studio's FBX importer enlarged each mesh by 100, so the imported models were scaled to 0.01 and their measured sizes now match the Blender manifest in studs. All templates are anchored and have collision, touch, and query disabled. Mesh and texture IDs are in `studio-asset-manifest.json`. The kit is available for placement; it has not been scattered through the live arena. Vary yaw, scale, and placement, leaving main combat routes readable.

Validation: the rendered Blender lineup and FBX round-trip were checked for one mesh, triangle counts, UVs, material assignment, and ground-level origin. A temporary Studio lineup rendered successfully and was removed after inspection. No Roblox performance or gameplay test has been performed for these assets.
