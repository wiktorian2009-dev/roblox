-- build_boards.luau (2026-10-09, Claude): builds workspace.Leaderboards (3 snowy wooden boards) in EDIT mode.
-- Run in the Studio command bar / MCP execute_luau (Edit). Safe to re-run: an existing workspace.Leaderboards is moved to
-- ServerStorage.LeaderboardsBackup_<date> first (never deleted).
-- The boards are one Persistent model (always streamed in); each board's "Screen" part carries BoardId for LeaderboardClient.
-- Move the whole set with workspace.Leaderboards:PivotTo(cf) (the pivot is the ground point in front-centre; LookVector = the
-- direction the screens face).
-- 2026-10-09 run: built here as ServerStorage.Leaderboards (staged), then ../HubRing20261009/after_apply.luau placed it in the
-- hub ring's west gap at (-236, 0.14, -282) facing the lobby centre. The PIVOT below is only the build position.
local PIVOT = CFrame.lookAt(Vector3.new(-184, 0.24, -282), Vector3.new(-160, 0.24, -282))

local SS = game:GetService("ServerStorage")
local old = workspace:FindFirstChild("Leaderboards")
if old then
	local bk = SS:FindFirstChild("LeaderboardsBackup_20261009") or Instance.new("Folder")
	bk.Name = "LeaderboardsBackup_20261009"; bk.Parent = SS
	old.Parent = bk
end

local WOOD = Color3.fromRGB(122, 84, 56)
local WOOD_DARK = Color3.fromRGB(92, 62, 42)
local SNOW = Color3.fromRGB(246, 250, 255)
local SCREEN = Color3.fromRGB(24, 44, 84)

local function part(model, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = model
	return p
end

-- one board, built around its own ground point; front (screen) faces the board CFrame's LookVector
local function board(id, cf)
	local m = Instance.new("Model")
	m.Name = "Board_" .. id
	local W, H, BASE = 10, 13, 2.2 -- screen width / height / height of the screen's lower edge
	local cy = BASE + H / 2
	local screen = part(m, "Screen", Vector3.new(W, H, 0.4), cf * CFrame.new(0, cy, 0), SCREEN)
	screen:SetAttribute("BoardId", id)
	part(m, "Back", Vector3.new(W + 0.6, H + 0.6, 0.25), cf * CFrame.new(0, cy, 0.32), WOOD_DARK, Enum.Material.Wood)
	for _, sx in ipairs({-1, 1}) do
		part(m, "Post", Vector3.new(0.8, H + BASE + 0.9, 0.9), cf * CFrame.new(sx * (W / 2 + 0.4), (H + BASE + 0.9) / 2, 0.05), WOOD, Enum.Material.Wood)
		part(m, "PostCap", Vector3.new(1.1, 1.1, 1.1), cf * CFrame.new(sx * (W / 2 + 0.4), H + BASE + 1.05, 0.05), SNOW, Enum.Material.Snow,
			{Shape = Enum.PartType.Ball, CanCollide = false})
		part(m, "Drift", Vector3.new(2.6, 1.1, 2.3), cf * CFrame.new(sx * (W / 2 + 0.4), 0.15, 0.05), SNOW, Enum.Material.Snow,
			{Shape = Enum.PartType.Ball, CanCollide = false})
	end
	part(m, "Top", Vector3.new(W, 0.5, 0.8), cf * CFrame.new(0, BASE + H + 0.25, 0.05), WOOD, Enum.Material.Wood)
	part(m, "Bottom", Vector3.new(W, 0.5, 0.8), cf * CFrame.new(0, BASE - 0.25, 0.05), WOOD, Enum.Material.Wood)
	-- a soft roll of snow along the top (cylinder axis = X)
	part(m, "SnowCap", Vector3.new(W + 0.4, 0.9, 1.0), cf * CFrame.new(0, BASE + H + 0.75, 0.05), SNOW, Enum.Material.Snow,
		{Shape = Enum.PartType.Cylinder, CanCollide = false})
	m.PrimaryPart = screen
	m.WorldPivot = cf
	return m
end

local root = Instance.new("Model")
root.Name = "Leaderboards"
root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
-- middle board = Snow; the other two angle in a little toward the viewer
local layout = {
	{id = "Snow", cf = CFrame.new(0, 0, 0)},
	{id = "ArenaKOs", cf = CFrame.new(12.6, 0, 1.6) * CFrame.Angles(0, math.rad(14), 0)},
	{id = "Playtime", cf = CFrame.new(-12.6, 0, 1.6) * CFrame.Angles(0, math.rad(-14), 0)},
}
for _, b in ipairs(layout) do board(b.id, PIVOT * b.cf).Parent = root end
root.WorldPivot = PIVOT
root:SetAttribute("Built", "2026-10-09 build_boards.luau")
root.Parent = SS -- staged; after_apply.luau (HubRing20261009) moves it into workspace
return "built " .. #root:GetChildren() .. " boards (staged in ServerStorage)"
