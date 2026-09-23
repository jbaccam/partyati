-- Temporary server test Script in Studio Play; never packaged.
local RS=game.ReplicatedStorage
local C=RS.RogueliteCombat
local Shop=require(game.ServerScriptService.ShopService)
local Ch=require(game.ServerScriptService.CharacterService)
local Drops=require(game.ServerScriptService.ShardDropService)
local Death=require(C.ZombieDeath)
local Effects=require(game.ServerScriptService.CombatEffectsService)
local E=require(C.EconomyConfig)
local Motion=require(C.ShardMotion)
local p=game.Players:GetPlayers()[1]
local root=p.Character.HumanoidRootPart
local savedCF=root.CFrame
local savedShards=Shop.states[p].shards
local savedRadius=Ch.states[p].stats.PickupRadius
local savedPhase=Shop.phase
local checked=0
local fixtures=Instance.new('Folder');fixtures.Name='ShardTestFixtures';fixtures.Parent=workspace
local function check(v,msg) checked+=1;assert(v,msg) end
local function npc(pos,dead,owned)
 local m=Instance.new('Model');m.Name='ShardTestMob'
 local r=Instance.new('Part');r.Name='HumanoidRootPart';r.Anchored=true;r.CanCollide=false;r.Position=pos;r.Parent=m;m.PrimaryPart=r
 local h=Instance.new('Humanoid');h.BreakJointsOnDeath=false;h.Parent=m;m.Parent=fixtures
 game.CollectionService:AddTag(m,'RogueliteZombie')
 if owned then m:SetAttribute('LastDamageUserId',p.UserId) end
 if dead then h.Health=0 end
 return m
end
local ok,err=xpcall(function()
 C:SetAttribute('ZombiesEnabled',false);Shop.phase='Combat';RS.RogueliteRunState:SetAttribute('Phase','Combat');RS.RogueliteRunState:SetAttribute('WaveEndsAt',workspace:GetServerTimeNow()+300)
 Drops.clear(false);Ch.states[p].stats.PickupRadius=6
 local at=Vector3.new(56,150,423)
 root.CFrame=CFrame.new(at+Vector3.new(30,0,0))
 local m=npc(at,true,true);local before=Shop.states[p].shards
 Death.finish(m);check(#Drops.drops==1,'exactly one drop per death');check(Shop.states[p].shards==before,'death does not directly credit')
 Death.finish(m);check(#Drops.drops==1,'duplicate death ignored')
 local d=Drops.drops[1];check(d.value==E.KILL_SHARDS,'configured value');check(d.owner==p,'killer owns drop')
 check(not Drops.collect(p,d),'brief visible rest before pickup');d.born-=1
 check(not Drops.collect(p,d),'distant pickup rejected')
 root.CFrame=CFrame.new(d.position+Vector3.new(0,2,0))
 d.owner={};check(not Drops.collect(p,d),'wrong owner rejected');d.owner=p
 local wall=Instance.new('Part');wall.Anchored=true;wall.Size=Vector3.new(8,.2,8);wall.Position=d.position+Vector3.new(0,1,0);wall.Parent=fixtures
 check(not Drops.collect(p,d),'occluded pickup rejected');wall:Destroy()
 check(Drops.collect(p,d),'nearby living owner starts magnet');check(Shop.states[p].shards==before,'no credit before arrival')
 Drops.step(d.started+Motion.PULL_SECONDS*.5);check(Shop.states[p].shards==before and d.model.Parent~=nil,'mid-flight not collected')
 check((d.position-d.startPosition).Magnitude>0,'magnet advances toward player')
 Drops.step(d.started+Motion.PULL_SECONDS+.01);check(Shop.states[p].shards==before+2,'one arrival credit')
 check(not Drops.collect(p,d),'pickup replay rejected');Drops.clear(false)
 local alive=npc(at,false,true);Death.finish(alive);check(alive.Parent~=nil and #Drops.drops==0,'living mob cannot drop');alive:Destroy();check(#Drops.drops==0,'cleanup no drop')
 local dead=npc(at,true,true);Shop.phase='Shop';Death.finish(dead);check(#Drops.drops==0,'shop phase death no reward');Shop.phase='Combat'
 local environmental=npc(at,true,false);Death.finish(environmental);d=Drops.drops[1];check(d and d.owner==nil,'environmental death public pickup')
 d.born-=1;root.CFrame=CFrame.new(d.position+Vector3.new(0,2,0));check(Drops.collect(p,d),'public pickup locks one collector');check(not Drops.collect(p,d),'no second claim in flight');Drops.clear(false)
 local combatMob=npc(at,false,false);combatMob.Humanoid.Died:Connect(function() Death.finish(combatMob) end)
 root.CFrame=CFrame.new(at+Vector3.new(30,0,0))
 local damage=Effects.hit(combatMob,1000,{owner=p,character=p.Character,stats=Ch.states[p].stats},true)
 check(damage==100,'real combat lethal hit: '..tostring(damage)..' player health '..p.Character.Humanoid.Health);check(#Drops.drops==1,'Died plus combat finish only one pickup');check(Drops.drops[1].owner==p,'attribution before lethal damage')
 before=Shop.states[p].shards;Drops.clear(true);check(Shop.states[p].shards==before+2,'wave banks owned drops');check(#Drops.drops==0,'wave clears geometry')
 Death.finish(npc(at,true,true));before=Shop.states[p].shards;Drops.clear(false);check(Shop.states[p].shards==before,'test abort grants no pending reward')
 for _=1,140 do Death.finish(npc(at,true,true)) end
 check(#Drops.drops==140,'every death has its own pickup above old cap');local total=0;for _,drop in Drops.drops do total+=drop.value end;check(total==280,'all death values retained');Drops.clear(false)
 Death.finish(npc(at,true,true));d=Drops.drops[1];root.CFrame=CFrame.new(d.position+Vector3.new(0,2,0))
 d.born-=1;local old=Shop.states[p].shards;Shop.states[p].shards=E.MAX_SHARDS-1;check(Drops.collect(p,d),'collect at cap');Drops.step(d.started+Motion.PULL_SECONDS+.01);check(Shop.states[p].shards==E.MAX_SHARDS,'balance capped');Shop.states[p].shards=old;Drops.clear(false)
 Death.finish(npc(at,true,true));d=Drops.drops[1];d.born-=1;root.CFrame=CFrame.new(d.position+Vector3.new(0,2,0));check(Drops.collect(p,d),'start cancellable pull')
 root.CFrame=CFrame.new(at+Vector3.new(150,0,0));Drops.step(d.started+.1);check(d.target==nil and not d.collected,'teleport cancels pull without reward');Drops.clear(false)
 check((Motion.idle(at,0,0)-Motion.idle(at,0,.4)).Magnitude>.05,'gentle bob changes position')
 check(Motion.pull(at,at+Vector3.new(10,0,0),Motion.PULL_SECONDS)==at+Vector3.new(10,0,0),'pull ends at player')
 check(Ch.drop==nil,'random health-orb producer removed')
 check(workspace:FindFirstChild('PracticeHealthDrop',true)==nil,'no glowing health drops')
end,debug.traceback)
Drops.clear(false);fixtures:Destroy();root.CFrame=savedCF;Ch.states[p].stats.PickupRadius=savedRadius
Shop.states[p].shards=savedShards;Shop.phase=savedPhase;RS.RogueliteRunState:SetAttribute('Phase',savedPhase);RS.RogueliteRunState:SetAttribute('WaveEndsAt',nil);Shop.publish(p)
script:SetAttribute('Result',game.HttpService:JSONEncode({passed=ok,assertions=checked,error=ok and '' or err}))
