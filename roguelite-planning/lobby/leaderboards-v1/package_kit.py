"""Pack the six leaderboard meshes into one FBX for a single Studio 3D Importer pass.
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python package_kit.py

All meshes keep the shared board origin, so the imported Model preserves their relative placement;
InstallLeaderboards.luau reads that placement to detect any importer turn before fitting them.
"""
import bpy, json
from pathlib import Path
ROOT = Path(__file__).resolve().parent
meta = json.loads((ROOT / 'metadata.json').read_text())
names = [m['name'] for m in meta['meshes']]
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(str(ROOT / 'LeaderboardsV1.blend'), link=False) as (src, dst):
    missing = [n for n in names if n not in src.objects]
    assert not missing, missing
    dst.objects = names
for o in dst.objects:
    bpy.context.collection.objects.link(o); o.hide_viewport = False; o.hide_render = False; o.select_set(True)
    assert tuple(o.location) == (0, 0, 0), (o.name, tuple(o.location))
bpy.ops.export_scene.fbx(filepath=str(ROOT / 'exports/fbx/Lobby_Leaderboards_V1.fbx'), use_selection=True, object_types={'MESH'},
                         axis_forward='-Z', axis_up='Y', path_mode='COPY', embed_textures=True, add_leaf_bones=False)
print('packed', names)
