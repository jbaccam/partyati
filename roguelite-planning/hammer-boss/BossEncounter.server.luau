local RS=game:GetService('ReplicatedStorage')
local B=require(script.Parent:WaitForChild('BossService'))
local run=RS:WaitForChild('RogueliteRunState')
local combat=RS:WaitForChild('RogueliteCombat')
local Motion=require(combat:WaitForChild('BossMotion'))
-- Encounter selection is server-owned; no client spawn or damage remote.
local current,lastWave
local function update()
 local wave=run:GetAttribute('Wave');local active=combat:GetAttribute('ZombiesEnabled')==true
 if not active then current=nil;lastWave=nil;run:SetAttribute('BossAlive',false);return end
 if wave~=(combat:GetAttribute('HammerBossWave') or 20) or lastWave==wave then return end
 local marker=workspace:FindFirstChild('RogueliteZombieSpawn');if not marker then return end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={workspace:FindFirstChild('RogueliteEnemies'),marker}
 local p=marker.Position+Vector3.new(0,0,-15);local ground=workspace:Raycast(p+Vector3.yAxis*35,-Vector3.yAxis*100,params)
 if not ground then return end
 current=B.spawn(CFrame.new(ground.Position+Vector3.yAxis*(Motion.RootHeight+.1)),false)
 if current then
  lastWave=wave;run:SetAttribute('BossAlive',true)
  current.Destroying:Connect(function() run:SetAttribute('BossAlive',false) end)
 end
end
combat:GetAttributeChangedSignal('ZombiesEnabled'):Connect(function() task.defer(update) end)
run:GetAttributeChangedSignal('Wave'):Connect(function() task.defer(update) end)
task.defer(update)
