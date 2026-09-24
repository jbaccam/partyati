from pathlib import Path
p=Path('roguelite-planning/hammer-boss/reference_rebuild.py').resolve()
s=p.read_text().replace('bpy.ops.render.render(write_still=True)','None')
exec(compile(s,str(p),'exec'),{'__file__':str(p)})
import bpy
bpy.context.scene.render.resolution_percentage=60
bpy.context.scene.camera.location=(.4,-30,11)
from mathutils import Vector
cam=bpy.context.scene.camera;cam.rotation_euler=(Vector((-.7,0,6.05))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=16.2
bpy.context.scene.render.filepath=str(p.parent/'reference-rebuild/GripCorrection.png')
bpy.ops.render.render(write_still=True)
