"""Reference-inspired creature mesh, baked textures and custom NPC rig. Run in Blender."""
import bpy, bmesh, math, json, random
from pathlib import Path
from mathutils import Vector
from mathutils.noise import noise_vector, noise, multi_fractal
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

def realistic_skin(material):
    n=material.node_tree.nodes;l=material.node_tree.links;p=n.get('Principled BSDF')
    pos=n.new('ShaderNodeNewGeometry')
    def tex(scale,detail=3,rough=.7):
        t=n.new('ShaderNodeTexNoise');l.new(pos.outputs['Position'],t.inputs['Vector']);t.inputs['Scale'].default_value=scale;t.inputs['Detail'].default_value=detail;t.inputs['Roughness'].default_value=rough;return t
    # Independent scales: pallor patches, irregular speckles, pores and fine wrinkles.
    coarse=tex(3.1,5);speck=tex(58,3);pores=tex(155,2);wrinkle=tex(29,4)
    vc=n.new('ShaderNodeVertexColor');vc.layer_name='SkinTint'
    ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.22;ramp.color_ramp.elements[0].color=(.27,.20,.14,1);ramp.color_ramp.elements[1].position=.70;ramp.color_ramp.elements[1].color=(.86,.75,.59,1);l.new(coarse.outputs['Fac'],ramp.inputs[0])
    mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=.46;l.new(vc.outputs['Color'],mix.inputs[1]);l.new(ramp.outputs[0],mix.inputs[2])
    spots=n.new('ShaderNodeValToRGB');spots.color_ramp.elements[0].position=.28;spots.color_ramp.elements[0].color=(.16,.10,.07,1);spots.color_ramp.elements[1].position=.55;spots.color_ramp.elements[1].color=(1,1,1,1);l.new(speck.outputs['Fac'],spots.inputs[0])
    pigment=n.new('ShaderNodeMixRGB');pigment.blend_type='MULTIPLY';pigment.inputs[0].default_value=.50;l.new(mix.outputs[0],pigment.inputs[1]);l.new(spots.outputs[0],pigment.inputs[2])
    warp=tex(5,3);scale=n.new('ShaderNodeVectorMath');scale.operation='SCALE';scale.inputs[3].default_value=.17;l.new(warp.outputs['Color'],scale.inputs[0]);add=n.new('ShaderNodeVectorMath');add.operation='ADD';l.new(pos.outputs['Position'],add.inputs[0]);l.new(scale.outputs[0],add.inputs[1])
    vein=n.new('ShaderNodeTexVoronoi');vein.feature='DISTANCE_TO_EDGE';vein.inputs['Scale'].default_value=11;l.new(add.outputs[0],vein.inputs['Vector'])
    thin=n.new('ShaderNodeMapRange');thin.clamp=True;thin.inputs['From Min'].default_value=.001;thin.inputs['From Max'].default_value=.023;thin.inputs['To Min'].default_value=.24;thin.inputs['To Max'].default_value=0;l.new(vein.outputs['Distance'],thin.inputs[0])
    vm=n.new('ShaderNodeMixRGB');l.new(thin.outputs[0],vm.inputs[0]);l.new(pigment.outputs[0],vm.inputs[1]);vm.inputs[2].default_value=(.16,.19,.165,1);l.new(vm.outputs[0],p.inputs['Base Color'])
    # Stretched noise creates fine crumpled skin instead of uniform sandpaper.
    mapping=n.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY';mapping.inputs[1].default_value=(1.5,1.5,.65);l.new(pos.outputs['Position'],mapping.inputs[0]);l.new(mapping.outputs[0],wrinkle.inputs['Vector'])
    b1=n.new('ShaderNodeBump');b1.inputs['Strength'].default_value=.55;b1.inputs['Distance'].default_value=.020;l.new(wrinkle.outputs['Fac'],b1.inputs['Height'])
    b2=n.new('ShaderNodeBump');b2.inputs['Strength'].default_value=.52;b2.inputs['Distance'].default_value=.015;l.new(pores.outputs['Fac'],b2.inputs['Height']);l.new(b1.outputs[0],b2.inputs['Normal']);l.new(b2.outputs[0],p.inputs['Normal'])
    rough=n.new('ShaderNodeMapRange');rough.inputs['From Min'].default_value=.15;rough.inputs['From Max'].default_value=.85;rough.inputs['To Min'].default_value=.57;rough.inputs['To Max'].default_value=.91;l.new(coarse.outputs['Fac'],rough.inputs[0]);l.new(rough.outputs[0],p.inputs['Roughness'])
realistic_skin(skin)

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

# Closed, broad skin patches with gravity-dependent sag; each uses distinct landmarks.
# The inner sheet penetrates the torso; remeshing fuses the attachment naturally.
fold_edges=[]
def drape(name,x0,x1,top,bottom,sag,depth,bulge,seed):
    vs=[];fs=[];nu=34;nv=13
    def point(u,v,back=False):
        x=x0+(x1-x0)*u
        edge=math.sin(math.pi*u)**.72
        ztop=top[0]*(1-u)+top[1]*u+.035*math.sin(u*9+seed)*edge
        zbottom=bottom[0]*(1-u)+bottom[1]*u-sag*edge*(1+.10*math.sin(7*u+seed))
        z=ztop*(1-v)+zbottom*v
        # Broad lobe with asymmetric creases converging towards its attachments.
        yy=depth[0]*(1-u)+depth[1]*u
        yy+=bulge*edge*math.sin(math.pi*v*.73)+.009*math.sin(17*u+v*4+seed)*edge*math.sin(math.pi*v)
        if back:yy=max(.015,yy-(.045+.25*(1-v)+.18*(1-edge)))
        return (x,-yy,z)
    for back in [False,True]:
        for j in range(nv):
            for i in range(nu):vs.append(point(i/(nu-1),j/(nv-1),back))
    span=nu*nv
    for side in range(2):
        off=side*span
        for j in range(nv-1):
            for i in range(nu-1):
                a=off+j*nu+i;quad=(a,a+1,a+nu+1,a+nu);fs.append(quad if not side else tuple(reversed(quad)))
    border=list(range(nu))+[j*nu+nu-1 for j in range(1,nv)]+[(nv-1)*nu+i for i in range(nu-2,-1,-1)]+[j*nu for j in range(nv-2,0,-1)]
    for a,b in zip(border,border[1:]+border[:1]):fs.append((a,b,b+span,a+span))
    me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(name,me);scene.collection.objects.link(o);o.data.materials.append(skin);pieces.append(o)
    fold_edges.append([Vector(point(u,1)) for u in np.linspace(.03,.97,28)])
    return o
bone('Root',(0,0,0),(0,0,.5),None)
bone('Pelvis',(0,0,3.9),(0,0,4.65),'Root')
bone('Spine',(0,0,4.65),(0,0,5.5),'Pelvis')
bone('Chest',(0,0,5.5),(0,0,6.45),'Spine')
bone('Neck',(0,0,6.45),(0,0,7.05),'Chest')
bone('Head',(0,0,7.05),(0,0,8.55),'Neck')

# Uneven, emaciated trunk with ribs beneath skin rather than rows of surface tubes.
tube('Torso',[(0,0,3.57),(-.03,.01,3.9),(-.045,.025,4.15),(-.02,.025,4.6),(.025,.03,5),(.045,.01,5.5),(.025,0,6),(0,0,6.35),(0,0,6.55)],[(.18,.15),(.46,.27),(.64,.31),(.60,.30),(.49,.265),(.64,.34),(.87,.395),(.92,.37),(.47,.25)],n=48)
tube('Neck',[(0,.02,6.35),(0,.04,6.7),(0,.03,7.1),(0,0,7.35)],[(.38,.27),(.31,.28),(.30,.26),(.34,.26)],n=28)
for s in [-1,1]:
    ell('Scapula',(s*.44,.265,6.04+(.05 if s>0 else 0)),(.34,.14,.40))
    # Clavicles and tapered tendons establish landmarks beneath the loose tissue.
    tube('Clavicle',[(s*.05,-.255,6.39),(s*.36,-.32,6.40),(s*.67,-.23,6.38),(s*.88,-.12,6.31)],[.035,.046,.038,.015],n=12)
drape('Left hanging pectoral',.07,.91,(6.36,6.24),(6.00,6.07),.31,(.35,.145),.20,3)
drape('Right hanging pectoral',-.91,-.025,(6.22,6.37),(6.03,5.91),.25,(.14,.36),.19,8)
drape('Oblique loose flap',-.58,.11,(5.71,5.60),(5.46,5.29),.10,(.18,.30),.105,19)
drape('Uneven abdominal lobe',-.46,.48,(5.00,5.16),(4.80,4.90),.19,(.10,.13),.17,27)
drape('Pelvic overhang',-.62,.62,(4.58,4.48),(4.17,4.04),.37,(.16,.15),.30,6)
drape('Long groin skin apron',-.48,.55,(4.25,4.18),(3.92,3.78),.56,(.23,.21),.30,37)
drape('Lower overlapping pelvic skin',-.36,.32,(3.99,3.95),(3.65,3.63),.37,(.285,.26),.255,12)
for j,(z,thick) in enumerate([(6.53,.031),(6.72,.041),(6.90,.028)]):
    pts=[(.30*math.cos(t),.025+.275*math.sin(t),z-.055*math.cos(t*2)+.02*math.sin(3*t+j)) for t in np.linspace(0,2*math.pi,53)]
    tube('Uneven neck compression',pts,[thick*(1+.2*math.sin(t*3+j)) for t in np.linspace(0,2*math.pi,53)],n=10)

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
drape('Left hanging jowl',.17,.36,(7.41,7.39),(6.97,7.09),.42,(.35,.30),.105,2)
drape('Right hanging jowl',-.36,-.17,(7.42,7.35),(7.01,6.94),.34,(.30,.35),.125,11)

for s,side in [(-1,'R'),(1,'L')]:
    hip=(s*.43,0,4.13);knee=(s*.70,-.06,2.24);ankle=(s*.82,.09,.48)
    bone('Thigh.'+side,hip,knee,'Pelvis');bone('Shin.'+side,knee,ankle,'Thigh.'+side);bone('Foot.'+side,ankle,(s*.82,-.54,.18),'Shin.'+side)
    tube('Thigh', [hip,(s*.50,.025,3.80),(s*.57,.055,3.45),(s*.65,.0,2.72),knee],[(.30,.255),(.28,.245),(.23,.20),(.145,.15),(.15,.145)],n=28)
    tube('Outer thigh tendon',[(s*.63,-.07,3.72),(s*.68,-.08,3.16),(s*.70,-.16,2.37)],[(.070,.040),(.052,.035),(.035,.025)],n=12)
    ell('Kneecap',(s*.7,-.13,2.26),(.175,.12,.235))
    tube('Lower leg',[knee,(s*.73,.10,2.00),(s*.75,.16,1.69),(s*.79,.13,1.19),ankle],[(.16,.145),(.18,.205),(.17,.20),(.105,.12),(.105,.105)],n=28)
    tube('Shin ridge',[(s*.70,-.19,2.20),(s*.75,-.065,1.51),(s*.82,-.02,.46)],[.058,.049,.035],n=10)
    ell('Heel pad',(s*.82,.225,.235),(.175,.235,.20))
    tube('Achilles tendon',[(s*.815,.18,.85),(s*.82,.23,.53),(s*.82,.29,.30)],[.062,.055,.077],n=16)
    ell('Ankle outer bone',(s*.96,.09,.48),(.075,.09,.11))
    ell('Ankle inner bone',(s*.70,.055,.53),(.065,.08,.085))
    ell('Foot arch',(s*.82,-.055,.255),(.155,.275,.165))
    ell('Forefoot pad',(s*.83,-.345,.16),(.235,.25,.115))
    tube('Instep tendon',[(s*.80,-.01,.43),(s*.78,-.25,.29),(s*.72,-.48,.21)],[.032,.028,.020],n=10)
    for j in range(5):
        x=s*(.655+j*.087);ell('Toe',(x,-.53-(4-j)*.013,.14),(.073-j*.006,.155-j*.012,.081-j*.007))
    tube('Ankle skin transition',[(s*.82,.10,.66),(s*.82,.12,.47),(s*.82,.14,.32)],[(.12,.13),(.13,.135),(.135,.15)],n=20)
    shoulder=(s*.89,0,6.31);elbow=(s*1.59,.0,5.77);wrist=(s*2.18,-.13,6.33)
    bone('UpperArm.'+side,shoulder,elbow,'Chest');bone('Forearm.'+side,elbow,wrist,'UpperArm.'+side);bone('Hand.'+side,wrist,(s*2.30,-.13,6.83),'Forearm.'+side)
    ell('Shoulder',shoulder,(.29,.27,.31))
    tube('Upper arm',[shoulder,(s*1.17,.0,6.12),elbow],[(.27,.26),(.235,.235),(.145,.145)],n=24)
    tube('Forearm',[elbow,(s*1.83,-.06,6.0),wrist],[(.15,.15),(.205,.18),(.12,.11)],n=24)
    if s<0:drape('Right elbow skin pocket',-1.95,-1.22,(6.06,6.10),(5.89,5.93),.38,(.035,.025),.13,32)
    else:drape('Left elbow skin pocket',1.23,1.96,(6.13,6.12),(5.92,5.98),.29,(.025,.045),.14,9)
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
print('FUSING',len(pieces),flush=True)
bpy.ops.object.select_all(action='DESELECT')
for o in pieces:o.select_set(True)
bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join();body=bpy.context.object;body.name='PaleWatcher_Skin'
activate(body)
r=body.modifiers.new('Unified organic skin','REMESH');r.mode='VOXEL';r.voxel_size=.018;r.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=r.name)
smooth=body.modifiers.new('Soft tissue','SMOOTH');smooth.factor=.85;smooth.iterations=3;bpy.ops.object.modifier_apply(modifier=smooth.name)
print('SCULPT RELIEF',len(body.data.vertices),flush=True)
# Non-repeating micro relief and slight silhouette asymmetry on the fused sculpture.
sculpt_normals=[v.normal.copy() for v in body.data.vertices]
for v,normal_vec in zip(body.data.vertices,sculpt_normals):
    p=body.matrix_world@v.co
    irregular=noise(p*8.7)*.003+noise(p*24.2)*.0015
    broad=noise(p*2.9)*.003
    v.co+=normal_vec*(irregular+broad)
body.data.update()
print('CUTTING FACE',flush=True)
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
# Remesh loses material assignments: use spatial coloration on skin through attributes.
print('SKIN COLOR',len(body.data.vertices),flush=True)
body.data.materials.clear();body.data.materials.append(skin)
attr=body.data.color_attributes.new(name='SkinTint',type='FLOAT_COLOR',domain='POINT')
# Different patches at each joint: uneven redness, gray-blue pallor and ochre mottling.
patches=[((-1.59,-.09,5.75),(.24,.26,.27),.78),((1.63,-.02,5.88),(.30,.22,.19),.66),((-2.19,-.1,6.33),(.17,.18,.21),.68),((2.15,-.1,6.38),(.23,.17,.17),.84),((-.70,-.17,2.25),(.22,.22,.21),.83),((.71,-.13,2.31),(.19,.22,.32),.66),((-.82,.12,.49),(.21,.25,.20),.72),((.82,.19,.48),(.23,.24,.15),.82),((-.52,.02,7.42),(.15,.22,.28),.74),((.51,.02,7.46),(.17,.22,.23),.64),((.03,-.33,6.70),(.29,.15,.27),.52),((-.82,-.07,6.17),(.24,.29,.29),.45),((.72,-.11,6.28),(.26,.25,.18),.57),((-.38,-.31,3.72),(.23,.20,.34),.54),((.33,-.37,4.02),(.22,.20,.25),.61)]
# Sample attachment edges once; nearest distance yields diffuse redness along sagging hems.
edge_array=np.array([list(p) for line in fold_edges for p in line])
for v in body.data.vertices:
    q=body.matrix_world@v.co;x,y,z=q
    mott=noise(q*6.7);breakup=max(.13,min(1,.58+noise(q*19.3)*1.8))
    redness=max([strength*math.exp(-sum(((q[i]-c[i])/r[i])**2 for i in range(3))*1.25) for c,r,strength in patches])
    if abs(x)>2.03 and z>6.35:redness=max(redness,.53+noise(q*7)*.17)
    edge_d2=np.min(np.sum((edge_array-np.array(q))**2,axis=1))
    edge_red=math.exp(-edge_d2/.007)*.63
    redness=min(.91,redness*(.82+.88*breakup)+edge_red*(.65+breakup*.45))
    base=Vector((.57,.48,.36))*(1+mott*.16)
    shade=Vector((.33,.105,.080))
    col=base.lerp(shade,redness)
    gray=max(0,noise(q*3.8)-.04)*.38
    col=col.lerp(Vector((.27,.30,.285)),gray)
    attr.data[v.index].color=(*col,1)
# Join accessory surfaces; assign same tint attribute white on non-skin meshes.
for o in details:
    at=o.data.color_attributes.new(name='SkinTint',type='FLOAT_COLOR',domain='POINT')
    for item in at.data:item.color=(1,1,1,1)
source_collection=bpy.data.collections.new('High resolution sculpt • editing source');scene.collection.children.link(source_collection)
high_parts=[]
for original in [body]+details:
    clone=original.copy();clone.data=original.data.copy();source_collection.objects.link(clone);high_parts.append(clone)
bpy.ops.object.select_all(action='DESELECT')
for clone in high_parts:clone.select_set(True)
bpy.context.view_layer.objects.active=high_parts[0];bpy.ops.object.join();high=bpy.context.object;high.name='PaleWatcher_HighSculpt';bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
high.hide_render=True;high.hide_set(True);high.select_set(False)
# Reserve detail geometry instead of allowing global decimation to flatten small teeth/eyes.
body.data.calc_loop_triangles();activate(body);reduce=body.modifiers.new('Body game budget','DECIMATE');reduce.ratio=min(1,12200/len(body.data.loop_triangles));bpy.ops.object.modifier_apply(modifier=reduce.name)
detail_tris=0
for o in details:o.data.calc_loop_triangles();detail_tris+=len(o.data.loop_triangles)
for o in details:
    count=len(o.data.loop_triangles);ratio=min(1,max(24/count,6600/detail_tris))
    if ratio<1:
        activate(o);reduce=o.modifiers.new('Detail game budget','DECIMATE');reduce.ratio=ratio;bpy.ops.object.modifier_apply(modifier=reduce.name)
bpy.ops.object.select_all(action='DESELECT');body.select_set(True)
for o in details:o.select_set(True)
bpy.context.view_layer.objects.active=body;bpy.ops.object.join();body.name='PaleWatcher'
print('JOINED SCULPT',len(body.data.vertices),flush=True)
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
shared_edges=[e for e in bm.edges if len(e.link_faces)>2]
if shared_edges:bmesh.ops.split_edges(bm,edges=shared_edges)
loose=[e for e in bm.edges if not e.link_faces]
if loose:bmesh.ops.delete(bm,geom=loose,context='EDGES')
bound=[e for e in bm.edges if e.is_boundary]
if bound:bmesh.ops.holes_fill(bm,edges=bound,sides=10)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free();body.data.update()
print('GEOMETRY',len(body.data.vertices),len(body.data.polygons),flush=True)
activate(body);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False) if hasattr(bpy.ops.mesh,'normals_make_consistent') else None
bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.0025);bpy.ops.object.mode_set(mode='OBJECT')

# Bake portable color and tangent-space grain, with no lighting in the color texture.
scene.render.engine='CYCLES';scene.cycles.samples=12;scene.render.bake.margin=16
def bake(name,kind):
    print('BAKING',name,flush=True)
    im=bpy.data.images.new(name,width=4096,height=4096,alpha=False)
    if kind!='COLOR':im.colorspace_settings.name='Non-Color'
    restore=[]
    for m in body.data.materials:
        node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;m.node_tree.nodes.active=node
        if kind in ['COLOR','ROUGHNESS']:
            nodes=m.node_tree.nodes;links=m.node_tree.links;principled=nodes.get('Principled BSDF');out=nodes.get('Material Output');old=out.inputs['Surface'].links[0].from_socket
            e=nodes.new('ShaderNodeEmission');inp=principled.inputs['Base Color' if kind=='COLOR' else 'Roughness']
            if inp.links:links.new(inp.links[0].from_socket,e.inputs[0])
            else:
                val=inp.default_value;e.inputs[0].default_value=val if kind=='COLOR' else (val,val,val,1)
            links.new(e.outputs[0],out.inputs['Surface']);restore.append((m,out,old,e))
    activate(body)
    scene.render.bake.use_selected_to_active=False
    # Bake pore/wrinkle bump on the game topology directly: projecting rays across
    # tightly overlapping skin folds can hit the underside and invert the normal.
    bpy.ops.object.bake(type='EMIT' if kind in ['COLOR','ROUGHNESS'] else kind)
    high.hide_render=True;high.hide_set(True);high.select_set(False);scene.render.bake.use_selected_to_active=False
    for m,out,old,e in restore:m.node_tree.links.new(old,out.inputs['Surface']);m.node_tree.nodes.remove(e)
    im.filepath_raw=str(OUT/'textures'/(name+'.png'));im.file_format='PNG';im.save();im.pack();return im
color=bake('PaleWatcher_Color','COLOR');normal=bake('PaleWatcher_Normal','NORMAL');rough=bake('PaleWatcher_Roughness','ROUGHNESS')
final=bpy.data.materials.new('PaleWatcher_Baked');final.use_nodes=True;n=final.node_tree.nodes;l=final.node_tree.links;p=n.get('Principled BSDF');p.inputs['Roughness'].default_value=.82
ct=n.new('ShaderNodeTexImage');ct.image=color;l.new(ct.outputs['Color'],p.inputs['Base Color'])
nt=n.new('ShaderNodeTexImage');nt.image=normal;nm=n.new('ShaderNodeNormalMap');l.new(nt.outputs['Color'],nm.inputs['Color']);l.new(nm.outputs['Normal'],p.inputs['Normal'])
rt=n.new('ShaderNodeTexImage');rt.image=rough;l.new(rt.outputs['Color'],p.inputs['Roughness'])
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
    if z<.40:candidates=[b for b in deform if b[0]=='Foot.'+('L' if x>0 else 'R')]
    elif 3.10<z<4.35 and abs(x)<.45 and y<-.32:candidates=[b for b in deform if b[0]=='Pelvis']
    elif z>6.93 and abs(x)<.65: candidates=[b for b in deform if b[0] in ['Head','Neck']]
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
stats={'vertices':len(body.data.vertices),'triangles':len(body.data.polygons),'bones':len(arm.bones),'max_influences':max(len(v.groups) for v in body.data.vertices),'unweighted_vertices':sum(not v.groups for v in body.data.vertices),'height_blender_units':round(body.dimensions.z,3),'texture_resolution':4096,'revision':2,'high_sculpt_vertices':len(high.data.vertices)}
(OUT/'validation.json').write_text(json.dumps(stats,indent=2))
scene.render.filepath=str(OUT/'PaleWatcher_Preview.png');bpy.ops.render.render(write_still=True)
cam.location=(0,-20,7.7);aim(cam,(0,-.05,6.75));cam.data.ortho_scale=6.8;scene.render.filepath=str(OUT/'PaleWatcher_Detail.png');bpy.ops.render.render(write_still=True)
cam.location=(13,-4,5);aim(cam,(0,0,4.1));cam.data.ortho_scale=9.7;scene.render.filepath=str(OUT/'PaleWatcher_Side.png');bpy.ops.render.render(write_still=True)
cam.location=(4,7,7);aim(cam,(0,0,4.2));cam.data.ortho_scale=10;scene.render.filepath=str(OUT/'PaleWatcher_Back.png');bpy.ops.render.render(write_still=True)
print('DONE',stats,flush=True)
