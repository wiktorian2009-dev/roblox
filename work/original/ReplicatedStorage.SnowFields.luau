-- SNOW FIELDS
-- Fields are placed in Studio as boxes inside Workspace > SnowFieldZones.
--   * Move / resize the box: the bottom of the box is the ground level of the field.
--   * Size is snapped to whole tiles (TileSize studs). Turning a box by 90 degrees works; other angles are snapped to the grid.
--   * Attribute "Stage" on the box = a folder in ReplicatedStorage > SnowStages (look + values).
--   * Optional overrides on the box: DisplayName, SnowPerPhase, RegrowSeconds, TileHP.
-- When the game starts the server reads the boxes, removes them, and shares the field data with clients.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnowFields = {}

SnowFields.TileSize = 3
SnowFields.MaxPhase = 3
-- tile look & heights come from ReplicatedStorage > SnowFieldStyles
SnowFields.Spinner = {Speed = 7, Inner = 1.0, Outer = 5.3} -- Speed MUST match the visual spin
SnowFields.Defaults = {SnowPerPhase = 1, RegrowSeconds = 8, TileHP = 1}

function SnowFields.Origin(f)
	local ts = SnowFields.TileSize
	return f.Center - Vector3.new(f.Width * ts / 2, 0, f.Depth * ts / 2)
end

function SnowFields.TileCenter(f, x, z)
	local ts = SnowFields.TileSize
	return SnowFields.Origin(f) + Vector3.new((x + 0.5) * ts, 0, (z + 0.5) * ts)
end

local function readZones()
	local list, used = {}, {}
	local zones = workspace:FindFirstChild("SnowFieldZones")
	if not zones then return list end
	local ts = SnowFields.TileSize
	for i, z in ipairs(zones:GetChildren()) do
		if z:IsA("BasePart") then
			local stageName = z:GetAttribute("Stage") or z:GetAttribute("Style") or "Starter"
			local stages = ReplicatedStorage:FindFirstChild("SnowStages")
			local stage = stages and stages:FindFirstChild(stageName)
			if not stage then
				warn("[SnowFields] Field '" .. z.Name .. "' uses unknown Stage '" .. stageName .. "', using Starter")
				stageName = "Starter"
				stage = stages and stages:FindFirstChild("Starter")
			end
			-- box attribute wins, then the stage folder, then the default
			local function pick(attr)
				local v = z:GetAttribute(attr)
				if v == nil and stage then v = stage:GetAttribute(attr) end
				return v
			end
			local id = z.Name
			if used[id] then id = id .. "_" .. i end
			used[id] = true
			table.insert(list, {
				Id = id,
				Name = pick("DisplayName") or z.Name,
				Center = Vector3.new(z.Position.X, z.Position.Y - z.Size.Y / 2, z.Position.Z),
				-- boxes turned 90/270 degrees: swap width and depth so the field matches what you see
				Width = math.max(1, math.floor(((math.abs(math.floor(z.Orientation.Y + 0.5)) % 180 == 90) and z.Size.Z or z.Size.X) / ts + 0.5)),
				Depth = math.max(1, math.floor(((math.abs(math.floor(z.Orientation.Y + 0.5)) % 180 == 90) and z.Size.X or z.Size.Z) / ts + 0.5)),
				SnowPerPhase = pick("SnowPerPhase") or SnowFields.Defaults.SnowPerPhase,
				RegrowSeconds = pick("RegrowSeconds") or SnowFields.Defaults.RegrowSeconds,
				TileHP = pick("TileHP") or SnowFields.Defaults.TileHP,
				Style = stageName,
			})
		end
	end
	return list
end

if RunService:IsServer() then
	SnowFields.Fields = readZones()
	if RunService:IsRunning() and #SnowFields.Fields == 0 then
		warn("[SnowFields] No snow fields found. Put boxes in Workspace > SnowFieldZones (and keep their Archivable property ON).")
	end
	if RunService:IsRunning() then
		local folder = Instance.new("Folder")
		folder.Name = "SnowFieldData"
		for _, f in ipairs(SnowFields.Fields) do
			local c = Instance.new("Configuration")
			c.Name = f.Id
			for k, v in pairs(f) do c:SetAttribute(k, v) end
			c.Parent = folder
		end
		folder.Parent = ReplicatedStorage
		local zones = workspace:FindFirstChild("SnowFieldZones")
		if zones then zones:Destroy() end
	end
else
	SnowFields.Fields = {}
	local folder = ReplicatedStorage:WaitForChild("SnowFieldData")
	for _, c in ipairs(folder:GetChildren()) do
		table.insert(SnowFields.Fields, c:GetAttributes())
	end
end

return SnowFields

