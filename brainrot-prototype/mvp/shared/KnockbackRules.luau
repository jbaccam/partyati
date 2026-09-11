-- Carry hits keep a running attacker in range; finishers/abilities create ring-out pressure.
local Rules=require(script.Parent.CombatRules)
local K={}
function K.Kind(context,combo,single)
 if context=="Ultimate" then return "Ultimate" end
 if context=="M1" then return (single or combo==3) and "Finisher" or "Carry" end
 return context=="BasicProjectile" and "Finisher" or "Ability"
end
function K.Resolve(base,health,maxHealth,weight,direction,kind)
 if direction.Magnitude<.001 then return Vector3.zero,0,0 end
 local original=direction.Unit*Rules.knockback(base,health,maxHealth,weight)
 if kind=="Ultimate" then return original,0,0 end -- Preserve existing ultimate force and feel.
 local flat=Vector3.new(direction.X,0,direction.Z)
 local heading=flat.Magnitude>.001 and flat.Unit or Vector3.zero
 if kind=="Carry" then
  local speed=math.clamp(Rules.knockback(math.max(18,base*2),health,maxHealth,weight),13,27)
  return heading*speed+Vector3.yAxis*11,.12,.12
 end
 local scale=kind=="Finisher" and 1.5 or 1.4
 local v=original*scale
 local horizontal=Vector3.new(v.X,0,v.Z)
 if horizontal.Magnitude>105 then horizontal=horizontal.Unit*105 end
 local up=math.clamp(v.Y,0,65)
 if heading.Magnitude>0 and base>=20 then up=math.max(up,kind=="Finisher" and 23 or 18) end
 return horizontal+Vector3.yAxis*up,kind=="Finisher" and .20 or .18,.15
end
return table.freeze(K)
