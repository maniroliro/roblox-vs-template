local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local MorphManager = require(Modules.Managers.MorphManager)

local GroupMorphService = {}

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════

local GROUP_ID = 366681433 -- Change this to your group ID
local MORPH_NAME = "Group67Morph"
local PROXIMITY_PROMPT = game.Workspace.Map.Lobby.Group67Morph.Handle.ProximityPrompt

-- ═══════════════════════════════════════════════════════════

local function isPlayerInGroup(player: Player): boolean
	local success, isInGroup = pcall(function()
		return player:IsInGroup(GROUP_ID)
	end)

	return success and isInGroup
end

local function onPromptTriggered(player: Player)
	if not isPlayerInGroup(player) then
		return
	end

	MorphManager.ApplyMorph(player, MORPH_NAME)
end

function GroupMorphService.Init() end

function GroupMorphService.Start()
	if PROXIMITY_PROMPT then
		PROXIMITY_PROMPT.Triggered:Connect(onPromptTriggered)
	else
		warn("[GroupMorphService] PROXIMITY_PROMPT not set! Please configure the reference.")
	end
end

return GroupMorphService
