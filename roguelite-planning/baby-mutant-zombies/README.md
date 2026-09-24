# Baby and Mutant Zombie: first 3D review

**September 22 follow-up:** The missing top shoulder shirt has been corrected. `Mutant/SlamAnimation.blend` and `Mutant/SlamAnimation.fbx` now contain a baked overhead slam from the shared runtime pose samples. `Slam_Hunched.png`, `Slam_ArmsRaised.png`, and `Slam_Impact.png` are actual Blender previews. Tuned gameplay code is installed, but mesh import and actual Play verification remain pending. See [current integration status](../studio-prototype/combat/ZOMBIE_VARIANTS.md); it supersedes the earlier no-animation status below.

Ready-to-import files: `BabyZombie_Import.fbx` and `MutantZombie_Import.fbx`. Each contains 15 unskinned sections with embedded original artwork. Import as a model with mesh names preserved, without merging meshes or auto-rigging. The scoped installer will create 15 Motor6Ds from the authored joints. `ServerStorage.ZombieVariantImportTools` contains `ZombieImportData` and `InstallZombieVariants` in the open roguelite Edit data model. No UI interaction will resume without explicit permission.

Built from the concept explicitly approved by the user on September 22, 2026. The user requested an early preview before extensive execution or rework. `ModelPreview.png`, each `Preview.png`, and each `Back.png` are actual Blender renders. The approved AI concept is retained separately in `source-art/ApprovedConcept.png`.

## Deliverables

- `Baby/Model.blend` and `Mutant/Model.blend`: editable meshes, packed original textures, provisional rigid rigs, and isolated preview stages.
- `Baby/Model.fbx`, `Mutant/Model.fbx`, and the corresponding GLB files: neutral-pose, textured, rigged exports; no lights, cameras, or floors.
- `Parts.fbx` in each folder: mesh-only export for a future Motor6D assembly.
- Each body has exactly 15 independently articulated sections and a 16-bone R15-style hierarchy. These are custom NPC proportions, not certified Roblox avatar bodies or guaranteed stock-animation replacements.
- Each character has its own newly generated atlas and face. No pixels were copied from the original regular zombie. Clothing outlines, hems, proportions, UVs, and geometry are authored for these meshes.

The baby master uses a non-keyframed arms-forward preview pose. Exports retain the rest pose. Mutant fingers are deliberately simplified into heavy mitten hands. Surface islands reuse regions of each mob's own atlas to reduce material count; the two mobs never share a texture. Small surface transitions remain visible at some separate mesh seams in this initial review version.

## Validation and limits

`verify_models.py` independently reopens Blender, FBX, and GLB files for both characters, checks their 15 body sections and 16 bones, normalized rigid weights, bounded UVs, loaded textures, closed geometry, ground alignment, moving elbow, and stable unrelated foot. The measured report is `verification.json`.

Runtime locomotion and slam code are synced, and the slam is baked into `Mutant/SlamAnimation.fbx` for review. Both meshes are now uploaded and assembled in Studio under `ServerStorage.RogueliteNPCs`; `StudioAssetManifest.json` records all asset IDs. A single-client Play smoke test verified spawns, stats, client motion and mutant slam starts. Detailed attack edge cases, mobile profiling, published asset access and multiplayer remain unverified.

### Rounded full shirt review

The latest mutant revision replaces the separate top patch, front panels, and back wrap with one continuous full-coverage shirt torso. Successively smaller shoulder rings round into the neck, and rounded sleeve crowns replace flat sleeve tops. `Mutant/ShirtReview.png` is the current actual-mesh close-up. The neutral exports, import FBX, geometry metadata, slam assets and installed Studio model use this revision. Earlier pair/underarm review images are historical. Studio importer metadata was refreshed before assembly.

### Corrections after the first in-progress render

The first render retained Blender's default cube UV layer on rounded cubes. It put face pixels on the head top and feet, and clothing pixels on the head edge. The builder now removes all initial UV layers before assigning the custom atlas coordinates. Verification explicitly rejects clothing-quadrant UVs on heads, hands, feet, and forearms. Both faces now occupy the front of the head.

The mutant's front garment was repositioned outside the torso; additional raised chest pieces that could intersect it were removed. Its back and side garment is now a continuous fitted shell rather than a slab. Per the user's correction, full torn short sleeves replace the initially proposed shoulder scraps, including fabric underneath and behind both upper arms. `Mutant/UnderarmCheck.png` shows the raised-arm construction check, not a production animation.

## Reproduction

Run each command from the repository root, in a dedicated background Blender process:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' -b --threads 4 --python-exit-code 1 --python roguelite-planning/baby-mutant-zombies/build_models.py -- Baby
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' -b --threads 4 --python-exit-code 1 --python roguelite-planning/baby-mutant-zombies/build_models.py -- Mutant
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' -b --threads 4 --python-exit-code 1 --python roguelite-planning/baby-mutant-zombies/verify_models.py
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' -b --threads 4 --python-exit-code 1 --python roguelite-planning/baby-mutant-zombies/render_pair.py
```

Textures were produced with the built-in image generation tool. Provenance and the generation prompts are recorded in `ASSETS.md` and `source-art/PROMPTS.md`.
