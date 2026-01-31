local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ServerScriptService.Scripts.Modules

local MultipliersData = require(ReplicatedStorage.Modules.Shared.Data.MultipliersData)

local MAP_UNLOCK_ORDER = {
	["67Blue"] = "67Red",
	["67Red"] = "67Green",
	["67Green"] = "67Purple",
}

local function onSkipStagePurchased(player)
	local MapService = require(Modules.Services.MapService)
	local PlayerDataManager = require(Modules.Managers.PlayerDataManager)

	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	local lastMap = data.LastMapPlayed
	if not lastMap or lastMap == "" then
		return false
	end

	local mapData = data.Map[lastMap]
	if not mapData then
		return false
	end

	if mapData.LastCheckpoint >= 50 then
		return false
	end

	local newCheckpoint = mapData.LastCheckpoint + 1
	if newCheckpoint > 50 then
		return false
	end

	mapData.LastCheckpoint = newCheckpoint
	data.CurrentCheckpoint = newCheckpoint

	if newCheckpoint > (mapData.CheckpointReached or 0) then
		local previousReached = mapData.CheckpointReached or 0
		mapData.CheckpointReached = newCheckpoint
		local MapsData = require(Modules.Data.MapsData)
		local cashReward = (newCheckpoint - previousReached) * MapsData.CheckpointRewards
		PlayerDataManager.Increase(player, "Cash", cashReward)
	end

	if newCheckpoint >= 50 then
		mapData.Completed = true
		PlayerDataManager.Increase(player, "Wins", 1)

		local nextMap = MAP_UNLOCK_ORDER[lastMap]
		if nextMap then
			MapService.DestroyUnlockWall(nextMap)
		end

		MapService.ShowFinishPart(player, lastMap)
		MapService.TeleportToCheckpoint(player, lastMap, 50)
	else
		MapService.TeleportToCheckpoint(player, lastMap, newCheckpoint)
	end

	PlayerDataManager.UpdateClient(player)
	return true
end

local function onFinishMapPurchased(player)
	local MapService = require(Modules.Services.MapService)
	local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
	local MapsData = require(Modules.Data.MapsData)

	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	local lastMap = data.LastMapPlayed
	if not lastMap or lastMap == "" then
		return false
	end

	local mapData = data.Map[lastMap]
	if not mapData then
		return false
	end

	if (mapData.CheckpointReached or 0) >= 50 then
		return false
	end

	local checkpointReached = mapData.CheckpointReached or 0
	local cashReward = (50 - checkpointReached) * MapsData.CheckpointRewards
	PlayerDataManager.Increase(player, "Cash", cashReward)

	mapData.CheckpointReached = 50
	mapData.LastCheckpoint = 50
	data.CurrentCheckpoint = 50
	mapData.Completed = true
	PlayerDataManager.Increase(player, "Wins", 1)

	local nextMap = MAP_UNLOCK_ORDER[lastMap]
	if nextMap then
		MapService.DestroyUnlockWall(nextMap)
	end

	MapService.ShowFinishPart(player, lastMap)
	MapService.TeleportToCheckpoint(player, lastMap, 50)

	PlayerDataManager.UpdateClient(player)
	return true
end

local function onBuyCash(Amount)
	return function(player)
		local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
		PlayerDataManager.Increase(player, "Cash", Amount)
		PlayerDataManager.UpdateClient(player)
		return true
	end
end

local function onKillAll(purchaser)
	local Players = game:GetService("Players")

	for _, targetPlayer in Players:GetPlayers() do
		if targetPlayer ~= purchaser then
			local character = targetPlayer.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.Health = 0
				end
			end
		end
	end

	return true
end

local function onGearPurchased(gearKey)
	return function(player)
		local GearsService = require(Modules.Services.GearsService)
		return GearsService.GiveGearFromRobux(player, gearKey)
	end
end

local function onMultiplierPurchased(productId)
	return function(player)
		local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
		local PlayerStatsManager = require(ReplicatedStorage.Modules.Shared.Managers.PlayerStatsManager)
		
		local statType, multiplier = MultipliersData.GetMultiplierByProductId(productId)
		if not statType or not multiplier then
			return false
		end
		
		local data = PlayerDataManager.GetData(player)
		if not data then
			return false
		end
		
		if not data.RobuxMultipliers then
			data.RobuxMultipliers = { Jump = 1, Speed = 1 }
		end
		
		local currentMultiplier = data.RobuxMultipliers[statType] or 1
		if multiplier <= currentMultiplier then
			return false
		end
		
		data.RobuxMultipliers[statType] = multiplier
		PlayerStatsManager.ApplyRobuxMultipliers(player, data.RobuxMultipliers)
		PlayerDataManager.UpdateClient(player)
		
		return true
	end
end

local multiplierProducts = {}
for _, entry in MultipliersData.Jump do
	multiplierProducts[entry.ProductId] = onMultiplierPurchased(entry.ProductId)
end
for _, entry in MultipliersData.Speed do
	multiplierProducts[entry.ProductId] = onMultiplierPurchased(entry.ProductId)
end

local baseProducts = {
	[3490496273] = onSkipStagePurchased,
	[3490493898] = onFinishMapPurchased,
	[3490490753] = onBuyCash(1000),
	[3490491535] = onBuyCash(5000),
	[3490491767] = onBuyCash(10000),
	[3490493055] = onBuyCash(30000),
	[3490493315] = onBuyCash(50000),
	[3490494453] = onKillAll,

	[3496999724] = onGearPurchased("BloxyCola"),
	[3497000224] = onGearPurchased("TeddyBear"),
	[3497000553] = onGearPurchased("Cheezburger"),
	[3497000951] = onGearPurchased("Pizza"),
	[3497001338] = onGearPurchased("PirateJuice"),
}

for productId, handler in multiplierProducts do
	baseProducts[productId] = handler
end

return baseProducts
