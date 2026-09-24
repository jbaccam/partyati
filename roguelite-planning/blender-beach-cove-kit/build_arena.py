"""Assemble the Beach Cove arena from the exported kit.

    blender --background --python build_arena.py

Reads exports/glb, places instances into the reference composition, renders
previews/arena-overview.png, and writes arena-layout.json for Studio.

Arena size: 125 studs clear across the sand, inside face to inside face. The
cliff ring is set so each piece's inner wall lands on that circle, then pushed
out slightly where a piece is deep so the ring never eats into the floor.

The layout follows `textures/source/beach-cove-reference.png`: a continuous rim
of mostly mid-height headlands with taller masses at the back, big framing blocks
at the two front corners, palms crowding the rim tops, and a sparse scatter of
rocks, tide pools, grass and driftwood across an otherwise open floor. That
emptiness is deliberate -- MODULAR_CLIFF_KIT.md asks for the central 75-85% to
stay clear for combat.
"""
import json
import math
import random
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
GLB = ROOT / "exports/glb"

ARENA_RADIUS = 62.5          # 125 studs across the clear sand
FLOOR_RADIUS = 120.0          # sand disc, out under the cliff feet

rng = random.Random(20260923)

bpy.ops.wm.read_factory_settings(use_empty=True)


# ---------------------------------------------------------------------------
LIBRARY = {}


def load(stem):
    """Import one exported asset once; later placements are linked duplicates."""
    if stem in LIBRARY:
        return LIBRARY[stem]
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(GLB / f"{stem}.glb"))
    new = [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"]
    obj = new[0]
    obj.name = "LIB_" + stem
    obj.rotation_euler = (0, 0, 0)
    obj.location = (0, 0, 0)
    # glTF import rotates Y-up back to Z-up; bake that in so local space matches
    # the generator's, with z=0 at the foot.
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    lo = min((obj.matrix_world @ v.co).z for v in obj.data.vertices)
    for v in obj.data.vertices:
        v.co.z -= lo
    obj.data.update()
    obj.hide_render = True
    obj.hide_viewport = True
    LIBRARY[stem] = obj
    return obj


PLACEMENTS = []


def place(stem, x, y, z=0.0, yaw=0.0):
    src = load(stem)
    dup = src.copy()          # linked duplicate: shares mesh data and material
    dup.data = src.data
    dup.hide_render = False
    dup.hide_viewport = False
    dup.name = f"{stem}_{len(PLACEMENTS):03d}"
    dup.location = (x, y, z)
    dup.rotation_euler = (0, 0, math.radians(yaw))
    bpy.context.collection.objects.link(dup)
    PLACEMENTS.append({"asset": stem, "blender": (x, y, z), "yaw_deg": yaw})
    return dup


def radius_of(stem):
    """Half-depth of an asset, used to seat it against the arena circle."""
    o = load(stem)
    return max(o.dimensions.x, o.dimensions.y) * 0.5


# ---------------------------------------------------------------------------
# the cliff rim
# ---------------------------------------------------------------------------
# Walked round the circle by angular coverage rather than a fixed list of
# angles: each piece advances the cursor by a fraction of its own angular width,
# so neighbours always overlap and the rim closes with no gaps to see through.
# A hand-written table of 20 slots left roughly 70 studs of holes in a 470-stud
# circumference.
OVERLAP = 0.68          # advance this fraction of each piece's own width

# Which masses suit which part of the ring. The back of the cove carries the
# height, the two front corners carry big framing blocks, as in the reference.
def rim_pool(angle):
    back = 45 <= angle <= 135
    front = 225 <= angle <= 315
    if back:
        return ["06-headland-tall-mass", "03-headland-tall", "09-stack-triple",
                "06-headland-tall-mass", "02-headland-medium", "08-stack-double"]
    if front:
        return ["05-plateau-broad", "10-rim-corner-wedge", "01-headland-short",
                "04-plateau-wide-low", "07-headland-tapered", "05-plateau-broad"]
    return ["02-headland-medium", "05-plateau-broad", "07-headland-tapered",
            "03-headland-tall", "08-stack-double", "01-headland-short"]


def angular_half_width(stem, r):
    o = load(stem)
    return math.degrees(math.atan2(max(o.dimensions.x, o.dimensions.y) * 0.5, r))


rim_objects = []
angle = 0.0
guard = 0
while angle < 360.0 and guard < 200:
    guard += 1
    stem = rng.choice(rim_pool(angle % 360))
    a = math.radians(angle)
    r = ARENA_RADIUS + radius_of(stem) * 0.80
    obj = place(stem, math.cos(a) * r, math.sin(a) * r, 0.0,
                angle + 90 + rng.uniform(-45, 45))
    rim_objects.append((obj, stem, a, r))
    angle += 2 * angular_half_width(stem, r) * OVERLAP

# A second row behind, filling any sky still showing between rim tops.
angle = rng.uniform(0, 30)
guard = 0
while angle < 360.0 and guard < 200:
    guard += 1
    stem = rng.choice(["01-headland-short", "02-headland-medium",
                       "06-headland-tall-mass", "04-plateau-wide-low"])
    a = math.radians(angle)
    r = ARENA_RADIUS + radius_of(stem) * 0.80 + rng.uniform(16, 26)
    place(stem, math.cos(a) * r, math.sin(a) * r, 0.0, rng.uniform(0, 360))
    angle += 2 * angular_half_width(stem, r) * 0.95

# ---------------------------------------------------------------------------
# palms crowding the rim tops, a few down on the sand
# ---------------------------------------------------------------------------
PALMS = ["16-palm-tall", "17-palm-leaning", "18-palm-short"]
for obj, stem, a, r in rim_objects:
    if stem.startswith(("04-", "01-")):
        continue                      # low plateaus stay bare, as in the reference
    for _ in range(rng.choice((1, 1, 2))):
        top = obj.dimensions.z - 1.2
        jitter_a = a + rng.uniform(-0.09, 0.09)
        # Bias outward so palms crown the rim rather than leaning over the floor.
        jitter_r = r + rng.uniform(1, 7)
        place(rng.choice(PALMS),
              math.cos(jitter_a) * jitter_r, math.sin(jitter_a) * jitter_r,
              top, rng.uniform(0, 360))

for angle in (12, 98, 186, 274, 340):
    a = math.radians(angle) + rng.uniform(-0.08, 0.08)
    r = ARENA_RADIUS - rng.uniform(3, 8)
    place(rng.choice(PALMS), math.cos(a) * r, math.sin(a) * r, 0.0, rng.uniform(0, 360))

# ---------------------------------------------------------------------------
# floor dressing -- sparse, keeping the middle open
# ---------------------------------------------------------------------------
def scatter(stem, count, r_min, r_max, avoid=()):
    placed = []
    for _ in range(count):
        for _try in range(60):
            a = rng.uniform(0, math.tau)
            r = math.sqrt(rng.uniform((r_min / ARENA_RADIUS) ** 2, (r_max / ARENA_RADIUS) ** 2)) * ARENA_RADIUS
            x, y = math.cos(a) * r, math.sin(a) * r
            if all((x - px) ** 2 + (y - py) ** 2 > pr ** 2 for px, py, pr in list(avoid) + placed):
                placed.append((x, y, 11.0))
                place(stem, x, y, 0.0, rng.uniform(0, 360))
                break
    return placed

taken = []
# Two tide pools, off-centre, as in the reference.
for x, y in ((-24, -6), (18, 14)):
    place("23-tide-pool-large" if x < 0 else "22-tide-pool-small", x, y, 0.0, rng.uniform(0, 360))
    taken.append((x, y, 16.0))

taken += scatter("24-grass-patch-small", 7, 14, 58, taken)
taken += scatter("25-grass-patch-large", 4, 18, 56, taken)
taken += scatter("11-boulder-medium", 5, 16, 57, taken)
taken += scatter("15-shore-rock-low", 3, 20, 55, taken)
taken += scatter("13-rock-cluster", 2, 30, 54, taken)

# Story props against the rim: driftwood at the front left, the wreck at the right.
place("19-driftwood-log", -40, -38, 0.0, 28)
place("20-driftwood-planks", -33, -44, 0.0, -14)
place("21-wrecked-rowboat", 52, 20, 0.0, 200)
place("12-boulder-large", 46, -34, 0.0, 65)
place("12-boulder-large", -52, 8, 0.0, 130)
place("14-standing-rock", -47, -18, 0.0, 15)

# ---------------------------------------------------------------------------
# sand floor
# ---------------------------------------------------------------------------
bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=FLOOR_RADIUS, depth=2.0, location=(0, 0, -1.0))
floor = bpy.context.object
floor.name = "Sand_Floor"
fm = bpy.data.materials.new("Sand")
fm.use_nodes = True
bsdf = fm.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Roughness"].default_value = 1.0
tx = fm.node_tree.nodes.new("ShaderNodeTexImage")
tx.image = bpy.data.images.load(str(ROOT / "textures/sand.png"))
tx.extension = "REPEAT"
mapping = fm.node_tree.nodes.new("ShaderNodeMapping")
coord = fm.node_tree.nodes.new("ShaderNodeTexCoord")
mapping.inputs["Scale"].default_value = (FLOOR_RADIUS * 2 / 10.0,) * 3
fm.node_tree.links.new(coord.outputs["Object"], mapping.inputs["Vector"])
fm.node_tree.links.new(mapping.outputs["Vector"], tx.inputs["Vector"])
fm.node_tree.links.new(tx.outputs["Color"], bsdf.inputs["Base Color"])
floor.data.materials.append(fm)

# ---------------------------------------------------------------------------
# layout export for Studio
# ---------------------------------------------------------------------------
# Blender is Z-up; the kit exports with axis_up='Y', axis_forward='-Z', so a
# Roblox position is (x, z, -y) and a Blender yaw about +Z becomes a Roblox yaw
# about +Y with the sign flipped.
#
# Roblox also pivots a MeshPart at its bounding-box centre, not at the origin the
# mesh was authored around, so each asset records the offset from its ground
# origin to that centre. The placement script applies it after rotating.
assets = {}
for stem, src in LIBRARY.items():
    xs = [v.co.x for v in src.data.vertices]
    ys = [v.co.y for v in src.data.vertices]
    zs = [v.co.z for v in src.data.vertices]
    cx, cy, cz = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2
    assets[stem] = {
        "size_studs": [round(max(xs) - min(xs), 3), round(max(zs) - min(zs), 3), round(max(ys) - min(ys), 3)],
        "pivot_offset": [round(cx, 3), round(cz, 3), round(-cy, 3)],
    }

layout = {
    "arena_clear_diameter_studs": ARENA_RADIUS * 2,
    "sand_floor_radius_studs": FLOOR_RADIUS,
    "axis_note": "Roblox position = (blender_x, blender_z, -blender_y); yaw_deg is about Roblox +Y",
    "pivot_note": "MeshPart pivots at its bounding-box centre; add pivot_offset after rotating",
    "assets": assets,
    "instances": [
        {
            "asset": p["asset"],
            "position": [round(p["blender"][0], 3), round(p["blender"][2], 3), round(-p["blender"][1], 3)],
            "yaw_deg": round(-p["yaw_deg"] % 360, 2),
        }
        for p in PLACEMENTS
    ],
}
(ROOT / "arena-layout.json").write_text(json.dumps(layout, indent=2))
print("INSTANCES", len(PLACEMENTS), flush=True)

# ---------------------------------------------------------------------------
# render
# ---------------------------------------------------------------------------
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 2400
scene.render.resolution_y = 1350
scene.render.image_settings.file_format = "PNG"
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "None"

world = bpy.data.worlds.new("Sky")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.42, 0.66, 0.90, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.85

bpy.ops.object.light_add(type="SUN")
sun = bpy.context.object
sun.data.energy = 2.6
sun.data.angle = 0.22
sun.rotation_euler = (math.radians(46), 0, math.radians(38))

bpy.ops.object.camera_add()
cam = bpy.context.object
cam.data.lens = 38
scene.camera = cam


def shot(name, location, target):
    cam.location = location
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = str(ROOT / "previews" / name)
    bpy.ops.render.render(write_still=True)


shot("arena-overview.png", (0, -212, 96), (0, 4, 4))
shot("arena-topdown.png", (0, -55, 250), (0, 0, 0))
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "beach-cove-arena.blend"))
print("ARENA_READY", flush=True)
