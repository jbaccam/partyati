"""Lobby leaderboards V1: three matching boards (Top Kills, Highest Wave, Time Played).
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python build_leaderboards.py -- --render

Self-contained. The painted-atlas helpers below are a verbatim copy of cohesion-v6/collection/art_helpers.py
(same tile specs, no randomness in the textures), so the Timber/Details/Roof atlases come out byte-identical to
the Collection and Quests atlases already uploaded in Studio. validate_exports.py checks that hash match.

Authored at final stud size. Fronts -Y, ground Z=0, origin = board pivot (plinth centre on the ground).
Meshes: LB_Frame_Timber / LB_Frame_Details / LB_Frame_Roof are shared by all three boards;
LB_Emblem_Kills / LB_Emblem_Wave / LB_Emblem_Time sit in the front gable of each board.
"""
import bpy, bmesh, math, json, sys
import numpy as np
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parent
for d in ['textures', 'exports/fbx', 'renders', 'work']:
    (ROOT / d).mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
N = 2048
tile = {}; mats = {}
groups = {}      # (output mesh, texture family) -> objects
TARGET = 'Frame'  # which output mesh new pieces belong to


# ---- Painted atlases (copied from cohesion-v6/collection/art_helpers.py) -------------------------------
def image(name, pixels):
    im = bpy.data.images.new(name, width=N, height=N, alpha=True); im.pixels.foreach_set(pixels.astype(np.float32).ravel())
    im.filepath_raw = str(ROOT / 'textures' / (name + '.png')); im.file_format = 'PNG'; im.save(); im.pack()
    m = bpy.data.materials.new(name); m.use_nodes = True; bs = m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Roughness'].default_value = .84
    tex = m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image = im; tex.interpolation = 'Linear'; m.node_tree.links.new(tex.outputs['Color'], bs.inputs['Base Color'])
    return m


def texture_set(name, cols, rows, spec):
    arr = np.ones((N, N, 4), dtype=np.float32); w = N // cols; h = N // rows
    for idx, (key, base, kind) in enumerate(spec):
        yy, xx = np.mgrid[0:h, 0:w]; u = xx / (w - 1); v = yy / (h - 1); seed = idx + 7
        patch = .025 * np.sin(u * 8 + np.sin(v * 6 + seed) * .8 + seed) + .020 * np.sin(v * 10 + u * 5 + seed * 3)
        if kind == 'wood':
            flow = u + .016 * np.sin(v * 7 + seed) + .008 * np.sin(v * 19 + seed * 2)
            patch += .030 * np.sin(flow * 28 + seed) + .018 * np.sin(flow * 62 + v * 3)
            for j in range(7):
                center = .07 + j * .14 + .025 * np.sin(v * (5 + j % 3) + seed + j)
                line = np.exp(-((u - center) / (.005 + .002 * (j % 3))) ** 2)
                taper = np.clip(np.sin(v * math.pi * 1.2 + j * .5), 0, 1)
                patch -= line * taper * .15
                patch += np.exp(-((u - center - .010) / .007) ** 2) * taper * .055
            ku = .23 + .12 * (idx % 4); kv = .28 + .12 * (idx % 3)
            r = np.sqrt(((u - ku) / .078) ** 2 + ((v - kv) / .15) ** 2)
            patch -= .11 * np.exp(-((r - .9) / .075) ** 2) + .055 * np.exp(-r * r * 5)
            patch += .038 * np.exp(-((r - 1.1) / .08) ** 2)
            edge = np.minimum(u, 1 - u); patch += .065 * np.exp(-edge / 0.032)
            patch -= .06 * (np.exp(-v / .027) + np.exp(-(1 - v) / .027))
        elif kind == 'end':
            r = np.sqrt(((u - .46) * 1.1) ** 2 + ((v - .52) * .87) ** 2)
            warped = r + .013 * np.sin(np.arctan2(v - .52, u - .46) * 5)
            patch += .03 * np.sin(warped * 25)
            patch -= .10 * np.maximum(0, np.cos(warped * 53)) ** 12
            patch += .045 * np.maximum(0, np.cos(warped * 53 - .6)) ** 10
        elif kind == 'stone':
            patch += .03 * np.sin(u * 12 + v * 5) + .02 * np.cos(v * 13 - u * 3)
            patch += .04 * v - .04 * np.exp(-v / .045)
            for j in range(3):
                cx = .18 + j * .29; cy = .3 + .13 * ((j + idx) % 3)
                patch += .028 * np.exp(-((u - cx) ** 2 / .025 + (v - cy) ** 2 / .065))
        elif kind == 'metal':
            patch += .035 * v + .03 * np.sin(u * 8 - v * 6)
            patch += .07 * np.exp(-np.minimum(u, 1 - u) / .035)
            patch -= .065 * np.exp(-v / .04)
            patch += np.where(v > .67 - .4 * u, .018, -.015)
        elif kind == 'blue':
            patch += .035 * v + .025 * np.sin(u * 9 + v * 4) + .05 * np.exp(-np.minimum(u, 1 - u) / .025)
            patch -= .09 * np.exp(-v / .03)
        elif kind == 'leather':
            patch += .025 * np.sin(u * 6 + v * 4) - .065 * np.exp(-np.minimum(u, 1 - u) / .045)
        rgb = np.array(base, dtype=np.float32) / 255
        tilearr = np.clip(rgb[None, None, :] * (1 + patch[:, :, None] * 1.8), 0, 1)
        row = idx // cols; col = idx % cols; arr[row * h:(row + 1) * h, col * w:(col + 1) * w, :3] = tilearr
        pad = 8; tile[key] = (name, (col * w + pad) / N, (row * h + pad) / N, (w - 2 * pad) / N, (h - 2 * pad) / N)
    mats[name] = image('LeaderboardsV1_' + name, arr)


texture_set('Timber', 4, 2, [
    ('oak', (146, 93, 47), 'wood'), ('oakLight', (171, 116, 62), 'wood'), ('oakWarm', (155, 99, 48), 'wood'), ('oakDark', (106, 66, 36), 'wood'),
    ('end', (183, 138, 78), 'end'), ('endDark', (132, 87, 46), 'end'), ('leather', (104, 58, 37), 'leather'), ('rope', (175, 151, 100), 'wood')])
texture_set('Details', 4, 4, [
    ('stone', (128, 143, 147), 'stone'), ('stoneLight', (157, 169, 165), 'stone'), ('stoneWarm', (148, 148, 133), 'stone'), ('stoneDark', (95, 112, 120), 'stone'),
    ('iron', (39, 50, 59), 'metal'), ('steel', (68, 83, 96), 'metal'), ('steelLight', (125, 145, 156), 'metal'), ('steelEdge', (170, 186, 192), 'metal'),
    ('gold', (177, 127, 49), 'metal'), ('goldLight', (213, 162, 68), 'metal'), ('coal', (31, 35, 39), 'stone'), ('ember', (221, 103, 27), 'stone'),
    ('ash', (86, 82, 72), 'stone'), ('paper', (213, 195, 153), 'leather'), ('red', (147, 62, 43), 'leather'), ('blueInk', (28, 65, 86), 'metal')])
texture_set('Roof', 2, 2, [('blue', (39, 93, 126), 'blue'), ('blueLight', (54, 116, 149), 'blue'), ('blueDark', (29, 64, 83), 'blue'), ('blueMid', (46, 102, 133), 'blue')])


def active(o):
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o


def uv(o, key):
    # Coherent per-piece local-axis grain, with separate perpendicular end grain.
    me = o.data
    while me.uv_layers: me.uv_layers.remove(me.uv_layers[0])
    layer = me.uv_layers.new(name='PaintedUV'); layer.active_render = True
    coords = np.array([v.co[:] for v in me.vertices]); lo = coords.min(0); size = coords.max(0) - lo; axis = int(np.argmax(size))
    wood = key.startswith('oak')
    for face in me.polygons:
        normal = np.array(face.normal); drop = int(np.argmax(np.abs(normal)))
        kk = ('endDark' if key == 'oakDark' else 'end') if wood and drop == axis else key
        if wood and drop != axis: ax0 = [a for a in range(3) if a not in [drop, axis]][0]; ax1 = axis
        else: ax0, ax1 = [a for a in range(3) if a != drop]
        family, x, y, w, h = tile[kk]
        for li in face.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            a = (co[ax0] - lo[ax0]) / max(size[ax0], 1e-5); b = (co[ax1] - lo[ax1]) / max(size[ax1], 1e-5)
            layer.data[li].uv = (x + w * a, y + h * b)


def finish(o, name, key, bevel=0):
    o.name = name; active(o); bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        b = o.modifiers.new('Crafted bevel', 'BEVEL'); b.width = bevel; b.segments = 1; b.affect = 'EDGES'; bpy.ops.object.modifier_apply(modifier=b.name)
    o.data.update(); uv(o, key); family = tile[key][0]; o.data.materials.append(mats[family])
    groups.setdefault((TARGET, family), []).append(o)
    return o


def box(name, p, s, key='oak', bevel=.06, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=p); o = bpy.context.object; o.scale = s; finish(o, name, key, bevel); o.rotation_euler = rot; return o


def mesh(name, v, f, key='oak', bevel=0):
    me = bpy.data.meshes.new(name); me.from_pydata(v, [], f); me.update(); bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); return finish(o, name, key, bevel)


def prism(name, profile, depth, key='steel', y=0, bevel=.04):
    n = len(profile)
    return mesh(name, [(x, y + d, z) for d in [-depth / 2, depth / 2] for x, z in profile],
                [tuple(reversed(range(n))), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)], key, bevel)


def rod(name, a, b, r=.10, key='iron', n=10, r2=None):
    a = Vector(a); b = Vector(b); bpy.ops.mesh.primitive_cone_add(vertices=n, radius1=r, radius2=r if r2 is None else r2, depth=(b - a).length, location=(a + b) / 2)
    o = bpy.context.object; finish(o, name, key, .015 if r > .09 else 0); o.rotation_euler = (b - a).to_track_quat('Z', 'Y').to_euler(); return o


def beam(name, a, b, w=.4, d=.4, key='oakDark'):
    a = Vector(a); b = Vector(b); o = box(name, (a + b) / 2, (w, d, (b - a).length), key, min(w, d) * .12); o.rotation_euler = (b - a).to_track_quat('Z', 'Y').to_euler(); return o


def cyl(name, p, r, h, key='steel', n=12): return rod(name, (p[0], p[1], p[2] - h / 2), (p[0], p[1], p[2] + h / 2), r, key, n)
def bolt(x, y, z, r=.08): return rod('Square forged peg', (x, y - .065, z), (x, y + .035, z), r, 'steelLight', 6)


def ring(name, p, R, r, key='iron', rot=(math.pi / 2, 0, 0), segments=12):
    bpy.ops.mesh.primitive_torus_add(major_segments=segments, minor_segments=5, major_radius=R, minor_radius=r, location=p, rotation=rot); return finish(bpy.context.object, name, key)


def disc(name, x, y, z, r, depth, key, n=16):
    # Flat disc facing -Y (front).
    return rod(name, (x, y + depth / 2, z), (x, y - depth / 2, z), r, key, n)


# ---- Board frame (shared by all three boards) ----------------------------------------------------------
# Contract used by the Studio installer (Blender coords; Studio local = (x, z, -y)):
#   posts x=+-4.75 y=.3; list display plane y=-.06, centre z=4.4, 7.7 x 5.7;
#   title sign plane y=-.53, centre z=8.1, 6.6 x .87; emblem centre (0, -2.1, 10.85).
PX, PY = 4.75, .3
TARGET = 'Frame'
box('Stone plinth core', (0, .2, .17), (11.6, 4.4, .36), 'stoneDark', .14)
for ix in range(4):
    for iy in range(2):
        box('Fitted broad stone flag', (-4.29 + ix * 2.86, -.88 + iy * 2.16, .39), (2.82, 2.12, .14), ['stone', 'stoneWarm', 'stoneLight'][(ix + iy * 2) % 3], .05)

for x in [-PX, PX]:
    s = math.copysign(1, x)
    box('Dressed post footing', (x, PY, .72), (1.22, 1.22, .62), 'stone', .11)
    box('Full height oak post', (x, PY, 4.85), (.84, .84, 8.3), 'oakWarm', .10)
    box('Oak capital', (x, PY, 9.2), (1.18, 1.18, .40), 'oakLight', .065)
    for z in [1.14, 8.5]:
        box('Forged post collar', (x, PY, z), (.91, .91, .26), 'iron', .035)
        for dx in [-.23, .23]: bolt(x + dx, PY - .465, z, .075)
    # Tie beams carry the roof trusses fore and aft; knee braces hold the overhangs.
    box('Roof tie beam', (x, .2, 9.6), (.56, 4.3, .40), 'oakDark', .07)
    beam('Front knee brace', (x, PY, 7.6), (x, -1.3, 9.42), .34, .36, 'oak')
    beam('Rear knee brace', (x, PY, 7.6), (x, 1.9, 9.42), .34, .36, 'oak')
    beam('Inner knee brace', (x, PY, 7.9), (x - s * 1.2, PY, 8.95), .32, .34, 'oak')
    box('Roof purlin', (x, .2, 9.96), (.5, 4.5, .32), 'oakLight', .06)
    # Hanging lantern on a forged bracket off the outer face of each post.
    lx = x + s * 1.12
    beam('Lantern wall bracket', (x + s * .42, PY, 7.2), (lx + s * .08, PY, 7.2), .14, .14, 'iron')
    beam('Bracket diagonal', (x + s * .42, PY, 6.6), (lx, PY, 7.18), .10, .10, 'iron')
    lz = 6.2
    box('Lantern base', (lx, PY, lz), (.52, .52, .12), 'iron', .03)
    box('Lantern warm glass', (lx, PY, lz + .40), (.36, .36, .64), 'goldLight', .03)
    for dx in [-.21, .21]:
        for dy in [-.21, .21]: box('Lantern frame upright', (lx + dx, PY + dy, lz + .40), (.06, .06, .74), 'iron', .012)
    box('Lantern hood', (lx, PY, lz + .80), (.6, .6, .15), 'iron', .04)
    ring('Lantern hanging loop', (lx, PY, lz + .95), .11, .033, 'iron', (math.pi / 2, 0, 0), 8)
    rod('Lantern chain', (lx, PY, lz + 1.03), (lx, PY, 7.15), .03, 'iron', 6)
box('Long header beam', (0, PY, 9.0), (9.5, .56, .58), 'oakWarm', .07)
for x in [-2.6, 0, 2.6]: bolt(x, PY - .30, 9.0, .085)

# Front-gabled truss roof: ridge runs front to back like the Collection pavilion.
RIDGE, EAVE, HALF = 12.1, 9.7, 6.2
def roof_z(x): return RIDGE - abs(x) / HALF * (RIDGE - EAVE)
for ty, front in [(-1.8, True), (2.2, False)]:
    box('Truss bottom chord', (0, ty, 9.95), (11.0, .44, .36), 'oakLight', .06)
    for s in [-1, 1]:
        beam('Truss rafter', (0, ty, roof_z(0) - .38), (s * 5.95, ty, roof_z(5.95) - .38), .44, .46, 'oakLight')
    # Pediment infill behind the truss; the front one carries the stat emblem.
    prism('Gable pediment boards', [(-5.1, 10.12), (5.1, 10.12), (0, 11.6)], .16, 'oakDark', ty + (.2 if front else -.2), .03)
    if not front: beam('Truss king post', (0, ty, 10.1), (0, ty, 11.7), .36, .36, 'oak')
    for x in [-3.6, 3.6]: bolt(x, ty - .25, 9.95, .07)
beam('Fitted ridge timber', (0, -2.25, RIDGE + .02), (0, 2.65, RIDGE + .02), .38, .42, 'oakLight')
for s in [-1, 1]:
    for row in range(2):
        t0 = row * .5; t1 = row * .5 + .52
        for col in range(3):
            ya = -2.2 + col * 1.6; yb = ya + 1.62
            xa, xb = s * HALF * t0, s * HALF * t1
            verts = [(xa, ya, roof_z(xa)), (xa, yb, roof_z(xa)), (xb, yb, roof_z(xb)), (xb, ya, roof_z(xb))]
            mesh('Painted blue roof plate', verts + [(x, y, z - .14) for x, y, z in verts],
                 [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], ['blue', 'blueMid', 'blueLight'][(row + col * 2) % 3], .025)
    for y in [-.6, 1.0]:
        beam('Standing roof seam', (0, y, RIDGE + .035), (s * HALF * 1.02, y, roof_z(HALF * 1.02) + .035), .055, .055, 'blueDark')
    for y in [-2.25, 2.65]:
        beam('Barge board', (0, y, RIDGE + .05), (s * HALF * 1.03, y, roof_z(HALF * 1.03) - .05), .20, .22, 'oakLight')
    beam('Eave fascia', (s * HALF * 1.02, -2.3, EAVE - .1), (s * HALF * 1.02, 2.7, EAVE - .1), .22, .18, 'oakLight')

# List board: vertical boards in a pegged frame, the painted blue display panel, braced from behind.
for i in range(9): box('Board backing plank', (-3.84 + i * .96, PY + .2, 4.4), (.94, .30, 6.2), 'oakDark' if i % 3 == 1 else 'oak', .04)
for x in [-4.15, 4.15]: box('Board frame stile', (x, PY - .05, 4.4), (.36, .70, 6.4), 'oakLight', .05)
for z, h in [(1.35, .36), (7.45, .40)]: box('Board frame rail', (0, PY - .05, z), (8.66, .70, h), 'oakLight', .05)
for x in [-4.15, 4.15]:
    for z in [1.35, 7.45]:
        box('Board corner plate', (x, PY - .415, z), (.40, .05, .40), 'iron', .02); bolt(x, PY - .45, z, .06)
box('Display panel', (0, 0, 4.4), (7.7, .12, 5.7), 'blueDark', .02)
box('Board lower shelf ledge', (0, PY - .5, 1.22), (8.4, .40, .14), 'oakWarm', .035)
for x in [-2.4, 2.4]:
    beam('Rear board strut', (x, 2.1, .45), (x, .75, 4.4), .30, .28, 'oakDark')
    box('Strut iron shoe', (x, 2.05, .55), (.42, .52, .2), 'iron', .03)

# Title plaque; the editable Studio sign floats 0.02 in front of the blue inset (same as the stations).
box('Sign oak surround', (0, -.34, 8.1), (7.1, .30, 1.2), 'oakLight', .09)
box('Sign blue inset', (0, -.49, 8.1), (6.7, .04, .95), 'blueDark', .03)
for x in [-3.35, 3.35]: bolt(x, -.52, 8.1, .08)
for x in [-2.6, 2.6]: box('Plaque iron hanger', (x, -.02, 8.73), (.14, .70, .12), 'iron', .02)


# ---- Emblems (one per board, Details atlas) -----------------------------------------------------------
EX, EY, EZ = 0, -2.1, 10.85
FY = EY - .12  # icon plane, just proud of the medallion face


def medallion():
    disc('Brass medallion rim', EX, EY, EZ, 1.02, .16, 'gold', 20)
    disc('Medallion field', EX, EY - .06, EZ, .86, .08, 'blueInk', 20)
    for a in range(4):
        ang = math.pi / 4 + a * math.pi / 2
        bolt(EX + math.cos(ang) * .94, EY - .1, EZ + math.sin(ang) * .94, .05)


def flat(name, cx, cz, length, width, angle, key, depth=.06, y=None):
    # A flat bar on the icon plane, rotated about the board normal (Y).
    return box(name, (cx, FY if y is None else y, cz), (length, depth, width), key, .012, rot=(0, -angle, 0))


TARGET = 'Emblem_Kills'
medallion()
for s in [-1, 1]:
    ang = math.radians(90 + s * 42)  # blade points up and outwards; hilts cross low
    d = (math.cos(ang), math.sin(ang))
    hx, hz = EX - d[0] * .42, EZ - d[1] * .42  # guard position
    tip = (hx + d[0] * 1.02, hz + d[1] * 1.02)
    flat('Sword blade', hx + d[0] * .45, hz + d[1] * .45, .9, .15, ang, 'steelEdge')
    px, pz = -d[1] * .075, d[0] * .075  # half blade width, perpendicular
    ex, ez = hx + d[0] * .9, hz + d[1] * .9
    prism('Sword point', [(ex + px, ez + pz), (ex - px, ez - pz), (ex + d[0] * .2, ez + d[1] * .2)], .06, 'steelEdge', FY, .01)
    flat('Sword fuller', (hx + tip[0]) / 2, (hz + tip[1]) / 2, .8, .04, ang, 'steel', .02, FY - .04)
    flat('Sword guard', hx, hz, .44, .09, ang + math.pi / 2, 'goldLight', .09)
    flat('Sword grip', hx - d[0] * .18, hz - d[1] * .18, .3, .09, ang, 'red', .08)
    disc('Sword pommel', hx - d[0] * .36, FY, hz - d[1] * .36, .07, .1, 'goldLight', 8)

TARGET = 'Emblem_Wave'
medallion()
# Heater shield with three stacked chevrons: each chevron is one more wave cleared.
shield = [(-.5, .5), (.5, .5), (.5, .05), (.3, -.36), (0, -.6), (-.3, -.36), (-.5, .05)]
prism('Shield brass border', [(EX + x * 1.12, EZ + z * 1.12 + .02) for x, z in shield], .08, 'goldLight', FY + .02, .01)
prism('Shield face', [(EX + x, EZ + z + .02) for x, z in shield], .08, 'steelLight', FY - .02, .01)
for i in range(3):
    cz = EZ - .3 + i * .27
    for s in [-1, 1]:
        flat('Wave chevron', EX + s * .16, cz + .08, .4, .1, s * math.radians(-30), 'red', .05, FY - .07)

TARGET = 'Emblem_Time'
medallion()
top, bot = EZ + .6, EZ - .6
for z in [top, bot]: flat('Hourglass cap', EX, z, .78, .12, 0, 'goldLight', .22)
for x in [-.33, .33]: rod('Hourglass post', (EX + x, FY - .02, bot), (EX + x, FY - .02, top), .035, 'gold', 6)
rod('Upper glass bulb', (EX, FY - .08, top - .05), (EX, FY - .08, EZ + .03), .27, 'steelEdge', 12, .05)
rod('Lower glass bulb', (EX, FY - .08, bot + .05), (EX, FY - .08, EZ - .03), .27, 'steelEdge', 12, .05)
rod('Falling sand', (EX, FY - .15, EZ + .2), (EX, FY - .15, bot + .2), .02, 'goldLight', 5)
rod('Settled sand', (EX, FY - .12, bot + .07), (EX, FY - .12, bot + .26), .22, 'goldLight', 12, .07)
rod('Remaining sand', (EX, FY - .12, EZ + .13), (EX, FY - .12, EZ + .3), .06, 'goldLight', 10, .15)


# ---- Join, validate, export ----------------------------------------------------------------------------
meta = {'kit': 'LobbyLeaderboardsV1', 'front': '-Y', 'up': '+Z', 'units': 'studs (final size)',
        'studio_local': '(x, z, -y); front faces local +Z',
        'contract': {'display': {'center': [0, -.06, 4.4], 'size': [7.7, 5.7]}, 'sign': {'center': [0, -.53, 8.1], 'size': [6.6, .87]},
                     'emblem': [EX, EY, EZ], 'lanterns': [[-5.87, PY, 6.6], [5.87, PY, 6.6]]},
        'meshes': []}
assets = []
for (target, family), obs in groups.items():
    active(obs[0])
    for o in obs: o.select_set(True)
    bpy.ops.object.join(); o = bpy.context.object
    o.name = f'LB_{target}_{family}' if target == 'Frame' else f'LB_{target}'
    bpy.context.scene.cursor.location = (0, 0, 0); bpy.ops.object.origin_set(type='ORIGIN_CURSOR'); bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bm = bmesh.new(); bm.from_mesh(o.data); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=.000001)
    bad = [f for f in bm.faces if f.calc_area() < 1e-10]
    if bad: bmesh.ops.delete(bm, geom=bad, context='FACES')
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(o.data); bm.free(); o.data.update()
    for p in o.data.polygons: p.material_index = 0
    o.data.materials.clear(); o.data.materials.append(mats[family]); assets.append(o)
    o.data.calc_loop_triangles(); vv = np.array([v.co[:] for v in o.data.vertices]); lo = vv.min(0); hi = vv.max(0); tris = len(o.data.loop_triangles)
    assert tris < 20000, (o.name, tris)
    # Triangle soup for the Studio EditableMesh uploader: corner positions, split normals, UVs.
    me = o.data; uvl = me.uv_layers.active.data; P, Nn, U = [], [], []
    for t in me.loop_triangles:
        for li in t.loops:
            P.append([round(c, 5) for c in me.vertices[me.loops[li].vertex_index].co])
            Nn.append([round(c, 5) for c in me.corner_normals[li].vector])
            U.append([round(c, 6) for c in uvl[li].uv])
    (ROOT / 'work' / (o.name + '.mesh.json')).write_text(json.dumps({'p': P, 'n': Nn, 'uv': U}, separators=(',', ':')))
    meta['meshes'].append({'name': o.name, 'texture': 'textures/LeaderboardsV1_' + family + '.png', 'family': family,
                           'center': ((lo + hi) / 2).tolist(), 'size': (hi - lo).tolist(), 'triangles': tris, 'vertices': len(me.vertices),
                           'zero_area_triangles': int(sum(t.area < 1e-10 for t in me.loop_triangles)), 'fbx': 'exports/fbx/' + o.name + '.fbx'})
    active(o)
    bpy.ops.export_scene.fbx(filepath=str(ROOT / 'exports/fbx' / (o.name + '.fbx')), use_selection=True, object_types={'MESH'},
                             axis_forward='-Z', axis_up='Y', path_mode='COPY', embed_textures=True, add_leaf_bones=False)
(ROOT / 'metadata.json').write_text(json.dumps(meta, indent=2))

# ---- Review renders: the three boards on a small arc, as placed in the lobby -----------------------------
names = {o.name: o for o in assets}
frame = [names[n] for n in names if n.startswith('LB_Frame')]
layout = [('Emblem_Kills', 0, 0, 0), ('Emblem_Wave', -13.2, 2.2, -16), ('Emblem_Time', 13.2, 2.2, 16)]  # (emblem, x, y, yaw deg)
coll = bpy.data.collections.new('Review layout'); bpy.context.scene.collection.children.link(coll)
for emblem, x, y, yaw in layout:
    for src in frame + [names['LB_' + emblem]]:
        c = src.copy(); coll.objects.link(c)
        c.location = (x, y, 0); c.rotation_euler = (0, 0, math.radians(yaw))
for o in assets: o.hide_render = True
bpy.ops.mesh.primitive_plane_add(size=80, location=(0, 0, -.01)); g = bpy.context.object; g.name = 'Review meadow'
gm = bpy.data.materials.new('Meadow'); gm.use_nodes = True; gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (.23, .46, .08, 1); g.data.materials.append(gm)

scene = bpy.context.scene; world = bpy.data.worlds.new('Soft daylight'); scene.world = world; world.use_nodes = True
world.node_tree.nodes['Background'].inputs[0].default_value = (.42, .62, .9, 1); world.node_tree.nodes['Background'].inputs[1].default_value = .7


def light(name, loc, power, size, target=(0, 0, 5)):
    bpy.ops.object.light_add(type='AREA', location=loc); o = bpy.context.object; o.name = name; o.data.energy = power; o.data.shape = 'DISK'; o.data.size = size
    o.rotation_euler = (Vector(target) - o.location).to_track_quat('-Z', 'Y').to_euler()


light('Key', (-14, -24, 26), 5200, 10); light('Fill', (20, -10, 14), 2200, 10); light('Rim', (4, 16, 20), 2400, 8)
bpy.ops.object.light_add(type='SUN'); sun = bpy.context.object; sun.data.energy = 2.2; sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
bpy.ops.object.camera_add(); cam = bpy.context.object; scene.camera = cam; cam.data.lens = 35
scene.render.engine = 'CYCLES'; scene.cycles.samples = 48; scene.cycles.use_denoising = True
scene.render.resolution_x = 1600; scene.render.resolution_y = 1000; scene.view_settings.view_transform = 'AgX'
scene.view_settings.look = 'AgX - Punchy'
scene.render.image_settings.file_format = 'PNG'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'LeaderboardsV1.blend'))


def shot(path, loc, target):
    cam.location = loc; cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = str(ROOT / 'renders' / path); bpy.ops.render.render(write_still=True)


if '--render' in sys.argv:
    shot('Leaderboards_Overview.png', (0, -38, 9), (0, 0, 5.5))
    shot('Leaderboards_Center.png', (5, -17, 6.5), (0, 0, 6.8))
    from mathutils import Matrix
    scene.render.resolution_x = scene.render.resolution_y = 700
    for emblem, x, y, yaw in layout:
        rot = Matrix.Rotation(math.radians(yaw), 3, 'Z'); at = Vector((x, y, 0))
        shot(f'Leaderboards_{emblem}.png', at + rot @ Vector((0, -7.5, 10.6)), at + rot @ Vector((0, 0, 10.6)))
print(json.dumps(meta['meshes'], indent=1))
