-- Shared deterministic rules. Clients use these only for presentation.
local Rules={}
function Rules.damage(base, stacks)
 return base*(1+0.03*math.clamp(stacks,0,3))
end
-- Root-to-landing drop, excluding standing root clearance; ordinary hop is free.
function Rules.slamDamage(drop)
 return 12+math.clamp((drop-6)*0.5,0,18)
end
function Rules.knockback(base, health, maxHealth, weight)
 return base*(1+(1-math.clamp(health/math.max(maxHealth,1),0,1))*1.1)/math.max(weight,0.1)
end
function Rules.combo(previous,last,now)
 return now-last>0.8 and 1 or previous%3+1
end
function Rules.aim(value)
 if typeof(value)~="Vector3" then return nil end
 for _,v in {value.X,value.Y,value.Z} do
  if v~=v or math.abs(v)>10000 then return nil end
 end
 local flat=Vector3.new(value.X,0,value.Z)
 if flat.Magnitude<0.001 then return nil end
 return flat.Unit
end
function Rules.decay(stacks,lastDecay,now)
 local ticks=math.max(0,math.floor((now-lastDecay)/2.25))
 return math.max(0,stacks-ticks),lastDecay+ticks*2.25
end
-- A vertical capsule of total half-height halfHeight and hemispherical radius radius.
function Rules.capsuleInSphere(center,attackRadius,target,radius,halfHeight)
 local segment=math.max(0,halfHeight-radius)
 local nearest=target+Vector3.new(0,math.clamp(center.Y-target.Y,-segment,segment),0)
 return (nearest-center).Magnitude<=attackRadius+radius
end
return table.freeze(Rules)
