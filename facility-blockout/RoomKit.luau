-- Original institutional furnishing kit. Static reviewed meshes are used only where noted.
local K={};local V=Vector3.new;local C=Color3.fromRGB
K.colors={wall=C(140,139,125),lower=C(84,99,89),trim=C(47,57,51),metal=C(94,100,94),wood=C(76,56,39),paper=C(179,172,146),cloth=C(115,126,113),dark=C(39,46,43)}
local P=K.colors
function K.model(parent,name) local m=Instance.new("Model");m.Name=name;m.Parent=parent;return m end
function K.part(parent,n,s,cf,c,mat,collide)
 local p=Instance.new("Part");p.Name=n;p.Size=s;p.CFrame=typeof(cf)=="CFrame" and cf or CFrame.new(cf);p.Color=c or P.metal;p.Material=mat or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=collide==true;p.CanTouch=false;p.CastShadow=collide==true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
function K.rod(parent,n,a,b,d,c) local p=K.part(parent,n,V((b-a).Magnitude,d,d),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),c,Enum.Material.Metal);p.Shape=Enum.PartType.Cylinder;return p end
function K.disc(parent,n,cf,d,h,c) local p=K.part(parent,n,V(h,d,d),cf*CFrame.Angles(0,0,math.pi/2),c,Enum.Material.Metal);p.Shape=Enum.PartType.Cylinder;return p end
function K.sign(parent,cf,title,w,h)
 local p=K.part(parent,"EnamelSign",V(w or 5,h or 1.2,.12),cf,P.trim)
 for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do local g=Instance.new("SurfaceGui");g.Face=face;g.CanvasSize=Vector2.new(600,180);g.Parent=p;local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(.94,.9);t.Position=UDim2.fromScale(.03,.05);t.BackgroundTransparency=1;t.Text=title;t.TextColor3=P.paper;t.TextScaled=true;t.Font=Enum.Font.GothamMedium;t.Parent=g end
 return p
end
function K.node(parent,cf,kind,id,item)
 local p=K.part(parent,"Interaction_"..id,V(.4,.4,.4),cf);p.Transparency=1;p.CanQuery=false
 p:SetAttribute("InteractionKind",kind);p:SetAttribute("ObjectiveId",id);if item then p:SetAttribute("ItemId",item) end
 local q=Instance.new("ProximityPrompt");q.ActionText=kind=="Search" and "Search" or "Interact";q.ObjectText=id:gsub("_"," ");q.HoldDuration=kind=="Search" and 1.2 or .6;q.MaxActivationDistance=8;q.RequiresLineOfSight=kind~="Hide";q.Parent=p;return p
end
function K.place(parent,template,cf,name)
 local m=template:Clone();m.Name=name or template.Name
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.CFrame=cf*p.CFrame;p.Anchored=true;p.CanCollide=true;p.CanTouch=false end end
 m.Parent=parent;return m
end
function K.book(parent,cf,w,d,h,color)
 local m=K.model(parent,"LooseVolume");K.part(m,"PageBlock",V(w-.08,h,d-.09),cf,P.paper)
 for _,y in {-h/2,h/2} do K.part(m,"ClothCover",V(w+.03,.045,d+.03),cf*CFrame.new(0,y,0),color or P.cloth,Enum.Material.Fabric) end
 K.part(m,"Spine",V(.07,h+.05,d+.03),cf*CFrame.new(-w/2,0,0),color or P.cloth,Enum.Material.Fabric);return m
end
function K.cabinet(parent,cf,w,h,style,id,item)
 local m=K.model(parent,style=="medical" and "GlazedMedicalCabinet" or "InstitutionalStorageCabinet");local col=style=="wood" and P.wood or P.lower;local mat=style=="wood" and Enum.Material.Wood or Enum.Material.Metal
 local function p(n,s,pos,c,mt,collision) return K.part(m,n,s,cf*CFrame.new(pos),c or col,mt or mat,collision) end
 p("RecessedPlinth",V(w-.35,.35,2.2),V(0,.18,0),P.dark,nil,true)
 for _,x in {-w/2+.1,w/2-.1} do p("SidePanel",V(.2,h,2.5),V(x,h/2,0),nil,nil,true) end
 p("BackPanel",V(w,h,.12),V(0,h/2,-1.2),nil,nil,true)
 for _,y in {.4,h,h*.5} do p("Shelf",V(w,.16,2.5),V(0,y,0),nil,nil,true) end
 for _,sg in {-1,1} do
  p("InsetDoorFrame",V(w/2-.16,h-.7,.12),V(sg*w/4,h/2+.1,1.27),col,nil,true)
  if style=="medical" then local g=p("FrostedGlass",V(w/2-.45,h-1.2,.08),V(sg*w/4,h/2+.1,1.35),C(107,137,130),Enum.Material.Glass);g.Transparency=.35 end
  p("RaisedDoorInset",V(w/2-.48,.08,.08),V(sg*w/4,h-.55,1.38),P.metal)
  p("PullMount",V(.14,.65,.15),V(sg*.3,h*.53,1.46),P.dark)
  for _,y in {.9,h-.7} do p("Hinge",V(.13,.3,.12),V(sg*(w/2-.18),y,1.4),P.metal) end
 end
 if id then K.node(m,cf*CFrame.new(0,h*.53,1.65),"Search",id,item) end
 return m
end
function K.shelf(parent,cf,w,h,id,item)
 local m=K.model(parent,"UtilityShelving");local function p(n,s,pos,c,mat,col) return K.part(m,n,s,cf*CFrame.new(pos),c,mat,col) end
 for _,x in {-w/2,w/2} do for _,z in {-1.35,1.35} do p("AnglePost",V(.16,h,.16),V(x,h/2,z),P.trim,Enum.Material.Metal,true) end end
 for i=0,3 do local y=.6+i*(h-1)/3;p("FoldedShelf",V(w+.2,.16,2.9),V(0,y,0),P.metal,Enum.Material.Metal,true)
  for j=1,2 do local x=(j-1.5)*w*.4;local box=p("ArchiveCarton",V(w*.3,1.1,2),V(x,y+.65,.05),C(112+i*5,100+i*4,77+i*3),Enum.Material.Fabric)
   p("CartonLid",V(w*.3+.08,.12,2.08),V(x,y+1.23,.05),P.paper)
   p("IndexLabel",V(.7,.3,.02),V(x,y+.65,1.06),P.paper)
  end
 end
 if id then K.node(m,cf*CFrame.new(0,3,1.75),"Search",id,item) end;return m
end
function K.table(parent,cf,w,d,metal)
 local m=K.model(parent,metal and "SteelWorktable" or "OakInstitutionTable");local col=metal and P.metal or P.wood;local mat=metal and Enum.Material.Metal or Enum.Material.Wood
 K.part(m,"RoundedEdgeTop",V(w,.28,d),cf*CFrame.new(0,3.3,0),col,mat,true)
 for _,z in {-d/2+.22,d/2-.22} do K.part(m,"Apron",V(w-.5,.55,.16),cf*CFrame.new(0,2.91,z),col,mat) end
 for _,x in {-w/2+.45,w/2-.45} do for _,z in {-d/2+.45,d/2-.45} do
  K.rod(m,"Leg",cf:PointToWorldSpace(V(x,.16,z)),cf:PointToWorldSpace(V(x,3.15,z)),metal and .18 or .29,col)
  K.disc(m,"Foot",cf*CFrame.new(x,.09,z),.34,.15,P.dark)
 end end;return m
end
function K.chair(parent,cf) return K.place(parent,game.ServerStorage.CoherentKitTemplates.OfficeChair,cf,"MatchingUpholsteredChair") end
function K.bench(parent,cf)
 local m=K.model(parent,"CourtyardSlattedBench")
 for i=0,3 do K.part(m,"OakSeatSlat",V(8,.18,.48),cf*CFrame.new(0,2,i*.52-.78),P.wood,Enum.Material.Wood,true) end
 for i=0,2 do K.part(m,"OakBackSlat",V(8,.5,.18),cf*CFrame.new(0,2.65+i*.56,-1.03)*CFrame.Angles(math.rad(-8),0,0),P.wood,Enum.Material.Wood) end
 for _,x in {-3.2,3.2} do
  K.rod(m,"RearFrame",cf:PointToWorldSpace(V(x,.1,-.8)),cf:PointToWorldSpace(V(x,4,-1.1)),.21,P.trim)
  K.rod(m,"FrontFrame",cf:PointToWorldSpace(V(x,.1,.8)),cf:PointToWorldSpace(V(x,2,.8)),.21,P.trim)
  K.rod(m,"ArmRest",cf:PointToWorldSpace(V(x,2.85,-.8)),cf:PointToWorldSpace(V(x,2.85,.8)),.21,P.trim)
  K.rod(m,"ArmSupport",cf:PointToWorldSpace(V(x,2,.8)),cf:PointToWorldSpace(V(x,2.85,.8)),.16,P.trim)
 end;return m
end
function K.tray(parent,cf,id,item)
 local m=K.model(parent,"MedicalInstrumentTrolley");K.table(m,cf,4,2.6,true)
 for _,x in {-1.55,1.55} do for _,z in {-.85,.85} do local p=K.part(m,"RubberCaster",V(.16,.45,.45),cf*CFrame.new(x,.22,z),P.dark);p.Shape=Enum.PartType.Cylinder end end
 K.part(m,"LowerTray",V(3.6,.1,2.2),cf*CFrame.new(0,.9,0),P.metal,Enum.Material.Metal)
 for _,z in {-1.25,1.25} do K.part(m,"TrayLip",V(4,.2,.08),cf*CFrame.new(0,3.5,z),P.metal,Enum.Material.Metal) end
 K.disc(m,"InstrumentBowl",cf*CFrame.new(-.9,3.53,0),.8,.12,P.paper)
 K.part(m,"FoldedCloth",V(1.3,.16,1),cf*CFrame.new(.7,3.54,0),P.paper,Enum.Material.Fabric)
 if id then K.node(m,cf*CFrame.new(0,3.8,0),"Search",id,item) end;return m
end
function K.bed(parent,cf,id)
 local m=K.place(parent,game.ServerStorage.FacilityRoomTemplates.HospitalBed,cf,"InstitutionBed")
 K.part(m,"FoldedWoolBlanket",V(4.6,.14,3.1),cf*CFrame.new(0,1.98,2.7),P.cloth,Enum.Material.Fabric)
 local pillow=K.part(m,"Pillow",V(3,.4,1.45),cf*CFrame.new(0,2.1,-3.3),P.paper,Enum.Material.Fabric);local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=pillow
 if id then local a=K.node(m,cf*CFrame.new(0,.8,0),"Hide",id);a:SetAttribute("HidePosition",(cf*CFrame.new(0,.65,0)).Position);a:SetAttribute("ExitPosition",(cf*CFrame.new(3.7,2,0)).Position) end;return m
end
function K.lamp(parent,pos,sector,index)
 local m=K.model(parent,"CeilingLuminaire");m:SetAttribute("PowerSector",sector)
 K.part(m,"Housing",V(2.5,.25,5.5),CFrame.new(pos),P.metal,Enum.Material.Metal)
 local p=K.part(m,"Diffuser",V(2.2,.1,5.15),CFrame.new(pos-V(0,.2,0)),C(202,208,183),Enum.Material.Neon)
 local l=Instance.new("SurfaceLight");l.Face=Enum.NormalId.Bottom;l.Angle=110;l.Range=32;l.Brightness=3.6;l.Color=C(209,211,187);l.Shadows=true;l.Parent=p
 p:SetAttribute("PowerSector",sector);p:SetAttribute("RatedBrightness",3.6);p:SetAttribute("Flickers",index%17==0);return p
end
function K.fence(parent,cf,w,h,gap)
 local m=K.model(parent,"ServiceMeshFence");local function localrod(n,a,b,d) K.rod(m,n,cf:PointToWorldSpace(a),cf:PointToWorldSpace(b),d,P.metal) end
 for _,x in {-w/2,w/2} do localrod("GalvanizedPost",V(x,0,0),V(x,h+.2,0),.22) end
 localrod("TopRail",V(-w/2,h,0),V(w/2,h,0),.16)
 local low=gap and 3.15 or .2
 for y=low,h,1.3 do localrod("MeshHorizontal",V(-w/2,y,0),V(w/2,y,0),.032) end
 for x=-w/2,w/2,1.3 do localrod("MeshVertical",V(x,low,0),V(x,h,0),.032) end
 local barrier=K.part(m,"FenceCollision",V(w,h-low,.18),cf*CFrame.new(0,(h+low)/2,0),P.metal,nil,true);barrier.Transparency=1
 if gap then localrod("SlideSillRail",V(-w/2,3.15,0),V(w/2,3.15,0),.12);m:SetAttribute("TraversalType","Slide");K.sign(m,cf*CFrame.new(w/2-2,5,.12),"SERVICE ACCESS",3,.7) end
 return m
end
return K
