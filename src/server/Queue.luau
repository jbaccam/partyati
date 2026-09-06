local Queue = {}
-- Records are server-owned. Arrival order is assigned when opting in, not on login.
function Queue.List(records)
	local players = {}
	for player, record in pairs(records) do
		if player.Parent and record.Queued and not record.InMatch then
			table.insert(players, player)
		end
	end
	table.sort(players, function(a, b)
		return records[a].QueueOrder < records[b].QueueOrder
	end)
	return players
end
return Queue
