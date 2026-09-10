-- Review-only baseline; no stamina, slide, vault, enemies, or persistent rewards.
local Players=game:GetService("Players")
local folder=Instance.new("Folder"); folder.Name="FacilityMovementReview"; folder.Parent=game:GetService("ReplicatedStorage")
local remote=Instance.new("RemoteEvent"); remote.Name="Sprint"; remote.Parent=folder
local last={}
remote.OnServerEvent:Connect(function(player,active)
 if typeof(active)~="boolean" or not workspace:FindFirstChild("FacilityLayoutReview") then return end
 local now=os.clock()
 if active and now-(last[player] or 0)<.1 then return end
 last[player]=now
 local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if hum and hum.Health>0 then hum.WalkSpeed=active and 24 or 16 end
end)
Players.PlayerRemoving:Connect(function(player) last[player]=nil end)
