"""Second batch, after the first batch passed Studio texture and scale inspection."""
exec(compile((__import__('pathlib').Path(r'C:/Users/Jeremiah/Documents/ChatGPT/Roblox/facility-blockout/production/blender/build_kit.py').read_text().split('assets=[]')[0]), 'kit_helpers', 'exec'))
assets=[]
if not bpy.data.objects.get('CourtyardTree'):
    rng=random.Random(639)
    rod((0,0,0),(.25,.15,6),.64,7,12)
    rod((.25,.15,5.6),(-.4,.5,12),.39,7,10)
    for i in range(7):
        a=i*math.tau/7;rod((0,0,.5),(math.cos(a)*1.9,math.sin(a)*1.9,.12),.18,7,8)
    vs=[];fs=[]
    for i in range(25):
        a=i*2.399;radius=rng.uniform(3.2,7);z=rng.uniform(10,17)-radius*.13
        end=Vector((math.cos(a)*radius,math.sin(a)*radius,z));start=Vector((0,0,rng.uniform(5.5,10)))
        mid=start.lerp(end,.65);rod(start,mid,.16,7,8);rod(mid,end,.065,7,7)
        for j in range(80):
            p=end+Vector((rng.uniform(-2,2),rng.uniform(-2,2),rng.uniform(-1.5,1.5)))
            axis=Vector((rng.uniform(-1,1),rng.uniform(-1,1),rng.uniform(-.3,1))).normalized();side=axis.cross(Vector((0,0,1))).normalized();le=rng.uniform(.5,.95);wi=le*.37;n=len(vs)
            vs.extend([tuple(p-axis*le*.5),tuple(p+side*wi),tuple(p+Vector((0,0,.09))),tuple(p-side*wi),tuple(p+axis*le*.5)])
            fs.extend([(n,n+1,n+2),(n+1,n+4,n+2),(n+4,n+3,n+2),(n+3,n,n+2)])
    o=mesh('TreeLeaves',vs,fs,3);o.data.materials.append(mats[4])
    for p in o.data.polygons:
        if p.index%5==0:p.material_index=1
    assets.append(finish('CourtyardTree'))
if not bpy.data.objects.get('MedicalGurney'):
    cube((0,0,2.5),(4.6,9,.32),0,.12)
    cube((0,.7,2.9),(4.2,6.8,.48),5,.2)
    o=cube((0,-3.1,3.15),(4.2,1.8,.4),5,.16);o.rotation_euler.x=math.radians(18)
    cube((0,0,1),(3.7,6.8,.14),0,.05)
    for x in (-1.75,1.75):
        for y in (-3.2,3.2):
            rod((x,y,.55),(x,y,2.4),.14)
            rod((x-.18,y,.45),(x+.18,y,.45),.4,6,14)
    for x in (-2.3,2.3):
        rod((x,-3.6,2.55),(x,-3.6,3.75),.1);rod((x,3.6,2.55),(x,3.6,3.75),.1)
        rod((x,-3.6,3.75),(x,3.6,3.75),.1)
        for y in (-2.5,-1,1,2.5):rod((x,y,2.6),(x,y,3.75),.065)
    rod((1.7,-3.1,2.5),(1.7,-3.1,7),.065)
    rod((1.1,-3.1,7),(2.3,-3.1,7),.065)
    cube((1.3,-3.1,6.45),(.4,.17,.65),5,.08)
    assets.append(finish('MedicalGurney'))
for o in assets:export([o],o.name+'.fbx')
batch=[]
for i,o in enumerate(assets):
    d=o.copy();d.data=o.data;collection.objects.link(d);d.name=o.name+'_Batch';d.location.x=i*32;batch.append(d)
if batch:export(batch,'ExpansionBatch.fbx')
for o in batch:bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=str(DEST/'blender'/'Facility_ModularKit.blend'))
result={'assets':[{'name':o.name,'triangles':len(o.data.polygons),'dimensions':list(o.dimensions)} for o in assets],'import_scale_correction':1/28}
