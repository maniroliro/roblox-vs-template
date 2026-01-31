local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Spring = require(ReplicatedStorage.Modules.Packages.spring)
local SoundManager = require(ReplicatedStorage.Modules.Client.Managers.SoundManager)

local UIAnimations = {}

local buttonSprings = {}
local connections = {}

local BUTTON_SMOOTH_TIME = 0.05
local FRAME_SMOOTH_TIME = 0.08

local function updateButtonSize(button: GuiButton, spring)
	local baseSize = button:GetAttribute("BaseSize")
	if not baseSize then
		return
	end

	local scale = spring.Current
	button.Size = UDim2.new(
		baseSize.X.Scale * scale,
		baseSize.X.Offset * scale,
		baseSize.Y.Scale * scale,
		baseSize.Y.Offset * scale
	)
end

function UIAnimations.SetupButton(button: GuiButton)
	if buttonSprings[button] then
		return
	end

	button:SetAttribute("BaseSize", button.Size)

	local spring = Spring.new(1, BUTTON_SMOOTH_TIME)
	buttonSprings[button] = spring

	local buttonConnections = {}

	buttonConnections[#buttonConnections + 1] = button.MouseEnter:Connect(function()
		spring.Target = 1.06
		SoundManager.Play("Hover")
	end)

	buttonConnections[#buttonConnections + 1] = button.MouseLeave:Connect(function()
		spring.Target = 1
	end)

	buttonConnections[#buttonConnections + 1] = button.MouseButton1Down:Connect(function()
		spring.Target = 0.91
	end)

	buttonConnections[#buttonConnections + 1] = button.MouseButton1Up:Connect(function()
		spring.Target = 1
	end)

	buttonConnections[#buttonConnections + 1] = button.Activated:Connect(function()
		spring.Target = 1
		SoundManager.Play("Click")
	end)

	connections[button] = buttonConnections

	buttonConnections[#buttonConnections + 1] = button.Destroying:Connect(function()
		UIAnimations.CleanupButton(button)
	end)
end

function UIAnimations.CleanupButton(button: GuiButton)
	local buttonConnections = connections[button]
	if buttonConnections then
		for _, conn in buttonConnections do
			conn:Disconnect()
		end
		connections[button] = nil
	end

	buttonSprings[button] = nil
end

function UIAnimations.SetupAllButtons(parent: Instance)
	for _, descendant in parent:GetDescendants() do
		if descendant:IsA("GuiButton") then
			UIAnimations.SetupButton(descendant)
		end
	end

	parent.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("GuiButton") then
			UIAnimations.SetupButton(descendant)
		end
	end)
end

function UIAnimations.OpenFrame(frame: Frame, callback: (() -> ())?)
	if not frame:GetAttribute("BaseSize") then
		frame:SetAttribute("BaseSize", frame.Size)
	end

	local baseSize = frame:GetAttribute("BaseSize")
	frame.Size =
		UDim2.new(baseSize.X.Scale * 0.9, baseSize.X.Offset * 0.9, baseSize.Y.Scale * 0.9, baseSize.Y.Offset * 0.9)

	frame.Visible = true

	local spring = Spring.new(0.9, FRAME_SMOOTH_TIME)
	spring.Target = 1

	local startTime = tick()
	local maxDuration = 0.25

	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local scale = spring:Update(dt)

		frame.Size = UDim2.new(
			baseSize.X.Scale * scale,
			baseSize.X.Offset * scale,
			baseSize.Y.Scale * scale,
			baseSize.Y.Offset * scale
		)

		local elapsed = tick() - startTime
		if math.abs(scale - 1) < 0.005 or elapsed > maxDuration then
			frame.Size = baseSize
			conn:Disconnect()
			if callback then
				callback()
			end
		end
	end)
end

function UIAnimations.CloseFrame(frame: Frame, callback: (() -> ())?)
	local baseSize = frame:GetAttribute("BaseSize") or frame.Size
	frame:SetAttribute("BaseSize", baseSize)

	local spring = Spring.new(1, FRAME_SMOOTH_TIME)
	spring.Target = 0.9

	local startTime = tick()
	local maxDuration = 0.2

	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local scale = spring:Update(dt)

		frame.Size = UDim2.new(
			baseSize.X.Scale * scale,
			baseSize.X.Offset * scale,
			baseSize.Y.Scale * scale,
			baseSize.Y.Offset * scale
		)

		local elapsed = tick() - startTime
		if math.abs(scale - 0.9) < 0.005 or elapsed > maxDuration then
			frame.Visible = false
			frame.Size = baseSize
			conn:Disconnect()
			if callback then
				callback()
			end
		end
	end)
end

function UIAnimations.Init()
	RunService.RenderStepped:Connect(function(dt)
		for button, spring in buttonSprings do
			if button and button.Parent then
				spring:Update(dt)
				updateButtonSize(button, spring)
			end
		end
	end)
end

return UIAnimations
