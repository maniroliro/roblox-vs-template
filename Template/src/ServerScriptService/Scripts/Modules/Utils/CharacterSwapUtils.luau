local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local rigsFolder = Assets.Rigs
local prisonerRig = rigsFolder.Prisoner

local CharacterSwapUtils = {}

function CharacterSwapUtils.SwapCharacter(player: Player, rig: Model?)
	local char = player.Character
	assert(char, "Character not found")
	assert(char.PrimaryPart, "Old character has no PrimaryPart")

	rig = rig or prisonerRig
	assert(rig, "No rig provided and no default rig available")

	local newChar = (rig :: Model):Clone()

	local newRootPart = newChar:FindFirstChild("HumanoidRootPart")
	assert(newRootPart, "Rig has no HumanoidRootPart")

	local newHumanoid = newChar:FindFirstChildOfClass("Humanoid")
	assert(newHumanoid, "Rig has no Humanoid")

	newChar.PrimaryPart = newRootPart
	newChar:SetPrimaryPartCFrame(char.PrimaryPart.CFrame)
	newChar.Name = player.Name

	if char:FindFirstChild("Animate") and not newChar:FindFirstChild("Animate") then
		char.Animate:Clone().Parent = newChar
	end
	if char:FindFirstChild("Health") and not newChar:FindFirstChild("Health") then
		char.Health:Clone().Parent = newChar
	end

	player.Character = newChar
	newChar.Parent = workspace
	newRootPart.CFrame = char.HumanoidRootPart.CFrame

	for _, part in newChar:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end

	char:Destroy()
end

return CharacterSwapUtils
