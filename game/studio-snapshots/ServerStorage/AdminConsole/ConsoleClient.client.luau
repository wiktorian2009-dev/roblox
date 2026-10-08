-- Admin console: F2 (or the ADMIN button) to open, type ;commands, Enter to run.
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cmdEvent = ReplicatedStorage:WaitForChild("AdminCommand")

local sg = script.Parent
local window = sg:WaitForChild("Window")
local log = window:WaitForChild("Log")
local box = window:WaitForChild("Input")
local order = 0
local history, hIndex = {}, 0

-- the toggle button lives in its own always-visible ScreenGui
local tg = Instance.new("ScreenGui")
tg.Name = "AdminToggle"
tg.ResetOnSpawn = false
tg.DisplayOrder = 200
tg.Parent = sg.Parent
local toggleBtn = sg:WaitForChild("ToggleTemplate"):Clone()
toggleBtn.Name = "Toggle"
toggleBtn.Parent = tg

local function add(text, color)
	for line in (text .. "\n"):gmatch("([^\n]*)\n") do
		order += 1
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, 0, 0, 18)
		l.Font = Enum.Font.Code
		l.TextSize = 15
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = color
		l.Text = line
		l.LayoutOrder = order
		l.Parent = log
	end
	task.defer(function() log.CanvasPosition = Vector2.new(0, 1e6) end)
end

local function toggle()
	sg.Enabled = not sg.Enabled
	if sg.Enabled then task.defer(function() box:CaptureFocus() end) end
end
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.F2 then toggle()
	elseif box:IsFocused() and #history > 0 then
		if input.KeyCode == Enum.KeyCode.Up then hIndex = math.max(1, hIndex - 1); box.Text = history[hIndex]
		elseif input.KeyCode == Enum.KeyCode.Down then hIndex = math.min(#history + 1, hIndex + 1); box.Text = history[hIndex] or "" end
	end
end)
toggleBtn.Activated:Connect(toggle)

box.FocusLost:Connect(function(enter)
	if not enter then return end
	local text = box.Text
	if text:gsub("%s", "") == "" then return end
	if text:sub(1, 1) ~= ";" then text = ";" .. text end
	table.insert(history, text)
	hIndex = #history + 1
	add("> " .. text, Color3.fromRGB(170, 180, 200))
	cmdEvent:FireServer(text)
	box.Text = ""
	task.defer(function() box:CaptureFocus() end)
end)

cmdEvent.OnClientEvent:Connect(function(msg, ok)
	add(msg, ok and Color3.fromRGB(120, 235, 140) or Color3.fromRGB(255, 120, 120))
end)

add("Admin console ready. Type help and press Enter.", Color3.fromRGB(255, 190, 60))
