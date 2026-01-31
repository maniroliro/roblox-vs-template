--[[ Made By Wheez ]]
--
local Settings = {
	["RefreshDelay"] = (24 * 60 * 60),
	--[[
	RefreshDelay in Seconds.
	It determines the time in which all gifts
	are refreshed, so that they can be claimed
	again. This also resets the timer
	on them.
	--]]
}
--[[]]
--
local DataStoreService = game:GetService("DataStoreService")
local GiftsData = DataStoreService:GetDataStore("GiftsDataStore")
local DataModule = require(script:WaitForChild("Data"))
--[[]]
--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[[]]
--
local RunService = game:GetService("RunService")
local PlayersService = game:GetService("Players")
local OldSessions = {}
local LastRefresh = {}
PlayersService.PlayerAdded:Connect(function(Player)
	local CurrentSession = Instance.new("IntValue")
	CurrentSession.Name = "CurrentSession"
	CurrentSession.Parent = Player
	local ClaimedGifts = Instance.new("Folder")
	ClaimedGifts.Name = "ClaimedGifts"
	ClaimedGifts.Parent = Player
	local Data = DataModule["Get"](Player, GiftsData)
	if typeof(Data) ~= "nil" then
		OldSessions[Player.Name] = Data["TotalSession"]
		if typeof(Data["ClaimedGifts"]) ~= "nil" then
			for i, v in pairs(Data["ClaimedGifts"]) do
				local n = Instance.new("ObjectValue")
				n.Name = v
				n.Parent = ClaimedGifts
			end
		end
		if typeof(Data["LastRefresh"]) ~= "nil" then
			local TimeDifference = (os.time() - Data["LastRefresh"][2])
			if TimeDifference >= Settings.RefreshDelay then
				ClaimedGifts:ClearAllChildren()
				OldSessions[Player.Name] = 0
				table.insert(LastRefresh, { Player.Name, os.time() })
			else
				table.insert(LastRefresh, Data["LastRefresh"])
			end
		else
			table.insert(LastRefresh, { Player.Name, os.time() })
		end
	else
		OldSessions[Player.Name] = 0
		table.insert(LastRefresh, { Player.Name, os.time() })
	end
	local LoadedGifts = Instance.new("ObjectValue")
	LoadedGifts.Name = "LoadedGifts"
	LoadedGifts.Parent = Player
end)
PlayersService.PlayerRemoving:Connect(function(Player)
	local PlayerName = Player.Name
	if not Player:FindFirstChild("LoadedGifts") then
		return
	end
	local LastRefreshSession
	for i, v in pairs(LastRefresh) do
		if v[1] == PlayerName then
			LastRefreshSession = v
			break
		end
	end
	DataModule["Save"](Player, GiftsData, OldSessions[PlayerName], LastRefreshSession)
	for i, v in pairs(OldSessions) do
		if v == PlayerName then
			table.remove(OldSessions, PlayerName)
			break
		end
	end
end)
game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(2)
	end
end)
--[[]]
--
local SharedGiftData = require(ReplicatedStorage:WaitForChild("GiftFolder"):WaitForChild("SharedGiftData"))
ReplicatedStorage.GiftFolder.GetData.OnServerInvoke = function(Player)
	return OldSessions[Player.Name]
end
ReplicatedStorage.GiftFolder.ClaimGift.OnServerInvoke = function(Player, GiftNumber)
	if not tonumber(GiftNumber) then
		return
	end
	if Player.ClaimedGifts:FindFirstChild(GiftNumber) then
		return
	end
	if GiftNumber > #SharedGiftData then
		return
	end
	local Array = nil
	for i, v in pairs(SharedGiftData) do
		if v.GiftNumber == GiftNumber then
			Array = v
			break
		end
	end
	if typeof(Array) == "nil" then
		return
	end
	local Requirement = Array.Time
	local Current = (Player.CurrentSession.Value + OldSessions[Player.Name])
	if Current >= Requirement then
		local function RewardPlayer()
			local Object = nil
			for i, v in pairs(Player:GetDescendants()) do
				if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name == Array.Reward.Currency then
					Object = v
					break
				end
			end
			if typeof(Object) ~= "nil" then
				local n = Instance.new("ObjectValue")
				n.Name = GiftNumber
				n.Parent = Player.ClaimedGifts
				Object.Value += Array.Reward.Amount
				return true
			else
				warn("Gift System: Unable to Find Reward Value")
			end
		end
		return RewardPlayer()
	end
end
require(script:WaitForChild("Session"))()
