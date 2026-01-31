--[[ Made By Wheez]]
--
local Player = game:GetService("Players").LocalPlayer
repeat
	task.wait()
until Player:FindFirstChild("LoadedGifts")
require(script:WaitForChild("Toggle"))(script)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GiftFolder = ReplicatedStorage:WaitForChild("GiftFolder")
local SharedGiftData = require(GiftFolder:WaitForChild("SharedGiftData"))
--[[]]
--
local List = script.Parent:WaitForChild("Frame"):WaitForChild("List")
local SessionData = GiftFolder:WaitForChild("GetData"):InvokeServer()
local GiftObjects = {}
--[[]]
--
local Debounce = false
--[[]]
--
local TweenService = game:GetService("TweenService")
local HoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local function FormatNumber(Int)
	return string.format("%02i", Int)
end
function ConvertSeconds(Seconds)
	local Minutes = (Seconds - Seconds % 60) / 60
	Seconds = Seconds - Minutes * 60
	local Hours = (Minutes - Minutes % 60) / 60
	Minutes = Minutes - Hours * 60
	local FinalText = FormatNumber(Seconds)
	FinalText = FormatNumber(Minutes) .. ":" .. FinalText
	if Hours > 0 then
		FinalText = FormatNumber(Hours) .. ":" .. FinalText
	end
	return FinalText
end
--[[]]
--
local function SetReady(Object, GiftNumber)
	Object.TextLabel.Text = "READY"
	Object.TextLabel.TextColor3 = Color3.fromRGB(47, 255, 61)
	Object.Icon.ImageColor3 = Color3.fromRGB(47, 255, 61)
	local Connection
	Connection = Object.Button.Activated:Connect(function()
		if Debounce == true then
			return
		end
		Debounce = true
		Connection:Disconnect()
		local Response = GiftFolder.ClaimGift:InvokeServer(GiftNumber)
		if Response == true then
			Object.TextLabel.Text = "Claimed"
			Object.TextLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			Object.Icon.ImageColor3 = Color3.fromRGB(61, 164, 255)
		end
		task.wait(0.1)
		Debounce = false
	end)
end
local function CreateTemplates()
	local function ReturnCreatedObj()
		local Object = script["Template"]:Clone()
		return Object
	end
	for i, v in pairs(SharedGiftData) do
		local GiftNumber = v["GiftNumber"]
		local Requirement = v["Time"]
		local Object = ReturnCreatedObj()
		Object.Name = tostring(GiftNumber)
		Object.LayoutOrder = GiftNumber
		local RemainingTime = (Requirement - SessionData)
		if RemainingTime <= 0 then
			if Player.ClaimedGifts:FindFirstChild(GiftNumber) then
				Object.TextLabel.Text = "Claimed"
				Object.TextLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			else
				SetReady(Object, GiftNumber)
			end
		else
			Object.TextLabel.Text = ConvertSeconds(RemainingTime)
			table.insert(GiftObjects, { Object, Requirement, GiftNumber })
		end
		Object.Button.MouseEnter:Connect(function()
			TweenService:Create(
				Object.Button,
				HoverInfo,
				{ Position = UDim2.new(0.5, 0, 0.3, 0), ImageColor3 = Color3.fromRGB(200, 200, 200) }
			):Play()
		end)
		Object.Button.MouseLeave:Connect(function()
			TweenService:Create(
				Object.Button,
				HoverInfo,
				{ Position = UDim2.new(0.5, 0, 0.4, 0), ImageColor3 = Color3.fromRGB(255, 255, 255) }
			):Play()
		end)
		Object.Parent = List
	end
end
CreateTemplates()
--[[]]
--
local SessionObject = Player:WaitForChild("CurrentSession")
local ToggleButton = script.Parent["TextButton"]
SessionObject:GetPropertyChangedSignal("Value"):Connect(function()
	local NewSession = (SessionData + SessionObject.Value)
	local LowestTimer, IsReady = nil, false
	for i, v in pairs(GiftObjects) do
		local Object = v[1]
		local Requirement = v[2]
		local RemainingTime = (Requirement - NewSession)
		if LowestTimer == nil or (RemainingTime < LowestTimer) then
			LowestTimer = RemainingTime
		end
		if RemainingTime <= 0 then
			table.remove(GiftObjects, i)
			SetReady(Object, v[3])
		else
			Object.TextLabel.Text = ConvertSeconds(RemainingTime)
		end
	end
	for i, v in pairs(SharedGiftData) do
		if (v.Time - NewSession) <= 0 and not Player.ClaimedGifts:FindFirstChild(v.GiftNumber) then
			IsReady = true
			break
		end
	end
	if IsReady then
		ToggleButton.Lowest.Text = "READY"
		ToggleButton.Lowest.TextColor3 = Color3.fromRGB(47, 255, 61)
	else
		ToggleButton.Lowest.TextColor3 = Color3.fromRGB(255, 255, 255)
		if typeof(LowestTimer) ~= "nil" then
			ToggleButton.Lowest.Text = ConvertSeconds(LowestTimer)
		else
			ToggleButton.Lowest.Text = ""
		end
	end
end)
