local Catalog = require(script.Parent.Catalog)
local Config = require(script.Parent.Config)
local P = {}
-- X/Z identify the first occupied cell, indexed 0..Config.Grid-1.
function P.Bounds(o)
	local d = Catalog.Definitions[o.ObjectType]
	return o.X, o.X + d.W, o.Z, o.Z + d.D
end
function P.Valid(o, placed)
	local d = Catalog.Definitions[o.ObjectType]
	if not d then
		return false, "Choose a prop!"
	end
	for _, key in ipairs({ "X", "Z", "Level" }) do
		local v = o[key]
		if type(v) ~= "number" or v ~= v or math.abs(v) > 100 or v % 1 ~= 0 then
			return false, "Aim at a grid square"
		end
	end
	if o.Level < 0 or o.Level + d.H > 8 then
		return false, "That's too high!"
	end
	local x1, x2, z1, z2 = P.Bounds(o)
	if x1 < 0 or x2 > Config.Grid or z1 < 0 or z2 > Config.Grid then
		return false, "Keep it on your island"
	end
	local supported = o.Level == 0
	for _, p in ipairs(placed) do
		local pd = Catalog.Definitions[p.ObjectType]
		local a, b, c, e = P.Bounds(p)
		if pd.Stackable and o.Level == p.Level + pd.H and x1 >= a and x2 <= b and z1 >= c and z2 <= e then
			supported = true
		end
		if x1 < b and x2 > a and z1 < e and z2 > c and o.Level < p.Level + pd.H and o.Level + d.H > p.Level then
			return false, "That spot is taken"
		end
	end
	if not supported then
		return false, "Aim at the top of a stackable prop"
	end
	return true, o.Level > 0 and "Stack it!" or "Place here!"
end
function P.CFrame(o, origin)
	local d = Catalog.Definitions[o.ObjectType]
	local x = o.X + d.W / 2 - Config.Grid / 2
	local z = o.Z + d.D / 2 - Config.Grid / 2
	return CFrame.new(origin + Vector3.new(x, o.Level, z) * Config.Cell)
end
function P.FromPoint(point, origin, kind, support)
	local x = math.floor((point.X - origin.X) / Config.Cell + Config.Grid / 2)
	local z = math.floor((point.Z - origin.Z) / Config.Cell + Config.Grid / 2)
	local level = 0
	if support then
		local base = Catalog.Definitions[support.ObjectType]
		local d = Catalog.Definitions[kind]
		if base.Stackable and d.W <= base.W and d.D <= base.D then
			level = support.Level + base.H
			x = math.clamp(x, support.X, support.X + base.W - d.W)
			z = math.clamp(z, support.Z, support.Z + base.D - d.D)
		end
	end
	return { ObjectType = kind, X = x, Z = z, Level = level }
end
return P
