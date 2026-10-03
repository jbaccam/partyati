# Brightness correction — current version

Use `Lighting.corrected.rbxm` and `corrected-lighting.json` instead of the earlier after bundle. Brightness was reduced from 1.8 to 0.45 and range from 30 to 22 across all 205 lights. This reduces overlapping illumination; the current mansion foyer was visually checked with readable wall, floor, and railing detail. Light count and global Lighting settings were unchanged.

# Basic house illumination

Lighting-only update for the eleven existing houses. Geometry, doors and global Lighting settings were unchanged. `lighting.json` records all final light positions and settings in the houses' current world positions. The native before/after bundles contain lighting only, grouped by TargetHousePath; they are not full house models and should not be inserted alongside the existing lights without replacing the old lighting.

The prior nice-house marker cleanup incorrectly converted its invisible light Parts into Models. PointLights parented to those Models did not illuminate anything. This pass replaces all 48 invalid light containers with 46 proper anchored Parts. Locations were recovered from the original fixture layout, spaced apart, lowered from ceilings, and aligned with the house's current 180-degree rotation and vertical translation.

All house illumination uses transparent anchored Parts, collision/touch/query disabled, CastShadow disabled, and shadowless PointLights. Brightness is 1.8, range 30, and color is warm white (255,247,233). Existing lights were reused where functional. Added 4 lights to GEOHOMES Mansion, 1 to the smaller generic house, and 6 to the original nested House to fill coverage gaps. Other houses retained their light counts. Total count increased from 196 to 205, while all 205 now have valid light parents.

Visually checked the nice-house living area and cabin kitchen. Fresh Play mode: 205 lights, zero invalid parents, zero server/client warnings or errors. Property checks verified invisible anchored Parts and disabled collisions, touches, queries and shadows. Full multiplayer frame-time testing was not performed.
