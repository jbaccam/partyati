return function(package)
 package=package or game.ReplicatedStorage.TungPrototype
 local Audio=require(package.CombatAudio)
 local folder=Instance.new("Folder");folder.Name="AudioTestFixture";folder.Parent=workspace
 local ok,err=pcall(function()
  local n=0;for _,id in Audio.Assets do n+=1;assert(id:match("^rbxassetid://%d+$"),"Real Creator Store recordings, no default built-ins") end
  assert(n==8,"Curated source set")
  local camera=workspace.CurrentCamera;local position=camera and camera.CFrame.Position or Vector3.zero
  local step=Audio.Play(folder,position,"Step","tung_sahur")
  local hit=Audio.Play(folder,position,"Hit","tung_sahur")
  assert(step and hit and step.Volume<hit.Volume*.4,"Footsteps must remain quieter than combat")
  assert(not Audio.Play(folder,position,"Step","tung_sahur"),"Same-place same-kind duplicate audio is coalesced")
  assert(not Audio.PlayRaw(folder,position,"rbxasset://sounds/action_jump.mp3",1,.4),"Old rejected built-ins are not a fallback")
  for i=1,30 do Audio.PlayRaw(folder,position,Audio.Assets.Hit,1,.2) end
  assert(#folder:GetChildren()<=24,"Combat voices have a hard local bound")
  for _,p in folder:GetChildren() do
   assert(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch,"Audio emitters are cosmetic only")
  end
 end)
 folder:Destroy();assert(ok,err)
 return "Creator Store-only sources, volume hierarchy, deduplication and 24-voice bound passed"
end
