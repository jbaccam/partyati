# Hammer zombie — faithful rebuild

A fresh Blender recreation of the supplied hammer-zombie reference, authored to
match that single view as closely as measurement allows. It is model, pose and
textures only: **no rig, no animation, no Roblox export, nothing installed in
Studio.** The earlier attempt in `../hammer-boss-rebuild/` is untouched and
remains available for comparison.

## What this is not

This does not replace the installed boss. `../hammer-boss/finished/` still holds
the rigged, animated, uploaded `HammerBoss_NPC` used by the roguelite encounter.
Nothing here is wired into gameplay.

## Files

- `build_boss.py` — the whole generator. Self-contained: it does not `exec()` or
  import any sibling kit, so editing a neighbouring folder cannot change it.
- `HammerBoss.blend` — editable scene with the baked atlas packed in.
- `textures/HammerBoss_Color.png` — 4096 × 4096 baked colour atlas, 15 sections
  on a 5 × 5 UV grid.
- `textures/HammerBoss_Face.png` — 1024 × 1024 painted face, projected onto the
  skull's front in the shader.
- `manifest.json` — measured geometry.
- `previews/` — real Blender renders. `Reference_Match.png` reproduces the
  sheet's framing and aspect exactly; `Comparison_*.png` are side-by-side sheets
  built by `make_comparison.py`.
- `build.log` — the last build, including the exposure probe output.

## How the reference was measured

The sheet is 1086 × 1448 and the figure spans y=218 to y=1285, so 1067 px covers
an authored height of 11.5 studs — **0.01078 studs per pixel**. Every landmark in
the generator was read off the image at that scale rather than estimated, which
is what fixes the grip separation, the hammer span and the face layout.

| Measure | Reference | Rebuild |
| --- | --- | --- |
| Height | 11.50 | 11.61 |
| Shoulder span (widest, at the upper arm) | ~8.4 | 8.87 |
| Grip separation | ~5.3 | 5.37 |
| Hammer span overall | ~11.0 | 11.61 |
| Hammer head (along haft × thick × tall) | 4.56 × — × 5.11 | 3.42 × 1.94 × 3.96 |
| Head width | 1.88 | 2.06 |
| Ferrules on the haft | 6 | 6 |

The hammer head is authored smaller than the raw silhouette measurement because
that measurement includes the chamfers and lug, and because the weapon sits
closer to the camera than the body and perspective enlarges it.

## Colour: measured, not eyeballed

`build_boss.py` renders the comparison frame, then samples five material regions
in both the render and the reference and prints the per-channel ratio as
`EXPOSURE_PROBE`. Those ratios are multiplied into the `CALIBRATION` table at the
top of the file, and the build is repeated. Current agreement, in sRGB:

| Material | Reference | Rebuild | Worst channel |
| --- | --- | --- | --- |
| Skin (bare belly) | 183, 209, 144 | 185, 211, 145 | 1.8% |
| Shirt | 213, 199, 185 | 209, 197, 183 | 5.2% |
| Hammer iron | 138, 133, 137 | 144, 140, 143 | 10.5% |
| Haft wood | 168, 135, 117 | 169, 137, 116 | 3.4% |
| Trousers | 100, 103, 115 | 95, 100, 109 | 12.0% |

Regions are boxes given as fractions of the frame plus a colour rule, which works
because the render reproduces the sheet's framing. Single-pixel probes were tried
first and failed: the rebuild's limbs do not land on exactly the reference's
pixels, so one coordinate sampled belly in one image and background in the other.

## Construction notes

- Volumes are low-subdivision icospheres, scaled and jittered, **flat shaded**.
  That faceting is the look; smooth shading loses it entirely.
- Speckle uses world-space position so spot density stays constant in stud space
  across every body section. Generated coordinates normalise per object, which
  would give a foot the same spot count as the belly.
- Gore is a union of soft spheres placed at the wounds the reference shows, warped
  at two frequencies with an amplitude derived from each blob's radius. A small
  fixed warp leaves them reading as circles.
- The face is **painted, not modelled**. Modelled sockets read as sunglasses and
  modelled creases read as tusks. The artwork is rasterised with numpy inside the
  generator, then planar-projected onto the skull and gated on the surface facing
  forward so it does not smear down the sides.
- The hammer's bright chamfers come from the Bevel modifier's material index,
  which puts generated bevel faces in a second slot.
- The haft is an eight-sided prism with lengthwise grain, so the wood shader keys
  off **Object** coordinates; the weapon keeps its rotation through the bake for
  that reason while the body is flattened to world space.

## Rebuilding

```
blender -b --python build_boss.py       # ~5 min: bake plus nine renders
python make_comparison.py               # needs Pillow; Blender's Python has none
```

`PROBE_ONLY=1` renders only the comparison frame at low samples for fast
exposure iteration.

## Provenance

The reference is the user's own image, already preserved unchanged in this
repository at `../hammer-boss/source/boss-reference.png`, SHA256
`B401488FE31019B7D2179CBCF652D17082BA92E1B5ED7AD2BF2D5A64736CA6F6`. The file
supplied in this session is a WebP re-encode of that same picture. No pixels from
it are used in the model: the face texture is drawn from measured coordinates,
and all geometry, materials and the colour atlas are authored here. No Creator
Store model is used.

## Validation

Verified in Blender: the generator runs clean under Blender 5.2.1 LTS; the atlas
bakes without errors; nine renders were produced and inspected; the measured
geometry above comes from the built mesh, not from intent; the colour agreement
table comes from sampling the actual render against the actual reference.

Not verified: Roblox Studio import, in-engine appearance and scale, and any
gameplay behaviour — none of which this asset attempts. There is no rig, so no
deformation has been tested.

Known differences from the reference, stated plainly: the shoulders are about 5%
wider and the head about 10% wider than measured; the hammer head reads slightly
larger and more face-on than the sheet, which shows it at a steeper angle; and
the painted eyes are rounder and the forehead furrows more regular than the
sheet's hand-drawn ones. The rebuild interprets a single front view, so the back,
sides and underside are authored rather than recovered.
