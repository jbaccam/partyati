-- Local, non-colliding ground warning. The server alone resolves the impact.
local Types=require(script.Parent.ZombieTypes)
local V={};local visuals={}
function V.remove(npc) local p=visuals[npc];if p then p:Destroy();visuals[npc]=nil end end
function V.update(npc,now)
    local started=npc:GetAttribute('SlamStart');local center=npc:GetAttribute('SlamPosition')
    local age=started and now-started
    if not center or not age or age<0 or age>Types.Slam.impact+.23 or not npc.Parent then V.remove(npc);return end
    local p=visuals[npc]
    if not p then
        p=Instance.new('Part');p.Name='MutantSlamWarning';p.Shape=Enum.PartType.Cylinder
        p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
        p.Material=Enum.Material.Neon;p.Size=Vector3.new(.035,Types.Slam.radius*2,Types.Slam.radius*2)
        p.Parent=workspace;visuals[npc]=p
    end
    p.CFrame=CFrame.new(center+Vector3.yAxis*.04)*CFrame.Angles(0,0,math.pi/2)
    if age<Types.Slam.impact then p.Color=Color3.fromRGB(223,92,48);p.Transparency=.82-age/Types.Slam.impact*.20
    else p.Color=Color3.fromRGB(238,191,126);p.Transparency=.45+(age-Types.Slam.impact)/.23*.55 end
end
return V
