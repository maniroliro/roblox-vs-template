local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RemotesManager = require(ReplicatedStorage.Modules.Shared.Managers.RemotesManager)

local MorphManager = {}

local morphsFolder = nil
local activeMorphs = {} -- [Player] = morphName
local updateCameraRemote = nil

function MorphManager.ApplyMorph(player: Player, morphName: string): boolean
	if not morphsFolder then
		return false
	end

	local morphModel = morphsFolder:FindFirstChild(morphName)
	if not morphModel then
		return false
	end

	local oldCharacter = player.Character
	if not oldCharacter then
		return false
	end

	local oldRootPart = oldCharacter:FindFirstChild("HumanoidRootPart")
	if not oldRootPart then
		return false
	end

	local oldPosition = oldRootPart.CFrame

	local savedTools = {}
	local equippedToolName = nil

	for _, child in oldCharacter:GetChildren() do
		if child:IsA("Tool") then
			equippedToolName = child.Name
			table.insert(savedTools, child)
			child.Parent = nil
		end
	end

	for _, tool in player.Backpack:GetChildren() do
		if tool:IsA("Tool") then
			table.insert(savedTools, tool)
			tool.Parent = nil
		end
	end

	local newCharacter = morphModel:Clone()

	local newRootPart = newCharacter:FindFirstChild("HumanoidRootPart")
	if not newRootPart then
		newCharacter:Destroy()
		for _, tool in savedTools do
			tool.Parent = player.Backpack
		end
		return false
	end

	local newHumanoid = newCharacter:FindFirstChildOfClass("Humanoid")
	if not newHumanoid then
		newCharacter:Destroy()
		for _, tool in savedTools do
			tool.Parent = player.Backpack
		end
		return false
	end

	newCharacter.Name = player.Name
	newCharacter:PivotTo(oldPosition)
	newCharacter.Parent = workspace

	player.Character = newCharacter

	oldCharacter:Destroy()

	for _, tool in savedTools do
		tool.Parent = player.Backpack
	end

	if equippedToolName then
		task.defer(function()
			local humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
			local toolToEquip = player.Backpack:FindFirstChild(equippedToolName)
			if humanoid and toolToEquip then
				humanoid:EquipTool(toolToEquip)
			end
		end)
	end

	activeMorphs[player] = morphName

	if updateCameraRemote then
		updateCameraRemote:FireClient(player)
	end

	return true
end

function MorphManager.RemoveMorph(player: Player)
	activeMorphs[player] = nil
end

function MorphManager.GetActiveMorph(player: Player): string?
	return activeMorphs[player]
end

function MorphManager.HasMorph(player: Player): boolean
	return activeMorphs[player] ~= nil
end

function MorphManager.ReapplyMorph(player: Player)
	local morphName = activeMorphs[player]
	if morphName then
		task.wait(0.1)
		MorphManager.ApplyMorph(player, morphName)
	end
end

local function onPlayerRemoving(player: Player)
	activeMorphs[player] = nil
end

function MorphManager.Init()
	morphsFolder = ServerStorage:WaitForChild("67s")
end

function MorphManager.Start()
	updateCameraRemote = RemotesManager:GetRemote("UpdateCamera")
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return MorphManager
