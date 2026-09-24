"""Update only bowling material in the current full import derivative."""
import bpy
from pathlib import Path

P = Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(P / 'Weapon_Showcase_Corrected.blend'))
ball = bpy.data.objects['W22_Bowling_Ball']
black = ((17 / 255 + .055) / 1.055) ** 2.4
material = bpy.data.materials.new('Bowling | uniform black, lighting-only sockets')
material.use_nodes = True
material.diffuse_color = (black, black, black, 1)
shader = material.node_tree.nodes.get('Principled BSDF')
shader.inputs['Base Color'].default_value = (black, black, black, 1)
shader.inputs['Roughness'].default_value = .3
ball.data.materials.clear()
ball.data.materials.append(material)
for face in ball.data.polygons:
    face.material_index = 0
# Replace the old correction atlas too, for reproducible legacy import scripts.
atlas = bpy.data.images.new('Bowling_Uniform_Black', width=320, height=320, alpha=False)
atlas.pixels.foreach_set([17/255, 17/255, 17/255, 1] * (320 * 320))
atlas.filepath_raw = str(P / 'textures/Bowling_Charcoal_Corrected.png')
atlas.file_format = 'PNG'
atlas.save()
bpy.ops.object.select_all(action='DESELECT')
for obj in bpy.data.objects:
    if obj.type in {'MESH', 'ARMATURE'}:
        obj.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(P / 'Weapon_Showcase_Corrected.blend'))
bpy.ops.export_scene.fbx(filepath=str(P / 'Weapon_Showcase_Corrected.fbx'), use_selection=True,
    object_types={'MESH', 'ARMATURE'}, add_leaf_bones=False, bake_anim=False,
    path_mode='COPY', embed_textures=True, axis_forward='-Z', axis_up='Y')
assert all(p.material_index == 0 for p in ball.data.polygons)
assert not any(n.type == 'TEX_IMAGE' for n in material.node_tree.nodes)
print('Bowling black material verified; geometry preserved.')
