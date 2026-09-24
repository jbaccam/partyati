# Bowling Ball

Editable reference reconstruction with separately named closed mesh components. Preview and Alternate are actual Blender Cycles renders. Geometry-only FBX/GLB include a packed portable color atlas; palette UV islands intentionally overlap by color. Unseen surfaces inferred from the single source. Component intersections at assembly joints are intentional. Static pose, no rig, no Studio test.

Rebuild: Blender 5.2 --background --threads 4 --python ../../batches/juggler_utility/build_utility.py -- 22

Measured mesh and export checks: validation.json.
