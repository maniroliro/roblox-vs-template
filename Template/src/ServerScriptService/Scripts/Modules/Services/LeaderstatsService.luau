local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local PlayerDataManager = require(Modules.Managers.PlayerDataManager)

local LeaderstatsService = {}

local function createLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats

	return leaderstats
end

local function updateLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	local wins = leaderstats:FindFirstChild("Wins")
	if wins then
		wins.Value = data.Wins or 0
	end
end

local function waitForPlayerData(player: Player): boolean
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
	createLeaderstats(player)
	
	task.spawn(function()
		if waitForPlayerData(player) then
			updateLeaderstats(player)
		end
	end)
end

function LeaderstatsService.UpdatePlayer(player: Player)
	updateLeaderstats(player)
end

function LeaderstatsService.AddWin(player: Player, amount: number?)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end
	
	local addAmount = amount or 1
	data.Wins = (data.Wins or 0) + addAmount
	updateLeaderstats(player)
end

function LeaderstatsService.Init() end

function LeaderstatsService.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	
	Players.PlayerAdded:Connect(onPlayerAdded)
end

return LeaderstatsService
