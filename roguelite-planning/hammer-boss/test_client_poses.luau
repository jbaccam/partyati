-- Run as a temporary LocalScript during Studio Play, not in production.
-- Motor6D floating-point transforms are checked within 0.01 studs and
-- 0.002 basis-vector distance (approximately 0.12 degrees).
local M=require(game.ReplicatedStorage.RogueliteCombat.BossMotion);local clone=workspace.ZombieVariantPreviews.HammerBoss_Preview:Clone();game.CollectionService:RemoveTag(clone,'HammerBoss');clone.Parent=workspace
local root=clone.HumanoidRootPart;root.Anchored=true;clone:PivotTo(CFrame.new(0,10000,0));local pe,be,count=0,0,0
for _,name in {'Idle','Walk','Slam','Swing','Spin','Hit','Death'} do local clip=M.Data.clips[name]
for f=0,#clip.frames-1,5 do local poses=M.sample(name,f/clip.fps);M.apply(clone,poses);game:GetService('RunService').Heartbeat:Wait();game:GetService('RunService').Heartbeat:Wait()
for _,n in {'LeftUpperArm','LeftLowerArm','LeftHand','RightUpperArm','RightLowerArm','RightHand','Hammer'} do local p=clone[n];local expected=root.CFrame*poses[n]*p:GetAttribute('BossRest');pe=math.max(pe,(p.Position-expected.Position).Magnitude)
for _,axis in {'XVector','YVector','ZVector'} do be=math.max(be,(p.CFrame[axis]-expected[axis]).Magnitude) end end;count+=1 end end
clone:Destroy();game.ReplicatedStorage:SetAttribute('BossHingeClientTest',game.HttpService:JSONEncode({ok=pe<.01 and be<.002,samples=count,maxPosition=pe,maxBasisVectorError=be}));script:Destroy()
