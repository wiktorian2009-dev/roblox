-- TrailerPuppets (2026-10-06, Claude): client-local stand-ins for shots the real plow cannot reach in time (DESIGN rev 2, section 7).
-- A puppet is PlowAssembly.Build(explicit part ids) stripped to anchored visuals (no collisions / queries / touches, scripts and
-- sounds removed, seats disabled), moved by CFrame only (no physics, no velocity writes), pivoted at the ground-level root like the
-- real plow. The driver is a clone of the server-made blank R15 rig (ReplicatedStorage.TrailerRuntime.DriverRig) posed with the
-- local character's own sit animation. Motion: a recorded reference track (TrailerRefs) or the build's kinematic profile.
-- Puppet minis (shot 10 fallback) reuse MiniPlowClient's closed lawnmower loop and pose maths. No side effects at require time.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local P = {}
P.__index = P

local Math
function P.Init(math) Math = math end

local function folder()
	local f = workspace:FindFirstChild("TrailerPuppets")
	if not f then
		f = Instance.new("Folder")
		f.Name = "TrailerPuppets"
		f.Parent = workspace
	end
	return f
end
P.Folder = folder

local function strip(m, castShadow)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery, d.CastShadow = true, false, false, false, castShadow
			if d:IsA("Seat") or d:IsA("VehicleSeat") then d.Disabled = true end
		end
	end
end

-- ground rays ignore every plow, pet, mini, puppet and character
function P.RayParams(extra)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local list = {folder()}
	for _, n in ipairs({"Snowplows", "FollowingPets", "MiniPlows"}) do
		local x = workspace:FindFirstChild(n)
		if x then table.insert(list, x) end
	end
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(list, pl.Character) end end
	for _, x in ipairs(extra or {}) do table.insert(list, x) end
	rp.FilterDescendantsInstances = list
	rp.RespectCanCollide = true
	return rp
end
function P.Ground(pos, rp, fallbackY)
	-- critic fix: from 8 studs above (not 60), so arches, roofs and props overhead are never taken for the ground
	local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 8, pos.Z), Vector3.new(0, -200, 0), rp)
	if hit then return hit.Position.Y end
	return fallbackY
end
-- ground-level root at a flat position, pitched by the front / rear axle hits (section 7.3)
function P.GroundCF(pos, heading, rp, axle)
	axle = axle or 3.1
	local y0 = P.Ground(pos, rp, pos.Y)
	local f, r = pos + heading * axle, pos - heading * axle
	local yf, yr = P.Ground(Vector3.new(f.X, y0, f.Z), rp, y0), P.Ground(Vector3.new(r.X, y0, r.Z), rp, y0)
	local front, rear = Vector3.new(f.X, yf, f.Z), Vector3.new(r.X, yr, r.Z)
	local mid = (front + rear) / 2
	local fwd = front - rear
	if fwd.Magnitude < 1e-3 then fwd = heading end
	return CFrame.lookAt(mid, mid + fwd.Unit)
end

local function sitAnimationId()
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	local animate = char and char:FindFirstChild("Animate")
	local sit = animate and animate:FindFirstChild("sit")
	local anim = sit and (sit:FindFirstChild("SitAnim") or sit:FindFirstChildOfClass("Animation"))
	return anim and anim:IsA("Animation") and anim.AnimationId ~= "" and anim.AnimationId or nil
end

--------------------------------------------------------------------------------------------------------------------------------
-- puppet plow
--------------------------------------------------------------------------------------------------------------------------------
function P.New(name, build, seatWeld, ToCFrame)
	local Assembly = require(RS:WaitForChild("PlowAssembly"))
	local ok, m = pcall(Assembly.Build, build)
	if not ok or not m then return nil, "PlowAssembly.Build failed: " .. tostring(m) end
	strip(m, true)
	m.Name = "TrailerPuppet_" .. name
	local self = setmetatable({name = name, model = m, seatRel = m:GetAttribute("SeatPos") or CFrame.new(0, 3, 1), shown = false}, P)
	local c0 = seatWeld and ToCFrame and ToCFrame(seatWeld.C0)
	local c1 = seatWeld and ToCFrame and ToCFrame(seatWeld.C1)
	self.seatOffset = (c0 and c1) and (c0 * c1:Inverse()) or CFrame.new(0, 1.8, 0) -- fallback until round 1 records the SeatWeld
	self.seatWeldRecorded = c0 ~= nil and c1 ~= nil
	self:BuildDriver()
	return self
end

function P:BuildDriver()
	local rt = RS:FindFirstChild("TrailerRuntime")
	local rig = rt and rt:FindFirstChild("DriverRig")
	if not rig then return end
	local d = rig:Clone()
	d.Name = "TrailerPuppet_" .. self.name .. "_Driver"
	local hrp = d:FindFirstChild("HumanoidRootPart")
	local hum = d:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then d:Destroy() return end
	for _, x in ipairs(d:GetDescendants()) do
		if x:IsA("LuaSourceContainer") or x:IsA("Sound") then
			x:Destroy()
		elseif x:IsA("BasePart") then
			-- the root is anchored and moved by CFrame; limbs hang on their Motor6Ds so the sit animation can pose them
			x.CanCollide, x.CanTouch, x.CanQuery, x.Massless = false, false, false, true
			x.Anchored = x == hrp
		end
	end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.NameDisplayDistance = 0
	pcall(function() hum.EvaluateStateMachine = false end)
	if not hum:FindFirstChildOfClass("Animator") then Instance.new("Animator").Parent = hum end
	self.driver, self.hrp, self.hum = d, hrp, hum
end

function P:PlaySit()
	if self.sitTrack or not self.hum then return end
	local id = sitAnimationId()
	if not id then return end
	local animator = self.hum:FindFirstChildOfClass("Animator")
	local a = Instance.new("Animation")
	a.AnimationId = id
	local ok, track = pcall(function() return animator:LoadAnimation(a) end)
	if ok and track then
		track.Looped = true
		track:Play(0)
		self.sitTrack = track
	end
end

function P:Show(on)
	if on == self.shown then return end
	self.shown = on
	local f = on and folder() or nil
	self.model.Parent = f
	if self.driver then self.driver.Parent = f end
	if on then self:PlaySit() end
end

function P:Place(rootCF)
	self.model:PivotTo(rootCF)
	if self.hrp then
		local pp = self.model.PrimaryPart
		local seatCF = (pp and pp.CFrame or rootCF) * self.seatRel * CFrame.new(0, -0.3, 0) -- PlowService L228, L244
		self.hrp.CFrame = seatCF * self.seatOffset
	end
end

-- def: shot.puppet; ctx = {from = Vector3, to = Vector3, stats = {MaxSpeed, Accel}, brakeFactor, brakeShare, track, kinematic,
-- rp = RaycastParams, axle}. Returns fn(tau) -> rootCF, and the motion source ("reference" / "kinematic") or nil + reason.
function P:Motion(def, ctx)
	local from, to = Math.flat(ctx.from), Math.flat(ctx.to)
	local dir = Math.flatUnit(to - from)
	local D = (to - from).Magnitude
	local heading = dir
	if def.heading and Math.flatUnit(def.heading):Dot(dir) > math.cos(math.rad(12)) then heading = Math.flatUnit(def.heading) end
	local rp, axle = ctx.rp, ctx.axle
	local y0 = ctx.to.Y
	local anchorT = def.kind == "stop" and def.stop or def.exit
	local track = ctx.track
	if track and type(track.frames) == "table" and #track.frames >= 2 then
		local frames, hz = track.frames, track.hz or 30
		local anchor = math.clamp(math.floor(tonumber(track.anchor) or #frames), 1, #frames)
		local anchorCF = P.GroundCF(Vector3.new(to.X, y0, to.Z), heading, rp, axle)
		return function(tau)
			local f = math.clamp(anchor + (tau - anchorT) * hz, 1, #frames)
			local i = math.floor(f)
			local k = f - i
			local a, b = frames[i], frames[math.min(i + 1, #frames)]
			local yaw = a[4] + Math.wrap(b[4] - a[4]) * k
			return anchorCF * CFrame.new(Math.lerp(a[1], b[1], k), Math.lerp(a[2], b[2], k), Math.lerp(a[3], b[3], k)) * CFrame.Angles(0, yaw, 0)
		end, "reference"
	end
	if not ctx.kinematic then return nil, "no reference track and kinematic profile disabled" end
	if def.kind == "stop" then
		local b = ctx.stats.Accel * ctx.brakeFactor * ctx.brakeShare
		local T = def.stop - def.enter
		local vc = Math.cruiseThenBrake(D, T, b) or math.sqrt(2 * b * D)
		vc = math.min(vc, ctx.stats.MaxSpeed)
		local dBrake = vc * vc / (2 * b)
		local tb = def.stop - vc / b
		return function(tau)
			local left
			if tau >= def.stop then left = 0
			elseif tau >= tb then local e = def.stop - tau; left = 0.5 * b * e * e
			else left = dBrake + vc * (tb - tau) end
			local pos = to - dir * left
			return P.GroundCF(Vector3.new(pos.X, y0, pos.Z), tau >= def.stop and heading or dir, rp, axle)
		end, "kinematic"
	end
	local v = D / math.max(def.exit - def.enter, 0.1)
	return function(tau)
		local pos = from + dir * (v * (tau - def.enter))
		return P.GroundCF(Vector3.new(pos.X, y0, pos.Z), dir, rp, axle)
	end, "kinematic"
end

function P:Destroy()
	if self.sitTrack then pcall(function() self.sitTrack:Stop(0) end) end
	if self.model then self.model:Destroy() end
	if self.driver then self.driver:Destroy() end
	self.model, self.driver = nil, nil
end

--------------------------------------------------------------------------------------------------------------------------------
-- puppet minis (shot 10 fallback, section 7.4): MiniPlowClient's route(fd) / pose(f, i, n, t) (L290-340) on a field record
--------------------------------------------------------------------------------------------------------------------------------
local Minis = {}
Minis.__index = Minis

function P.NewMinis(build, n, rec)
	local C = require(RS:WaitForChild("PlowConfig"))
	local SF = require(RS:WaitForChild("SnowFields"))
	local Assembly = require(RS:WaitForChild("PlowAssembly"))
	local M = C.Minis
	local ok, tpl = pcall(Assembly.Build, build)
	if not ok or not tpl then return nil, "PlowAssembly.Build failed" end
	strip(tpl, false)
	for _, d in ipairs(tpl:GetDescendants()) do
		if d:IsA("Seat") or d:IsA("VehicleSeat") then d.Transparency = 1 end
	end
	if not tpl.PrimaryPart then tpl.PrimaryPart = tpl:FindFirstChildWhichIsA("BasePart", true) end
	pcall(function() tpl:ScaleTo(M.Scale) end)
	local self = setmetatable({models = {}, shown = false, M = M}, Minis)
	for i = 1, n do
		local m = tpl:Clone()
		m.Name = "TrailerPuppetMini_" .. i
		self.models[i] = m
	end
	tpl:Destroy()
	-- route (copy of MiniPlowClient route(), closed lawnmower loop)
	local ts, inset = SF.TileSize, 3
	local W, D = rec.Width * ts, rec.Depth * ts
	local span = math.max(0, D - inset * 2)
	local lanes = math.max(2, math.floor(span / M.LaneGap) + 1)
	if lanes % 2 == 1 then lanes -= 1 end
	local gap = span / (lanes - 1)
	local order = {}
	for l = 0, lanes - 1, 2 do table.insert(order, l) end
	for l = lanes - 1, 1, -2 do table.insert(order, l) end
	local x0, x1 = math.min(inset, W / 2), math.max(W - inset, W / 2)
	local len = x1 - x0
	local legs, total = {}, 0
	for i, l in ipairs(order) do
		local z = inset + l * gap
		local zn = inset + order[i % #order + 1] * gap
		local dz = zn - z
		local turn = math.pi * math.abs(dz) / 2
		table.insert(legs, {z = z, dz = dz, dir = (i % 2 == 1) and 1 or -1, len = len, turn = turn, start = total})
		total += len + turn
	end
	-- snow top (MiniPlowClient snowTop): ground + Floor + Phase3 heights of the stage
	local stages = RS:FindFirstChild("SnowStages")
	local st = stages and (stages:FindFirstChild(rec.Style or "Starter") or stages:FindFirstChild("Starter"))
	local floor, p3 = st and st:FindFirstChild("Floor"), st and st:FindFirstChild("Phase3")
	local h = (floor and not rec.NoFloor and floor.Size.Y or 0) + (p3 and p3.Size.Y or 1.6)
	local o = rec.Center - Vector3.new(W / 2, 0, D / 2)
	self.route = {legs = legs, total = math.max(total, 1), x0 = x0, x1 = x1, o = o, y = o.Y + h + M.Hover}
	return self
end

function Minis:Pose(i, n, t)
	local r = self.route
	local s = (t * self.M.Speed + (i - 1) / n * r.total) % r.total
	local leg = r.legs[#r.legs]
	for _, g in ipairs(r.legs) do if s < g.start + g.len + g.turn then leg = g break end end
	local u = s - leg.start
	local x, z, hx, hz
	if u <= leg.len then
		x = leg.dir == 1 and (r.x0 + u) or (r.x1 - u)
		z, hx, hz = leg.z, leg.dir, 0
	else
		local a = math.clamp((u - leg.len) / math.max(leg.turn, 1e-6), 0, 1) * math.pi
		local rad = math.abs(leg.dz) / 2
		local sz = leg.dz >= 0 and 1 or -1
		local cx = leg.dir == 1 and r.x1 or r.x0
		x = cx + leg.dir * math.sin(a) * rad
		z = leg.z + sz * (1 - math.cos(a)) * rad
		hx, hz = leg.dir * math.cos(a), sz * math.sin(a)
	end
	local p = Vector3.new(r.o.X + x, r.y, r.o.Z + z)
	return CFrame.lookAt(p, p + Vector3.new(hx, 0, hz))
end

function Minis:Show(on)
	if on == self.shown then return end
	self.shown = on
	local f = on and folder() or nil
	for _, m in ipairs(self.models) do m.Parent = f end
end

function Minis:Update(t)
	local n = #self.models
	for i, m in ipairs(self.models) do
		local ok, cf = pcall(self.Pose, self, i, n, t)
		if ok then m:PivotTo(cf) end
	end
end

function Minis:Destroy()
	for _, m in ipairs(self.models) do m:Destroy() end
	self.models = {}
end

function P.DestroyFolder()
	local f = workspace:FindFirstChild("TrailerPuppets")
	if f then f:Destroy() end
end

return P
