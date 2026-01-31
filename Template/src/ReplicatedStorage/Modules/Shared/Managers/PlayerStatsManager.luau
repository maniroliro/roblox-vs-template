local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerStatsManager = {}

local playerMultipliers = {}

local BASE_STATS = {
	JumpPower = 50,
	WalkSpeed = 16,
	CashMultiplier = 1,
}

local function getPlayerEntry(player: Player)
	if not playerMultipliers[player] then
		playerMultipliers[player] = {
			Sources = {
				JumpPower = {},
				WalkSpeed = {},
				CashMultiplier = {},
			},
		}
	end
	return playerMultipliers[player]
end

local function calculateTotalMultiplier(sources: { [string]: number }): number
	local total = 1
	for _, multiplier in sources do
		total = total * multiplier
	end
	return total
end

local function applyStatsToCharacter(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local entry = getPlayerEntry(player)

	local jumpMultiplier = calculateTotalMultiplier(entry.Sources.JumpPower)
	local speedMultiplier = calculateTotalMultiplier(entry.Sources.WalkSpeed)

	local newJumpPower = BASE_STATS.JumpPower * jumpMultiplier
	local newWalkSpeed = BASE_STATS.WalkSpeed * speedMultiplier

	humanoid.UseJumpPower = true
	humanoid.JumpPower = newJumpPower
	humanoid.WalkSpeed = newWalkSpeed

	print(
		"[PlayerStatsManager] Applied stats to",
		player.Name,
		"- JumpPower:",
		newJumpPower,
		"WalkSpeed:",
		newWalkSpeed
	)
end

function PlayerStatsManager.AddMultiplier(player: Player, statType: string, sourceId: string, multiplier: number)
	local entry = getPlayerEntry(player)

	if not entry.Sources[statType] then
		warn("[PlayerStatsManager] Unknown stat type:", statType)
		return
	end

	entry.Sources[statType][sourceId] = multiplier
	applyStatsToCharacter(player)
end

function PlayerStatsManager.RemoveMultiplier(player: Player, statType: string, sourceId: string)
	local entry = getPlayerEntry(player)

	if not entry.Sources[statType] then
		return
	end

	entry.Sources[statType][sourceId] = nil
	applyStatsToCharacter(player)
end

function PlayerStatsManager.GetCashMultiplier(player: Player): number
	local entry = getPlayerEntry(player)
	return calculateTotalMultiplier(entry.Sources.CashMultiplier)
end

function PlayerStatsManager.ApplyStats(player: Player)
	applyStatsToCharacter(player)
end

function PlayerStatsManager.ApplyRobuxMultipliers(player: Player, robuxMultipliers: { Jump: number, Speed: number })
	if not robuxMultipliers then
		return
	end
	
	if robuxMultipliers.Jump and robuxMultipliers.Jump > 1 then
		PlayerStatsManager.AddMultiplier(player, "JumpPower", "RobuxMultiplier", robuxMultipliers.Jump)
	end
	
	if robuxMultipliers.Speed and robuxMultipliers.Speed > 1 then
		PlayerStatsManager.AddMultiplier(player, "WalkSpeed", "RobuxMultiplier", robuxMultipliers.Speed)
	end
end

function PlayerStatsManager.ClearPlayer(player: Player)
	playerMultipliers[player] = nil
end

function PlayerStatsManager.RefreshCharacter(player: Player)
	applyStatsToCharacter(player)
end

function PlayerStatsManager.Init()
	if RunService:IsServer() then
		Players.PlayerRemoving:Connect(function(player)
			PlayerStatsManager.ClearPlayer(player)
		end)
	end
end

function PlayerStatsManager.Start() end

return PlayerStatsManager
