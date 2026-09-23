"""Original low-poly grass, built in a separate background Blender process."""
import bpy, bmesh, math, random, json
from pathlib import Path
from mathutils import Vector
OUT = Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(9216)
palette = [(0.19,.29,.085),(.25,.36,.105),(.32,.43,.13),(.39,.49,.17),(.45,.55,.21),(.34,.44,.14)]
# Tiny original swatch atlas: one portable texture/material for every mesh.
atlas=bpy.data.images.new('GrassPalette',width=96,height=16)
atlas.pixels=[v for y in range(16) for x in range(96) for v in (*palette[x//16],1)]
atlas.filepath_raw=str(OUT/'GrassPalette.png'); atlas.file_format='PNG'; atlas.save(); atlas.pack()
mat=bpy.data.materials.new('Matte grass palette'); mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF'); bs.inputs['Roughness'].default_value=.94; bs.inputs['Specular IOR Level'].default_value=.12
t=mat.node_tree.nodes.new('ShaderNodeTexImage'); t.image=atlas; t.interpolation='Closest'; mat.node_tree.links.new(t.outputs['Color'],bs.inputs['Base Color'])
def mesh(name,clusters):
    verts=[]; faces=[]; shades=[]
    for cx,cy,height,count,radius in clusters:
        for k in range(count):
            a=random.uniform(0,math.tau); r=radius*math.sqrt(random.random())
            x=cx+math.cos(a)*r; y=cy+math.sin(a)*r
            h=height*random.uniform(.65,1.2); w=h*random.uniform(.10,.18)
            lean=h*random.uniform(.20,.48); a+=random.uniform(-.5,.5)
            along=Vector((math.cos(a),math.sin(a),0)); side=Vector((-math.sin(a),math.cos(a),0))
            base=Vector((x,y,0)); start=len(verts)
            # Three diamond cross sections and a tip give real thickness and folded faces.
            for z,width,bend in [(0,.56,0),(.43,1,.17),(.77,.54,.53)]:
                center=base+along*lean*bend+Vector((0,0,h*z))
                for offset in [side*w*width,along*w*.19*width,-side*w*width,-along*w*.19*width]: verts.append(tuple(center+offset))
            verts.append(tuple(base+along*lean+Vector((0,0,h))))
            faces.append(tuple(start+i for i in (3,2,1,0))); shades.append(0)
            color=random.choice([1,1,2,2,3])
            for row in range(2):
                for j in range(4):
                    faces.append((start+row*4+j,start+row*4+(j+1)%4,start+(row+1)*4+(j+1)%4,start+(row+1)*4+j)); shades.append(min(5,color+row))
            for j in range(4): faces.append((start+8+j,start+8+(j+1)%4,start+12)); shades.append(min(4,color+1))
    data=bpy.data.meshes.new(name); data.from_pydata(verts,[],faces); data.update()
    ob=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(ob); data.materials.append(mat)
    uv=data.uv_layers.new(name='Palette')
    for p,c in zip(data.polygons,shades):
        for li in p.loop_indices: uv.data[li].uv=((c+.5)/6,.5)
    bm=bmesh.new(); bm.from_mesh(data); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(data); bm.free()
    return ob
specs=[('01_SmallTuft',[(0,0,.85,7,.16)]),('02_TallTuft',[(0,0,1.65,11,.24)]),('03_WideTuft',[(-.35,0,1.05,7,.23),(.35,.1,.8,6,.22)]),('04_MeadowClump',[(-.65,0,1.2,9,.32),(.15,.3,1.6,10,.3),(.7,-.22,1,7,.25)]),('05_LargePatch',[(-1.7,.2,.9,7,.35),(-.8,.55,1.35,10,.4),(.2,.2,1.7,11,.35),(1.15,.45,1.2,8,.32),(.65,-.65,.85,7,.3),(-.65,-.6,.8,7,.3)]),('06_SpreadingPatch',[(-2.1,.1,.75,7,.4),(-1.25,.65,1.1,8,.35),(-.35,.3,1.35,10,.4),(.5,.8,.9,7,.3),(1.5,.55,1.2,9,.35),(2.1,-.05,.7,6,.3),(.8,-.65,.85,7,.3),(-.9,-.8,.65,6,.3)])]
assets=[]; report=[]
for name,clusters in specs:
    ob=mesh(name,clusters); assets.append(ob)
    bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); bpy.context.view_layer.objects.active=ob
    bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH'},add_leaf_bones=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),use_selection=True,export_format='GLB')
    ob.data.calc_loop_triangles()
    report.append(dict(name=name,triangles=len(ob.data.loop_triangles),vertices=len(ob.data.vertices),dimensions=list(ob.dimensions),ground_origin=True))
(OUT/'manifest.json').write_text(json.dumps(report,indent=2))
def solid(name,color):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True; p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1); p.inputs['Roughness'].default_value=.95; return m
ground=solid('Muted meadow',(.24,.32,.12)); labelmat=solid('Warm white',(.85,.88,.76))
for i,ob in enumerate(assets):
    ob.location=((i%3-1)*6,(1-i//3)*5,0)
    bpy.ops.object.text_add(location=(ob.location.x,ob.location.y-1.8,.035))
    text=bpy.context.object; text.name='Label '+ob.name; text.data.body=ob.name[3:].replace('Tuft',' TUFT').replace('Clump',' CLUMP').replace('Patch',' PATCH').upper(); text.data.align_x='CENTER'; text.data.size=.34; text.data.extrude=0; text.data.materials.append(labelmat)
bpy.ops.mesh.primitive_plane_add(size=200); bpy.context.object.name='Preview ground'; bpy.context.object.data.materials.append(ground)
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=32
scene.world=bpy.data.worlds.new('Meadow daylight'); scene.world.color=(.35,.35,.35)
scene.world.use_nodes=True; scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.7,.8,1,1); scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.7
bpy.ops.object.light_add(type='AREA',location=(-3,-4,14)); bpy.context.object.data.energy=2300; bpy.context.object.data.shape='DISK'; bpy.context.object.data.size=9
bpy.ops.object.camera_add(location=(11,-19,21)); camera=bpy.context.object; camera.rotation_euler=(Vector((0,2,0.4))-camera.location).to_track_quat('-Z','Y').to_euler(); camera.data.type='ORTHO'; camera.data.ortho_scale=22; scene.camera=camera
scene.render.resolution_x=1600; scene.render.resolution_y=1100; scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'GrassKit.blend'))
scene.render.filepath=str(OUT/'GrassKitPreview.png'); bpy.ops.render.render(write_still=True)
print('GRASS_KIT_COMPLETE '+json.dumps(report))
