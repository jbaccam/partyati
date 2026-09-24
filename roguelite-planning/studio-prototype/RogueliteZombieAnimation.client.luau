-- Procedural articulated locomotion and timestamped mutant slam on every client.
local Tags=game:GetService('CollectionService')
local RunService=game:GetService('RunService')
local combat=game.ReplicatedStorage:WaitForChild('RogueliteCombat')
local Types=require(combat:WaitForChild('ZombieTypes'))
local Motion=require(combat:WaitForChild('ZombieMotion'))
local SlamVisuals=require(combat:WaitForChild('ZombieSlamVisuals'))
local tracked={}
local function track(npc)
    if tracked[npc] then return end
    local joints={}
    for _,v in npc:GetDescendants() do if v:IsA('Motor6D') then joints[v.Name]=v end end
    tracked[npc]={joints=joints,phase=((npc:GetAttribute('SpawnIndex') or 1)*2.3999632297)%(2*math.pi),stride=0,reach=0}
end
Tags:GetInstanceAddedSignal('RogueliteZombie'):Connect(track)
Tags:GetInstanceRemovedSignal('RogueliteZombie'):Connect(function(npc) tracked[npc]=nil;SlamVisuals.remove(npc) end)
for _,npc in Tags:GetTagged('RogueliteZombie') do track(npc) end
RunService.PreSimulation:Connect(function(dt)
    local now=workspace:GetServerTimeNow()
    for npc,state in tracked do
        if not npc.Parent then tracked[npc]=nil;SlamVisuals.remove(npc);continue end
        local root=npc:FindFirstChild('HumanoidRootPart');local h=npc:FindFirstChildOfClass('Humanoid')
        if not root or not h or h.Health<=0 or npc:GetAttribute('PracticeTarget') then SlamVisuals.remove(npc);continue end
        SlamVisuals.update(npc,now)
        local kind=npc:GetAttribute('ZombieType') or 'Regular';local config=Types.get(kind)
        local v=root.AssemblyLinearVelocity;local speed=Vector2.new(v.X,v.Z).Magnitude
        local blend=1-math.exp(-math.min(dt,.1)*10)
        local attackStart=npc:GetAttribute('SlamStart');local age=attackStart and now-attackStart
        local attacking=age and age>=0 and age<=Types.Slam.recovery
        state.reach+=((npc:GetAttribute('Chasing') and 1 or 0)-state.reach)*blend
        local walking=h.FloorMaterial~=Enum.Material.Air and speed>.35 and not attacking
        state.stride+=((walking and math.clamp(speed/config.speed,0,1) or 0)-state.stride)*blend
        state.phase=(state.phase+math.min(dt,.1)*math.min(speed,config.speed*1.5)*config.cadence)%(2*math.pi)
        for name,pose in Motion.pose(kind,state.phase,state.stride,state.reach,now,age) do
            local motor=state.joints[name]
            if not motor or not motor:IsDescendantOf(npc) then motor=npc:FindFirstChild(name,true);state.joints[name]=motor end
            if motor and motor:IsA('Motor6D') then motor.Transform=pose end
        end
    end
end)
