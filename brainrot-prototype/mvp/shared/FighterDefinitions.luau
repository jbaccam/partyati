-- Initial playable roster for the brainrot arena fighter.
-- These are design values, shared by server combat logic and client presentation.
-- Combat must remain server-authoritative; clients may request an input, never a result.
local Fighters = {
	{
		Id = "tung_sahur", DisplayName = "Tung Sahur", ModelName = "Tung Sahur",
		Role = "All-Rounder Bruiser", Difficulty = 1,
		Stats = {MaxHealth=115, WalkSpeed=20, JumpVelocity=52, AirControl=0.85, Weight=1.12, AirJumps=1, Hitbox="Medium"},
		Basic = {Name="Wooden Hands", Hits={3,3,6}, FinalKnockback=34, Reach=5.5, Recovery=0.36,
			Description="Two quick palm strikes into a broad wooden uppercut."},
		Abilities = {
			Q={Name="Bat Beat", Damage=10, Knockback=38, Cooldown=5.0, Range=7,
				Description="Swing a wide wooden club arc. The outer third is a sweet spot for 13 damage and 46 knockback."},
			E={Name="Sahur Slam", Damage=12, Knockback=42, Cooldown=8.0, Range=9,
				Description="Hop and pound the ground. In the air, descend into the strike and create a landing ring."},
			R={Name="Dawn Call", Damage=7, Knockback=28, Cooldown=8.5, Range=8,
				Description="Launch up and forward with a wake-up shout. One use before landing; serves as recovery."},
		},
		Passive={Name="Keep the Beat", Description="Hits within 2.25 seconds build up to 3 Beat stacks. Each grants 3% damage and 4% movement speed; inactivity removes stacks one at a time."},
		Ultimate={Name="Midnight Alarm", Damage=54, Knockback=82, Duration=3.7,
			Hits={
				{At=0.65,Damage=8,Knockback=8,Radius=10,Effect="AlarmBeat"},
				{At=1.25,Damage=8,Knockback=12,Radius=12,Effect="AlarmBeat"},
				{At=2.05,Damage=14,Knockback=26,Radius=14,Effect="AlarmStrike"},
				{At=3.15,Damage=24,Knockback=82,Radius=20,Effect="AlarmFinal"},
			},
			Description="Drum the wooden body twice with the club for sonic booms, sweep a resonant strike, then smash out a final ground shockwave. Four warned impacts deal 54 total base damage; the final hit launches."},
	},
	{
		Id = "tralalero", DisplayName = "Tralalero Tralala", ModelName = "Tralalero Tralala",
		Role = "Aerial Rushdown", Difficulty = 2,
		Stats = {MaxHealth=95, WalkSpeed=18.5, JumpVelocity=58, AirControl=1.15, Weight=0.88, AirJumps=2, Hitbox="Medium"},
		Basic = {Name="Fin Flurry", Hits={2.5,2.5,5}, FinalKnockback=31, Reach=5.5, Recovery=0.28,
			Description="Fast alternating fin swipes ending in a tail kick."},
		Abilities = {
			Q={Name="Shark Torpedo", Damage=11, Knockback=39, Cooldown=6.0, Range=15,
				Description="Surge in the aimed direction. The dash can curve slightly and ends on the first enemy hit."},
			E={Name="Sonar Snap", Damage=4, Knockback=12, Cooldown=10.0, Range=35,
				Description="Ping a cone ahead. The closest enemy hit is revealed for 4 seconds and takes 15% more knockback from Tralalero."},
			R={Name="Wave Breach", Damage=8, Knockback=30, Cooldown=9.0, Range=9,
				Description="Ride a rising wave up and forward. One use before landing; serves as recovery."},
		},
		Passive={Name="Blood in the Water", Description="After traveling 20 studs while airborne, the next damaging hit gains 4 damage. Landing or hitting consumes it."},
		Ultimate={Name="Feeding Frenzy", Damage=40, Knockback=82, Duration=7,
			Description="Gain high-speed swimming through the air and three aimed bite rushes before a final tail launch."},
	},
	{
		Id = "ballerina", DisplayName = "Ballerina Cappuccina", ModelName = "Ballerina Cappuccina",
		Role = "Technical Duelist", Difficulty = 3,
		Stats = {MaxHealth=92, WalkSpeed=19.5, JumpVelocity=60, AirControl=1.2, Weight=0.82, AirJumps=2, Hitbox="Small"},
		Basic = {Name="Ribbon Combination", Hits={2,2,5}, FinalKnockback=29, Reach=5, Recovery=0.24,
			Description="A precise three-step dance combination with very fast recovery."},
		Abilities = {
			Q={Name="Pirouette", Damage=11, Knockback=35, Cooldown=5.5, Range=6.5,
				Description="Spin through nearby enemies with four light hits and a final outward kick."},
			E={Name="Pointe Counter", Damage=9, Knockback=36, Cooldown=10.5, Range=6,
				Description="Enter a 0.4-second counter pose. A melee hit triggers a sidestep and retaliating strike; projectiles are deflected."},
			R={Name="Grand Jete", Damage=7, Knockback=25, Cooldown=7.5, Range=14,
				Description="Leap in the aimed direction with a damaging split kick. One use before landing; serves as recovery."},
		},
		Passive={Name="Perfect Tempo", Description="Landing a different move than the previous hit grants one Tempo stack, up to 3. At 3, the next ability starts 20% faster and consumes the stacks."},
		Ultimate={Name="Grand Finale", Damage=34, Knockback=76, Duration=5,
			Description="Create a spotlight that draws enemies into a rapid dance sequence and launches them on the final pose."},
	},
	{
		Id = "bombardiro", DisplayName = "Bombardiro Crocodilo", ModelName = "Bombardiro Crocodilo",
		Role = "Artillery Heavy", Difficulty = 2,
		Stats = {MaxHealth=108, WalkSpeed=14, JumpVelocity=48, AirControl=0.7, Weight=1.15, AirJumps=1, Hitbox="Large"},
		Basic = {Name="Wing Bash", Hits={4,4,7}, FinalKnockback=40, Reach=6.5, Recovery=0.44,
			Description="Slow, long-reaching wing and snout strikes."},
		Abilities = {
			Q={Name="Croc Bomb", Damage=12, Knockback=44, Cooldown=6.5, Range=55,
				Description="Lob a timed bomb at the cursor. A close explosion also pushes Bombardiro without damaging him."},
			E={Name="Carpet Run", Damage=12, Knockback=34, Cooldown=11.0, Range=22,
				Description="Fly forward for 0.9 seconds and drop three 4-damage bombs along the route."},
			R={Name="Afterburner", Damage=6, Knockback=24, Cooldown=10.0, Range=16,
				Description="Blast up and forward, leaving a short damaging exhaust trail. One use before landing; serves as recovery."},
		},
		Passive={Name="Payload", Description="Hitting an enemy with a bomb while airborne reduces Afterburner's remaining cooldown by 1.5 seconds, once per cast."},
		Ultimate={Name="Grand Bombardment", Damage=45, Knockback=84, Duration=6,
			Description="Mark five visible impact circles in sequence. Bombs arrive after clear warnings and launch enemies away from each center."},
	},
	{
		Id = "chimpanzini", DisplayName = "Chimpanzini Bananini", ModelName = "Chimpanzini Bananini",
		Role = "Trickster", Difficulty = 2,
		Stats = {MaxHealth=100, WalkSpeed=18, JumpVelocity=56, AirControl=1.0, Weight=0.95, AirJumps=2, Hitbox="Medium"},
		Basic = {Name="Fruit Fists", Hits={3,3,5}, FinalKnockback=32, Reach=5.5, Recovery=0.3,
			Description="Quick ape punches with a banana backswing finisher."},
		Abilities = {
			Q={Name="Banana Boomerang", Damage=12, Knockback=34, Cooldown=5.5, Range=40,
				Description="Throw a banana for 7 damage outbound and 5 on return; one target may be hit on each pass."},
			E={Name="Peel Trap", Damage=8, Knockback=28, Cooldown=9.0, Range=5,
				Description="Drop one peel that lasts 8 seconds. The first enemy to touch it slips briefly and pops upward."},
			R={Name="Vine Grapple", Damage=5, Knockback=18, Cooldown=7.5, Range=60,
				Description="Grapple terrain to swing or an enemy to pull both fighters together. Serves as recovery."},
		},
		Passive={Name="Top Banana", Description="An ability hit primes the next basic attack for 3 bonus damage and a short forward lunge. The bonus expires after 4 seconds."},
		Ultimate={Name="Banana Stampede", Damage=38, Knockback=74, Duration=6,
			Description="Send three clearly telegraphed waves of banana apes across the arena in alternating lanes."},
	},
	{
		Id = "cappuccino", DisplayName = "Cappuccino Assassino", ModelName = "Cappuccino Assassino",
		Role = "Assassin", Difficulty = 3,
		Stats = {MaxHealth=88, WalkSpeed=20.5, JumpVelocity=57, AirControl=1.1, Weight=0.80, AirJumps=2, Hitbox="Small"},
		Basic = {Name="Spoon Work", Hits={3,3,6}, FinalKnockback=30, Reach=5, Recovery=0.23,
			Description="The fastest basic combination, with narrow reach and a sharp spoon finisher."},
		Abilities = {
			Q={Name="Espresso Dash", Damage=9, Knockback=30, Cooldown=4.5, Range=13,
				Description="Dash through one enemy. A hit lets Cappuccino recast once within 1.5 seconds without another cooldown."},
			E={Name="Saucer Parry", Damage=10, Knockback=38, Cooldown=11.0, Range=5,
				Description="Parry for 0.35 seconds. Reflect a projectile or circle behind a melee attacker and strike."},
			R={Name="Steam Step", Damage=5, Knockback=18, Cooldown=9.0, Range=10,
				Description="Make two short directional steam bursts. Charges are restored together on landing; serves as recovery."},
		},
		Passive={Name="Caffeine Rush", Description="Three ability hits within 6 seconds trigger 4 seconds of Rush: 15% movement speed and cooldowns tick 25% faster."},
		Ultimate={Name="Final Serving", Damage=36, Knockback=80, Duration=4,
			Description="Telegraph and perform three rapid target-to-target dashes, then return for a launching final cut."},
	},
	{
		Id = "patapim", DisplayName = "Brr Brr Patapim", ModelName = "Brr Brr Patapim",
		Role = "Ground Controller", Difficulty = 2,
		Stats = {MaxHealth=110, WalkSpeed=15, JumpVelocity=50, AirControl=0.75, Weight=1.14, AirJumps=1, Hitbox="Large"},
		Basic = {Name="Branch Bash", Hits={4,4,6}, FinalKnockback=38, Reach=6.5, Recovery=0.4,
			Description="Heavy branch swipes that cover a broad area."},
		Abilities = {
			Q={Name="Root Line", Damage=8, Knockback=22, Cooldown=7.0, Range=32,
				Description="Send roots through connected ground. The first enemy hit is held for 0.55 seconds."},
			E={Name="Acorn Guard", Damage=6, Knockback=26, Cooldown=12.0, Range=7,
				Description="Grow a 2.5-second tree shield with 25 health. When broken or expired it bursts outward."},
			R={Name="Canopy Bounce", Damage=6, Knockback=25, Cooldown=9.0, Range=8,
				Description="Spring upward from a temporary leaf canopy. Enemies above it are bumped away; serves as recovery."},
		},
		Passive={Name="Seed Trail", Description="Moving 15 ground studs plants a seed, up to 2. Casting near a seed consumes it to add 15% range; seeds expire after 8 seconds."},
		Ultimate={Name="Ancient Stampede", Damage=42, Knockback=80, Duration=6,
			Description="Roots mark three lanes before forest spirits charge through them, finishing with an upward tree burst."},
	},
	{
		Id = "lirili", DisplayName = "Lirili Larila", ModelName = "Lirili Larila",
		Role = "Defensive Grappler", Difficulty = 1,
		Stats = {MaxHealth=118, WalkSpeed=15, JumpVelocity=50, AirControl=0.75, Weight=1.20, AirJumps=1, Hitbox="Large"},
		Basic = {Name="Trunk and Tusk", Hits={4,4,7}, FinalKnockback=42, Reach=6.5, Recovery=0.42,
			Description="Trunk jabs ending with a lifting tusk swing."},
		Abilities = {
			Q={Name="Trunk Snatch", Damage=7, Knockback=18, Cooldown=6.5, Range=16,
				Description="Extend the trunk to pull the first enemy into close range for a basic-attack follow-up."},
			E={Name="Cactus Brace", Damage=4, Knockback=30, Cooldown=10.0, Range=5,
				Description="Brace for 1.2 seconds with 50% damage reduction. Contact attackers take thorn damage and bounce away."},
			R={Name="Desert Geyser", Damage=6, Knockback=28, Cooldown=9.0, Range=8,
				Description="Blast water underneath to rise rapidly and push nearby enemies aside. Serves as recovery."},
		},
		Passive={Name="Water Reserve", Description="Damage taken fills a 100-point reserve. At full reserve, the next ability gains 25% size and knockback, then empties it."},
		Ultimate={Name="Oasis Crash", Damage=24, Knockback=86, Duration=3,
			Description="Choose a visible landing circle, leap high, then crash down with a wide water-and-cactus shockwave."},
	},
	{
		Id = "frigo", DisplayName = "Frigo Camelo", ModelName = "Frigo Camelo",
		Role = "Tank Zoner", Difficulty = 1,
		Stats = {MaxHealth=130, WalkSpeed=13.5, JumpVelocity=47, AirControl=0.65, Weight=1.28, AirJumps=1, Hitbox="Large"},
		Basic = {Name="Fridge Door", Hits={5,5,8}, FinalKnockback=45, Reach=6, Recovery=0.5,
			Description="Slow camel bumps ending in a refrigerator-door slam."},
		Abilities = {
			Q={Name="Ice Tray", Damage=9, Knockback=27, Cooldown=6.0, Range=45,
				Description="Fire three spreading ice cubes for 3 damage each. Hits slow movement by 20% for 1.5 seconds."},
			E={Name="Cold Storage", Damage=6, Knockback=30, Cooldown=12.5, Range=7,
				Description="Move slowly while taking 40% less damage for 1.5 seconds, then release a chill burst."},
			R={Name="Freezer Eject", Damage=8, Knockback=32, Cooldown=10.0, Range=14,
				Description="Fire an ice block one way and recoil in the opposite direction. Aim down to recover upward."},
		},
		Passive={Name="Deep Freeze", Description="Ability hits add Frost for 4 seconds. At 4 stacks, the target is frozen for 0.45 seconds and becomes immune to Frost for 5 seconds."},
		Ultimate={Name="Power Outage", Damage=40, Knockback=78, Duration=7,
			Description="Create a cold field that slows enemies while warning circles show where five heavy icicles will fall."},
	},
	{
		Id = "saturno", DisplayName = "La Vacca Saturno Saturnita", ModelName = "La Vacca Saturno Saturnita",
		Role = "Space Controller", Difficulty = 3,
		Stats = {MaxHealth=112, WalkSpeed=15.5, JumpVelocity=54, AirControl=0.95, Weight=1.10, AirJumps=2, Hitbox="Large"},
		Basic = {Name="Horn Orbit", Hits={3,4,6}, FinalKnockback=36, Reach=6.5, Recovery=0.36,
			Description="Horn swipes followed by a spinning Saturn-ring hit."},
		Abilities = {
			Q={Name="Orbit Ring", Damage=14, Knockback=36, Cooldown=6.0, Range=38,
				Description="Throw a ring that curves out and returns. One enemy may take 7 damage on each pass."},
			E={Name="Gravity Well", Damage=8, Knockback=16, Cooldown=12.0, Range=30,
				Description="Place a warned sphere for 3 seconds that pulls enemies inward and deals four light ticks."},
			R={Name="Saturn Slingshot", Damage=7, Knockback=25, Cooldown=9.0, Range=18,
				Description="Orbit an aimed point briefly, then launch along the tangent. Serves as steerable recovery."},
		},
		Passive={Name="Low Gravity", Description="Holding jump reduces fall speed by 35% for up to 1.2 seconds per airtime; attacking cancels the float."},
		Ultimate={Name="Event Horizon", Damage=38, Knockback=88, Duration=5,
			Description="Form a telegraphed black hole that pulls fighters for 4 seconds before a powerful outward collapse."},
	},
	{
		Id = "orangutini", DisplayName = "Orangutini Ananassini", ModelName = "Orangutini Ananassini",
		Role = "Power Grappler", Difficulty = 2,
		Stats = {MaxHealth=122, WalkSpeed=16.5, JumpVelocity=51, AirControl=0.80, Weight=1.18, AirJumps=1, Hitbox="Large"},
		Basic = {Name="Pineapple Pummel", Hits={4,4,8}, FinalKnockback=43, Reach=6, Recovery=0.4,
			Description="Long ape-arm punches ending in a two-handed hammer fist."},
		Abilities = {
			Q={Name="Pineapple Pound", Damage=13, Knockback=48, Cooldown=6.5, Range=7,
				Description="Armored overhead smash. The startup resists light knockback but still takes damage."},
			E={Name="Peel and Throw", Damage=9, Knockback=44, Cooldown=9.5, Range=5,
				Description="Grab a nearby fighter and throw them in the aimed horizontal direction after a short escape window."},
			R={Name="Canopy Clamber", Damage=6, Knockback=24, Cooldown=8.5, Range=14,
				Description="Pull upward with one arm, then choose a second forward pull. Serves as recovery."},
		},
		Passive={Name="Heavy Hands", Description="Landing an aerial damaging move empowers the next grounded basic finisher with 25% extra knockback for 4 seconds."},
		Ultimate={Name="Jungle Rumble", Damage=42, Knockback=84, Duration=8,
			Description="Gain 20% speed, strong resistance to light flinches, and empowered ground pounds with clear impact warnings."},
	},
	{
		Id = "cocofanto", DisplayName = "Cocofanto Elefanto", ModelName = "Cocofanto Elefanto",
		Role = "Defensive Zoner", Difficulty = 2,
		Stats = {MaxHealth=116, WalkSpeed=14.5, JumpVelocity=49, AirControl=0.72, Weight=1.20, AirJumps=1, Hitbox="Large"},
		Basic = {Name="Husk and Tusk", Hits={4,4,7}, FinalKnockback=40, Reach=6.5, Recovery=0.42,
			Description="Broad trunk and tusk attacks that protect Cocofanto's front."},
		Abilities = {
			Q={Name="Coconut Cannon", Damage=14, Knockback=48, Cooldown=6.5, Range=60,
				Description="Charge for up to 1 second to raise the coconut from 6 damage and 24 knockback to full power."},
			E={Name="Shell Shelter", Damage=5, Knockback=24, Cooldown=12.0, Range=6,
				Description="Close the husk for up to 2 seconds, blocking 30 projectile damage. Reopening pushes nearby enemies."},
			R={Name="Trunk Jet", Damage=6, Knockback=25, Cooldown=9.5, Range=10,
				Description="Spray water downward for a rising, slightly steerable recovery and a small push below."},
		},
		Passive={Name="Thick Husk", Description="After avoiding damage for 8 seconds, the next hit against Cocofanto deals 20% less damage and 30% less knockback."},
		Ultimate={Name="Tropical Monsoon", Damage=40, Knockback=80, Duration=7,
			Description="A moving rainstorm follows Cocofanto while rotating coconuts and water bursts control nearby space."},
	},
}

-- MVP tuning overrides. Unselected design entries remain available for planning.
local mvp = {
 tung_sahur={"TungSahur",115,20,28,1.12,2,3,1},
 tralalero={"Tralalero",100,24,33,0.94,1.9,2.6,1},
 chimpanzini={"Chimpanzini",105,22,30,1.0,1.9,2.7,1},
 ballerina={"Ballerina",90,25,34,0.84,1.6,2.7,2},
 bombardiro={"Bombardiro",130,16,24,1.25,2.8,2.5,1},
}
for _,fighter in Fighters do
 local tuning=mvp[fighter.Id]
 fighter.MVP=tuning~=nil
 if tuning then
  fighter.AssetName=tuning[1]
  local stats=fighter.Stats
  stats.MaxHealth=tuning[2]; stats.WalkSpeed=tuning[3]; stats.SprintSpeed=tuning[4]
  stats.Weight=tuning[5]; stats.HitRadius=tuning[6]; stats.HitHalfHeight=tuning[7]; stats.AirJumps=tuning[8]
 end
end
local function find(id) for _,f in Fighters do if f.Id==id then return f end end end
local shark=find("tralalero")
shark.Stats.JumpVelocity=60
shark.Basic={Name="Bite & Tail",Hits={3,3,6},HitTimes={.115,.115,.15},FinalKnockback=35,Reach=5.5,Recovery=.30,
 Description="Two aimed jaw bites, then a broad sweeping tail finisher. Airborne hits gain 1 damage."}
shark.Abilities.Q={Name="Shark Torpedo",Damage=11,Knockback=39,Cooldown=5.5,Range=26,Duration=.58,HitTime=.08,
 Description="Rush forward 26 studs in 0.42 seconds with a snapping bite. Stops at walls; each enemy can be hit once."}
shark.Abilities.E={Name="Tail Launcher",Damage=8,Knockback=52,Cooldown=7,Range=7,Duration=.70,HitTime=.32,
 Description="Turn through a full close-range tail sweep, popping nearby enemies high for an aerial follow-up. The hit lands after 0.32 seconds."}
shark.Abilities.R={Name="Porpoise Breach",Damage=8,Knockback=30,Cooldown=9,Range=34,Duration=.95,
 Description="Make a long forward porpoise arc: 0.8 seconds of forward thrust, with normal gravity. One recovery per landing."}
shark.Passive={Name="Air Hunter",Description="Airborne basic strikes deal 1 extra damage."}
shark.Ultimate={Name="Feeding Frenzy",Damage=39,Knockback=70,Duration=2.4,Description="Three warned, forward bite bursts. Each can be dodged; no sustained flight."}
local dancer=find("ballerina")
dancer.Stats.JumpVelocity=62
dancer.Basic={Name="Pointe Kicks",Hits={2,2,5},HitTimes={.08,.08,.11},FinalKnockback=29,Reach=5,Recovery=.23,
 Description="Alternate two fast narrow kicks, then step forward into a launching finishing kick."}
dancer.Abilities.Q={Name="Pirouette",Damage=12,Knockback=35,Cooldown=5.5,Range=6.5,Duration=.8,HitTime=.15,Description="Travel forward while spinning for three light hits and a finishing kick."}
dancer.Abilities.E={Name="Pointe Counter",Damage=9,Knockback=36,Cooldown=10.5,Range=7,Duration=.7,HitTime=.08,Description="Block one hit during a 0.4-second window. Retaliate only if the attacker is close and visible."}
dancer.Abilities.R={Name="Double Air Step",Damage=7,Knockback=25,Cooldown=7.5,Range=25,Duration=.80,
 Description="Two quick forward ballet steps with a brief pause between them. Low arcs, not a vertical boost. One sequence per airtime, plus two regular air jumps."}
dancer.Passive={Name="Light Footed",Description="Small hitbox, fast melee recovery and two air jumps, balanced by 90 health and low weight."}
dancer.Ultimate={Name="Grand Finale",Damage=36,Knockback=72,Duration=2.7,Description="Four warned close-range dance hits; the last launches. Enemies can leave the spotlight."}
local chimp=find("chimpanzini")
chimp.Stats.JumpVelocity=68
chimp.Basic={Name="Peel Lash",Hits={3,3,5},HitTimes={.12,.12,.16},FinalKnockback=27,Reach=7.5,Recovery=.34,
 Description="Two extended banana lashes, then flick a visible peel up to 13 studs. The peel stops at walls."}
chimp.Abilities.Q.Range=32
chimp.Abilities.Q.Duration=.65; chimp.Abilities.Q.HitTime=.18
chimp.Abilities.Q.Description="Throw a fast banana 32 studs out in half a second, then back to its launch point: 7 outward and 5 return damage. Walls stop it."
chimp.Abilities.E.Description="Drop one visible peel for 8 seconds. After a 0.5-second warning, the first enemy in range takes a pop-up hit."
chimp.Abilities.E.Duration=.5; chimp.Abilities.E.HitTime=.2
chimp.Abilities.R={Name="Peel Glide",Damage=0,Knockback=0,Cooldown=8,Range=35,Duration=1.4,
 Description="Spread the peel and soar upward and forward for 1.25 seconds. Steer with movement; gravity returns when lift expires. No contact damage; one glide per landing."}
chimp.Passive={Name="Top Banana",Description="An ability hit primes the next melee lash for 3 bonus damage, expiring after 4 seconds. The ranged finisher does not consume it."}
chimp.Ultimate={Name="Banana Barrage",Damage=36,Knockback=65,Duration=2.8,Description="Three warned fans of dodgeable banana projectiles. Each target can take only one hit per fan."}
local bomber=find("bombardiro")
bomber.Stats.JumpVelocity=42
bomber.Basic={Name="Croc Chomp",Hits={7},HitTimes={.27},SingleHit=true,FinalKnockback=42,Reach=6.5,Recovery=.65,
 Description="One heavy, broad jaw chomp after a readable windup. Every chomp launches; no three-hit punch combo."}
bomber.Abilities.Q={Name="Croc Bomb",Damage=13,Knockback=40,Cooldown=6.5,Range=38,Duration=.9,HitTime=.35,Description="Fire a visible slow bomb that explodes on contact or at maximum range. Firing slows movement."}
bomber.Abilities.E={Name="Carpet Run",Damage=12,Knockback=32,Cooldown=11,Range=29,Duration=1.15,HitTime=.2,Description="Fly level forward for 0.9 seconds and release three falling bombs. Each explodes for 4 damage on impact. Gravity resumes when the pass ends."}
bomber.Abilities.R={Name="Afterburner Flight",Damage=0,Knockback=0,Cooldown=10,Range=51,Duration=1.8,
 Description="Power forward and slowly climb for 1.6 seconds. Fuel then cuts out and gravity resumes. One flight per landing; no contact damage."}
bomber.Passive={Name="Heavy Airframe",Description="130 health and high knockback resistance; large hitbox, slower attacks and reduced speed while firing."}
bomber.Ultimate={Name="Grand Bombardment",Damage=42,Knockback=75,Duration=3.3,Description="Three visible, line-of-sight blast zones ahead detonate after warnings. No map-wide hits."}

local byId = {}
for _, fighter in Fighters do
	assert(not byId[fighter.Id], `Duplicate fighter id: {fighter.Id}`)
	byId[fighter.Id] = fighter
end

return table.freeze({List=table.freeze(Fighters), ById=table.freeze(byId)})
