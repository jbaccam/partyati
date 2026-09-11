-- Pure stock accounting. A particular character can lose at most one stock.
local Rules={StockCount=4,ResetDelay=4}
function Rules.New()
 return {stocks=Rules.StockCount,alive=false,serial=0,resetAt=nil}
end
function Rules.Spawn(state,now)
 if state.stocks<=0 then
  if now<(state.resetAt or math.huge) then return nil end
  state.stocks=Rules.StockCount;state.resetAt=nil
 end
 state.serial+=1;state.alive=true
 return state.serial
end
function Rules.Lose(state,serial,now)
 if not state.alive or serial~=state.serial then return false end
 state.alive=false;state.stocks=math.max(0,state.stocks-1)
 if state.stocks==0 then state.resetAt=now+Rules.ResetDelay end
 return true
end
function Rules.OutOfBounds(position,center)
 return position.Y<center.Y-28 or math.abs(position.X-center.X)>110 or math.abs(position.Z-center.Z)>110
end
return table.freeze(Rules)
