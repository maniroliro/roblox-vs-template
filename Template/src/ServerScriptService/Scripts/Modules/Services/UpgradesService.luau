local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Modules = ServerScriptService.Scripts.Modules
local SharedModules = ReplicatedStorage.Modules.Shared

local RemotesManager = require(SharedModules.Managers.RemotesManager)
local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
local PlayerStatsManager = require(SharedModules.Managers.PlayerStatsManager)
local UpgradesData = require(SharedModules.Data.UpgradesData)

local UpgradesService = {}

local buyUpgradeRemote = nil

local STAT_MAPPING = {
	CashMultiplier = "CashMultiplier",
	SpeedMultiplier = "WalkSpeed",
	JumpMultiplier = "JumpPower",
}

local function applyUpgradeMultiplier(player: Player, upgradeType: string)
	local level = PlayerDataManager.GetNested(player, "UpgradesLevel", upgradeType) or 1
	if level < 1 then
		level = 1
	end
	local multiplier = UpgradesData.GetMultiplier(upgradeType, level)

	local statName = STAT_MAPPING[upgradeType]
	if not statName then
		return
	end

	local sourceKey = "Upgrade_" .. upgradeType
	PlayerStatsManager.RemoveMultiplier(player, statName, sourceKey)

	if multiplier > 1 then
		PlayerStatsManager.AddMultiplier(player, statName, sourceKey, multiplier)
	end
end

local function applyRobuxMultipliers(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data or not data.RobuxMultipliers then
		return
	end
	
	PlayerStatsManager.ApplyRobuxMultipliers(player, data.RobuxMultipliers)
end

local function applyAllUpgrades(player: Player)
	for upgradeType, _ in STAT_MAPPING do
		applyUpgradeMultiplier(player, upgradeType)
	end
	applyRobuxMultipliers(player)
end

local function onBuyUpgrade(player: Player, upgradeType: string)
	if typeof(upgradeType) ~= "string" then
		return false
	end

	if not UpgradesData[upgradeType] then
		return false
	end

	local currentLevel = PlayerDataManager.GetNested(player, "UpgradesLevel", upgradeType) or 1
	if currentLevel < 1 then
		currentLevel = 1
	end
	local maxLevel = UpgradesData.GetMaxLevel(upgradeType)

	if currentLevel >= maxLevel then
		return false
	end

	local nextLevelData = UpgradesData.GetNextLevelData(upgradeType, currentLevel)
	if not nextLevelData then
		return false
	end

	local playerCash = PlayerDataManager.Get(player, "Cash") or 0
	if playerCash < nextLevelData.Price then
		return false
	end

	PlayerDataManager.Decrease(player, "Cash", nextLevelData.Price)
	PlayerDataManager.SetNested(player, "UpgradesLevel", upgradeType, currentLevel + 1)

	applyUpgradeMultiplier(player, upgradeType)

	return true
end

local function waitForPlayerData(player: Player)
	local maxWait = 10
	local waited = 0
	while waited < maxWait do
		local data = PlayerDataManager.GetData(player)
		if data then
			return true
		end
		task.wait(0.1)
		waited += 0.1
	end
	return false
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		if PlayerDataManager.GetData(player) then
			applyAllUpgrades(player)
		end
	end)

	if waitForPlayerData(player) then
		if player.Character then
			applyAllUpgrades(player)
		end
	end
end

function UpgradesService.Init()
	buyUpgradeRemote = RemotesManager:GetRemote("BuyUpgrade")
end

function UpgradesService.Start()
	buyUpgradeRemote.OnServerInvoke = onBuyUpgrade

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
end

return UpgradesService
