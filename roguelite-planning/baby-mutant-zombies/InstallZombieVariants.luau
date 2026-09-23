-- Edit-time installer: call returned function(importedModel, 'Baby' or 'Mutant').
-- Keeps the raw import and refuses to overwrite a gameplay template.
local Data=require(script.Parent.ZombieImportData)
local Types=require(game.ReplicatedStorage.RogueliteCombat.ZombieTypes)
local function vec(a)return Vector3.new(a[1],a[2],a[3])end
local function motorName(name)
    if name=='LowerTorso' then return 'Root' elseif name=='UpperTorso' then return 'Waist' elseif name=='Head' then return 'Neck' end
    for _,pair in {{'UpperArm','Shoulder'},{'LowerArm','Elbow'},{'Hand','Wrist'},{'UpperLeg','Hip'},{'LowerLeg','Knee'},{'Foot','Ankle'}} do
        if name:sub(-#pair[1])==pair[1] then return name:sub(1,#name-#pair[1])..pair[2] end
    end
end
return function(source,kind)
    assert(game.PlaceId==107877054949326,'Installer is scoped to the roguelite place')
    assert(not game:GetService('RunService'):IsRunning(),'Install in Edit mode')
    assert(Data[kind] and source and source:IsA('Model'),'Expected imported Baby or Mutant Model')
    local data=Data[kind];local config=Types.get(kind);local found={};local count=0
    for _,obj in source:GetDescendants() do
        if obj:IsA('MeshPart') and data.parts[obj.Name] then
            assert(not found[obj.Name],'Duplicate imported section '..obj.Name)
            assert(obj.MeshId~='','Mesh must be uploaded, not a temporary EditableMesh')
            local appearance=obj:FindFirstChildOfClass('SurfaceAppearance')
            assert(obj.TextureID~='' or (appearance and appearance.ColorMap~=''),'Missing texture on '..obj.Name)
            found[obj.Name]=obj;count+=1
        end
    end
    assert(count==15,'Expected 15 named mesh sections; import the provided _Import.fbx file')
    local templates=game.ServerStorage:FindFirstChild('RogueliteNPCs');assert(templates)
    assert(not templates:FindFirstChild(config.template),'Template already exists; do not overwrite')
    -- Find the importer's uniform scale and axis rotation from all section centers.
    local meanA,meanB=Vector3.zero,Vector3.zero
    for name,obj in found do meanA+=obj.Position;meanB+=vec(data.parts[name].center) end
    meanA/=15;meanB/=15
    local aa,bb=0,0
    for name,obj in found do aa+=(obj.Position-meanA).Magnitude^2;bb+=(vec(data.parts[name].center)-meanB).Magnitude^2 end
    assert(aa>0);local scale=math.sqrt(bb/aa)
    local directions={Vector3.xAxis,-Vector3.xAxis,Vector3.yAxis,-Vector3.yAxis,Vector3.zAxis,-Vector3.zAxis}
    local best,cost=nil,math.huge
    for _,right in directions do for _,up in directions do if math.abs(right:Dot(up))<.01 then
        local rot=CFrame.fromMatrix(Vector3.zero,right,up,right:Cross(up));local error=0
        for name,obj in found do error+=((rot:VectorToWorldSpace(obj.Position-meanA)*scale)-(vec(data.parts[name].center)-meanB)).Magnitude^2 end
        if error<cost then best,cost=rot,error end
    end end end
    assert(math.sqrt(cost/15)<.15,'Imported section layout does not match authored geometry; inspect before installing')
    local npc=Instance.new('Model');npc.Name=config.template
    local parts={}
    for name,obj in found do
        local p=obj:Clone()
        for _,child in p:GetChildren() do if not child:IsA('SurfaceAppearance') then child:Destroy() end end
        p.Size=obj.Size*scale;p.CFrame=CFrame.new(vec(data.parts[name].center))*(best*obj.CFrame.Rotation)
        p.Color=Color3.new(1,1,1);p.Anchored=false;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.Massless=true
        p.Parent=npc;parts[name]=p
    end
    local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Transparency=1
    root.Size=kind=='Baby' and Vector3.new(.9,.8,.65) or Vector3.new(2.2,2,1.3)
    local rootHeight=kind=='Baby' and 1.24 or 3.15
    root.CFrame=CFrame.new(0,rootHeight,0);root.CanCollide=true;root.CanQuery=false;root.CanTouch=false
    root.Anchored=true;root.Parent=npc;parts.HumanoidRootPart=root;npc.PrimaryPart=root
    for name,j in data.joints do
        local a,b=parts[j.parent],parts[name];local frame=CFrame.new(vec(j.head))
        local m=Instance.new('Motor6D');m.Name=motorName(name);m.Part0=a;m.Part1=b
        m.C0=a.CFrame:ToObjectSpace(frame);m.C1=b.CFrame:ToObjectSpace(frame);m.Parent=a
    end
    local h=Instance.new('Humanoid');h.RigType=Enum.HumanoidRigType.R15;h.AutomaticScalingEnabled=false
    h.HipHeight=rootHeight-root.Size.Y/2;h.BreakJointsOnDeath=false;h.RequiresNeck=true
    h.MaxHealth=config.health;h.Health=config.health;h.WalkSpeed=config.speed;h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
    h.Parent=npc;Instance.new('Animator',h)
    npc:SetAttribute('ZombieType',kind);npc:SetAttribute('BaseMoveSpeed',config.speed)
    npc:SetAttribute('ContactDamage',config.damage);npc:SetAttribute('ContactRange',config.contactRange)
    npc:SetAttribute('SourceAsset','baby-mutant-zombies/'..kind..'/Model.blend')
    npc.Parent=templates
    return {name=npc.Name,parts=count,scale=scale,alignmentError=math.sqrt(cost/15),height=data.height}
end
