"""Measure joint continuity and torso clearance in the exported animation."""
import bpy,json,math
from pathlib import Path
from mathutils import Vector
HERE=Path(__file__).resolve().parent
exec(compile((HERE/'validate_lever.py').read_text(),str(HERE/'validate_lever.py'),'exec'))
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
bones=bpy.data.objects['HammerBoss_Rig'].data.bones
report={}
for clip in ['Idle','Walk','Slam','Swing','Spin']:
 rows=d['clips'][clip]['frames'];jump=(0,None);clearance=(100,None)
 for f,row in enumerate(rows):
  inv=delta(row['UpperTorso']).inverted()
  for side in ['Right','Left']:
   b=bones[side+'LowerArm'].head_local;w=bones[side+'Hand'].head_local
   elbow=delta(row[side+'LowerArm'])@b;wrist=delta(row[side+'Hand'])@w
   if f:
    old=delta(rows[f-1]['UpperTorso']).inverted()@delta(rows[f-1][side+'LowerArm'])@b
    dist=(inv@elbow-old).length
    if dist>jump[0]:jump=(dist,[f,side])
   for k in range(11):
    p=inv@elbow.lerp(wrist,k/10)
    # Conservative torso core, not the shoulder's intentional union.
    q=(p.x/2.25)**2+((p.y+.15)/1.7)**2+((p.z-6.5)/2.15)**2
    if q<clearance[0]:clearance=(q,[f,side,k])
 report[clip]={'maxElbowStepInTorsoSpace':jump,'minTorsoCoreClearanceSquared':clearance}
 assert clearance[0]>1.25,(clip,'Arm entered torso core',clearance)
 # Stroke speed alone cannot distinguish a flip from intentional motion.
 # validate_wrists.py checks wrist bend and joint closure directly.
(OUT/'arm-polish-checks.json').write_text(json.dumps(report,indent=2))
print('ARM_REPORT',json.dumps(report))
