--[[
	LeaderboardService.luau
	Manages game leaderboards (Wins, Coins, TimePlayed)
	Uses OrderedDataStore for ranking
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Settings = require(Modules.Settings.Settings)

local LeaderboardService = {}

-- ═══════════════════════════════════════════════════════════
-- UI REFERENCES - FILL THESE VARIABLES!
-- ═══════════════════════════════════════════════════════════
-- Place here the references to the leaderboard ScrollingFrames
-- Cloned templates will be parented directly to these ScrollingFrames

local topParts = workspace.Level_Art.Maps.Lobby.TOP

local LEADERBOARD_SCROLLFRAMES = {
	-- Wins leaderboard ScrollingFrame
	Wins = topParts["TOP WIN"].Visual.SurfaceGui.Frame.ScrollingFrame,

	-- Coins leaderboard ScrollingFrame
	Coins = topParts["TOP MONEY"].Visual.SurfaceGui.Frame.ScrollingFrame,

	-- Time Played leaderboard ScrollingFrame
	TimePlayed = topParts["TOP TIME"].Visual.SurfaceGui.Frame.ScrollingFrame,
}

-- Template for each leaderboard entry (must be in ReplicatedStorage)
local LEADERBOARD_TEMPLATE = ReplicatedStorage.Assets.UITemplates.Leaderboard.InfoTemplate

-- ═══════════════════════════════════════════════════════════

-- DataStores
local LeaderboardStores = {}

-- Rankings cache (for tags/badges)
LeaderboardService.Rankings = {
	Wins = {}, -- [UserId] = rank
	Coins = {},
	TimePlayed = {},
}

-- ═══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════

--[[
	Formats large number (1000 -> 1K, 1000000 -> 1M)
]]
local function FormatNumber(num: number): string
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(num)
	end
end

--[[
	Formats time in hours/minutes
]]
local function FormatTime(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	else
		return string.format("%dm", minutes)
	end
end

--[[
	Returns color based on rank
]]
local function GetRankColor(rank: number): Color3
	if rank == 1 then
		return Color3.fromRGB(255, 213, 0) -- Gold
	elseif rank == 2 then
		return Color3.fromRGB(192, 192, 192) -- Silver
	elseif rank == 3 then
		return Color3.fromRGB(205, 127, 50) -- Bronze
	else
		return Color3.fromRGB(216, 216, 216) -- Default
	end
end

-- ═══════════════════════════════════════════════════════════
-- UPDATE FUNCTIONS
-- ═══════════════════════════════════════════════════════════

--[[
	Updates a player's value in the leaderboard
]]
function LeaderboardService.UpdatePlayerScore(leaderboardName: string, userId: number, value: number)
	local store = LeaderboardStores[leaderboardName]
	if not store then
		warn("[LeaderboardService] DataStore not found:", leaderboardName)
		return
	end

	local success, err = pcall(function()
		store:SetAsync(tostring(userId), value)
	end)

	if not success then
		warn("[LeaderboardService] Error updating", leaderboardName, "for userId", userId, ":", err)
	end
end

--[[
	Updates all leaderboards for a player
]]
function LeaderboardService.UpdateAllScores(player: Player, data: any)
	if not data then
		return
	end

	local userId = player.UserId

	-- Updates Wins
	if data.Wins then
		LeaderboardService.UpdatePlayerScore("Wins", userId, data.Wins)
	end

	-- Updates Coins
	if data.Coins then
		LeaderboardService.UpdatePlayerScore("Coins", userId, data.Coins)
	end

	-- Updates TimePlayed
	if data.TimePlayed then
		LeaderboardService.UpdatePlayerScore("TimePlayed", userId, data.TimePlayed)
	end
end

-- ═══════════════════════════════════════════════════════════
-- DISPLAY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

--[[
	Updates the display of a specific leaderboard
]]
function LeaderboardService.RefreshLeaderboardDisplay(leaderboardName: string)
	local store = LeaderboardStores[leaderboardName]
	local scrollingFrame = LEADERBOARD_SCROLLFRAMES[leaderboardName]

	if not store then
		return
	end

	if not scrollingFrame then
		-- ScrollingFrame not configured, just updates cache
		return
	end

	if not LEADERBOARD_TEMPLATE then
		warn("[LeaderboardService] LEADERBOARD_TEMPLATE not configured!")
		return
	end

	local success, err = pcall(function()
		local topCount = Settings.Leaderboards.TopPlayersCount or 100
		local data = store:GetSortedAsync(false, topCount)
		local page = data:GetCurrentPage()

		-- Clears old entries (keeps UIListLayout and Template if they exist)
		for _, child in pairs(scrollingFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "Template" then
				child:Destroy()
			end
		end

		-- Rankings cache
		local rankCache = {}

		-- Creates entries
		for rank, savedData in ipairs(page) do
			local userId = tonumber(savedData.key)
			local value = savedData.value

			if userId and value and value > 0 then
				rankCache[userId] = rank

				-- Gets player name
				local successName, username = pcall(function()
					return Players:GetNameFromUserIdAsync(userId)
				end)
				if not successName or not username then
					username = "Unknown"
				end

				-- Clones template
				local entry = LEADERBOARD_TEMPLATE:Clone()
				entry.Name = "Entry_" .. rank
				entry.Visible = true

				-- Avatar
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

				-- Rank
				local rankLabel = entry:FindFirstChild("RankLabel")
				if rankLabel then
					rankLabel.Text = "#" .. rank
				end

				-- Nome
				local nameLabel = entry:FindFirstChild("NameLabel")
				if nameLabel then
					nameLabel.Text = username
				end

				-- Value (formatted differently for time)
				local valueLabel = entry:FindFirstChild("NumberLabel") or entry:FindFirstChild("ValueLabel")
				if valueLabel then
					if leaderboardName == "TimePlayed" then
						valueLabel.Text = FormatTime(value)
					else
						valueLabel.Text = FormatNumber(value)
					end
				end

				-- Background color
				entry.BackgroundColor3 = GetRankColor(rank)

				-- Parents to ScrollingFrame
				entry.Parent = scrollingFrame
			end
		end

		-- Updates rankings cache
		LeaderboardService.Rankings[leaderboardName] = rankCache
	end)

	if not success then
		warn("[LeaderboardService] Error updating display of", leaderboardName, ":", err)
	end
end

--[[
	Updates all leaderboard displays
]]
function LeaderboardService.RefreshAllDisplays()
	LeaderboardService.RefreshLeaderboardDisplay("Wins")
	LeaderboardService.RefreshLeaderboardDisplay("Coins")
	LeaderboardService.RefreshLeaderboardDisplay("TimePlayed")
end

-- ═══════════════════════════════════════════════════════════
-- RANKING FUNCTIONS
-- ═══════════════════════════════════════════════════════════

--[[
	Returns a player's rank in a specific leaderboard
]]
function LeaderboardService.GetPlayerRank(leaderboardName: string, userId: number): number?
	return LeaderboardService.Rankings[leaderboardName][userId]
end

--[[
	Returns all rankings of a player
]]
function LeaderboardService.GetAllPlayerRanks(userId: number): { Wins: number?, Coins: number?, TimePlayed: number? }
	return {
		Wins = LeaderboardService.Rankings.Wins[userId],
		Coins = LeaderboardService.Rankings.Coins[userId],
		TimePlayed = LeaderboardService.Rankings.TimePlayed[userId],
	}
end

-- ═══════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════

function LeaderboardService.Init()
	print("[LeaderboardService] Initializing...")

	-- Creates DataStores
	local storeNames = Settings.Leaderboards.DataStoreNames

	LeaderboardStores.Wins = DataStoreService:GetOrderedDataStore(storeNames.Wins)
	LeaderboardStores.Coins = DataStoreService:GetOrderedDataStore(storeNames.Coins)
	LeaderboardStores.TimePlayed = DataStoreService:GetOrderedDataStore(storeNames.TimePlayed)

	-- Checks if references were configured
	local configured = false
	for name, scrollFrame in pairs(LEADERBOARD_SCROLLFRAMES) do
		if scrollFrame then
			configured = true
			print("[LeaderboardService] Leaderboard configured:", name)
		end
	end

	if not configured then
		warn("[LeaderboardService] WARNING: No leaderboard configured!")
		warn("[LeaderboardService] Configure LEADERBOARD_SCROLLFRAMES at the top of LeaderboardService.luau")
	end

	if not LEADERBOARD_TEMPLATE then
		warn("[LeaderboardService] WARNING: LEADERBOARD_TEMPLATE not configured!")
		warn("[LeaderboardService] Configure the variable at the top of LeaderboardService.luau")
	end

	-- Display update loop
	task.spawn(function()
		while true do
			LeaderboardService.RefreshAllDisplays()
			task.wait(Settings.Leaderboards.RefreshRate or 60)
		end
	end)

	print("[LeaderboardService] Initialized!")
end

return LeaderboardService
