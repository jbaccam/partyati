local Data = require(game.ReplicatedStorage.CopyTheScene.AssetData)
local S = {}
function S.Create(kind, parent, position, scale, yaw)
	local model = Instance.new("Model")
	model.Name = kind
	for _, entry in ipairs(Data[kind]) do
		local p = Instance.new("Part")
		p.Name = entry.Name
		p.Size = Vector3.new(table.unpack(entry.Size))
		p.CFrame = CFrame.new(table.unpack(entry.CFrame))
		p.Color = Color3.new(table.unpack(entry.Color))
		p.Material = Enum.Material[entry.Material]
		p.Shape = Enum.PartType[entry.Shape]
		p.Transparency = entry.Transparency
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if entry.Mesh then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType[entry.Mesh.Type]
			mesh.MeshId, mesh.TextureId = entry.Mesh.Id, entry.Mesh.Texture
			mesh.Scale = Vector3.new(table.unpack(entry.Mesh.Scale))
			mesh.Offset = Vector3.new(table.unpack(entry.Mesh.Offset))
			mesh.Parent = p
		end
		p.Parent = model
	end
	model.WorldPivot = CFrame.identity
	model:ScaleTo(scale or 1)
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0))
	model.Parent = parent
	return model
end
return S
