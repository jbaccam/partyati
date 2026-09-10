local CabinetClosure = {}
CabinetClosure.close=function(m,override)
 local back=override or m:FindFirstChild("Back");if not back or not back:IsA("BasePart") then return 0 end
 local function thin(p)local s={p.Size.X,p.Size.Y,p.Size.Z};local axes={p.CFrame.RightVector,p.CFrame.UpVector,p.CFrame.ZVector};local j=1;for k=2,3 do if s[k]<s[j] then j=k end end;local n=axes[j];return Vector3.new(n.X,0,n.Z).Unit end
 local normal=thin(back);if normal.X~=normal.X then return 0 end
 local done=0
 for _,hinge in ipairs(m:GetDescendants()) do if hinge:IsA("BasePart") and hinge.Name=="Hinge" then
  local parts={[hinge]=hinge.CFrame};local door=nil
  for _,j in ipairs(hinge:GetChildren()) do if j:IsA("Motor6D") and j.Part0==hinge and j.Part1 and j.Part1:IsDescendantOf(m) then parts[j.Part1]=j.Part1.CFrame;if j.Part1.Name=="Door" then door=j.Part1 end end end
  if door then
   local dn=thin(door);local best,score
   for _,sign in ipairs({-1,1}) do local target=normal*sign;local angle=math.atan2(dn:Cross(target).Y,dn:Dot(target));local t=CFrame.new(hinge.Position)*CFrame.Angles(0,angle,0)*CFrame.new(-hinge.Position);local c=(t*parts[door]).Position;local s=(Vector3.new(c.X,0,c.Z)-Vector3.new(back.Position.X,0,back.Position.Z)).Magnitude;if not score or s<score then score=s;best=t end end
   for p in pairs(parts) do p.Anchored=true end
   for p,cf in pairs(parts) do p.CFrame=best*cf end
   done+=1
  end
 end end
 return done
end
return CabinetClosure
