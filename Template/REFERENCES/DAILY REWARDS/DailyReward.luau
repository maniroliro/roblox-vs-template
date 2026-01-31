-- services
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- modules
local DAILY_REWARD_CONFIG = require(ReplicatedStorage:FindFirstChild("DAILY_REWARD_CONFIG", true))

-- values
local MAX_ATTEMPTS = 10

-- variables
local dailyRewardDataStore = DataStoreService:GetDataStore(DAILY_REWARD_CONFIG.DATASTORE_KEY)

local playerRewardData = {}
local playerSessionData = {}
local savingCache = {}

local DEFAULT_DATA = {

	CurrentDay = 1,
	RewardRedeemable = false,
	NextDailyRewardTime = 0,

	TotalDailyRewardsClaimed = 0,
	LongestDailyRewardStreak = 0,
	CurrentDailyRewardStreak = 0,
}
local DEFAULT_SESSION_DATA = {

	DataStatus = 0, -- (0 = NOT_ATTEMPTED, 1 = SUCCESS, 2 = FAILED)
}

local DailyReward = {}

-- functions
function FetchPlayerData(player)
	local success, data, err
	local attempts = 10
	repeat
		success, data, err = pcall(function()
			return dailyRewardDataStore:GetAsync(player.UserId)
		end)
		attempts -= 1
		task.wait()
	until success or attempts <= 0

	-- do final check if it was successful
	if not success then
		warn("Failed to fetch reward data: " .. err, player.Name)
		return success
	end

	-- check for previous data entry
	if data == nil then
		--print("No previous reward data found for: " .. player.Name)
	else
		--print("Successfully fetched reward data: " .. player.Name)
	end
	return success, data, err
end

function InitializePlayerData(player)
	local success, err
	local attempts = MAX_ATTEMPTS
	repeat
		success, err = pcall(function()
			return dailyRewardDataStore:SetAsync(player.UserId, playerRewardData[player.UserId])
		end)

		if not success then
			warn(
				"Failed to save player data for "
					.. player.Name
					.. ". Attempts left: "
					.. attempts
					.. ". Error: "
					.. tostring(err)
			)
			task.wait(0.5)
		end

		attempts -= 1
	until success or attempts <= 0

	-- do final check if it was successful
	if success then
		print("Successfully initialized reward data: " .. player.Name)
	end
	return success
end

function StorePlayerData(player)
	if playerSessionData[player.UserId]["DataStatus"] ~= 1 then
		warn("Save blocked: data not loaded for " .. player.Name)
		return false
	end

	if savingCache[player.UserId] then
		return false
	end
	savingCache[player.UserId] = true

	-- save settings data to data store
	local success, result
	local attempts = MAX_ATTEMPTS
	repeat
		success, result = pcall(function()
			dailyRewardDataStore:UpdateAsync(player.UserId, function(pastPlayerRewardData)
				local data = pastPlayerRewardData or table.clone(DEFAULT_DATA)

				local newData = playerRewardData[player.UserId]
				if not newData then
					return data
				end

				for key, value in pairs(newData) do
					if value ~= nil then
						data[key] = value
					end
				end

				return data
			end)
		end)

		if not success then
			warn(
				"Failed to update reward data for "
					.. player.Name
					.. ". Attempts left: "
					.. attempts
					.. ". Error: "
					.. tostring(result)
			)
			task.wait(0.5)
		end

		attempts -= 1
	until success or attempts <= 0

	-- do final check if it was successful
	if success then
		print("Successfully updated reward data: " .. player.Name)
	end
	savingCache[player.UserId] = nil
	return success
end

-- module functions
function DailyReward.AddPlayer(player)
	playerRewardData[player.UserId] = table.clone(DEFAULT_DATA)
	playerSessionData[player.UserId] = table.clone(DEFAULT_SESSION_DATA)

	-- check if player has previous data
	local success, storedData = FetchPlayerData(player) -- check's to see if the player has "storedData" and if so it overwrite's their default data with that data
	if success then
		if storedData then
			for token, value in pairs(storedData) do
				if playerRewardData[player.UserId][token] ~= nil then
					playerRewardData[player.UserId][token] = value
				end
			end
			print("Successfully loaded reward data: " .. player.Name)
		else
			InitializePlayerData(player) -- must be their first time playing so we add them to the datastore (they have no previous data)
		end
		playerSessionData[player.UserId]["DataStatus"] = 1 -- SUCCESS
	else
		playerSessionData[player.UserId]["DataStatus"] = 2 -- FAILED
	end

	-- return player data once it has been loaded
	return playerRewardData[player.UserId], playerSessionData[player.UserId]
end

function DailyReward.RemovePlayer(player)
	StorePlayerData(player)
	if not savingCache[player.UserId] then
		playerRewardData[player.UserId] = nil
		playerSessionData[player.UserId] = nil
	end
end

function DailyReward.SavePlayerData(player)
	return StorePlayerData(player)
end

function DailyReward.GetPlayerData(player, key)
	local prdata = playerRewardData[player.UserId]
	if prdata ~= nil then
		return prdata[key]
	end
end

function DailyReward.SetPlayerData(player, key, value)
	local prdata = playerRewardData[player.UserId]
	if prdata ~= nil then
		prdata[key] = value
	end
end

function DailyReward.AddToPlayerData(player, key, amount)
	local prdata = playerRewardData[player.UserId]
	if prdata ~= nil then
		prdata[key] += amount
	end
end

return DailyReward
