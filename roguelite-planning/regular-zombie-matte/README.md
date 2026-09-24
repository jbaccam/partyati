# Regular zombie palette match

Six texture edits produced with the built-in image generation tool from the regular zombie's original UV textures. Kept the stock mesh, rig, face expression, clothing pattern and normalized UV layout. No new geometry. Source textures remain in `../zombie-stock-r15-preview/supplied-textures/studio-native/`.

Final assets: `Head.png`, `Torso.png`, `LeftArm.png`, `RightArm.png`, `LeftLeg.png`, `RightLeg.png`. Body texture resolution changed from 1024 square to 1254 square; normalized UVs retain their layout. Head remains 1254 square. Original texture IDs and new uploaded IDs are recorded in `texture-ids.json`.

Generation prompt (one call per named texture):

> Edit this Roblox zombie UV texture image ONLY by color grading the green skin to a pale muted olive/sage green with midtone approximately RGB 140,163,95, dark olive mottling. Match a dry matte hand-painted zombie game texture. Reduce dark emerald saturation and baked shiny highlights. Preserve EXACT texture island positions, silhouettes, black background, dimensions, panel boundaries, ALL clothing brown colors, rips, features and the original face expression and feature positions. Do not rearrange, crop, add padding, add text, draw a character or render a 3D model. Output the flat usable UV texture atlas. This is the [part] texture.

Studio material baseline: Plastic, white Color, zero Reflectance, matching the baby/mutant material settings. Applied to the workspace regular showcase and ServerStorage gameplay template. Changes are visual only; combat stats and animation are unchanged.
