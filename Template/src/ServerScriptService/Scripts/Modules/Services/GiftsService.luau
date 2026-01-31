local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Modules = ServerScriptService.Scripts.Modules
local SharedModules = ReplicatedStorage.Modules.Shared

local RemotesManager = require(SharedModules.Managers.RemotesManager)
local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
local GiftsData = require(SharedModules.Data.GiftsData)

local GiftsService = {}

local RESET_INTERVAL = 24 * 60 * 60 -- 24 hours in seconds
local sessionPlaytime = {} -- [Player] = seconds in current session
local ItemsService = nil
local GearsService = nil

local getPlaytimeDataRemote = nil
local claimGiftRemote = nil
local playtimeUpdatedRemote = nil

local function getTotalPlaytime(player: Player): number
	local playtimeData = PlayerDataManager.GetNested(player, "Playtime", "TotalSeconds") or 0
	local currentSession = sessionPlaytime[player] or 0
	return playtimeData + currentSession
end

local function checkAndResetGifts(player: Player)
	local lastReset = PlayerDataManager.GetNested(player, "Playtime", "LastReset") or 0
	local currentTime = os.time()

	if currentTime - lastReset >= RESET_INTERVAL then
		PlayerDataManager.SetNested(player, "Playtime", "ClaimedGifts", {})
		PlayerDataManager.SetNested(player, "Playtime", "TotalSeconds", 0)
		PlayerDataManager.SetNested(player, "Playtime", "LastReset", currentTime)
		return true
	end

	return false
end

local function hasClaimedGift(player: Player, giftNumber: number): boolean
	local claimedGifts = PlayerDataManager.GetNested(player, "Playtime", "ClaimedGifts") or {}
	return table.find(claimedGifts, giftNumber) ~= nil
end

local function getGiftData(giftNumber: number)
	for _, gift in GiftsData do
		if gift.GiftNumber == giftNumber then
			return gift
		end
	end
	return nil
end

local function onGetPlaytimeData(player: Player)
	checkAndResetGifts(player)

	local totalPlaytime = getTotalPlaytime(player)
	local claimedGifts = PlayerDataManager.GetNested(player, "Playtime", "ClaimedGifts") or {}
	local lastReset = PlayerDataManager.GetNested(player, "Playtime", "LastReset") or os.time()

	return {
		TotalPlaytime = totalPlaytime,
		ClaimedGifts = claimedGifts,
		LastReset = lastReset,
	}
end

local function onClaimGift(player: Player, giftNumber: number)
	if typeof(giftNumber) ~= "number" then
		return false
	end

	if giftNumber < 1 or giftNumber > #GiftsData then
		return false
	end

	if hasClaimedGift(player, giftNumber) then
		return false
	end

	local giftData = getGiftData(giftNumber)
	if not giftData then
		return false
	end

	local totalPlaytime = getTotalPlaytime(player)
	if totalPlaytime < giftData.Time then
		return false
	end

	local claimedGifts = PlayerDataManager.GetNested(player, "Playtime", "ClaimedGifts") or {}
	table.insert(claimedGifts, giftNumber)
	PlayerDataManager.SetNested(player, "Playtime", "ClaimedGifts", claimedGifts)

	PlayerDataManager.Increase(player, "Cash", giftData.Reward)

	if giftData.Item then
		if not ItemsService then
			ItemsService = require(Modules.Services.ItemsService)
		end
		ItemsService.GiveItem(player, giftData.Item)
	end

	if giftData.Gear then
		if not GearsService then
			GearsService = require(Modules.Services.GearsService)
		end
		GearsService.GiveGearFromRobux(player, giftData.Gear)
	end

	return true
end

local function startPlaytimeTracking()
	task.spawn(function()
		while true do
			task.wait(1)

			for _, player in Players:GetPlayers() do
				if sessionPlaytime[player] then
					sessionPlaytime[player] += 1

					if playtimeUpdatedRemote then
						playtimeUpdatedRemote:FireClient(player, getTotalPlaytime(player))
					end
				end
			end
		end
	end)
end

local function onPlayerAdded(player: Player)
	sessionPlaytime[player] = 0

	local lastReset = PlayerDataManager.GetNested(player, "Playtime", "LastReset")
	if not lastReset or lastReset == 0 then
		PlayerDataManager.SetNested(player, "Playtime", "LastReset", os.time())
	end

	checkAndResetGifts(player)
end

local function onPlayerRemoving(player: Player)
	local currentSession = sessionPlaytime[player] or 0

	if currentSession > 0 then
		local totalSeconds = PlayerDataManager.GetNested(player, "Playtime", "TotalSeconds") or 0
		PlayerDataManager.SetNested(player, "Playtime", "TotalSeconds", totalSeconds + currentSession)
	end

	sessionPlaytime[player] = nil
end

function GiftsService.Init()
	getPlaytimeDataRemote = RemotesManager:GetRemote("GetPlaytimeData")
	claimGiftRemote = RemotesManager:GetRemote("ClaimGift")
	playtimeUpdatedRemote = RemotesManager:GetRemote("PlaytimeUpdated")
end

function GiftsService.Start()
	getPlaytimeDataRemote.OnServerInvoke = onGetPlaytimeData
	claimGiftRemote.OnServerInvoke = onClaimGift

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	startPlaytimeTracking()
end

return GiftsService
