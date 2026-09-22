# Asset provenance

The user supplied 35 generated item-reference PNGs in `C:/Users/Jeremiah/Downloads/weapons` and approved the previously completed Glock trial. `inventory.json` records every supplied reference, its exclusive modeling assignment, and its output directory. `approved-glock.json` records the separate approved reference.

All delivered mesh geometry was constructed locally in Blender from those visual references. Review images are renders of the actual mesh assets. No Creator Store models, downloaded meshes, image billboards, or generated substitutes for Blender renders were used.

Each asset directory includes an unmodified `Reference.png` for direct comparison. Unseen surfaces and depth were inferred from the single supplied image and are documented in each README.

Materials use simple colors and local base-color textures, packed into Blender and embedded in exports. Some magic items also use transparent/emissive materials; their final Roblox appearance may require import-side material setup. Staging lights, cameras and review floors are excluded from FBX/GLB exports.

The approved Glock's original trial is retained separately. The standardized delivery copy removes invisible degenerate faces without changing its approved appearance.

### Rocket launcher rear bore repair — September 22, 2026

The imported launcher had eight olive tube-cap triangles and eight dark rear-bore-cap triangles at exactly original X=-2.55. Their overlapping areas caused the reported green interior z-fighting. `batches/guns/build_guns.py` now recesses the dark disk to X=-2.52. `fix_launcher_rear_cap.py` applies this same change to the existing Blender, GLB and FBX without rebaking the atlas. All 2,588 triangles remain and both export reimports have no zero-area triangles. Original files are retained under `assets/11-rocket-launcher/backups/20260922-rear-cap`. No replacement Roblox asset was uploaded; the existing Studio mesh receives the separate native-Part compatibility repair documented in `studio-prototype/ASSETS.md`.
