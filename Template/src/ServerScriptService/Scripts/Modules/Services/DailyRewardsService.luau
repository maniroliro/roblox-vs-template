local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local SharedModules = ReplicatedStorage.Modules.Shared

local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
local DailyRewardsData = require(SharedModules.Data.DailyRewardsData)
local RemotesManager = require(SharedModules.Managers.RemotesManager)
local ItemsService = nil
local GearsService = nil

local DailyRewardsService = {}

local dailyRewardAvailableRemote = nil
local notifiedPlayers = {}

local function canClaimReward(dailyRewards)
	if dailyRewards.LastClaimedTime == 0 then
		return true
	end

	local currentTime = os.time()
	local nextAvailableTime = dailyRewards.LastClaimedTime + DailyRewardsData.CooldownSeconds

	return currentTime >= nextAvailableTime
end

local function getNextAvailableTime(dailyRewards)
	if dailyRewards.LastClaimedTime == 0 then
		return 0
	end
	return dailyRewards.LastClaimedTime + DailyRewardsData.CooldownSeconds
end

local function onGetDailyRewardsData(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return nil
	end

	local dailyRewards = data.DailyRewards

	return {
		CurrentDay = dailyRewards.CurrentDay,
		LastClaimedTime = dailyRewards.LastClaimedTime,
		NextAvailableTime = getNextAvailableTime(dailyRewards),
		CanClaim = canClaimReward(dailyRewards),
		CurrentStreak = dailyRewards.CurrentStreak,
		LongestStreak = dailyRewards.LongestStreak,
	}
end

local function onClaimDailyReward(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	local dailyRewards = data.DailyRewards

	if not canClaimReward(dailyRewards) then
		return false
	end

	notifiedPlayers[player] = nil

	local reward = DailyRewardsData.Rewards[dailyRewards.CurrentDay]
	if not reward then
		return false
	end

	if reward.Cash then
		PlayerDataManager.Increase(player, "Cash", reward.Cash)
	end

	if reward.Item then
		if not ItemsService then
			ItemsService = require(Modules.Services.ItemsService)
		end
		ItemsService.GiveItem(player, reward.Item)
	end

	if reward.Gear then
		if not GearsService then
			GearsService = require(Modules.Services.GearsService)
		end
		GearsService.GiveGearFromRobux(player, reward.Gear)
	end

	local claimedDay = dailyRewards.CurrentDay

	dailyRewards.LastClaimedTime = os.time()
	dailyRewards.CurrentStreak = dailyRewards.CurrentStreak + 1

	if dailyRewards.CurrentStreak > dailyRewards.LongestStreak then
		dailyRewards.LongestStreak = dailyRewards.CurrentStreak
	end

	if dailyRewards.CurrentDay < DailyRewardsData.MaxDays then
		dailyRewards.CurrentDay = dailyRewards.CurrentDay + 1
	else
		dailyRewards.CurrentDay = 1
		dailyRewards.CurrentStreak = 0
	end

	PlayerDataManager.UpdateClient(player)

	return true, claimedDay
end

local function checkAndNotifyPlayer(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	if not data.DailyRewards then
		data.DailyRewards = {
			CurrentDay = 1,
			LastClaimedTime = 0,
			CurrentStreak = 0,
			LongestStreak = 0,
		}
	end

	-- if FORCE_RESET_DATA then
	-- 	data.DailyRewards.CurrentDay = 1
	-- 	data.DailyRewards.LastClaimedTime = 0
	-- 	data.DailyRewards.CurrentStreak = 0
	-- end

	local canClaim = canClaimReward(data.DailyRewards)

	if canClaim and dailyRewardAvailableRemote then
		if not notifiedPlayers[player] then
			notifiedPlayers[player] = true
			dailyRewardAvailableRemote:FireClient(player)
		end
	end
end

local function startRewardChecker()
	print("[DailyRewards] startRewardChecker started")
	task.spawn(function()
		while true do
			task.wait(5)
			print("[DailyRewards] Checking all players...")
			for _, player in Players:GetPlayers() do
				local data = PlayerDataManager.GetData(player)
				if data and data.DailyRewards then
					local canClaim = canClaimReward(data.DailyRewards)
					print("[DailyRewards]", player.Name, "canClaim:", canClaim, "notified:", notifiedPlayers[player])
					if canClaim and dailyRewardAvailableRemote and not notifiedPlayers[player] then
						print("[DailyRewards] Firing DailyRewardAvailable to", player.Name)
						notifiedPlayers[player] = true
						dailyRewardAvailableRemote:FireClient(player)
					end
				end
			end
		end
	end)
end

local function onPlayerAdded(player: Player)
	local maxRetries = 10
	local retries = 0
	while not PlayerDataManager.GetData(player) and retries < maxRetries do
		task.wait(0.5)
		retries += 1
	end

	task.wait(1)
	checkAndNotifyPlayer(player)
end

function DailyRewardsService.Init() end

function DailyRewardsService.Start()
	local getDailyRewardsData = RemotesManager:GetRemote("GetDailyRewardsData")
	local claimDailyReward = RemotesManager:GetRemote("ClaimDailyReward")
	dailyRewardAvailableRemote = RemotesManager:GetRemote("DailyRewardAvailable")

	getDailyRewardsData.OnServerInvoke = onGetDailyRewardsData
	claimDailyReward.OnServerInvoke = onClaimDailyReward

	local dailyRewardsClosed = RemotesManager:GetRemote("DailyRewardsClosed")
	dailyRewardsClosed.OnServerEvent:Connect(function(player)
		print("[DailyRewards] GUI closed by", player.Name, "- resetting notified status")
		notifiedPlayers[player] = nil
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		notifiedPlayers[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	startRewardChecker()
end

return DailyRewardsService
