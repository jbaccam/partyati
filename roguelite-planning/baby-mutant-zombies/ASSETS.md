# Asset provenance

Date: 2026-09-22. Scope: these two zombie models only.

| Asset | Origin | Use |
| --- | --- | --- |
| `source-art/ApprovedConcept.png` | Built-in image generation, explicitly approved in conversation | Shape, clothing and art-direction reference |
| `source-art/BabyTexture.png` | Newly generated with built-in image generation, using the approved concept as style reference | Baby's unique skin, face, ochre shirt and brown shorts/straps |
| `source-art/MutantTexture.png` | Newly generated with built-in image generation, using the approved concept as style reference | Mutant's unique skin, face, brown vest and charcoal-brown trousers |
| Body meshes, UV layouts, rigid rigs | Original procedural authoring in `build_models.py` | Editable custom game assets |
| Render cameras, lights and floor | Original Blender presentation setup | Review only, excluded from body exports |

The regular zombie screenshots were used only to establish the approved concept's style. Its meshes and textures were not reused in these two assets. The user-supplied Minecraft images provided only relative-size and broad silhouette inspiration; no source geometry or texture pixels were extracted from them. No Creator Store, purchased, scraped, or downloaded third-party character geometry is included. The generated concept is not claimed to be a Blender or Studio screenshot.
