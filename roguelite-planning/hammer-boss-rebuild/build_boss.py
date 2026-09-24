"""Hammer boss stage 1: geometry, painterly atlas, R15+Hammer rig, previews.

Proportions are width-weighted on purpose. The boss reads as the largest zombie
through shoulder span, belly mass and weapon size, not through height alone.
"""
import bpy, math, json, random
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
(OUT / 'textures').mkdir(exist_ok=True)
(OUT / 'previews').mkdir(exist_ok=True)
random.seed(71)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
parts = {}; spec = {}


def mixnode(nt):
    """Blender 4/5 split ShaderNodeMix off ShaderNodeMixRGB; support both."""
    try:
        m = nt.nodes.new('ShaderNodeMix'); m.data_type = 'RGBA'; m.blend_type = 'MIX'
        fac = [s for s in m.inputs if s.name == 'Factor'][0]
        cols = [s for s in m.inputs if s.name in ('A', 'B') and s.type == 'RGBA']
        res = [s for s in m.outputs if s.type == 'RGBA'][0]
        return m, fac, cols[0], cols[1], res
    except Exception:
        m = nt.nodes.new('ShaderNodeMixRGB')
        return m, m.inputs[0], m.inputs[1], m.inputs[2], m.outputs[0]


def material(name, color, patch=True, blood=0.0, bscale=2.4, bseed=0.0, bthresh=.56):
    """Emission colour source for the EMIT bake. Blood is a soft noise mask so
    stains keep painterly edges instead of reading as pasted-on decals."""
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; n = nt.nodes; n.clear()
    out = n.new('ShaderNodeOutputMaterial'); em = n.new('ShaderNodeEmission')
    nt.links.new(em.outputs[0], out.inputs['Surface'])
    if not patch:
        em.inputs[0].default_value = (*color, 1)
        return m
    coord = n.new('ShaderNodeTexCoord')
    noise = n.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = 4.2
    noise.inputs['Detail'].default_value = 1.0
    noise.inputs['Roughness'].default_value = .65
    nt.links.new(coord.outputs['Generated'], noise.inputs['Vector'])
    ramp = n.new('ShaderNodeValToRGB'); ramp.color_ramp.interpolation = 'CONSTANT'
    ramp.color_ramp.elements.remove(ramp.color_ramp.elements[1])
    for i, (pos, fac) in enumerate([(0, .70), (.34, .83), (.45, .95), (.56, 1.05), (.67, 1.14)]):
        e = ramp.color_ramp.elements[0] if i == 0 else ramp.color_ramp.elements.new(pos)
        e.position = pos; e.color = (*[c * fac for c in color], 1)
    nt.links.new(noise.outputs['Fac'], ramp.inputs[0])
    src = ramp.outputs[0]
    if blood > 0:
        bn = n.new('ShaderNodeTexNoise')
        bn.inputs['Scale'].default_value = bscale
        bn.inputs['Detail'].default_value = 2.0
        bn.inputs['Roughness'].default_value = .52
        if 'W' in bn.inputs:
            bn.inputs['W'].default_value = bseed
        nt.links.new(coord.outputs['Generated'], bn.inputs['Vector'])
        br = n.new('ShaderNodeValToRGB'); br.color_ramp.interpolation = 'EASE'
        br.color_ramp.elements[0].position = bthresh
        br.color_ramp.elements[0].color = (0, 0, 0, 1)
        br.color_ramp.elements[1].position = min(.99, bthresh + .17)
        br.color_ramp.elements[1].color = (1, 1, 1, 1)
        nt.links.new(bn.outputs['Fac'], br.inputs[0])
        gate = n.new('ShaderNodeMath'); gate.operation = 'MULTIPLY'
        gate.inputs[1].default_value = blood
        nt.links.new(br.outputs[0], gate.inputs[0])
        mx, fac_s, a_s, b_s, res = mixnode(nt)
        nt.links.new(src, a_s)
        b_s.default_value = (.255, .034, .030, 1)
        nt.links.new(gate.outputs[0], fac_s)
        src = res
    nt.links.new(src, em.inputs[0])
    return m


GREEN = (.27, .56, .065)
skin = material('Mottled boss skin', GREEN)
skinB = material('Boss skin with stains', GREEN, blood=.85, bseed=1.7, bthresh=.60)
skinFace = material('Boss face skin', GREEN, blood=.88, bseed=4.1, bthresh=.60)
shirt = material('Torn canvas shirt', (.62, .58, .47), blood=.55, bseed=2.9, bthresh=.66)
strap = material('Worn leather strap', (.20, .145, .105))
pants = material('Ragged slate trousers', (.115, .135, .175))
sash = material('Faded red waist sash', (.29, .075, .075))
steel = material('Battered hammer steel', (.29, .30, .315), blood=.50, bseed=5.3, bthresh=.70)
wood = material('Scarred hammer haft', (.26, .155, .085))
band = material('Iron haft band', (.175, .18, .195))
dark = material('Mouth and sockets', (.020, .016, .012), False)
eye = material('Pale dead eyes', (.88, .90, .86), False)
tooth = material('Blunt yellow teeth', (.70, .66, .40), False)
brow = material('Heavy brow shadow', (.19, .28, .09), False)


def add(obj, part, mat):
    obj.data.materials.clear(); obj.data.materials.append(mat)
    parts.setdefault(part, []).append(obj)
    return obj


def box(part, loc, dim, mat, bev=.06, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object; o.dimensions = dim
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rot:
        o.rotation_euler = rot
    if bev:
        mod = o.modifiers.new('Softened edge', 'BEVEL'); mod.width = bev; mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return add(o, part, mat)


def frustum(part, base, top, bw, bd, tw, td, mat, bev=.07):
    """Tapered limb segment. Distinct upper-arm and forearm tapers are what give
    the limbs an elbow instead of the featureless sausage look."""
    bx, by, bz = base; tx, ty, tz = top
    v = [(bx - bw / 2, by - bd / 2, bz), (bx + bw / 2, by - bd / 2, bz),
         (bx + bw / 2, by + bd / 2, bz), (bx - bw / 2, by + bd / 2, bz),
         (tx - tw / 2, ty - td / 2, tz), (tx + tw / 2, ty - td / 2, tz),
         (tx + tw / 2, ty + td / 2, tz), (tx - tw / 2, ty + td / 2, tz)]
    f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    me = bpy.data.meshes.new('limb segment'); me.from_pydata(v, [], f); me.update()
    o = bpy.data.objects.new('limb', me); scene.collection.objects.link(o)
    if bev:
        mod = o.modifiers.new('Softened edge', 'BEVEL'); mod.width = bev; mod.segments = 1
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return add(o, part, mat)


def blob(part, loc, scale, mat, sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=1, location=loc)
    o = bpy.context.object; o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return add(o, part, mat)


def panel(part, coords, y, thick, mat):
    verts = [(x, y, z) for x, z in coords] + [(x, y + thick, z) for x, z in coords]
    n = len(coords)
    faces = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))] + \
            [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    me = bpy.data.meshes.new('torn panel'); me.from_pydata(verts, [], faces); me.update()
    o = bpy.data.objects.new('detail', me); scene.collection.objects.link(o)
    return add(o, part, mat)


def register(name, parent, head, tail):
    spec[name] = {'parent': parent, 'head': head, 'tail': tail}


# ---------------------------------------------------------------- skeleton plan
# Front is Blender -Y. Ground is z=0. Target total height 10.8.
ROOT_Z = 4.45
register('LowerTorso', 'HumanoidRootPart', (0, 0, 4.45), (0, 0, 5.55))
register('UpperTorso', 'LowerTorso', (0, 0, 5.55), (0, 0, 8.60))
register('Head', 'UpperTorso', (0, -.10, 8.92), (0, -.10, 10.80))

GRIP = {}
for side, s in [('Right', -1), ('Left', 1)]:
    # Elbow pushed out and the grip pulled in: the rest pose must sit well inside
    # the chain length or no IK pose can reach without tearing the wrist apart.
    sh = (s * 2.30, .05, 8.22)
    el = (s * 2.95, -1.15, 6.30)
    wr = (-1.45, -2.45, 5.25) if s < 0 else (.62, -2.45, 5.25)
    tip = (wr[0] - s * .10, wr[1] - .42, wr[2] - .34)
    register(side + 'UpperArm', 'UpperTorso', sh, el)
    register(side + 'LowerArm', side + 'UpperArm', el, wr)
    register(side + 'Hand', side + 'LowerArm', wr, tip)
    GRIP[side] = wr
    lx = s * 1.18
    register(side + 'UpperLeg', 'LowerTorso', (lx, 0, 4.30), (lx * 1.10, 0, 2.52))
    register(side + 'LowerLeg', side + 'UpperLeg', (lx * 1.10, 0, 2.52), (lx * 1.16, -.02, .78))
    register(side + 'Foot', side + 'LowerLeg', (lx * 1.16, -.02, .78), (lx * 1.16, -.85, .30))
register('Hammer', 'HumanoidRootPart', (-.415, -2.45, 5.25), (.585, -2.45, 5.25))

# ---------------------------------------------------------------- torso + belly
box('LowerTorso', (0, -.15, 4.78), (3.05, 2.35, 1.55), pants, .16)
box('LowerTorso', (0, -.30, 5.42), (3.30, 2.55, .52), sash, .10)
# Belly is the silhouette defining mass: widest point, projecting well forward.
# It is kept below the chest so the shirt has clear space to read above it.
blob('LowerTorso', (0, -1.06, 5.66), (2.38, 1.98, 1.20), skin)
blob('UpperTorso', (0, -1.10, 6.46), (2.44, 2.02, 1.26), skinB)
box('UpperTorso', (0, -.22, 5.98), (2.95, 2.05, 1.05), skin, .18)
# Chest and shoulder yoke carry the width. The deltoid mass lives on the arm
# only; doubling it on the torso made the shoulders read as cauliflower.
box('UpperTorso', (0, -.05, 7.62), (4.32, 2.16, 1.62), skin, .22)
box('UpperTorso', (0, -.02, 8.18), (4.72, 2.02, .96), skin, .20)
box('UpperTorso', (0, -.10, 8.76), (1.52, 1.40, .70), skin, .12)
# Torn canvas shirt. The chest panel sits above the belly and the side flaps hang
# past it, so the fabric frames the bare gut instead of being swallowed by it.
panel('UpperTorso', [(-2.02, 8.46), (2.02, 8.46), (1.96, 7.62), (1.60, 7.28),
                     (1.12, 7.58), (.52, 7.18), (-.14, 7.52), (-.78, 7.14),
                     (-1.32, 7.50), (-1.74, 7.20), (-1.98, 7.52)], -1.34, .14, shirt)
panel('UpperTorso', [(-2.06, 8.48), (2.06, 8.48), (2.00, 7.48), (1.62, 7.76),
                     (1.10, 7.40), (.42, 7.70), (-.44, 7.38), (-1.20, 7.68),
                     (-1.70, 7.34), (-2.02, 7.60)], 1.04, .14, shirt)
for s in [-1, 1]:
    # Flank flap, hanging outside the belly silhouette.
    panel('UpperTorso', [(s * 1.74, 8.44), (s * 2.42, 8.34), (s * 2.50, 7.10),
                         (s * 2.26, 6.40), (s * 2.02, 6.98), (s * 1.78, 6.62),
                         (s * 1.70, 7.42)], -1.44, 2.66, shirt)
    box('UpperTorso', (s * 1.24, -1.42, 7.98), (.38, .24, 1.28), strap, .05, rot=(0, s * .17, 0))
    box('UpperTorso', (s * 1.36, 1.10, 7.98), (.38, .24, 1.28), strap, .05, rot=(0, s * .17, 0))
    box('UpperTorso', (s * 1.18, -1.48, 7.34), (.50, .18, .44), band, .04)

# ---------------------------------------------------------------- head
box('Head', (0, -.10, 9.82), (2.42, 2.08, 1.92), skinFace, .20)
box('Head', (0, .08, 10.76), (2.18, 1.88, .26), skin, .08)
for s in [-1, 1]:
    # Heavy ridge slanting down toward the nose reads as a scowl at a distance.
    box('Head', (s * .54, -1.16, 10.06), (.94, .34, .38), brow, .06, rot=(0, -s * .24, 0))
    blob('Head', (s * .52, -1.00, 9.78), (.42, .20, .36), dark, 1)
    blob('Head', (s * .52, -1.13, 9.80), (.28, .12, .23), eye, 1)
box('Head', (0, -1.10, 9.42), (1.34, .17, .52), dark, .09)
for x, z, w in [(-.44, 9.52, .22), (-.12, 9.55, .24), (.20, 9.54, .22), (.50, 9.50, .19)]:
    box('Head', (x, -1.14, z), (w, .14, .22), tooth, .02, rot=(0, random.uniform(-.14, .14), 0))
for x, z, w in [(-.30, 9.31, .19), (.18, 9.32, .21)]:
    box('Head', (x, -1.14, z), (w, .14, .19), tooth, .02)
box('Head', (0, -1.08, 9.70), (.34, .28, .40), skinFace, .07)
box('Head', (0, -.10, 9.02), (1.34, 1.26, .38), skin, .10)

# ---------------------------------------------------------------- arms
for side, s in [('Right', -1), ('Left', 1)]:
    sh = Vector(spec[side + 'UpperArm']['head'])
    el = Vector(spec[side + 'UpperArm']['tail'])
    wr = Vector(spec[side + 'LowerArm']['tail'])
    blob(side + 'UpperArm', sh + Vector((s * .16, -.05, -.06)), (1.14, 1.12, 1.00), skin)
    frustum(side + 'UpperArm', (sh.x + s * .04, sh.y - .18, sh.z - .30),
            (el.x, el.y + .10, el.z + .22), 1.72, 1.74, 1.42, 1.46,
            skinB if s < 0 else skin)
    blob(side + 'LowerArm', el + Vector((0, -.04, .04)), (.76, .80, .72), skin)
    frustum(side + 'LowerArm', (el.x, el.y - .06, el.z),
            (wr.x + s * .06, wr.y + .06, wr.z + .18), 1.40, 1.44, 1.16, 1.18,
            skin if s < 0 else skinB)
    box(side + 'Hand', (wr.x - s * .04, wr.y - .30, wr.z - .26), (1.16, 1.02, .96), skin, .12)
    for i in range(4):
        box(side + 'Hand', (wr.x - s * .04, wr.y - .78, wr.z - .02 - i * .27),
            (1.12, .40, .24), skin, .05)
    box(side + 'Hand', (wr.x + s * .52, wr.y - .48, wr.z - .18), (.34, .52, .46), skin, .07)

# ---------------------------------------------------------------- legs
for side, s in [('Right', -1), ('Left', 1)]:
    hp = Vector(spec[side + 'UpperLeg']['head'])
    kn = Vector(spec[side + 'UpperLeg']['tail'])
    an = Vector(spec[side + 'LowerLeg']['tail'])
    frustum(side + 'UpperLeg', (hp.x, hp.y, hp.z - .05), (kn.x, kn.y, kn.z + .10),
            1.78, 1.86, 1.50, 1.56, pants)
    panel(side + 'UpperLeg', [(hp.x - .86, 2.92), (hp.x - .58, 2.66), (hp.x - .22, 2.94),
                              (hp.x + .24, 2.62), (hp.x + .62, 2.90), (hp.x + .86, 2.70),
                              (hp.x + .84, 2.52), (hp.x - .86, 2.52)], -.98, 1.94, pants)
    blob(side + 'LowerLeg', kn + Vector((0, -.04, 0)), (.78, .82, .70), skin)
    frustum(side + 'LowerLeg', (kn.x, kn.y, kn.z), (an.x, an.y, an.z + .18),
            1.48, 1.54, 1.28, 1.34, skin)
    box(side + 'Foot', (an.x, an.y - .48, .42), (1.82, 2.58, .88), skin, .16)
    box(side + 'Foot', (an.x, an.y - .48, .07), (1.86, 2.62, .16), skin, .03)

# ---------------------------------------------------------------- hammer
HY, HZ = -2.45, 5.25
HAFT_MIN, HAFT_MAX = -3.66, 1.95
box('Hammer', ((HAFT_MIN + HAFT_MAX) / 2, HY, HZ),
    (HAFT_MAX - HAFT_MIN, .62, .66), wood, .07)
for bx in [-2.72, -2.05, -1.05, -.02, .95, 1.62]:
    box('Hammer', (bx, HY, HZ), (.22, .69, .73), band, .04)
box('Hammer', (1.90, HY, HZ), (.38, .76, .80), band, .05)
# Head: roughly as wide as the torso from belly centre to one side.
box('Hammer', (-4.66, HY, HZ), (2.30, 2.22, 3.30), steel, .17)
box('Hammer', (-3.66, HY, HZ), (.50, 1.56, 2.08), steel, .10)
box('Hammer', (-5.76, HY, HZ), (.34, 1.78, 2.36), steel, .09)
box('Hammer', (-4.66, HY - 1.16, HZ), (.70, .24, .70), steel, .06)
for dz, dy in [(1.12, -.62), (-1.06, .58), (.42, .74)]:
    box('Hammer', (-4.30, HY + dy, HZ + dz), (.86, .14, .30), band, .04,
        rot=(random.uniform(-.2, .2), 0, 0))

# ------------------------------------------------- join, unwrap, bake the atlas
objects = {}
order = list(parts.keys())
for idx, name in enumerate(order):
    items = parts[name]
    bpy.ops.object.select_all(action='DESELECT')
    for o in items:
        o.select_set(True)
    bpy.context.view_layer.objects.active = items[0]
    if len(items) > 1:
        bpy.ops.object.join()
    o = bpy.context.object; o.name = name
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    scene.cursor.location = spec[name]['head']
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=.025)
    bpy.ops.object.mode_set(mode='OBJECT')
    for uv in o.data.uv_layers.active.data:
        uv.uv = ((uv.uv.x * .94 + .03 + idx % 4) / 4, (uv.uv.y * .94 + .03 + idx // 4) / 4)
    objects[name] = o

atlas = bpy.data.images.new('HammerBoss_Color', width=2048, height=2048, alpha=False)
for m in [skin, skinB, skinFace, shirt, strap, pants, sash, steel, wood, band, dark, eye, tooth, brow]:
    nd = m.node_tree.nodes.new('ShaderNodeTexImage'); nd.image = atlas
    m.node_tree.nodes.active = nd
scene.render.engine = 'CYCLES'; scene.cycles.samples = 1
scene.render.bake.margin = 6; scene.render.bake.use_clear = False
for o in objects.values():
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.bake(type='EMIT')
atlas.filepath_raw = str(OUT / 'textures/HammerBoss_Color.png')
atlas.file_format = 'PNG'; atlas.save(); atlas.pack()
mat = bpy.data.materials.new('HammerBoss painted atlas'); mat.use_nodes = True
bs = mat.node_tree.nodes.get('Principled BSDF')
bs.inputs['Roughness'].default_value = .93
tex = mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image = atlas
mat.node_tree.links.new(tex.outputs['Color'], bs.inputs['Base Color'])
for o in objects.values():
    o.data.materials.clear(); o.data.materials.append(mat)
    for p in o.data.polygons:
        p.material_index = 0

# ---------------------------------------------------------------------- armature
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.armature_add(location=(0, 0, 0))
rig = bpy.context.object; rig.name = 'HammerBoss_Rig'; rig.show_in_front = True
bpy.ops.object.mode_set(mode='EDIT')
eb = rig.data.edit_bones; eb.remove(eb[0])
root = eb.new('HumanoidRootPart'); root.head = (0, 0, ROOT_Z); root.tail = (0, 0, ROOT_Z + .45)
for name, d in spec.items():
    b = eb.new(name); b.head = d['head']; b.tail = d['tail']
    b.parent = eb[d['parent']]; b.use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')
for name, o in objects.items():
    vg = o.vertex_groups.new(name=name)
    vg.add(list(range(len(o.data.vertices))), 1, 'REPLACE')
    md = o.modifiers.new('Rigid limb skinning', 'ARMATURE'); md.object = rig
    o.parent = rig

allv = [(o.matrix_world @ v.co) for o in objects.values() for v in o.data.vertices]
body = [(objects[n].matrix_world @ v.co) for n in objects if n != 'Hammer'
        for v in objects[n].data.vertices]
torso = [(objects[n].matrix_world @ v.co) for n in ('LowerTorso', 'UpperTorso')
         for v in objects[n].data.vertices]


def seg(a, b):
    return (Vector(a) - Vector(b)).length


reach = seg(spec['RightUpperArm']['head'], spec['RightUpperArm']['tail']) + \
        seg(spec['RightLowerArm']['head'], spec['RightLowerArm']['tail'])
restspan = seg(spec['RightUpperArm']['head'], spec['RightLowerArm']['tail'])
stats = {
    'sections': len(objects), 'bones': len(rig.data.bones),
    'triangles': sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objects.values()),
    'height': round(max(v.z for v in body), 3),
    'shoulderSpan': round(max(v.x for v in body) - min(v.x for v in body), 3),
    'bellyDepth': round(-min(v.y for v in torso), 3),
    'hammerSpan': round(max(v.x for v in allv) - min(v.x for v in allv), 3),
    'gripSeparation': round((Vector(GRIP['Left']) - Vector(GRIP['Right'])).length, 3),
    'armReach': round(reach, 3),
    'restShoulderToGrip': round(restspan, 3),
    'restReachUsed': round(restspan / reach, 3),
    'front': 'Blender -Y; Roblox -Z', 'rootHeight': ROOT_Z,
    'joints': spec,
    'animationStatus': 'Stage 1 rig only; no clips authored yet',
}
(OUT / 'manifest.json').write_text(json.dumps(stats, indent=2))

# ------------------------------------------------------------------- previews
floor = bpy.data.materials.new('Preview backdrop'); floor.use_nodes = True
fb = floor.node_tree.nodes.get('Principled BSDF')
fb.inputs['Base Color'].default_value = (.17, .21, .26, 1)
fb.inputs['Roughness'].default_value = .92
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -.14))
fl = bpy.context.object; fl.dimensions = (240, 240, .26); fl.name = 'PreviewFloor'
fl.data.materials.append(floor)


def aim(o, p):
    o.rotation_euler = (Vector(p) - o.location).to_track_quat('-Z', 'Y').to_euler()


bpy.ops.object.camera_add(location=(0, -30, 7)); cam = bpy.context.object
cam.data.type = 'ORTHO'; cam.data.ortho_scale = 15.5; scene.camera = cam
for loc, power, size in [((-9, -13, 17), 1500, 9), ((8, -7, 11), 900, 7), ((2, 11, 14), 1250, 8)]:
    bpy.ops.object.light_add(type='AREA', location=loc)
    l = bpy.context.object; l.data.energy = power; l.data.shape = 'DISK'; l.data.size = size
    aim(l, (0, 0, 5.4))
scene.world.color = (.22, .22, .22)
scene.cycles.samples = 28; scene.cycles.use_denoising = True
scene.render.resolution_x = 820; scene.render.resolution_y = 1040
# Standard, not AgX: the preview should report the baked albedo the Roblox
# surface will actually show, and AgX desaturates it well away from that.
scene.view_settings.view_transform = 'Standard'
scene.render.image_settings.file_format = 'PNG'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'HammerBoss.blend'))
for tag, loc in [('Front', (0, -30, 7)), ('ThreeQuarter', (19, -23, 10)),
                 ('Side', (30, 0, 7)), ('Back', (0, 30, 7))]:
    cam.location = loc; aim(cam, (0, -.4, 5.4))
    scene.render.filepath = str(OUT / f'previews/Boss_{tag}.png')
    bpy.ops.render.render(write_still=True)
print('BOSS_STAGE1_COMPLETE', json.dumps({k: stats[k] for k in
      ['sections', 'bones', 'triangles', 'height', 'shoulderSpan',
       'bellyDepth', 'hammerSpan', 'gripSeparation', 'armReach',
       'restShoulderToGrip', 'restReachUsed']}))
