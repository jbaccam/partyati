import bpy,json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
OUT=Path(__file__).resolve().parent/'reference-rebuild'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'ReferenceBoss.blend'))
s=bpy.context.scene;cam=s.camera
s.render.resolution_percentage=70;s.cycles.samples=24
views=[('LeftGrip_Front',(6,-12,7),(3.45,-2.65,5.35),4.4),('LeftGrip_Under',(5,-9,1.8),(3.45,-2.65,5.05),3.5),('Body_Back',(9,22,12),(0,0,6.5),14.6)]
for name,loc,target,scale in views:
 cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
 s.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
report={}
from mathutils import Matrix
import math
HT=Matrix.Translation((-4.40,-2.65,2.65))@Matrix.Rotation(math.radians(-13),4,'Y')
for side,g in [('Left',8.05),('Right',2.72)]:
 o=bpy.data.objects['Continuous '+side+'Hand surface']
 verts=[HT.inverted()@o.matrix_world@v.co for v in o.data.vertices]
 bvh=BVHTree.FromPolygons(verts,[list(p.vertices) for p in o.data.polygons])
 clearances=[]
 for x in [g-.45,g-.15,g+.15,g+.45]:
  for direction,radius in [((0,1,0),.275),((0,-1,0),.275),((0,0,1),.295),((0,0,-1),.295)]:
   hit,n,index,d=bvh.ray_cast(Vector((x,0,0)),Vector(direction),2)
   clearances.append(None if hit is None else round(d-radius,4))
 report[side]={'cardinalContactClearanceStuds':clearances,'maxGapStuds':max(v for v in clearances if v is not None),'triangles':sum(len(p.vertices)-2 for p in o.data.polygons)}
(OUT/'grip-contact-checks.json').write_text(json.dumps(report,indent=2))
# An isolated underside view makes the handle/finger contact visible.
for o in bpy.data.objects:
 if o.type=='MESH' and o.parent and o.parent.name not in ('LeftHand_CTRL','Hammer_CTRL'):o.hide_render=True
cam.location=(6,1,2.1);target=Vector((3.44,-2.65,4.75));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=3.3
s.render.filepath=str(OUT/'LeftGrip_Contact.png');bpy.ops.render.render(write_still=True)
print('CONTINUITY_REVIEW_COMPLETE')
