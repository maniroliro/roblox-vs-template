local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
local MorphManager = require(Modules.Managers.MorphManager)
local MapsData = require(Modules.Data.MapsData)
local RemotesManager = require(ReplicatedStorage.Modules.Shared.Managers.RemotesManager)

local MapService = {}

local TOTAL_CHECKPOINTS = 50
local MAP_NAMES = { "67Blue", "67Red", "67Purple", "67Green" }
local MAP_FOLDER = workspace.Map
local LOBBY_SPAWN = MAP_FOLDER.Lobby.SpawnLocation

local MAP_COLORS = {
	["67Blue"] = Color3.fromRGB(38, 67, 98),
	["67Red"] = Color3.fromRGB(163, 75, 75),
	["67Purple"] = Color3.fromRGB(123, 47, 123),
	["67Green"] = Color3.fromRGB(65, 145, 51),
}

local VFX_FOLDER = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("VFX"):WaitForChild("Parts")
local CHECKPOINT_VFX = VFX_FOLDER:WaitForChild("Checkpoint")
local WIN_VFX = VFX_FOLDER:WaitForChild("Win")

local finishTouchDebounce = {}
local killPartsDebounce = {}

local function spawnCheckpointVFX(checkpointPart: BasePart, isWin: boolean, mapName: string?)
	local vfxTemplate = isWin and WIN_VFX or CHECKPOINT_VFX
	local vfxClone = vfxTemplate:Clone()

	vfxClone.CFrame = checkpointPart.CFrame
	vfxClone.Parent = checkpointPart

	local stageColor = mapName and MAP_COLORS[mapName] or nil

	for _, descendant in vfxClone:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			if stageColor then
				descendant.Color = ColorSequence.new(stageColor)
			end
			descendant:Emit(descendant:GetAttribute("EmitCount") or 20)
		end
	end

	task.delay(3, function()
		vfxClone:Destroy()
	end)
end

local function formatCheckpointName(index: number): string
	if index < 10 then
		return "0" .. tostring(index)
	end
	return tostring(index)
end

local function getCheckpointPart(mapName: string, checkpointIndex: number): Part?
	local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
	if not mapFolder then
		return nil
	end

	if checkpointIndex == 0 then
		return mapFolder:FindFirstChild("SpawnLocation")
	end

	local checkpoints = mapFolder:FindFirstChild("Checkpoints")
	if not checkpoints then
		return nil
	end

	return checkpoints:FindFirstChild(formatCheckpointName(checkpointIndex))
end

local function teleportToCheckpoint(player: Player, mapName: string, checkpointIndex: number)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		return
	end

	local checkpointPart = getCheckpointPart(mapName, checkpointIndex)
	if not checkpointPart then
		return
	end

	local hipHeight = humanoid.HipHeight
	local targetPosition = checkpointPart.Position + Vector3.new(0, hipHeight + 3, 0)
	rootPart.CFrame = CFrame.new(targetPosition)
end

local function teleportToLobby(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		return
	end

	local hipHeight = humanoid.HipHeight
	local targetPosition = LOBBY_SPAWN.Position + Vector3.new(0, hipHeight + 3, 0)
	rootPart.CFrame = CFrame.new(targetPosition)
end

local function giveCheckpointReward(player: Player, previousCheckpoint: number, newCheckpoint: number)
	local checkpointsGained = newCheckpoint - previousCheckpoint
	local cashReward = checkpointsGained * MapsData.CheckpointRewards
	PlayerDataManager.Increase(player, "Cash", cashReward)
end

local MAP_UNLOCK_ORDER = {
	["67Blue"] = "67Red",
	["67Red"] = "67Green",
	["67Green"] = "67Purple",
}

local function destroyUnlockWall(mapName: string)
	local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
	if not mapFolder then
		return
	end

	local color = mapName:gsub("67", "")
	local wall = mapFolder:FindFirstChild(color .. "UnlockWall")
	if wall then
		wall:Destroy()
	end
end

local function getFinishPart(mapName: string): BasePart?
	print("[MapService] getFinishPart called for:", mapName)

	local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
	if not mapFolder then
		print("[MapService] ERROR: mapFolder not found:", mapName)
		return nil
	end

	local toAnimate = mapFolder:FindFirstChild("ToAnimate")
	if not toAnimate then
		print("[MapService] ERROR: ToAnimate not found in", mapName)
		return nil
	end

	local color = mapName:gsub("67", "")
	local gigantFolderName = color .. "67Gigant"
	print("[MapService] Looking for:", gigantFolderName)

	local gigantFolder = toAnimate:FindFirstChild(gigantFolderName)
	if not gigantFolder then
		print("[MapService] ERROR: gigantFolder not found:", gigantFolderName)
		print("[MapService] ToAnimate children:", toAnimate:GetChildren())
		return nil
	end

	local finishPart = gigantFolder:FindFirstChild("Finish")
	if not finishPart then
		print("[MapService] ERROR: Finish part not found in", gigantFolderName)
		print("[MapService] gigantFolder children:", gigantFolder:GetChildren())
		return nil
	end

	print("[MapService] Found Finish part:", finishPart:GetFullName())
	return finishPart
end

local function showFinishPart(player: Player, mapName: string)
	print("[MapService] showFinishPart called for:", mapName)
	local finishPart = getFinishPart(mapName)
	if not finishPart then
		print("[MapService] ERROR: Could not show finish part - not found")
		return
	end

	print("[MapService] Firing ShowFinishPart remote to:", player.Name)
	RemotesManager.FireClient(player, "ShowFinishPart", mapName)
end

local function hideFinishPart(player: Player, mapName: string)
	local finishPart = getFinishPart(mapName)
	if not finishPart then
		return
	end

	print("[MapService] Firing HideFinishPart remote to:", player.Name)
	RemotesManager.FireClient(player, "HideFinishPart", mapName)
end

local function onFinishPartTouched(player: Player, mapName: string)
	print("[MapService] onFinishPartTouched called:", player.Name, mapName)

	local debounceKey = player.UserId .. "_" .. mapName
	if finishTouchDebounce[debounceKey] then
		print("[MapService] Debounced, ignoring")
		return
	end
	finishTouchDebounce[debounceKey] = true

	local data = PlayerDataManager.GetData(player)
	if not data then
		print("[MapService] ERROR: No player data")
		finishTouchDebounce[debounceKey] = nil
		return
	end

	local mapData = data.Map[mapName]
	if not mapData then
		print("[MapService] ERROR: No map data for", mapName)
		finishTouchDebounce[debounceKey] = nil
		return
	end

	print("[MapService] LastCheckpoint:", mapData.LastCheckpoint, "TOTAL_CHECKPOINTS:", TOTAL_CHECKPOINTS)
	if mapData.LastCheckpoint ~= TOTAL_CHECKPOINTS then
		print("[MapService] Player not at checkpoint 50, ignoring")
		finishTouchDebounce[debounceKey] = nil
		return
	end

	print("[MapService] Resetting player and teleporting to lobby")
	mapData.CheckpointReached = 0
	mapData.LastCheckpoint = 0
	data.CurrentCheckpoint = 0
	mapData.TimesCompleted = (mapData.TimesCompleted or 0) + 1

	PlayerDataManager.Increase(player, "Cash", 10000)

	hideFinishPart(player, mapName)
	PlayerDataManager.UpdateClient(player)
	teleportToLobby(player)
	print("[MapService] Player teleported to lobby")

	task.delay(1, function()
		finishTouchDebounce[debounceKey] = nil
	end)
end

local function onCheckpointTouched(player: Player, mapName: string, checkpointIndex: number)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	local mapData = data.Map[mapName]
	if not mapData then
		return
	end

	if checkpointIndex <= mapData.CheckpointReached then
		return
	end

	local checkpointPart = getCheckpointPart(mapName, checkpointIndex)
	if checkpointPart then
		local isWin = checkpointIndex >= TOTAL_CHECKPOINTS
		spawnCheckpointVFX(checkpointPart, isWin, mapName)
	end

	mapData.LastCheckpoint = checkpointIndex
	data.CurrentCheckpoint = checkpointIndex
	data.LastMapPlayed = mapName

	if checkpointIndex > (mapData.CheckpointReached or 0) then
		local previousReached = mapData.CheckpointReached or 0
		mapData.CheckpointReached = checkpointIndex
		giveCheckpointReward(player, previousReached, checkpointIndex)
	end

	if checkpointIndex >= TOTAL_CHECKPOINTS then
		mapData.Completed = true
		PlayerDataManager.Increase(player, "Wins", 1)

		local nextMap = MAP_UNLOCK_ORDER[mapName]
		if nextMap then
			destroyUnlockWall(nextMap)
		end

		showFinishPart(player, mapName)
	end

	PlayerDataManager.UpdateClient(player)
end

local function setupCheckpointConnections()
	for _, mapName in MAP_NAMES do
		local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
		if not mapFolder then
			continue
		end

		local checkpoints = mapFolder:FindFirstChild("Checkpoints")
		if not checkpoints then
			continue
		end

		for _, checkpoint in checkpoints:GetChildren() do
			if not checkpoint:IsA("BasePart") then
				continue
			end

			local checkpointIndex = tonumber(checkpoint.Name)
			if not checkpointIndex then
				continue
			end

			checkpoint.Touched:Connect(function(hit)
				local character = hit.Parent
				if not character then
					return
				end

				local player = Players:GetPlayerFromCharacter(character)
				if not player then
					return
				end

				onCheckpointTouched(player, mapName, checkpointIndex)
			end)
		end
	end
end

local function onMiscTouched(player: Player, mapName: string)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return
	end

	if data.LastMapPlayed == mapName then
		return
	end

	data.LastMapPlayed = mapName
	data.CurrentCheckpoint = 0
	PlayerDataManager.UpdateClient(player)
end

local function setupMiscConnections()
	for _, mapName in MAP_NAMES do
		local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
		if not mapFolder then
			continue
		end

		local misc = mapFolder:FindFirstChild("Misc")
		if not misc then
			continue
		end

		for _, part in misc:GetChildren() do
			if not part:IsA("BasePart") then
				continue
			end

			part.Touched:Connect(function(hit)
				local character = hit.Parent
				if not character then
					return
				end

				local player = Players:GetPlayerFromCharacter(character)
				if not player then
					return
				end

				onMiscTouched(player, mapName)
			end)
		end
	end
end

local function setupFinishConnections()
	print("[MapService] setupFinishConnections called")
	for _, mapName in MAP_NAMES do
		print("[MapService] Setting up finish for:", mapName)
		local finishPart = getFinishPart(mapName)
		if not finishPart then
			print("[MapService] WARNING: No finish part for", mapName)
			continue
		end

		print("[MapService] Connecting Touched event for finish part")

		finishPart.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then
				return
			end

			local player = Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end

			onFinishPartTouched(player, mapName)
		end)
		print("[MapService] Finish connection done for", mapName)
	end
	print("[MapService] setupFinishConnections complete")
end

local function respawnPlayer(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		teleportToLobby(player)
		return
	end

	local lastMap = data.LastMapPlayed
	if lastMap and lastMap ~= "" then
		local mapData = data.Map[lastMap]
		if mapData and mapData.LastCheckpoint > 0 then
			data.CurrentCheckpoint = mapData.LastCheckpoint
			PlayerDataManager.UpdateClient(player)
			teleportToCheckpoint(player, lastMap, mapData.LastCheckpoint)
		else
			data.CurrentCheckpoint = 0
			PlayerDataManager.UpdateClient(player)
			teleportToLobby(player)
		end
	else
		data.CurrentCheckpoint = 0
		PlayerDataManager.UpdateClient(player)
		teleportToLobby(player)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	task.wait(0.1)

	if not MorphManager.HasMorph(player) then
		respawnPlayer(player)
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			MorphManager.RemoveMorph(player)
			player.CharacterAdded:Wait()
			task.wait(0.1)
			respawnPlayer(player)
		end)
	end
end

local function onPlayerAdded(player: Player)
	local maxRetries = 10
	local retries = 0
	while not PlayerDataManager.GetData(player) and retries < maxRetries do
		task.wait(0.5)
		retries += 1
	end

	local data = PlayerDataManager.GetData(player)
	if data then
		for mapName, mapData in data.Map do
			if mapData.Completed and (mapData.CheckpointReached or 0) >= TOTAL_CHECKPOINTS then
				showFinishPart(player, mapName)
			end
		end
	end

	if player.Character then
		onCharacterAdded(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end

local function onGoBackStage(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	local lastMap = data.LastMapPlayed
	if not lastMap or lastMap == "" then
		return false
	end

	local mapData = data.Map[lastMap]
	if not mapData then
		return false
	end

	local newCheckpoint = mapData.LastCheckpoint - 1
	if newCheckpoint < 0 then
		return false
	end

	mapData.LastCheckpoint = newCheckpoint
	data.CurrentCheckpoint = newCheckpoint
	PlayerDataManager.UpdateClient(player)

	if newCheckpoint == 0 then
		teleportToLobby(player)
	else
		teleportToCheckpoint(player, lastMap, newCheckpoint)
	end

	return true
end

local function onGoForwardStage(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	local lastMap = data.LastMapPlayed
	if not lastMap or lastMap == "" then
		return false
	end

	local mapData = data.Map[lastMap]
	if not mapData then
		return false
	end

	local newCheckpoint = mapData.LastCheckpoint + 1
	if newCheckpoint > TOTAL_CHECKPOINTS then
		return false
	end

	if newCheckpoint > (mapData.CheckpointReached or 0) then
		return false
	end

	mapData.LastCheckpoint = newCheckpoint
	data.CurrentCheckpoint = newCheckpoint
	PlayerDataManager.UpdateClient(player)
	teleportToCheckpoint(player, lastMap, newCheckpoint)

	return true
end

local function onUseSkip(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	if (data.FreeSkips or 0) <= 0 then
		return false
	end

	local lastMap = data.LastMapPlayed
	if not lastMap or lastMap == "" then
		return false
	end

	local mapData = data.Map[lastMap]
	if not mapData then
		return false
	end

	if (mapData.CheckpointReached or 0) >= TOTAL_CHECKPOINTS then
		return false
	end

	local newCheckpoint = mapData.LastCheckpoint + 1
	if newCheckpoint > TOTAL_CHECKPOINTS then
		return false
	end

	data.FreeSkips = data.FreeSkips - 1
	mapData.LastCheckpoint = newCheckpoint
	data.CurrentCheckpoint = newCheckpoint

	if newCheckpoint > (mapData.CheckpointReached or 0) then
		local previousReached = mapData.CheckpointReached or 0
		mapData.CheckpointReached = newCheckpoint
		giveCheckpointReward(player, previousReached, newCheckpoint)
	end

	if newCheckpoint >= TOTAL_CHECKPOINTS then
		mapData.Completed = true
		PlayerDataManager.Increase(player, "Wins", 1)

		local nextMap = MAP_UNLOCK_ORDER[lastMap]
		if nextMap then
			destroyUnlockWall(nextMap)
		end

		showFinishPart(player, lastMap)
		teleportToCheckpoint(player, lastMap, TOTAL_CHECKPOINTS)
	else
		teleportToCheckpoint(player, lastMap, newCheckpoint)
	end

	PlayerDataManager.UpdateClient(player)

	return true
end

local function onUseFinish(player: Player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	local lastMap = data.LastMapPlayed
	if not lastMap or lastMap == "" then
		return false
	end

	local mapData = data.Map[lastMap]
	if not mapData then
		return false
	end

	if (mapData.CheckpointReached or 0) >= TOTAL_CHECKPOINTS then
		return false
	end

	local checkpointReached = mapData.CheckpointReached or 0
	giveCheckpointReward(player, checkpointReached, TOTAL_CHECKPOINTS)

	teleportToCheckpoint(player, lastMap, TOTAL_CHECKPOINTS)

	task.delay(0.5, function()
		local currentData = PlayerDataManager.GetData(player)
		if not currentData then
			return
		end

		local currentMapData = currentData.Map[lastMap]
		if not currentMapData then
			return
		end

		currentMapData.CheckpointReached = TOTAL_CHECKPOINTS
		currentMapData.LastCheckpoint = TOTAL_CHECKPOINTS
		currentData.CurrentCheckpoint = TOTAL_CHECKPOINTS
		currentMapData.Completed = true
		PlayerDataManager.Increase(player, "Wins", 1)

		local nextMap = MAP_UNLOCK_ORDER[lastMap]
		if nextMap then
			destroyUnlockWall(nextMap)
		end

		showFinishPart(player, lastMap)
		PlayerDataManager.UpdateClient(player)
	end)

	return true
end

function MapService.Init() end

local function setupMorphConnections()
	print("[MapService] setupMorphConnections called")
	local morphTouchDebounce = {}

	for _, mapName in MAP_NAMES do
		print("[MapService] Setting up morph for map:", mapName)
		local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
		if not mapFolder then
			print("[MapService] ERROR: mapFolder not found:", mapName)
			continue
		end

		local winFolder = mapFolder:FindFirstChild("Win")
		if not winFolder then
			print("[MapService] ERROR: Win folder not found in", mapName)
			continue
		end

		local freeItemsFolder = winFolder:FindFirstChild("FreeItems")
		if not freeItemsFolder then
			print("[MapService] ERROR: FreeItems folder not found in", mapName)
			continue
		end

		local color = mapName:gsub("67", "")
		local morphPartName = color .. "67Morph"
		local morphPart = freeItemsFolder:FindFirstChild(morphPartName)

		print("[MapService] Looking for morphPart:", morphPartName, "in", freeItemsFolder:GetFullName())
		print("[MapService] FreeItems children:", freeItemsFolder:GetChildren())

		if morphPart then
			print("[MapService] Found morphPart:", morphPart:GetFullName(), "IsA Model:", morphPart:IsA("Model"))

			local touchPart = nil
			if morphPart:IsA("BasePart") then
				touchPart = morphPart
			elseif morphPart:IsA("Model") then
				for _, child in morphPart:GetChildren() do
					if child:IsA("MeshPart") or child:IsA("BasePart") then
						touchPart = child
						break
					end
				end
			end

			if touchPart then
				print("[MapService] Using touchPart:", touchPart:GetFullName())
				touchPart.Touched:Connect(function(hit)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if not player then
						return
					end

					print("[MapService] Morph part touched by:", player.Name)

					local debounceKey = player.UserId .. "_" .. morphPartName
					if morphTouchDebounce[debounceKey] then
						print("[MapService] Debounced, ignoring")
						return
					end
					morphTouchDebounce[debounceKey] = true

					print("[MapService] Applying morph:", morphPartName)
					MorphManager.ApplyMorph(player, morphPartName)

					task.delay(1, function()
						morphTouchDebounce[debounceKey] = nil
					end)
				end)
				print("[MapService] Touched connection created for:", morphPartName)
			else
				print("[MapService] ERROR: No valid BasePart/MeshPart found in morphPart")
			end
		else
			print("[MapService] ERROR: morphPart not found:", morphPartName)
		end
	end

	print("[MapService] setupMorphConnections finished")
end

local function setupKillPartsConnections()
	local killPartsFolder = MAP_FOLDER.Lobby:FindFirstChild("KillParts")
	if not killPartsFolder then
		return
	end

	for _, killPart in killPartsFolder:GetChildren() do
		if not killPart:IsA("BasePart") then
			continue
		end

		killPart.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then
				return
			end

			local player = Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end

			if killPartsDebounce[player] then
				return
			end
			killPartsDebounce[player] = true

			respawnPlayer(player)

			task.delay(1, function()
				killPartsDebounce[player] = nil
			end)
		end)
	end
end

function MapService.Start()
	setupCheckpointConnections()
	setupMiscConnections()
	setupFinishConnections()
	setupMorphConnections()
	setupKillPartsConnections()

	local goBackStage = RemotesManager:GetRemote("GoBackStage")
	local goForwardStage = RemotesManager:GetRemote("GoForwardStage")
	local useSkip = RemotesManager:GetRemote("UseSkip")
	local useFinish = RemotesManager:GetRemote("UseFinish")

	goBackStage.OnServerInvoke = onGoBackStage
	goForwardStage.OnServerInvoke = onGoForwardStage
	useSkip.OnServerInvoke = onUseSkip
	useFinish.OnServerInvoke = onUseFinish

	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

function MapService.SkipToCheckpoint(player: Player, mapName: string, checkpointIndex: number)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	local mapData = data.Map[mapName]
	if not mapData then
		return false
	end

	mapData.LastCheckpoint = checkpointIndex
	data.CurrentCheckpoint = checkpointIndex
	data.LastMapPlayed = mapName
	PlayerDataManager.UpdateClient(player)

	teleportToCheckpoint(player, mapName, checkpointIndex)

	return true
end

function MapService.TeleportToCheckpoint(player: Player, mapName: string, checkpointIndex: number)
	teleportToCheckpoint(player, mapName, checkpointIndex)
end

function MapService.TeleportToLobby(player: Player)
	teleportToLobby(player)
end

function MapService.DestroyUnlockWall(mapName: string)
	destroyUnlockWall(mapName)
end

function MapService.ShowFinishPart(player: Player, mapName: string)
	showFinishPart(player, mapName)
end

function MapService.GetNextCheckpoint(player: Player, mapName: string): number?
	local data = PlayerDataManager.GetData(player)
	if not data then
		return nil
	end

	local mapData = data.Map[mapName]
	if not mapData then
		return nil
	end

	local nextCheckpoint = mapData.LastCheckpoint + 1
	if nextCheckpoint > TOTAL_CHECKPOINTS then
		return nil
	end

	return nextCheckpoint
end

return MapService
