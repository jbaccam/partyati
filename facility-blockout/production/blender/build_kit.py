"""Author reusable facility meshes in Blender; never alter unrelated scene objects."""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector, Matrix
DEST=Path(r'C:/Users/Jeremiah/Documents/ChatGPT/Roblox/facility-blockout/production')
scene=bpy.data.scenes.get('FacilityProduction') or bpy.data.scenes.new('FacilityProduction')
bpy.context.window.scene=scene
scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=0.28
collection=bpy.data.collections.get('Facility_ModularKit')
if collection is None:
    collection=bpy.data.collections.new('Facility_ModularKit');scene.collection.children.link(collection)
palette=[(84,95,87),(96,68,40),(108,68,42),(49,75,39),(72,95,47),(172,168,145),(35,42,37),(81,68,49)]
mats=[]
for i,c in enumerate(palette):
    m=bpy.data.materials.get('FacilitySwatch'+str(i)) or bpy.data.materials.new('FacilitySwatch'+str(i));m.diffuse_color=tuple(v/255 for v in c)+(1,);mats.append(m)
image=bpy.data.images.get('FacilityPalette') or bpy.data.images.new('FacilityPalette',width=512,height=512)
rng=random.Random(2731);pixels=[]
for y in range(512):
    for x in range(512):
        idx=(y//256)*4+x//128;col=palette[idx]
        grain=math.sin(x*.51+math.sin(y*.04)*2)*.025 if idx in (1,7) else 0
        n=rng.uniform(-.027,.027)+grain
        pixels.extend([max(.001,min(1,v/255+n)) for v in col]+[1])
image.pixels=pixels;image.filepath_raw=str(DEST/'exports'/'FacilityPalette.png');image.file_format='PNG';image.save()
surface=bpy.data.materials.get('FacilityAtlas') or bpy.data.materials.new('FacilityAtlas');surface.use_nodes=True
nodes=surface.node_tree.nodes;bs=nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.83
tex=nodes.get('FacilityAtlasImage') or nodes.new('ShaderNodeTexImage');tex.name='FacilityAtlasImage';tex.image=image;surface.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
parts=[]
def adopt(o,mat):
    for c in list(o.users_collection): c.objects.unlink(o)
    collection.objects.link(o);o.data.materials.append(mats[mat]);parts.append(o);return o
def cube(loc,dim,mat=0,bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=dim
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('ManufacturedEdge','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
    return adopt(o,mat)
def rod(a,b,r,mat=0,verts=10):
    a,b=Vector(a),Vector(b);d=b-a
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d.length,location=(a+b)/2)
    o=bpy.context.object;o.rotation_mode='QUATERNION';o.rotation_quaternion=d.to_track_quat('Z','Y');bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    for p in o.data.polygons:p.use_smooth=True
    return adopt(o,mat)
def mesh(name,verts,faces,mat):
    d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update();o=bpy.data.objects.new(name,d);collection.objects.link(o);o.data.materials.append(mats[mat]);parts.append(o);return o
def finish(name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False) if hasattr(bpy.ops.mesh,'normals_make_consistent') else None
    bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.015);bpy.ops.object.mode_set(mode='OBJECT')
    uv=o.data.uv_layers.active.data
    for poly in o.data.polygons:
        mi=int(o.data.materials[poly.material_index].name.replace('FacilitySwatch',''))
        for li in poly.loop_indices:
            u,v=uv[li].uv;uv[li].uv=((mi%4+.03+u*.94)/4,(mi//4+.02+v*.96)/2)
        poly.material_index=0
    o.data.materials.clear();o.data.materials.append(surface)
    mod=o.modifiers.new('ExportTriangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=mod.name)
    o['FacilityAsset']=name;o['Units']='1 Blender unit = 1 Roblox stud';o['Pivot']='floor center';o['Snap']=.5
    parts.clear();return o
def export(objects,filename):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.fbx(filepath=str(DEST/'exports'/filename),use_selection=True,object_types={'MESH'},apply_unit_scale=True,bake_space_transform=True,axis_forward='-Z',axis_up='Y',bake_anim=False,path_mode='COPY',embed_textures=True,use_triangles=True)

assets=[]
if not bpy.data.objects.get('DiningBenchSet'):
    cube((0,0,3.3),(24,5.7,.3),1,.12)
    for y in (-4.5,4.5):cube((0,y,1.82),(24,1.65,.25),1,.12)
    for x in (-8.4,8.4):
        for y in (-2,2):
            rod((x,y,.2),(x,y,3.12),.13)
            rod((x,y,2.7),(x,0,1.25),.11)
        rod((x,-5,.22),(x,5,.22),.16)
        for y in (-4.5,4.5):rod((x,y,.25),(x,y,1.72),.14)
        rod((x,-4.5,1.6),(x,4.5,1.6),.12)
        for y in (-4.9,4.9):cube((x,y,.12),(.65,.65,.24),6,.06)
    for y in (-2.2,2.2):rod((-10,y,3),(10,y,3),.1)
    assets.append(finish('DiningBenchSet'))
if not bpy.data.objects.get('ChainLink'):
    vs=[];fs=[]
    for i in range(28):
        a=math.tau*i/28;center=Vector((.65*math.cos(a),.33*math.sin(a),.15));normal=Vector((math.cos(a),math.sin(a),0))
        for j in range(8):
            b=math.tau*j/8;v=center+normal*(.135*math.cos(b))+Vector((0,0,.135*math.sin(b)));vs.append(tuple(v))
    for i in range(28):
        for j in range(8):fs.append((i*8+j,((i+1)%28)*8+j,((i+1)%28)*8+(j+1)%8,i*8+(j+1)%8))
    o=mesh('OvalForgedLink',vs,fs,2)
    for p in o.data.polygons:p.use_smooth=True
    assets.append(finish('ChainLink'))
if not bpy.data.objects.get('VentGrille'):
    for x in (-3.05,3.05):cube((x,0,1.9),(.2,.45,3.8),0)
    for z in (.12,3.68):cube((0,0,z),(6.2,.45,.24),0)
    for i in range(8):
        o=cube((0,-.02,.48+i*.39),(5.85,.5,.12),0,.02);o.rotation_euler.x=math.radians(28)
    for x in (-2.85,2.85):
        for z in (.3,3.5):rod((x,-.3,z),(x,-.22,z),.095,2,12)
    assets.append(finish('VentGrille'))
if not bpy.data.objects.get('LeafyShrub'):
    rng=random.Random(816);vs=[];faces=[]
    rod((0,0,0),(0,0,1.6),.1,7)
    for b in range(18):
        a=b*2.399;end=Vector((math.cos(a)*rng.uniform(1.2,2.6),math.sin(a)*rng.uniform(1.2,2.4),rng.uniform(1.4,3.5)))
        rod((0,0,.45),end,.036,7,7)
        for j in range(28):
            pos=end+Vector((rng.uniform(-.6,.6),rng.uniform(-.6,.6),rng.uniform(-.55,.55)))
            axis=Vector((rng.uniform(-1,1),rng.uniform(-1,1),rng.uniform(-.4,1))).normalized();side=axis.cross(Vector((0,0,1))).normalized();le=rng.uniform(.35,.65);wi=le*.35;idx=len(vs)
            vs += [tuple(pos-axis*le*.5),tuple(pos+side*wi),tuple(pos+Vector((0,0,.065))),tuple(pos-side*wi),tuple(pos+axis*le*.5)]
            faces += [(idx,idx+1,idx+2),(idx+1,idx+4,idx+2),(idx+4,idx+3,idx+2),(idx+3,idx,idx+2)]
    leaf=mesh('IndividualLeaves',vs,faces,3)
    for p in leaf.data.polygons:
        if p.index%7==0:p.material_index=1
    leaf.data.materials.append(mats[4]);assets.append(finish('LeafyShrub'))
for o in assets:export([o],o.name+'.fbx')
batch=[]
for i,o in enumerate(assets):
    d=o.copy();d.data=o.data;collection.objects.link(d);d.name=o.name+'_Batch';d.location.x=i*32;batch.append(d)
if batch:export(batch,'RepresentativeBatch.fbx')
for o in batch:bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=str(DEST/'blender'/'Facility_ModularKit.blend'))
result={'assets':[{'name':o.name,'vertices':len(o.data.vertices),'triangles':len(o.data.polygons),'dimensions':list(o.dimensions)} for o in assets],'batch':str(DEST/'exports'/'RepresentativeBatch.fbx')}
