-- Combat-copy orientation only. Bounds come from reviewed GLB vertices via
-- measure_weapon_presentations.py; launcher rear closure fixes coplanar disks.
local P={}
P.Definitions={
 ['06']={rotation=CFrame.Angles(0,0,-.66),center=Vector3.new(0.0046318880,-0.0149131237,0.0000000000),size=Vector3.new(0.1871237799,0.8691405363,0.1871237342),original=Vector3.new(0.6274683453,0.7558228521,0.1871237342)},
 ['12']={rotation=CFrame.Angles(0,math.rad(0),0)*CFrame.Angles(0,0,math.rad(180)),center=Vector3.new(0,0,0),size=Vector3.new(0.8163542137,0.5745849901,0.0584626969),original=Vector3.new(0.8163542137,0.5745849901,0.0584626969)},
 ['13']={rotation=CFrame.Angles(0,math.rad(0),0)*CFrame.Angles(0,0,math.rad(180)),center=Vector3.new(0,0,0),size=Vector3.new(0.2411631900,0.9629643787,0.1205815950),original=Vector3.new(0.2411631900,0.9629643787,0.1205815950)},
 ['26']={rotation=CFrame.Angles(0,math.rad(0),0)*CFrame.Angles(0,0,math.rad(166.24901291686024)),center=Vector3.new(0.0038391455,0.0067597201,0),size=Vector3.new(0.2820501186,0.9156363165,0.0968053495),original=Vector3.new(0.4139965030,0.9051163570,0.0968053495)},
 ['30']={rotation=CFrame.Angles(0,math.rad(90),0)*CFrame.Angles(0,0,math.rad(39)),center=Vector3.new(0,0.0114072734,-0.0240529768),size=Vector3.new(0.1280422900,0.9651408843,0.1992876828),original=Vector3.new(0.6892638768,0.7131062194,0.1280422900)},
 ['32']={rotation=CFrame.Angles(0,math.rad(0),0)*CFrame.Angles(0,0,math.rad(48)),center=Vector3.new(-0.0026037041,0.0173542938,0),size=Vector3.new(0.3510793572,0.9565571727,0.1317766137),original=Vector3.new(0.7331696240,0.6671560736,0.1317766137)},
 ['01']={rotation=CFrame.Angles(0,math.rad(-90),0)*CFrame.Angles(0,0,math.rad(90)),center=Vector3.new(0,0,0),size=Vector3.new(0.5280692224,0.8394496498,0.1283245172),original=Vector3.new(0.8394496498,0.1283245172,0.5280692224)}
}
function P.prepare(model)
 local d=P.Definitions[model.Name]
 if not d or model:GetAttribute('PresentationVersion')==1 then return nil end
 local size,center=model:GetAttribute('BoundsSize'),model:GetAttribute('BoundsCenter')
 assert(typeof(size)=='Vector3' and typeof(center)=='Vector3','Missing bounds: '..model.Name)
 local scale=size.Magnitude
 assert(scale>0 and (size/scale-d.original).Magnitude<.01,'Unexpected mesh proportions: '..model.Name)
 local pivot=model:GetPivot()
 local poses={}
 for _,part in model:GetDescendants() do
  if part:IsA('BasePart') then poses[part]=pivot*d.rotation*pivot:ToObjectSpace(part.CFrame) end
 end
 return {model=model,pivot=pivot,poses=poses,center=d.rotation:VectorToWorldSpace(center)+d.center*scale,size=d.size*scale}
end
function P.commit(plan)
 local model=plan.model
 for part,pose in plan.poses do part.CFrame=pose end
 if model.PrimaryPart then model.PrimaryPart.PivotOffset=model.PrimaryPart.CFrame:ToObjectSpace(plan.pivot)
 else model.WorldPivot=plan.pivot end
 model:SetAttribute('BoundsCenter',plan.center)
 model:SetAttribute('BoundsSize',plan.size)
 model:SetAttribute('PresentationVersion',1)
end
function P.stabilizeLauncher(model)
 if model.Name~='11' and not model.Name:match('^11_') then return end
 local mesh=model:FindFirstChild('W11_Rocket_Launcher',true)
 assert(mesh and mesh:IsA('MeshPart'),'Missing reviewed launcher mesh')
 if model:GetAttribute('StableLauncherBoreVersion')==2
  and model:FindFirstChild('StableRearBoreBackstop')
  and model:FindFirstChild('StableRearOliveInset') then return end
 -- The green flicker is at the REAR (+native X) opening: the imported olive
 -- tube end and dark bore end share X=214.5 exactly. Eight triangles per disk
 -- overlap, although none have identical vertices. The old -X cap hid the
 -- opposite opening. Remove it and cover the actual coincident rear disks.
 for _,name in {'StableBoreBackstop','StableRearBoreBackstop','StableRearOliveInset'} do
  local old=model:FindFirstChild(name);if old then old:Destroy() end
 end
 local scale=mesh.Size/mesh.MeshSize
 local function disk(name,x,diameter,color)
  local cap=Instance.new('Part');cap.Name=name;cap.Shape=Enum.PartType.Cylinder
  cap.Size=Vector3.new(1*scale.X,diameter*scale.Y,diameter*scale.Z)
  cap.CFrame=mesh.CFrame*CFrame.new(Vector3.new(x,26.27882385253906,0)*scale)
  cap.Color=color;cap.Material=Enum.Material.SmoothPlastic
  cap.Anchored=true;cap.CanCollide=false;cap.CanTouch=false;cap.CanQuery=false;cap.CastShadow=false
  cap.Parent=model
 end
 -- Both surfaces sit ahead of the original X=214.5 plane and have separated
 -- depths. The original green inset appearance is retained inside a dark bore.
 disk('StableRearBoreBackstop',218.5,108,Color3.fromRGB(14,15,18))
 disk('StableRearOliveInset',221.5,90,Color3.fromRGB(102,113,56))
 model:SetAttribute('StableLauncherBore',true)
 model:SetAttribute('StableLauncherBoreVersion',2)
end
function P.apply(model)
 local plan=P.prepare(model)
 if plan then P.commit(plan) end
 P.stabilizeLauncher(model)
end
return P
