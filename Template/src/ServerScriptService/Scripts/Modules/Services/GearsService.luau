local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local SharedModules = ReplicatedStorage.Modules.Shared

local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
local RemotesManager = require(SharedModules.Managers.RemotesManager)
local PlayerStatsManager = require(SharedModules.Managers.PlayerStatsManager)
local GearsData = require(SharedModules.Data.GearsData)

local GearsService = {}

local gearsFolder = ServerStorage:WaitForChild("Gears")

local EFFECT_TO_STAT = {
	JumpPowerMultiplier = "JumpPower",
	SpeedPowerMultiplier = "WalkSpeed",
	CashMultiplier = "CashMultiplier",
}

local function applyGearEffects(player: Player, gearKey: string, effects: { [string]: number }, duration: number)
	local effectId = gearKey .. "_" .. os.time()

	print("[GearsService] Applying effects for", gearKey, "to", player.Name)
	print("[GearsService] Effects:", effects)

	for effectName, multiplier in effects do
		local statType = EFFECT_TO_STAT[effectName]
		if statType then
			print("[GearsService] Adding multiplier:", statType, "=", multiplier)
			PlayerStatsManager.AddMultiplier(player, statType, effectId .. "_" .. effectName, multiplier)
		else
			warn("[GearsService] Unknown effect:", effectName)
		end
	end

	RemotesManager.FireClient(player, "GearEffectStarted", gearKey, duration)

	task.delay(duration, function()
		if not player.Parent then
			return
		end

		for effectName, _ in effects do
			local statType = EFFECT_TO_STAT[effectName]
			if statType then
				PlayerStatsManager.RemoveMultiplier(player, statType, effectId .. "_" .. effectName)
			end
		end

		RemotesManager.FireClient(player, "GearEffectEnded", gearKey)
	end)
end

local function giveGearToPlayer(player: Player, gearKey: string)
	local gearData = GearsData[gearKey]
	if not gearData then
		return false
	end

	local gearTool = gearsFolder:FindFirstChild(gearKey)
	if not gearTool then
		warn("[GearsService] Gear tool not found:", gearKey)
		return false
	end

	local toolClone = gearTool:Clone()
	toolClone.Parent = player.Backpack

	local isActivated = false

	toolClone.Activated:Connect(function()
		if isActivated then
			return
		end
		isActivated = true

		local character = player.Character
		if not character then
			return
		end

		if gearData.ActivatedCallback then
			gearData.ActivatedCallback(toolClone, character)
		end

		toolClone:Destroy()

		if gearData.Effects and next(gearData.Effects) then
			applyGearEffects(player, gearKey, gearData.Effects, gearData.Duration)
		end
	end)

	return true
end

local function onBuyGearWithCash(player: Player, gearKey: string)
	local gearData = GearsData[gearKey]
	if not gearData then
		return false
	end

	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	local price = gearData.Price
	if (data.Cash or 0) < price then
		return false
	end

	PlayerDataManager.Decrease(player, "Cash", price)

	local success = giveGearToPlayer(player, gearKey)
	if not success then
		PlayerDataManager.Increase(player, "Cash", price)
		return false
	end

	return true
end

local function onGearPurchasedWithRobux(player: Player, gearKey: string)
	return giveGearToPlayer(player, gearKey)
end

function GearsService.Init() end

function GearsService.Start()
	local buyGearRemote = RemotesManager:GetRemote("BuyGearWithCash")
	buyGearRemote.OnServerInvoke = onBuyGearWithCash

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.1)
			PlayerStatsManager.RefreshCharacter(player)
		end)
	end)

	for _, player in Players:GetPlayers() do
		if player.Character then
			PlayerStatsManager.RefreshCharacter(player)
		end
		player.CharacterAdded:Connect(function()
			task.wait(0.1)
			PlayerStatsManager.RefreshCharacter(player)
		end)
	end
end

function GearsService.GiveGearFromRobux(player: Player, gearKey: string)
	return onGearPurchasedWithRobux(player, gearKey)
end

return GearsService
