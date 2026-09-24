# Crystal shard — shop currency

Original 3D model authored by Astra on September 22, 2026 for this project, based on the user-provided `C:/Users/Jeremiah/Downloads/ChatGPT Image Sep 22, 2026, 10_22_38 AM.png`. No third-party geometry or textures were used. The source reference's license/provenance beyond the user's attachment has not been independently established.

The model follows `../art-references/ART_DIRECTION_USER_2026-09-17.txt`: chunky readable silhouette, visible irregular facets, tiny softened chamfers, controlled blue/cyan colors and a subtle broad painterly base-color texture. The reference's tall double-pointed silhouette is retained. There are no particles, aura, emissive shader, attached lights, cracks, sparks, or ground effect. Preview studio lights and camera are presentation objects only and are excluded from mesh exports.

## Files

- `CrystalShard.blend`: editable mesh and preview lighting, with the base-color image packed.
- `CrystalShard.fbx`: selected mesh only; base-color texture embedded.
- `CrystalShard.glb`: portable selected mesh with base-color texture.
- `CrystalShard_BaseColor.png`: 512 × 512 opaque base-color map; use as the Roblox mesh texture.
- `CrystalShard_Preview.png`: transparent isolated render.
- `generate_crystal_shard.py`: deterministic Blender mesh/texture/export/render generator.
- `CrystalShardGeometry.json`: original 24-facet silhouette in Y-up coordinates, one-based triangles and per-face RGB colors.
- `CrystalShardVisual.lua`: immediate upload-free Roblox WedgePart fallback using that same silhouette and face palette.

## Scale and Roblox integration

The unchamfered source is 3 Blender units tall, centered on its origin, with Z up. The final chamfered mesh measures 1.0061 × 0.6890 × 2.9009 units and contains 40 vertices / 76 triangles. Default fallback gameplay height is 1.25 studs. Import the FBX through Studio's 3D Importer, check import units and scale to the desired height. Publish the mesh under the experience owner before relying on it in a published experience. Mesh export has one material, a UV map, and no external runtime dependencies beyond the texture. The mesh uses an opaque painted finish so its silhouette remains readable against grass.

Until the mesh has an approved uploaded asset ID, copy the Lua module into the game's shared modules and call `CrystalShardVisual.create(parent, "CrystalShard", 1.25)`. It returns a Model with a centered, invisible `PrimaryPart`; position it with `Model:PivotTo(...)`. All geometry is anchored and non-colliding/non-queryable/non-touching. The server should own pickup validation separately. The fallback has 24 triangles represented by 48 WedgeParts plus the invisible root. Use the imported single MeshPart for production drop density; the fallback deliberately sacrifices chamfers and texture variation to avoid requiring mesh upload or EditableMesh permissions.

## Reproduce

Run `"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --python roguelite-planning/crystal-shard/generate_crystal_shard.py` from the repository root. The generator writes only this asset directory and runs in a fresh Blender process, so it does not change an open Blender or Studio scene.

## Verification scope

Generated and rendered successfully with Blender 5.2.1 LTS, with both mesh exports completed. Reloaded the saved `.blend` and verified every edge is manifold, all 76 triangles have positive area, and the mesh has exactly one material and one UV map. Astra visually inspected the final PNG preview: isolated blue/cyan shard, clear double tips and large facets, no aura or VFX. Gameplay pickup behavior, currency accounting and Studio client testing are owned by the integrating gameplay change, not verified by this asset generator.
