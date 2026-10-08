-- SnowFieldClient: builds the snow tiles locally and animates changes sent by the server.
-- Fields are STREAMED: only fields near you are built (a few hundred tiles per frame), far ones are removed.
-- The LOOK of the tiles comes from ReplicatedStorage > SnowStages > <Stage>:
--   Phase3 / Phase2 / Phase1 : Material, MaterialVariant, Color, Transparency, Reflectance, and HEIGHT (Size.Y)
--   Floor                    : the field floor (Size.Y = thickness)
--   Puff                     : particle emitters burst on every scrape (attribute EmitCount per emitter)
--   folder attributes        : Gap, HeightJitter
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SF = require(ReplicatedStorage:WaitForChild("SnowFields"))
local updateEvent = ReplicatedStorage:WaitForChild("SnowFieldUpdate")
local syncFunc = ReplicatedStorage:WaitForChild("SnowFieldSync")
local collectedEvent = ReplicatedStorage:WaitForChild("SnowCollected")
local stylesFolder = ReplicatedStorage:WaitForChild("SnowStages")
local player = Players.LocalPlayer
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))

local TS = SF.TileSize
local BUILD_DISTANCE = 170     -- build a field when you're this close to its edge
local UNLOAD_DISTANCE = 240    -- remove it when you're this far
local TILES_PER_FRAME = 250    -- spread building over frames (no stutter)

local root = Instance.new("Folder")
root.Name = "SnowFieldsVisual"
root.Parent = workspace

local function lockDown(p)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end

--------------------------------------------------
-- STYLES
--------------------------------------------------
local styleCache = {}
local function getStyle(name)
	if styleCache[name] then return styleCache[name] end
	local s = stylesFolder:FindFirstChild(name or "Starter") or stylesFolder:WaitForChild("Starter")
	local st = {
		phases = {},
		floor = s:FindFirstChild("Floor"),
		puff = s:FindFirstChild("Puff"),
		gap = s:GetAttribute("Gap") or 0.15,
		jitter = s:GetAttribute("HeightJitter") or 0.18,
	}
	for p = 1, SF.MaxPhase do st.phases[p] = s:WaitForChild("Phase" .. p) end
	styleCache[name] = st
	return st
end

--------------------------------------------------
-- FIELD DATA (always kept) + VISUALS (only when near)
--------------------------------------------------
local fields = {}
for _, f in ipairs(SF.Fields) do
	local n = f.Width * f.Depth
	local fd = {def = f, style = getStyle(f.Style or "Starter"), phases = table.create(n, SF.MaxPhase), hp = table.create(n, 100),
		jitter = {}, built = false, building = false}
	for i = 1, n do fd.jitter[i] = (math.random() - 0.5) * fd.style.jitter end
	local o = SF.Origin(f)
	fd.minX, fd.minZ = o.X, o.Z
	fd.maxX, fd.maxZ = o.X + f.Width * TS, o.Z + f.Depth * TS
	fields[f.Id] = fd
end

local function heightOf(style, p, jitter)
	if p <= 0 then return 0.1 end
	return style.phases[p].Size.Y + jitter
end

local function tileCenter(fd, i)
	local f = fd.def
	local x = (i - 1) % f.Width
	local z = (i - 1) // f.Width
	return SF.TileCenter(f, x, z)
end

local function apply(fd, i, p, animate, growing)
	local part = fd.parts[i]
	if not part then return end
	local style = fd.style
	local h = heightOf(style, p, fd.jitter[i])
	if p > 0 then
		-- damaged layers sink toward the layer below (100% HP = full height)
		local lower = p > 1 and heightOf(style, p - 1, fd.jitter[i]) or 0.1
		local frac = (fd.hp[i] or 100) / 100
		h = lower + (h - lower) * (0.3 + 0.7 * frac)
	end
	local tp = style.phases[math.max(p, 1)]
	part.Material = tp.Material
	part.MaterialVariant = tp.MaterialVariant
	part.Reflectance = tp.Reflectance
	local g = {
		Size = Vector3.new(TS - style.gap, h, TS - style.gap),
		CFrame = CFrame.new(fd.centers[i] + Vector3.new(0, fd.floorTop + h / 2, 0)),
		Color = tp.Color,
		Transparency = p <= 0 and 1 or tp.Transparency,
	}
	if animate then
		local info = growing and TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			or TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(part, info, g):Play()
	else
		for k, v in pairs(g) do part[k] = v end
	end
end

local function puff(fd, pos, big)
	if not fd.puff then return end
	fd.puff.CFrame = CFrame.new(pos)
	for _, e in ipairs(fd.puff:GetChildren()) do
		if e:IsA("ParticleEmitter") then
			local n = e:GetAttribute("EmitCount") or 2
			e:Emit(big and n + 1 or n)
		end
	end
end

local function hitPuff(fd, pos)
	if not fd.puff then return end
	fd.puff.CFrame = CFrame.new(pos)
	for _, e in ipairs(fd.puff:GetChildren()) do
		if e:IsA("ParticleEmitter") then e:Emit(1) end
	end
end

local function buildVisual(fd)
	if fd.built or fd.building then return end
	fd.building = true
	local f, style = fd.def, fd.style
	local folder = Instance.new("Folder")
	folder.Name = f.Id
	fd.folder = folder
	fd.floorTop = 0
	if style.floor then
		local floor = style.floor:Clone()
		floor.Name = "FieldFloor"
		lockDown(floor)
		floor.Size = Vector3.new(f.Width * TS + 0.8, style.floor.Size.Y, f.Depth * TS + 0.8)
		floor.CFrame = CFrame.new(f.Center + Vector3.new(0, style.floor.Size.Y / 2, 0))
		floor.Parent = folder
		fd.floorTop = style.floor.Size.Y
	end
	if style.puff then
		fd.puff = style.puff:Clone()
		lockDown(fd.puff)
		fd.puff.Transparency = 1
		fd.puff.Parent = folder
	end
	fd.parts, fd.centers = {}, {}
	folder.Parent = root
	local base = style.phases[SF.MaxPhase]
	local n = f.Width * f.Depth
	for i = 1, n do
		if not fd.building then return end -- unloaded while building
		local part = base:Clone()
		part.Name = "Snow"
		lockDown(part)
		part.CastShadow = false
		fd.centers[i] = tileCenter(fd, i)
		fd.parts[i] = part
		apply(fd, i, fd.phases[i], false)
		part.Parent = folder
		if i % TILES_PER_FRAME == 0 then task.wait() end
	end
	fd.building = false
	fd.built = true
end

local function destroyVisual(fd)
	fd.building = false
	fd.built = false
	if fd.folder then fd.folder:Destroy() end
	fd.folder, fd.parts, fd.centers, fd.puff = nil, nil, nil, nil
end

-- server updates: always update the data, animate only if the field is built
updateEvent.OnClientEvent:Connect(function(id, flat)
	local fd = fields[id]
	if not fd then return end
	for j = 1, #flat, 3 do
		local i, p, hp = flat[j], flat[j + 1], flat[j + 2]
		local old, oldHp = fd.phases[i], fd.hp[i]
		if old and (p ~= old or hp ~= oldHp) then
			fd.phases[i] = p
			fd.hp[i] = hp
			if fd.built then
				apply(fd, i, p, true, p > old)
				local top = fd.centers[i] + Vector3.new(0, fd.floorTop + heightOf(fd.style, math.max(old, 1), 0), 0)
				if p < old then
					puff(fd, top, old == SF.MaxPhase)      -- layer broke
				elseif p == old and hp < oldHp then
					hitPuff(fd, top)                       -- just damaged
				end
			end
		end
	end
end)

-- initial state
task.spawn(function()
	for _ = 1, 10 do
		local ok, res = pcall(function() return syncFunc:InvokeServer() end)
		if ok and type(res) == "table" then
			for id, data in pairs(res) do
				local fd = fields[id]
				if fd and type(data) == "table" then
					local str = data.p or ""
					for i = 1, #str do
						local p = tonumber(str:sub(i, i))
						if p then
							fd.phases[i] = p
							fd.hp[i] = data.h and data.h[i] or 100
							if fd.built then apply(fd, i, p, false) end
						end
					end
				end
			end
			return
		end
		task.wait(1)
	end
end)

-- streaming loop
task.spawn(function()
	while true do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local pos = hrp and hrp.Position or workspace.CurrentCamera.CFrame.Position
		for _, fd in pairs(fields) do
			local dx = math.max(fd.minX - pos.X, 0, pos.X - fd.maxX)
			local dz = math.max(fd.minZ - pos.Z, 0, pos.Z - fd.maxZ)
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist < BUILD_DISTANCE and not fd.built and not fd.building then
				task.spawn(buildVisual, fd)
			elseif dist > UNLOAD_DISTANCE and (fd.built or fd.building) then
				destroyVisual(fd)
			end
		end
		task.wait(0.5)
	end
end)

--------------------------------------------------
-- "+N" POPUPS
--------------------------------------------------
local FONT = Enum.Font.FredokaOne
collectedEvent.OnClientEvent:Connect(function(amount)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(3.2, 1.3)
	bb.StudsOffset = Vector3.new((math.random() - 0.5) * 3, 3, 0)
	bb.AlwaysOnTop = false -- 2026-10-04 (Claude): AlwaysOnTop billboards don't render here
	bb.LightInfluence = 0
	bb.Adornee = hrp
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = FONT
	l.TextScaled = true
	l.Text = "+" .. NumberFormat.Abbreviate(amount)
	l.Size = UDim2.fromScale(0.7, 1)
	l.TextXAlignment = Enum.TextXAlignment.Right
	local ico = Instance.new("ImageLabel")
	ico.BackgroundTransparency = 1
	ico.Image = "rbxassetid://83244601927288"
	ico.Position = UDim2.fromScale(0.72, 0)
	ico.Size = UDim2.fromScale(0.3, 1)
	ico.ScaleType = Enum.ScaleType.Fit
	ico.Parent = bb
	TweenService:Create(ico, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.3), {ImageTransparency = 1}):Play()
	l.TextColor3 = Color3.new(1, 1, 1)
	local st = Instance.new("UIStroke")
	st.Thickness = 2.5
	st.Color = Color3.fromRGB(40, 110, 200)
	st.Parent = l
	l.Parent = bb
	bb.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(bb, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{StudsOffset = bb.StudsOffset + Vector3.new(0, 2.5, 0)}):Play()
	TweenService:Create(l, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.3),
		{TextTransparency = 1}):Play()
	TweenService:Create(st, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.3),
		{Transparency = 1}):Play()
	task.delay(0.9, function() bb:Destroy() end)
end)

--------------------------------------------------
-- HUD COUNTER
--------------------------------------------------
local comma = NumberFormat.Abbreviate -- 1.1K, 2.5M, 3.4B, 1.2T ...

task.spawn(function()
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("RNGGui"):WaitForChild("SnowCounter")
	local label = hud:WaitForChild("Amount")
	local scale = hud:FindFirstChildOfClass("UIScale")
	local stat = player:WaitForChild("leaderstats"):WaitForChild("Snow")
	label.Text = comma(stat.Value)
	stat.Changed:Connect(function(v)
		label.Text = comma(v)
		if scale then
			scale.Scale = 1.12
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
		end
	end)
end)
