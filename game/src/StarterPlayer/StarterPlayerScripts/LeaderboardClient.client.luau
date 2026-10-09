-- LeaderboardClient (2026-10-09, Claude): draws the global leaderboards (LeaderboardService) on the board screens in
-- workspace.Leaderboards (any part with a BoardId attribute; its Front face shows the board). Visual only.
-- Data: ReplicatedStorage.LeaderboardData.<BoardId> (JSON) + NextRefresh attribute; own score = player attribute LB_<BoardId>.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local L = require(RS:WaitForChild("LeaderboardConfig"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FONT = Enum.Font.FredokaOne
local NAVY = Color3.fromRGB(20, 40, 85)
local WHITE = Color3.fromRGB(255, 255, 255)
local SOFT = Color3.fromRGB(175, 200, 230)
local MEDAL = {Color3.fromRGB(255, 200, 60), Color3.fromRGB(210, 222, 236), Color3.fromRGB(226, 150, 92)}

local function fmt(board, v)
	v = tonumber(v) or 0
	if board.Id == "Playtime" then return L.FormatTime(v) end
	return NumberFormat.Abbreviate(v)
end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function label(parent, props)
	local t = new("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = WHITE, Text = ""}, parent)
	for k, v in pairs(props) do t[k] = v end
	return t
end
local function maxText(t, size) new("UITextSizeConstraint", {MaxTextSize = size}, t) end

--------------------------------------------------
-- one board screen
--------------------------------------------------
local function build(part, board)
	local gui = new("SurfaceGui", {
		Name = "Leaderboard_" .. board.Id, Adornee = part, Face = Enum.NormalId.Front, ResetOnSpawn = false,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 50, LightInfluence = 0,
		MaxDistance = 160, ClipsDescendants = true,
	}, nil)
	local root = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(24, 44, 84), BorderSizePixel = 0}, gui)
	new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 160, 185))}, root)

	label(root, {Name = "Title", Position = UDim2.fromScale(0.05, 0.03), Size = UDim2.fromScale(0.9, 0.09), Text = board.Icon .. " " .. board.Title})
	new("UIStroke", {Color = NAVY, Thickness = 3}, root.Title)
	local sub = label(root, {Name = "Sub", Position = UDim2.fromScale(0.05, 0.12), Size = UDim2.fromScale(0.9, 0.045), Text = board.Sub, TextColor3 = board.Accent})
	maxText(sub, 26)
	new("Frame", {Name = "Line", Position = UDim2.fromScale(0.06, 0.177), Size = UDim2.new(0.88, 0, 0, 3), BackgroundColor3 = board.Accent,
		BackgroundTransparency = 0.45, BorderSizePixel = 0}, root)

	local rows = {}
	for i = 1, L.Show do
		local row = new("Frame", {Name = "Row" .. i, Position = UDim2.fromScale(0.04, 0.192 + (i - 1) * 0.0645), Size = UDim2.fromScale(0.92, 0.058),
			BackgroundColor3 = WHITE, BackgroundTransparency = i % 2 == 1 and 0.91 or 0.95, BorderSizePixel = 0}, root)
		new("UICorner", {CornerRadius = UDim.new(0.3, 0)}, row)
		local stroke = new("UIStroke", {Color = board.Accent, Thickness = 2, Enabled = false}, row)
		local badge = new("Frame", {Name = "Badge", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.015, 0.5), Size = UDim2.fromScale(0.82, 0.82),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = MEDAL[i] or NAVY, BackgroundTransparency = MEDAL[i] and 0 or 1, BorderSizePixel = 0}, row)
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, badge)
		local rank = label(badge, {Size = UDim2.fromScale(1, 1), Text = tostring(i), TextColor3 = MEDAL[i] and NAVY or SOFT})
		new("UIPadding", {PaddingTop = UDim.new(0.14, 0), PaddingBottom = UDim.new(0.14, 0)}, rank)
		local face = new("ImageLabel", {Name = "Face", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.115, 0.5), Size = UDim2.fromScale(0.86, 0.86),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(60, 90, 140), BackgroundTransparency = 0.3, BorderSizePixel = 0}, row)
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, face)
		local name = label(row, {Name = "PlayerName", Position = UDim2.fromScale(0.225, 0.12), Size = UDim2.fromScale(0.46, 0.76), TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd})
		maxText(name, 26)
		local value = label(row, {Name = "Value", Position = UDim2.fromScale(0.68, 0.12), Size = UDim2.fromScale(0.3, 0.76), TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = board.Accent})
		maxText(value, 26)
		rows[i] = {frame = row, stroke = stroke, face = face, name = name, value = value}
	end
	local empty = label(root, {Name = "Empty", Position = UDim2.fromScale(0.1, 0.42), Size = UDim2.fromScale(0.8, 0.07), TextColor3 = SOFT, Visible = false})
	maxText(empty, 28)

	local you = new("Frame", {Name = "You", Position = UDim2.fromScale(0.04, 0.852), Size = UDim2.fromScale(0.92, 0.075), BackgroundColor3 = Color3.fromRGB(10, 22, 48),
		BackgroundTransparency = 0.25, BorderSizePixel = 0}, root)
	new("UICorner", {CornerRadius = UDim.new(0.3, 0)}, you)
	new("UIStroke", {Color = board.Accent, Thickness = 2, Transparency = 0.35}, you)
	local youRank = label(you, {Name = "Rank", Position = UDim2.fromScale(0.04, 0.16), Size = UDim2.fromScale(0.5, 0.68), TextXAlignment = Enum.TextXAlignment.Left})
	maxText(youRank, 28)
	local youValue = label(you, {Name = "Value", Position = UDim2.fromScale(0.5, 0.16), Size = UDim2.fromScale(0.46, 0.68), TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = board.Accent})
	maxText(youValue, 28)
	local foot = label(root, {Name = "Foot", Position = UDim2.fromScale(0.05, 0.937), Size = UDim2.fromScale(0.9, 0.04), TextColor3 = SOFT})
	maxText(foot, 20)

	gui.Parent = playerGui
	return {gui = gui, part = part, board = board, rows = rows, empty = empty, youRank = youRank, youValue = youValue, foot = foot}
end

--------------------------------------------------
-- data -> screens
--------------------------------------------------
local dataFolder = RS:WaitForChild("LeaderboardData")
local screens = {} -- [part] = screen
local cache = {}   -- [boardId] = decoded data

local function read(board)
	local v = dataFolder:FindFirstChild(board.Id)
	if not v then return {list = {}} end
	local ok, res = pcall(function() return HttpService:JSONDecode(v.Value) end)
	return ok and type(res) == "table" and res or {list = {}}
end

local function render(s)
	local board = s.board
	local data = cache[board.Id] or read(board)
	cache[board.Id] = data
	local list = type(data.list) == "table" and data.list or {}
	local mine
	for _, e in ipairs(list) do if e.u == player.UserId then mine = e end end
	for i, row in ipairs(s.rows) do
		local e = list[i]
		row.frame.Visible = e ~= nil
		if e then
			row.name.Text = tostring(e.n or ("Player " .. tostring(e.u)))
			row.value.Text = fmt(board, e.v)
			row.face.Image = (tonumber(e.u) or 0) > 0 and string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", e.u) or ""
			local me = e.u == player.UserId
			row.stroke.Enabled = me
			row.frame.BackgroundColor3 = me and board.Accent or WHITE
			row.frame.BackgroundTransparency = me and 0.7 or (i % 2 == 1 and 0.91 or 0.95)
		end
	end
	s.empty.Visible = #list == 0
	s.empty.Text = data.note or "No scores yet - be the first!"
	local own = tonumber(player:GetAttribute("LB_" .. board.Id)) or 0
	s.youRank.Text = mine and ("YOU  #" .. mine.r) or (own > 0 and #list >= L.Fetch and ("YOU  #" .. L.Fetch .. "+") or "YOU")
	s.youValue.Text = fmt(board, own)
end

local function renderAll(boardId)
	for _, s in pairs(screens) do
		if not boardId or s.board.Id == boardId then render(s) end
	end
end

local function footer()
	local nextAt = tonumber(dataFolder:GetAttribute("NextRefresh"))
	for _, s in pairs(screens) do
		local data = cache[s.board.Id]
		local left = nextAt and math.max(0, math.ceil(nextAt - workspace:GetServerTimeNow())) or nil
		local timer = left and (left > 0 and ("Updates in " .. left .. "s") or "Updating...") or ""
		s.foot.Text = (data and data.note and #(data.list or {}) > 0) and (data.note .. "  ·  " .. timer) or timer
	end
end

local function bind(part)
	if screens[part] or not part:IsA("BasePart") then return end
	local board = L.ById[part:GetAttribute("BoardId") or ""]
	if not board then return end
	local s = build(part, board)
	screens[part] = s
	render(s)
	part.AncestryChanged:Connect(function()
		if not part:IsDescendantOf(workspace) and screens[part] then
			screens[part].gui:Destroy()
			screens[part] = nil
		end
	end)
end

for _, v in ipairs(dataFolder:GetChildren()) do
	if v:IsA("StringValue") then v.Changed:Connect(function() cache[v.Name] = nil; renderAll(v.Name) end) end
end
dataFolder.ChildAdded:Connect(function(v)
	if v:IsA("StringValue") then v.Changed:Connect(function() cache[v.Name] = nil; renderAll(v.Name) end); cache[v.Name] = nil; renderAll(v.Name) end
end)
for _, b in ipairs(L.Boards) do
	player:GetAttributeChangedSignal("LB_" .. b.Id):Connect(function() renderAll(b.Id) end)
end

local function watch(root)
	for _, d in ipairs(root:GetDescendants()) do if d:GetAttribute("BoardId") then bind(d) end end
	root.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			if d:GetAttribute("BoardId") then bind(d) else task.defer(function() if d:GetAttribute("BoardId") then bind(d) end end) end
		end
	end)
end
local root = workspace:FindFirstChild("Leaderboards")
if root then watch(root) end
workspace.ChildAdded:Connect(function(c) if c.Name == "Leaderboards" then watch(c) end end)

while true do
	footer()
	task.wait(1)
end
