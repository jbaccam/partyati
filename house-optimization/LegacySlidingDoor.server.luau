

local Door = script.Parent.Door
local Button1 = script.Parent:FindFirstChild("Button1")
local Button2 = script.Parent:FindFirstChild("Button2")
local Open = false




local Debounce = false
function ButtonClicked(Player)
	local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
 local near = root and ((Button1 and (root.Position-Button1.Position).Magnitude <= 16) or (Button2 and (root.Position-Button2.Position).Magnitude <= 16))
 if not near then return end
 if not Debounce then
		Debounce = true
		if Open then
			Open = false
			
			Door.Transparency = 0.6
			for i,v in pairs(Door:GetChildren()) do
				if v:IsA("Decal") then
					v.Transparency = 0.6
				end
			end
			for i = 1,(Door.Size.z / 0.30) do
				Door.CFrame = Door.CFrame + (Door.CFrame.lookVector * 0.30)
				wait()
			end
		else
			Open = true
			
			for i = 1,(Door.Size.z / 0.30) do
				Door.CFrame = Door.CFrame - (Door.CFrame.lookVector * 0.30)
				wait()
			end
			Door.Transparency = 0.6
			for i,v in pairs(Door:GetChildren()) do
				if v:IsA("Decal") then
					v.Transparency = 0.6
				end
			end
		end
		wait(0.4)
		Debounce = false
	end
end
if Button1 and Button1:FindFirstChildOfClass("ClickDetector") then Button1:FindFirstChildOfClass("ClickDetector").MouseClick:Connect(ButtonClicked) end
if Button2 and Button2:FindFirstChildOfClass("ClickDetector") then Button2:FindFirstChildOfClass("ClickDetector").MouseClick:Connect(ButtonClicked) end

