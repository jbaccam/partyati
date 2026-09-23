-- Disposable Studio server Script; never included in the Rojo production tree.
assert(game:GetService('RunService'):IsStudio())
local c=game.ReplicatedStorage.RogueliteCombat
local X=require(c.RunXP);local S=require(game.ServerScriptService.ShopService)
local D=require(game.ServerScriptService.ShardDropService)
local p=game.Players:GetPlayers()[1];local s=S.states[p];local f=c.PlayerStates[tostring(p.UserId)]
local count=0
local function check(ok,label) assert(ok,label);count+=1 end
local l,x,n=X.add(1,0,20);check(l==2 and x==0 and n==1,'exact level')
l,x,n=X.add(1,0,57);check(l==3 and x==7 and n==2,'multi-level overflow')
for _,bad in {-1,.5,0/0,math.huge,1000001} do l,x,n=X.add(1,0,bad);check(l==1 and x==0 and n==0,'invalid award') end
l,x,n=X.add(1000,0,1000000);check(l==1000 and x==X.required(1000),'bounded max level')
check(s.level==1 and s.xp==0,'starting currency does not grant XP')
S.phase='Combat';game.ReplicatedStorage.RogueliteRunState:SetAttribute('Phase','Combat');S.publish(p)
f:SetAttribute('WeaponEnabled',false)
p.Character:PivotTo(CFrame.new(74,7,450));task.wait(.4)
local function drop()
 local npc=Instance.new('Model');npc.Name='XPTestFixture';npc:SetAttribute('LastDamageUserId',p.UserId);npc.Parent=workspace
 local h=Instance.new('Humanoid');h.Parent=npc;h.Health=0
 game.CollectionService:AddTag(npc,'RogueliteZombie')
 local d=D.spawn(npc,p.Character.HumanoidRootPart.Position+Vector3.new(2,0,0));npc:Destroy()
 return d
end
local startShards=s.shards
local first=drop();check(first~=nil,'real death drop created')
check(s.xp==0,'no XP on spawn')
check(not D.collect(p,first),'no collection before rest')
task.wait(1.5)
check(first.collected and not first.model.Parent,'magnet arrived and removed drop')
check(s.xp==2 and s.shards==startShards+2,'pickup gives both XP and currency')
D.step(workspace:GetServerTimeNow()+2);check(s.xp==2,'no duplicate XP')
for _=1,9 do drop() end
task.wait(1.5)
check(s.level==2 and s.xp==0 and s.pendingLevels==1,'ten pickups level up exactly')
check(f:GetAttribute('RunLevel')==2 and f:GetAttribute('RunXPRequired')==30,'replicated progression')
drop();task.wait(1.5)
check(s.xp==2,'XP continues after level up')
local bank=drop();D.clear(true)
check(s.xp==2 and not bank.model.Parent,'uncollected end-wave banking gives no pickup XP')
S.phase='Shop';game.ReplicatedStorage.RogueliteRunState:SetAttribute('Phase','Shop');S.publish(p)
S.request(p,'Shards',s.revision,'Add',100)
check(s.xp==2 and s.level==2,'debug currency does not grant XP')
task.wait(.3)
local before=s.shards;S.request(p,'Reroll',s.revision)
check(s.shards<before and s.xp==2,'spending does not remove XP')
local rejected=drop();check(rejected==nil,'no drops or XP outside combat')
S.phase='Combat';game.ReplicatedStorage.RogueliteRunState:SetAttribute('Phase','Combat');S.publish(p)
script:SetAttribute('Results',game:GetService('HttpService'):JSONEncode({passed=count,xp=s.xp,level=s.level,required=f:GetAttribute('RunXPRequired')}))
