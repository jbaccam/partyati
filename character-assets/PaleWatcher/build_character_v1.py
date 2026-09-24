"""Reference-inspired creature mesh, baked textures and custom NPC rig. Run in Blender."""
import bpy, bmesh, math, json, random
from pathlib import Path
from mathutils import Vector
import numpy as np

OUT=Path(__file__).resolve().parent
random.seed(81)
scene=bpy.data.scenes.new('PaleWatcher_Asset')
bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'
scene.unit_settings.scale_length=.28
pieces=[]; details=[]; bones=[]

def activate(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o

def mat(name,color,grain=True):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.79
    if grain:
        tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=380;tex.inputs['Detail'].default_value=2
        coarse=n.new('ShaderNodeTexNoise');coarse.inputs['Scale'].default_value=5.8;coarse.inputs['Detail'].default_value=4
        mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=.45;l.new(tex.outputs['Fac'],mix.inputs[1]);l.new(coarse.outputs['Fac'],mix.inputs[2])
        ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.13;ramp.color_ramp.elements[0].color=(*[v*.43 for v in color],1);ramp.color_ramp.elements[1].position=.65;ramp.color_ramp.elements[1].color=(*color,1)
        l.new(mix.outputs[0],ramp.inputs[0]);l.new(ramp.outputs[0],p.inputs['Base Color'])
        bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.22;bump.inputs['Distance'].default_value=.004;l.new(tex.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs[0],p.inputs['Normal'])
    return m
skin=mat('Chalk skin • pores and mottling',(.78,.735,.66))
rose=mat('Skin creases • muted rose',(.42,.20,.155))
claw=mat('Blackened keratin',(.028,.023,.019))
mouth=mat('Mouth depth',(.038,.009,.007))
ivory=mat('Old ivory teeth',(.51,.40,.235))
white=mat('Palm eye sclera',(.66,.58,.34))
iris=mat('Amber iris',(.25,.16,.027))
pupil=mat('Pupil',(.003,.002,.001),False)

def ell(name,c,s,material=skin,target=pieces):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,location=c)
    o=bpy.context.object;o.name=name;o.scale=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material);target.append(o);return o

def tube(name,points,radii,material=skin,target=pieces,n=12):
    vs=[];fs=[]
    for i,p in enumerate(points):
        p=Vector(p);t=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        t.normalize();a=t.cross(Vector((0,1,0))).normalized();b=t.cross(a).normalized()
        rr=radii[i];rx,ry=rr if isinstance(rr,tuple) else (rr,rr)
        for k in range(n):
            q=p+a*(math.cos(k*2*math.pi/n)*rx)+b*(math.sin(k*2*math.pi/n)*ry);vs.append(q)
    for i in range(len(points)-1):
        for k in range(n):
            a=i*n+k;b=i*n+(k+1)%n;fs.append((a,b,b+n,a+n))
    fs.append(tuple(reversed(range(n))));fs.append(tuple((len(points)-1)*n+k for k in range(n)))
    me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(name,me);scene.collection.objects.link(o);o.data.materials.append(material);target.append(o);return o

def bone(name,h,t,parent):bones.append((name,Vector(h),Vector(t),parent))
bone('Root',(0,0,0),(0,0,.5),None)
bone('Pelvis',(0,0,3.9),(0,0,4.65),'Root')
bone('Spine',(0,0,4.65),(0,0,5.5),'Pelvis')
bone('Chest',(0,0,5.5),(0,0,6.45),'Spine')
bone('Neck',(0,0,6.45),(0,0,7.05),'Chest')
bone('Head',(0,0,7.05),(0,0,8.55),'Neck')

# Lean torso with connected draping folds, not clothing.
tube('Torso',[(0,0,3.57),(0,0,3.9),(0,0,4.15),(0,0,4.6),(0,0,5),(0,0,5.5),(0,0,6),(0,0,6.35),(0,0,6.55)],[(.18,.15),(.46,.30),(.65,.34),(.65,.35),(.55,.32),(.69,.37),(.91,.43),(.92,.39),(.47,.25)],n=40)
tube('Neck',[(0,.02,6.35),(0,.04,6.7),(0,.03,7.1),(0,0,7.35)],[(.38,.27),(.31,.28),(.30,.26),(.34,.26)],n=28)
for s in [-1,1]:
    ell('Pectoral',(s*.40,-.245,6.11),(.47,.16,.245))
    ell('Scapula',(s*.46,.27,6.06),(.38,.20,.43))
    for j in range(6):
        z=5.89-j*.18;w=.82-j*.043
        pts=[(s*(.04+w*.9*t),-.37*math.sqrt(max(.06,1-(.9*t)**2)),z-.13*math.sin(t*math.pi)) for t in np.linspace(0,1,21)]
        tube('Rib skin fold',pts,[(.075,.040)]*21,n=10)
for j in range(6):
    z=4.90-j*.18;w=.54 if j<4 else .49-(j-4)*.08
    pts=[(w*t,-.34*math.sqrt(max(.08,1-(t*.87)**2))-.013,z-.23*(1-t*t)) for t in np.linspace(-1,1,31)]
    tube('Sagging abdomen fold',pts,[(.105,.055)]*31,n=12)
for j in range(5):
    pts=[(.30*math.cos(t),.03+.275*math.sin(t),6.55+j*.135-.055*math.cos(t*2)) for t in np.linspace(0,2*math.pi,45)]
    tube('Neck wrinkle',pts,[.035]*45,n=8)

# Blank elongated cranium, low face, drooping jaw and chin tendrils.
ell('Eyeless cranium',(0,.01,7.76),(.52,.425,.70))
ell('Midface',(0,-.20,7.41),(.39,.27,.41))
ell('Jaw',(0,-.12,7.10),(.36,.29,.26))
for s in [-1,1]:
    tube('Drooping cheek',[(s*.34,-.27,7.52),(s*.40,-.34,7.23),(s*.30,-.37,6.90),(s*.26,-.32,6.59)],[.095,.087,.068,.022],n=14)
    ell('Ear',(s*.49,.015,7.44),(.085,.11,.19))
    ell('Ear hollow',(s*.53,-.053,7.45),(.045,.046,.13),rose,details)
    tube('Throat tendon',[(s*.20,-.18,6.45),(s*.18,-.29,6.8),(s*.19,-.32,7.08)],[.045,.047,.07],n=10)
ell('Chin flap',(0,-.27,6.99),(.25,.13,.18))

for s,side in [(-1,'R'),(1,'L')]:
    hip=(s*.43,0,4.13);knee=(s*.70,-.06,2.24);ankle=(s*.82,.09,.48)
    bone('Thigh.'+side,hip,knee,'Pelvis');bone('Shin.'+side,knee,ankle,'Thigh.'+side);bone('Foot.'+side,ankle,(s*.82,-.54,.18),'Shin.'+side)
    tube('Thigh', [hip,(s*.53,.02,3.74),(s*.64,.02,3.0),knee],[(.32,.28),(.31,.26),(.19,.19),(.17,.16)],n=24)
    ell('Kneecap',(s*.7,-.13,2.26),(.175,.12,.235))
    tube('Lower leg',[knee,(s*.75,.13,1.8),(s*.80,.14,1.0),ankle],[(.17,.16),(.20,.19),(.105,.11),(.13,.12)],n=22)
    tube('Shin ridge',[(s*.70,-.19,2.20),(s*.75,-.065,1.51),(s*.82,-.02,.46)],[.058,.049,.035],n=10)
    ell('Foot',(s*.82,-.18,.24),(.22,.43,.18))
    for j in range(5):
        x=s*(.64+j*.088);ell('Toe',(x,-.49-(4-j)*.012,.16),(.058,.16,.082))
    for j in range(3):
        pts=[(s*.82+.135*math.cos(t),.08+.135*math.sin(t),.46+j*.09) for t in np.linspace(0,2*math.pi,25)]
        tube('Ankle fold',pts,[.025]*25,n=8)
    shoulder=(s*.89,0,6.31);elbow=(s*1.59,.0,5.77);wrist=(s*2.18,-.13,6.33)
    bone('UpperArm.'+side,shoulder,elbow,'Chest');bone('Forearm.'+side,elbow,wrist,'UpperArm.'+side);bone('Hand.'+side,wrist,(s*2.30,-.13,6.83),'Forearm.'+side)
    ell('Shoulder',shoulder,(.29,.27,.31))
    tube('Upper arm',[shoulder,(s*1.17,.0,6.12),elbow],[(.27,.26),(.235,.235),(.145,.145)],n=24)
    tube('Forearm',[elbow,(s*1.83,-.06,6.0),wrist],[(.15,.15),(.205,.18),(.12,.11)],n=24)
    tube('Elbow hanging skin',[(s*1.20,.015,6.05),(s*1.49,.04,5.54),(s*1.68,.01,5.64),(s*1.97,-.04,6.13)],[(.08,.13),(.09,.11),(.11,.12),(.045,.045)],n=12)
    ell('Palm',(s*2.29,-.135,6.61),(.255,.115,.33))
    # Four long spread fingers plus inward-reaching thumb.
    for j in range(5):
        if j==4:
            a=(s*2.08,-.13,6.53);b=(s*1.87,-.14,6.66);c=(s*1.79,-.16,6.75);d=(s*1.53,-.26,7.02)
        else:
            x=2.07+j*.145;spread=(j-1.5)*.15;length=[.69,.94,.90,.66][j]
            a=(s*x,-.13,6.82);b=(s*(x+spread*.5),-.12,6.82+length*.5);c=(s*(x+spread*.85),-.16,6.82+length*.68);d=(s*(x+spread*1.12),-.28,6.82+length+.18)
        bn='Finger%d.%s'%(j+1,side);bone(bn,a,b,'Hand.'+side);bone(bn+'.tip',b,d,bn)
        tube('Finger', [a,b,c],[.064,.051,.040],rose,n=12)
        tube('Long tapered claw',[c,tuple(Vector(c).lerp(Vector(d),.55)),d],[.048,.029,.002],claw,details,n=10)
        for q in [b]:ell('Knuckle',q,(.060,.057,.066),rose)
    # Eye faces forward from the middle of each hand.
    cx=s*2.29;cz=6.63
    ell('Palm eye socket',(cx,-.235,cz),(.159,.047,.135),rose,details)
    ell('Palm eyeball',(cx,-.263,cz),(.112,.053,.073),white,details)
    ell('Amber iris',(cx,-.310,cz),(.052,.012,.056),iris,details)
    ell('Black pupil',(cx,-.322,cz),(.023,.008,.040),pupil,details)
    for sign in [-1,1]:
        pts=[(cx+.128*t,-.283,cz+sign*.071*math.sqrt(max(0,1-t*t))) for t in np.linspace(-1,1,19)]
        tube('Palm eyelid',pts,[.021]*19,rose,details,n=8)

# Fuse skin into one continuous sculpture, then cut true mouth and nostril cavities.
bpy.ops.object.select_all(action='DESELECT')
for o in pieces:o.select_set(True)
bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join();body=bpy.context.object;body.name='PaleWatcher_Skin'
activate(body)
r=body.modifiers.new('Unified organic skin','REMESH');r.mode='VOXEL';r.voxel_size=.025;r.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=r.name)
smooth=body.modifiers.new('Soft tissue','SMOOTH');smooth.factor=1.1;smooth.iterations=3;bpy.ops.object.modifier_apply(modifier=smooth.name)
for name,c,sc in [('Mouth opening',(0,-.395,7.17),(.23,.22,.12)),('Nostril R',(-.066,-.426,7.53),(.036,.085,.058)),('Nostril L',(.066,-.426,7.53),(.036,.085,.058))]:
    cutter=ell(name,c,sc,target=[]);activate(body);mod=body.modifiers.new(name,'BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
ell('Mouth interior',(0,-.285,7.17),(.225,.09,.09),mouth,details)
for s in [-1,1]:ell('Nostril depth',(s*.066,-.384,7.53),(.026,.023,.048),mouth,details)
for j in range(7):
    x=(j-3)*.048;z=7.211+random.uniform(-.009,.008)
    tube('Irregular tooth',[(x,-.379,z+.024),(x,-.386,z-.014-random.random()*.026)],[.020,.011],ivory,details,n=7)
for sign in [-1,1]:
    pts=[(.22*t,-.447+.025*t*t,7.17+sign*.115*math.sqrt(max(0,1-t*t))-.02*t*t) for t in np.linspace(-1,1,25)]
    tube('Withered lip',pts,[(.026,.023)]*25,rose,details,n=8)
activate(body);d=body.modifiers.new('Game mesh reduction','DECIMATE');d.ratio=min(1,13900/len(body.data.polygons));bpy.ops.object.modifier_apply(modifier=d.name)
# Remesh loses material assignments: use spatial coloration on skin through attributes.
body.data.materials.clear();body.data.materials.append(skin)
attr=body.data.color_attributes.new(name='SkinTint',type='FLOAT_COLOR',domain='POINT')
for v in body.data.vertices:
    x,y,z=body.matrix_world@v.co
    hand=max(0,min(1,(abs(x)-1.94)*3))
    creases=.25*max(0,math.sin((z-3.7)*29)) if 3.7<z<4.9 and y<-.26 else 0
    tint=min(.8,hand*.72+creases)
    attr.data[v.index].color=(1*(1-tint)+.78*tint,1*(1-tint)+.39*tint,1*(1-tint)+.32*tint,1)
n=skin.node_tree.nodes;l=skin.node_tree.links;p=n.get('Principled BSDF');existing=p.inputs['Base Color'].links[0].from_socket
vc=n.new('ShaderNodeVertexColor');vc.layer_name='SkinTint';mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;l.new(existing,mix.inputs[1]);l.new(vc.outputs['Color'],mix.inputs[2]);l.new(mix.outputs[0],p.inputs['Base Color'])
# Join accessory surfaces; assign same tint attribute white on non-skin meshes.
for o in details:
    at=o.data.color_attributes.new(name='SkinTint',type='FLOAT_COLOR',domain='POINT')
    for item in at.data:item.color=(1,1,1,1)
bpy.ops.object.select_all(action='DESELECT');body.select_set(True)
for o in details:o.select_set(True)
bpy.context.view_layer.objects.active=body;bpy.ops.object.join();body.name='PaleWatcher'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
for p in body.data.polygons:p.use_smooth=True
tri=body.modifiers.new('Export triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=tri.name)
if len(body.data.polygons)>19500:
    dec=body.modifiers.new('Final budget','DECIMATE');dec.ratio=19400/len(body.data.polygons);bpy.ops.object.modifier_apply(modifier=dec.name)
# Remove microscopic remesh flaps and degeneracies before unwrapping and skinning.
bm=bmesh.new();bm.from_mesh(body.data)
flaps=[f for f in bm.faces if sum(e.is_boundary for e in f.edges)>=2 and any(len(e.link_faces)>2 for e in f.edges)]
if flaps:bmesh.ops.delete(bm,geom=flaps,context='FACES_ONLY')
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.001)
bmesh.ops.dissolve_degenerate(bm,dist=.001,edges=list(bm.edges))
loose=[e for e in bm.edges if not e.link_faces]
if loose:bmesh.ops.delete(bm,geom=loose,context='EDGES')
bound=[e for e in bm.edges if e.is_boundary]
if bound:bmesh.ops.holes_fill(bm,edges=bound,sides=10)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free();body.data.update()
print('GEOMETRY',len(body.data.vertices),len(body.data.polygons),flush=True)
activate(body);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False) if hasattr(bpy.ops.mesh,'normals_make_consistent') else None
bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.009);bpy.ops.object.mode_set(mode='OBJECT')

# Bake portable color and tangent-space grain, with no lighting in the color texture.
scene.render.engine='CYCLES';scene.cycles.samples=8;scene.render.bake.margin=12
def bake(name,kind):
    im=bpy.data.images.new(name,width=2048,height=2048,alpha=False)
    if kind=='NORMAL':im.colorspace_settings.name='Non-Color'
    for m in body.data.materials:
        node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;m.node_tree.nodes.active=node
    activate(body)
    if kind=='DIFFUSE':scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True
    bpy.ops.object.bake(type=kind)
    im.filepath_raw=str(OUT/'textures'/(name+'.png'));im.file_format='PNG';im.save();im.pack();return im
color=bake('PaleWatcher_Color','DIFFUSE');normal=bake('PaleWatcher_Normal','NORMAL')
final=bpy.data.materials.new('PaleWatcher_Baked');final.use_nodes=True;n=final.node_tree.nodes;l=final.node_tree.links;p=n.get('Principled BSDF');p.inputs['Roughness'].default_value=.82
ct=n.new('ShaderNodeTexImage');ct.image=color;l.new(ct.outputs['Color'],p.inputs['Base Color'])
nt=n.new('ShaderNodeTexImage');nt.image=normal;nm=n.new('ShaderNodeNormalMap');l.new(nt.outputs['Color'],nm.inputs['Color']);l.new(nm.outputs['Normal'],p.inputs['Normal'])
body.data.materials.clear();body.data.materials.append(final)
for p in body.data.polygons:p.material_index=0

# Custom deformation skeleton. Maximum two normalized influences per vertex.
arm=bpy.data.armatures.new('PaleWatcher_Skeleton');rig=bpy.data.objects.new('PaleWatcher_Rig',arm);scene.collection.objects.link(rig);activate(rig);bpy.ops.object.mode_set(mode='EDIT')
for name,h,t,parent in bones:
    b=arm.edit_bones.new(name);b.head=h;b.tail=t
    if parent:b.parent=arm.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True;arm.display_type='OCTAHEDRAL';arm.bones['Root'].use_deform=False
deform=[b for b in bones if b[0]!='Root'];groups={name:body.vertex_groups.new(name=name) for name,h,t,p in deform}
def dist(pt,a,b):
    v=b-a;t=max(0,min(1,(pt-a).dot(v)/v.length_squared));return (pt-(a+v*t)).length
for v in body.data.vertices:
    q=v.co;x,y,z=q
    if z>6.93 and abs(x)<.65: candidates=[b for b in deform if b[0] in ['Head','Neck']]
    elif abs(x)>1.97 and z>6.4:candidates=[b for b in deform if b[0].endswith('L' if x>0 else 'R') or b[0].endswith(('L' if x>0 else 'R')+'.tip')]
    else:candidates=[b for b in deform if not b[0].startswith('Finger')]
    ds=sorted([(dist(q,h,t),name) for name,h,t,p in candidates])[:2]
    weights=[1/(d+.045)**5 for d,name in ds];total=sum(weights)
    for (_,name),w in zip(ds,weights):groups[name].add([v.index],w/total,'REPLACE')
body.parent=rig;mod=body.modifiers.new('Creature deformation','ARMATURE');mod.object=rig

# A subtle looping breathing/hand motion sample, exported separately.
scene.render.fps=30;scene.frame_start=1;scene.frame_end=91
for f,phase in [(1,0),(23,1),(46,0),(68,-1),(91,0)]:
    for name in ['Chest','Neck','Head','Hand.L','Hand.R']:
        pb=rig.pose.bones[name];pb.rotation_mode='XYZ';pb.rotation_euler=(phase*.025,phase*.013,phase*(.018 if name=='Head' else .008));pb.keyframe_insert('rotation_euler',frame=f)
action=rig.animation_data.action;action.name='Unsettling_Idle';action.use_fake_user=True
scene.frame_set(1)

# Studio preview stage, excluded from asset exports.
stage=bpy.data.collections.new('Preview only');scene.collection.children.link(stage)
def stage_obj(o):
    for c in list(o.users_collection):c.objects.unlink(o)
    stage.objects.link(o)
def aim(o,point):o.rotation_euler=(Vector(point)-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(10,-23,10));cam=bpy.context.object;cam.name='Preview_Camera';stage_obj(cam);aim(cam,(0,0,4.3));cam.data.type='ORTHO';cam.data.ortho_scale=10.7;scene.camera=cam
for name,loc,power,col,size in [('Key',(-5,-8,12),1800,(.88,.94,1),6),('Warm fill',(6,-3,7),750,(1,.82,.70),5),('Rim',(0,4,9),2200,(.45,.67,1),5)]:
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.color=col;o.data.shape='DISK';o.data.size=size;aim(o,(0,0,4.7));stage_obj(o)
scene.world=bpy.data.worlds.new('Dark studio');scene.world.use_nodes=True;scene.world.node_tree.nodes.get('Background').inputs[0].default_value=(.023,.029,.036,1);scene.world.node_tree.nodes.get('Background').inputs[1].default_value=.35
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True;scene.render.resolution_x=1050;scene.render.resolution_y=1250;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
activate(body);rig.select_set(True)
rig.animation_data.action=None
bpy.ops.export_scene.fbx(filepath=str(OUT/'PaleWatcher_Rigged.fbx'),use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,bake_anim=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
rig.animation_data.action=action
bpy.ops.export_scene.fbx(filepath=str(OUT/'PaleWatcher_Idle.fbx'),use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,bake_anim=True,bake_anim_use_all_actions=False,bake_anim_use_nla_strips=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
scene.frame_set(1);activate(rig)
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_perspective='CAMERA';area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'PaleWatcher.blend'))
stats={'vertices':len(body.data.vertices),'triangles':len(body.data.polygons),'bones':len(arm.bones),'max_influences':max(len(v.groups) for v in body.data.vertices),'unweighted_vertices':sum(not v.groups for v in body.data.vertices),'height_blender_units':round(body.dimensions.z,3),'texture_resolution':2048}
(OUT/'validation.json').write_text(json.dumps(stats,indent=2))
scene.render.filepath=str(OUT/'PaleWatcher_Preview.png');bpy.ops.render.render(write_still=True)
cam.location=(0,-20,7.7);aim(cam,(0,-.05,6.75));cam.data.ortho_scale=6.8;scene.render.filepath=str(OUT/'PaleWatcher_Detail.png');bpy.ops.render.render(write_still=True)
print('DONE',stats,flush=True)
