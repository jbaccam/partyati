# Nice house cabinet cleanup

This is the latest nice house export, superseding `../house-11.optimized.rbxm`. The before model captures the user's current edited house at the start of this pass. Both exports contain only `Workspace.Folder.nice house`; other houses were untouched.

258 cabinet/counter door panels were aligned with their cabinet fronts using their hinge positions and cabinet back planes. Six cabinet variants with merged back geometry used their paired hinge positions to establish the front plane. Panels and handles were anchored before movement to prevent joints from moving them twice. Cabinet assemblies are now static and shut; no cabinet-opening scripts were added. Room doors were not changed.

Removed 604 clothes/hanger parts, 34 glasses/dish stacks, 128 concealed shelves behind opaque cabinet doors, 693 cabinet joints, and 16 empty containers. Closet clothing included individual Shirt/Pant/Fabric meshes missed by the earlier model-level removal. Preserved open closet structure, visible shelving, cabinet bodies, major furniture and architecture.

| Count | Before | After |
|---|---:|---:|
| BaseParts | 15,771 | 15,005 |
| MeshParts | 2,264 | 2,006 |
| Models | 4,102 | 4,086 |
| Joints | 1,366 | 673 |
| Unanchored parts | 1,362 | 673 |
| Total instances | 22,998 | 21,333 |

Scripts 0, sounds 0, lights 48, textures 0, decals 143 and SurfaceAppearances 1 remained unchanged. Detailed records are in audit.json. The count baseline differs from the preceding pass because this pass starts from the user's latest Studio edits.

Validation: visually inspected cabinet variants and emptied closet; fresh Play mode had zero unanchored cabinet door parts among 212 cabinet-only Door parts (258 closures also includes counters/islands). Client and server logs contained zero warnings/errors. Native model round-trip counts matched. Remaining jointed room/window/appliance assemblies were preserved; this is not a multiplayer load benchmark.

Use NiceHouse.optimized.rbxm for this version; do not insert the backup beside it. CloseCabinetPanels.luau records the closure helper; it is not installed as a runtime script.
