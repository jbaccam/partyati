-- Deterministic client presentation. Server timestamps align the slam with damage.
local M={}
local function cf(x,y,z,lift,forward)
    return CFrame.new(0,lift or 0,-(forward or 0))*CFrame.Angles(math.rad(x or 0),math.rad(y or 0),math.rad(z or 0))
end
local function smooth(t) return t*t*(3-2*t) end
local slamKeys={
    {t=0,waist=-26,neck=16,shoulder=25,elbow=12,wrist=-8,root=-.03,lift=0},
    {t=.32,waist=-16,neck=12,shoulder=154,elbow=18,wrist=-12,root=-.08,lift=.08},
    {t=.46,waist=-48,neck=24,shoulder=60,elbow=4,wrist=8,root=-.06,lift=-.80},
    {t=.58,waist=-46,neck=22,shoulder=58,elbow=7,wrist=4,root=-.05,lift=-.73},
    {t=1,waist=-26,neck=16,shoulder=25,elbow=12,wrist=-8,root=-.03,lift=0},
}
function M.slam(age)
    local a,b=slamKeys[1],slamKeys[2]
    for i=2,#slamKeys do a,b=slamKeys[i-1],slamKeys[i];if age<=b.t then break end end
    local alpha=math.clamp((age-a.t)/(b.t-a.t),0,1)
    alpha=(b.t==.46) and alpha*alpha or smooth(alpha)
    local v={};for _,key in {'waist','neck','shoulder','elbow','wrist','root','lift'} do v[key]=a[key]+(b[key]-a[key])*alpha end
    local poses={Root=cf(0,0,0,v.root),Waist=cf(v.waist,0,0,v.lift),Neck=cf(v.neck)}
    for _,side in {'Left','Right'} do
        local sign=side=='Left' and 1 or -1
        poses[side..'Shoulder']=cf(v.shoulder,0,sign*-4)
        poses[side..'Elbow']=cf(v.elbow);poses[side..'Wrist']=cf(v.wrist)
        poses[side..'Hip']=cf(7);poses[side..'Knee']=cf(-13);poses[side..'Ankle']=cf(6)
    end
    return poses
end
function M.pose(kind,phase,stride,reach,clock,attackAge)
    if kind=='Mutant' and attackAge and attackAge>=0 and attackAge<=1 then return M.slam(attackAge) end
    local step=math.sin(phase);local bounce=math.cos(phase*2);local idle=math.sin(clock*2.1)*.012
    local poses={};local mutant=kind=='Mutant';local baby=kind=='Baby'
    for _,side in {'Left','Right'} do
        local s=side=='Left' and 1 or -1;local wave=step*s
        poses[side..'Shoulder']=cf(mutant and (25+wave*9*stride) or (83*reach+wave*5*stride),0,s*(mutant and -3 or 3)*reach,wave*(mutant and .07 or .035)*stride)
        poses[side..'Elbow']=cf(mutant and 12 or 8*reach+math.sin(phase-.4)*s*2*stride)
        poses[side..'Wrist']=cf(mutant and -8 or -5*reach)
        poses[side..'Hip']=cf((mutant and 5 or 0)+wave*(mutant and 22 or 34)*stride)
        poses[side..'Knee']=cf((mutant and -8 or 0)-math.max(0,-wave)*(mutant and 24 or 42)*stride)
        poses[side..'Ankle']=cf((mutant and 3 or 0)-wave*8*stride)
    end
    poses.Root=cf(0,0,0,mutant and -.03 or 0)
    poses.Waist=cf((mutant and -26 or -7*reach)+bounce*1.5*stride,math.cos(phase)*2*stride,step*(mutant and 4 or 3.5)*stride,idle+bounce*(mutant and .08 or baby and .045 or .055)*stride)
    poses.Neck=cf((mutant and 16 or 5*reach)-math.cos(phase*2-.35)*1.5*stride,0,mutant and 0 or 3-math.sin(phase-.25)*2*stride)
    return poses
end
return M
