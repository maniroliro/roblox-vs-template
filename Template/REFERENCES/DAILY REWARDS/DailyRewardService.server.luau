-- services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- config module
local DAILY_REWARD_CONFIG = require(ReplicatedStorage:FindFirstChild("DAILY_REWARD_CONFIG", true))

-- remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local functionsFolder = remotesFolder:WaitForChild("Functions")
local promptDailyRewardFunction = functionsFolder:WaitForChild("PromptDailyReward")

-- modules
local DailyReward = require(script.DailyReward)

-- values
local AUTOSAVE_DELAY = 60

-- functions
function GetRewardStatus(player, playerRewardData)
	-- Cheat Sheet: (0 = IGNORE, 1 = REDEEM, 2 = RESET)
	if playerRewardData.NextDailyRewardTime == 0 then
		-- player has no data (reset and start them off at day 1)
		print("Daily rewards started for: ", player.Name)
		return 2
	else
		if os.time() > playerRewardData.NextDailyRewardTime then
			if playerRewardData.RewardRedeemable and DAILY_REWARD_CONFIG.RESET_STREAK_IF_MISSED then
				-- player is outside the redeem period (reset)
				print("Daily reward redeem period expired: ", player.Name)
				return 2
			else
				-- player has redeemed reward already, and cooldown has expired and we increment to the next day
				if playerRewardData.CurrentDay < DAILY_REWARD_CONFIG.MAX_DAYS then
					DailyReward.AddToPlayerData(player, "CurrentDay", 1)
				else
					DailyReward.SetPlayerData(player, "CurrentDay", 1)
				end
				DailyReward.SetPlayerData(
					player,
					"NextDailyRewardTime",
					os.time() + DAILY_REWARD_CONFIG.COOLDOWN_SECONDS
				)
				DailyReward.SetPlayerData(player, "RewardRedeemable", true)
				print("Next day's reward unlocked: ", player.Name)
				return 1
			end
		else
			if playerRewardData.RewardRedeemable then
				-- player is within redeem period and yet to do so (redeemable)
				print("Reward is still eligible to redeem: ", player.Name)
				return 1
			end
		end
	end

	-- player has no reward to claim yet
	print("Not eligible to claim any rewards yet: ", player.Name)
	return 0
end

function GivePlayerReward(player, dayID)
	-- if dayID == 1 do somemthing here
end

-- player data
Players.PlayerAdded:Connect(function(player)
	local playerRewardData, playerSessionData = DailyReward.AddPlayer(player)
	if playerSessionData.DataStatus == 1 then
		local rewardStatus = GetRewardStatus(player, playerRewardData)
		if rewardStatus == 2 then
			DailyReward.SetPlayerData(player, "CurrentDay", 1)
			DailyReward.SetPlayerData(player, "NextDailyRewardTime", os.time() + DAILY_REWARD_CONFIG.COOLDOWN_SECONDS)
			DailyReward.AddToPlayerData(player, "CurrentDailyRewardStreak", 0)
			DailyReward.SetPlayerData(player, "RewardRedeemable", true)
		end

		-- check if player is able to claim a reward
		if rewardStatus >= 1 then
			task.defer(function()
				local success, err = pcall(function()
					promptDailyRewardFunction:InvokeClient(player, playerRewardData)
				end)
				if success then
					DailyReward.AddToPlayerData(player, "TotalDailyRewardsClaimed", 1)
					DailyReward.AddToPlayerData(player, "CurrentDailyRewardStreak", 1)
					local longestDailyRewardStreak = DailyReward.GetPlayerData(player, "LongestDailyRewardStreak")
					local currentDailyRewardStreak = DailyReward.GetPlayerData(player, "CurrentDailyRewardStreak")
					if currentDailyRewardStreak > longestDailyRewardStreak then
						DailyReward.SetPlayerData(player, "LongestDailyRewardStreak", currentDailyRewardStreak)
					end
					DailyReward.SetPlayerData(player, "RewardRedeemable", false)
					GivePlayerReward(player, playerRewardData.CurrentDay)
				else
					warn(err)
				end
			end)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	DailyReward.RemovePlayer(player)
end)

-- server close
game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		DailyReward.RemovePlayer(player)
	end
end)

--  autosave
task.spawn(function()
	while task.wait(AUTOSAVE_DELAY) do
		local executed, total = 0, 0
		for _, player in pairs(Players:GetPlayers()) do
			local success = DailyReward.SavePlayerData(player)
			total += 1
			if success then
				executed += 1
			end
		end
		print("Players Data Autosaved: (" .. tostring(executed) .. "/" .. tostring(total) .. ")")
	end
end)
