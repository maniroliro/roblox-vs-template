local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local PlayerDataManager = require(Modules.Managers.PlayerDataManager)

local LeaderboardService = {}

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════

local REFRESH_RATE = 60
local TOP_PLAYERS_COUNT = 100
local UPDATE_PLAYER_INTERVAL = 30

local studioSuffix = RunService:IsStudio() and "_Studio" or ""

local DATASTORE_NAMES = {
	Wins = "Leaderboard_Wins" .. studioSuffix,
	TimePlayed = "Leaderboard_TimePlayed" .. studioSuffix,
	RobuxSpent = "Leaderboard_RobuxSpent" .. studioSuffix,
}

-- ═══════════════════════════════════════════════════════════
-- UI REFERENCES - CONFIGURE THESE!
-- ═══════════════════════════════════════════════════════════

local libs = workspace.Map.Lobby.Lbs

local LEADERBOARD_WINS = libs.Wins.GUI.SurfaceGui.Frame.ScrollingFrame -- workspace.Maps.Lobby.TOP_WIN.Visual.SurfaceGui.Frame.ScrollingFrame
local LEADERBOARD_TIME = libs.Time.GUI.SurfaceGui.Frame.ScrollingFrame -- workspace.Maps.Lobby.TOP_TIME.Visual.SurfaceGui.Frame.ScrollingFrame
local LEADERBOARD_ROBUX = libs.Spenders.GUI.SurfaceGui.Frame.ScrollingFrame -- workspace.Maps.Lobby.TOP_ROBUX.Visual.SurfaceGui.Frame.ScrollingFrame

local LEADERBOARD_TEMPLATE = ReplicatedStorage.Assets.UI.Leaderboard.InfoTemplate -- ReplicatedStorage.Assets.UITemplates.Leaderboard.InfoTemplate

-- ═══════════════════════════════════════════════════════════

local LeaderboardStores = {}

LeaderboardService.Rankings = {
	Wins = {},
	TimePlayed = {},
	RobuxSpent = {},
}

-- ═══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function formatNumber(num: number): string
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(num)
	end
end

local function formatTime(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	else
		return string.format("%dm", minutes)
	end
end

local function getRankColor(rank: number): Color3
	if rank == 1 then
		return Color3.fromRGB(255, 213, 0)
	elseif rank == 2 then
		return Color3.fromRGB(192, 192, 192)
	elseif rank == 3 then
		return Color3.fromRGB(205, 127, 50)
	else
		return Color3.fromRGB(216, 216, 216)
	end
end

-- ═══════════════════════════════════════════════════════════
-- UPDATE FUNCTIONS
-- ═══════════════════════════════════════════════════════════

function LeaderboardService.UpdatePlayerScore(leaderboardName: string, userId: number, value: number)
	local store = LeaderboardStores[leaderboardName]
	if not store then
		return
	end

	local success, err = pcall(function()
		store:SetAsync(tostring(userId), value)
	end)

	if not success then
		warn("[LeaderboardService] Error updating", leaderboardName, "for userId", userId, ":", err)
	end
end

function LeaderboardService.UpdateAllScores(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	local userId = player.UserId

	if data.Wins then
		LeaderboardService.UpdatePlayerScore("Wins", userId, data.Wins)
	end

	if data.Playtime and data.Playtime.TotalSeconds then
		LeaderboardService.UpdatePlayerScore("TimePlayed", userId, data.Playtime.TotalSeconds)
	end

	if data.RobuxSpent then
		LeaderboardService.UpdatePlayerScore("RobuxSpent", userId, data.RobuxSpent)
	end
end

-- ═══════════════════════════════════════════════════════════
-- DISPLAY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

function LeaderboardService.RefreshLeaderboardDisplay(leaderboardName: string, scrollingFrame: ScrollingFrame?)
	local store = LeaderboardStores[leaderboardName]
	if not store then
		return
	end

	if not scrollingFrame then
		return
	end

	if not LEADERBOARD_TEMPLATE then
		return
	end

	local success, err = pcall(function()
		local data = store:GetSortedAsync(false, TOP_PLAYERS_COUNT)
		local page = data:GetCurrentPage()

		for _, child in scrollingFrame:GetChildren() do
			if child:IsA("Frame") and child.Name ~= "Template" then
				child:Destroy()
			end
		end

		local rankCache = {}

		for rank, savedData in ipairs(page) do
			local userId = tonumber(savedData.key)
			local value = savedData.value

			if userId and value and value > 0 then
				rankCache[userId] = rank

				local successName, username = pcall(function()
					return Players:GetNameFromUserIdAsync(userId)
				end)
				if not successName or not username then
					username = "Unknown"
				end

				local entry = LEADERBOARD_TEMPLATE:Clone()
				entry.Name = "Entry_" .. rank
				entry.Visible = true

				local avatarImage = entry:FindFirstChild("Image")
				if avatarImage then
					local successAvatar, avatarContent = pcall(function()
						return Players:GetUserThumbnailAsync(
							userId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size100x100
						)
					end)
					if successAvatar and avatarContent then
						avatarImage.Image = avatarContent
					end
				end

				local rankLabel = entry:FindFirstChild("RankLabel")
				if rankLabel then
					rankLabel.Text = "#" .. rank
				end

				local nameLabel = entry:FindFirstChild("NameLabel")
				if nameLabel then
					nameLabel.Text = username
				end

				local valueLabel = entry:FindFirstChild("NumberLabel") or entry:FindFirstChild("ValueLabel")
				if valueLabel then
					if leaderboardName == "TimePlayed" then
						valueLabel.Text = formatTime(value)
					else
						valueLabel.Text = formatNumber(value)
					end
				end

				entry.BackgroundColor3 = getRankColor(rank)
				entry.Parent = scrollingFrame
			end
		end

		LeaderboardService.Rankings[leaderboardName] = rankCache
	end)

	if not success then
		warn("[LeaderboardService] Error updating display of", leaderboardName, ":", err)
	end
end

function LeaderboardService.RefreshAllDisplays()
	LeaderboardService.RefreshLeaderboardDisplay("Wins", LEADERBOARD_WINS)
	LeaderboardService.RefreshLeaderboardDisplay("TimePlayed", LEADERBOARD_TIME)
	LeaderboardService.RefreshLeaderboardDisplay("RobuxSpent", LEADERBOARD_ROBUX)
end

-- ═══════════════════════════════════════════════════════════
-- RANKING FUNCTIONS
-- ═══════════════════════════════════════════════════════════

function LeaderboardService.GetPlayerRank(leaderboardName: string, userId: number): number?
	return LeaderboardService.Rankings[leaderboardName][userId]
end

function LeaderboardService.GetAllPlayerRanks(userId: number)
	return {
		Wins = LeaderboardService.Rankings.Wins[userId],
		TimePlayed = LeaderboardService.Rankings.TimePlayed[userId],
		RobuxSpent = LeaderboardService.Rankings.RobuxSpent[userId],
	}
end

-- ═══════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════

local function startDisplayLoop()
	task.spawn(function()
		while true do
			LeaderboardService.RefreshAllDisplays()
			task.wait(REFRESH_RATE)
		end
	end)
end

local function startPlayerUpdateLoop()
	task.spawn(function()
		while true do
			task.wait(UPDATE_PLAYER_INTERVAL)
			for _, player in Players:GetPlayers() do
				LeaderboardService.UpdateAllScores(player)
			end
		end
	end)
end

function LeaderboardService.Init()
	LeaderboardStores.Wins = DataStoreService:GetOrderedDataStore(DATASTORE_NAMES.Wins)
	LeaderboardStores.TimePlayed = DataStoreService:GetOrderedDataStore(DATASTORE_NAMES.TimePlayed)
	LeaderboardStores.RobuxSpent = DataStoreService:GetOrderedDataStore(DATASTORE_NAMES.RobuxSpent)

	print("[LeaderboardService] DataStores initialized")
end

function LeaderboardService.Start()
	startDisplayLoop()
	startPlayerUpdateLoop()

	Players.PlayerRemoving:Connect(function(player)
		LeaderboardService.UpdateAllScores(player)
	end)

	print("[LeaderboardService] Started")
end

return LeaderboardService
