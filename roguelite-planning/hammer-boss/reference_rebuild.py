"""Reference-led rebuild. Real Blender meshes; reference establishes the front view.
Independent of the rejected first-pass rig and its proportions.
"""
import bpy,bmesh,math,random,json
from pathlib import Path
from mathutils import Vector,Matrix
OUT=Path(__file__).resolve().parent/'reference-rebuild';OUT.mkdir(exist_ok=True)
random.seed(726)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene;groups={}

def mat(name,color,noise=.1,speckles=False):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF');p.inputs['Roughness'].default_value=.91;p.inputs['Specular IOR Level'].default_value=.17
 tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=7;tex.inputs['Detail'].default_value=1.3;tex.inputs['Roughness'].default_value=.7
 ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.20;ramp.color_ramp.elements[0].color=(*(c*(1-noise) for c in color),1);ramp.color_ramp.elements[1].position=.80;ramp.color_ramp.elements[1].color=(*(min(1,c*(1+noise)) for c in color),1)
 l.new(tex.outputs['Fac'],ramp.inputs[0]);out=ramp.outputs['Color']
 if speckles:
  v=n.new('ShaderNodeTexNoise');v.inputs['Scale'].default_value=34;v.inputs['Detail'].default_value=2;v.inputs['Roughness'].default_value=.72
  dot=n.new('ShaderNodeValToRGB');dot.color_ramp.interpolation='CONSTANT';dot.color_ramp.elements[0].position=.58;dot.color_ramp.elements[0].color=(1,1,1,1);dot.color_ramp.elements[1].position=.645;dot.color_ramp.elements[1].color=(.12,.19,.063,1)
  l.new(v.outputs['Fac'],dot.inputs[0]);mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=.80;l.new(out,mix.inputs[1]);l.new(dot.outputs[0],mix.inputs[2]);out=mix.outputs[0]
 l.new(out,p.inputs['Base Color']);return m
family=bpy.data.images.load(str(OUT.parent.parent/'baby-mutant-zombies/source-art/MutantTexture.png'));family.pack()
skin=bpy.data.materials.new('Exact existing Tank green skin');skin.use_nodes=True
sn=skin.node_tree.nodes;sl=skin.node_tree.links;sp=sn.get('Principled BSDF');sp.inputs['Roughness'].default_value=.91;sp.inputs['Specular IOR Level'].default_value=.15
st=sn.new('ShaderNodeTexImage');st.image=family;su=sn.new('ShaderNodeUVMap');su.uv_map='FamilyPaint';sl.new(su.outputs['UV'],st.inputs['Vector']);sl.new(st.outputs['Color'],sp.inputs['Base Color'])
skinDark=mat('Skin shadow folds',(.105,.18,.035),.08)
skinLight=mat('Raised green folds',(.31,.47,.105),.10)
black=mat('Socket and mouth darkness',(.013,.021,.009),.02)
eye=mat('Clouded ivory eyes',(.83,.87,.78),.02)
teeth=mat('Old ivory uneven teeth',(.69,.66,.48),.08)
cloth=mat('Dirty torn cream undershirt',(.48,.42,.29),.40,True)
strapmat=mat('Battered dark brown suspenders',(.115,.075,.054),.42)
iron=mat('Charcoal worn hammer iron',(.105,.11,.115),.34)
ironEdge=mat('Worn pale iron bevels',(.29,.285,.265),.28)
rust=mat('Dark dried cartoon stains',(.18,.028,.021),.16)
pants=mat('Ragged charcoal trousers',(.066,.076,.090),.35,True)
sash=mat('Torn wine red waist cloth',(.12,.025,.024),.23)
wood=mat('Worn brown hardwood shaft',(.255,.105,.035),.30)
woodLight=mat('Scuffed wood grain',(.39,.19,.073),.16)

def family_uv(o,face=False):
 uv=o.data.uv_layers.get('FamilyPaint') or o.data.uv_layers.new(name='FamilyPaint')
 vs=[v.co for v in o.data.vertices];lo=[min(v[i] for v in vs) for i in range(3)];span=[max(max(v[i] for v in vs)-lo[i],.00001) for i in range(3)]
 for p in o.data.polygons:
  front=face and p.normal.y<-.22;axis=max(range(3),key=lambda i:abs(p.normal[i]))
  for li in p.loop_indices:
   v=o.data.vertices[o.data.loops[li].vertex_index].co
   a,b=(0,2) if front or axis==1 else (1,2) if axis==0 else (0,1)
   u,w=(v[a]-lo[a])/span[a],(v[b]-lo[b])/span[b]
   uv.data[li].uv=((int(front)+.016+.968*u)/2,(1+.016+.968*w)/2)

def finish(o,name,group,m,bevel=0,segments=2):
 o.name=name
 if bevel:
  bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Rounded chipped edge','BEVEL');mod.width=bevel;mod.segments=segments;bpy.ops.object.modifier_apply(modifier=mod.name)
 o.data.materials.append(m)
 if m==skin:family_uv(o)
 groups.setdefault(group,[]).append(o);return o
def box(name,group,loc,dims,m,bevel=.08):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=dims;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,group,m,bevel,3)
def mesh(name,group,verts,faces,m):
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);scene.collection.objects.link(o)
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
 return finish(o,name,group,m)
def ellipsoid(name,group,loc,dims,m,segments=20,rings=12):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=loc);o=bpy.context.object;o.scale=Vector(dims)/2;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for p in o.data.polygons:p.use_smooth=True
 return finish(o,name,group,m)
def tube(name,group,points,radii,m,n=16):
 pts=list(map(Vector,points));verts=[]
 tangents=[(pts[min(j+1,len(pts)-1)]-pts[max(0,j-1)]).normalized() for j in range(len(pts))]
 # Pick one stable frame for the entire curve. A fixed Y-up frame collapses
 # rings when curled fingers run parallel to Y, leaving the observed holes.
 reference=min([Vector((0,1,0)),Vector((1,0,0)),Vector((0,0,1))],key=lambda axis:max(abs(t.dot(axis)) for t in tangents))
 for j,p in enumerate(pts):
  direction=tangents[j];x=direction.cross(reference).normalized();y=direction.cross(x).normalized()
  rx,ry=radii[j] if isinstance(radii[j],tuple) else (radii[j],radii[j])
  for i in range(n):
   a=2*math.pi*i/n;verts.append(p+x*math.cos(a)*rx+y*math.sin(a)*ry)
 faces=[tuple(range(n-1,-1,-1)),tuple(range((len(pts)-1)*n,len(pts)*n))]
 faces.extend((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for j in range(len(pts)-1) for i in range(n))
 return mesh(name,group,verts,faces,m)
def loft(name,group,rings,m,n=28):
 # z, center x, center y, halfwidth, halfdepth. Gentle angular variation.
 verts=[]
 for j,(z,x,y,w,d) in enumerate(rings):
  for i in range(n):
   a=2*math.pi*i/n;fac=1+.008*math.sin(i*2.7+j*.8)
   verts.append((x+w*math.cos(a)*fac,y+d*math.sin(a)*fac,z))
 faces=[tuple(range(n-1,-1,-1)),tuple(range((len(rings)-1)*n,len(rings)*n))]
 faces.extend((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for j in range(len(rings)-1) for i in range(n))
 return mesh(name,group,verts,faces,m)
def patch(name,group,coords,m,thickness=.017):
 if m==rust:
  # Ragged painted boundaries replace rectangular stickers.
  center=Vector(tuple(sum(p[i] for p in coords)/len(coords) for i in range(3)));rough=[]
  for a,b in zip(coords,coords[1:]+coords[:1]):
   a,b=Vector(a),Vector(b)
   for k in range(3):
    p=a.lerp(b,k/3);p=center+(p-center)*random.uniform(.83,1.17);rough.append(tuple(p))
  # Subdivided surface, rather than a single flat polygon that cuts into skin.
  center=sum((Vector(p) for p in rough),Vector())/len(rough)
  verts=[center]+[Vector(p) for p in rough]
  faces=[(0,i+1,(i+1)%len(rough)+1) for i in range(len(rough))]
  o=mesh(name,group,verts,faces,m)
  bm=bmesh.new();bm.from_mesh(o.data)
  bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=3,use_grid_fill=True)
  bm.to_mesh(o.data);bm.free();bpy.context.view_layer.update()
  coords=[tuple(v.co) for v in o.data.vertices]
  surface=[]
  for point in coords:
   p=Vector(point);best=None
   for target in groups.get(group,[]):
    if target.type!='MESH' or not target.data.materials or target.data.materials[0] not in (skin,cloth,iron):continue
    inv=target.matrix_world.inverted();origin=inv@Vector((p.x,-12,p.z));direction=inv.to_3x3()@Vector((0,1,0))
    hit,loc,normal,index=target.ray_cast(origin,direction)
    if hit:
     world=target.matrix_world@loc
     if best is None or world.y<best.y:best=world
   if best is not None:p.y=best.y-.018
   surface.append(tuple(p))
  for v,p in zip(o.data.vertices,surface):v.co=p
  o.data.update();return o
 n=len(coords);vs=list(coords)+[(x,y+thickness,z) for x,y,z in coords];faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 return mesh(name,group,vs,faces,m)
def line(name,group,pts,r,m):return tube(name,group,pts,[r]*len(pts),m,7)

def unify(group,material,voxel=.065):
 items=[o for o in groups[group] if len(o.data.materials)==1 and o.data.materials[0]==material]
 if not items:return
 bpy.ops.object.select_all(action='DESELECT')
 for o in items:o.select_set(True)
 bpy.context.view_layer.objects.active=items[0]
 for o in items:groups[group].remove(o)
 bpy.ops.object.join();o=bpy.context.object
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 mod=o.modifiers.new('Continuous sculpted surface','REMESH');mod.mode='VOXEL';mod.voxel_size=voxel;mod.use_smooth_shade=True
 bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Blend anatomical transitions','SMOOTH');mod.factor=1.1;mod.iterations=5
 bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Game surface topology','DECIMATE');mod.ratio=.32
 bpy.ops.object.modifier_apply(modifier=mod.name)
 for p in o.data.polygons:p.use_smooth=True
 o.name='Continuous '+group+' surface'
 if material==skin:family_uv(o)
 groups[group].append(o)
 return o

# Tall reference silhouette; the abdomen projects forward without widening the hips.
loft('Continuous chest back and trapezius','Torso',[(4.5,0,.10,1.7,1.05),(5.2,0,-.10,2.16,1.50),(6.4,0,-.20,2.56,1.72),(7.6,0,.14,2.74,1.55),(8.6,0,.28,2.97,1.62),(9.2,0,.34,3.15,1.57),(9.65,-.06,.32,3.12,1.47),(10.0,-.10,.28,2.94,1.36),(10.35,-.14,.18,2.47,1.18),(10.65,-.16,.04,1.79,.96),(10.86,-.17,-.10,.90,.67)],skin,48)
ellipsoid('Huge hanging exposed stomach','Torso',(0,-.71,6.36),(5.10,3.76,4.31),skin,28,18)
ellipsoid('Heavy neck','Head',(-.16,-.28,9.71),(1.55,1.45,1.30),skin)
bodySkin=unify('Torso',skin,.070)
bpy.context.view_layer.update()

def surface_ray(origin,direction,targets):
 origin=Vector(origin);direction=Vector(direction).normalized();best=None
 for target in targets:
  inv=target.matrix_world.inverted()
  hit,loc,normal,index=target.ray_cast(inv@origin,inv.to_3x3()@direction)
  if hit:
   loc=target.matrix_world@loc;normal=(target.matrix_world.to_3x3()@normal).normalized()
   if best is None or (loc-origin).length<(best[0]-origin).length:best=(loc,normal)
 return best
head=box('Beveled bald head','Head',(-.40,-.40,10.77),(1.94,1.82,2.26),skin,.32)
head.rotation_euler.y=math.radians(-2);head.rotation_euler.z=math.radians(2)
# Thick face panels match the reference expression rather than reusing a different mob face.
face=Vector((-.40,-1.46,10.70))
def facepts(coords):return [(face.x+x,face.y+y,face.z+z) for x,y,z in coords]
for s in [-1,1]:
 socket=patch('Angular sunken eye socket','Head',facepts([(s*.10,-.01,.27),(s*.30,-.02,.15),(s*.48,-.02,-.02),(s*.73,.01,.04),(s*.82,.03,.39),(s*.69,.015,.56),(s*.40,-.02,.45)]),black)
 iris=ellipsoid('Unequal milky eyes','Head',face+Vector((s*.47,-.09,.20)),(.32,.08,.13 if s==1 else .30),eye,14,8)
 patch('Overhanging angry brow','Head',facepts([(s*.09,-.065,.28),(s*.14,-.08,.49),(s*.61,-.035,.66),(s*.85,.02,.55),(s*.74,-.04,.38),(s*.30,-.115,.26)]),skin)
 line('Brow shadow crease','Head',facepts([(s*.13,-.073,.62),(s*.38,-.035,.78),(s*.62,.0,.80),(s*.80,.02,.63)]),.023,skinDark)
 patch('Nostril','Head',facepts([(s*.07,-.18,-.09),(s*.25,-.095,-.16),(s*.10,-.16,-.25)]),black)
 line('Cheek fold','Head',facepts([(s*.71,-.035,-.05),(s*.67,-.04,-.29),(s*.73,-.02,-.49)]),.019,skinDark)
ellipsoid('Blunt zombie nose','Head',face+Vector((0,-.07,-.05)),(.40,.30,.39),skin,12,8)
patch('Dark crooked snarl','Head',facepts([(-.60,-.015,-.60),(-.49,-.04,-.35),(-.23,-.07,-.27),(.04,-.085,-.31),(.40,-.04,-.28),(.65,.00,-.46),(.64,.00,-.76),(.26,-.09,-.69),(-.18,-.08,-.67)]),black)
for i,(x,z) in enumerate([(-.37,-.40),(-.15,-.37),(.31,-.37),(.50,-.46),(-.43,-.63),(.28,-.64)]):
 o=box('Uneven individual tooth','Head',face+Vector((x,-.075,z)),(.15 if i!=2 else .19,.07,.18 if i<5 else .12),teeth,.027);o.rotation_euler.y=(i%3-1)*.12
line('Forehead wrinkle','Head',facepts([(-.71,.02,.93),(-.37,-.04,.84),(0,-.05,.82),(.39,-.04,.87),(.66,.02,1.01)]),.019,skinDark)
patch('Small dried temple stain','Head',facepts([(.68,.01,.80),(.83,.08,.96),(.83,.09,.61),(.66,.00,.46),(.63,-.02,.23),(.72,.01,.13),(.65,-.02,-.10),(.51,-.06,.05),(.56,-.05,.40)]),rust)

# Use the family's green skin only; this boss has his own modeled expression.
family_uv(head,False)
line('Healed diagonal brow scar','Head',facepts([(.16,-.14,.94),(.27,-.16,.78),(.36,-.17,.59),(.51,-.15,.37)]),.036,skinLight)
for x,z in [(.26,.81),(.35,.62),(.44,.45)]:
 line('Scar stitch crease','Head',facepts([(x-.07,-.17,z-.015),(x+.07,-.17,z+.015)]),.016,skinDark)

# Sleeveless undershirt: a fitted torn shell with the large scooped belly opening.
N=96;rows=20;verts=[]
for j in range(rows):
 t=j/(rows-1)
 for i in range(N):
  a=2*math.pi*i/N;front=max(0,-math.sin(a))
  bottom=5.1+2.63*front**2.0+(.12*math.sin(i*5.3)+.06*math.cos(i*2.9))
  top=9.35-.72*front**3;z=bottom+(top-bottom)*t
  # Fit every garment vertex to the actual enlarged skin, not an old proxy ellipse.
  radial=Vector((math.cos(a),math.sin(a),0))
  hit=surface_ray(Vector((0,0,z))+radial*12,-radial,[bodySkin])
  assert hit,'Shirt fitting ray missed the torso'
  loc,normal=hit;clearance=.13/max(.4,normal.dot(radial))
  loc+=radial*clearance;loc.z=z;verts.append(tuple(loc))
faces=[(j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i) for j in range(rows-1) for i in range(N)]
o=mesh('Torn undershirt with arched belly opening','Torso',verts,faces,cloth)
shirt=o
bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Fabric thickness','SOLIDIFY');mod.thickness=.055;mod.offset=1;bpy.ops.object.modifier_apply(modifier=mod.name)
for poly in o.data.polygons:poly.use_smooth=True
bpy.context.view_layer.update()
# Continuous shoulder bands, dark side straps and proper framed buckles.
for s in [-1,1]:
 def frontY(x,z):
  hit=surface_ray((x,-12,z),(0,1,0),[bodySkin,shirt]);return hit[0].y-.14
 vs=[]
 for i in range(35):
  a=math.radians(-42+i*264/34);radial=Vector((0,-math.cos(a),math.sin(a)))
  for dx in [-.25,.25]:
   origin=Vector((s*1.90+dx,.1,8.15));hit=surface_ray(origin+radial*12,-radial,[bodySkin,shirt]);assert hit
   loc,normal=hit;vs.append(tuple(loc+normal*.15))
 fs=[(i*2,i*2+1,i*2+3,i*2+2) for i in range(34)]
 band=mesh('Continuous worn suspender','Torso',vs,fs,strapmat);bpy.context.view_layer.objects.active=band;md=band.modifiers.new('Leather thickness','SOLIDIFY');md.thickness=.13;bpy.ops.object.modifier_apply(modifier=md.name)
 cx=s*1.9;y=frontY(cx,8.67)-.1;z=8.67
 for dx,dz,w,h in [(-.28,0,.105,.65),(.28,0,.105,.65),(0,-.29,.56,.10),(0,.29,.56,.10)]:box('Square buckle iron frame','Torso',(cx+dx,y-.05,z+dz),(w,.16,h),ironEdge,.025)
 box('Buckle central tongue','Torso',(cx,y-.08,z),(.34,.09,.06),ironEdge,.02)
 for z2 in [7.9,9.1]:line('Harness edge scuff','Torso',[(cx-.18,frontY(cx,z2)-.14,z2),(cx-.18,frontY(cx,z2+.11)-.14,z2+.11)],.012,ironEdge)

# Heavy, relatively long legs, with wine-colored tattered waistcloth.
seat=loft('Continuous full trouser seat and waistband','Hips',[(3.08,0,.26,1.37,.80),(3.35,0,.40,1.87,1.14),(3.60,0,.43,2.17,1.36),(3.85,0,.40,2.27,1.47),(4.08,0,.32,2.24,1.48),(4.30,0,.23,2.14,1.39),(4.52,0,.12,2.00,1.26),(4.85,0,.03,1.89,1.14)],pants,48)
for v in seat.data.vertices:
 if v.co.y>.9:
  v.co.y-=.12*math.exp(-(v.co.x/.36)**2)*max(0,1-abs(v.co.z-3.65)/1.2)
unify('Hips',pants,.065)
loft('Dark red waist sash','Hips',[(4.33,0,.0,1.94,1.22),(4.51,0,-.02,2.02,1.26),(4.69,0,.01,1.99,1.19)],sash)
patch('Hanging torn sash ends','Hips',[(.52,-1.27,4.53),(.99,-1.24,4.5),(.94,-1.15,2.83),(.67,-1.24,3.02),(.48,-1.27,3.75),(.32,-1.31,3.23),(.15,-1.30,3.57)],sash,.09)
for side,s in [('Right',-1),('Left',1)]:
 group=side+'Leg';x=s*1.65
 thigh=loft('Heavy trouser thigh',group,[(2.10,x*1.11,.02,.84,.85),(2.6,x*1.04,.05,.96,.96),(3.20,x,.10,1.0,1.03),(3.55,x*.97,.13,.92,1.01),(3.85,x*.94,.13,.78,.94),(4.10,x*.91,.13,.59,.82),(4.35,x*.87,.13,.38,.61),(4.60,x*.83,.13,.17,.34)],pants,40)
 bpy.context.view_layer.objects.active=thigh
 md=thigh.modifiers.new('Rounded hip to thigh transition','SUBSURF');md.levels=2
 bpy.ops.object.modifier_apply(modifier=md.name)
 for p in thigh.data.polygons:p.use_smooth=True
 loft('Faceted green lower leg',group,[(.38,x*1.16,-.12,.75,.76),(1.02,x*1.13,.04,.77,.79),(1.84,x*1.11,.03,.82,.83),(2.29,x*1.10,.04,.84,.83)],skin,20)
 # A closed torn hem wraps around each knee with individual uneven ends.
 vs=[]
 for j in range(2):
  for i in range(24):
   a=i*math.pi/12;z=2.38 if j==0 else 1.82+.16*math.sin(i*3.7)+.055*math.cos(i*7)
   vs.append((x*1.1+.87*math.cos(a),.04+.9*math.sin(a),z))
 faces=[(i,(i+1)%24,(i+1)%24+24,i+24) for i in range(24)]
 o=mesh('Ragged trouser cuff',group,vs,faces,pants);bpy.context.view_layer.objects.active=o;md=o.modifiers.new('Thick frayed cuff','SOLIDIFY');md.thickness=.07;bpy.ops.object.modifier_apply(modifier=md.name)
 patch('Torn knee exposing green skin',group,[(x-.30,-.887,2.65),(x-.42,-.878,2.40),(x-.14,-.895,2.28),(x+.25,-.89,2.45),(x+.15,-.898,2.79)],skin)
 foot=box('Large square bare foot',group,(x*1.18,-.48,.40),(1.93,2.28,.8),skin,.20);foot.rotation_euler.z=s*-.045

# Hammer follows the image: a long diagonal haft, widely separated grips and tall head.
hammerT=Matrix.Translation((-4.40,-2.65,2.65))@Matrix.Rotation(math.radians(-13),4,'Y')
hammerBefore=set(bpy.data.objects)
o=box('Long thick hardwood handle','Hammer',(4.05,0,0),(9.05,.55,.59),wood,.10)
for x in [3.8,4.35,4.9,5.45,6.0,6.55,7.1,7.65]:box('Dark wrapped handle grip','Hammer',(x,0,0),(.24,.64,.68),strapmat,.045)
box('Heavy rectangular forged hammer head','Hammer',(0,0,0),(3.10,2.25,4.42),iron,.25)
for x in [-1.40,1.40]:box('Chipped broad hammer edge','Hammer',(x,0,0),(.31,2.31,4.29),ironEdge,.13)
for z in [-2.04,2.04]:box('Hammer bevel reinforcement','Hammer',(0,0,z),(2.85,2.31,.20),ironEdge,.075)
box('Hammer front center plate','Hammer',(.04,-1.15,0),(.64,.16,.85),ironEdge,.055)
box('Hammer center plate inset','Hammer',(.04,-1.24,0),(.39,.055,.54),iron,.03)
for x,z in [(-1.1,1.5),(.94,-1.6),(.44,1.97),(-.85,-.78),(.89,.73)]:
 line('Thin crooked iron scuff','Hammer',[(x,-1.134,z),(x+.17,-1.141,z-.13),(x+.06,-1.136,z-.40)],.019,ironEdge)
for x,z in [(-.76,-1.75),(-.44,-1.45),(.84,1.6)]:patch('Sparse old stain on hammer','Hammer',[(x,-1.148,z),(x+.23,-1.151,z+.13),(x+.41,-1.149,z-.06),(x+.20,-1.151,z-.23),(x-.12,-1.148,z-.16)],rust)
for i in range(7):line('Long wood wear','Hammer',[(2.0+i*.85,-.282,-.10),(2.55+i*.85,-.283,-.08)],.012,woodLight)
for o in set(bpy.data.objects)-hammerBefore:o.matrix_world=hammerT@o.matrix_world

# Closed hands are constructed around the actual rectangular shaft section.
grips={'Right':2.72,'Left':8.05}
wrists={}
for side,s in [('Right',-1),('Left',1)]:
 g=grips[side];center=hammerT@Vector((g,0,0));group=side+'Hand'
 new=set(bpy.data.objects)
 # The overhand palm is outside the shaft, with no wooden bar through its mass.
 palmY=-.43 if side=='Left' else .43
 box('Closed grip palm',group,(g,palmY,.22),(1.36,.38,.89),skin,.16)
 # Both wrists approach from above and behind, aligned with the forearm.
 tube('Integrated wrist and metacarpals',group,[(g,.30,1.18),(g,.25,.92),(g,palmY*.45,.65),(g,palmY,.36)],[(.47,.47),(.48,.47),(.57,.40),(.60,.30)],skin,24)
 for i in range(4):
  x=g+(i-1.5)*.30
  outline=[(-.43,.25),(-.40,.395),(-.20,.395),(.20,.395),(.43,.23),(.43,-.20),(.23,-.355),(-.20,-.355),(-.40,-.21)]
  if side=='Right':outline=[(-y,z) for y,z in outline]
  pts=[(x,y,z) for y,z in outline]
  tube('Closed finger contacting haft',group,pts,[.18,.18,.18,.18,.18,.175,.17,.17,.16],skin,12)
 # Both requested thumbs now sit on the -X side of their respective hands.
 thumbY=-1 if side=='Left' else 1
 tube('Opposed thumb on corrected side',group,[(g-.55,thumbY*.42,.54),(g-.73,thumbY*.30,.33),(g-.75,0,.10),(g-.64,-thumbY*.31,.05)],[.24,.24,.23,.18],skin,16)
 unify(group,skin,.035)
 for o in groups[group]:o.matrix_world=hammerT@o.matrix_world
 wrists[side]=hammerT@Vector((g,.30,1.03))

# Anatomical masses are simple rounded forms, with short elbows and weighty wrists.
for side,s in [('Right',-1),('Left',1)]:
 shoulder=Vector((s*2.92,.02,9.13));elbow=Vector((s*3.61,-.08,6.87));wrist=wrists[side]
 tube('Muscular deltoid biceps and triceps',side+'UpperArm',[shoulder+Vector((-s*.30,0,1.10)),shoulder+Vector((-s*.15,0,.82)),shoulder+Vector((0,0,.34)),shoulder,shoulder.lerp(elbow,.28),shoulder.lerp(elbow,.52)+Vector((0,-.14,0)),shoulder.lerp(elbow,.76)+Vector((0,-.08,0)),elbow+Vector((0,0,.15)),elbow-Vector((0,0,.20))],[(.22,.24),(.85,.85),(1.22,1.10),(1.18,1.10),(1.13,1.09),(1.22,1.23),(1.01,1.05),(.81,.83),(.68,.71)],skin,32)
 tube('Muscular forearm with tapered tendons',side+'Forearm',[elbow+Vector((0,0,.24)),elbow,elbow.lerp(wrist,.20)+Vector((s*.06,0,0)),elbow.lerp(wrist,.36)+Vector((s*.10,0,0)),elbow.lerp(wrist,.62),elbow.lerp(wrist,.86),wrist,(wrist+(wrist-elbow).normalized()*.08)],[(.68,.70),(.79,.82),(1.02,1.03),(1.07,1.01),(.84,.88),(.61,.60),(.48,.48),(.46,.46)],skin,32)
 # Continuous asymmetric muscle contour: a front biceps belly and rear triceps sweep.
 upper=groups[side+'UpperArm'][-1]
 for v in upper.data.vertices:
  if 7.2<v.co.z<8.85:
   front=max(0,min(1,-v.co.y/.7));back=max(0,min(1,v.co.y/.7))
   v.co.y-=.20*front*math.exp(-((v.co.z-7.98)/.48)**2)
   v.co.y+=.19*back*math.exp(-((v.co.z-8.30)/.65)**2)
 unify(side+'UpperArm',skin,.050)
 unify(side+'Forearm',skin,.045)
 # Surface-only angular stain patches, no open wounds or volume cut-outs.
 a=shoulder+Vector((s*.34,-1.07,.54))
 patch('Battered shoulder stain',side+'UpperArm',[(a.x-.23,a.y,a.z+.35),(a.x+.12,a.y-.01,a.z+.29),(a.x+.24,a.y+.02,a.z-.08),(a.x+.14,a.y-.005,a.z-.48),(a.x-.07,a.y-.01,a.z-.35),(a.x-.16,a.y-.01,a.z+.08)],rust)
 if s==1:
  a=elbow.lerp(wrist,.45)+Vector((.0,-.94,.06));patch('Forearm dark paint scrape',side+'Forearm',[(a.x-.20,a.y,a.z+.32),(a.x+.14,a.y,a.z+.24),(a.x+.26,a.y,a.z-.02),(a.x+.05,a.y,a.z-.18),(a.x-.09,a.y,a.z-.48),(a.x-.10,a.y,a.z-.05)],rust)

# Belly detail: inset navel and subtle folds, sparse asymmetric painted wear.
ellipsoid('Small recessed belly button','Torso',(0,-2.59,5.86),(.22,.045,.27),skinDark,12,8)
ellipsoid('Navel shadow','Torso',(0,-2.625,5.86),(.10,.012,.15),black,10,6)
for x,z in [(-1.52,6.74),(1.35,5.98)]:
 y=-.71-1.88*math.sqrt(max(.01,1-(x/2.55)**2-((z-6.36)/2.155)**2))-.025
 patch('Subtle dark belly scrape','Torso',[(x-.10,y+.03,z+.26),(x+.15,y,z+.16),(x+.19,y-.01,z-.01),(x+.03,y,z-.17),(x-.05,y+.02,z-.06)],rust)
# Tunic tears/stains mapped onto the actual garment surface, with irregular edges.
for coords in [[(-.98,-1.48,8.72),(-.72,-1.48,8.64),(-.81,-1.51,8.42),(-1.10,-1.5,8.49)],[(.86,-1.40,9.1),(1.10,-1.39,9.02),(.98,-1.44,8.78),(.78,-1.43,8.96)]]:patch('Old stain in torn fabric','Torso',coords,rust)

# Review rig uses mesh-parent controls in the exact reference stance. The rejected
# first-pass motion is deliberately not applied to these changed proportions.
from mathutils.bvhtree import BVHTree
bodyBVH=BVHTree.FromPolygons([bodySkin.matrix_world@v.co for v in bodySkin.data.vertices],[list(p.vertices) for p in bodySkin.data.polygons])
samples=[shirt.matrix_world@v.co for v in shirt.data.vertices]
samples.extend(shirt.matrix_world@p.center for p in shirt.data.polygons)
distances=[]
for point in samples:
 loc,n,index,d=bodyBVH.find_nearest(point)
 distances.append(d if (point-loc).dot(n)>=0 else -d)
(OUT/'garment-fit-checks.json').write_text(json.dumps({'sampleCount':len(samples),'minSignedSkinClearance':min(distances),'insideSkinSamples':sum(d<0 for d in distances),'shoulderCapRadiiUnchanged':[1.22,1.10],'trapeziusTop':10.86,'upperBackHalfWidth':3.15,'upperBackHalfDepth':1.62},indent=2))
rig=bpy.data.objects.new('Boss_REFERENCE_RIG',None);scene.collection.objects.link(rig);rig.empty_display_type='PLAIN_AXES'
controls={}
for group,obs in groups.items():
 control=bpy.data.objects.new(group+'_CTRL',None);scene.collection.objects.link(control);control.parent=rig;control.empty_display_size=.22;controls[group]=control
 for o in obs:o.parent=control
rig['Reference']='ChatGPT Image Sep 23, 2026, 01_23_51 PM.png'
rig['Revision']='Reference-led geometry rebuild; wide closed grips; 9.05 unit haft'

# Archive an editable mesh-only export and an actual, grounded Blender comparison render.
bpy.ops.object.select_all(action='DESELECT')
for obs in groups.values():
 for o in obs:o.select_set(True)
bpy.context.view_layer.objects.active=groups['Torso'][0]
bpy.ops.export_scene.fbx(filepath=str(OUT/'ReferenceBoss.fbx'),use_selection=True,object_types={'MESH'},bake_anim=False,axis_forward='-Z',axis_up='Y')

floorMat=mat('Neutral slate stage',(.11,.14,.13),.06)
bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object;floor.name='RENDER_STAGE_ONLY';floor.location.z=-.025;floor.data.materials.append(floorMat)
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
for loc,energy,size in [((-8,-10,16),1900,7),((8,-6,13),1100,7),((1,7,14),2200,6)]:
 bpy.ops.object.light_add(type='AREA',location=loc);l=bpy.context.object;l.data.energy=energy;l.data.shape='DISK';l.data.size=size;aim(l,(0,0,6))
scene.world=bpy.data.worlds.new('Soft daylight');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.62,.70,.8,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.42
bpy.ops.object.camera_add(location=(.4,-30,11));cam=bpy.context.object;cam.name='Reference comparison camera';cam.data.type='ORTHO';cam.data.ortho_scale=15.7;aim(cam,(-.7,0,6.05));scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=True;scene.render.resolution_x=1086;scene.render.resolution_y=1448;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'ReferenceBoss_Front.png')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ReferenceBoss.blend'));bpy.ops.render.render(write_still=True)
cam.location=(13,-27,11);aim(cam,(0,0,6));cam.data.ortho_scale=14.7;scene.render.filepath=str(OUT/'ReferenceBoss_ThreeQuarter.png');bpy.ops.render.render(write_still=True)
cam.location=(24,0,10);aim(cam,(0,0,6));scene.render.filepath=str(OUT/'ReferenceBoss_Side.png');bpy.ops.render.render(write_still=True)
manifest={'height':11.92,'hammerHandleLength':9.05,'gripSeparation':grips['Left']-grips['Right'],'groups':list(groups),'objects':sum(len(o) for o in groups.values()),'referencePose':True,'animationStatus':'Rebuild requires fresh animation retargeting; prior clips are not validated for this mesh'}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2));print('REFERENCE_REBUILD_COMPLETE',json.dumps(manifest))
