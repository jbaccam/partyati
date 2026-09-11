-- Pure server-clock rules for a deliberate sprint-reset melee bonus.
-- Client messages report movement intent only; physical eligibility is sampled by the server.
local Rules={ReleaseTime=.12,BuildTime=.18,Recharge=.7,IntentLifetime=.6,InputInterval=.04,InputBurst=4,VictimImmunity=1,Multiplier=1.2}
function Rules.new()
 return {moving=false,lastIntent=-math.huge,lastAccepted=-math.huge,lastConsumed=-math.huge,
  releaseQualified=true,ready=false,buildAt=nil,releaseAt=nil,inputCredit=Rules.InputBurst,lastRateAt=nil}
end
function Rules.intent(state,moving,now)
 if typeof(moving)~="boolean" or typeof(now)~="number" or now~=now or math.abs(now)==math.huge then return false end
 if now<state.lastAccepted then return false end
 -- Heartbeats and a genuine release can arrive in the same packet/frame. A small
 -- burst allowance preserves those edges without permitting an unbounded stream.
 state.inputCredit=math.min(Rules.InputBurst,state.inputCredit+(now-(state.lastRateAt or now))/Rules.InputInterval)
 state.lastRateAt=now
 if state.inputCredit<1 then return false end
 state.inputCredit-=1
 state.lastAccepted=now; state.lastIntent=now
 if not moving then
  if state.moving or state.releaseAt==nil then state.releaseAt=now end
  state.buildAt=nil; state.ready=false
 elseif not state.moving then
  if state.releaseAt and now-state.releaseAt>=Rules.ReleaseTime then state.releaseQualified=true end
  state.releaseAt=nil
 end
 state.moving=moving
 return true
end
function Rules.sample(state,now,physicalEligible)
 if not state.moving and state.releaseAt and now-state.releaseAt>=Rules.ReleaseTime then state.releaseQualified=true end
 local eligible=physicalEligible and state.moving and now-state.lastIntent<=Rules.IntentLifetime and state.releaseQualified
 if not eligible then state.buildAt=nil; state.ready=false; return false end
 state.buildAt=state.buildAt or now
 state.ready=now-state.buildAt>=Rules.BuildTime and now-state.lastConsumed>=Rules.Recharge
 return state.ready
end
function Rules.consume(state,now)
 if not state.ready then return false end
 state.ready=false; state.releaseQualified=false; state.releaseAt=nil; state.buildAt=nil; state.lastConsumed=now
 return true
end
function Rules.canAmplify(lastReceived,now)
 return now-(lastReceived or -math.huge)>=Rules.VictimImmunity
end
function Rules.amplify(velocity)
 return Vector3.new(velocity.X*Rules.Multiplier,velocity.Y,velocity.Z*Rules.Multiplier)
end
return Rules
