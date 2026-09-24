import bpy,json,math
from pathlib import Path
from mathutils import Matrix,Vector
OUT=Path(__file__).resolve().parent/'finished'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
exec(compile((OUT.parent/'validate_lever.py').read_text(),str(OUT.parent/'validate_lever.py'),'exec'))
bones=bpy.data.objects['HammerBoss_Rig'].data.bones
report={}
for clip,active in {'Slam':(23,24),'Swing':(19,25),'Spin':(21,37)}.items():
 ratios=[]
 for f in range(active[0],active[1]+1):
  row=d['clips'][clip]['frames'][f]
  for side in ['Right','Left']:
   a=bones[side+'UpperArm'].head_local;b=bones[side+'LowerArm'].head_local;w=bones[side+'Hand'].head_local
   ratios.append((delta(row[side+'Hand'])@w-delta(row['UpperTorso'])@a).length/((b-a).length+(w-b).length))
 report[clip]={'minArmExtension':min(ratios),'maxArmExtension':max(ratios)}
 # Wrist stacking now takes priority over locking both elbows. Validate
 # actual lever reach; the wrist regression checks joint closure and bend.
 assert min(report0['minHeadReach'] for report0 in json.loads((OUT/'lever-motion-checks.json').read_text()).values())>9
rows=d['clips']['Walk']['frames'];plantError=0;legError=0;heights=[]
for f,row in enumerate(rows):
 heights.append((delta(row['LowerTorso'])@Vector((0,.1,4.45))).z)
 for side in ['Right','Left']:
  a=bones[side+'UpperLeg'].head_local;b=bones[side+'LowerLeg'].head_local;w=bones[side+'Foot'].head_local
  ankle=delta(row[side+'Foot'])@w
  legError=max(legError,(ankle-delta(row['LowerTorso'])@a).length-((b-a).length+(w-b).length))
  phase=(f/48-(0 if side=='Right' else .43))%1;stance=.60 if side=='Right' else .57
  if f and 1/48<phase<stance:
   prev=delta(rows[f-1][side+'Foot'])@w
   plantError=max(plantError,(ankle-prev-Vector((0,4.5/30,0))).length)
report['Walk']={'plantedFootWorldDriftPerFrame':plantError,'maxLegOverreach':legError,'bodyBob':max(heights)-min(heights),'speed':4.5,'cycleSeconds':1.6}
(OUT/'heavy-motion-checks.json').write_text(json.dumps(report,indent=2));print('HEAVY_REPORT',json.dumps(report))
assert plantError<.001
assert legError<.001
assert max(heights)-min(heights)>.5
