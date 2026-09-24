import bpy, json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
for kind,offset in [('Baby',-3.9),('Mutant',1.3)]:
    names=json.loads((OUT/kind/'manifest.json').read_text())['sections']+[kind+'Zombie_Rig']
    with bpy.data.libraries.load(str(OUT/kind/'Model.blend'),link=False) as (src,dst):
        dst.objects=[n for n in src.objects if n in names]
    for o in dst.objects:
        if o is not None:
            scene.collection.objects.link(o)
            if o.type=='ARMATURE':o.location.x=offset
bpy.ops.mesh.primitive_plane_add(size=200)
floor=bpy.context.object
fm=bpy.data.materials.new('Warm gray stage');fm.use_nodes=True
fm.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.23,.22,.20,1)
fm.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.95
floor.data.materials.append(fm);floor.location.z=-.015
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
for loc,power,size in [((-7,-9,13),2100,8),((7,-5,8),1250,7),((2,5,11),1800,6)]:
    bpy.ops.object.light_add(type='AREA',location=loc);l=bpy.context.object
    l.data.energy=power;l.data.shape='DISK';l.data.size=size;aim(l,(0,0,4))
scene.world=bpy.data.worlds.new('Studio environment');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.59,.64,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.55
bpy.ops.object.camera_add(location=(12,-32,13))
cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=13.4
aim(cam,(-.45,0,4.1));scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=1600;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(OUT/'ModelPreview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ModelPreview.blend'))
bpy.ops.render.render(write_still=True)
