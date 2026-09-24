return function(combat)
 local M=require(combat.WeaponMotion);local C=require(combat.ChainWeaponMotion);local P=require(combat.SpecialMotion)
 local checks=0
 local function check(ok,msg) checks+=1;assert(ok,msg) end
 local root=CFrame.new(0,5,0);local aim=Vector3.new(0,5,-5)
 for _,id in {'01','03','05','06','16','20','26','27','31','32'} do
  local template=combat.WeaponTemplates[id];local size=template:GetAttribute('BoundsSize');local center=template:GetAttribute('BoundsCenter')
  local function pose(age,style,side) return M.pose(root,4.2,1,aim,0,age,'Melee',id,root.LookVector,8,size,center,style,side) end
  for _,style in {'Horizontal','Diagonal','Slap','Downward','Thrust'} do
   local hitStart=M.attackTiming(id,'Melee',style)
   check(not select(2,pose(hitStart-.001,style,1)),'Windup damages '..id)
   check(select(2,pose(hitStart+.001,style,1)),'Strike inactive '..id)
   for _,age in {.12,.22,.33,.46} do
    local a,b=pose(age,style,1),pose(age,style,-1)
    if style~='Thrust' then
     check(math.abs(a.X+b.X)<1e-4 and math.abs(a.Y-b.Y)<1e-4 and math.abs(a.Z-b.Z)<1e-4,'Combo is not mirrored')
    end
   end
   local cut=pose(M.SwingHitEnd,style,1)
   local idle=CFrame.new(4.2,5.25,0);local state={};local previous=cut
   for i=0,120 do
    local age=M.SwingHitEnd+(M.SwingDuration-M.SwingHitEnd)*i/120
    local cf=M.swingReturn(cut,idle,age,state,id,style)
    check((cf.Position-previous.Position).Magnitude<.6,'Recovery position jump')
    check(cf.UpVector:Dot(previous.UpVector)>.98,'Recovery rotation jump')
    previous=cf
   end
   check((previous.Position-idle.Position).Magnitude<.001,'Recovery must settle')
  end
  local hitStart,hitEnd,duration=M.attackTiming(id,'Melee','Downward')
  local horizontalStart,horizontalEnd,horizontalDuration=M.attackTiming(id,'Melee','Horizontal')
  check(hitStart==horizontalStart and hitEnd==horizontalEnd and duration==horizontalDuration,'Downward and horizontal timing must match')
  local apex,middle,impact=pose(hitStart,'Downward',1),pose((hitStart+hitEnd)*.5,'Downward',1),pose(hitEnd,'Downward',1)
  local grip=Vector3.new(0,center.Y-size.Y*.42,0)
  local head=Vector3.new(0,center.Y+size.Y*.5,0)
  local ga,gi=apex:PointToWorldSpace(grip),impact:PointToWorldSpace(grip)
  local ha,hm,hi=apex:PointToWorldSpace(head),middle:PointToWorldSpace(head),impact:PointToWorldSpace(head)
  check(ga.Z-gi.Z>2.8,'Overhead grip needs room to drive forward')
  check(math.abs(ga.Y-gi.Y)<1,'Overhead hand drops instead of swinging')
  check(ha.Z-hi.Z>2 and ha.Y-hi.Y>size.Y,'Overhead head must swing forward and down')
  check((hm-(ha+hi)*.5).Magnitude>size.Y*.5,'Overhead head takes a straight drop instead of an arc')
  for i=0,24 do
   local cf=pose(hitStart+(hitEnd-hitStart)*i/24,'Downward',1)
   check(math.abs((cf:PointToWorldSpace(head)-cf:PointToWorldSpace(grip)).Magnitude-size.Y*.92)<1e-4,'Overhead lever length changes')
  end
  if id=='31' then
   for _,side in {-1,1} do
    for _,age in {.20,.29,.37} do
     local cf=pose(age,'Downward',side)
     local before=pose(age-.001,'Downward',side):PointToWorldSpace(head)
     local after=pose(age+.001,'Downward',side):PointToWorldSpace(head)
     check(cf.RightVector:Dot((after-before).Unit)>.85,'Hammer end face must lead the downward stroke')
    end
   end
  end
 end
 for i=1,8 do
  check(M.chooseSide(i)~=M.chooseSide(i+1),'Combination side repeats')
  check(M.chooseStyle('32',3,i)=='Horizontal','Excalibur style changed')
 end
 for _,id in {'02','04','25'} do
  local rig=C.bind(combat.WeaponTemplates[id],id);check(rig~=nil,'Missing chain rig')
  for _,style in (id=='02' and {'FigureEight','Spin'} or {'Horizontal'}) do
   for i=0,60 do
    local age=M.SwingHitStart+(M.SwingHitEnd-M.SwingHitStart)*i/60
    local cf=C.pose(rig,root,root.LookVector,aim,age,6,style,1)
    local _,boxes=C.sample(rig,age,cf)
    for _,box in boxes do
     check(box.cf.Position.Magnitude<100,'Chain escaped bounds')
     check(box.size.X>0 and box.size.Y>0 and box.size.Z>0,'Invalid chain hit box')
    end
   end
  end
 end
 local a=P.rotation('31',0,Vector3.new(0,0,-1));local previous=a;local maxRock=0
 for i=1,480 do
  local cf=P.rotation('31',i/60,Vector3.new(0,0,-1))
  local _,angle=a:ToObjectSpace(cf):ToAxisAngle();maxRock=math.max(maxRock,angle)
  check(angle<math.rad(18),'Hammer rocks too far or tumbles')
  local _,step=previous:ToObjectSpace(cf):ToAxisAngle()
  check(step<math.rad(4),'Hammer flight rotation snaps');previous=cf
 end
 check(M.attackReach('31','Downward',8)==10,'Hammer overhead reach must extend to ten studs')
 check(M.attackReach('31','Horizontal',8)==8,'Hammer horizontal reach must remain eight studs')
 check(M.attackReach('31','Diagonal',8)==8,'Hammer diagonal reach must remain eight studs')
 for id in M.DownwardWeapons do
  for _,baseRange in {4,6,8,12} do
   check(M.attackReach(id,'Downward',baseRange)==baseRange*1.25,'Every overhead needs extended reach')
   check(M.attackReach(id,'Horizontal',baseRange)==baseRange,'Horizontal reach changed')
   for serial=1,6 do
    local close=M.chooseStyle(id,1,serial,baseRange*.75,baseRange)
    check(close==M.chooseStyle(id,1,serial),'Close combinations changed')
    local far=M.chooseStyle(id,1,serial,baseRange*1.2,baseRange)
    check(id=='31' or far=='Downward','Outer target must select a reachable strike')
   end
  end
 end
 check(M.attackReach('31','Downward',12)==15,'Hammer overhead must respect range modifiers')
 check(maxRock>math.rad(8),'Hammer flight is too stiff')
 check(P.profiles['31'].height==0,'Hammer path is not straight')
 return {checks=checks}
end
