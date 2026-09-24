-- Scoped edit-time import. Source is kept for provenance; never deletes other NPCs.
local D=require(game.ReplicatedStorage.RogueliteCombat.BossData)
local function v(a)return Vector3.new(table.unpack(a))end
return function(source)
 assert(game.PlaceId==107877054949326 and not game:GetService('RunService'):IsRunning(),'Use roguelite Edit mode')
 assert(source and source:IsA('Model'),'Pass the imported boss model')
 local templates=game.ServerStorage.RogueliteNPCs
 assert(not templates:FindFirstChild('HammerBoss_NPC'),'Boss template exists; inspect before replacing')
 local found={};local count=0
 for _,o in source:GetDescendants() do
  if o:IsA('MeshPart') and D.parts[o.Name] then assert(not found[o.Name],'Duplicate section');assert(o.MeshId~='','Upload meshes first');found[o.Name]=o;count+=1 end
 end
 assert(count==16,'Expected 15 body sections and Hammer')
 local meanA,meanB=Vector3.zero,Vector3.zero
 for name,o in found do meanA+=o.Position;meanB+=v(D.parts[name].center) end;meanA/=count;meanB/=count
 local aa,bb=0,0
 for name,o in found do aa+=(o.Position-meanA).Magnitude^2;bb+=(v(D.parts[name].center)-meanB).Magnitude^2 end
 local scale=math.sqrt(bb/aa);local best,cost=nil,math.huge
 local axes={Vector3.xAxis,-Vector3.xAxis,Vector3.yAxis,-Vector3.yAxis,Vector3.zAxis,-Vector3.zAxis}
 for _,right in axes do for _,up in axes do if math.abs(right:Dot(up))<.01 then
  local rot=CFrame.fromMatrix(Vector3.zero,right,up,right:Cross(up));local error=0
  for name,o in found do error+=((rot:VectorToWorldSpace(o.Position-meanA)*scale)-(v(D.parts[name].center)-meanB)).Magnitude^2 end
  if error<cost then best,cost=rot,error end
 end end end
 assert(math.sqrt(cost/count)<.15,'Mesh layout mismatches source')
 local npc=Instance.new('Model');npc.Name='HammerBoss_NPC';local parts={}
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Transparency=1;root.Size=Vector3.new(3.2,2.6,2.5)
 root.CFrame=CFrame.new(0,D.rootHeight,0);root.Anchored=true;root.CanCollide=true;root.CanTouch=false;root.CanQuery=false;root.Parent=npc
 parts.HumanoidRootPart=root;npc.PrimaryPart=root
 for name,o in found do
  local p=o:Clone()
  for _,child in p:GetChildren() do if not child:IsA('SurfaceAppearance') then child:Destroy() end end
  p.Size=o.Size*scale;p.CFrame=CFrame.new(v(D.parts[name].center))*(best*o.CFrame.Rotation)
  p.Color=Color3.new(1,1,1);p.RenderFidelity=Enum.RenderFidelity.Precise;p.CanCollide=false;p.CanTouch=false;p.CanQuery=name~='Hammer';p.Massless=true;p.Anchored=false
  -- Surface maps bypass Humanoid texture compositing, which damages atlas seams.
  if p.TextureID~='' and not p:FindFirstChildOfClass('SurfaceAppearance') then
   local surface=Instance.new('SurfaceAppearance');surface.Name='BossSurface';surface.ColorMap=p.TextureID;surface.AlphaMode=Enum.AlphaMode.Overlay;surface.Parent=p;p.TextureID=''
  end
  p:SetAttribute('BossRest',root.CFrame:ToObjectSpace(p.CFrame));p.Parent=npc;parts[name]=p
 end
 for name,j in D.joints do
  local a,b=parts[j.parent],parts[name];local frame=CFrame.new(v(j.head))
  local m=Instance.new('Motor6D');m.Name='Boss_'..name;m.Part0=a;m.Part1=b;m.C0=a.CFrame:ToObjectSpace(frame);m.C1=b.CFrame:ToObjectSpace(frame);m.Parent=a
 end
 local h=Instance.new('Humanoid');h.RigType=Enum.HumanoidRigType.R15;h.AutomaticScalingEnabled=false;h.RequiresNeck=false;h.BreakJointsOnDeath=false
 h.HipHeight=D.rootHeight-root.Size.Y/2;h.MaxHealth=1800;h.Health=h.MaxHealth;h.WalkSpeed=D.walkSpeed or 4.5;h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;h.Parent=npc
 Instance.new('Animator',h)
 npc:SetAttribute('IsBoss',true);npc:SetAttribute('IsHammerBoss',true);npc:SetAttribute('ZombieType','HammerBoss');npc:SetAttribute('ContactDamage',0);npc:SetAttribute('ContactRange',0);npc:SetAttribute('BaseMoveSpeed',D.walkSpeed or 4.5)
 npc:SetAttribute('SourceAsset','hammer-boss/finished/HammerBoss.blend');npc.Parent=templates
 return {name=npc.Name,sections=count,alignmentError=math.sqrt(cost/count),scale=scale}
end
