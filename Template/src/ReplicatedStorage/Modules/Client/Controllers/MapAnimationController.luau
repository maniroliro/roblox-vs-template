local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QualityManager = require(ReplicatedStorage.Modules.Client.Managers.QualityManager)

local MapAnimationController = {}

local MAP_FOLDER = workspace:WaitForChild("Map")
local MAP_NAMES = { "67Blue", "67Red", "67Purple", "67Green" }

-- Animation config for 6Hand and 7Hand objects
local HAND_CONFIG = {
	BASE_BOB_HEIGHT = 10,
	BASE_BOB_SPEED = 2,
	BASE_ROTATION_SPEED = 6,
	BASE_ROTATION_ANGLE = 10,
	SCALE_BY_SIZE = false,
}

-- Animation config for 6HandBig and 7HandBig objects
local HAND_BIG_CONFIG = {
	BASE_BOB_HEIGHT = 30,
	BASE_BOB_SPEED = 7,
	BASE_ROTATION_SPEED = 10,
	BASE_ROTATION_ANGLE = 10,
	SCALE_BY_SIZE = false,
}

-- Animation config for [Color]67 objects (Blue67, Red67, Purple67, Green67)
local COLOR67_CONFIG = {
	BASE_BOB_HEIGHT = 8,
	BASE_BOB_SPEED = 1.8,
	BASE_ROTATION_SPEED = 15,
	BASE_ROTATION_ANGLE = 5,
	SCALE_BY_SIZE = false,
}

-- Animation config for [Color]67Gigant objects
local GIGANT_CONFIG = {
	BASE_BOB_HEIGHT = 5,
	BASE_BOB_SPEED = 1.5,
	BASE_ROTATION_SPEED = 15,
	BASE_ROTATION_ANGLE = 3,
	SCALE_BY_SIZE = false,
}

local animatedObjects = {}
local allParticleEmitters = {}

local COLORS = { "Blue", "Red", "Purple", "Green" }

local function getAnimationType(objectName: string): string
	-- Check for HandBig first (more specific)
	if string.find(objectName, "6HandBig") then
		return "6HandBig"
	elseif string.find(objectName, "7HandBig") then
		return "7HandBig"
	-- Check for regular Hand
	elseif string.find(objectName, "6Hand") then
		return "6Hand"
	elseif string.find(objectName, "7Hand") then
		return "7Hand"
	end

	-- Check for [Color]67Gigant
	for _, color in COLORS do
		if string.find(objectName, color .. "67Gigant") then
			return "Gigant"
		end
	end

	-- Check for [Color]67
	for _, color in COLORS do
		if string.find(objectName, color .. "67") then
			return "Color67"
		end
	end

	return "Other"
end

local function getConfigForType(animationType: string)
	if animationType == "6Hand" or animationType == "7Hand" then
		return HAND_CONFIG
	elseif animationType == "6HandBig" or animationType == "7HandBig" then
		return HAND_BIG_CONFIG
	elseif animationType == "Color67" then
		return COLOR67_CONFIG
	elseif animationType == "Gigant" then
		return GIGANT_CONFIG
	else
		return COLOR67_CONFIG
	end
end

local function setupModelAnimation(object: Model | BasePart)
	local primaryPart
	local isModel = object:IsA("Model")

	if isModel then
		primaryPart = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
	else
		primaryPart = object
	end

	if not primaryPart then
		return
	end

	local animationType = getAnimationType(object.Name)
	local config = getConfigForType(animationType)

	local scale = 1
	if config.SCALE_BY_SIZE then
		local size = primaryPart.Size
		local averageSize = (size.X + size.Y + size.Z) / 3
		scale = math.clamp(averageSize / 10, 0.3, 3)
	end

	local bobHeight = config.BASE_BOB_HEIGHT * scale
	local bobSpeed = config.BASE_BOB_SPEED * scale
	local rotationSpeed = config.BASE_ROTATION_SPEED * scale
	local rotationAngle = config.BASE_ROTATION_ANGLE * scale

	local originalCFrame
	if isModel then
		originalCFrame = object:GetPivot()
	else
		originalCFrame = object.CFrame
	end

	table.insert(animatedObjects, {
		object = object,
		isModel = isModel,
		originalCFrame = originalCFrame,
		bobHeight = bobHeight,
		bobSpeed = bobSpeed,
		rotationSpeed = rotationSpeed,
		rotationAngle = rotationAngle,
		animationType = animationType,
	})
end

local function setupMapAnimations()
	for _, mapName in MAP_NAMES do
		local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
		if not mapFolder then
			continue
		end

		local toAnimate = mapFolder:FindFirstChild("ToAnimate")
		if not toAnimate then
			continue
		end

		for _, child in toAnimate:GetChildren() do
			if child:IsA("Model") then
				setupModelAnimation(child)
			elseif child:IsA("BasePart") then
				setupModelAnimation(child)
			elseif child:IsA("Folder") then
				for _, subChild in child:GetChildren() do
					if subChild:IsA("Model") then
						setupModelAnimation(subChild)
					elseif subChild:IsA("BasePart") then
						setupModelAnimation(subChild)
					end
				end
			end
		end
	end
end

local function updateAnimations(deltaTime: number)
	if not QualityManager.IsHighQuality() then
		return
	end

	local currentTime = tick()

	for _, data in animatedObjects do
		if not data.object or not data.object.Parent then
			continue
		end

		-- Phase offset for synchronized opposite animations
		local phaseOffset = 0
		if data.animationType == "7Hand" or data.animationType == "7HandBig" then
			phaseOffset = math.pi
		end

		local bobSineValue = math.sin((currentTime * data.bobSpeed) + phaseOffset)
		local rotationTime = (currentTime * data.rotationSpeed) + phaseOffset

		local offset = bobSineValue * data.bobHeight
		local halfAngle = data.rotationAngle / 2

		local rotationCFrame
		if data.animationType == "Gigant" or data.animationType == "Color67" then
			local rotX = math.rad(math.sin(rotationTime) * halfAngle)
			local rotY = math.rad(math.cos(rotationTime) * halfAngle)
			local rotZ = math.rad(math.sin(rotationTime + math.pi / 2) * halfAngle)
			rotationCFrame = CFrame.Angles(rotX, rotY, rotZ)
		else
			local rotationRad = math.rad(math.sin(rotationTime) * halfAngle)
			rotationCFrame = CFrame.Angles(0, rotationRad, 0)
		end

		local newCFrame = (data.originalCFrame + Vector3.new(0, offset, 0)) * rotationCFrame

		if data.isModel then
			data.object:PivotTo(newCFrame)
		else
			data.object.CFrame = newCFrame
		end
	end
end

local function collectParticleEmitters()
	for _, mapName in MAP_NAMES do
		local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
		if not mapFolder then
			continue
		end

		for _, descendant in mapFolder:GetDescendants() do
			if descendant:IsA("ParticleEmitter") then
				table.insert(allParticleEmitters, descendant)
			end
		end
	end

	local lobby = MAP_FOLDER:FindFirstChild("Lobby")
	if lobby then
		for _, descendant in lobby:GetDescendants() do
			if descendant:IsA("ParticleEmitter") then
				table.insert(allParticleEmitters, descendant)
			end
		end
	end
end

local function setParticleEmittersEnabled(enabled: boolean)
	for _, emitter in allParticleEmitters do
		if emitter and emitter.Parent then
			emitter.Enabled = enabled
		end
	end
end

local function onParticleAdded(descendant: Instance)
	if not descendant:IsA("ParticleEmitter") then
		return
	end

	table.insert(allParticleEmitters, descendant)

	if not QualityManager.IsHighQuality() then
		descendant.Enabled = false
	end
end

local function resetAnimationsToOriginal()
	for _, data in animatedObjects do
		if data.object and data.object.Parent then
			if data.isModel then
				data.object:PivotTo(data.originalCFrame)
			else
				data.object.CFrame = data.originalCFrame
			end
		end
	end
end

local function onHighQualityChanged(enabled: boolean)
	setParticleEmittersEnabled(enabled)

	if not enabled then
		resetAnimationsToOriginal()
	end
end

function MapAnimationController.SetHighQuality(enabled: boolean)
	QualityManager.SetHighQuality(enabled)
end

function MapAnimationController.Init() end

function MapAnimationController.Start()
	setupMapAnimations()
	collectParticleEmitters()

	QualityManager.HighQualityChanged:Connect(onHighQualityChanged)

	for _, mapName in MAP_NAMES do
		local mapFolder = MAP_FOLDER:FindFirstChild(mapName)
		if mapFolder then
			mapFolder.DescendantAdded:Connect(onParticleAdded)
		end
	end

	local lobby = MAP_FOLDER:FindFirstChild("Lobby")
	if lobby then
		lobby.DescendantAdded:Connect(onParticleAdded)
	end

	animationConnection = RunService.Heartbeat:Connect(updateAnimations)
end

return MapAnimationController
