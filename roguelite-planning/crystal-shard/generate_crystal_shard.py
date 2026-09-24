"""Run with Blender --background --python generate_crystal_shard.py.
Original Astra-authored mesh. No external geometry, texture, or generated VFX.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Two irregular six-sided shoulders: tall, double-pointed and slightly asymmetric.
vertices = [(0.035, -0.025, 1.5)]
for z, radius, phase, ox in [(0.47, .51, 0.0, -.025), (-.49, .435, .16, .025)]:
    for i in range(6):
        a = i * math.tau / 6 + phase
        vertices.append((math.cos(a)*radius+ox, math.sin(a)*radius*.78,
                         z + [.075,-.045,.015,-.07,.06,-.03][i]))
vertices.append((.025,.015,-1.5))
faces=[]
for i in range(6):
    j=(i+1)%6
    faces.extend([(0,1+i,1+j),(1+i,7+i,7+j),(1+i,7+j,1+j),(13,7+j,7+i)])
mesh=bpy.data.meshes.new('CrystalShardGeometry')
mesh.from_pydata(vertices,[],faces)
mesh.update()
obj=bpy.data.objects.new('CrystalShard',mesh)
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active=obj
obj.select_set(True)
# Face normals and tiny chamfers soften the outline without losing the faceting.
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode='OBJECT')
palette=[(0.075,.36,.73,1),(.11,.51,.84,1),(.20,.67,.90,1),(.37,.79,.94,1),(.14,.57,.86,1),(.53,.85,.95,1)]
for idx,c in enumerate(palette):
    c=tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in c[:3])+(1,)
    mat=bpy.data.materials.new('PaintedAzureFacet%02d'%idx); mat.diffuse_color=c;mat.use_nodes=True
    nt=mat.node_tree; nt.nodes.clear()
    out=nt.nodes.new('ShaderNodeOutputMaterial'); bs=nt.nodes.new('ShaderNodeBsdfPrincipled')
    bs.inputs['Roughness'].default_value=.43
    tex=nt.nodes.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=2.7;tex.inputs['Detail'].default_value=1.0
    ramp=nt.nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position=.2;ramp.color_ramp.elements[1].position=.8
    ramp.color_ramp.elements[0].color=tuple(x*.83 for x in c[:3])+(1,)
    ramp.color_ramp.elements[1].color=tuple(min(1,x*1.045) for x in c[:3])+(1,)
    nt.links.new(tex.outputs['Fac'],ramp.inputs[0]);nt.links.new(ramp.outputs[0],bs.inputs['Base Color']);nt.links.new(bs.outputs[0],out.inputs[0])
    mesh.materials.append(mat)
for p in mesh.polygons: p.material_index=[3,0,1,4,2,1,0,3,4,2,3,1,4,2,1,0,5,2,1,4,2,0,4,3][p.index]
bevel=obj.modifiers.new('Soft edge chamfer','BEVEL');bevel.width=.012;bevel.segments=1
bpy.ops.object.modifier_apply(modifier=bevel.name)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.035);bpy.ops.object.mode_set(mode='OBJECT')

# Bake the broad painterly color into one portable base-color texture.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1
img=bpy.data.images.new('CrystalShard_BaseColor',width=512,height=512,alpha=False)
for mat in obj.data.materials:
    nt=mat.node_tree;n=nt.nodes.new('ShaderNodeTexImage');n.image=img;nt.nodes.active=n;n.select=True
scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True;scene.render.bake.margin=8
bpy.ops.object.bake(type='DIFFUSE')
img.filepath_raw=str(OUT/'CrystalShard_BaseColor.png');img.file_format='PNG';img.save()
mat=bpy.data.materials.new('CrystalShard_PaintedAzure');mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.43
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=img
mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
obj.data.materials.clear();obj.data.materials.append(mat)
for p in obj.data.polygons:p.material_index=0
tri=obj.modifiers.new('Portable triangulation','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=tri.name)
bpy.ops.export_scene.gltf(filepath=str(OUT/'CrystalShard.glb'),export_format='GLB',use_selection=True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'CrystalShard.fbx'),use_selection=True,object_types={'MESH'},apply_unit_scale=True,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)

# Matching, upload-free fallback data in Roblox's Y-up coordinates.
data={'vertices':[[round(x,6),round(z,6),round(-y,6)] for x,y,z in vertices],
      'faces':[[i+1 for i in f] for f in faces],
      'colors':[[round(c*255) for c in palette[p%len(palette)][:3]] for p in [3,0,1,4,2,1,0,3,4,2,3,1,4,2,1,0,5,2,1,4,2,0,4,3]]}
(OUT/'CrystalShardGeometry.json').write_text(json.dumps(data,indent=2))

def point_at(ob,where): ob.rotation_euler=(Vector(where)-ob.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(4,-7,2.4));camera=bpy.context.object;point_at(camera,(0,0,0));camera.data.type='ORTHO';camera.data.ortho_scale=4.25;scene.camera=camera
for name,pos,power,size in [('Key',(-3,-4,6),500,5),('Fill',(4,-1,3),330,4),('Rim',(1,4,3),450,3)]:
    bpy.ops.object.light_add(type='AREA',location=pos);light=bpy.context.object;light.name=name;light.data.energy=power;light.data.shape='DISK';light.data.size=size;point_at(light,(0,0,0))
scene.world.color=(.15,.15,.15)
scene.render.engine='CYCLES';scene.cycles.samples=48
scene.render.resolution_x=900;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.film_transparent=True
scene.view_settings.view_transform='Standard'
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'CrystalShard_Preview.png')
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
img.pack();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CrystalShard.blend'))
bpy.ops.render.render(write_still=True)
assert len(obj.data.vertices)<1000
print('CRYSTAL_SHARD_COMPLETE',json.dumps({'vertices':len(obj.data.vertices),'triangles':len(obj.data.polygons),'dimensions':list(obj.dimensions),'output':str(OUT)}))
