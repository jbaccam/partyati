return function(Roster)
	assert(#Roster.List == 12, "Expected the 12-fighter launch roster")
	local seenNames = {}
	local roles = {}
	for _, fighter in Roster.List do
		assert(Roster.ById[fighter.Id] == fighter, `Missing ById entry for {fighter.Id}`)
		assert(not seenNames[fighter.DisplayName], `Duplicate display name: {fighter.DisplayName}`)
		seenNames[fighter.DisplayName] = true
		roles[fighter.Role] = true
		assert(fighter.Difficulty >= 1 and fighter.Difficulty <= 3)
		local stats = fighter.Stats
		assert(stats.MaxHealth >= 85 and stats.MaxHealth <= 135)
		assert(stats.WalkSpeed >= 13 and stats.WalkSpeed <= 21)
		assert(stats.JumpVelocity >= 45 and stats.JumpVelocity <= 62)
		assert(stats.Weight >= 0.75 and stats.Weight <= 1.3)
		assert(stats.AirJumps >= 1 and stats.AirJumps <= 2)
		assert(stats.Hitbox == "Small" or stats.Hitbox == "Medium" or stats.Hitbox == "Large")
		assert(#fighter.Basic.Hits == 3)
		assert(fighter.Basic.FinalKnockback > 0 and fighter.Basic.Reach > 0)
		for _, key in {"Q", "E", "R"} do
			local ability = fighter.Abilities[key]
			assert(ability and ability.Name and ability.Description, `{fighter.Id} missing {key}`)
			assert(ability.Cooldown >= 4 and ability.Cooldown <= 13)
			assert(ability.Damage >= 0 and ability.Knockback >= 0 and ability.Range > 0)
		end
		assert(fighter.Passive.Name and fighter.Passive.Description)
		assert(fighter.Ultimate.Name and fighter.Ultimate.Description)
		assert(fighter.Ultimate.Damage > 0 and fighter.Ultimate.Knockback > 0)
	end
	local roleCount = 0
	for _ in roles do roleCount += 1 end
	assert(roleCount >= 10, "Roster needs distinct play styles")
	return {passed=true, fighters=#Roster.List, uniqueRoles=roleCount}
end
