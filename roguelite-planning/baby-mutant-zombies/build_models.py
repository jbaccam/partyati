"""Original meshes for the approved baby/mutant concept. Dedicated background Blender only."""
import bpy, bmesh, math, json, random, sys
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
KIND = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else 'Baby'
assert KIND in ('Baby', 'Mutant')
DEST = OUT / KIND
DEST.mkdir(exist_ok=True)
random.seed(138 if KIND == 'Baby' else 257)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
parts = {}
joints = {}
texture = bpy.data.images.load(str(OUT / 'source-art' / (KIND + 'Texture.png')))
texture.pack()
material = bpy.data.materials.new(KIND + ' original painted atlas')
material.use_nodes = True
bs = material.node_tree.nodes.get('Principled BSDF')
bs.inputs['Roughness'].default_value = .91
bs.inputs['Specular IOR Level'].default_value = .15
tex = material.node_tree.nodes.new('ShaderNodeTexImage')
tex.image = texture
material.node_tree.links.new(tex.outputs['Color'], bs.inputs['Base Color'])

def register(name, parent, head, tail):
    joints[name] = dict(parent=parent, head=list(head), tail=list(tail))

def uv_map(o, tile, face=False):
    """Box project into padded atlas tiles; full frontal head projects into its unique face."""
    while o.data.uv_layers:
        o.data.uv_layers.remove(o.data.uv_layers[0])
    uv = o.data.uv_layers.new(name='PaintedAtlas')
    co = [v.co for v in o.data.vertices]
    lo = [min(v[i] for v in co) for i in range(3)]
    hi = [max(v[i] for v in co) for i in range(3)]
    span = [max(hi[i]-lo[i], .00001) for i in range(3)]
    for p in o.data.polygons:
        normal = p.normal
        front = face and normal.y < -.22
        chosen = 1 if front else tile
        tx, ty = chosen % 2, 1-chosen//2
        axis = max(range(3), key=lambda i: abs(normal[i]))
        for li in p.loop_indices:
            v = o.data.vertices[o.data.loops[li].vertex_index].co
            if front or axis == 1:
                u, w = (v.x-lo[0])/span[0], (v.z-lo[2])/span[2]
            elif axis == 0:
                u, w = (v.y-lo[1])/span[1], (v.z-lo[2])/span[2]
            else:
                u, w = (v.x-lo[0])/span[0], (v.y-lo[1])/span[1]
            # Keep front features upright and use material variation on the other surfaces.
            uv.data[li].uv = ((tx+.016+.968*u)/2, (ty+.016+.968*w)/2)

def finish(o, part, label, tile, bevel=0, face=False):
    o.name = label
    if bevel:
        bpy.context.view_layer.objects.active = o
        mod = o.modifiers.new('Soft faceted corners', 'BEVEL')
        mod.width = bevel
        mod.segments = 3 if face else 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # Recalculate before choosing UV projection axes.
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(o.data); bm.free(); o.data.update()
    uv_map(o, tile, face)
    o.data.materials.append(material)
    parts.setdefault(part, []).append(o)
    return o

def box(part, label, loc, dims, tile=0, bevel=.05, face=False):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object; o.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, part, label, tile, bevel, face)

def mesh(part, label, verts, faces, tile=0, bevel=0):
    me = bpy.data.meshes.new(label); me.from_pydata(verts, [], faces); me.update()
    o = bpy.data.objects.new(label, me); scene.collection.objects.link(o)
    return finish(o, part, label, tile, bevel)

def profile(w, d, corner=.24):
    # Twelve points retain large flat planes with softened broad corners.
    r = min(w, d)*corner
    points=[]
    for cx, cy, start in [(w/2-r,d/2-r,0),(-w/2+r,d/2-r,90),
                          (-w/2+r,-d/2+r,180),(w/2-r,-d/2+r,270)]:
        for t in (0,45,90):
            a=math.radians(start+t)
            points.append((cx+r*math.cos(a),cy+r*math.sin(a)))
    return points

def loft(part, label, levels, tile=0, corner=.24):
    # Each level is (z, x-center, y-center, width, depth).
    verts=[]
    for z,x,y,w,d in levels:
        verts.extend((x+px,y+py,z) for px,py in profile(w,d,corner))
    n=12; faces=[tuple(range(n-1,-1,-1))]
    for j in range(len(levels)-1):
        for i in range(n):
            faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    faces.append(tuple(range((len(levels)-1)*n,len(levels)*n)))
    return mesh(part,label,verts,faces,tile)

def panel(part,label,coords,y,thickness,tile,bevel=.012):
    # coords may supply individual Y depths, allowing fabric to follow a hunched torso.
    front=[(p[0],p[2] if len(p)>2 else y,p[1]) for p in coords]
    verts=front+[(x,yy+thickness,z) for x,yy,z in front]; n=len(coords)
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(part,label,verts,faces,tile,bevel)

def strap(part,label,a,b,width,depth,tile):
    a,b=Vector(a),Vector(b)
    o=box(part,label,(a+b)/2,(width,depth,(b-a).length),tile,.018)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return o

def button(part,loc,radius):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10,ring_count=5,radius=1,location=loc)
    o=bpy.context.object; o.scale=(radius,.028,radius)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,part,'Old ochre button',2)

def torn_cuff(part,label,x,z,w,d,tile,depth=.25,y=0):
    top=profile(w,d); n=len(top)
    verts=[(x+a,y+b,z) for a,b in top]
    verts += [(x+a,y+b,z-depth-(.07 if i%3==0 else -.035 if i%3==1 else .01)) for i,(a,b) in enumerate(top)]
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(part,label,verts,faces,tile)

def vest_wrap(levels):
    verts=[]
    for j,(z,x,y,w,d) in enumerate(levels):
        ring=profile(w,d,.27)
        for k,i in enumerate([11,0,1,2,3,4,5,6]):
            px,py=ring[i]
            zz=z+(.08 if k%2 else -.08) if j==0 else z
            verts.append((x+px,y+py,zz))
    faces=[]
    for j in range(len(levels)-1):
        for i in range(7):faces.append((j*8+i,j*8+i+1,(j+1)*8+i+1,(j+1)*8+i))
    o=mesh('UpperTorso','Continuous vest back and sides',verts,faces,2)
    bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('Fabric thickness and closed hems','SOLIDIFY');mod.thickness=.065
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return o

def fitted_shirt_front(label,coords):
    # Subdivide a planar cloth panel before bending it over the torso. A single
    # non-planar n-gon can triangulate through the chest even if its boundary clears it.
    me=bpy.data.meshes.new(label)
    me.from_pydata([(p[0],0,p[1]) for p in coords],[],[tuple(range(len(coords)))])
    me.update();bm=bmesh.new();bm.from_mesh(me)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=3,use_grid_fill=True)
    silhouette=[(3.75,-.465),(3.88,-.465),(4.38,-.545),(5.27,-.70),
                (6.15,-.785),(6.78,-.66),(7.10,-.455),(7.3,-.455)]
    for v in bm.verts:
        z=v.co.z
        for (za,ya),(zb,yb) in zip(silhouette,silhouette[1:]):
            if za<=z<=zb:
                v.co.y=ya+(yb-ya)*(z-za)/(zb-za)-.16
                break
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(me);bm.free();me.update()
    o=bpy.data.objects.new(label,me);scene.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('Closed shirt fabric','SOLIDIFY');mod.thickness=.065;mod.offset=0
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,'UpperTorso',label,2)

if KIND == 'Baby':
    root_z=1.24
    register('LowerTorso','HumanoidRootPart',(0,0,1.24),(0,0,1.51))
    register('UpperTorso','LowerTorso',(0,0,1.51),(0,0,2.20))
    register('Head','UpperTorso',(0,0,2.19),(0,-.03,3.45))
    loft('LowerTorso','Suspender shorts waistband',[(1.16,0,0,.87,.58),(1.36,0,0,.97,.64),(1.53,0,0,.95,.62)],3)
    loft('UpperTorso','Little ochre shirt',[(1.47,0,0,.94,.61),(1.77,0,0,1.00,.69),(2.08,0,0,.98,.62),(2.20,0,0,.76,.56)],2)
    box('Head','Short green neck',(0,0,2.23),(.45,.44,.24),0,.06)
    head=box('Head','Rounded classic head with original painted face',(0,-.025,2.86),(1.32,1.03,1.30),0,.25,True)
    # Neck opening and fabric tears are original geometry, not copied clothing images.
    panel('UpperTorso','Open torn shirt collar',[(-.25,2.22),(.25,2.22),(.15,2.04),(.04,1.99),(-.14,2.07)],-.325,.045,0)
    panel('UpperTorso','Small shirt tear',[(-.10,1.94),(.02,1.90),(-.02,1.80),(-.08,1.73),(-.16,1.84)],-.359,.02,0)
    for s in [-1,1]:
        strap('UpperTorso','Front suspender',(s*.33,-.348,1.47),(s*.36,-.32,2.17),.12,.054,3)
        strap('UpperTorso','Back suspender',(s*.31,.345,1.49),(s*.36,.31,2.15),.12,.047,3)
        strap('UpperTorso','Over shoulder suspender',(s*.36,-.30,2.18),(s*.36,.30,2.18),.12,.054,3)
        button('LowerTorso',(s*.32,-.344,1.42),.058)
    for side,s in [('Left',1),('Right',-1)]:
        x=s*.72
        register(side+'UpperArm','UpperTorso',(x,0,2.06),(x,0,1.68))
        register(side+'LowerArm',side+'UpperArm',(x,0,1.68),(x,0,1.35))
        register(side+'Hand',side+'LowerArm',(x,0,1.35),(x,0,1.12))
        loft(side+'UpperArm','Little upper arm',[(1.65,x,0,.38,.42),(1.93,x,0,.46,.46),(2.10,x,0,.43,.42)],0)
        torn_cuff(side+'UpperArm','Torn ochre sleeve',x,2.12,.50,.49,2,.19)
        loft(side+'LowerArm','Little forearm',[(1.32,x,0,.34,.36),(1.48,x,0,.39,.42),(1.69,x,0,.37,.40)],0)
        box(side+'Hand','Chunky little hand',(x,-.02,1.20),(.40,.42,.31),0,.065)
        lx=s*.26
        register(side+'UpperLeg','LowerTorso',(lx,0,1.26),(lx,0,.80))
        register(side+'LowerLeg',side+'UpperLeg',(lx,0,.80),(lx,0,.29))
        register(side+'Foot',side+'LowerLeg',(lx,0,.29),(lx,-.30,.13))
        loft(side+'UpperLeg','Shorts leg',[(.82,lx,0,.42,.50),(1.10,lx,0,.45,.53),(1.28,lx,0,.43,.53)],3)
        torn_cuff(side+'UpperLeg','Frayed shorts hem',lx,1.00,.47,.55,3,.16)
        loft(side+'LowerLeg','Bare little shin',[(.22,lx,0,.34,.38),(.46,lx,0,.36,.39),(.75,lx,0,.41,.45),(.84,lx,0,.39,.42)],0)
        box(side+'Foot','Bare rounded foot',(lx,-.15,.17),(.45,.69,.34),0,.085)
else:
    root_z=3.15
    register('LowerTorso','HumanoidRootPart',(0,.16,3.15),(0,.18,4.02))
    register('UpperTorso','LowerTorso',(0,.18,4.02),(0,.05,6.76))
    register('Head','UpperTorso',(0,-.55,6.73),(0,-.72,8.28))
    loft('LowerTorso','Heavy trouser waist',[(2.94,0,.12,2.0,1.10),(3.35,0,.16,2.23,1.25),(3.85,0,.15,2.13,1.24),(4.04,0,.15,1.90,1.14)],3)
    # A single continuous garment surface replaces the separate shoulder cap,
    # front patches and back wrap. Shrinking upper rings round over the trapezius
    # into a neckline hidden beneath the thick neck, with no exposed flat shelf.
    torso=loft('UpperTorso','Continuous rounded full shirt',[
        (3.88,0,.12,2.07,1.29),(4.38,0,.12,2.31,1.45),
        (5.27,0,.10,3.02,1.72),(6.15,0,.17,3.55,2.03),
        (6.55,0,.22,3.54,2.03),(6.79,0,.22,3.34,1.93),
        (6.98,0,.16,2.95,1.76),(7.13,0,.02,2.34,1.48),
        (7.21,0,-.18,1.60,1.20),(7.23,0,-.40,1.02,.94)],2,.31)
    for i in range(12):torso.data.vertices[i].co.z += [-.09,.04,-.04,.02][i%4]
    # Smooth normals across the curved cloth, preserving the broad bulky shape.
    for poly in torso.data.polygons:poly.use_smooth=True
    box('Head','Thick neck',(0,-.47,6.82),(1.05,1.02,.60),0,.18)
    box('Head','Rounded mutant head with unique scowl',(0,-.67,7.56),(1.79,1.48,1.83),0,.37,True)
    for side,s in [('Left',1),('Right',-1)]:
        x=s*2.12
        register(side+'UpperArm','UpperTorso',(x,.10,6.65),(s*2.43,-.02,4.70))
        register(side+'LowerArm',side+'UpperArm',(s*2.43,-.02,4.70),(s*2.66,-.20,2.64))
        register(side+'Hand',side+'LowerArm',(s*2.66,-.20,2.64),(s*2.66,-.34,1.52))
        loft(side+'UpperArm','Massive tapered shoulder and biceps',[(4.64,s*2.43,-.02,1.06,1.15),(5.12,s*2.39,.02,1.36,1.47),(5.85,s*2.25,.10,1.73,1.67),(6.48,s*2.08,.16,1.85,1.79),(6.89,s*1.96,.20,1.39,1.45),(7.02,s*1.93,.20,.99,1.04)],0,.31)
        # Fully wrapped sleeves: front, back, outer shoulder and underside all carry fabric.
        sleeve=loft(side+'UpperArm','Complete torn shirt sleeve',[
            (5.69,s*2.29,.085,1.78,1.79),(5.85,s*2.25,.10,1.87,1.81),
            (6.48,s*2.08,.16,1.99,1.93),(6.89,s*1.96,.20,1.53,1.59),
            (7.02,s*1.93,.20,1.11,1.18),
            (7.13,s*1.91,.20,.66,.74),
            (7.17,s*1.90,.20,.20,.24)],2,.31)
        for poly in sleeve.data.polygons:poly.use_smooth=True
        # Uneven hem is geometry and closes beneath the arm too.
        for i in range(12):sleeve.data.vertices[i].co.z += [-.13,.06,-.05,.02][i%4]
        sleeve.data.update()
        loft(side+'LowerArm','Long heavy faceted forearm',[(2.58,s*2.65,-.18,1.07,1.11),(3.10,s*2.68,-.14,1.28,1.29),(3.81,s*2.59,-.10,1.43,1.47),(4.30,s*2.49,-.06,1.33,1.36),(4.74,s*2.43,-.02,1.08,1.15)],0,.27)
        loft(side+'Hand','Heavy mitten fist',[(1.57,s*2.68,-.31,1.02,1.07),(1.75,s*2.69,-.32,1.22,1.24),(2.27,s*2.67,-.24,1.21,1.23),(2.69,s*2.66,-.19,1.06,1.09)],0,.24)
        box(side+'Hand','Broad inward thumb',(s*2.12,-.47,2.18),(.39,.62,.64),0,.12)
        lx=s*.65
        register(side+'UpperLeg','LowerTorso',(lx,.13,3.25),(s*.77,.08,1.86))
        register(side+'LowerLeg',side+'UpperLeg',(s*.77,.08,1.86),(s*.82,-.04,.53))
        register(side+'Foot',side+'LowerLeg',(s*.82,-.04,.53),(s*.82,-.65,.24))
        loft(side+'UpperLeg','Wide heavy trouser thigh',[(1.83,s*.77,.07,1.12,1.23),(2.39,s*.71,.12,1.20,1.36),(3.12,lx,.14,1.18,1.34),(3.31,lx,.14,1.09,1.22)],3)
        loft(side+'LowerLeg','Stocky green shin',[(.42,s*.82,-.04,.88,1.0),(.81,s*.82,.0,1.01,1.08),(1.48,s*.79,.05,1.10,1.17),(1.89,s*.77,.07,1.07,1.15)],0)
        torn_cuff(side+'LowerLeg','Torn trouser shin',s*.78,1.89,1.19,1.28,3,.51,.06)
        panel(side+'UpperLeg','Exposed knee through ragged trouser tear',[(s*.72-.19,2.26),(s*.72-.29,2.05),(s*.72-.11,1.95),(s*.72+.17,2.12),(s*.72+.11,2.37)],-.573,.018,0,.008)
        box(side+'Foot','Heavy bare foot',(s*.83,-.36,.30),(1.16,1.80,.60),0,.14)

# Exactly fifteen sections with pivots at the intended R15-style joints.
objects={}
for name, items in parts.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in items:o.select_set(True)
    bpy.context.view_layer.objects.active=items[0]
    bpy.ops.object.join(); o=bpy.context.object; o.name=name
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    scene.cursor.location=joints[name]['head']; bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    # Collapse duplicate material slots created by joining surface pieces.
    o.data.materials.clear(); o.data.materials.append(material)
    for p in o.data.polygons:p.material_index=0
    objects[name]=o
assert len(objects)==15

# A provisional rigid limb rig supports an honest pose preview and export validation.
# Final locomotion/attack clips deliberately wait until this model preview is reviewed.
bpy.ops.object.select_all(action='DESELECT'); bpy.ops.object.armature_add(location=(0,0,0))
rig=bpy.context.object; rig.name=KIND+'Zombie_Rig'
bpy.ops.object.mode_set(mode='EDIT'); bones=rig.data.edit_bones
bones.remove(bones[0]); root=bones.new('HumanoidRootPart')
root.head=(0,0,root_z); root.tail=(0,0,root_z+.25)
for name,sp in joints.items():
    b=bones.new(name); b.head=sp['head']; b.tail=sp['tail']; b.parent=bones[sp['parent']]
bpy.ops.object.mode_set(mode='OBJECT')
for name,o in objects.items():
    vg=o.vertex_groups.new(name=name); vg.add(list(range(len(o.data.vertices))),1.0,'REPLACE')
    mod=o.modifiers.new('Rigid segmented body skinning','ARMATURE'); mod.object=rig
    o.parent=rig

bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True)
for o in objects.values():o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.fbx(filepath=str(DEST/'Model.fbx'),use_selection=True,object_types={'MESH','ARMATURE'},add_leaf_bones=False,bake_anim=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
bpy.ops.export_scene.gltf(filepath=str(DEST/'Model.glb'),use_selection=True,export_format='GLB',export_animations=False)
rig.select_set(False)
bpy.ops.export_scene.fbx(filepath=str(DEST/'Parts.fbx'),use_selection=True,object_types={'MESH'},bake_anim=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,use_armature_deform_only=True)

bpy.context.view_layer.update()
verts=[o.matrix_world@v.co for o in objects.values() for v in o.data.vertices]
stats={'name':KIND+'Zombie','sections':list(objects),'bones':len(rig.data.bones),
       'triangles':sum(len(p.vertices)-2 for o in objects.values() for p in o.data.polygons),
       'height':max(v.z for v in verts),'ground':min(v.z for v in verts),'joints':joints,
       'source_texture':'../source-art/'+KIND+'Texture.png','rig_status':'Provisional rigid 15-section rig; no production animations',
       'studio_status':'Not imported or playtested','front':'Blender -Y; intended Roblox -Z'}
(DEST/'manifest.json').write_text(json.dumps(stats,indent=2))

# Isolated render stage; not exported with the asset.
stage=bpy.data.collections.new('PREVIEW_ONLY'); scene.collection.children.link(stage)
def to_stage(o):
    for c in list(o.users_collection):c.objects.unlink(o)
    stage.objects.link(o)
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.mesh.primitive_plane_add(size=200)
floor=bpy.context.object; floor.name='Preview floor'; floor.location.z=-.015; to_stage(floor)
fm=bpy.data.materials.new('Warm gray studio');fm.diffuse_color=(.23,.22,.20,1);fm.use_nodes=True
fm.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.23,.22,.20,1)
fm.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.95
floor.data.materials.append(fm)
height=stats['height']; scale=height/8.5
for loc,power,size in [((-6,-9,13),1700,7),((7,-5,8),1050,6),((2,5,11),1800,6)]:
    bpy.ops.object.light_add(type='AREA',location=tuple(v*scale for v in loc))
    l=bpy.context.object;l.data.energy=power*scale*scale;l.data.shape='DISK';l.data.size=size*scale
    aim(l,(0,0,height*.5));to_stage(l)
scene.world=bpy.data.worlds.new('Neutral studio environment');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.59,.64,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.55
bpy.ops.object.camera_add(location=(height*.87,-height*2.25,height*.91))
cam=bpy.context.object;cam.name='Preview camera';cam.data.type='ORTHO';cam.data.ortho_scale=height*1.26
aim(cam,(0,0,height*.49));scene.camera=cam;to_stage(cam)
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=1120;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG'
# Pose only the baby arms forward. Export files above retain the neutral rest pose.
if KIND=='Baby':
    for side in ['Left','Right']:
        b=rig.pose.bones[side+'UpperArm'];b.rotation_mode='XYZ';b.rotation_euler.x=math.radians(-62)
        b=rig.pose.bones[side+'LowerArm'];b.rotation_mode='XYZ';b.rotation_euler.x=math.radians(-18)
scene.render.filepath=str(DEST/'Preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(DEST/'Model.blend'))
bpy.ops.render.render(write_still=True)
cam.location=(height*1.6,height*2.1,height*.95);aim(cam,(0,0,height*.49))
scene.render.filepath=str(DEST/'Back.png');bpy.ops.render.render(write_still=True)
print('MODEL_COMPLETE',json.dumps(stats))
