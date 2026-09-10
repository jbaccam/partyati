local Players=game:GetService("Players");local player=Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild("FacilityObjectives"):WaitForChild("Update")
local gui=Instance.new("ScreenGui");gui.Name="FacilityObjectiveFeedback";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local message=Instance.new("TextLabel");message.AnchorPoint=Vector2.new(.5,1);message.Position=UDim2.fromScale(.5,.91);message.Size=UDim2.new(.65,0,0,58);message.BackgroundColor3=Color3.fromRGB(26,34,30);message.BackgroundTransparency=.18;message.BorderSizePixel=0;message.TextColor3=Color3.fromRGB(215,214,191);message.TextSize=18;message.TextWrapped=true;message.Font=Enum.Font.Gotham;message.Visible=false;message.Parent=gui
local items=Instance.new("TextLabel");items.Position=UDim2.new(0,18,1,-125);items.Size=UDim2.new(.34,0,0,104);items.BackgroundTransparency=1;items.TextColor3=Color3.fromRGB(210,209,187);items.TextSize=15;items.TextXAlignment=Enum.TextXAlignment.Left;items.TextYAlignment=Enum.TextYAlignment.Bottom;items.TextWrapped=true;items.Font=Enum.Font.Gotham;items.Text="";items.Parent=gui
local serial=0
remote.OnClientEvent:Connect(function(data)
 if typeof(data)~="table" then return end
 items.Text=#data.items>0 and "SUPPLIES\n"..table.concat(data.items,"  •  ") or ""
 if data.message then serial+=1;local n=serial;message.Text=data.message;message.Visible=true;task.delay(7,function() if serial==n then message.Visible=false end end) end
end)
