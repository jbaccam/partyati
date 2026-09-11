local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local package = ReplicatedStorage:WaitForChild("TungPrototype")
local Config = require(package:WaitForChild("Config"))
local assets = package:WaitForChild("Assets")
local Roster=require(package:WaitForChild("FighterDefinitions"))
local Selection=require(package:WaitForChild("FighterSelectionRules"))
local requestFighter=package:FindFirstChild("RequestFighter") or Instance.new("RemoteEvent")
requestFighter.Name="RequestFighter";requestFighter.Parent=package
local chosen={}
local function status(player,message)
 player:SetAttribute("FighterSelectionStatus",message)
 player:SetAttribute("FighterSelectionAt",workspace:GetServerTimeNow())
end
local request = package:FindFirstChild("RequestMorph") or Instance.new("RemoteEvent")
request.Name = "RequestMorph"
request.Parent = package
local records = {}
local lastRequest = {}
local selected = {}
local allowed = RunService:IsStudio() or Config.EnablePublished
package:SetAttribute("Available", allowed)

local function restore(character)
	local record = records[character]
	if not record then return end
	records[character] = nil
	for _, connection in record.connections do connection:Disconnect() end
	if record.visual then record.visual:Destroy() end
	for object, properties in record.saved do
		if object.Parent then
			for property, value in properties do object[property] = value end
		end
	end
	if character.Parent then character:SetAttribute("TungSahurActive", nil) end
end

local function apply(player, character)
	if not allowed or player.Character ~= character or not selected[player] then return end
	if records[character] then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local id=chosen[player] or "tung_sahur"
	local fighter=Roster.ById[id]
	local template = fighter and assets:FindFirstChild(fighter.AssetName or "TungSahur")
	if not humanoid or humanoid.Health <= 0 or not root or not template then return end
	local source = template:FindFirstChild("Mesh")
	if not source or not source:IsA("MeshPart") or not source:FindFirstChild("Bone") then
		warn("[TungPrototype] Reviewed Tung Sahur asset is missing its skeleton.")
		return
	end
	local visual = template:Clone()
	visual.Name = Config.VisualName
	local mesh = visual:FindFirstChild("Mesh")
	visual.PrimaryPart = mesh
	-- Only our reviewed geometry clone is installed; it contains no executable code.
	for _, object in visual:GetDescendants() do
		if object:IsA("BaseScript") or object:IsA("ModuleScript") then
			visual:Destroy()
			warn("[TungPrototype] Refused executable content in visual template.")
			return
		elseif object:IsA("BasePart") then
			object.Anchored = false
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			object.Massless = true
			object.AssemblyLinearVelocity = Vector3.zero
			object.AssemblyAngularVelocity = Vector3.zero
		elseif object:IsA("Bone") then
			object.Transform = CFrame.identity
		end
	end
	local groundDistance = humanoid.HipHeight + root.Size.Y * 0.5
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = character:FindFirstChild("Left Leg")
		groundDistance += leg and leg.Size.Y or 2
	end
	-- Source geometry faces -Z. Its mesh bounds include the soles of its feet.
	local offset = CFrame.new(0, mesh.Size.Y * 0.5 - groundDistance, 0)
	visual:PivotTo(root.CFrame * offset)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "TungVisualWeld"
	weld.Part0 = root
	weld.Part1 = mesh
	weld.Parent = mesh
	local record = {visual = visual, saved = {}, connections = {}}
	records[character] = record
	local function save(object, property, value)
		record.saved[object] = record.saved[object] or {}
		if record.saved[object][property] == nil then
			record.saved[object][property] = object[property]
		end
		object[property] = value
	end
	local function hide(object)
		if object:IsDescendantOf(visual) or object == visual then return end
		if object:IsA("BasePart") or object:IsA("Decal") or object:IsA("Texture") then
			save(object, "Transparency", 1)
		elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")
			or object:IsA("BillboardGui") or object:IsA("Highlight") then
			save(object, "Enabled", false)
		end
	end
	for _, object in character:GetDescendants() do hide(object) end
	save(humanoid, "DisplayName", fighter.DisplayName)
	table.insert(record.connections, character.DescendantAdded:Connect(hide))
	table.insert(record.connections, humanoid.Died:Connect(function()
		-- Keep the visible body for the death pose until CharacterRemoving.
		if visual.Parent then visual:SetAttribute("Dead", true) end
	end))
	visual:SetAttribute("TungVersion", Config.Version)
	visual:SetAttribute("FighterId",id)
	visual:SetAttribute("RigProfile",id)
	character:SetAttribute("FighterId",id)
	visual.Parent = character
	CollectionService:AddTag(visual, Config.VisualTag)
	character:SetAttribute("TungSahurActive", true)
	return true
end

local function onCharacter(player, character)
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if humanoid and root and player.Character == character then apply(player, character) end
	end)
end

local function addPlayer(player)
	chosen[player]="tung_sahur"
	player:SetAttribute("SelectedFighterId","tung_sahur")
	selected[player] = allowed and ((RunService:IsStudio() and Config.AutoMorphInStudio)
		or (not RunService:IsStudio() and Config.AutoMorphPublished))
	player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)
	player.CharacterRemoving:Connect(restore)
	if player.Character then onCharacter(player, player.Character) end
end

request.OnServerEvent:Connect(function(player, enabled, ...)
	-- Only a boolean for the sender's own cosmetic character is accepted.
	if not allowed or typeof(enabled) ~= "boolean" or select("#", ...) ~= 0 then return end
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < Config.RequestCooldown then return end
	lastRequest[player] = now
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local ok,reason=Selection.CanSwitch(character,workspace,workspace:GetServerTimeNow())
	if not ok then status(player,reason);return end
	selected[player] = enabled
	if enabled then apply(player, character) else restore(character) end
end)
requestFighter.OnServerEvent:Connect(function(player,id,...)
 if not allowed or select("#",...)~=0 then return end
 local now=os.clock()
 if now-(lastRequest[player] or -math.huge)<Config.RequestCooldown then return end
 lastRequest[player]=now
 local fighter=Selection.ValidateId(Roster,id)
 if not fighter then status(player,"That fighter is unavailable");return end
 local character=player.Character
 if chosen[player]==id and records[character] then status(player,"Already playing "..fighter.DisplayName);return end
 local ok,reason=Selection.CanSwitch(character,workspace,workspace:GetServerTimeNow())
 if not ok then status(player,reason);return end
 local template=assets:FindFirstChild(fighter.AssetName or "")
 if not template or not template:FindFirstChild("Mesh") then status(player,"This fighter's rig is unavailable");return end
 for _,v in template:GetDescendants() do if v:IsA("LuaSourceContainer") then status(player,"Unsafe fighter template");return end end
 local previous=chosen[player]
 restore(character)
 chosen[player]=id;selected[player]=true
 if not apply(player,character) then
  chosen[player]=previous;apply(player,character)
  status(player,"Could not load that fighter");return
 end
 player:SetAttribute("SelectedFighterId",id)
 status(player,"Selected "..fighter.DisplayName)
end)
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
	if player.Character then restore(player.Character) end
	lastRequest[player] = nil
	selected[player] = nil
	chosen[player] = nil
end)
for _, player in Players:GetPlayers() do addPlayer(player) end
