-- ShovelOrbit: renders every player's equipped shovels orbiting around them.
-- Which shovels a player has comes from the server (player attribute "EquippedShovels").
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local templates = ReplicatedStorage:WaitForChild("ShovelModels")
local localPlayer = Players.LocalPlayer
local Spinner = require(ReplicatedStorage:WaitForChild("SnowFields")).Spinner

-- hide Roblox's default hotbar / backpack
task.spawn(function()
	for _ = 1, 10 do
		if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end) then break end
		task.wait(0.5)
	end
end)

local INNER = 1.6        -- gap between the player's center and the shovel grips (the "hub")
local HEIGHT = -0.2      -- height of the spinner relative to the player's center (waist)
local SPEED = Spinner.Speed -- spin speed (radians / second), shared with the server's scraping
local SCALE = 0.8        -- size of the shovels
local TILT = 8           -- degrees the arms tilt up at the tips (0 = perfectly flat)
local GRIP_FROM_PIVOT = 1.8 * SCALE   -- distance from the shovel's pivot (shaft middle) to the top of its grip
local VIEW_DISTANCE = 220

local folder = Instance.new("Folder")
folder.Name = "OrbitingShovels"
folder.Parent = workspace

local rigs = {} -- [player] = {shovels = {{model=, shown=}}}

local function clear(player)
	local r = rigs[player]
	if r then
		for _, s in ipairs(r.shovels) do s.model:Destroy() end
	end
	rigs[player] = nil
end

local function build(player)
	clear(player)
	local attr = player:GetAttribute("EquippedShovels") or ""
	local r = {shovels = {}}
	for name in attr:gmatch("[^,]+") do
		local t = templates:FindFirstChild(name) or templates:FindFirstChild("_Placeholder") -- placeholder until it has its own 3D model
		if t then
			local m = t:Clone()
			m:ScaleTo(SCALE)
			-- outlines only on your own shovels (Roblox limits how many outlines can show)
			if player ~= localPlayer then
				local h = m:FindFirstChildOfClass("Highlight")
				if h then h:Destroy() end
			end
			m.Parent = folder
			table.insert(r.shovels, {model = m, shown = true})
		end
	end
	rigs[player] = r
end

local function track(player)
	player:GetAttributeChangedSignal("EquippedShovels"):Connect(function() build(player) end)
	build(player)
end
Players.PlayerAdded:Connect(track)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(track, p) end
Players.PlayerRemoving:Connect(clear)

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local now = workspace:GetServerTimeNow()
	local camPos = workspace.CurrentCamera.CFrame.Position
	for player, r in pairs(rigs) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local visible = root ~= nil and (root.Position - camPos).Magnitude < VIEW_DISTANCE
		local n = #r.shovels
		for i, s in ipairs(r.shovels) do
			if not visible then
				if s.shown then s.model.Parent = nil; s.shown = false end
			else
				if not s.shown then s.model.Parent = folder; s.shown = true end
				-- fidget spinner: every shovel is a spoke, grip toward the player, blade pointing out
				local ang = now * SPEED * (player:GetAttribute("SpinMult") or 1) + (i - 1) * (2 * math.pi / n) + (player.UserId % 7)
				local out = Vector3.new(math.cos(ang), math.sin(math.rad(TILT)), math.sin(ang)).Unit
				local up = Vector3.new(0, 1, 0)
				local yAxis = -out                       -- shovel's +Y (grip) points at the hub
				local xAxis = yAxis:Cross(up).Unit       -- sideways, so the blade lies flat
				local zAxis = xAxis:Cross(yAxis)         -- blade face points up
				local center = root.Position + Vector3.new(0, HEIGHT, 0)
				local pos = center + out * (INNER + GRIP_FROM_PIVOT) * (player:GetAttribute("ReachMult") or 1)
				s.model:PivotTo(CFrame.fromMatrix(pos, xAxis, yAxis, zAxis))
			end
		end
	end
end)

