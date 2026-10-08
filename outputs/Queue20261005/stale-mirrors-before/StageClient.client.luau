-- StageClient: personal lock walls. Unlocked walls disappear only for you (your character's physics run on your device).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local S = require(ReplicatedStorage:WaitForChild("StageConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local unlock = ReplicatedStorage:WaitForChild("UnlockStage")
local player = Players.LocalPlayer

local walls = {} -- [model] = {stage, part, gui, title, icon, cost, button, opened}

-- toast
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "StageToast"
toastGui.ResetOnSpawn = false
toastGui.DisplayOrder = 40
toastGui.Parent = player:WaitForChild("PlayerGui")
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.fromScale(0.5, 0.18)
toast.Size = UDim2.fromScale(0.5, 0.07)
toast.BackgroundTransparency = 1
toast.Font = Enum.Font.FredokaOne
toast.TextScaled = true
toast.TextTransparency = 1
toast.Parent = toastGui
local toastStroke = Instance.new("UIStroke"); toastStroke.Thickness = 3; toastStroke.Transparency = 1; toastStroke.Parent = toast
local function showToast(text, color)
	toast.Text = text
	toast.TextColor3 = color
	toast.TextTransparency = 0
	toastStroke.Transparency = 0
	task.delay(2, function()
		TweenService:Create(toast, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		TweenService:Create(toastStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
	end)
end

local function isOpen(id) return id == "Starter" or player:GetAttribute("Stage_" .. id) == true end

local function refresh(w)
	local s = S.ById[w.stage]
	if not s or not w.part.Parent then return end
	if isOpen(w.stage) then
		if not w.opened then
			w.opened = true
			w.part.CanCollide = false
			if w.gui then w.gui.Enabled = false end
			if w.fade then w.fade:Cancel() end
   w.fade = TweenService:Create(w.part, TweenInfo.new(0.6), {Transparency = 1})
   w.fade:Play()
		end
		return
	end
	w.opened = false
	if w.fade then w.fade:Cancel(); w.fade = nil end
	w.part.Transparency = w.baseTransparency
	w.part.CanCollide = true
	if w.gui then w.gui.Enabled = true end
	if w.title then w.title.Text = s.Name:upper() end
	local prev = S.Previous(w.stage)
	if prev and not isOpen(prev.Id) then
		if w.cost then w.cost.Text = "Unlock " .. prev.Name .. " first" end
		if w.button then w.button.Text = "LOCKED"; w.button.BackgroundColor3 = Color3.fromRGB(120, 125, 140) end
	else
		if w.cost then w.cost.Text = "❄ " .. NumberFormat.Abbreviate(s.Cost) end
		if w.button then w.button.Text = "UNLOCK"; w.button.BackgroundColor3 = Color3.fromRGB(50, 210, 90) end
	end
end

local pending = {} -- 2026-10-02 (Claude): a wall whose part streams in late is registered when the part arrives
local function register(model)
	if walls[model] or pending[model] or not model:GetAttribute("Stage") then return end
	pending[model] = true
	local part = model:WaitForChild("Stage paywall", 10)
	pending[model] = nil
	if not part or walls[model] then return end
	local w = {stage = model:GetAttribute("Stage"), part = part, baseTransparency = part.Transparency}
	w.gui = part:FindFirstChild("PaywallSurface")
	if w.gui then
		for _, d in ipairs(w.gui:GetDescendants()) do
			if d:IsA("TextLabel") then
				if d.Name == "CostLabel" then w.cost = d
				elseif d.Text:find("LOCKED") then w.title = d end
			elseif d:IsA("TextButton") and d.Name == "UnlockButton" then
				w.button = d
			end
		end
	end
	if w.button then
		w.button.MouseButton1Click:Connect(function()
			if isOpen(w.stage) then return end
			local ok, res, msg = pcall(function() return unlock:InvokeServer(w.stage) end)
			if ok and res == true then
				showToast("🎉 " .. S.ById[w.stage].Name .. " unlocked!", Color3.fromRGB(120, 255, 140))
			else
				showToast(tostring(ok and msg or "Try again"), Color3.fromRGB(255, 120, 120))
			end
		end)
	end
	walls[model] = w
	model.AncestryChanged:Connect(function() if not model.Parent then walls[model] = nil end end)
	refresh(w)
end

local function refreshAll() for _, w in pairs(walls) do refresh(w) end end
for _, s in ipairs(S.Order) do player:GetAttributeChangedSignal("Stage_" .. s.Id):Connect(refreshAll) end

for _, m in ipairs(workspace:GetDescendants()) do
	if m:IsA("Model") and m.Name == "StagePaywall_Model" then task.spawn(register, m) end
end
workspace.DescendantAdded:Connect(function(m) -- streaming can bring walls in later
	if m:IsA("Model") and m.Name == "StagePaywall_Model" then task.spawn(register, m)
	elseif m.Name == "Stage paywall" and m.Parent and m.Parent.Name == "StagePaywall_Model" then task.spawn(register, m.Parent) end
end)

