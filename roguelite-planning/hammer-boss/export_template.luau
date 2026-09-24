-- Edit-time snapshot of only the authored boss template.
local npc=game.ServerStorage.RogueliteNPCs.HammerBoss_NPC
local list={npc};for _,o in npc:GetDescendants() do table.insert(list,o) end
local ids={};for i,o in list do ids[o]='BOSS'..i end
local function value(v)
 local t=typeof(v)
 if t=='CFrame' then v={v:GetComponents()}
 elseif t=='Vector3' then v={v.X,v.Y,v.Z}
 elseif t=='Color3' then v={v.R,v.G,v.B}
 elseif t=='EnumItem' then v=v.Value
 elseif t=='Instance' then v=ids[v] end
 return {t=t,v=v}
end
local out={}
for _,o in list do
 local properties={'Name','Archivable'}
 local function add(names)for _,n in names do table.insert(properties,n) end end
 if o:IsA('BasePart') then add({'Size','CFrame','PivotOffset','Color','Material','Anchored','CanCollide','CanTouch','CanQuery','Massless','CastShadow','Transparency','Reflectance'}) end
 if o:IsA('MeshPart') then add({'MeshId','TextureID','MeshSize','RenderFidelity','CollisionFidelity'}) end
 if o:IsA('SurfaceAppearance') then add({'AlphaMode','ColorMap','NormalMap','MetalnessMap','RoughnessMap'}) end
 if o:IsA('Motor6D') then add({'C0','C1','Transform','Part0','Part1'}) end
 if o:IsA('Model') then add({'PrimaryPart'}) end
 if o:IsA('Humanoid') then add({'RigType','HipHeight','MaxHealth','Health','WalkSpeed','RequiresNeck','BreakJointsOnDeath','AutomaticScalingEnabled','DisplayDistanceType'}) end
 local row={id=ids[o],parent=ids[o.Parent],class=o.ClassName,properties={},attributes={}}
 for _,n in properties do row.properties[n]=value(o[n]) end
 for n,v in o:GetAttributes() do row.attributes[n]=value(v) end
 table.insert(out,row)
end
return game:GetService('HttpService'):JSONEncode(out)
