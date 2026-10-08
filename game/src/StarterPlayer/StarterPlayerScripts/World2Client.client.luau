-- World2Client (2026-10-02, Claude): short toasts for World 2 activity rewards (World2Notice from World2Activities).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local notice = RS:WaitForChild("World2Notice", 60)
if not notice then return end

local gui = Instance.new("ScreenGui")
gui.Name = "World2Toast"
gui.ResetOnSpawn = false
gui.DisplayOrder = 41
gui.Parent = player:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.fromScale(0.5, 0.24)
label.Size = UDim2.fromScale(0.6, 0.06)
label.BackgroundTransparency = 1
label.Font = Enum.Font.FredokaOne
label.TextScaled = true
label.TextTransparency = 1
label.Parent = gui
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Transparency = 1
stroke.Parent = label

local token = 0
notice.OnClientEvent:Connect(function(text, good)
	token += 1
	local my = token
	label.Text = tostring(text)
	label.TextColor3 = good and Color3.fromRGB(255, 226, 120) or Color3.fromRGB(255, 165, 165)
	label.TextTransparency = 0
	stroke.Transparency = 0
	task.delay(2.8, function()
		if my ~= token then return end
		TweenService:Create(label, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
	end)
end)
