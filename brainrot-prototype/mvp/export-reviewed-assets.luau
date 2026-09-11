-- Read-only exporter for the reviewed MVP asset/clip classes.
-- Call returned function(instance, firstByte, byteCount). No Instances are changed.
-- Attributes are returned as explicit Rojo property values for the project overlay.
return function(root, firstByte, byteCount)
	local function escape(v)
		return tostring(v):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
	end
	local function tag(kind, name, value)
		return "<" .. kind .. ' name="' .. escape(name) .. '">' .. value .. "</" .. kind .. ">"
	end
	local function vector(v)
		return "<X>" .. v.X .. "</X><Y>" .. v.Y .. "</Y><Z>" .. v.Z .. "</Z>"
	end
	local function frame(v)
		local components = { v:GetComponents() }
		local names = { "X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22" }
		local out = {}
		for index, name in names do
			table.insert(out, "<" .. name .. ">" .. components[index] .. "</" .. name .. ">")
		end
		return table.concat(out)
	end
	local refs = {}
	local serial = 0
	local counts = {}
	local function register(i)
		serial += 1
		refs[i] = "MVP" .. serial
		counts[i.ClassName] = (counts[i.ClassName] or 0) + 1
		for _, c in i:GetChildren() do
			register(c)
		end
	end
	register(root)
	local allowed = {
		Model = true,
		MeshPart = true,
		Bone = true,
		Attachment = true,
		AnimationController = true,
		Animator = true,
		KeyframeSequence = true,
		Keyframe = true,
		Pose = true,
	}
	local function item(i)
		assert(allowed[i.ClassName], "Unsupported class needs explicit review: " .. i.ClassName)
		local props = { tag("string", "Name", escape(i.Name)) }
		local function prop(kind, name, value)
			if kind == "bool" then
				value = tostring(value)
			elseif kind == "CoordinateFrame" then
				value = frame(value)
			elseif kind == "Vector3" then
				value = vector(value)
			elseif kind == "Content" then
				value = "<url>" .. escape(value) .. "</url>"
			elseif kind == "token" then
				value = tostring(value.Value)
			elseif kind == "Color3" then
				value = "<R>" .. value.R .. "</R><G>" .. value.G .. "</G><B>" .. value.B .. "</B>"
			else
				value = escape(value)
			end
			table.insert(props, tag(kind, name, value))
		end
		prop("bool", "Archivable", i.Archivable)
		if i:IsA("Model") then
			if i.PrimaryPart then
				table.insert(props, tag("Ref", "PrimaryPart", assert(refs[i.PrimaryPart], "External PrimaryPart")))
			end
		elseif i:IsA("MeshPart") then
			prop("Content", "MeshId", i.MeshId)
			prop("Content", "TextureID", i.TextureID)
			prop("Vector3", "size", i.Size)
			prop("Vector3", "InitialSize", i.MeshSize)
			prop("CoordinateFrame", "CFrame", i.CFrame)
			prop("CoordinateFrame", "PivotOffset", i.PivotOffset)
			prop("Color3", "Color", i.Color)
			prop("token", "Material", i.Material)
			prop("token", "RenderFidelity", i.RenderFidelity)
			prop("token", "CollisionFidelity", i.CollisionFidelity)
			for _, name in { "Anchored", "CanCollide", "CanTouch", "CanQuery", "Massless", "CastShadow" } do
				prop("bool", name, i[name])
			end
			for _, name in { "Transparency", "Reflectance" } do
				prop("float", name, i[name])
			end
		elseif i:IsA("Bone") or i:IsA("Attachment") then
			prop("CoordinateFrame", "CFrame", i.CFrame)
			prop("bool", "Visible", i.Visible)
		elseif i:IsA("KeyframeSequence") then
			prop("bool", "Loop", i.Loop)
			prop("token", "Priority", i.Priority)
			prop("float", "AuthoredHipHeight", i.AuthoredHipHeight)
		elseif i:IsA("Keyframe") then
			prop("float", "Time", i.Time)
		elseif i:IsA("Pose") then
			prop("CoordinateFrame", "CFrame", i.CFrame)
			prop("float", "Weight", i.Weight)
			prop("token", "EasingStyle", i.EasingStyle)
			prop("token", "EasingDirection", i.EasingDirection)
		end
		local children = {}
		for _, c in i:GetChildren() do
			table.insert(children, item(c))
		end
		return '<Item class="'
			.. i.ClassName
			.. '" referent="'
			.. refs[i]
			.. '"><Properties>'
			.. table.concat(props)
			.. "</Properties>"
			.. table.concat(children)
			.. "</Item>"
	end
	local attributes = {}
	for name, v in root:GetAttributes() do
		local t = typeof(v)
		if t == "string" then
			attributes[name] = { String = v }
		elseif t == "boolean" then
			attributes[name] = { Bool = v }
		elseif t == "number" then
			attributes[name] = { Float64 = v }
		elseif t == "Vector3" then
			attributes[name] = { Vector3 = { v.X, v.Y, v.Z } }
		else
			error("Unsupported attribute " .. name .. " " .. t)
		end
	end
	-- Descendant attributes would need their own project overlay entries.
	for _, i in root:GetDescendants() do
		assert(next(i:GetAttributes()) == nil, "Unexpected child attributes: " .. i:GetFullName())
	end
	local xml = '<roblox version="4">' .. item(root) .. "</roblox>"
	firstByte = firstByte or 1
	byteCount = math.min(byteCount or 40000, 40000)
	return { xml = string.sub(xml, firstByte, firstByte + byteCount - 1), totalBytes = #xml, counts = counts, attributes = attributes }
end
