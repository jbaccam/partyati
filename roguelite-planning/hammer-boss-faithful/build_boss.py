"""Faithful rebuild of the supplied hammer-zombie reference. Run under Blender 5.2.

Written self-contained on purpose: it does not exec() or import any sibling
generator, so editing a neighbouring kit cannot silently change this one.

Everything is measured off the reference image. The character is 1086 x 1448
pixels tall in that image, spanning y=218 (crown) to y=1285 (sole), which is
1067 px for an authored height of 11.5 studs -- 0.01078 studs per pixel. Every
landmark below was read off the image at that scale, so the silhouette,
grip separation and hammer span are reproductions rather than guesses.

Look direction: the character faces -Y, Z is up, +X is the character's LEFT
(which appears on the viewer's RIGHT in a front render).
"""
import bpy, bmesh, math, json, os, random
import numpy as np
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
# Exposure is tuned by sampling the render against the reference, which needs
# several passes; PROBE_ONLY renders just the comparison frame so each pass is
# about a minute instead of five.
PROBE_ONLY = os.environ.get('PROBE_ONLY') == '1'
(OUT / 'textures').mkdir(exist_ok=True)
(OUT / 'previews').mkdir(exist_ok=True)
random.seed(20260923)

PPS = 0.01078          # studs per reference pixel
HEIGHT = 11.5          # authored crown-to-sole height in studs

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
    for item in list(block):
        if item.users == 0:
            block.remove(item)
scene = bpy.context.scene
parts = {}


def add(section, obj):
    parts.setdefault(section, []).append(obj)
    return obj


def activate(o):
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o


def flatten(o):
    """Flat shading is the whole look: the reference reads as large lit facets."""
    for p in o.data.polygons:
        p.use_smooth = False


# --------------------------------------------------------------- shader helpers
def mixnode(nt):
    """Blender 4/5 split ShaderNodeMix off ShaderNodeMixRGB; support both."""
    try:
        m = nt.nodes.new('ShaderNodeMix')
        m.data_type = 'RGBA'
        m.blend_type = 'MIX'
        fac = [s for s in m.inputs if s.name == 'Factor'][0]
        cols = [s for s in m.inputs if s.name in ('A', 'B') and s.type == 'RGBA']
        res = [s for s in m.outputs if s.type == 'RGBA'][0]
        return m, fac, cols[0], cols[1], res
    except Exception:
        m = nt.nodes.new('ShaderNodeMixRGB')
        return m, m.inputs[0], m.inputs[1], m.inputs[2], m.outputs[0]


def srgb(*c):
    """Reference colours were eyedropped in sRGB; Blender wants scene-linear."""
    def lin(v):
        v = v / 255.0
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    return tuple(lin(v) for v in c)


def emit_material(name):
    """All surfaces bake through EMIT, so the atlas stores pure albedo."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    em = nt.nodes.new('ShaderNodeEmission')
    nt.links.new(em.outputs[0], out.inputs['Surface'])
    return m, nt, em


def worldpos(nt):
    """World position keeps speckle density constant across every body section.

    Generated coordinates normalise per object, which would make the spots on a
    foot the same count as the spots on the belly. Holding the noise scale in
    stud space is the same rule the beach kit uses for studs-per-repeat.
    """
    g = nt.nodes.new('ShaderNodeNewGeometry')
    return g.outputs['Position']


def noise(nt, vec, scale, detail=2.0, rough=0.55, w=0.0):
    n = nt.nodes.new('ShaderNodeTexNoise')
    # 4D so each layer can be offset by W; otherwise every speckle scale would
    # share one field and the spots would stack on top of each other.
    n.noise_dimensions = '4D'
    n.inputs['Scale'].default_value = scale
    n.inputs['Detail'].default_value = detail
    n.inputs['Roughness'].default_value = rough
    n.inputs['W'].default_value = w
    nt.links.new(vec, n.inputs['Vector'])
    return n.outputs['Fac']


def ramp(nt, fac, stops, interp='LINEAR'):
    r = nt.nodes.new('ShaderNodeValToRGB')
    r.color_ramp.interpolation = interp
    while len(r.color_ramp.elements) > 1:
        r.color_ramp.elements.remove(r.color_ramp.elements[-1])
    for i, (pos, col) in enumerate(stops):
        e = r.color_ramp.elements[0] if i == 0 else r.color_ramp.elements.new(pos)
        e.position = pos
        e.color = (*col, 1)
    nt.links.new(fac, r.inputs[0])
    return r.outputs[0]


def blend(nt, fac, a, b):
    m, f, sa, sb, res = mixnode(nt)
    if hasattr(fac, 'node'):
        nt.links.new(fac, f)
    else:
        f.default_value = fac
    if hasattr(a, 'node'):
        nt.links.new(a, sa)
    else:
        sa.default_value = (*a, 1)
    if hasattr(b, 'node'):
        nt.links.new(b, sb)
    else:
        sb.default_value = (*b, 1)
    return res


def warped(nt, pos, amount, scale, w=0.0):
    """Push sample positions around with noise so masks get ragged organic edges."""
    n = nt.nodes.new('ShaderNodeTexNoise')
    n.noise_dimensions = '4D'
    n.inputs['Scale'].default_value = scale
    n.inputs['Detail'].default_value = 2.0
    n.inputs['W'].default_value = w
    nt.links.new(pos, n.inputs['Vector'])
    sc = nt.nodes.new('ShaderNodeVectorMath')
    sc.operation = 'SCALE'
    sc.inputs['Scale'].default_value = amount
    nt.links.new(n.outputs['Color'], sc.inputs[0])
    off = nt.nodes.new('ShaderNodeVectorMath')
    off.operation = 'ADD'
    nt.links.new(pos, off.inputs[0])
    nt.links.new(sc.outputs[0], off.inputs[1])
    return off.outputs[0]


def ragged(nt, pos, radius, seed):
    """Two-octave warp sized as a fraction of the feature it distorts.

    A sphere union only stops reading as circles once the displacement is a
    large share of the blob radius, so amplitude is derived from `radius`
    rather than being a fixed number.
    """
    coarse = warped(nt, pos, radius * 0.85, 1.9, seed)
    return warped(nt, coarse, radius * 0.34, 5.5, seed + 3.7)


def blob_mask(nt, vec, centers):
    """Union of soft spheres. Lets gore sit exactly where the reference puts it
    instead of wherever a noise threshold happens to land."""
    best = None
    for cx, cy, cz, rad in centers:
        sub = nt.nodes.new('ShaderNodeVectorMath')
        sub.operation = 'SUBTRACT'
        nt.links.new(vec, sub.inputs[0])
        sub.inputs[1].default_value = (cx, cy, cz)
        ln = nt.nodes.new('ShaderNodeVectorMath')
        ln.operation = 'LENGTH'
        nt.links.new(sub.outputs['Vector'], ln.inputs[0])
        mr = nt.nodes.new('ShaderNodeMapRange')
        mr.clamp = True
        mr.inputs['From Min'].default_value = rad
        mr.inputs['From Max'].default_value = rad * 0.45
        mr.inputs['To Min'].default_value = 0.0
        mr.inputs['To Max'].default_value = 1.0
        nt.links.new(ln.outputs['Value'], mr.inputs[0])
        if best is None:
            best = mr.outputs[0]
        else:
            mx = nt.nodes.new('ShaderNodeMath')
            mx.operation = 'MAXIMUM'
            nt.links.new(best, mx.inputs[0])
            nt.links.new(mr.outputs[0], mx.inputs[1])
            best = mx.outputs[0]
    return best


# Per-channel gains from the last EXPOSURE_PROBE run (reference linear mean
# divided by render linear mean, per material region). Keeping the correction
# in a table rather than folding it into every constant means the eyedropped
# colours below stay readable and the loop stays re-measurable: rebuild, read
# the printed scales, multiply them in here, rebuild again.
CALIBRATION = {
    'skin':  (0.921, 0.935, 0.953),
    'shirt': (1.219, 1.131, 1.114),
    'stone': (0.749, 0.672, 0.729),
    'wood':  (1.008, 0.902, 1.199),
    'pants': (1.414, 1.122, 1.384),
}


def cal(key, *c):
    """Eyedropped sRGB, converted to linear, with that material's gain applied."""
    gains = CALIBRATION.get(key, (1.0, 1.0, 1.0))
    return tuple(min(1.0, v * g) for v, g in zip(srgb(*c), gains))


# ------------------------------------------------------------------- materials
# Colours eyedropped from the reference and converted out of sRGB.
# Corrected from the belly probe: the render's green channel already matched the
# sheet (x1.03) while red was 22% and blue 53% low, i.e. the skin was too
# saturated rather than too dark. These are the eyedropped values with that
# per-channel correction folded in, so the hue is measured, not guessed.
SKIN_BASE = cal('skin', 171, 211, 99)
SKIN_DEEP = cal('skin', 145, 178, 79)
SPOT_MID = cal('skin', 114, 156, 76)
SPOT_DARK = cal('skin', 62, 92, 53)
GORE_RIM = srgb(112, 30, 28)
GORE_CORE = srgb(178, 48, 38)

# Gore placed by hand at the reference's wound positions (world studs).
WOUNDS = [
    (0.62, -0.95, 11.06, 0.22),   # gash starts at the crown
    (0.80, -0.95, 10.66, 0.24),   # runs down the viewer-right temple
    (0.90, -0.88, 10.26, 0.22),   # past the outer corner of the socket
    (0.84, -1.05, 9.94, 0.17),    # tapers out on the cheek
    (-3.30, -0.70, 8.70, 0.78),   # character's right deltoid
    (-3.75, -0.55, 7.85, 0.62),   # character's right upper arm, outer
    (-3.05, -1.60, 5.55, 0.55),   # character's right forearm
    (3.25, -0.85, 8.80, 0.88),    # character's left deltoid, the largest wound
    (3.60, -0.60, 7.70, 0.60),    # character's left upper arm
    (3.85, -0.90, 6.20, 0.52),    # character's left forearm puncture
    (1.05, -3.05, 5.95, 0.46),    # belly, viewer-right
    (-1.15, -2.95, 7.05, 0.34),   # belly splatter below the shirt hem
    (-1.30, -3.02, 6.60, 0.26),   # and its run-off
    (-1.22, -3.05, 6.20, 0.20),
    (0.55, -3.16, 6.70, 0.24),    # second streak, viewer-right of the navel
    (2.05, -2.35, 7.35, 0.30),    # splash on his left flank
    (-2.95, -1.05, 6.30, 0.34),   # right forearm, upper
]


def skin_material(name):
    m, nt, em = emit_material(name)
    pos = worldpos(nt)
    # Two independent speckle scales: soft mid-green patches with crisp dark
    # dots on top. One scale alone reads as noise, not as rotting skin.
    broad = ramp(nt, noise(nt, pos, 1.6, 3.0, 0.6),
                 [(0.36, SKIN_DEEP), (0.64, SKIN_BASE)])
    # Ramps run dark-to-light so the spot colour is the MINORITY: each layer
    # only fires above its threshold. Reversed, the spot colour floods the body
    # and the base green survives as dots, which is the opposite of the sheet.
    patch_f = noise(nt, warped(nt, pos, 0.16, 6.0, 1.7), 4.6, 2.0, 0.5)
    patch = ramp(nt, patch_f, [(0.575, (0, 0, 0)), (0.650, (1, 1, 1))], 'EASE')
    col = blend(nt, patch, broad, SPOT_MID)
    # Fewer, larger spots. Dense uniform speckle reads as granite; the sheet has
    # scattered irregular blotches with clear skin between them.
    spot_f = noise(nt, warped(nt, pos, 0.09, 14.0, 4.3), 7.6, 2.0, 0.45)
    spot = ramp(nt, spot_f, [(0.630, (0, 0, 0)), (0.685, (1, 1, 1))], 'EASE')
    col = blend(nt, spot, col, SPOT_DARK)
    fine_f = noise(nt, warped(nt, pos, 0.05, 26.0, 8.1), 22.0, 1.5, 0.4)
    fine = ramp(nt, fine_f, [(0.705, (0, 0, 0)), (0.745, (1, 1, 1))], 'EASE')
    col = blend(nt, fine, col, SPOT_DARK)
    # Gore last so nothing speckles over it.
    gore = blob_mask(nt, ragged(nt, pos, 0.62, 11.0), WOUNDS)
    rim = nt.nodes.new('ShaderNodeMapRange')
    rim.clamp = True
    rim.inputs['From Min'].default_value = 0.02
    rim.inputs['From Max'].default_value = 0.34
    nt.links.new(gore, rim.inputs[0])
    col = blend(nt, rim.outputs[0], col, GORE_RIM)
    core = nt.nodes.new('ShaderNodeMapRange')
    core.clamp = True
    core.inputs['From Min'].default_value = 0.36
    core.inputs['From Max'].default_value = 0.62
    nt.links.new(gore, core.inputs[0])
    col = blend(nt, core.outputs[0], col, GORE_CORE)
    nt.links.new(col, em.inputs[0])
    return m


def flat_material(name, color):
    m, nt, em = emit_material(name)
    em.inputs[0].default_value = (*color, 1)
    return m


def cloth_material(name, base, dark, stain, blood_at=(), spotscale=3.4,
                   holes=None):
    m, nt, em = emit_material(name)
    pos = worldpos(nt)
    col = ramp(nt, noise(nt, pos, spotscale, 3.0, 0.6), [(0.32, dark), (0.66, base)])
    grime = ramp(nt, noise(nt, warped(nt, pos, 0.12, 7.0, 2.9), 6.5, 2.0),
                 [(0.560, (0, 0, 0)), (0.665, (1, 1, 1))], 'EASE')
    col = blend(nt, grime, col, stain)
    if holes is not None:
        worn = ramp(nt, noise(nt, warped(nt, pos, 0.22, 4.0, 6.3), 3.1, 3.0, 1.9),
                    [(holes, (0, 0, 0)), (holes + 0.045, (1, 1, 1))], 'EASE')
        col = blend(nt, worn, col, SKIN_DEEP)
    if blood_at:
        gore = blob_mask(nt, ragged(nt, pos, 0.50, 5.0), blood_at)
        mr = nt.nodes.new('ShaderNodeMapRange')
        mr.clamp = True
        mr.inputs['From Min'].default_value = 0.05
        mr.inputs['From Max'].default_value = 0.45
        nt.links.new(gore, mr.inputs[0])
        col = blend(nt, mr.outputs[0], col, GORE_RIM)
    nt.links.new(col, em.inputs[0])
    return m


def stone_material(name, base, dark, blood_at=()):
    m, nt, em = emit_material(name)
    pos = worldpos(nt)
    col = ramp(nt, noise(nt, pos, 5.5, 4.0, 0.62), [(0.30, dark), (0.70, base)])
    grit = ramp(nt, noise(nt, pos, 22.0, 2.0, 0.5),
                [(0.545, (0, 0, 0)), (0.625, (1, 1, 1))], 'EASE')
    col = blend(nt, grit, col, dark)
    nick = ramp(nt, noise(nt, warped(nt, pos, 0.10, 9.0, 3.3), 13.0, 3.0),
                [(0.690, (0, 0, 0)), (0.745, (1, 1, 1))], 'EASE')
    col = blend(nt, nick, col, srgb(30, 27, 30))
    if blood_at:
        gore = blob_mask(nt, ragged(nt, pos, 0.85, 9.0), blood_at)
        mr = nt.nodes.new('ShaderNodeMapRange')
        mr.clamp = True
        mr.inputs['From Min'].default_value = 0.04
        mr.inputs['From Max'].default_value = 0.40
        nt.links.new(gore, mr.inputs[0])
        col = blend(nt, mr.outputs[0], col, srgb(112, 26, 24))
        mr2 = nt.nodes.new('ShaderNodeMapRange')
        mr2.clamp = True
        mr2.inputs['From Min'].default_value = 0.42
        mr2.inputs['From Max'].default_value = 0.70
        nt.links.new(gore, mr2.inputs[0])
        col = blend(nt, mr2.outputs[0], col, srgb(152, 34, 30))
    nt.links.new(col, em.inputs[0])
    return m


def wood_material(name):
    """Object coordinates, not world: the grain must run along the haft, and the
    haft is rotated into the pose rather than modelled in place."""
    m, nt, em = emit_material(name)
    tc = nt.nodes.new('ShaderNodeTexCoord')
    pos = tc.outputs['Object']
    # Squash Y and Z so noise stretches into lengthwise planks along local X.
    sq = nt.nodes.new('ShaderNodeVectorMath')
    sq.operation = 'MULTIPLY'
    sq.inputs[1].default_value = (0.10, 3.0, 3.0)
    nt.links.new(pos, sq.inputs[0])
    col = ramp(nt, noise(nt, sq.outputs[0], 3.0, 4.0, 0.62),
               [(0.30, cal('wood', 121, 70, 47)), (0.55, cal('wood', 163, 102, 66)),
                (0.78, cal('wood', 195, 133, 90))])
    streak = ramp(nt, noise(nt, sq.outputs[0], 9.0, 3.0),
                  [(0.545, (0, 0, 0)), (0.620, (1, 1, 1))], 'EASE')
    col = blend(nt, streak, col, cal('wood', 124, 72, 49))
    nt.links.new(col, em.inputs[0])
    return m


skin = skin_material('Zombie skin - speckled and torn')
shirt = cloth_material('Torn cream shirt', cal('shirt', 213, 194, 169),
                       cal('shirt', 159, 141, 119),
                       cal('shirt', 135, 108, 80),
                       blood_at=[(1.45, -2.60, 8.20, 0.46), (-1.45, -2.60, 7.95, 0.40),
                                 (0.35, -2.70, 7.55, 0.34)], spotscale=5.0)
strap = cloth_material('Leather suspender', srgb(104, 78, 66), srgb(62, 45, 40),
                       srgb(136, 108, 90), spotscale=7.0)
buckle = stone_material('Steel buckle', srgb(196, 196, 198), srgb(138, 138, 144))
# `holes` punches worn-through patches back to skin green, which the sheet
# shows all over the trouser legs.
pants = cloth_material('Ragged navy trousers', cal('pants', 61, 59, 86),
                       cal('pants', 31, 30, 48), cal('pants', 85, 80, 107),
                       spotscale=4.2, holes=0.685)
sash = cloth_material('Dark red waistcloth', srgb(118, 38, 44), srgb(62, 20, 26),
                      srgb(142, 52, 56), spotscale=5.5)
# Hammer iron reads ~RGB(105,100,105) in the reference AFTER lighting, so the
# stored albedo has to sit well above that or the render lands near black.
stone = stone_material('Hammer iron', cal('stone', 85, 76, 85),
                       cal('stone', 54, 47, 54),
                       blood_at=[(-4.35, -3.95, 3.70, 0.95), (-3.75, -3.80, 1.45, 0.85),
                                 (-5.10, -3.70, 1.20, 0.62)])
stone_edge = stone_material('Hammer worn edge', cal('stone', 132, 122, 129),
                            cal('stone', 100, 92, 98))
band = stone_material('Haft ferrule', cal('stone', 75, 64, 74),
                      cal('stone', 47, 40, 47))
wood = wood_material('Hammer haft')
voidmat = flat_material('Socket and mouth void', srgb(16, 20, 16))
eyewhite = flat_material('Eye', srgb(228, 230, 226))
tooth = flat_material('Tooth', srgb(214, 208, 190))
crease = flat_material('Carved crease', srgb(38, 52, 32))


# ------------------------------------------------------------------- primitives
def blob(section, name, center, radii, mat, subdiv=2, jitter=0.035, seed=0):
    """Faceted ellipsoid. The reference's arms and belly are exactly this: a
    low-subdivision icosphere, flat shaded, with enough irregularity that the
    facets do not read as a manufactured ball."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1.0,
                                          location=center)
    o = bpy.context.object
    o.name = name
    rnd = random.Random(seed or hash(name) & 0xffff)
    for v in o.data.vertices:
        v.co = Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]))
        if jitter:
            v.co += Vector([rnd.uniform(-jitter, jitter) * r for r in radii])
    o.data.materials.append(mat)
    flatten(o)
    return add(section, o)


def chamfer_box(section, name, center, size, mat, bevel=0.14, segments=2,
                rot=(0, 0, 0), edge_mat=None, taper=1.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.scale = size
    activate(o)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if taper != 1.0:
        # Narrow the bottom relative to the top. The reference skull is a broad
        # cranium over a smaller jaw, not a plain cube.
        for v in o.data.vertices:
            t = (v.co.z / size[2]) + 0.5           # 0 at the base, 1 at the top
            k = taper + (1.0 - taper) * t
            v.co.x *= k
            v.co.y *= k
    o.data.materials.append(mat)
    if edge_mat is not None:
        o.data.materials.append(edge_mat)
    md = o.modifiers.new('chamfer', 'BEVEL')
    md.width = bevel
    md.segments = segments
    md.limit_method = 'ANGLE'
    md.angle_limit = math.radians(30)
    if edge_mat is not None:
        # Bevel faces get their own slot, which is how the reference's hammer
        # shows bright worn chamfers against dark cast iron.
        for attr in ('material', 'material_index_offset'):
            if hasattr(md, attr):
                setattr(md, attr, 1)
                break
    bpy.ops.object.modifier_apply(modifier=md.name)
    flatten(o)
    return add(section, o)


def limb(section, name, nodes, mat, sides=9, jitter=0.02, seed=1):
    """Faceted tapered tube through a list of (point, radius) nodes."""
    rnd = random.Random(seed)
    verts, faces = [], []
    pts = [Vector(p) for p, _ in nodes]
    for i, (p, r) in enumerate(nodes):
        p = Vector(p)
        nxt = pts[min(i + 1, len(pts) - 1)]
        prv = pts[max(0, i - 1)]
        t = (nxt - prv)
        if t.length < 1e-6:
            t = Vector((0, 0, 1))
        t.normalize()
        helper = Vector((0, 1, 0)) if abs(t.y) < 0.9 else Vector((1, 0, 0))
        a = t.cross(helper).normalized()
        b = t.cross(a).normalized()
        rx, ry = r if isinstance(r, (tuple, list)) else (r, r)
        for k in range(sides):
            ang = k * 2 * math.pi / sides
            q = p + a * (math.cos(ang) * rx) + b * (math.sin(ang) * ry)
            q += Vector([rnd.uniform(-jitter, jitter) * max(rx, ry) for _ in range(3)])
            verts.append(q)
    for i in range(len(nodes) - 1):
        for k in range(sides):
            x = i * sides + k
            y = i * sides + (k + 1) % sides
            faces.append((x, y, y + sides, x + sides))
    faces.append(tuple(reversed(range(sides))))
    faces.append(tuple((len(nodes) - 1) * sides + k for k in range(sides)))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    o = bpy.data.objects.new(name, me)
    scene.collection.objects.link(o)
    o.data.materials.append(mat)
    flatten(o)
    return add(section, o)


def garment(section, name, rings, mat, sides=36, jag=0.0, jag_seed=0,
            thickness=0.085):
    """Lofted shell for the shirt, trousers and waistcloth.

    `rings` are (z, cx, cy, rx, ry) or a callable of theta returning them. The
    final ring can be given a zigzag so the hem tears into triangular teeth --
    the shirt's hem in the reference is sharply serrated, not frayed.
    """
    rnd = random.Random(jag_seed)
    verts, faces = [], []
    for ri, ring in enumerate(rings):
        last = ri == len(rings) - 1
        for k in range(sides):
            th = k * 2 * math.pi / sides
            z, cx, cy, rx, ry = ring(th) if callable(ring) else ring
            x = cx + math.sin(th) * rx
            y = cy - math.cos(th) * ry
            if last and jag:
                z -= jag * (1.0 if k % 2 else 0.18) * rnd.uniform(0.50, 1.40)
            verts.append(Vector((x, y, z)))
    for i in range(len(rings) - 1):
        for k in range(sides):
            a = i * sides + k
            b = i * sides + (k + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    o = bpy.data.objects.new(name, me)
    scene.collection.objects.link(o)
    o.data.materials.append(mat)
    md = o.modifiers.new('cloth thickness', 'SOLIDIFY')
    md.thickness = thickness
    md.offset = 0.0
    activate(o)
    bpy.ops.object.modifier_apply(modifier=md.name)
    flatten(o)
    return add(section, o)


def strip(section, name, nodes, mat, width=0.40, thick=0.11):
    """Flat leather band swept along a path -- the suspenders."""
    verts, faces = [], []
    pts = [Vector(p) for p in nodes]
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(0, i - 1)])
        if t.length < 1e-6:
            t = Vector((0, 0, 1))
        t.normalize()
        side = t.cross(Vector((0, -1, 0)))
        if side.length < 1e-4:
            side = Vector((1, 0, 0))
        side.normalize()
        norm = side.cross(t).normalized()
        for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            verts.append(p + side * (sx * width / 2) + norm * (sy * thick / 2))
    for i in range(len(pts) - 1):
        for k in range(4):
            a = i * 4 + k
            b = i * 4 + (k + 1) % 4
            faces.append((a, b, b + 4, a + 4))
    faces.append((3, 2, 1, 0))
    faces.append(tuple((len(pts) - 1) * 4 + k for k in range(4)))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    o = bpy.data.objects.new(name, me)
    scene.collection.objects.link(o)
    o.data.materials.append(mat)
    flatten(o)
    return add(section, o)


# ------------------------------------------------------------------------ head
HEAD_C = Vector((0, -0.58, 10.56))
HEAD_R = Vector((1.03, 0.96, 1.05))
FACE_Y = HEAD_C.y - HEAD_R.y
FACE_UV = 1.10          # half-extent, in studs, that the face texture covers


def _inside(px, py, poly):
    """Vectorised even-odd point-in-polygon over a whole coordinate grid."""
    res = np.zeros(px.shape, dtype=bool)
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        denom = (yj - yi) if (yj - yi) != 0 else 1e-9
        res ^= ((yi > py) != (yj > py)) & (px < (xj - xi) * (py - yi) / denom + xi)
        j = i
    return res


def _octagon(cx, cz, w, h, tilt):
    pts = []
    for k in range(8):
        a = (k + 0.5) * 2 * math.pi / 8
        x, z = math.cos(a) * w, math.sin(a) * h
        pts.append((cx + x * math.cos(tilt) - z * math.sin(tilt),
                    cz + x * math.sin(tilt) + z * math.cos(tilt)))
    return pts


def _arc_band(v0, half, rise, thick, steps=18):
    """A shallow arc with thickness -- one carved forehead furrow."""
    top, bot = [], []
    for i in range(steps + 1):
        u = -half + 2 * half * i / steps
        v = v0 + rise * math.cos(math.pi * u / (2 * half))
        top.append((u, v + thick / 2))
        bot.append((u, v - thick / 2))
    return top + bot[::-1]


def build_face_image(size=1024, ss=2):
    """Paint the face rather than model it.

    Every geometric attempt at the eyes, mouth and wrinkles read wrong: modelled
    sockets looked like sunglasses and modelled creases looked like tusks. The
    reference's face is flat painted artwork over shallow relief, so this draws
    it as artwork and the shader projects it onto the skull.
    """
    n = size * ss
    axis = np.linspace(-FACE_UV, FACE_UV, n)
    U, V = np.meshgrid(axis, axis)            # row 0 = bottom, Blender's order
    rgba = np.zeros((n, n, 4), dtype=np.float32)

    def paint(poly, color):
        m = _inside(U, V, np.array(poly, dtype=np.float64))
        rgba[m, 0:3] = color
        rgba[m, 3] = 1.0

    VOID = srgb(18, 22, 18)
    LINE = srgb(44, 62, 36)
    WHITE = srgb(232, 234, 230)
    BONE = srgb(216, 210, 192)

    # Landmarks measured off the sheet at 0.01078 studs/px. Head centre sits at
    # x=542, z=10.47 there; each socket runs x 0.12..0.70 out from centre and
    # z +0.14..-0.36, the mouth is 0.88 wide at z -0.50..-0.90, and the furrows
    # sit ON the brow ridge rather than high on the forehead. The first pass put
    # the sockets out to 1.03 and the mouth 0.25 too high, which is why the face
    # read as a wide mask instead of two sunken pits over a grimace.
    for v0, half, rise in ((0.20, 0.50, 0.070), (0.34, 0.40, 0.058)):
        paint(_arc_band(v0, half, rise, 0.020), LINE)

    socket = [(-0.72, -0.02), (-0.66, 0.12), (-0.46, 0.18), (-0.24, 0.14),
              (-0.12, 0.02), (-0.13, -0.16), (-0.26, -0.30), (-0.50, -0.36),
              (-0.68, -0.30), (-0.76, -0.16)]
    paint(socket, VOID)
    paint([(-u, v) for u, v in reversed(socket)], VOID)

    # Eyes: an angular wedge, widest at the outer top and drawn to a point at
    # the inner corner. That asymmetry, not the tilt alone, is the glare.
    eye = [(-0.580, -0.010), (-0.505, 0.100), (-0.320, 0.092), (-0.255, -0.040),
           (-0.345, -0.145), (-0.525, -0.125)]
    paint(eye, WHITE)
    paint([(-u, v) for u, v in reversed(eye)], WHITE)

    # Nasolabial folds run diagonally from beside the nose to the mouth corner,
    # which is what stops them reading as vertical bars.
    fold = [(-0.240, -0.300), (-0.300, -0.320), (-0.520, -0.700), (-0.455, -0.730)]
    paint(fold, LINE)
    paint([(-u, v) for u, v in reversed(fold)], LINE)

    nostril = [(-0.200, -0.255), (-0.068, -0.330), (-0.085, -0.400),
               (-0.228, -0.335)]
    paint(nostril, VOID)
    paint([(-u, v) for u, v in reversed(nostril)], VOID)

    paint([(-0.44, -0.500), (-0.28, -0.460), (-0.10, -0.445), (0.10, -0.445),
           (0.28, -0.460), (0.44, -0.500), (0.40, -0.730), (0.22, -0.820),
           (0.00, -0.845), (-0.22, -0.820), (-0.40, -0.730)], VOID)

    for x, w, top, h in ((-0.260, 0.054, -0.478, 0.100),
                         (-0.088, 0.066, -0.455, 0.132),
                         (0.088, 0.066, -0.455, 0.132),
                         (0.260, 0.054, -0.478, 0.100)):
        paint([(x - w, top), (x + w, top), (x + w, top - h), (x - w, top - h)], BONE)
    for x, w, bot, h in ((-0.240, 0.058, -0.790, 0.092),
                         (0.110, 0.062, -0.812, 0.110)):
        paint([(x - w, bot + h), (x + w, bot + h), (x + w, bot), (x - w, bot)], BONE)

    # Box-downsample the supersampled buffer for clean edges.
    rgba = rgba.reshape(size, ss, size, ss, 4).mean(axis=(1, 3))
    img = bpy.data.images.new('HammerBoss_Face', width=size, height=size, alpha=True)
    img.colorspace_settings.name = 'Non-Color'     # values are already linear
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = str(OUT / 'textures/HammerBoss_Face.png')
    img.file_format = 'PNG'
    img.save()
    img.pack()
    return img


def head_material(face_img):
    """Speckled skin with the painted face composited over the front only."""
    m = skin_material('Zombie head - skin plus painted face')
    nt = m.node_tree
    em = next(nd for nd in nt.nodes if nd.type == 'EMISSION')
    base = em.inputs[0].links[0].from_socket

    geo = nt.nodes.new('ShaderNodeNewGeometry')
    sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    nt.links.new(geo.outputs['Position'], sep.inputs[0])
    du = nt.nodes.new('ShaderNodeMath')
    du.operation = 'MULTIPLY_ADD'
    du.inputs[1].default_value = 1.0 / (2 * FACE_UV)
    du.inputs[2].default_value = 0.5
    nt.links.new(sep.outputs['X'], du.inputs[0])
    dz = nt.nodes.new('ShaderNodeMath')
    dz.operation = 'SUBTRACT'
    dz.inputs[1].default_value = HEAD_C.z
    nt.links.new(sep.outputs['Z'], dz.inputs[0])
    dv = nt.nodes.new('ShaderNodeMath')
    dv.operation = 'MULTIPLY_ADD'
    dv.inputs[1].default_value = 1.0 / (2 * FACE_UV)
    dv.inputs[2].default_value = 0.5
    nt.links.new(dz.outputs[0], dv.inputs[0])
    comb = nt.nodes.new('ShaderNodeCombineXYZ')
    nt.links.new(du.outputs[0], comb.inputs['X'])
    nt.links.new(dv.outputs[0], comb.inputs['Y'])

    tex = nt.nodes.new('ShaderNodeTexImage')
    tex.image = face_img
    tex.extension = 'CLIP'          # nothing outside the painted square
    tex.interpolation = 'Linear'
    nt.links.new(comb.outputs[0], tex.inputs['Vector'])

    # Planar projection would otherwise smear the face down the sides and back
    # of the skull, so gate it on the surface actually facing forward (-Y).
    nsep = nt.nodes.new('ShaderNodeSeparateXYZ')
    nt.links.new(geo.outputs['Normal'], nsep.inputs[0])
    neg = nt.nodes.new('ShaderNodeMath')
    neg.operation = 'MULTIPLY'
    neg.inputs[1].default_value = -1.0
    nt.links.new(nsep.outputs['Y'], neg.inputs[0])
    front = nt.nodes.new('ShaderNodeMapRange')
    front.clamp = True
    front.inputs['From Min'].default_value = 0.10
    front.inputs['From Max'].default_value = 0.42
    nt.links.new(neg.outputs[0], front.inputs[0])
    gate = nt.nodes.new('ShaderNodeMath')
    gate.operation = 'MULTIPLY'
    nt.links.new(tex.outputs['Alpha'], gate.inputs[0])
    nt.links.new(front.outputs[0], gate.inputs[1])

    nt.links.new(blend(nt, gate.outputs[0], base, tex.outputs['Color']),
                 em.inputs[0])
    return m


face_img = build_face_image()
skin_head = head_material(face_img)

chamfer_box('Head', 'Skull', HEAD_C, (HEAD_R.x * 2, HEAD_R.y * 2, HEAD_R.z * 2),
            skin_head, bevel=0.40, segments=3, taper=0.90)
limb('Head', 'Neck', [((0, -0.35, 9.05), 0.88), ((0, -0.48, 9.80), 0.80)],
     skin_head, sides=8)


def face_y(x, zr):
    """Approximate the chamfered skull's front surface so applied relief hugs it
    instead of floating off the cheeks."""
    dx = max(0.0, abs(x) - 0.52) / 0.51
    dz = max(0.0, abs(zr) - 0.54) / 0.51
    return FACE_Y + 0.40 * (dx ** 1.7 + dz ** 1.7)


def face_panel(section, name, pts, mat, proud=0.035, depth=0.55):
    """Extrude a 2D outline (x, z-relative-to-head-centre) into the skull."""
    n = len(pts)
    verts, faces = [], []
    for x, zr in pts:
        verts.append(Vector((x, face_y(x, zr) - proud, HEAD_C.z + zr)))
    for x, zr in pts:
        verts.append(Vector((x, face_y(x, zr) + depth, HEAD_C.z + zr)))
    faces.append(tuple(range(n)))
    faces.append(tuple(reversed(range(n, 2 * n))))
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, j + n, i + n))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    o = bpy.data.objects.new(name, me)
    scene.collection.objects.link(o)
    o.data.materials.append(mat)
    activate(o)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    flatten(o)
    return add(section, o)


# Only shallow relief is modelled now: a brow ridge for the painted sockets to
# sit under, and a low nose bridge. Everything else is in the artwork.
BROW = [(-0.88, 0.34), (-0.50, 0.42), (-0.17, 0.29), (0.0, 0.22), (0.17, 0.29),
        (0.50, 0.42), (0.88, 0.34), (0.88, 0.20), (0.50, 0.27), (0.15, 0.13),
        (-0.15, 0.13), (-0.50, 0.27), (-0.88, 0.20)]
face_panel('Head', 'BrowRidge', BROW, skin_head, proud=0.070, depth=0.32)
chamfer_box('Head', 'NoseBridge', (0, FACE_Y + 0.010, HEAD_C.z - 0.055),
            (0.34, 0.12, 0.34), skin_head, bevel=0.08)

# ----------------------------------------------------------------------- torso
blob('Torso', 'Trapezius', (0, -0.20, 9.18), (2.28, 1.38, 0.98), skin, subdiv=2)
blob('Torso', 'Chest', (0, -0.60, 8.42), (2.56, 1.62, 1.48), skin, subdiv=3)
blob('Torso', 'MidTorso', (0, -1.00, 7.40), (2.28, 1.74, 1.24), skin, subdiv=3)
blob('Torso', 'Belly', (0, -1.50, 6.28), (2.36, 1.98, 1.82), skin, subdiv=3)
blob('Torso', 'Hips', (0, -0.60, 4.72), (1.98, 1.38, 1.18), skin, subdiv=2)
# Navel: the reference makes this a distinct dark pit, not a shading trick.
chamfer_box('Torso', 'Navel', (0.02, -3.40, 5.55), (0.22, 0.30, 0.26),
            voidmat, bevel=0.06)

# Shirt. Hem height varies around the body and is deeper on the character's
# left, then serrates into teeth.
def shirt_top(th):
    # Deep front scoop: the reference shows bare green collarbone above the cloth.
    dip = 0.56 * max(0.0, math.cos(th)) ** 1.3
    return (9.26 - dip, 0.0, -0.38, 2.10, 1.58)


def shirt_mid(th):
    return (8.30, 0.0, -0.72, 2.58, 1.80)


def shirt_low(th):
    return (7.80, 0.0, -0.97, 2.60, 1.96)


def shirt_hem(th):
    z = 7.44 + 0.24 * math.cos(th) - 0.90 * abs(math.sin(th))
    z -= 0.74 * max(0.0, math.sin(th))          # hangs lower on his left
    return (z, 0.0, -1.12, 2.56, 2.04)


garment('Shirt', 'Shirt', [shirt_top, shirt_mid, shirt_low, shirt_hem], shirt,
        sides=64, jag=0.18, jag_seed=4, thickness=0.070)

# Suspenders ride ON the shirt, so their path has to clear the cloth surface --
# the first pass buried them inside the torso and nothing showed.
for sgn, tag in ((-1, 'R'), (1, 'L')):
    strip('Straps', f'Strap{tag}', [
        (sgn * 0.66, -2.48, 5.10), (sgn * 0.92, -3.30, 6.35),
        (sgn * 1.20, -3.18, 7.55), (sgn * 1.44, -2.62, 8.55),
        (sgn * 1.64, -1.86, 9.22), (sgn * 1.72, -0.60, 9.72),
        (sgn * 1.64, 0.62, 9.34), (sgn * 1.30, 1.34, 7.95),
        (sgn * 0.92, 1.22, 6.45),
    ], strap, width=0.48, thick=0.14)
    bx, by, bz = sgn * 1.38, -2.78, 8.46
    for dx, dz, sx, sz in ((0, 0.32, 0.80, 0.16), (0, -0.32, 0.80, 0.16),
                           (-0.32, 0, 0.16, 0.80), (0.32, 0, 0.16, 0.80)):
        chamfer_box('Buckles', f'Buckle{tag}{dx}{dz}',
                    (bx + dx, by, bz + dz), (sx, 0.20, sz), buckle,
                    bevel=0.040, rot=(0, math.radians(sgn * 16), 0))

# ------------------------------------------------------------------------ arms
# Grips read straight off the reference: 5.25 studs apart in screen space, with
# the far end swung back so the true separation lands near 5.4.
GRIP_R = Vector((-1.69, -2.62, 3.86))     # character's right, near the head
GRIP_L = Vector((3.56, -1.50, 4.12))      # character's left, at the butt

# Shoulder span measured off the reference is 8.4 studs at the widest, which is
# the upper arm rather than the deltoid -- so the arm nodes, not the shoulder
# blobs, are what has to be held in.
limb('ArmR', 'UpperArmR', [
    ((-1.92, -0.44, 9.50), 1.18), ((-2.50, -0.52, 8.60), 1.44),
    ((-2.68, -0.76, 7.60), 1.20), ((-2.72, -1.06, 6.60), 1.04),
], skin, sides=9, seed=11)
limb('ArmR', 'ForearmR', [
    ((-2.72, -1.06, 6.60), 1.06), ((-2.62, -1.58, 5.86), 1.44),
    ((-2.34, -2.24, 4.94), 1.42), ((-2.00, -2.70, 4.28), 1.12),
], skin, sides=9, seed=12)
blob('ArmR', 'DeltoidR', (-2.62, -0.46, 8.54), (1.50, 1.52, 1.50), skin, subdiv=2)
blob('ArmR', 'ElbowR', (-2.72, -1.08, 6.58), (1.08, 1.12, 1.04), skin, subdiv=2)

limb('ArmL', 'UpperArmL', [
    ((1.95, -0.44, 9.50), 1.20), ((2.54, -0.54, 8.58), 1.46),
    ((2.80, -0.78, 7.58), 1.22), ((2.96, -0.98, 6.56), 1.06),
], skin, sides=9, seed=21)
limb('ArmL', 'ForearmL', [
    ((2.96, -0.98, 6.56), 1.08), ((3.20, -1.18, 5.78), 1.46),
    ((3.40, -1.42, 4.92), 1.42), ((3.52, -1.56, 4.35), 1.14),
], skin, sides=9, seed=22)
blob('ArmL', 'DeltoidL', (2.66, -0.48, 8.52), (1.52, 1.54, 1.52), skin, subdiv=2)
blob('ArmL', 'ElbowL', (2.96, -1.00, 6.54), (1.10, 1.14, 1.06), skin, subdiv=2)

# ------------------------------------------------------------------------ hammer
# Local space: +X runs along the haft from the head toward the butt. The object
# is rotated into the pose rather than baked in place, so the wood grain node
# can key off Object coordinates.
HEAD_LEN = 3.42          # extent along the haft
HEAD_TALL = 3.96         # perpendicular, in the image plane
HEAD_THICK = 1.94        # toward the camera
HEAD_DROP = -0.80        # haft passes 32% down from the head's top

hx = -0.30 + HEAD_LEN / 2
# A wide two-segment bevel is what gives the octagonal silhouette; one segment
# barely rounded the corners on a block this size.
chamfer_box('HammerHead', 'Head', (hx, 0, HEAD_DROP),
            (HEAD_LEN, HEAD_THICK, HEAD_TALL), stone, bevel=0.62, segments=2,
            edge_mat=stone_edge)
# Raised rim tracing inside the octagon, then the square boss within it.
for face_sgn in (-1, 1):
    y = face_sgn * (HEAD_THICK / 2 + 0.018)
    for ex, ez, sx, sz in ((0, HEAD_TALL / 2 - 0.72, HEAD_LEN - 1.70, 0.14),
                           (0, -HEAD_TALL / 2 + 0.72, HEAD_LEN - 1.70, 0.14),
                           (-HEAD_LEN / 2 + 0.66, 0, 0.14, HEAD_TALL - 1.70),
                           (HEAD_LEN / 2 - 0.66, 0, 0.14, HEAD_TALL - 1.70)):
        chamfer_box('HammerHead', f'Rim{face_sgn}{ex}{ez}',
                    (hx + ex, y, HEAD_DROP + ez), (sx, 0.09, sz), stone_edge,
                    bevel=0.035)
    chamfer_box('HammerHead', f'Boss{face_sgn}', (hx - 0.30, y, HEAD_DROP - 0.34),
                (0.80, 0.20, 0.80), stone, bevel=0.12, edge_mat=stone_edge)
# Single rectangular lug on the outer striking face.
chamfer_box('HammerHead', 'Lug', (-0.30 - 0.26, 0, HEAD_DROP + 0.28),
            (0.62, 1.00, 1.62), stone, bevel=0.13, edge_mat=stone_edge)

HAFT_R = 0.375
limb('HammerShaft', 'Haft', [((0.35, 0, 0), HAFT_R), ((10.85, 0, 0), HAFT_R)],
     wood, sides=8, jitter=0.0)
chamfer_box('HammerShaft', 'HaftCap', (10.88, 0, 0), (0.22, 0.86, 0.86), wood,
            bevel=0.10)
# Six ferrules on the butt half, as counted in the reference.
for i in range(6):
    bx = 6.05 + i * 0.86
    limb('HammerBands', f'Ferrule{i}',
         [((bx, 0, 0), HAFT_R + 0.075), ((bx + 0.46, 0, 0), HAFT_R + 0.075)],
         band, sides=8, jitter=0.0)

# ------------------------------------------------------------------------ fists
# The reference grips the haft with a chunky mitt: one big knuckle mass above
# the haft, four finger bars curling underneath, thumb laid over the top.
def fist(section, tag, local_x, flip):
    bpy.ops.object.select_all(action='DESELECT')
    chamfer_box(section, f'Palm{tag}', (local_x, -0.10, 0.34),
                (1.72, 1.70, 1.42), skin, bevel=0.34, segments=2)
    for i in range(4):
        fx = local_x - 0.62 + i * 0.415
        chamfer_box(section, f'Finger{tag}{i}', (fx, -0.30, -0.52),
                    (0.375, 1.42, 0.96), skin, bevel=0.20, segments=2)
    chamfer_box(section, f'Thumb{tag}', (local_x + flip * 0.80, -0.44, 0.44),
                (0.72, 0.92, 0.62), skin, bevel=0.22, segments=2,
                rot=(0, 0, math.radians(flip * 14)))


GRIP_LOCAL_R = 4.00      # near the head
GRIP_LOCAL_L = 9.45      # at the butt
fist('HandR', 'R', GRIP_LOCAL_R, 1)
fist('HandL', 'L', GRIP_LOCAL_L, -1)

# --------------------------------------------------------- pose the whole weapon
# Solve the placement from the two measured grip points so the hands cannot
# drift off the haft: the haft axis is simply the line between the grips.
axis = (GRIP_L - GRIP_R)
span_local = GRIP_LOCAL_L - GRIP_LOCAL_R
scale_fix = axis.length / span_local
origin = GRIP_R - axis.normalized() * (GRIP_LOCAL_R * scale_fix)
rot_z = math.atan2(axis.y, axis.x)
rot_y = -math.asin(max(-1.0, min(1.0, axis.normalized().z)))
HAMMER_SECTIONS = ('HammerHead', 'HammerShaft', 'HammerBands', 'HandR', 'HandL')
for sect in HAMMER_SECTIONS:
    for o in parts[sect]:
        # Bake each piece's layout along the haft into its mesh first, otherwise
        # setting a shared location below would collapse them all onto one point.
        activate(o)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        o.rotation_mode = 'XYZ'
        # X is the haft axis, so this roll turns the head without moving either
        # grip -- it just shows a sliver of the top face, as the reference does.
        o.rotation_euler = (math.radians(-21), rot_y, rot_z)
        o.location = origin
        o.scale = (scale_fix, scale_fix, scale_fix)

# ------------------------------------------------------------------------- legs
for sgn, tag in ((-1, 'R'), (1, 'L')):
    hip = Vector((sgn * 1.22, -0.42, 4.60))
    knee = Vector((sgn * 1.44, -0.34, 2.32))
    ankle = Vector((sgn * 1.52, -0.18, 0.74))
    limb('Legs', f'Thigh{tag}', [(hip, 1.20), ((hip + knee) / 2, 1.04),
                                 (knee, 0.94)], skin, sides=9, seed=30 + sgn)
    limb('Legs', f'Shin{tag}', [(knee, 0.90), ((knee + ankle) / 2, 0.80),
                                (ankle, 0.72)], skin, sides=9, seed=40 + sgn)
    blob('Legs', f'Knee{tag}', knee, (0.94, 0.94, 0.86), skin, subdiv=2)
    toe_out = math.radians(32 if sgn > 0 else -12)
    chamfer_box('Legs', f'Foot{tag}', (ankle.x + sgn * 0.10, ankle.y - 0.86, 0.36),
                (1.78, 2.72, 0.72), skin, bevel=0.18, rot=(0, 0, toe_out))

    # Trousers: a torn outer flap over a longer inner leg, both serrated. Finer
    # and shallower teeth than the first pass, which read as a sawtooth crown.
    hem_z = 1.55 if sgn > 0 else 1.28
    garment('Pants', f'Leg{tag}', [
        (5.02, hip.x, hip.y, 1.54, 1.50),
        (3.70, hip.x * 1.06, -0.40, 1.44, 1.44),
        (2.50, knee.x, knee.y, 1.28, 1.30),
        (hem_z, knee.x * 1.06, knee.y, 1.20, 1.22),
    ], pants, sides=44, jag=0.24, jag_seed=7 + sgn, thickness=0.085)
    garment('Pants', f'Flap{tag}', [
        (3.85, hip.x * 1.03, -0.42, 1.50, 1.48),
        (2.78, knee.x * 1.00, -0.38, 1.40, 1.40),
    ], pants, sides=44, jag=0.28, jag_seed=17 + sgn, thickness=0.075)

garment('Pants', 'Seat', [
    (5.24, 0, -0.52, 2.02, 1.44),
    (4.60, 0, -0.50, 2.12, 1.48),
    (4.05, 0, -0.46, 2.06, 1.44),
], pants, sides=34, jag=0.0, thickness=0.10)

# Dark red waistcloth under the belly, hanging lower on his left.
def sash_ring(z, r):
    def f(th):
        return (z - 0.30 * max(0.0, math.sin(th)), 0.0, -0.62, r, r * 0.76)
    return f


garment('Sash', 'Waistcloth', [sash_ring(5.30, 2.10), sash_ring(4.55, 2.20),
                               sash_ring(3.75, 2.14)], sash,
        sides=34, jag=0.30, jag_seed=9, thickness=0.09)

# ---------------------------------------------- join, unwrap and bake the atlas
objects = {}
order = list(parts.keys())
GRID = 5
for idx, name in enumerate(order):
    items = parts[name]
    bpy.ops.object.select_all(action='DESELECT')
    for o in items:
        o.select_set(True)
    bpy.context.view_layer.objects.active = items[0]
    if len(items) > 1:
        bpy.ops.object.join()
    o = bpy.context.object
    o.name = name
    # Hammer sections keep their rotation so Object coordinates still run along
    # the haft for the wood grain; everything else is flattened to world space.
    bpy.ops.object.transform_apply(location=name not in HAMMER_SECTIONS,
                                   rotation=name not in HAMMER_SECTIONS,
                                   scale=True)
    activate(o)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')
    cell = 1.0 / GRID
    cx, cy = idx % GRID, idx // GRID
    for uv in o.data.uv_layers.active.data:
        uv.uv = ((uv.uv.x * 0.94 + 0.03 + cx) * cell,
                 (uv.uv.y * 0.94 + 0.03 + cy) * cell)
    objects[name] = o

ATLAS = 4096
atlas = bpy.data.images.new('HammerBoss_Color', width=ATLAS, height=ATLAS, alpha=False)
all_mats = [skin, skin_head, shirt, strap, buckle, pants, sash, stone, stone_edge, band,
            wood, voidmat, eyewhite, tooth, crease]
for m in all_mats:
    nd = m.node_tree.nodes.new('ShaderNodeTexImage')
    nd.image = atlas
    m.node_tree.nodes.active = nd

scene.render.engine = 'CYCLES'
scene.cycles.samples = 1
scene.render.bake.margin = 8
scene.render.bake.use_clear = False
scene.view_settings.view_transform = 'Standard'
for o in objects.values():
    activate(o)
    bpy.ops.object.bake(type='EMIT')
atlas.filepath_raw = str(OUT / 'textures/HammerBoss_Color.png')
atlas.file_format = 'PNG'
atlas.save()
atlas.pack()

painted = bpy.data.materials.new('HammerBoss painted atlas')
painted.use_nodes = True
bs = painted.node_tree.nodes.get('Principled BSDF')
bs.inputs['Roughness'].default_value = 0.92
if 'Specular IOR Level' in bs.inputs:
    bs.inputs['Specular IOR Level'].default_value = 0.18
tex = painted.node_tree.nodes.new('ShaderNodeTexImage')
tex.image = atlas
painted.node_tree.links.new(tex.outputs['Color'], bs.inputs['Base Color'])
for o in objects.values():
    o.data.materials.clear()
    o.data.materials.append(painted)
    for p in o.data.polygons:
        p.material_index = 0

# ------------------------------------------------------------------ measurements
allv = [(o.matrix_world @ v.co) for o in objects.values() for v in o.data.vertices]
body = [(objects[n].matrix_world @ v.co) for n in objects
        if not n.startswith('Hammer') and n not in ('HandR', 'HandL')
        for v in objects[n].data.vertices]
stats = {
    'sections': len(objects),
    'triangles': sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
                     for o in objects.values()),
    'vertices': sum(len(o.data.vertices) for o in objects.values()),
    'height': round(max(v.z for v in body) - min(v.z for v in body), 3),
    'shoulderSpan': round(max(v.x for v in body) - min(v.x for v in body), 3),
    'bellyDepth': round(-min(v.y for v in body), 3),
    'headWidth': round(2 * HEAD_R.x, 3),
    'hammerSpan': round(max(v.x for v in allv) - min(v.x for v in allv), 3),
    'gripSeparation': round((GRIP_L - GRIP_R).length, 3),
    'hammerHeadSize': [HEAD_LEN, HEAD_THICK, HEAD_TALL],
    'haftRadius': HAFT_R,
    'ferrules': 6,
    'atlas': ATLAS,
    'front': 'Blender -Y',
    'studsPerReferencePixel': PPS,
}
(OUT / 'manifest.json').write_text(json.dumps(stats, indent=2))

# --------------------------------------------------------------------- previews
def aim(o, target):
    o.rotation_euler = (Vector(target) - o.location).to_track_quat('-Z', 'Y').to_euler()


ground = bpy.data.materials.new('Preview ground')
ground.use_nodes = True
gb = ground.node_tree.nodes.get('Principled BSDF')
gb.inputs['Base Color'].default_value = (*srgb(120, 200, 58), 1)
gb.inputs['Roughness'].default_value = 0.95
bpy.ops.mesh.primitive_plane_add(size=400, location=(0, 0, 0))
floor = bpy.context.object
floor.name = 'PreviewGround'
floor.data.materials.append(ground)

world = scene.world or bpy.data.worlds.new('World')
scene.world = world
world.use_nodes = True
wnt = world.node_tree
wnt.nodes.clear()
wout = wnt.nodes.new('ShaderNodeOutputWorld')
wmix = wnt.nodes.new('ShaderNodeMixShader')
bg = wnt.nodes.new('ShaderNodeBackground')        # what the camera sees
bg_amb = wnt.nodes.new('ShaderNodeBackground')    # what actually lights the model
lightpath = wnt.nodes.new('ShaderNodeLightPath')
wnt.links.new(lightpath.outputs['Is Camera Ray'], wmix.inputs[0])
wnt.links.new(bg_amb.outputs[0], wmix.inputs[1])
wnt.links.new(bg.outputs[0], wmix.inputs[2])
wnt.links.new(wmix.outputs[0], wout.inputs['Surface'])
# Splitting the two lets the backdrop stay a bright sky while ambient fill is
# dialled independently -- otherwise brightening the sky also blows out the model.
bg.inputs[0].default_value = (*srgb(122, 186, 232), 1)
bg.inputs[1].default_value = 1.0
bg_amb.inputs[0].default_value = (*srgb(150, 180, 205), 1)
bg_amb.inputs[1].default_value = 0.30

bpy.ops.object.camera_add(location=(0, -21.5, 6.8))
cam = bpy.context.object
scene.camera = cam
cam.data.lens = 50

for loc, power, size in (((-11, -16, 19), 3300, 11), ((10, -9, 12), 960, 8),
                         ((3, 13, 15), 1080, 9)):
    bpy.ops.object.light_add(type='AREA', location=loc)
    lt = bpy.context.object
    lt.data.energy = power
    lt.data.shape = 'DISK'
    lt.data.size = size
    aim(lt, (0, -1.0, 6.0))

scene.cycles.samples = 18 if PROBE_ONLY else 64
scene.cycles.use_denoising = True
scene.render.image_settings.file_format = 'PNG'
if not PROBE_ONLY:
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'HammerBoss.blend'))

# Reference-match render: same framing and aspect as the supplied image so the
# two can be laid side by side without rescaling.
#
# Framing is solved, not eyeballed. In the sheet the figure occupies 73.7% of
# frame height, so the visible height is 11.5 / 0.737 = 15.6 studs. For a 36mm
# sensor that fixes distance as D = 15.6 * lens / 36. An 85mm lens puts the
# camera 36.8 studs back; the 50mm first attempt sat at 21 studs and its
# perspective blew the hammer head up to twice its size in the sheet.
scene.render.resolution_x, scene.render.resolution_y = 1086, 1448
cam.data.lens = 85
# The figure plus its hammer is centred near x = -0.9, not on the body axis.
cam.location = (-0.85, -36.8, 7.20)
aim(cam, (-0.85, 0, 5.90))
scene.render.filepath = str(OUT / 'previews/Reference_Match.png')
bpy.ops.render.render(write_still=True)

# Exposure probe. Single pixels were unreliable -- the rebuild's limbs do not
# land on exactly the same coordinates as the sheet's, so a fixed coordinate can
# sample belly in one image and background in the other. Comparing the mean of
# every skin-coloured pixel is robust to that and gives a direct scale factor.
REF_IMAGE = Path(r'..') / 'hammer-boss' / 'source' / 'boss-reference.png'

# Each entry is a box (as fractions of the frame, which line up because the
# render reproduces the sheet's framing) plus a colour rule that picks the
# material out of whatever else shares that box.
REGIONS = {
    'skin':   ((0.39, 0.42, 0.68, 0.53),
               lambda r, g, b: (g > r * 1.12) & (g > b * 1.6) & (g > 0.04)),
    'shirt':  ((0.40, 0.28, 0.62, 0.40),
               lambda r, g, b: (r > g) & (g > b) & (r - b > 0.02) & (r > 0.22)),
    'stone':  ((0.02, 0.58, 0.32, 0.86),
               lambda r, g, b: (abs(r - b) < 0.05) & (abs(r - g) < 0.05) & (g > 0.01)),
    'wood':   ((0.42, 0.57, 0.66, 0.67),
               lambda r, g, b: (r > g * 1.22) & (g > b * 1.10) & (r > 0.04)),
    'pants':  ((0.38, 0.70, 0.72, 0.80),
               lambda r, g, b: (b > r * 1.04) & (b > g * 1.01) & (b < 0.22)),
}


def load_rgb(path):
    img = bpy.data.images.load(str(path))
    w, h = img.size
    buf = np.empty(len(img.pixels), dtype=np.float32)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    return buf.reshape(h, w, 4)[:, :, :3][::-1]      # Blender stores bottom-up


def region_stats(rgb, spec):
    (x0, y0, x1, y1), rule = spec
    h, w = rgb.shape[:2]
    box = rgb[int(y0 * h):int(y1 * h), int(x0 * w):int(x1 * w)].reshape(-1, 3)
    m = rule(box[:, 0], box[:, 1], box[:, 2])
    if m.sum() < 300:
        return None
    sel = box[m]
    return {'pixels': int(m.sum()),
            'linear': [round(float(v), 5) for v in sel.mean(axis=0)],
            'srgb': [round(float(min(1.0, v) ** (1 / 2.2) * 255))
                     for v in sel.mean(axis=0)]}


render_rgb = load_rgb(OUT / 'previews/Reference_Match.png')
ref_rgb = load_rgb((OUT / REF_IMAGE).resolve())
report = {}
for key, spec in REGIONS.items():
    a = region_stats(render_rgb, spec)
    b = region_stats(ref_rgb, spec)
    entry = {'render': a, 'reference': b}
    if a and b:
        entry['scale'] = [round(b['linear'][i] / max(1e-6, a['linear'][i]), 3)
                          for i in range(3)]
    report[key] = entry
print('EXPOSURE_PROBE', json.dumps(report))
if PROBE_ONLY:
    print('FAITHFUL_BOSS_COMPLETE', json.dumps(stats))
    raise SystemExit(0)

# Technical turnaround on a neutral backdrop.
gb.inputs['Base Color'].default_value = (*srgb(58, 62, 70), 1)
bg.inputs[0].default_value = (*srgb(48, 52, 60), 1)
scene.render.resolution_x, scene.render.resolution_y = 840, 1080
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 15.5
for tag, loc in (('Front', (0, -30, 6.0)), ('ThreeQuarter', (20, -24, 9.0)),
                 ('Side', (30, 0, 6.0)), ('Back', (0, 30, 6.0))):
    cam.location = loc
    aim(cam, (0, -0.6, 5.4))
    scene.render.filepath = str(OUT / f'previews/{tag}.png')
    bpy.ops.render.render(write_still=True)

# Close-ups on the two things the reference was judged on.
cam.data.type = 'PERSP'
cam.data.lens = 85
scene.render.resolution_x, scene.render.resolution_y = 1000, 1000
for tag, loc, target in (
        ('Detail_Face', (0.4, -7.0, 11.4), (0, -1.5, 10.30)),
        ('Detail_GripNear', (-3.2, -9.0, 5.2), (-1.7, -3.0, 3.85)),
        ('Detail_GripFar', (5.0, -8.0, 5.6), (3.5, -1.7, 4.05)),
        ('Detail_HammerHead', (-6.6, -9.5, 3.4), (-4.2, -1.4, 2.40))):
    cam.location = loc
    aim(cam, target)
    scene.render.filepath = str(OUT / f'previews/{tag}.png')
    bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'HammerBoss.blend'))
print('FAITHFUL_BOSS_COMPLETE', json.dumps(stats))
