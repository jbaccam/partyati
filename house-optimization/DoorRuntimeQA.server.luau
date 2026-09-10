local HttpService=game:GetService("HttpService")
local h=script.Parent
local states=require(h.DoorRuntime).controllers
local player=game:GetService("Players"):GetPlayers()[1]
local char=player.Character
local root=char:FindFirstChild("HumanoidRootPart")
local original=char:GetPivot()
local anchored=root.Anchored
root.Anchored=true
local results={doors=#states,passed=0,failures={}}
local function check(condition,label) if not condition then table.insert(results.failures,label) end end
for i,s in ipairs(states) do
 local label=tostring(i)..":"..s.door.Name
 check(not s.toggle(nil),label.." nil player")
 char:PivotTo(CFrame.new(0,2000,0))
 check(not s.toggle(player),label.." distance rejection")
 char:PivotTo(CFrame.new(s.prompt.Parent.Position+Vector3.new(0,0,2)))
 s.door:SetAttribute("Locked",true)
 check(not s.toggle(player),label.." lock rejection")
 s.door:SetAttribute("Locked",nil)
 local startOpen=s.opened
 check(s.toggle(player),label.." first toggle")
 check(not s.toggle(player),label.." debounce")
 task.wait(.7)
 check(s.opened~=startOpen,label.." changed state")
 for _,g in ipairs(s.groups)do
 local target=s.opened and g.open or g.closed
 check((g.hinge.CFrame.Position-target.Position).Magnitude<.01 and g.hinge.CFrame.LookVector:Dot(target.LookVector)>.999,label.." endpoint")
 for j,p in ipairs(g.parts)do
 local expected=target*g.offsets[j]
 check((p.Position-expected.Position).Magnitude<.01,label.." panel offset")
 end
 end
 check(s.toggle(player),label.." second toggle")
 task.wait(.7)
 check(s.opened==startOpen,label.." return state")
 if #results.failures==0 then results.passed+=1 end
end
char:PivotTo(original) root.Anchored=anchored
script:SetAttribute("Result",HttpService:JSONEncode(results))
