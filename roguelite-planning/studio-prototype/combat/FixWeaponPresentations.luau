-- Edit-only migration of the six requested combat copies, not showcase assets.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play before applying')
local combat=game.ReplicatedStorage.RogueliteCombat
local P=require(combat.WeaponPresentation)
local plans={}
for _,id in {'01','06','12','13','26','30','32'} do
 local plan=P.prepare(combat.WeaponTemplates[id])
 if plan then table.insert(plans,plan) end
end
for _,plan in plans do P.commit(plan) end
P.stabilizeLauncher(combat.WeaponTemplates['11'])
return {updated=#plans}
