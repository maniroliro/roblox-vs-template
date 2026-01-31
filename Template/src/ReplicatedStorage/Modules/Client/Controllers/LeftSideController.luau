local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Modules = ReplicatedStorage.Modules
local PlayerDataManager = require(Modules.Client.Managers.PlayerDataManager)
local GUIManager = require(Modules.Client.Managers.GUIManager)
local FormatUtils = require(Modules.Shared.Utils.FormatUtils)
local CashFrameController = require(Modules.Client.Controllers.CashFrameController)
local GearsFrameController = require(Modules.Client.Controllers.GearsFrameController)

local LeftSideController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("GUI")
local leftSide = gui:WaitForChild("LeftSide")
local frames = gui:WaitForChild("Frames")

local cashLabel = leftSide:WaitForChild("Cash"):WaitForChild("Title")
local winsLabel = leftSide:WaitForChild("Wins"):WaitForChild("Title")
local gearsButton = leftSide:WaitForChild("Gears")
local upgradesButton = leftSide:WaitForChild("Upgrades")
local inviteButton = leftSide:WaitForChild("Invite")
local buyCashButton = leftSide:WaitForChild("Cash")

local gearsFrame = frames:WaitForChild("Gears")
local upgradesFrame = frames:WaitForChild("Upgrades")
local buyCashFrame = frames:WaitForChild("Cash")

local function updateCashLabel(data)
	if not data then
		return
	end
	cashLabel.Text = FormatUtils.FormatCash(data.Cash or 0)
end

local function updateWinsLabel(data)
	if not data then
		return
	end
	winsLabel.Text = FormatUtils.FormatNumber(data.Wins or 0)
end

local function updateUI(data)
	updateCashLabel(data)
	updateWinsLabel(data)
end

local function onDataUpdated(newData, oldData)
	updateUI(newData)
end

local function onGearsButtonClicked()
	GUIManager.ToggleFrame("Gears")
end

local function onUpgradesButtonClicked()
	GUIManager.ToggleFrame("Upgrades")
end

local function onInviteButtonClicked()
	local success, err = pcall(function()
		SocialService:PromptGameInvite(player)
	end)
end

local function onBuyCashButtonClicked()
	GUIManager.ToggleFrame("Cash")
end

function LeftSideController.Init()
	CashFrameController.Init()
	GearsFrameController.Init()

	-- Setup gears frame references (TODO: uncomment and set proper paths)
	-- GearsFrameController.SetTemplate(gearTemplate)
	-- GearsFrameController.SetContent(gearsContent)

	GUIManager.RegisterFrame("Gears", gearsFrame)
	GUIManager.RegisterFrame("Upgrades", upgradesFrame)
	GUIManager.RegisterFrame("Cash", buyCashFrame)
end

function LeftSideController.Start()
	CashFrameController.Start()
	GearsFrameController.Start()

	gearsButton.Activated:Connect(onGearsButtonClicked)
	upgradesButton.Activated:Connect(onUpgradesButtonClicked)
	inviteButton.Activated:Connect(onInviteButtonClicked)
	buyCashButton.Activated:Connect(onBuyCashButtonClicked)

	PlayerDataManager.DataUpdated:Connect(onDataUpdated)

	task.spawn(function()
		local data = PlayerDataManager.WaitForData()
		updateUI(data)
	end)
end

return LeftSideController
