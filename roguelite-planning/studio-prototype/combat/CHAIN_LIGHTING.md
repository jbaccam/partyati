# Chain weapon readability

The user reported dark equipped idle chains becoming readable during attacks. Compared 02 (nunchucks), 04 (kusarigama), and 25 (wrecking ball) in Studio Play with unchanged materials, shadow casting disabled, independently posed bones, and duplicate meshes at matching orientations. Shadow disabling did not resolve the dark appearance. Shadow-facing idle skins were dark on the matched control too; there was no color/material switch in the animation source. This observation does not establish a Roblox renderer defect.

Applied a visual compensation to the three combat templates only: SurfaceAppearance using the existing texture for ColorMap and EmissiveMaskContent, white EmissiveTint, constant EmissiveStrength 1.5. The same setting applies during idle, swing and recovery; no scene lights, global lighting changes, mesh replacements or combat changes. Low emissive fill can keep them more readable in dark areas too. Display stands remain unchanged.

Reproduce using `../ApplyChainReadability.luau` in the roguelite Edit context. It validates the expected textures and preserves original templates under ServerStorage.BeforeChainReadability. Verified all three corrected templates and clones retain their material. Compared idle and fixed 0.17-second attack poses in the actual Play client, including a shadow-facing camera angle. Root Rojo packaging passed. No multiplayer/device validation was performed. Temporary comparison models, camera callbacks, GUI overrides and test slots were removed when returning to Edit mode.

Reference: https://create.roblox.com/docs/art/modeling/surface-appearance and https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance document the texture-masked emissive contribution.
