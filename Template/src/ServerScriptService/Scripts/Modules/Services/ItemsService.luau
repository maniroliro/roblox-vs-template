local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local GamePassesData = require(ReplicatedStorage.Modules.Shared.Data.GamePassesData)
local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
local RemotesManager = require(ReplicatedStorage.Modules.Shared.Managers.RemotesManager)

local ItemsService = {}

local itemsFolder = ServerStorage:WaitForChild("Items")

local function giveItemToPlayer(player: Player, itemKey: string)
	local itemTool = itemsFolder:FindFirstChild(itemKey)
	if not itemTool then
		warn("[ItemsService] Item not found:", itemKey)
		return false
	end

	local existingTool = player.Backpack:FindFirstChild(itemKey)
	if existingTool then
		return true
	end

	local character = player.Character
	if character then
		local equippedTool = character:FindFirstChild(itemKey)
		if equippedTool then
			return true
		end
	end

	local toolClone = itemTool:Clone()
	toolClone.Parent = player.Backpack

	return true
end

local function checkAndGiveOwnedItems(player: Player)
	for itemKey, gamePassId in GamePassesData do
		local success, ownsGamePass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
		end)

		if success and ownsGamePass then
			giveItemToPlayer(player, itemKey)
		end
	end
end

local function getGamePassPrice(gamePassId: number): number
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(gamePassId, Enum.InfoType.GamePass)
	end)

	if success and info and info.PriceInRobux then
		return info.PriceInRobux
	end

	return 0
end

local function onGamePassPurchased(player: Player, gamePassId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end

	local price = getGamePassPrice(gamePassId)
	if price > 0 then
		PlayerDataManager.Increase(player, "RobuxSpent", price)
	end

	local robuxPurchaseRemote = RemotesManager:GetRemote("RobuxPurchaseCompleted")
	if robuxPurchaseRemote then
		robuxPurchaseRemote:FireClient(player)
	end

	for itemKey, passId in GamePassesData do
		if passId == gamePassId then
			giveItemToPlayer(player, itemKey)
			break
		end
	end
end

local function onPlayerAdded(player: Player)
	checkAndGiveOwnedItems(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		checkAndGiveOwnedItems(player)
	end)
end

local function setupGamepassPads()
	local gamepassPads = workspace:FindFirstChild("Map")
		and workspace.Map:FindFirstChild("Lobby")
		and workspace.Map.Lobby:FindFirstChild("GamepassPads")

	if not gamepassPads then
		return
	end

	local touchDebounce = {}

	for _, padModel in gamepassPads:GetChildren() do
		local gamePassId = GamePassesData[padModel.Name]
		if not gamePassId then
			continue
		end

		local priceLabel = padModel:FindFirstChild("Price", true)
		if priceLabel and priceLabel:IsA("TextLabel") then
			local price = getGamePassPrice(gamePassId)
			if price > 0 then
				priceLabel.Text = tostring(price)
			end
		end

		local touchPart = padModel:FindFirstChild("TouchPart", true)
		if not touchPart then
			continue
		end

		touchPart.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end

			if touchDebounce[player] then
				return
			end

			touchDebounce[player] = true

			local success, ownsGamePass = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
			end)

			if success and not ownsGamePass then
				MarketplaceService:PromptGamePassPurchase(player, gamePassId)
			end

			task.delay(1, function()
				touchDebounce[player] = nil
			end)
		end)
	end
end

function ItemsService.Init() end

function ItemsService.Start()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamePassPurchased)

	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	setupGamepassPads()
end

function ItemsService.GiveItem(player: Player, itemKey: string): boolean
	return giveItemToPlayer(player, itemKey)
end

return ItemsService
