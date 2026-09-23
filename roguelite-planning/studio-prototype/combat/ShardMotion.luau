local M={REST_SECONDS=.3,PULL_SECONDS=.42,BOB_HEIGHT=.16}
function M.idle(origin,born,now)
 return origin+Vector3.new(0,math.sin((now-born)*2.7+born%6.28)*M.BOB_HEIGHT,0)
end
function M.pull(origin,target,elapsed)
 local t=math.clamp(elapsed/M.PULL_SECONDS,0,1)
 return origin:Lerp(target,t*t)
end
return M
