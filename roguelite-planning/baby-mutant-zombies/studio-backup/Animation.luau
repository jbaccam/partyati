-- Procedural R15 locomotion. Runs on every client; no animation upload required.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local WALK_SPEED = 13.5
local tracked = {}
local function track(npc)
    if tracked[npc] then return end
    local joints = {}
    for _, item in npc:GetDescendants() do
        if item:IsA("Motor6D") then joints[item.Name] = item end
    end
    -- Offset each spawn's step so a group does not march in lockstep.
    local phase = ((npc:GetAttribute("SpawnIndex") or 1) * 2.399963229728653) % (math.pi * 2)
    tracked[npc] = {joints = joints, phase = phase, reach = 0, stride = 0}
end
CollectionService:GetInstanceAddedSignal("RogueliteZombie"):Connect(track)
CollectionService:GetInstanceRemovedSignal("RogueliteZombie"):Connect(function(npc) tracked[npc] = nil end)
for _, npc in CollectionService:GetTagged("RogueliteZombie") do track(npc) end
RunService.PreSimulation:Connect(function(dt)
    for npc, state in tracked do
        local root = npc:FindFirstChild("HumanoidRootPart")
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        if not npc.Parent then tracked[npc] = nil continue end
        if not root or not humanoid then continue end
        local alive = humanoid.Health > 0
        local velocity = root.AssemblyLinearVelocity
        local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        local blend = 1 - math.exp(-dt * 10)
        state.reach += ((alive and npc:GetAttribute("Chasing") and 1 or 0) - state.reach) * blend
        local walking = alive and humanoid.FloorMaterial ~= Enum.Material.Air and speed > 0.35
        state.stride += ((walking and math.clamp(speed / WALK_SPEED, 0, 1) or 0) - state.stride) * blend
        state.phase = (state.phase + dt * math.min(speed, WALK_SPEED * 1.5) * 0.75) % (math.pi * 2)
        local step = math.sin(state.phase)
        local bounce = math.cos(state.phase * 2)
        local function pose(name, x, y, z, lift)
            local motor = state.joints[name]
            if not motor or not motor:IsDescendantOf(npc) then
                motor = npc:FindFirstChild(name, true)
                state.joints[name] = motor
            end
            if motor and motor:IsA("Motor6D") then
                motor.Transform = CFrame.new(0, lift or 0, 0)
                    * CFrame.Angles(math.rad(x), math.rad(y or 0), math.rad(z or 0))
            end
        end
        for _, side in {"Left", "Right"} do
            local sign = side == "Left" and 1 or -1
            local wave = step * sign
            -- Small opposing shoulder lifts keep the forward reach loose at each footfall.
            pose(side.."Shoulder", 83 * state.reach + wave * 5 * state.stride, 0,
                sign * 3 * state.reach, wave * 0.045 * state.stride)
            pose(side.."Elbow", 8 * state.reach + math.sin(state.phase - 0.4) * sign * 2 * state.stride)
            pose(side.."Wrist", -5 * state.reach)
            pose(side.."Hip", wave * 34 * state.stride)
            pose(side.."Knee", -math.max(0, -wave) * 42 * state.stride)
            pose(side.."Ankle", -wave * 8 * state.stride)
        end
        -- Two gentle rises per stride; torso roll makes one shoulder lead the other.
        -- Animate above the hips so the legs and authoritative root stay grounded.
        pose("Waist", -7 * state.reach + bounce * 1.5 * state.stride,
            math.cos(state.phase) * 2 * state.stride, step * 3.5 * state.stride,
            bounce * 0.055 * state.stride)
        pose("Neck", 5 * state.reach - math.cos(state.phase * 2 - 0.35) * 1.5 * state.stride,
            0, 3 - math.sin(state.phase - 0.25) * 2 * state.stride)
    end
end)

