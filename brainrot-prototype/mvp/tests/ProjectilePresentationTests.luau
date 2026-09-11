-- Studio ModuleScript; presentation-only regression fixtures, no live players.
return function(package)
 package=package or game.ReplicatedStorage.TungPrototype
 local Effects=require(package.CombatEffects)
 local fx=Effects.new()
 local source=Instance.new("Model");source.Name="ProjectilePresentationFixture";source.Parent=workspace
 local visual=Instance.new("Part");visual.Name="TungSahurVisual";visual.Anchored=true;visual.CanCollide=false
 visual.Size=Vector3.new(4,4,9);visual.Position=Vector3.new(0,0,-2);visual.Parent=source
 source:SetAttribute("FighterId","tralalero")
 local function count(name)
  local n=0;for _,p in fx.folder:GetDescendants() do if p.Name==name then n+=1 end end;return n
 end
 local ok,err=pcall(function()
  fx:Handle("FighterStrike",Vector3.zero,{source=source,fighterId="tralalero",aim=Vector3.new(0,0,-1),combo=1})
  assert(count("JawSnap")==18,"A jaw snap has paired curves")
  for _,p in fx.folder:GetDescendants() do
   if p.Name=="JawSnap" then assert(p.Position.Z<-6.5,"Jaw effect must be beyond the visible head, not inside controller capsule") end
  end
  fx:Handle("Projectile",Vector3.new(30,8,20),{source=source,id=1,kind="Banana",velocity=Vector3.new(54,0,0),duration=1,at=workspace:GetServerTimeNow()})
  assert(count("BananaCurve")==11 and count("BananaStem")==1 and count("BananaTip")==1,"Banana must read as a connected tapered crescent with tips")
  assert(count("BananaSegment")==0,"No legacy yellow cubes")
  for _,piece in fx.projectiles[1].pieces do
   local mesh=piece.part:FindFirstChild("EllipsoidSurface")
   assert(mesh and mesh:IsA("SpecialMesh") and mesh.MeshType==Enum.MeshType.Sphere and mesh.Scale==Vector3.one,"Sphere mesh preserves the elongated banana dimensions; Ball Parts render beads")
   assert((piece.part.Position-Vector3.new(30,8,20)).Magnitude<2,"Projectile pieces must spawn at cast position, never world origin")
  end
  fx:Handle("ProjectileEnd",Vector3.zero,{source=source,id=1});assert(#fx.projectiles==0,"Authoritative hit removes banana immediately")

  fx:Handle("Trap",Vector3.new(12,.15,12),{source=source,radius=3.5,duration=8})
  assert(#fx.traps==1 and count("BananaPeelTrap")==1 and count("PeelStrip")==18 and count("PeelInside")==18,"Trap leaves a recognizable three-strip peel on the ground")
  for _,p in fx.traps[1].container:GetChildren() do
   if p:IsA("BasePart") and (p.Name=="PeelStrip" or p.Name=="PeelInside") then
    local mesh=p:FindFirstChild("EllipsoidSurface")
    assert(mesh and mesh.MeshType==Enum.MeshType.Sphere,"Flat peel needs an ellipsoid surface, never shortest-axis dots")
    assert(p.Size.Z>p.Size.Y*3,"Peel strip must retain its broad, shallow silhouette")
   end
  end
  fx:Handle("Trap",Vector3.new(15,.15,12),{source=source,radius=3.5,duration=8})
  assert(#fx.traps==1 and count("BananaPeelTrap")==1,"Replacing trap cleans previous peel")
  fx:Handle("TrapEnd",Vector3.zero,{source=source});assert(#fx.traps==0 and count("BananaPeelTrap")==0,"Trigger removes peel and ring together")
  fx:Handle("Trap",Vector3.zero,{source=source,duration=1});fx.traps[1].expires=0;fx:Step();assert(#fx.traps==0,"Peel duration cannot leak")

  fx:Handle("BombDrop",Vector3.new(20,10,20),{source=source,id=2,target=Vector3.new(20,0,20),duration=1,at=workspace:GetServerTimeNow()-.5})
  fx:Step()
  local drop=fx.projectiles[1]
  local body=drop.container:FindFirstChild("BombBody")
  assert(body and math.abs(body.Position.Y-5)<.6,"Carpet Run bomb visibly falls toward synchronized impact point")
  assert(count("BombTailFin")==4,"Bomb silhouette includes four tail fins")
  fx:Handle("ProjectileEnd",Vector3.zero,{source=source,id=2});assert(#fx.projectiles==0,"Collision/impact removes the matching falling bomb")
  fx:Handle("Wave",Vector3.zero,{source=source,fighterId="tralalero",aim=Vector3.new(0,0,-1),radius=6})
  assert(count("FrenzyWaterCrest")==24,"Shark ultimate has bite/water presentation")
  fx:Handle("AlarmFinal",Vector3.zero,{source=source,fighterId="ballerina",radius=8})
  assert(count("BalletRibbon")==60,"Ballerina ultimate has rising ribbons")
  fx:Handle("Slam",Vector3.zero,{source=source,fighterId="bombardiro",radius=5})
  assert(count("BombSmoke")==5,"Bomb detonation differs from a melee strike")
  for _,p in fx.folder:GetDescendants() do
   if p:IsA("BasePart") then assert(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch,"Presentation never affects hitboxes or collision") end
   if p:IsA("Sound") then
    assert(not p.SoundId:find("swim") and not p.SoundId:find("volume_slider"),"No generic swim/UI-slider combat noises")
    assert(p:FindFirstChildOfClass("EqualizerSoundEffect"),"Combat cue uses a deliberate timbre profile")
   end
  end
 end)
 source:Destroy();fx.folder:Destroy()
 assert(ok,err)
 return "Forward jaw placement, curved fruit, persistent peel, synchronized bomb drop, ultimate FX and cosmetic safety passed"
end
