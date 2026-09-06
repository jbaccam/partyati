local Rules = {}
function Rules.Rank(results)
	local ranked = table.clone(results)
	table.sort(ranked, function(a, b)
		if a.Score ~= b.Score then
			return a.Score > b.Score
		end
		if a.PreviousTotal ~= b.PreviousTotal then
			return a.PreviousTotal > b.PreviousTotal
		end
		return a.TieOrder < b.TieOrder -- Randomized once per match, disclosed to players.
	end)
	return ranked
end
function Rules.Inventory(scene)
	local inventory = {}
	for _, group in ipairs({ scene.RequiredObjects, scene.DecoyObjects }) do
		for _, o in ipairs(group) do
			inventory[o.ObjectType] = (inventory[o.ObjectType] or 0) + 1
		end
	end
	return inventory
end
return Rules
