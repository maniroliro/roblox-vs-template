local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local SharedModules = ReplicatedStorage.Modules.Shared

local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
local RemotesManager = require(SharedModules.Managers.RemotesManager)

local DiamondSlapService = {}

local UNLOCK_TIME = 24 * 60 * 60 -- 24 hours in seconds
local ITEM_NAME = "SlapStickDiamond"

local handle = workspace:WaitForChild("Handle")
local itemsFolder = ServerStorage:WaitForChild("Items")

local touchDebounce = {}

local function getTimeRemaining(player: Player): number
	local data = PlayerDataManager.GetData(player)
	if not data or not data.FirstJoinTime then
		return UNLOCK_TIME
	end

	local elapsed = os.time() - data.FirstJoinTime
	local remaining = UNLOCK_TIME - elapsed

	return math.max(0, remaining)
end

local function isUnlocked(player: Player): boolean
	return getTimeRemaining(player) <= 0
end

local function hasCollected(player: Player): boolean
	local data = PlayerDataManager.GetData(player)
	return data and data.CollectedDiamondSlap == true
end

local function giveItem(player: Player)
	local itemTool = itemsFolder:FindFirstChild(ITEM_NAME)
	if not itemTool then
		warn("[DiamondSlapService] Item not found:", ITEM_NAME)
		return false
	end

	-- Check if already has the item in StarterGear
	local starterGear = player:FindFirstChild("StarterGear")
	if starterGear and not starterGear:FindFirstChild(ITEM_NAME) then
		local starterClone = itemTool:Clone()
		starterClone.Parent = starterGear
	end

	-- Check if already has the item in Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack and not backpack:FindFirstChild(ITEM_NAME) then
		local toolClone = itemTool:Clone()
		toolClone.Parent = backpack
	end

	return true
end

local function onHandleTouched(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end

	if touchDebounce[player] then
		return
	end
	touchDebounce[player] = true

	if not isUnlocked(player) then
		touchDebounce[player] = nil
		return
	end

	if hasCollected(player) then
		touchDebounce[player] = nil
		return
	end

	PlayerDataManager.Set(player, "CollectedDiamondSlap", true)
	giveItem(player)

	task.delay(1, function()
		touchDebounce[player] = nil
	end)
end

local function sendCountdownToPlayer(player: Player)
	local timeRemaining = getTimeRemaining(player)
	RemotesManager.FireClient(player, "DiamondSlapCountdown", timeRemaining)
end

local function startUnlockCheckLoop()
	task.spawn(function()
		while true do
			task.wait(60)

			for _, player in Players:GetPlayers() do
				local data = PlayerDataManager.GetData(player)
				if not data then
					continue
				end

				if data.CollectedDiamondSlap then
					continue
				end

				local timeRemaining = getTimeRemaining(player)
				if timeRemaining <= 0 then
					RemotesManager.FireClient(player, "DiamondSlapUnlocked")
				end
			end
		end
	end)
end

local function onPlayerAdded(player: Player)
	task.spawn(function()
		local data = nil
		while not data do
			data = PlayerDataManager.GetData(player)
			if not data then
				task.wait(0.1)
			end
		end

		if data.FirstJoinTime == 0 then
			PlayerDataManager.Set(player, "FirstJoinTime", os.time())
		end

		if data.CollectedDiamondSlap then
			giveItem(player)
			RemotesManager.FireClient(player, "DiamondSlapCollected")
			return
		end

		task.wait(1)
		sendCountdownToPlayer(player)
	end)
end

function DiamondSlapService.Init() end

function DiamondSlapService.Start()
	handle.Touched:Connect(onHandleTouched)

	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	startUnlockCheckLoop()
end

return DiamondSlapService
