--[[
	PlayerDataManager
	
	Responsible for:
	- Caching player profiles
	- Reading player data
	- Mutating player data
	- Syncing data to client
	
	Does NOT:
	- Load/save profiles (PlayerDataService does that)
	- Orchestrate systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataTemplate = require(ServerScriptService.Scripts.Modules.Data.PlayerDataTemplate)

local PlayerDataManager = {}
PlayerDataManager._cache = {} -- [Player] = Profile

local RemotesManager = nil
local updateDataRemote = nil

-- Initialize remotes (called after RemotesManager.Init)
function PlayerDataManager.Init()
	RemotesManager = require(ReplicatedStorage.Modules.Shared.Managers.RemotesManager)
	updateDataRemote = RemotesManager:GetRemote("UpdatePlayerData")
end

-- Cache Management
function PlayerDataManager.SetProfile(player: Player, profile)
	PlayerDataManager._cache[player] = profile
end

function PlayerDataManager.GetProfile(player: Player)
	return PlayerDataManager._cache[player]
end

function PlayerDataManager.GetData(player: Player)
	local profile = PlayerDataManager._cache[player]
	if not profile then
		return nil
	end
	return profile.Data
end

function PlayerDataManager.ClearCache(player: Player)
	PlayerDataManager._cache[player] = nil
end

-- Client Sync
function PlayerDataManager.UpdateClient(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	task.spawn(function()
		updateDataRemote:FireClient(player, data)
	end)
end

-- Data Mutation
function PlayerDataManager.Set(player: Player, key: string, value: any)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	data[key] = value
	PlayerDataManager.UpdateClient(player)
end

function PlayerDataManager.Get(player: Player, key: string)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return nil
	end

	return data[key]
end

function PlayerDataManager.Increase(player: Player, key: string, amount: number)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	data[key] = (data[key] or 0) + amount
	PlayerDataManager.UpdateClient(player)
end

function PlayerDataManager.Decrease(player: Player, key: string, amount: number)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	data[key] = (data[key] or 0) - amount
	PlayerDataManager.UpdateClient(player)
end

function PlayerDataManager.Reset(player: Player, key: string?)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	if key then
		data[key] = PlayerDataTemplate[key]
	else
		for k, v in PlayerDataTemplate do
			data[k] = v
		end
	end

	PlayerDataManager.UpdateClient(player)
end

-- Nested Data (for tables like Settings, Upgrades, etc.)
function PlayerDataManager.SetNested(player: Player, key: string, subKey: string, value: any)
	local data = PlayerDataManager.GetData(player)
	if not data or not data[key] then
		return
	end

	data[key][subKey] = value
	PlayerDataManager.UpdateClient(player)
end

function PlayerDataManager.GetNested(player: Player, key: string, subKey: string)
	local data = PlayerDataManager.GetData(player)
	if not data or not data[key] then
		return nil
	end

	return data[key][subKey]
end

function PlayerDataManager.Start()
	-- Nothing to start, but required by architecture
end

return PlayerDataManager
