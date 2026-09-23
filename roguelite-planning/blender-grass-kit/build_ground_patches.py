"""Broad low meadow islands, separate from upright tufts. Background Blender only."""
from pathlib import Path
SOURCE=Path(__file__).resolve().parent
# Reuse the native blade geometry and swatch material, without running tuft exports.
exec((SOURCE/'build_grass.py').read_text().split('specs=')[0])
OUT=SOURCE/'ground-patches'; OUT.mkdir(exist_ok=True)
atlas.filepath_raw=str(OUT/'GrassPalette.png'); atlas.save()
random.seed(2245)
specs=[('GroundPatch_Small',4,3,95,0),('GroundPatch_Round',6,4.7,210,1),('GroundPatch_Broad',9,5.7,340,2),('GroundPatch_Long',11,4,290,3)]
assets=[]; report=[]
for name,rx,ry,count,seed in specs:
    def boundary(a): return 1+.105*math.sin(3*a+seed)+.085*math.sin(5*a+seed*1.7)+.045*math.sin(9*a+.5)
    def level(r,a): return .025+.19*(1-r*r)+.055*math.sin(a*3+seed)*(1-r)
    clusters=[]
    for i in range(count):
        a=random.uniform(0,math.tau); r=math.sqrt(random.random())*.985; b=boundary(a)
        clusters.append((rx*r*b*math.cos(a),ry*r*b*math.sin(a),random.uniform(.25,.53)*(1.15-.3*r),random.choice([2,3,3,4]),.075))
    blades=mesh(name,clusters)
    for v in blades.data.vertices:
        a=math.atan2(v.co.y/ry,v.co.x/rx); r=min(1,math.sqrt((v.co.x/rx)**2+(v.co.y/ry)**2)/boundary(a))
        v.co.z+=level(r,a)
    vertices=[(0,0,level(0,0))]; faces=[]; N=64; R=6
    for ring in range(1,R+1):
        r=ring/R
        for j in range(N):
            a=math.tau*j/N; b=boundary(a)
            vertices.append((rx*r*b*math.cos(a),ry*r*b*math.sin(a),level(r,a)))
    for j in range(N): faces.append((0,1+j,1+(j+1)%N))
    for ring in range(R-1):
        for j in range(N):
            a=1+ring*N+j; b=1+ring*N+(j+1)%N; c=a+N; d=b+N
            faces.extend([(a,c,d),(a,d,b)])
    data=bpy.data.meshes.new(name+'_MeadowSurface'); data.from_pydata(vertices,[],faces); data.update()
    base=bpy.data.objects.new(name+'_Surface',data); bpy.context.collection.objects.link(base); data.materials.append(mat)
    uv=data.uv_layers.new(name='Palette')
    for p in data.polygons:
        c=p.center; shade=2 if math.sin(c.x*.8+seed)+math.sin(c.y*1.1)<.2 else 3
        for li in p.loop_indices: uv.data[li].uv=((shade+.5)/6,.5)
    bpy.ops.object.select_all(action='DESELECT'); base.select_set(True); blades.select_set(True); bpy.context.view_layer.objects.active=blades; bpy.ops.object.join()
    bm=bmesh.new(); bm.from_mesh(blades.data); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(blades.data); bm.free()
    reduce=blades.modifiers.new('Ground cover simplification','DECIMATE'); reduce.ratio=.38
    bpy.ops.object.modifier_apply(modifier=reduce.name)
    tri=blades.modifiers.new('Stable export triangles','TRIANGULATE'); bpy.ops.object.modifier_apply(modifier=tri.name)
    bm=bmesh.new(); bm.from_mesh(blades.data)
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.calc_area()<1e-8],context='FACES')
    bm.to_mesh(blades.data); bm.free(); blades.data.update()
    blades.data.calc_loop_triangles(); bpy.context.view_layer.update()
    report.append({'name':name,'dimensions':list(blades.dimensions),'triangles':len(blades.data.loop_triangles),'origin':'ground center'})
    bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH'},path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),use_selection=True,export_format='GLB')
    assets.append(blades)
for i,ob in enumerate(assets): ob.location=((i%2)*23,(i//2)*16,0)
bpy.ops.object.select_all(action='DESELECT')
for ob in assets: ob.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'GroundGrassPatches.fbx'),use_selection=True,object_types={'MESH'},path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
(OUT/'manifest.json').write_text(json.dumps(report,indent=2))
ground=bpy.data.materials.new('Preview warm earth'); ground.diffuse_color=(.52,.43,.25,1)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.035)); bpy.context.object.data.materials.append(ground)
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=24
scene.world=bpy.data.worlds.new('Daylight'); scene.world.use_nodes=True; bg=scene.world.node_tree.nodes.get('Background'); bg.inputs['Color'].default_value=(.78,.87,1,1); bg.inputs['Strength'].default_value=.8
bpy.ops.object.light_add(type='AREA',location=(0,-5,30)); bpy.context.object.data.energy=4800; bpy.context.object.data.size=22
bpy.ops.object.camera_add(location=(25,-28,46)); camera=bpy.context.object; camera.rotation_euler=(Vector((11,8,0))-camera.location).to_track_quat('-Z','Y').to_euler(); camera.data.type='ORTHO'; camera.data.ortho_scale=49; scene.camera=camera
scene.render.resolution_x=1500; scene.render.resolution_y=1050; scene.render.resolution_percentage=100; scene.view_settings.view_transform='AgX'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'GroundGrassPatches.blend'))
scene.render.filepath=str(OUT/'GroundGrassPatchesPreview.png'); bpy.ops.render.render(write_still=True)
print('GROUND_PATCHES_COMPLETE')
