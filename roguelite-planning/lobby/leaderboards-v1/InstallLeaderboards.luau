-- Installs the three lobby leaderboards (Edit mode). Re-runnable: replaces Workspace.RogueliteLobby.Leaderboards.
-- Needs exports/fbx/Lobby_Leaderboards_V1.fbx imported with Studio's 3D Importer (Upload to Roblox on, scale 1);
-- the imported Model can sit anywhere in Workspace or ServerStorage. It is moved to
-- ServerStorage.LobbyLeaderboardsKitV1 as the template. Small dressing (flowers, grass, pebbles) under the
-- plinths is moved to ServerStorage.Lobby_BeforeLeaderboards_<timestamp>, not deleted.
-- LeaderboardService (studio-prototype/combat) fills the boards at runtime by the RogueliteLeaderboard tag.
local Tags=game:GetService('CollectionService')
local SS=game:GetService('ServerStorage')
local lobby=workspace:WaitForChild('RogueliteLobby')

-- Timber/Details/Roof atlases are byte-identical to the uploaded QuestsV6 ones (see README), so reuse them.
local TEXTURE={Timber='rbxassetid://132497778572240',Details='rbxassetid://129102548852685',Roof='rbxassetid://91191527690749'}
local FAMILY={LB_Frame_Timber='Timber',LB_Frame_Details='Details',LB_Frame_Roof='Roof',LB_Emblem_Kills='Details',LB_Emblem_Wave='Details',LB_Emblem_Time='Details'}
-- Bounding-box centres from metadata.json, Blender (x,y,z) -> board local (x,z,-y); front faces local +Z.
local CENTER={
 LB_Frame_Details=Vector3.new(0,5.0050,-0.1425),
 LB_Frame_Timber=Vector3.new(0,6.3728,-0.2000),
 LB_Frame_Roof=Vector3.new(0,6.8541,-0.2100),
 LB_Emblem_Kills=Vector3.new(0,10.8500,2.1450),
 LB_Emblem_Wave=Vector3.new(0,10.8500,2.1675),
 LB_Emblem_Time=Vector3.new(0,10.8500,2.2921),
}
local BOARDS={ -- viewed from spawn, left to right: Wave, Kills, Time
 {stat='Kills',title='TOP KILLS',emblem='LB_Emblem_Kills',cf=CFrame.new(-1400,120,37)*CFrame.Angles(0,math.pi,0)},
 {stat='Wave',title='HIGHEST WAVE',emblem='LB_Emblem_Wave',cf=CFrame.new(-1383,120,35.5)*CFrame.Angles(0,math.pi+math.rad(15),0)},
 {stat='Time',title='TIME PLAYED',emblem='LB_Emblem_Time',cf=CFrame.new(-1417,120,35.5)*CFrame.Angles(0,math.pi-math.rad(15),0)},
}

-- Find the imported kit (or the template from a previous install).
local kit=SS:FindFirstChild('LobbyLeaderboardsKitV1')
if not kit then
 for _,root in {workspace,SS} do
  for _,d in root:GetDescendants() do
   if d:IsA('MeshPart') and d.Name=='LB_Frame_Timber' and not d:IsDescendantOf(lobby) then kit=d.Parent;break end
  end
  if kit then break end
 end
end
assert(kit,'Import exports/fbx/Lobby_Leaderboards_V1.fbx with the 3D Importer first')
local parts={}
for _,d in kit:GetDescendants() do if d:IsA('MeshPart') and CENTER[d.Name] then parts[d.Name]=d end end
for name in CENTER do assert(parts[name],'Missing '..name..' in the imported kit') end

-- Solve the importer placement: a uniform scale (the importer has brought kits in at 100x) and a
-- quarter-turn about Y, from the part centres. Each copy is then un-scaled and un-turned in place.
local ref=parts.LB_Frame_Timber
local SCALE=ref.Size.X/12.8701 -- LB_Frame_Timber is 12.87 studs wide in Blender
local best,bestErr
for q=0,3 do
 local rot=CFrame.Angles(0,q*math.pi/2,0)
 local err=0
 for name,p in parts do
  local expected=ref.Position+rot:VectorToWorldSpace((CENTER[name]-CENTER.LB_Frame_Timber)*SCALE)
  err=math.max(err,(expected-p.Position).Magnitude/SCALE)
 end
 if not bestErr or err<bestErr then best,bestErr=rot,err end
end
assert(bestErr<.05,'Imported part layout does not match metadata (error '..bestErr..')')
local unturn=best:Inverse()

local stamp=os.date('!%Y%m%d_%H%M%S')
kit.Name='LobbyLeaderboardsKitV1';kit.Parent=SS

local old=lobby:FindFirstChild('Leaderboards');if old then old.Parent=SS;old.Name='Leaderboards_Before_'..stamp end
local folder=Instance.new('Folder');folder.Name='Leaderboards';folder.Parent=lobby

local function part(name,parent,size,localCf,pivot,props)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=pivot*localCf;p.Anchored=true
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 for k,v in props or {} do p[k]=v end
 p.Parent=parent;return p
end
local signTemplate=lobby.Stations.Quests.StationName
local report={}
for _,b in BOARDS do
 local model=Instance.new('Model');model.Name='Leaderboard_'..b.stat
 local visuals=Instance.new('Folder');visuals.Name='Visuals';visuals.Parent=model
 for _,name in {'LB_Frame_Timber','LB_Frame_Details','LB_Frame_Roof',b.emblem} do
  local src=parts[name];local m=src:Clone()
  for _,c in m:GetChildren() do if c:IsA('SurfaceAppearance') then c:Destroy() end end
  m.TextureID=TEXTURE[FAMILY[name]];m.Color=Color3.new(1,1,1);m.Material=Enum.Material.SmoothPlastic
  m.Anchored=true;m.CanCollide=false;m.CanTouch=false;m.CanQuery=true;m.CastShadow=true
  m.Size=src.Size/SCALE
  m.CFrame=b.cf*CFrame.new(CENTER[name])*unturn*src.CFrame.Rotation;m:SetAttribute('Asset',name);m:SetAttribute('Revision',1);m.Parent=visuals
 end
 local collision=Instance.new('Folder');collision.Name='Collision';collision.Parent=model
 local hidden={Transparency=1,CanCollide=true,CanTouch=false,CanQuery=true}
 local plinth=part('Plinth',collision,Vector3.new(11.6,.46,4.4),CFrame.new(0,.23,-.2),b.cf,hidden)
 for _,x in {-4.75,4.75} do part('Post',collision,Vector3.new(1.1,9.4,1.1),CFrame.new(x,4.7,-.3),b.cf,hidden) end
 part('Board',collision,Vector3.new(8.7,6.4,.75),CFrame.new(0,4.4,-.25),b.cf,hidden)
 part('Roof',collision,Vector3.new(12.6,.5,5.0),CFrame.new(0,10.9,-.2),b.cf,hidden)
 local extras=Instance.new('Folder');extras.Name='Extras';extras.Parent=model
 for _,x in {-5.87,5.87} do
  part('WarmLens',extras,Vector3.new(.4,.6,.4),CFrame.new(x,6.6,-.3),b.cf,
   {Material=Enum.Material.Neon,Color=Color3.fromRGB(255,190,83),CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false})
 end
 -- Title uses the station sign styling (clone of the Quests StationName plane and label).
 local title=signTemplate:Clone();title.Name='Title';title.Size=Vector3.new(6.6,.87,.03)
 title.CFrame=b.cf*CFrame.new(0,8.1,.53)
 title:FindFirstChildWhichIsA('SurfaceGui',true):FindFirstChildWhichIsA('TextLabel',true).Text=b.title
 title.Parent=model
 local display=part('Display',model,Vector3.new(7.7,5.7,.02),CFrame.new(0,4.4,.09),b.cf,
  {Transparency=1,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false})
 model.PrimaryPart=plinth;model.WorldPivot=b.cf
 model:SetAttribute('LeaderboardStat',b.stat);Tags:AddTag(model,'RogueliteLeaderboard')
 model.Parent=folder

 -- Clear small ground dressing under the plinth footprint (moved to a backup folder).
 local moved=0
 for _,d in lobby.Scenery:GetDescendants() do
  if d:IsA('BasePart') and d.Size.Magnitude<4 and (d.Name:match('Flowers') or d.Name:match('Grass') or d.Name:match('Pebbles')) then
   local l=b.cf:PointToObjectSpace(d.Position)
   if math.abs(l.X)<6.6 and l.Z>-2.9 and l.Z<2.5 then
    local backup=SS:FindFirstChild('Lobby_BeforeLeaderboards_'..stamp) or Instance.new('Folder')
    backup.Name='Lobby_BeforeLeaderboards_'..stamp;backup.Parent=SS
    d:SetAttribute('OriginalParent',d.Parent:GetFullName());d.Parent=backup;moved+=1
   end
  end
 end
 table.insert(report,b.stat..': placed, dressing moved '..moved)
end
-- Title and display planes share the board pivot's rotation, so their Back face (+Z, where the SurfaceGuis
-- draw, as on the station signs) faces the board front.
return string.format('importer scale %.3f, turn %s, placement error %.4f\n',SCALE,tostring(select(2,best:ToEulerAnglesYXZ())),bestErr)..table.concat(report,'\n')
