return function()
 local rules=require(game.ReplicatedStorage.TungPrototype.PracticeStockRules)
 local s=rules.New();local serial=rules.Spawn(s,0)
 assert(s.stocks==4 and s.alive)
 assert(not rules.Lose(s,serial-1,1));assert(rules.Lose(s,serial,1))
 assert(not rules.Lose(s,serial,1.1) and s.stocks==3,"Duplicate ring-out/death lost two stocks")
 for i=1,3 do serial=rules.Spawn(s,i+1);assert(rules.Lose(s,serial,i+1)) end
 assert(s.stocks==0 and not s.alive);assert(not rules.Spawn(s,5))
 assert(rules.Spawn(s,8) and s.stocks==4,"Practice set did not reset")
 assert(not rules.Lose(s,serial,9),"Old character consumed new stock")
 assert(not rules.OutOfBounds(Vector3.zero,Vector3.zero))
 assert(rules.OutOfBounds(Vector3.new(0,-29,0),Vector3.zero))
 assert(rules.OutOfBounds(Vector3.new(111,20,0),Vector3.zero))
 return "PASS: 4 stocks, one loss per character, stale death rejected, timed practice reset, ring-out bounds"
end
