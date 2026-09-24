-- Temporary Studio-only single-client regression. Never included in the build.
local B=require(game.ServerScriptService.BossService)
local M=require(game.ReplicatedStorage.RogueliteCombat.BossMotion)
local player=game.Players:GetPlayers()[1]
local npc=game:GetService('CollectionService'):GetTagged('HammerBoss')[1]
local root=npc.PrimaryPart
local pr=player.Character.HumanoidRootPart
local ph=player.Character.Humanoid
local report={attacks={}}
local ok,err=xpcall(function()
 npc:SetAttribute('BossManual',true)
 while B.states[npc].attack do task.wait() end
 local base=root.CFrame
 pr.Anchored=true
 for _,kind in {'Slam','Swing','Spin'} do
  ph.Health=ph.MaxHealth
  npc:PivotTo(base)
  pr.CFrame=base*CFrame.new(0,0,-12)
  local before=npc:GetAttribute('BossHits') or 0
  assert(B.start(npc,kind,pr),'Attack start '..kind)
  local a=M.Attacks[kind]
  local head=M.head(npc:GetAttribute('BossFrame'),kind,kind=='Slam' and a.active or (kind=='Swing' and 23/30 or 29/36))
  local pos=head.Position
  -- The slam must now hit beyond its former 2.35-stud radius.
  pr.CFrame=CFrame.new(pos.X+(kind=='Slam' and 3.2 or 0),base.Y,pos.Z)
  task.wait(a.active-.12)
  local early=npc:GetAttribute('BossHits') or 0
  assert(early==before,'Early hit '..kind)
  task.wait(a.duration-a.active+.35)
  local hits=(npc:GetAttribute('BossHits') or 0)-before
  assert(hits==1,'Expected one hit '..kind..' got '..hits)
  report.attacks[kind]={earlyHits=early-before,hits=hits,damage=ph.MaxHealth-ph.Health,reach=M.reach(kind)}
 end
 ph.Health=ph.MaxHealth
 npc:SetAttribute('BossManual',false)
 B.states[npc].next=workspace:GetServerTimeNow()+100
 local start=root.Position
 pr.CFrame=CFrame.new(start+Vector3.new(0,0,45))
 task.wait(4)
 local travelled=(root.Position-start).Magnitude
 assert(travelled>12 and travelled<22,'Walk distance '..travelled)
 report.walk={distance=travelled,seconds=4,speed=npc.Humanoid.WalkSpeed}
 npc:SetAttribute('BossManual',true)
 pr.Anchored=false
end,debug.traceback)
pr.Anchored=false
report.ok=ok;report.error=not ok and err or nil
game.ReplicatedStorage:SetAttribute('HeavyBossTest',game:GetService('HttpService'):JSONEncode(report))
script:Destroy()
