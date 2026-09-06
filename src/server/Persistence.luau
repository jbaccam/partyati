local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.CopyTheScene.Config)
local P = { Records = {} }
local enabled = not RunService:IsStudio() or Config.StudioDataStores
local store = enabled
	and DataStoreService:GetDataStore(RunService:IsStudio() and "CopyTheScene_Studio_v1" or "CopyTheScene_v1")

-- Session cumulative receipts make retries idempotent, including ambiguous failed writes.
function P.Merge(old, session, coins, wins, now)
	old = type(old) == "table" and old or {}
	local receipts = type(old.Receipts) == "table" and old.Receipts or {}
	local previous = receipts[session] or { Coins = 0, Wins = 0 }
	old.Coins = math.max(0, tonumber(old.Coins) or 0) + math.max(0, coins - previous.Coins)
	old.Wins = math.max(0, tonumber(old.Wins) or 0) + math.max(0, wins - previous.Wins)
	receipts[session] = { Coins = math.max(coins, previous.Coins), Wins = math.max(wins, previous.Wins), At = now }
	-- Sessions are short-lived; keep a week of receipts for safe reconnect/retry overlap.
	for id, receipt in pairs(receipts) do
		if id ~= session and now - (receipt.At or now) > 7 * 86400 then
			receipts[id] = nil
		end
	end
	old.Receipts = receipts
	old.Version = 1
	return old
end

local function retry(callback)
	local result
	for attempt = 1, 3 do
		local ok, value = pcall(callback)
		if ok then
			return true, value
		end
		result = value
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	return false, result
end

function P.Load(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	for _, name in ipairs({ "Coins", "Wins" }) do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	local r =
		{ Session = HttpService:GenerateGUID(false), Coins = 0, Wins = 0, SavedCoins = 0, SavedWins = 0, Ready = false }
	P.Records[player] = r
	player:SetAttribute("SaveStatus", enabled and "Loading" or "Studio: not saved")
	if not enabled then
		r.Ready = true
		return
	end
	local ok, data = retry(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not player.Parent then
		P.Records[player] = nil
		return
	end
	if ok then
		r.Ready = true
		stats.Coins.Value = type(data) == "table" and tonumber(data.Coins) or 0
		stats.Wins.Value = type(data) == "table" and tonumber(data.Wins) or 0
		player:SetAttribute("SaveStatus", "Saved")
	else
		player:SetAttribute("SaveStatus", "Unavailable: rewards paused")
		warn("[CopyTheScene] Data load failed for", player.UserId, data)
	end
end

function P.Award(player, coins, wins)
	local r = P.Records[player]
	if not r or not r.Ready then
		return
	end
	r.Coins += coins
	r.Wins += wins
	player.leaderstats.Coins.Value += coins
	player.leaderstats.Wins.Value += wins
	player:SetAttribute("SaveStatus", enabled and "Pending save" or "Studio: not saved")
end

function P.Save(player)
	local r = P.Records[player]
	if not enabled or not r or not r.Ready then
		return true
	end
	while r.Saving do
		task.wait(0.1)
	end
	if r.Coins == r.SavedCoins and r.Wins == r.SavedWins then
		return true
	end
	r.Saving = true
	local coins, wins = r.Coins, r.Wins
	local ok, err = retry(function()
		return store:UpdateAsync("Player_" .. player.UserId, function(old)
			return P.Merge(old, r.Session, coins, wins, os.time())
		end)
	end)
	r.Saving = false
	if ok then
		r.SavedCoins = coins
		r.SavedWins = wins
	end
	if player.Parent then
		player:SetAttribute("SaveStatus", ok and "Saved" or "Retrying save")
	end
	if not ok then
		warn("[CopyTheScene] Save pending for", player.UserId, err)
	end
	return ok
end

function P.Remove(player)
	if P.Save(player) then
		P.Records[player] = nil
	end -- Failed saves stay queued for autosave/shutdown.
end

function P.Start()
	task.spawn(function()
		while task.wait(60) do
			for player in pairs(P.Records) do
				task.spawn(function()
					if P.Save(player) and not player.Parent then
						P.Records[player] = nil
					end
				end)
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for player in pairs(P.Records) do
			pending += 1
			task.spawn(function()
				P.Save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end
return P
