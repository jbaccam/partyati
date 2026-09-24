-- Run as a temporary sandboxed server Script in a disposable Studio Play session.
local combat=game.ReplicatedStorage.RogueliteCombat
local Motion=require(combat.ArcMotion)
local player=game.Players:GetPlayers()[1]
local state=combat.PlayerStates[tostring(player.UserId)]
local dummy=workspace.Zombie_R15_ProvidedTextures_Studio
local passed=0
local function check(value,label) assert(value,label);passed+=1 end
local a,b=Vector3.new(0,4,0),Vector3.new(0,4,-24)
local random=Random.new(922);local previous;local distinct=0;local sawS=false
for i=1,100 do
 local side,height,bend=Motion.shape('18',24,i,random)
 check((Motion.position(a,b,0,side,height,bend)-a).Magnitude<.001,'random start')
 check((Motion.position(a,b,1,side,height,bend)-b).Magnitude<.001,'random endpoint')
 check(math.abs(side)<=9*1.15 and math.abs(bend)<=9*.85 and height>=.8 and height<=6,'bounded route')
 local quarter=Motion.position(a,b,.25,side,height,bend)
 if previous and (quarter-previous).Magnitude>.01 then distinct+=1 end
 previous=quarter
 if quarter.X*Motion.position(a,b,.75,side,height,bend).X<0 then sawS=true end
end
check(distinct>90,'successive routes differ');check(sawS,'S-shaped routes included')
for _,id in {'18','33'} do
 for i=1,3 do
  local side,height=Motion.shape(id,24,i)
  check((Motion.position(a,b,0,side,height)-a).Magnitude<.001,'start '..id)
  check((Motion.position(a,b,1,side,height)-b).Magnitude<.001,'end '..id)
  check(Motion.position(a,b,.5,side,height).Y>4,'arc height '..id)
 end
 check(Motion.duration(id,24,180)<=Motion.duration(id,24,45),'speed scaling '..id)
end
local left=Motion.shape('18',24,1);local right=Motion.shape('18',24,3)
check(left<0 and right>0,'cards fan to opposite sides')
check(Motion.lid(0)==0 and Motion.lid(.24)==1 and Motion.lid(1)==0,'lid opens before launch then closes')
combat:SetAttribute('ZombiesEnabled',false)
local shards=state:GetAttribute('Shards')
local h=player.Character:FindFirstChildOfClass('Humanoid');local hp=h.Health
for i=1,6 do state['Slot'..i]:SetAttribute('WeaponId','') end
state:SetAttribute('WeaponEnabled',true)
local damageByWeapon={}
for _,id in {'18','33','00','11','03'} do
 state.Slot1:SetAttribute('WeaponId',id)
 player.Character:PivotTo(CFrame.new(70,7,id=='03' and 416 or 432))
 local before=dummy:GetAttribute('PracticeHits')
 task.wait(id=='11' and 4.5 or 3)
 damageByWeapon[id]=dummy:GetAttribute('PracticeHits')-before
 check(damageByWeapon[id]>0,'dummy hit with spawning off: '..id)
 state.Slot1:SetAttribute('WeaponId','');task.wait(.3)
end
check(h.Health==hp,'dummy does not harm player')
check(state:GetAttribute('Shards')==shards,'dummy grants no currency')
check(#workspace.RogueliteShardDrops:GetChildren()==0,'dummy creates no drops')
local Effects=require(game.ServerScriptService.CombatEffectsService)
local Stats=require(combat.CharacterStats)
local Characters=require(game.ServerScriptService.CharacterService)
local d=Stats.weapon(require(combat.WeaponCatalog).ById['18'],Characters.states[player].stats,Characters.states[player].class,1)
d.owner=player;d.character=player.Character;d.stats=Characters.states[player].stats
Effects.hit(dummy,100000,d)
check(dummy.Humanoid.Health==dummy.Humanoid.MaxHealth,'lethal practice damage resets health')
player.Character:PivotTo(CFrame.new(70,7,432));state.Slot1:SetAttribute('WeaponId','18')
task.wait(1);state:SetAttribute('WeaponEnabled',false);task.wait(1)
local before=dummy:GetAttribute('PracticeHits');task.wait(1)
check(dummy:GetAttribute('PracticeHits')==before,'disabled weapons stop hits')
state:SetAttribute('WeaponEnabled',true)
local wall=Instance.new('Part');wall.Name='ArcTestWall';wall.Anchored=true;wall.Size=Vector3.new(50,50,2);wall.Position=Vector3.new(70,15,421);wall.Parent=workspace
task.wait(2);before=dummy:GetAttribute('PracticeHits');task.wait(1)
check(dummy:GetAttribute('PracticeHits')==before,'wall blocks target acquisition')
wall:Destroy()
state.Slot1:SetAttribute('WeaponId','18');state.Slot2:SetAttribute('WeaponId','33')
script:SetAttribute('Results',game:GetService('HttpService'):JSONEncode({passed=passed,hits=damageByWeapon,shards=shards}))
