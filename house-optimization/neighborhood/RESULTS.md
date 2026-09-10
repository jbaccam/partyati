# Measured results

Counts cover the eleven neighborhood roots at the start/end of this pass. Scripts includes Script, LocalScript and ModuleScript.

| Class | Before | After | Removed |
|---|---:|---:|---:|
| BaseParts | 62776 | 40974 | 21802 |
| MeshParts | 4524 | 3208 | 1316 |
| Models | 8740 | 6193 | 2547 |
| Scripts | 376 | 300 | 76 |
| Sounds | 347 | 0 | 347 |
| Lights | 648 | 196 | 452 |
| Textures | 25712 | 3160 | 22552 |
| Decals | 3061 | 1227 | 1834 |
| SurfaceAppearances | 111 | 1 | 110 |

The nice house went from 34,777 to 16,023 BaseParts; the cabin from 5,696 to 4,089; the 4,880-part generic house to 4,456. All 347 remaining sounds were removed. All 300 remaining script instances are protected door systems, including setup scripts that self-remove at runtime.

Validation: 25/25 repaired doors passed automated open/close, endpoint, panel-offset, distance, lock and debounce checks. A mansion sliding door opened 6.300064 studs and closed to zero position residual using actual mouse input. Fresh client/server log checks contained zero warnings/errors. Rojo packaging passed. Native exports were read back and their counts checked; 28 orphaned Motor6Ds found by round-trip validation were removed from Studio.

Limits: imported static doors without controllers were preserved as static geometry. Existing motor-based doors and high-detail floors/walls/cabinets remain hotspots. No multiplayer or low-end device load test was performed.

