"""Author the Hammer Boss geometry, rigid rig and all seven baked motion clips.
Run with Blender --background --python build_boss.py. Only owns this directory.
"""
import bpy, bmesh, math, json, random, sys
from pathlib import Path
from mathutils import Vector, Matrix

OUT=Path(__file__).resolve().parent
FAMILY=OUT.parent/'baby-mutant-zombies'
random.seed(92326)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
parts={}; joints={}
texture=bpy.data.images.load(str(FAMILY/'source-art/MutantTexture.png')); texture.pack()
material=bpy.data.materials.new('Family olive painted atlas');material.use_nodes=True
bs=material.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.94;bs.inputs['Specular IOR Level'].default_value=.12
tex=material.node_tree.nodes.new('ShaderNodeTexImage');tex.image=texture
material.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
# Reuse the established mesh author's geometry/UV utilities, not its body proportions.
source=(FAMILY/'build_models.py').read_text()
exec(source[source.index('def register('):source.index("if KIND == 'Baby':")])

def flatmat(name,color):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.9
    p.inputs['Specular IOR Level'].default_value=.12
    return m
cloth=flatmat('Warm ivory torn canvas',(.48,.42,.30))
leather=flatmat('Worn umber harness',(.17,.105,.068))
metal=flatmat('Matte battered iron',(.17,.19,.20))
edge=flatmat('Scuffed iron edges',(.31,.32,.31))
wood=flatmat('Heavy ash handle',(.29,.14,.063))
blood=flatmat('Sparse dark cartoon stains',(.20,.043,.036))
dirt=flatmat('Soft ochre grime',(.30,.25,.16))
def paint(o,m):o.data.materials.clear();o.data.materials.append(m);return o
def ellipsoid(part,label,loc,dims,tile=0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=1,location=loc)
    o=bpy.context.object;o.scale=Vector(dims)/2;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,part,label,tile)

ROOT=3.8
register('LowerTorso','HumanoidRootPart',(0,.2,ROOT),(0,.2,4.8))
register('UpperTorso','LowerTorso',(0,.2,4.8),(0,.05,8.25))
register('Head','UpperTorso',(0,-.53,8.32),(0,-.6,10.4))
loft('LowerTorso','Broad ragged waistband',[(3.4,0,.2,3.2,1.9),(4.0,0,.2,3.5,2.15),(4.6,0,.05,3.6,2.3),(4.95,0,0,3.3,2.1)],3)
loft('UpperTorso','Broad rounded chest',[(4.6,0,0,3.8,2.5),(5.5,0,-.05,4.6,3.2),(6.8,0,.0,4.7,2.9),(7.7,0,.12,5.0,2.5),(8.1,0,.12,4.6,2.3),(8.4,0,0,3.2,1.9),(8.55,0,-.2,1.55,1.3)],0,.35)
ellipsoid('UpperTorso','Enormous forward hanging belly',(0,-.90,5.50),(5.35,4.15,4.15))
# Cloth is an open, thick shell around the actual stomach: irregular lower hem.
verts=[]
for r,(z,rx,ry,cy) in enumerate([(5.90,2.69,2.22,-.94),(6.75,2.62,2.0,-.95),(7.2,2.6,1.73,-.60),(7.65,2.60,1.46,.1),(8.02,2.42,1.30,.12)]):
    for i in range(24):
        a=2*math.pi*i/24
        zz=z+([-.24,.06,-.09,.17][i%4] if r==0 else 0)
        verts.append((rx*math.cos(a),cy+ry*math.sin(a),zz))
faces=[(r*24+i,r*24+(i+1)%24,(r+1)*24+(i+1)%24,(r+1)*24+i) for r in range(4) for i in range(24)]
o=paint(mesh('UpperTorso','Stretched torn sleeveless shirt',verts,faces),cloth)
bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Cloth thickness','SOLIDIFY');mod.thickness=.045;bpy.ops.object.modifier_apply(modifier=mod.name)
box('Head','Thick neck',(0,-.48,8.35),(1.55,1.35,.8),0,.2)
box('Head','Family block head with familiar scowl',(0,-.61,9.40),(2.28,1.9,2.18),0,.42,True)
# Small, deliberately sparse surface marks; closed shallow patches, no wounds.
paint(panel('Head','Dry cheek stain',[(.70,9.5),(.95,9.4),(.87,9.16),(.96,8.99),(.75,9.12)],-1.568,.015,0),blood)
for s in [-1,1]:
    paint(strap('UpperTorso','Harness front',(s*1.63,-2.63,6.3),(s*1.79,-1.25,7.95),.38,.11,3),leather)
    paint(strap('UpperTorso','Harness shoulder',(s*1.79,-1.15,7.95),(s*1.8,1.08,7.97),.38,.12,3),leather)
    paint(strap('UpperTorso','Harness back',(s*1.80,1.1,7.97),(s*1.5,1.34,5.92),.38,.1,3),leather)
    paint(box('UpperTorso','Square iron buckle',(s*1.72,-1.96,7.18),(.55,.15,.58),0,.055),edge)
    paint(box('UpperTorso','Buckle leather inset',(s*1.72,-2.047,7.18),(.32,.04,.35),0,.025),leather)

for side,s in [('Left',1),('Right',-1)]:
    shoulder=Vector((s*2.92,.04,7.75)); elbow=Vector((s*3.24,.0,5.0)); wrist=Vector((s*3.37,-.04,1.3))
    register(side+'UpperArm','UpperTorso',shoulder,elbow)
    register(side+'LowerArm',side+'UpperArm',elbow,wrist)
    register(side+'Hand',side+'LowerArm',wrist,(s*3.37,-.04,.35))
    loft(side+'UpperArm','Rounded heavy shoulder',[(4.9,s*3.24,0,1.40,1.42),(5.8,s*3.16,0,1.85,1.83),(7.0,s*3.00,.04,2.2,2.1),(7.75,s*2.80,.04,1.92,1.86),(8.15,s*2.68,.04,1.25,1.35)],0,.33)
    loft(side+'LowerArm','Heavy forearm',[(1.3,s*3.37,-.04,1.30,1.38),(2.4,s*3.40,-.04,1.65,1.61),(4.0,s*3.32,0,1.78,1.73),(5.05,s*3.24,0,1.37,1.40)],0,.31)
    # Hands are closed around the handle; fingers curve around its local Z axis.
    box(side+'Hand','Broad palm',(s*3.37,.1,1.05),(1.2,.78,.95),0,.18)
    for i in range(3):box(side+'Hand','Curled grip finger',(s*3.37+(i-1)*.32,-.40,.94),(.31,.55,.76),0,.10)
    box(side+'Hand','Thumb',(s*3.37-s*.55,-.23,1.18),(.43,.55,.65),0,.12)
    hip=Vector((s*1.22,.16,3.85));knee=Vector((s*1.52,.12,2.1));ankle=Vector((s*1.65,-.03,.55))
    register(side+'UpperLeg','LowerTorso',hip,knee);register(side+'LowerLeg',side+'UpperLeg',knee,ankle);register(side+'Foot',side+'LowerLeg',ankle,(s*1.65,-.65,.25))
    loft(side+'UpperLeg','Broad torn trouser leg',[(2.0,s*1.52,.12,1.55,1.7),(2.6,s*1.40,.15,1.80,1.9),(3.8,s*1.22,.16,1.8,1.9),(4.0,s*1.2,.16,1.55,1.65)],3)
    loft(side+'LowerLeg','Heavy exposed shin',[(.48,s*1.65,-.03,1.24,1.3),(1.1,s*1.62,.03,1.48,1.52),(2.15,s*1.52,.12,1.48,1.53)],0)
    torn_cuff(side+'LowerLeg','Asymmetric trouser tear',s*1.54,2.14,1.69,1.8,3,.65 if s==1 else .38,.12)
    box(side+'Foot','Broad planted foot',(s*1.65,-.44,.34),(1.65,2.22,.68),0,.19)
paint(panel('LeftLowerArm','Forearm dried stain',[(3.20,4.8),(3.54,4.66),(3.46,4.31),(3.22,4.42)],-.877,.012,0),blood)
paint(panel('UpperTorso','Cloth stain',[(-1.25,6.85),(-.90,6.78),(-1.04,6.51),(-1.38,6.57)],-1.69,.015,0),dirt)
register('Hammer','HumanoidRootPart',(0,0,0),(0,0,1))
# Weapon authoring axis +Z; hands grip at Z=0 and Z=1.5; head at Z=4.4.
paint(box('Hammer','Thick hammer haft',(0,0,1.55),(.48,.48,6.25),0,.10),wood)
for z in [-.70,-.38,-.06,.26,.58,.9,1.22,1.54,1.86]:
    paint(box('Hammer','Wrapped grip',(0,0,z),(.55,.55,.17),0,.05),leather)
paint(box('Hammer','Oversized bevelled hammer head',(0,0,4.15),(3.00,2.12,2.23),0,.23),metal)
for x in [-1.37,1.37]:paint(box('Hammer','Battered striking cap',(x,0,4.15),(.40,2.19,2.3),0,.14),edge)
paint(box('Hammer','Head reinforcing band',(0,0,4.15),(.40,2.19,2.30),0,.07),leather)
for x,z in [(-.95,4.75),(.94,3.54),(-1.10,3.90)]:
    o=paint(box('Hammer','Shallow metal scuff',(x,-1.069,z),(.43,.018,.055),0,.014),edge);o.rotation_euler.y=.3
paint(panel('Hammer','Small old stain',[(-1.0,3.63),(-.74,3.70),(-.65,3.95),(-.90,3.87)],-1.075,.012,0),blood)

objects={}
for name,items in parts.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in items:o.select_set(True)
    bpy.context.view_layer.objects.active=items[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    scene.cursor.location=joints[name]['head'];bpy.ops.object.origin_set(type='ORIGIN_CURSOR');objects[name]=o

# Roblox MeshParts use one color map. Bake all material slots to an original UV atlas
# so the cream cloth, iron, stains and wood survive import with the painted skin.
uvnode=material.node_tree.nodes.new('ShaderNodeUVMap');uvnode.uv_map='PaintedAtlas'
material.node_tree.links.new(uvnode.outputs['UV'],tex.inputs['Vector'])
atlas=bpy.data.images.new('HammerBoss_Color',width=2048,height=2048,alpha=False)
for m in list(bpy.data.materials):
    if m.use_nodes:
        n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=atlas;m.node_tree.nodes.active=n
bpy.ops.object.select_all(action='DESELECT')
for o in objects.values():o.select_set(True);o.data.uv_layers.new(name='BossAtlas');o.data.uv_layers.active_index=len(o.data.uv_layers)-1
bpy.context.view_layer.objects.active=objects['UpperTorso'];bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(60),island_margin=.008);bpy.ops.object.mode_set(mode='OBJECT')
scene.render.engine='CYCLES';scene.cycles.samples=1;scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True;scene.render.bake.margin=5
bpy.ops.object.bake(type='DIFFUSE')
atlas.filepath_raw=str(OUT/'HammerBoss_Color.png');atlas.file_format='PNG';atlas.save();atlas.pack()
baked=bpy.data.materials.new('HammerBoss baked original atlas');baked.use_nodes=True
p=baked.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.94;p.inputs['Specular IOR Level'].default_value=.1
t=baked.node_tree.nodes.new('ShaderNodeTexImage');t.image=atlas;baked.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
for o in objects.values():
    o.data.materials.clear();o.data.materials.append(baked)
    for p in o.data.polygons:p.material_index=0
    for uv in list(o.data.uv_layers):
        if uv.name!='BossAtlas':o.data.uv_layers.remove(uv)

bpy.ops.object.select_all(action='DESELECT');bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='HammerBoss_Rig'
bpy.ops.object.mode_set(mode='EDIT');bones=rig.data.edit_bones;bones.remove(bones[0]);b=bones.new('HumanoidRootPart');b.head=(0,0,ROOT);b.tail=(0,0,ROOT+.4)
for name,j in joints.items():
    b=bones.new(name);b.head=j['head'];b.tail=j['tail'];b.parent=bones[j['parent']]
bpy.ops.object.mode_set(mode='OBJECT')
for name,o in objects.items():
    vg=o.vertex_groups.new(name=name);vg.add(list(range(len(o.data.vertices))),1.,'REPLACE');mod=o.modifiers.new('Rigid articulated skin','ARMATURE');mod.object=rig;o.parent=rig

T=Matrix.Translation
def R(x=0,y=0,z=0):
    return Matrix.Rotation(math.radians(z),4,'Z')@Matrix.Rotation(math.radians(y),4,'Y')@Matrix.Rotation(math.radians(x),4,'X')
def around(p,r):return T(p)@r@T(-Vector(p))
def align(a,b,c,d):
    a,b,c,d=map(Vector,(a,b,c,d));return T(c)@(b-a).rotation_difference(d-c).to_matrix().to_4x4()@T(-a)
def ik(a,end,l1,l2,pole):
    a,end,pole=map(Vector,(a,end,pole));v=end-a;length=v.length;d=max(.05,min(length,l1+l2-.02));u=v.normalized()
    along=(l1*l1-l2*l2+d*d)/(2*d);height=math.sqrt(max(0,l1*l1-along*along));p=pole-a;p-=u*p.dot(u)
    return a+u*along+p.normalized()*height, max(0,length-l1-l2)

# Authored channels: hip yaw, torso yaw, crouch, torso lean, weapon yaw,
# weapon elevation, grip radius, grip height. Dense samples bake every frame.
neutral=[0,0,.18,7,105,-38,2.8,4.15]
CLIPS={
 'Slam':[(0,neutral),(4,neutral),(5,[0,-5,.23,5,108,-30,3.55,5.3]),(9,[-8,-14,.38,-4,125,12,3.25,6.8]),(12,[-12,-20,.48,-9,145,56,2.4,8.2]),(17,[-10,-17,.52,-10,160,65,2.2,8.55]),(19,[-3,-11,.42,-2,165,61,2.5,8.2]),(21,[4,0,.55,12,175,16,3.5,6.1]),(23,[6,5,.85,26,180,-48,4.7,4.08]),(24,[6,6,.97,29,180,-50,4.7,4.0]),(27,[6,8,1.04,31,180,-50,4.7,4.0]),(31,[5,8,.95,29,180,-50,4.7,4.05]),(36,[2,7,.65,19,153,-44,4.45,4.30]),(41,[0,4,.35,11,120,-42,3.95,4.85]),(46,[0,1,.21,7,104,-40,3.55,5.15]),(50,neutral)],
 'Swing':[(0,neutral),(5,neutral),(6,[0,0,.20,7,105,-30,3.6,5.4]),(10,[-15,-27,.32,5,91,-6,3.7,5.5]),(14,[-24,-43,.42,4,75,0,3.7,5.55]),(18,[-26,-46,.45,3,70,0,3.7,5.6]),(19,[-17,-42,.44,5,70,0,3.7,5.6]),(21,[12,-7,.44,7,115,0,3.8,5.5]),(23,[42,26,.47,9,181,0,3.8,5.5]),(25,[65,57,.52,10,250,0,3.8,5.5]),(29,[76,83,.6,12,295,-5,3.65,5.45]),(33,[70,85,.64,12,306,-12,3.5,5.4]),(38,[50,66,.5,10,312,-34,3.3,4.8]),(43,[29,40,.35,8,329,-60,3.15,4.7]),(48,[10,16,.27,8,392,-64,3.05,4.8]),(54,[0,0,.18,7,465,-38,3.55,5.2])],
 'Spin':[(0,neutral),(5,neutral),(6,[0,0,.28,8,103,-20,3.5,5.4]),(10,[-18,-28,.56,7,80,-4,3.6,5.4]),(14,[-34,-52,.74,8,63,0,3.65,5.4]),(20,[-38,-58,.78,9,57,0,3.65,5.4]),(21,[-17,-48,.72,8,58,0,3.7,5.4]),(24,[52,22,.57,9,97,0,3.8,5.4]),(27,[128,96,.48,10,179,0,3.8,5.4]),(30,[204,174,.5,11,258,0,3.8,5.4]),(33,[280,251,.56,13,337,0,3.8,5.4]),(37,[349,330,.61,14,416,0,3.8,5.4]),(40,[390,381,.70,16,461,-4,3.7,5.4]),(44,[402,402,.82,17,487,-12,3.5,5.2]),(48,[394,406,.65,13,494,-24,3.4,4.8]),(53,[380,391,.42,11,486,-39,3.3,4.8]),(58,[363,371,.29,8,473,-44,3.4,5.0]),(62,[359,361,.21,7,466,-39,3.5,5.18]),(66,[360,360,.18,7,465,-38,3.55,5.2])],
}
CLIPS['Swing'][-1]=(54,[*neutral[:4],neutral[4]+360,*neutral[5:]])
CLIPS['Spin'][-1]=(66,[360,360,*neutral[2:4],neutral[4]+360,*neutral[5:]])
def channels(clip,frame):
    keys=CLIPS[clip]
    for (f,a),(g,b) in zip(keys,keys[1:]):
        if f<=frame<=g:
            u=(frame-f)/(g-f);u=u*u*(3-2*u);return [x+(y-x)*u for x,y in zip(a,b)]
    return keys[-1][1]

def pose(clip,frame):
    sec=frame/30;stride=math.sin(sec*2*math.pi/1.35) if clip=='Walk' else 0
    c=channels(clip,frame) if clip in CLIPS else neutral[:]
    hip,torso,crouch,lean,wyaw,elev,radius,h=c
    if clip in ('Idle','Walk'):
        breath=math.sin(sec*2*math.pi/3.2);crouch+=.045*breath+abs(stride)*.10;lean+=.5*breath
        hip+=stride*3;torso-=stride*2;wyaw+=stride*1.7+.6*breath;h+=.03*breath;elev+=stride*1.5
    if clip=='Hit':lean-=math.sin(min(1,frame/18)*math.pi)*4;torso+=math.sin(min(1,frame/18)*math.pi)*3
    death=max(0,min(1,frame/84)) if clip=='Death' else 0
    if death:crouch+=min(1,death*1.7)*2.6;lean+=max(0,(death-.25)/.75)*70;h-=min(1,death*2)*3.8;elev-=min(1,death*2)*20
    D={}
    hips=T((stride*.10,0,-crouch))@around((0,.2,3.85),R(z=hip))
    D['LowerTorso']=hips
    chest=T((stride*.10,-.07,-crouch))@around((0,.2,4.8),R(x=lean,z=torso))
    D['UpperTorso']=chest
    D['Head']=chest@around(joints['Head']['head'],R(x=-lean*.25,z=-min(25,max(-25,torso-hip))*.35))
    # Weapon is a single rigid transform; arms solve to two explicit grip points.
    az=math.radians(-wyaw);el=math.radians(elev)
    direction=Vector((math.sin(az)*math.cos(el),math.cos(az)*math.cos(el),math.sin(el)))
    # Both hands stay in front of the rotating chest; the head has the long lever.
    facing=math.radians(torso)
    settle=1.0 if clip in ('Idle','Walk','Hit') else max(0,1-frame/8) if clip in CLIPS else 0
    if clip in CLIPS: settle=max(settle,max(0,(frame-CLIPS[clip][-1][0]+10)/10))
    hand_center=Vector((math.sin(facing)*radius-1.5*settle,-math.cos(facing)*radius,h-crouch*.15))
    # Project the shared grip onto both reach spheres before solving elbows.
    # This changes the whole rigid weapon, never detaches or stretches a hand.
    for _ in range(8):
        for side,s in [('Left',1),('Right',-1)]:
            a=Vector(joints[side+'UpperArm']['head']);b=Vector(joints[side+'LowerArm']['head']);w=Vector(joints[side+'Hand']['head'])
            shoulder=chest@a;offset=direction*((.15 if s==1 else 1.55)+.36-.85)
            delta=hand_center+offset-shoulder;limit=(b-a).length+(w-b).length-.06
            if delta.length>limit:hand_center-=delta.normalized()*(delta.length-limit)
    grip=hand_center-direction*.85
    weapon=T(grip)@Vector((0,0,1)).rotation_difference(direction).to_matrix().to_4x4()
    if death>.45:
        head=weapon@Vector((0,0,4.15));weapon.translation.z+=1.2-head.z
    D['Hammer']=weapon
    errors=[]
    for side,s in [('Left',1),('Right',-1)]:
        a=Vector(joints[side+'UpperArm']['head']);b=Vector(joints[side+'LowerArm']['head']);w=Vector(joints[side+'Hand']['head'])
        # Grip center lies .36 units along -Z from wrist in rest hand coordinates.
        z=.15 if s==1 else 1.55
        wrist=weapon@Vector((0,0,z+.36));target=weapon@Vector((0,0,z))
        shoulder=chest@a
        elbow,error=ik(shoulder,wrist,(b-a).length,(w-b).length,chest@Vector((s*5,-4.5,4.8)))
        errors.append(error)
        D[side+'UpperArm']=align(a,b,shoulder,elbow)
        D[side+'LowerArm']=align(b,w,elbow,wrist)
        # Both palms inherit the same stable weapon rotation, with opposing grip rolls.
        palm=(elbow-wrist);palm-=direction*palm.dot(direction);palm.normalize()
        handR=Matrix((palm.cross(direction),palm,direction)).transposed().to_4x4()
        D[side+'Hand']=T(wrist)@handR@T(-w)
        a=Vector(joints[side+'UpperLeg']['head']);b=Vector(joints[side+'LowerLeg']['head']);w=Vector(joints[side+'Foot']['head'])
        yaw=hip*.8 if clip=='Spin' else hip*.35
        angle=math.radians(yaw);step=abs(math.sin(math.radians(hip)*1.8))*.25 if clip=='Spin' else max(0,stride*s)*.28
        foot=R(z=yaw)@Vector((s*2.10,-.08+stride*s*.65,.55+step))
        foot.z=.55+step
        if death:foot=Vector((s*2.1,-.15,.55))
        knee,error=ik(hips@a,foot,(b-a).length,(w-b).length,R(z=yaw)@Vector((s*2.8,-3,2)))
        D[side+'UpperLeg']=align(a,b,hips@a,knee);D[side+'LowerLeg']=align(b,w,knee,foot)
        D[side+'Foot']=T(foot)@R(z=yaw+stride*s*4)@T(-w)
    return D,max(errors)

def apply(D,frame=None):
    for name in joints:
        pb=rig.pose.bones[name];pb.rotation_mode='QUATERNION';pb.matrix=D[name]@rig.data.bones[name].matrix_local
        bpy.context.view_layer.update()
        if frame is not None:
            for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(data_path=prop,frame=frame,group=name)

def select_asset():
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    for o in objects.values():o.select_set(True)
    bpy.context.view_layer.objects.active=rig

select_asset()
bpy.ops.export_scene.fbx(filepath=str(OUT/'HammerBoss_Rig.fbx'),use_selection=True,object_types={'MESH','ARMATURE'},add_leaf_bones=False,bake_anim=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
rig.select_set(False)
bpy.ops.export_scene.fbx(filepath=str(OUT/'HammerBoss_Import.fbx'),use_selection=True,object_types={'MESH'},bake_anim=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
C=Matrix(((-1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)))
def arr(m):return [round(m[i][3],6) for i in range(3)]+[round(m[i][j],6) for i in range(3) for j in range(3)]
data={'rootHeight':ROOT,'joints':{},'parts':{},'clips':{}}
for name,j in joints.items():
    data['joints'][name]={'parent':j['parent'],'head':list(C@Vector(j['head']))[:3]}
    vs=[C@(objects[name].matrix_world@v.co) for v in objects[name].data.vertices]
    lo=Vector([min(v[i] for v in vs) for i in range(3)]);hi=Vector([max(v[i] for v in vs) for i in range(3)])
    data['parts'][name]={'center':list((lo+hi)/2),'size':list(hi-lo)}
timing={'Idle':96,'Walk':81,'Slam':50,'Swing':54,'Spin':66,'Hit':18,'Death':84}
checks={}
scene.render.fps=30
for clip,last in timing.items():
    rig.animation_data_clear();frames=[];maxerr=0
    for f in range(last+1):
        D,error=pose(clip,f);maxerr=max(error,maxerr);apply(D,f+1)
        frames.append({n:arr(C@T((0,0,-ROOT))@d@T((0,0,ROOT))@C.inverted()) for n,d in D.items()})
    action=rig.animation_data.action;action.name='Boss_'+clip;action.use_fake_user=True
    scene.frame_start=1;scene.frame_end=last+1;scene.frame_set(1)
    if clip in CLIPS:
        for i,(f,_) in enumerate(CLIPS[clip]):scene.timeline_markers.new(clip+'_'+str(f),frame=f+1)
    select_asset()
    bpy.ops.export_scene.fbx(filepath=str(OUT/(clip+'.fbx')),use_selection=True,object_types={'MESH','ARMATURE'},add_leaf_bones=False,bake_anim=True,bake_anim_use_all_actions=False,bake_anim_use_nla_strips=False,bake_anim_simplify_factor=0,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
    data['clips'][clip]={'fps':30,'lastFrame':last,'frames':frames}
    checks[clip]={'frames':last+1,'maxArmOverreach':round(maxerr,6)}
(OUT/'BossData.json').write_text(json.dumps(data,separators=(',',':')))
(OUT/'BossData.luau').write_text('return game:GetService("HttpService"):JSONDecode([====['+json.dumps(data,separators=(',',':'))+']====])\n')
(OUT/'authoring-checks.json').write_text(json.dumps(checks,indent=2))

# Neutral product stage, excluded from every exported asset.
rig.animation_data_clear();apply(pose('Idle',0)[0]);scene.frame_set(1)
bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object;floor.name='PREVIEW_FLOOR';floor.location.z=-.02;floor.data.materials.append(flatmat('Stage',(.14,.17,.17)))
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
for loc,power,size in [((-7,-11,15),2300,8),((8,-5,11),1400,7),((2,7,13),2100,6)]:
    bpy.ops.object.light_add(type='AREA',location=loc);l=bpy.context.object;l.data.energy=power;l.data.shape='DISK';l.data.size=size;aim(l,(0,0,5))
scene.world=bpy.data.worlds.new('Neutral environment');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.50,.56,.60,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.55
bpy.ops.object.camera_add(location=(14,-26,13));cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=15;aim(cam,(0,0,5));scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.render.resolution_x=1152;scene.render.resolution_y=1152;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'HammerBoss.blend'))
scene.render.filepath=str(OUT/'Preview.png');bpy.ops.render.render(write_still=True)
print('BOSS_BUILD_COMPLETE',json.dumps(checks))
