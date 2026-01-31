local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PlayerDataManager = require(ReplicatedStorage.Modules.Client.Managers.PlayerDataManager)
local RemotesManager = require(ReplicatedStorage.Modules.Shared.Managers.RemotesManager)

local MapController = {}

local MAP_FOLDER = workspace:WaitForChild("Map")
local MAP_NAMES = { "67Blue", "67Red", "67Purple", "67Green" }
local MAP_UNLOCK_ORDER = {
	["67Blue"] = "67Red",
	["67Red"] = "67Green",
	["67Green"] = "67Purple",
}

local removedWalls = {}
local finishPartTweens = {}

local function getFinishPart(mapName: string): BasePart?
	print("[MapController] getFinishPart called for:", mapName)
	local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
	if not mapFolder then
		print("[MapController] mapFolder not found:", mapName)
		return nil
	end

	local toAnimate = mapFolder:FindFirstChild("ToAnimate")
	if not toAnimate then
		print("[MapController] ToAnimate not found in:", mapName)
		return nil
	end

	local color = mapName:gsub("67", "")
	local gigantFolderName = color .. "67Gigant"
	print("[MapController] Looking for:", gigantFolderName)
	local gigantFolder = toAnimate:FindFirstChild(gigantFolderName)
	if not gigantFolder then
		print("[MapController] gigantFolder not found:", gigantFolderName)
		print("[MapController] ToAnimate children:", toAnimate:GetChildren())
		return nil
	end

	local finishPart = gigantFolder:FindFirstChild("Finish")
	if not finishPart then
		print("[MapController] Finish not found in:", gigantFolderName)
		print("[MapController] gigantFolder children:", gigantFolder:GetChildren())
	end
	return finishPart
end

local function showFinishPartLocally(mapName: string)
	print("[MapController] showFinishPartLocally called for:", mapName)
	local finishPart = getFinishPart(mapName)
	if not finishPart then
		print("[MapController] ERROR: finishPart not found for:", mapName)
		return
	end

	if finishPartTweens[mapName] then
		finishPartTweens[mapName]:Cancel()
	end

	print("[MapController] Found finish part, starting pulse animation")
	finishPart.Transparency = 0.7

	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(finishPart, tweenInfo, { Transparency = 0.85 })
	finishPartTweens[mapName] = tween
	tween:Play()
	print("[MapController] Pulse tween started")
end

local function hideFinishPartLocally(mapName: string)
	if finishPartTweens[mapName] then
		finishPartTweens[mapName]:Cancel()
		finishPartTweens[mapName] = nil
	end

	local finishPart = getFinishPart(mapName)
	if not finishPart then
		return
	end

	finishPart.Transparency = 1
end

local function getUnlockWall(mapName: string): Instance?
	local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
	if not mapFolder then
		return nil
	end

	local color = mapName:gsub("67", "")
	return mapFolder:FindFirstChild(color .. "UnlockWall")
end

local function removeWallLocally(mapName: string)
	if removedWalls[mapName] then
		return
	end

	local wall = getUnlockWall(mapName)
	if not wall then
		return
	end

	wall:Destroy()

	for _, descendant in wall:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = 1
		end
	end

	removedWalls[mapName] = true
end

local function checkAndUnlockMaps(data)
	if not data or not data.Map then
		return
	end

	for completedMap, nextMap in MAP_UNLOCK_ORDER do
		local mapData = data.Map[completedMap]
		if mapData and mapData.Completed then
			removeWallLocally(nextMap)
		end
	end
end

local function onDataUpdated(newData, _oldData)
	checkAndUnlockMaps(newData)
end

function MapController.Init() end

function MapController.Start()
	PlayerDataManager.DataUpdated:Connect(onDataUpdated)

	print("[MapController] Connecting to ShowFinishPart remote")
	RemotesManager.OnEvent("ShowFinishPart", showFinishPartLocally)
	print("[MapController] Connecting to HideFinishPart remote")
	RemotesManager.OnEvent("HideFinishPart", hideFinishPartLocally)

	for _, mapName in MAP_NAMES do
		hideFinishPartLocally(mapName)
	end

	task.spawn(function()
		local data = PlayerDataManager.WaitForData()
		checkAndUnlockMaps(data)
	end)
end

return MapController
