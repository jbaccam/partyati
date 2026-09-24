"""Actual mesh close-up for the continuous shirt review, isolated Blender only."""
import bpy
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'Mutant/Model.blend'))
scene=bpy.context.scene
cam=scene.camera
cam.location=(10,-19,12)
cam.rotation_euler=(Vector((0,0,6.25))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.ortho_scale=7.8
scene.render.resolution_x=1100
scene.render.resolution_y=850
scene.cycles.samples=32
scene.render.filepath=str(OUT/'Mutant/ShirtReview.png')
bpy.ops.render.render(write_still=True)
