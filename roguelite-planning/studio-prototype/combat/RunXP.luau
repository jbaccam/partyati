-- Pure run progression. No persistent/account XP and no client award remote.
local X={XP_PER_SHARD=1,MAX_LEVEL=1000}
function X.required(level) return 20+(math.clamp(level,1,X.MAX_LEVEL)-1)*10 end
function X.add(level,xp,amount)
 if type(amount)~='number' or amount~=amount or amount%1~=0 or amount<0 or amount>1000000 then return level,xp,0 end
 local gained=0
 xp+=amount
 while level<X.MAX_LEVEL and xp>=X.required(level) do xp-=X.required(level);level+=1;gained+=1 end
 if level==X.MAX_LEVEL then xp=math.min(xp,X.required(level)) end
 return level,xp,gained
end
return X
