-- The exported poses drive rendering AND authoritative weapon collision.
local D=require(script.Parent.BossData)
local M={Data=D,RootHeight=D.rootHeight,HeadSize=Vector3.new(table.unpack(D.hammerHeadSize))}
local headRest=CFrame.new(table.unpack(D.hammerHeadRest))
M.Attacks={
 Slam={anticipation=5/30,active=23/30,finish=24/30,duration=50/30,cooldown=2.65,damage=24,radius=3.5},
 Swing={anticipation=6/30,active=19/30,finish=25/30,duration=54/30,cooldown=2.95,damage=18},
 Spin={anticipation=6/36,active=21/36,finish=37/36,duration=66/36,cooldown=4.15,damage=22},
}
local clips={}
for name,clip in D.clips do
 local frames={}
 for i,frame in clip.frames do local poses={};for part,values in frame do poses[part]=CFrame.new(table.unpack(values)) end;frames[i]=poses end
 clips[name]={frames=frames,duration=clip.lastFrame/clip.fps,last=clip.lastFrame,fps=clip.fps}
end
function M.duration(name) return clips[name].duration end
function M.sample(name,time,looped)
 local clip=assert(clips[name],'Unknown boss clip')
 if looped then time=time%clip.duration end
 local f=math.clamp(time*clip.fps,0,clip.last);local i=math.floor(f)+1;local j=math.min(i+1,#clip.frames);local alpha=f%1
 local result={}
 for part,cf in clip.frames[i] do result[part]=cf:Lerp(clip.frames[j][part],alpha) end
 return result
end
function M.head(root,clip,time)
 return root*M.sample(clip,time).Hammer*headRest
end
function M.reach(clip)
 local a=M.Attacks[clip];local p=M.head(CFrame.identity,clip,a.active).Position
 return Vector2.new(p.X,p.Z).Magnitude
end
function M.active(clip,time)
 local a=M.Attacks[clip];return a~=nil and time>=a.active and time<=a.finish
end
function M.apply(npc,poses)
 local rest={HumanoidRootPart=CFrame.identity}
 for name in D.parts do
  local part=npc:FindFirstChild(name)
  if part then rest[name]=part:GetAttribute('BossRest') end
 end
 for name,joint in D.joints do
  local m=npc:FindFirstChild('Boss_'..name,true)
  if m and rest[name] then
   local parentPose=joint.parent=='HumanoidRootPart' and CFrame.identity or poses[joint.parent]
   local parentRest=rest[joint.parent]
   if parentPose and parentRest then
    m.Transform=m.C0:Inverse()*(parentPose*parentRest):Inverse()*(poses[name]*rest[name])*m.C1
   end
  end
 end
end
-- Capsule sample points around a normal avatar's root, tested against the actual
-- oriented head. The small radius is player body width, not bonus weapon reach.
function M.touches(head,playerRoot)
 local half=M.HeadSize*.5
 for _,height in {-1.5,-.5,.5,1.5} do
  local p=head:PointToObjectSpace(playerRoot+Vector3.yAxis*height)
  local closest=Vector3.new(math.clamp(p.X,-half.X,half.X),math.clamp(p.Y,-half.Y,half.Y),math.clamp(p.Z,-half.Z,half.Z))
  if (p-closest).Magnitude<=.85 then return true end
 end
 return false
end
-- The warning follows the actual projected sweep, including its inner gap.
function M.warning(root,clip)
 local a=M.Attacks[clip];local points={}
 if clip=='Slam' then return {M.head(root,clip,a.active).Position},a.radius end
 for i=0,math.ceil((a.finish-a.active)*120) do
  local head=M.head(root,clip,math.min(a.finish,a.active+i/120))
  table.insert(points,head.Position)
 end
 return points,1.9
end
return M
