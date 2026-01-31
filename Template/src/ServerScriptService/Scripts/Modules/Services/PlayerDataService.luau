--[[
	PlayerDataService
	
	Responsible for:
	- Managing player session lifecycle (profile loading/unloading)
	- Orchestrating PlayerDataManager for data operations
	
	Does NOT:
	- Directly manipulate player data (uses PlayerDataManager)
	- Store data itself
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local ProfileStore = require(Modules.Packages.profilestore)
local PlayerDataTemplate = require(Modules.Data.PlayerDataTemplate)
local PlayerDataManager = require(Modules.Managers.PlayerDataManager)

local PlayerDataService = {}

local playerDataStore =
	ProfileStore.New("PlayerData" .. (RunService:IsStudio() and "_Studio" or ""), PlayerDataTemplate)

-- Private functions
local function onPlayerAdded(player: Player)
	local profile = playerDataStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		player:Kick("Failed to load data. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		PlayerDataManager.ClearCache(player)
		player:Kick("Session ended. Please rejoin.")
	end)

	if player.Parent == Players then
		PlayerDataManager.SetProfile(player, profile)
		PlayerDataManager.UpdateClient(player)
	else
		profile:EndSession()
	end
end

local function onPlayerRemoving(player: Player)
	local profile = PlayerDataManager.GetProfile(player)
	if not profile then
		return
	end

	profile:EndSession()
	PlayerDataManager.ClearCache(player)
end

-- Public API
function PlayerDataService.Init()
	-- Nothing to initialize
end

function PlayerDataService.Start()
	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle players that joined before this script ran
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return PlayerDataService
