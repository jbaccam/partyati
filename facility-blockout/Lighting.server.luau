-- Runs in Play; stopping restores bright edit-mode settings automatically.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("LibraryArtReady") do task.wait() end
local lighting=game:GetService("Lighting")
lighting.ClockTime=0;lighting.Brightness=1
lighting.Ambient=Color3.fromRGB(48,51,49);lighting.OutdoorAmbient=Color3.fromRGB(58,68,79)
lighting.ExposureCompensation=.3;lighting.EnvironmentDiffuseScale=.4;lighting.EnvironmentSpecularScale=.2;lighting.GlobalShadows=true
local grade=lighting:FindFirstChild("FacilityArtGrade") or Instance.new("ColorCorrectionEffect")
grade.Name="FacilityArtGrade";grade.Enabled=true;grade.Saturation=-.15;grade.Contrast=.07;grade.Parent=lighting
local art=root:WaitForChild("LibraryArt")
art.BlackCeiling.Transparency=0
for _,v in art:GetDescendants() do if v:IsA("SurfaceLight") and v.Parent.Name=="Fluorescent" then v.Range=40;v.Brightness=3.3 end end
