-- Server-owned enemy movement and test-wave lifecycle. Katana damage is in RogueliteCombat.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local combat = game:GetService('ReplicatedStorage'):WaitForChild('RogueliteCombat')
local Death = require(combat:WaitForChild('ZombieDeath'))
local Types = require(combat:WaitForChild('ZombieTypes'))
local Attacks = require(script.Parent:WaitForChild('ZombieAttacks'))
local waveGeneration = 0

combat:SetAttribute('ZombieCount',combat:GetAttribute('ZombieCount') or 5)
local function spawnCount() return math.clamp(combat:GetAttribute('ZombieCount') or 5,0,100) end
local COLLISION_GROUP = "RogueliteZombies"
if not PhysicsService:IsCollisionGroupRegistered(COLLISION_GROUP) then
    PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
end
PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)

local PLAYER_BASE_SPEED = 18
local ZOMBIE_SPEED = 12 -- Gentle reduction from 13.5 for more room to dodge.
local templates = ServerStorage:WaitForChild("RogueliteNPCs")
local template = templates:WaitForChild("Zombie_NPC")
local folder = Instance.new("Folder")
folder.Name = "RogueliteEnemies"
folder.Parent = workspace

local marker = workspace:WaitForChild("RogueliteZombieSpawn")
local spawnZombie
spawnZombie = function(index)
if combat:GetAttribute('ZombiesEnabled') ~= true or index>spawnCount() then return end
if folder:FindFirstChild(string.format('Zombie_%02d',index)) then return end
local thisWave = waveGeneration
local run=game:GetService('ReplicatedStorage'):FindFirstChild('RogueliteRunState')
local wave=run and run:GetAttribute('Wave') or 1
local kind=Types.forSlot(index,wave)
local config=Types.scaled(kind,wave)
local selected=templates:FindFirstChild(config.template)
if not selected then kind='Regular';config=Types.scaled(kind,wave);selected=template end
local npc = selected:Clone()
npc.Name = string.format("Zombie_%02d", index)
npc:SetAttribute("SpawnIndex", index)
npc:SetAttribute('ZombieType',kind)
npc:SetAttribute('ContactDamage',config.damage)
npc:SetAttribute('SlamDamage',config.slamDamage)
npc:SetAttribute('SpawnWave',wave)
npc:SetAttribute('ContactRange',config.contactRange)
npc.Parent = folder
local root = npc:WaitForChild("HumanoidRootPart")
local humanoid = npc:WaitForChild("Humanoid")
humanoid.MaxHealth = config.health
humanoid.Health = humanoid.MaxHealth
humanoid.BreakJointsOnDeath = false
humanoid.Died:Connect(function() Death.finish(npc) end)
-- Schedule replacements in this script's lifecycle, independently of the damage caller.
npc.Destroying:Connect(function()
    if not npc:GetAttribute('DeathPopped') then return end
    task.delay(3, function()
        if thisWave == waveGeneration and combat:GetAttribute('ZombiesEnabled') then spawnZombie(index) end
    end)
end)
local angle = (index - 1) * math.pi * 2 / math.max(1,spawnCount())
local position = marker.Position + Vector3.new(math.cos(angle) * 10, 0, math.sin(angle) * 10)
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.FilterDescendantsInstances = {folder, marker, workspace:FindFirstChild("Zombie_R15_ProvidedTextures_Studio")}
local ground = workspace:Raycast(position + Vector3.new(0, 30, 0), Vector3.new(0, -100, 0), groundParams)
if ground then position = Vector3.new(position.X, ground.Position.Y + humanoid.HipHeight + root.Size.Y / 2 + 0.1, position.Z) end
npc:PivotTo(CFrame.new(position) * marker.CFrame.Rotation)
for _, part in npc:GetDescendants() do
    if part:IsA("BasePart") then
        part.Anchored = false
        part.CollisionGroup = COLLISION_GROUP
    end
end
root:SetNetworkOwner(nil)
humanoid.WalkSpeed = config.speed
npc:SetAttribute('BaseMoveSpeed',config.speed)
humanoid.AutoRotate = true
humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
CollectionService:AddTag(npc, "RogueliteZombie")

local waypoints, waypointIndex = nil, 1
local computing, lastPath, generation = false, -math.huge, 0
local previousTarget = nil
local elapsed = 0
local function nearestTarget()
    local best, distance = nil, math.huge
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
        if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
            local offset=targetRoot.Position-root.Position
            local d = Vector2.new(offset.X,offset.Z).Magnitude
            if d < distance then best, distance = targetRoot, d end
        end
    end
    return best, distance
end

local connection
connection = RunService.Heartbeat:Connect(function(dt)
    if not npc.Parent or humanoid.Health <= 0 then
        generation += 1
        npc:SetAttribute("Chasing", false)
        connection:Disconnect()
        return
    end
    if Attacks.update(npc,previousTarget) then return end
    elapsed += dt
    if elapsed < 0.1 then return end
    elapsed = 0
    local target, distance = nearestTarget()
    if target ~= previousTarget then
        previousTarget = target
        generation += 1
        waypoints = nil
    end
    npc:SetAttribute("Chasing", target ~= nil)
    npc:SetAttribute("TargetUserId", target and Players:GetPlayerFromCharacter(target.Parent).UserId or 0)
    if not target then
        humanoid:Move(Vector3.zero)
        humanoid:MoveTo(root.Position)
        return
    end
    -- Gentle separation keeps the five bodies readable without pushing physics piles.
    local separation = Vector3.zero
    for _, other in folder:GetChildren() do
        local otherRoot = other ~= npc and other:FindFirstChild("HumanoidRootPart")
        if otherRoot then
            local delta = root.Position - otherRoot.Position
            delta = Vector3.new(delta.X, 0, delta.Z)
            local spacing = delta.Magnitude
            if spacing > 0.01 and spacing < 4.5 then
                separation += delta.Unit * (1 - spacing / 4.5)
            end
        end
    end
    if distance < config.stopRange and separation.Magnitude < 0.15 then
        humanoid:Move(Vector3.zero)
        humanoid:MoveTo(root.Position)
        return
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {folder, target.Parent, marker}
    local obstruction = workspace:Raycast(root.Position, target.Position - root.Position, params)
    if not obstruction then
        waypoints = nil
        local delta = target.Position - root.Position
        local flat = Vector3.new(delta.X, 0, delta.Z)
        local direction = (distance >= config.stopRange and flat.Magnitude > 0.01) and flat.Unit or Vector3.zero
        direction += separation * 1.8
        if direction.Magnitude > 0.05 then
            humanoid:MoveTo(root.Position + direction.Unit * math.min(8, math.max(distance - config.stopRange + 1, 1)))
        else
            humanoid:MoveTo(root.Position)
        end
        return
    end
    if not computing and os.clock() - lastPath > 1 then
        computing = true
        lastPath = os.clock()
        local requestGeneration = generation
        local start, finish = root.Position, target.Position
        task.spawn(function()
            local path = PathfindingService:CreatePath({AgentRadius = config.radius, AgentHeight = config.height, AgentCanJump = kind~='Mutant', WaypointSpacing = 4})
            local ok = pcall(function() path:ComputeAsync(start, finish) end)
            if requestGeneration == generation and npc.Parent and humanoid.Health > 0 then
                if ok and path.Status == Enum.PathStatus.Success then
                    waypoints, waypointIndex = path:GetWaypoints(), 2
                else
                    waypoints = nil
                end
            end
            computing = false
        end)
    end
    local point = waypoints and waypoints[waypointIndex]
    if point then
        if (Vector3.new(point.Position.X, root.Position.Y, point.Position.Z) - root.Position).Magnitude < 2 then
            waypointIndex += 1
            point = waypoints[waypointIndex]
        end
        if point then
            if point.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            humanoid:MoveTo(point.Position)
        end
    else
        humanoid:Move(Vector3.zero) -- Do not keep pushing through an unreachable obstacle.
    end
end)
end

local function resetWave()
    waveGeneration += 1
    for _,npc in folder:GetChildren() do
        if not npc:GetAttribute('IsHammerBoss') or not combat:GetAttribute('ZombiesEnabled') then npc:Destroy() end
    end
    if combat:GetAttribute('ZombiesEnabled') then
        for index = 1, spawnCount() do spawnZombie(index) end
    end
end
combat:GetAttributeChangedSignal('ZombiesEnabled'):Connect(resetWave)
combat:GetAttributeChangedSignal('ZombieCount'):Connect(resetWave)
resetWave()
