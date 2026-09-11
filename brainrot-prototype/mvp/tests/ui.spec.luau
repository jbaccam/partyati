-- Read-only client smoke checks. Execute this source in the Client datamodel after
-- installation; no remote firing, purchases, selection changes, or test health.
local Players=game:GetService("Players")
local player=Players.LocalPlayer
assert(player,"Run UI tests in Client, not Server")
local package=game.ReplicatedStorage:WaitForChild("TungPrototype")
local roster=require(package.FighterDefinitions)
local gui=player.PlayerGui:WaitForChild("TungPrototypeControls",10)
assert(gui and gui:FindFirstChild("FightersButton"),"Missing fighter menu toggle")
local selector=gui:FindFirstChild("FighterSelector")
assert(selector and selector:FindFirstChild("Close"),"Selector must be dismissible")
local count=0
for _,id in {"tung_sahur","tralalero","chimpanzini","ballerina","bombardiro"} do
 local f=roster.ById[id];assert(f and f.MVP,"Expected selectable MVP: "..id)
 local card=selector.FighterCards:FindFirstChild(id)
 assert(card and card:IsA("TextButton") and card.Selectable,"Missing selectable fighter card: "..id)
 local selectionLabel=card:FindFirstChild("Selected")
 assert(selectionLabel and selectionLabel:IsA("TextLabel"),"Missing selection label (use child reference, not GuiButton.Selected)")
 assert(card.FighterName.Text==f.DisplayName,"Wrong fighter label")
 assert(card.Moves.Text:find(f.Ultimate.Name,1,true),"Missing ultimate name")
 count+=1
end
for _,child in selector.FighterCards:GetChildren() do
 if child:IsA("TextButton") then count-=1 end
end
assert(count==0,"Only the five MVP fighters should be selectable")
local hud=player.PlayerGui:WaitForChild("TungCombatHUD",10)
assert(hud and hud:FindFirstChild("SprintToggle"),"Missing touch sprint control")
assert(hud.AbilityBar:FindFirstChild("SkillStrip"),"Missing server-authorized sprint strike feedback")
assert(hud.AbilityBar.SkillStrip:FindFirstChild("SprintStrike"),"Missing sprint strike state label")
assert(hud.AbilityBar.SkillStrip:FindFirstChild("TimingHint"),"Missing movement timing hint")
assert(hud.AbilityBar:FindFirstChild("PracticeStocks"),"Missing conditional stock counter")
assert(hud.AbilityBar:FindFirstChild("AbilityHint"),"Missing ability explanation hint")
assert(hud.AbilityBar.R:FindFirstChild("MotionTrack"),"Missing finite recovery duration meter")
assert(package:FindFirstChild("CombatSteer") and package.CombatSteer:IsA("RemoteEvent"),"Missing server-validated flight heading intent")
assert(package:FindFirstChild("CombatMoveIntent") and package.CombatMoveIntent:IsA("RemoteEvent"),"Missing movement intent remote")
local character=player.Character
if character and character:GetAttribute("TungSahurActive") then
 local f=roster.ById[character:GetAttribute("FighterId") or "tung_sahur"]
 assert(hud.AbilityBar.FighterStrip.Fighter.Text==string.upper(f.DisplayName),"HUD title stale after switch")
 for _,key in {"M1","Q","E","R","F"} do
  local name=key=="M1" and f.Basic.Name or key=="F" and f.Ultimate.Name or f.Abilities[key].Name
  assert(hud.AbilityBar[key]:FindFirstChild("Name").Text==name,"HUD ability stale: "..key)
 end
 local now=workspace:GetServerTimeNow()
 if character:GetAttribute("SprintStrikeReady")~=true and (character:GetAttribute("SprintStrikeUntil") or 0)<=now then
  assert(not hud.AbilityBar.SkillStrip.SprintStrike.Text:find("READY",1,true),"Client must not invent sprint-strike readiness")
 end
 if player:GetAttribute("SmashPracticeActive")~=true then
  assert(not hud.AbilityBar.PracticeStocks.Visible,"Practice lives must stay hidden outside practice")
 end
end
return "UI smoke checks passed: five cards, dismiss control, sprint control, active fighter labels, server-ready feedback, conditional stocks"
