local Weights = require(game.ReplicatedStorage.CopyTheScene.Config).Weights
local S = {}
local function distance(a, b)
	return math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2 + (a.Level - b.Level) ^ 2)
end
-- Minimum total distance assignment, independent of creation order. Scenes cap inventory at 10.
local function match(targets, placed)
	local memo = {}
	local function visit(i, mask, used)
		if i > #targets then
			return 0, {}
		end
		local key = i .. ":" .. mask
		if memo[key] then
			return table.unpack(memo[key])
		end
		local best, path = math.huge, {}
		local needed = math.min(#targets, #placed)
		if #targets - i + 1 > needed - used then
			local score, rest = visit(i + 1, mask, used)
			best = score
			path = table.clone(rest)
		end
		if used < needed then
			for j, p in ipairs(placed) do
				local bit = 2 ^ (j - 1)
				if bit32.band(mask, bit) == 0 then
					local score, rest = visit(i + 1, mask + bit, used + 1)
					score += distance(targets[i], p)
					if score < best then
						best = score
						path = table.clone(rest)
						path[i] = j
					end
				end
			end
		end
		memo[key] = { best, path }
		return best, path
	end
	local _, path = visit(1, 0, 0)
	return path
end
function S.Score(targets, placed)
	if #targets == 0 then
		return 0, {}
	end
	local total, matched = 0, 0
	local breakdown = { Object = 0, Position = 0 }
	local types = {}
	for _, t in ipairs(targets) do
		types[t.ObjectType] = true
	end
	for kind in pairs(types) do
		local ts, ps = {}, {}
		for _, t in ipairs(targets) do
			if t.ObjectType == kind then
				table.insert(ts, t)
			end
		end
		for _, p in ipairs(placed) do
			if p.ObjectType == kind then
				table.insert(ps, p)
			end
		end
		local assignment = match(ts, ps)
		for i, j in pairs(assignment) do
			local t, p = ts[i], ps[j]
			local d = distance(t, p)
			local pos = math.max(0, 1 - d / 4)
			breakdown.Object += 1
			breakdown.Position += pos
			matched += 1
		end
	end
	for k, v in pairs(breakdown) do
		total += v * Weights[k]
		breakdown[k] = math.floor(v / #targets * 100 + 0.5)
	end
	local extras = math.max(0, #placed - matched)
	local raw = math.clamp(total / #targets * 100 - extras * 5, 0, 100)
	-- Only exact recreations earn PERFECT, not rounding near-misses.
	return math.floor(raw * 10 + 0.00001) / 10, breakdown
end
return S
