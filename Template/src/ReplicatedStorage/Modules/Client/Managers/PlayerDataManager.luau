--[[
	PlayerDataManager (Client)
	
	Responsible for:
	- Caching player data received from server
	- Providing access to player data for client modules
	- Firing events when data changes
	
	Does NOT:
	- Modify data (server does that)
	- Make gameplay decisions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Packages.signal)
local SoundManager = require(ReplicatedStorage.Modules.Client.Managers.SoundManager)

local PlayerDataManager = {}
PlayerDataManager.DataUpdated = Signal.new()

local playerData = nil
local dataIsLoaded = false
local updateDataRemote = nil

-- Private functions
local function onDataUpdated(newData)
	local oldData = playerData
	playerData = newData
	dataIsLoaded = true

	if oldData then
		if newData.Cash and oldData.Cash and newData.Cash > oldData.Cash then
			SoundManager.Play("Cash")
		end

		if newData.Wins and oldData.Wins and newData.Wins > oldData.Wins then
			SoundManager.Play("Victory")
		end
	end

	PlayerDataManager.DataUpdated:Fire(newData, oldData)
end

-- Public API
function PlayerDataManager.Init()
	local RemotesManager = require(ReplicatedStorage.Modules.Shared.Managers.RemotesManager)
	updateDataRemote = RemotesManager:GetRemote("UpdatePlayerData")

	local robuxPurchaseRemote = RemotesManager:GetRemote("RobuxPurchaseCompleted")
	if robuxPurchaseRemote then
		robuxPurchaseRemote.OnClientEvent:Connect(function()
			SoundManager.Play("PurchasedRobux")
		end)
	end
end

function PlayerDataManager.Start()
	updateDataRemote.OnClientEvent:Connect(onDataUpdated)
end

function PlayerDataManager.GetData()
	return playerData
end

function PlayerDataManager.Get(key: string)
	if not playerData then
		return nil
	end
	return playerData[key]
end

function PlayerDataManager.GetNested(key: string, subKey: string)
	if not playerData or not playerData[key] then
		return nil
	end
	return playerData[key][subKey]
end

function PlayerDataManager.IsLoaded(): boolean
	return dataIsLoaded
end

function PlayerDataManager.WaitForData()
	if dataIsLoaded then
		return playerData
	end

	while not dataIsLoaded do
		task.wait(0.1)
	end

	return playerData
end

return PlayerDataManager
