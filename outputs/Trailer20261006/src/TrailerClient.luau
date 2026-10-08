-- TrailerClient (2026-10-06, Claude): the client half of the page-trailer director (DESIGN rev 2, sections 2.3-2.5, 5, 6, 8, 11).
-- Lock / Restore (everything recorded on first touch, restored once), the per-frame hide list, the Scriptable camera on one
-- RenderStep binding ("TrailerCam", Last), the shot engine (path / follow / orbit / static / hold, needs + fallbacks, cuts with
-- LightingSnap pulses, small grade deltas), warm-up streaming and camera parks, the AFK gate, and the real-plow driver.
-- The driver only writes inputs PlowDriveClient already reads (AFK attributes are the server's; PlowTestMove is a client-local
-- attribute that never replicates), so PlowDriveClient's Heartbeat stays the one velocity writer. Nothing here talks to the
-- server after ROLL: request() refuses and prints "[Trailer] BUG: request after ROLL".
-- Also the round-1 reference recorder (player attribute TrailerRefs): SeatWeld, drive numbers and puppet tracks as JSON lines.
-- No side effects at require time (Edit compile check, DESIGN 14.2).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

local Client = {}
local Math, Shots, Text, Puppets, Refs, Gui
local player
local R = nil -- current run
local state = "idle" -- idle | lock | slate | warm | gate | armed | running | refs | done | aborted
local shotById = {}

--------------------------------------------------------------------------------------------------------------------------------
-- basics
--------------------------------------------------------------------------------------------------------------------------------
local function log(fmt, ...) print("[Trailer] " .. string.format(fmt, ...)) end
local function unixms() return DateTime.now().UnixTimestampMillis end
local function serverNow() return workspace:GetServerTimeNow() end
local function aborted() return R == nil or R.aborted == true or R.restored == true end
local function waitUntil(cond, timeout)
	local t0 = os.clock()
	while true do
		if aborted() then error("aborted", 0) end
		if cond() then return true end
		if timeout and os.clock() - t0 >= timeout then return false end
		task.wait()
	end
end
local function sleep(s) waitUntil(function() return false end, s) end
local function v3s(v) return v and string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) or "nil" end

function Client.Init(mods)
	Math, Shots, Text, Puppets, Refs, Gui = mods.Math, mods.Shots, mods.Text, mods.Puppets, mods.Refs, mods.Gui
	player = Players.LocalPlayer
	Puppets.Init(Math)
	for _, s in ipairs(Shots.Shots) do shotById[s.id] = s end
end
function Client.State() return state end
function Client.Running() return state ~= "idle" and state ~= "done" and state ~= "aborted" end

local reqSeq = 0
local function request(action, args)
	if R and R.rollA then
		print("[Trailer] BUG: request after ROLL (" .. tostring(action) .. ")")
		return false
	end
	local remote = RS:FindFirstChild("TrailerRemote")
	if not (remote and remote:IsA("RemoteEvent")) then warn("[Trailer] TrailerRemote missing (" .. tostring(action) .. ")") return false end
	reqSeq += 1
	remote:FireServer("Req", reqSeq, action, args or {})
	return true
end

--------------------------------------------------------------------------------------------------------------------------------
-- record on first touch, restore once
--------------------------------------------------------------------------------------------------------------------------------
local function setProp(inst, prop, value)
	if not inst then return end
	local rec = R.saved[inst]
	if not rec then rec = {}; R.saved[inst] = rec end
	if rec[prop] == nil then
		local ok, v = pcall(function() return inst[prop] end)
		if not ok then return end
		rec[prop] = {v = v}
	end
	pcall(function() inst[prop] = value end)
end
local function restoreProp(inst, prop)
	local rec = R.saved[inst]
	local w = rec and rec[prop]
	if w then
		pcall(function() inst[prop] = w.v end)
		rec[prop] = nil
	end
end
-- StageClient disables a PaywallSurface when its stage opens (often while we hold it off): never restore an open stage's wall GUI
local function restoreValue(inst, prop, v)
	if prop == "Enabled" and inst:IsA("SurfaceGui") and inst.Name == "PaywallSurface" then
		local model = inst.Parent and inst.Parent.Parent
		local stage = model and model:GetAttribute("Stage")
		if stage and (stage == "Starter" or player:GetAttribute("Stage_" .. stage) == true) then return false end
	end
	return v
end
-- Enabled = false now and whenever a game script turns it back on (the game's wish is remembered for the restore)
local function hideEnabled(inst)
	local run = R
	if run.hooked[inst] then
		if inst.Enabled then inst.Enabled = false end
		return
	end
	setProp(inst, "Enabled", false)
	local ok, conn = pcall(function()
		return inst:GetPropertyChangedSignal("Enabled"):Connect(function()
			if run.restored or not inst.Enabled then return end
			local rec = run.saved[inst]
			if rec and rec.Enabled then rec.Enabled.v = true end
			inst.Enabled = false
		end)
	end)
	if ok then run.hooked[inst] = conn end
end

--------------------------------------------------------------------------------------------------------------------------------
-- hide list (section 8)
--------------------------------------------------------------------------------------------------------------------------------
local function keepFolders()
	local list = {}
	for _, n in ipairs(Shots.Hide.HumanoidKeep) do
		local f = workspace:FindFirstChild(n)
		if f then table.insert(list, f) end
	end
	return list
end
local function underKeep(inst)
	for _, f in ipairs(R.keep) do if inst:IsDescendantOf(f) then return true end end
	return false
end
local function hideModel(m)
	R.hiddenModels[m] = true
	local list = m:GetDescendants()
	if m:IsA("BasePart") then table.insert(list, m) end
	for _, d in ipairs(list) do
		if d:IsA("BasePart") then setProp(d, "LocalTransparencyModifier", 1)
		elseif d:IsA("Decal") or d:IsA("Texture") then setProp(d, "Transparency", 1)
		elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then hideEnabled(d) end
	end
end
-- critic fix: a locked stage's paywall WALL (not only its GUI) is invisible for the whole run. Locked = StageClient's rule
-- (isOpen: "Starter" or player attribute Stage_<id> == true, L40). The stage the run unlocks on camera keeps its wall (StageClient
-- fades it live). hideModel records LTM / GUI Enabled through setProp, so restore() puts them back once.
local function paywallLocked(m)
	local stage = m:GetAttribute("Stage")
	if type(stage) ~= "string" or stage == Shots.Config.UnlockStage then return false end
	return not (stage == "Starter" or player:GetAttribute("Stage_" .. stage) == true)
end
local function hidePaywall(m)
	if R.paywallHidden[m] or not m.Parent then return end
	if paywallLocked(m) then
		R.paywallHidden[m] = true
		hideModel(m)
	end
end
-- critic fix: the ContractYards "HELP YARD" signs (Yard_<Stage>.Gate.Sign SurfaceGui, one at Candy (1991, 17.6, 115)) stay hidden
-- even if a WorldGuiKeep entry would match them
local function hideHelpSigns()
	local yards = workspace:FindFirstChild(Shots.Anchors.Paths.HelpYards or "ContractYards")
	local n = 0
	if not yards then return 0 end
	for _, d in ipairs(yards:GetDescendants()) do
		if (d:IsA("SurfaceGui") or d:IsA("BillboardGui")) and d:FindFirstAncestor("Gate") then
			local txt = d:FindFirstChildWhichIsA("TextLabel", true)
			if txt and string.find(string.upper(txt.Text), "HELP", 1, true) then
				R.worldGuis[d] = true
				hideEnabled(d)
				n += 1
			end
		end
	end
	return n
end
local function hideHumanoid(h)
	setProp(h, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None)
	setProp(h, "HealthDisplayType", Enum.HumanoidHealthDisplayType.AlwaysOff)
	local model = h.Parent
	if not model or model == player.Character or underKeep(model) then return end
	hideModel(model) -- Help Yard NPCs, other characters, anything with a Humanoid outside the keep folders
end
local function keepGui(g)
	for _, n in ipairs(Shots.Config.WorldGuiKeep) do if g.Name == n or g:GetFullName() == n then return true end end
	return false
end
local function trackWorld(d)
	if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
		if not keepGui(d) then R.worldGuis[d] = true; hideEnabled(d) end
	elseif d:IsA("Humanoid") then
		R.humanoids[d] = true
		task.defer(function() if R and not R.restored and d.Parent then hideHumanoid(d) end end)
	elseif d:IsA("Beam") then
		R.beams[d] = true
	elseif d:IsA("Model") then
		if d.Name == "StagePaywall_Model" then table.insert(R.paywalls, d); hidePaywall(d) end
		local prefix = Shots.Hide.FrostKingPrefix
		if d.Name:sub(1, #prefix) == prefix then task.defer(function() if R and not R.restored then hideModel(d) end end) end
	end
end
local function trackPlayerGui(d)
	if d:IsA("LayerCollector") and d ~= Gui and not d:IsDescendantOf(Gui) then
		R.pgGuis[d] = true
		hideEnabled(d)
	end
end
local function beamsPass()
	local char = player.Character
	if not char then return end
	for b in pairs(R.beams) do
		if b.Parent and b.Enabled then
			local a0, a1 = b.Attachment0, b.Attachment1
			if b:IsDescendantOf(char) or (a0 and a0:IsDescendantOf(char)) or (a1 and a1:IsDescendantOf(char)) then hideEnabled(b) end
		end
	end
end
local function scanAll()
	R.keep = keepFolders()
	for _, d in ipairs(workspace:GetDescendants()) do trackWorld(d) end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if pg then for _, d in ipairs(pg:GetDescendants()) do trackPlayerGui(d) end end
	for _, n in ipairs(Shots.Hide.DevBoxes) do
		for _, c in ipairs(workspace:GetChildren()) do
			if c.Name == n and c:FindFirstChildWhichIsA("SurfaceGui", true) then hideModel(c) end
		end
	end
	R.helpSigns = hideHelpSigns()
	table.insert(R.conns, workspace.DescendantAdded:Connect(function(d) if R and not R.restored then trackWorld(d) end end))
	if pg then table.insert(R.conns, pg.DescendantAdded:Connect(function(d) if R and not R.restored then trackPlayerGui(d) end end)) end
end
local function hidePass()
	local n = R.frameNo
	for lc in pairs(R.pgGuis) do if lc.Parent and lc.Enabled then hideEnabled(lc) end end
	local cam = workspace.CurrentCamera
	if cam then
		for _, nm in ipairs(Shots.Hide.CameraEffects) do
			local e = cam:FindFirstChild(nm)
			if e and e:IsA("PostEffect") and e.Enabled then hideEnabled(e) end
		end
		if n % 3 == 0 then
			local w = cam:FindFirstChild(Shots.Hide.CameraWeather)
			if w then for _, d in ipairs(w:GetDescendants()) do if d:IsA("ParticleEmitter") and d.Enabled then hideEnabled(d) end end end
		end
	end
	local music = SoundService:FindFirstChild("Music")
	if music and music:IsA("SoundGroup") then setProp(music, "Volume", 0) end
	if n % 10 == 0 then for g in pairs(R.worldGuis) do if g.Parent and g.Enabled then hideEnabled(g) end end end
	if n % 10 == 5 then beamsPass() end
	if n % 30 == 0 then
		R.keep = keepFolders()
		for h in pairs(R.humanoids) do if h.Parent then hideHumanoid(h) end end
	end
	if n % 60 == 0 then
		for _, m in ipairs(R.paywalls) do hidePaywall(m) end -- late Stage attributes / streamed walls
		for m in pairs(R.hiddenModels) do if m.Parent then hideModel(m) end end
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
	end
	for _, inst in ipairs(R.shotHide) do
		if inst.Parent and inst.LocalTransparencyModifier ~= 1 then setProp(inst, "LocalTransparencyModifier", 1) end
	end
	-- review fix: pedestal 2's light stays on through S03/S04 (PlowGarageClient re-evaluates it on every Snow change, L272)
	local pl = R.pedLight
	if pl and pl.Parent and pl.Enabled ~= true then pcall(function() pl.Enabled = true end) end
	if R.snapUntil and os.clock() > R.snapUntil then
		R.snapUntil = nil
		player:SetAttribute("LightingSnap", R.snap0)
	end
end

--------------------------------------------------------------------------------------------------------------------------------
-- world lookups and anchors
--------------------------------------------------------------------------------------------------------------------------------
local function findPath(path)
	local inst = workspace
	for name in string.gmatch(path, "[^%.]+") do
		inst = inst:FindFirstChild(name)
		if not inst then return nil end
	end
	return inst
end
local function posOf(inst)
	if not inst then return nil end
	if inst:IsA("BasePart") then return inst.Position end
	if inst:IsA("Model") then return inst:GetPivot().Position end
	return nil
end
local function plowModel()
	local f = workspace:FindFirstChild("Snowplows")
	return f and f:FindFirstChild("Snowplow_" .. player.UserId)
end
local function plowHull()
	local m = plowModel()
	local hull = m and m.PrimaryPart
	if not hull or hull.Name ~= "Hull" then return nil, m end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0 and hum.SeatPart and hum.SeatPart.Parent == m) then return nil, m end
	return hull, m
end
local function fwdSpeed(hull)
	return hull.AssemblyLinearVelocity:Dot(Math.flatUnit(hull.CFrame.LookVector))
end
local function rayParams()
	local extra = {}
	for _, m in ipairs(R.paywalls) do if m.Parent then table.insert(extra, m) end end
	local cur = findPath(Shots.Anchors.Paths.Curtains)
	if cur then table.insert(extra, cur) end
	return Puppets.RayParams(extra)
end
local function groundPoint(v, fromY)
	local rp = rayParams()
	local hit = workspace:Raycast(Vector3.new(v.X, (fromY or v.Y) + 15, v.Z), Vector3.new(0, -80, 0), rp)
	return Vector3.new(v.X, hit and hit.Position.Y or v.Y, v.Z)
end
local function fieldRecord(id)
	local data = RS:FindFirstChild("SnowFieldData")
	local c = data and id and data:FindFirstChild(id)
	return c and c:GetAttributes() or nil
end
local function fieldFrame(id)
	local rec = fieldRecord(id)
	if not rec or typeof(rec.Center) ~= "Vector3" then return nil end
	local C = rec.Center
	local W, D = (rec.Width or 1) * 3, (rec.Depth or 1) * 3
	local u = W >= D and Vector3.xAxis or Vector3.zAxis
	local toPath = Vector3.new(0, 0, 55 - C.Z) -- Candy's main path line z = 55
	local perp = toPath - u * toPath:Dot(u)
	local v = perp.Magnitude > 1e-3 and perp.Unit or (u == Vector3.xAxis and Vector3.zAxis or Vector3.xAxis)
	return {p = C, u = u, v = v, rec = rec, live = true}
end

local function resolveAnchors()
	local A, S = R.anchors, Shots.Anchors
	local function set(name, p) if p then A[name] = {p = p, live = true} elseif not A[name] then A[name] = {p = S[name], live = false} end end
	set("E", posOf(findPath(S.Paths.Egg)))
	local hf = findPath(S.Paths.Headframe)
	local wheel = hf and hf:FindFirstChild("Wheel", true)
	set("Wh", posOf(wheel))
	set("H", posOf(findPath(S.Paths.Heart)))
	set("HE", posOf(findPath(S.Paths.Engine)))
	local portal = findPath(S.Paths.Portal)
	set("PT", portal and portal:IsA("Model") and (portal:GetBoundingBox()).Position or posOf(portal))
	-- the Candy gate (StageClient finds the same StagePaywall_Model / "Stage paywall")
	if not (A.G and A.G.live) then
		local wall
		for _, m in ipairs(R.paywalls) do
			if m.Parent and m:GetAttribute("Stage") == "Candy" then wall = m:FindFirstChild("Stage paywall") end
		end
		if wall and wall:IsA("BasePart") then
			local axis = wall.Size.X < wall.Size.Z and wall.CFrame.RightVector or wall.CFrame.LookVector
			axis = Math.flatUnit(axis, Vector3.xAxis)
			if axis.X < 0 then axis = -axis end -- from Sakura into Candy (+X side)
			local gy = groundPoint(wall.Position, wall.Position.Y - wall.Size.Y / 2 - 13).Y
			A.G = {p = wall.Position, a = axis, s = Vector3.new(-axis.Z, 0, axis.X), gy = gy, live = true, wall = wall}
		elseif not A.G then
			A.G = {p = S.G, a = Vector3.xAxis, s = Vector3.zAxis, gy = S.G.Y, live = false}
		end
	end
	-- MiniField (shot 10) and the Candy_1 record (puppet-minis fallback)
	local mf = fieldFrame(player:GetAttribute("MiniField"))
	if mf then A.C = mf end
	local c1 = fieldFrame(S.CandyField)
	if c1 then A.C1 = c1; if not A.C then A.C = {p = c1.p, u = c1.u, v = c1.v, live = false} end end
	if not A.C1 then A.C1 = {p = Vector3.new(2021, 4, 26), u = Vector3.xAxis, v = Vector3.zAxis, live = false} end
	if not A.C then A.C = A.C1 end
	-- the player's own bay (keys are stored for Bay_1)
	local bays = workspace:FindFirstChild("PlowGarage") and workspace.PlowGarage:FindFirstChild("Bays")
	local idx = player:GetAttribute("GarageBay")
	R.bayT, R.bayYawDeg = CFrame.new(), 0
	if bays and idx then
		local mine, one
		for _, m in ipairs(bays:GetChildren()) do
			if m:GetAttribute("BayIndex") == idx then mine = m end
			if m:GetAttribute("BayIndex") == 1 then one = m end
		end
		R.bayModel = mine
		if mine and one and mine ~= one then
			R.bayT = mine:GetPivot() * one:GetPivot():Inverse()
			local _, ry = R.bayT:ToEulerAnglesYXZ()
			R.bayYawDeg = -math.deg(ry)
		end
	end
end
local function anchor(name)
	local A = R.anchors[name]
	if A then return A end
	local p = Shots.Anchors[name]
	return {p = typeof(p) == "Vector3" and p or Vector3.zero, live = false}
end
local function point(spec)
	if typeof(spec) == "Vector3" then return spec end
	if spec.lerp then return Math.lerp(point(spec.lerp[1]), point(spec.lerp[2]), spec.lerp[3]) end
	local A = anchor(spec.at)
	local base = A.p
	if spec.y ~= nil and A.gy then base = Vector3.new(base.X, A.gy, base.Z) end
	local p = base + (spec.off or Vector3.zero) + Vector3.new(0, spec.y or 0, 0)
	if spec.a then p += (A.a or Vector3.xAxis) * spec.a end
	if spec.s then p += (A.s or Vector3.zAxis) * spec.s end
	if spec.u then p += (A.u or Vector3.xAxis) * spec.u end
	if spec.v then p += (A.v or Vector3.zAxis) * spec.v end
	return p
end
local function partsNear(pos, radius)
	local ok, list = pcall(function() return workspace:GetPartBoundsInRadius(pos, radius) end)
	return ok and #list or 0
end

--------------------------------------------------------------------------------------------------------------------------------
-- camera evaluation
--------------------------------------------------------------------------------------------------------------------------------
local function lookAt(pos, look)
	if (look - pos).Magnitude < 1e-3 then look = pos + Vector3.new(0, 0, -1) end
	return CFrame.lookAt(pos, look)
end
local function prepCam(cam)
	local c = {T = {}, P = {}, L = {}, F = {}, O = {}}
	if cam.type ~= "path" and cam.type ~= "follow" then R.camCache[cam] = c return c end
	local fov = cam.keys[1].fov or 60
	for i, k in ipairs(cam.keys) do
		c.T[i] = k.t
		fov = k.fov or fov
		c.F[i] = fov
		if cam.type == "path" then
			local p, l = point(k.pos), point(k.look)
			if cam.ref == "Bay" then p, l = R.bayT * p, R.bayT * l end
			c.P[i], c.L[i] = p, l
		else
			c.O[i], c.L[i] = k.offset, k.look
		end
	end
	R.camCache[cam] = c
	return c
end
local evalCam
local function evalHold(cam, u)
	local from = shotById[cam.fromShot]
	local used = (R.variants[cam.fromShot] and R.variants[cam.fromShot].cam) or (from and from.cam)
	if not used or used.type == "hold" or used.type == "follow" then return R.lastCF, R.lastFov end
	if not R.camCache[used] then prepCam(used) end
	local cf, fov = evalCam(used, 1, 0, true)
	local e = Math.ease("InOutSine", u)
	return cf + cf.LookVector * (cam.drift or 0) * e, fov
end
function evalCam(cam, u, dt, snap)
	local c = R.camCache[cam] or prepCam(cam)
	local e = Math.ease(cam.ease, u)
	if cam.type == "path" then
		local pos = Math.spline(c.P, c.T, e)
		local look = Math.spline(c.L, c.T, e)
		if cam.clampX then pos = Vector3.new(math.min(pos.X, cam.clampX), pos.Y, pos.Z) end
		return lookAt(pos, look), Math.linear(c.F, c.T, e)
	elseif cam.type == "follow" then
		local hull = plowHull()
		local F = R.follow
		if hull then
			local hp = hull.Position
			local yaw = Math.yawOf(Math.flatUnit(hull.CFrame.LookVector))
			if snap or not F.pos then F.pos, F.yaw = hp, yaw
			else
				F.pos = Math.smooth(F.pos, hp, dt, cam.posTau)
				F.yaw = Math.smoothAngle(F.yaw, yaw, dt, cam.yawTau)
			end
		end
		if not F.pos then return R.lastCF, R.lastFov end
		local off = Math.spline(c.O, c.T, e)
		local lk = Math.spline(c.L, c.T, e)
		local orbit = cam.orbitDeg and Math.lerp(cam.orbitDeg[1], cam.orbitDeg[2], e) or 0
		local frame = CFrame.new(F.pos) * CFrame.Angles(0, F.yaw + math.rad(orbit), 0)
		return lookAt(frame:PointToWorldSpace(off), frame:PointToWorldSpace(lk)), Math.linear(c.F, c.T, e)
	elseif cam.type == "orbit" then
		local center = cam.ref == "Bay" and (R.bayT * cam.center) or cam.center
		local a = Math.lerp(cam.a0, cam.a1, e) + (cam.ref == "Bay" and R.bayYawDeg or 0)
		local pos = center + Math.orbitOffset(a, cam.radius) + Vector3.new(0, cam.height, 0)
		return lookAt(pos, center + Vector3.new(0, cam.lookHeight, 0)), Math.lerp(cam.fov0, cam.fov1, e)
	elseif cam.type == "static" then
		return lookAt(point(cam.pos), point(cam.look)), cam.fov
	elseif cam.type == "hold" then
		return evalHold(cam, u)
	end
	return R.lastCF, R.lastFov
end

--------------------------------------------------------------------------------------------------------------------------------
-- real plow driver (sections 5.1-5.3, 6.5, 6.9, 6.11)
--------------------------------------------------------------------------------------------------------------------------------
local function setMove(v)
	if not R or R.restored then return end -- review fix: nothing writes PlowTestMove after Restore cleared it
	if R.lastMove == v then return end
	R.lastMove = v
	player:SetAttribute("PlowTestMove", v)
end
-- PlowDriveClient maps the move circle back to a square (L426-429); pre-scale so the plow gets exactly (steer, z)
local function sendMove(steer, z)
	local m = math.max(math.abs(steer), math.abs(z))
	local mag = math.sqrt(steer * steer + z * z)
	if mag > 1e-4 then local k = m / mag; steer, z = steer * k, z * k end
	setMove(Vector3.new(math.floor(steer * 1000 + 0.5) / 1000, 0, math.floor(z * 1000 + 0.5) / 1000))
end
local function kin(hull)
	local D, C = Shots.Config.Drive, R.C
	local vmax = hull:GetAttribute("MaxSpeed") or 20
	local acc = hull:GetAttribute("Accel") or 12
	return {vmax = vmax, vrev = vmax * C.Drive.ReverseFactor, a = acc * (1 + D.PlanPull), b = acc * C.Drive.BrakeFactor * D.BrakeSafety}
end
local function driveToward(hull, target, vTarget, reverse)
	local D = Shots.Config.Drive
	local look = Math.flatUnit(hull.CFrame.LookVector)
	local dir = Math.flatUnit(target - hull.Position, look)
	local maxSpeed = hull:GetAttribute("MaxSpeed") or 20
	if reverse then
		local ang = Math.angleTo(-look, dir)
		local steer = -Math.clamp(D.SteerGain * ang, -1, 1) -- reversing flips the yaw sign (PlowDriveClient L524)
		sendMove(steer, Math.clamp(vTarget / (maxSpeed * R.C.Drive.ReverseFactor), 0, 1))
	else
		local ang = Math.angleTo(look, dir)
		local steer = Math.clamp(D.SteerGain * ang, -1, 1)
		local cap = math.abs(ang) > 1.3 and 0.35 or (math.abs(ang) > 0.5 and 0.55 or 1) -- same caps as AFK (L252)
		sendMove(steer, -math.min(Math.clamp(vTarget / maxSpeed, 0, 1), cap))
	end
end
-- one control step along a route; returns arrived, distance left
local function routeStep(ms, hull)
	local D = Shots.Config.Drive
	local k = kin(hull)
	local target, left, idx = Math.pursuit(ms.path, hull.Position, D.Lookahead, ms.idx)
	ms.idx = idx
	ms.left = left
	if left <= D.ArriveRadius then
		sendMove(0, 0)
		if not ms.arrived and math.abs(fwdSpeed(hull)) < 0.5 then ms.arrived = true end
		return ms.arrived, left
	end
	local v = ms.cruise or (ms.reverse and k.vrev or k.vmax)
	if ms.stop then v = math.min(v, math.sqrt(2 * k.b * math.max(0, left - D.StopSlack))) end
	driveToward(hull, target, v, ms.reverse)
	return false, left
end

local function storeLane(hull, model)
	local J = R.join
	J.oldModel = model
	J.oldCF = hull.CFrame
	J.laneDir = Math.flatUnit(hull.CFrame.LookVector)
	J.laneOrigin = hull.Position
	-- review fix: where the AFK lane ends ahead (the gate's cached AFK route; its points already sit Afk.Inset inside the field)
	local route, info = R.afkRoute, R.afkInfo
	if route and info then
		local bestLat
		for i = 1, #route - 1, 2 do
			local p0, p1 = route[i], route[i + 1]
			local dirL = Math.flatUnit(p1 - p0)
			local rel = Math.flat(J.laneOrigin - p0)
			local lat = (rel - dirL * rel:Dot(dirL)).Magnitude
			if lat < info.lane * 0.5 + 1 and (not bestLat or lat < bestLat) then
				local a0, a1 = Math.flat(p0 - J.laneOrigin):Dot(J.laneDir), Math.flat(p1 - J.laneOrigin):Dot(J.laneDir)
				if math.max(a0, a1) > 0 then bestLat, J.laneEndAlong = lat, math.max(a0, a1) end
			end
		end
	end
	local G = Shots.Config.Gate
	if not J.laneEndAlong then
		log("S05: lane end not found from the AFK route - wide run capped at %.0f studs", G.LaneRun)
	elseif J.laneEndAlong - G.LaneEndMargin < G.LaneNeed then
		R.flags.s05ok = false
		log("S05: only %.1f studs of lane left at the join (< %.0f) - fallback", J.laneEndAlong, G.LaneNeed + G.LaneEndMargin)
	end
	log("plow lane stored at %s heading %s, lane end %s studs ahead", v3s(J.laneOrigin), v3s(J.laneDir),
		J.laneEndAlong and string.format("%.1f", J.laneEndAlong) or "?")
end

-- latest departure that still meets the move's crossAt / arriveBy (never later than the spec's 'at')
local function effectiveStart(mv, hull)
	if mv.kind ~= "route" or not hull then return mv.at end
	local route = R.routes[mv.route]
	if not route then return mv.at end
	local D, k = Shots.Config.Drive, kin(hull)
	local eff = mv.at
	if mv.crossAt then
		local g = anchor(mv.crossAt.point == "G" and "Gg" or mv.crossAt.point).p
		local dist = Math.flat(g - hull.Position).Magnitude
		eff = math.min(eff, mv.crossAt.t - Math.timeFromRest(dist, k.a, k.vmax) * D.Early)
	elseif mv.arriveBy then
		local path = {hull.Position}
		for _, p in ipairs(route) do table.insert(path, p) end
		local dist = Math.pathLength(path)
		eff = math.min(eff, mv.arriveBy - Math.minTime(dist, k.a, k.b, mv.reverse and k.vrev or k.vmax) * D.Early)
	end
	return eff
end

local function startMove(mv, tau, hull)
	local ms = {mv = mv, startTau = tau}
	R.move = ms
	if mv.kind == "route" then
		local route = R.routes[mv.route]
		if not route then log("plow move %s: route %s missing - holding", mv.id, tostring(mv.route)); ms.skip = true return end
		if mv.needNear and hull then
			local p = anchor(mv.needNear).p
			if Math.flat(p - hull.Position).Magnitude > Shots.Config.Drive.NearRadius then
				log("plow move %s skipped: plow %.1f studs from %s", mv.id, Math.flat(p - hull.Position).Magnitude, mv.needNear)
				ms.skip = true
				return
			end
		end
		ms.reverse = mv.reverse
		ms.stop = mv.stop
	end
	log("plow move %s start tau=%.2f (spec %.2f)", mv.id, tau, mv.at)
end
local function initRoute(ms, hull, tau)
	local mv = ms.mv
	local route = R.routes[mv.route]
	local path = {hull.Position}
	if Math.flat(route[#route] - hull.Position).Magnitude <= Shots.Config.Drive.ArriveRadius * 2 then
		-- already at the end (TrailerSplit 9-11 waits at P_hold): nothing to drive
		table.insert(path, route[#route])
		ms.path, ms.idx, ms.arrived, ms.logged = path, 1, true, true
		log("plow move %s: already at its end point", mv.id)
		return
	end
	for _, p in ipairs(route) do table.insert(path, p) end
	ms.path, ms.idx = path, 1
	local k = kin(hull)
	local dist = Math.pathLength(path)
	if mv.arriveBy and not mv.crossAt then
		ms.cruise = Math.timedCruise(dist, mv.arriveBy - tau, k.a, k.b, mv.reverse and k.vrev or k.vmax)
	end
	log("plow move %s route %.1f studs, cruise %s, arriveBy %s", mv.id, dist, ms.cruise and string.format("%.1f", ms.cruise) or "max",
		tostring(mv.arriveBy))
end

local function driverStep(tau, preMove)
	local hull, model = plowHull()
	local moves = Shots.PlowMoves
	local J = R.join
	-- store the AFK lane just before AFK goes off (2.40)
	local joinDef
	for _, m in ipairs(moves) do if m.kind == "join" then joinDef = m end end
	if joinDef and not J.oldCF and hull and tau >= joinDef.store and tau < joinDef.at + 0.5 then storeLane(hull, model) end
	-- S05 join check (review fix): runs before the move selection, because 'wide' starts at alignedBy and would otherwise
	-- replace the join move on the very frame the check was due
	if joinDef and R.flags.s05ok == nil and J.newAt and J.laneDir and tau >= joinDef.alignedBy then
		local D = Shots.Config.Drive
		if hull and model ~= J.oldModel then
			local along = (hull.Position - J.laneOrigin):Dot(J.laneDir)
			local yawErr = math.deg(math.abs(Math.angleTo(J.laneDir, Math.flatUnit(hull.CFrame.LookVector))))
			local ok = J.newAt <= joinDef.newBy and math.abs(along) <= D.AlignTol and yawErr <= D.AlignYawDeg
			R.flags.s05ok = ok
			log("S05 join check: along=%.2f yawErr=%.1f newAt=%.2f -> %s", along, yawErr, J.newAt, ok and "ok" or "fallback")
		else
			R.flags.s05ok = false
			log("S05 join check: no seated new plow at %.2f -> fallback", tau)
		end
	end
	-- pick the active move
	if preMove then
		if not R.move or R.move.mv ~= preMove then startMove(preMove, tau, hull) end
	else
		local i = R.moveIdx or 0
		while moves[i + 1] do
			local nxt = moves[i + 1]
			local cur = R.move
			if cur and cur.mv == nxt then i += 1 continue end
			-- an early departure is only planned once the current route move has arrived (else the spec time holds)
			local settled = not cur or cur.skip or cur.mv.kind ~= "route" or cur.arrived == true
			local eff = settled and effectiveStart(nxt, hull) or nxt.at
			eff = math.max(eff, cur and cur.startTau or -math.huge)
			if tau >= eff then i += 1; startMove(nxt, tau, hull) else break end
		end
		R.moveIdx = i
	end
	local ms = R.move
	if not ms then setMove(nil) return end
	local mv = ms.mv
	if mv.kind == "afk" then setMove(nil) return end
	if ms.skip or mv.kind == "hold" then sendMove(0, 0) return end
	if mv.kind == "join" then
		local D = Shots.Config.Drive
		if not hull or (J.oldModel and model == J.oldModel) or not J.laneDir then
			sendMove(0, 0)
			if tau > mv.newBy and not J.flagged then J.flagged = true; R.flags.s05ok = false; log("S05: no new plow by %.1f - fallback", mv.newBy) end
			return
		end
		if not J.newAt then J.newAt = tau; log("plow respawned with %s at tau=%.2f", Shots.Profile.SwapBlade, tau) end
		local along = (hull.Position - J.laneOrigin):Dot(J.laneDir)
		if along > D.JoinTol then
			local k = kin(hull)
			local target = J.laneOrigin + J.laneDir * (along - 6)
			driveToward(hull, target, math.min(k.vrev * 0.6, math.sqrt(2 * k.b * math.max(0, along - D.JoinTol))), true)
		else
			sendMove(0, 0)
		end
		return
	end
	if mv.kind == "lane" then
		-- review fix: a stop move along the stored lane, braking to min(LaneRun, lane end - LaneEndMargin), never off the field
		if not hull or not (J.laneDir and J.laneOrigin) then sendMove(0, 0) return end
		local D, G = Shots.Config.Drive, Shots.Config.Gate
		local dir, origin = J.laneDir, J.laneOrigin
		local along = (hull.Position - origin):Dot(dir)
		local stopAlong = G.LaneRun
		if J.laneEndAlong then stopAlong = math.min(stopAlong, J.laneEndAlong - G.LaneEndMargin) end
		local left = stopAlong - along
		if left <= D.ArriveRadius then
			sendMove(0, 0)
			if not ms.logged then ms.logged = true; log("plow move %s stopped tau=%.2f at along=%.1f (stop %.1f)", mv.id, tau, along, stopAlong) end
			return
		end
		local k = kin(hull)
		driveToward(hull, origin + dir * (along + 20), math.min(k.vmax, math.sqrt(2 * k.b * math.max(0, left - D.StopSlack))), false)
		return
	end
	if mv.kind == "route" then
		if not hull then sendMove(0, 0) return end
		if mv.waitSpawn and not ms.path then
			-- the travelled plow: wait for the new seated plow near Sakura
			if Math.flat(hull.Position - anchor("SakuraArrival").p).Magnitude > 400 then sendMove(0, 0) return end
		end
		if not ms.path then initRoute(ms, hull, tau) end
		local arrived, left = routeStep(ms, hull)
		if arrived and not ms.logged then
			ms.logged = true
			log("plow move %s stopped tau=%.2f err=%.2f studs (plan %s)", mv.id, tau, left, tostring(mv.arriveBy))
		end
		if mv.crossAt and not ms.crossLogged then
			local g = anchor("Gg").p
			if (hull.Position - ms.path[1]):Dot(R.anchors.G and R.anchors.G.a or Vector3.xAxis) >= (g - ms.path[1]):Dot(R.anchors.G and R.anchors.G.a or Vector3.xAxis) then
				ms.crossLogged = true
				log("plow crossed the Candy gate at tau=%.2f (plan %.2f)", tau, mv.crossAt.t)
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------
-- warm-up (section 2.4 step 2) and the Sakura -> Candy route (section 5.3)
--------------------------------------------------------------------------------------------------------------------------------
local function park(cf, fov, secs)
	if cf then R.parkCF, R.parkFov = cf, fov end
	sleep(secs)
end
local function staticCam(shot, useFallbackFor10)
	local cam = shot.cam
	if useFallbackFor10 and shot.id == "S10_Minis" and not (R.anchors.C and R.anchors.C.live and fieldRecord(player:GetAttribute("MiniField"))
		and fieldRecord(player:GetAttribute("MiniField")).Style == "Candy") then
		cam = shot.fallbacks[1].cam
	end
	if cam.type == "follow" or cam.type == "hold" then return nil end
	prepCam(cam)
	return cam
end
local function computeLegs()
	local A, S = R.anchors, Shots.Anchors
	local G = A.G
	local a = G.a or Vector3.xAxis
	local Gg = Vector3.new(G.p.X, G.gy or G.p.Y, G.p.Z)
	A.Gg = {p = Gg, live = G.live}
	local hold = groundPoint(Gg - a * S.HoldBack, Gg.Y)
	A.PHold = {p = hold, live = G.live}
	local tp = workspace:FindFirstChild("TravelPoints") and workspace.TravelPoints:FindFirstChild("Sakura")
	local arrival = tp and tp:IsA("BasePart") and tp.Position or S.SakuraArrival
	A.SakuraArrival = {p = arrival, live = tp ~= nil}
	local start = groundPoint(arrival + Math.flatUnit(hold - arrival) * S.LegAhead, arrival.Y)
	-- leg 1: pathfinding, Sakura arrival -> P_hold
	local leg1 = {start, hold}
	local ok, path = pcall(function()
		local p = PathfindingService:CreatePath({AgentRadius = 4, AgentHeight = 6, AgentCanJump = false})
		p:ComputeAsync(start, hold)
		return p
	end)
	if ok and path and path.Status == Enum.PathStatus.Success then
		leg1 = {}
		for _, w in ipairs(path:GetWaypoints()) do
			if #leg1 == 0 or Math.flat(w.Position - leg1[#leg1]).Magnitude >= 3 then table.insert(leg1, w.Position) end
		end
		if Math.flat(leg1[#leg1] - hold).Magnitude > 0.5 then table.insert(leg1, hold) end
		log("leg1 pathfinding ok: %d waypoints", #leg1)
	else
		-- critic fix: never a blind straight line; Anchors.Leg1Via (ground-snapped) between the leg start and P_hold
		local why = ok and path and tostring(path.Status) or tostring(path)
		local dirL = Math.flatUnit(hold - start)
		local lenL = Math.flat(hold - start).Magnitude
		local via = {}
		for _, v in ipairs(S.Leg1Via or {}) do
			local along = Math.flat(v - start):Dot(dirL)
			if along > 1 and along < lenL - 1 then table.insert(via, {along = along, p = groundPoint(v, v.Y)}) end
		end
		table.sort(via, function(x, y) return x.along < y.along end)
		leg1 = {start}
		for _, v in ipairs(via) do table.insert(leg1, v.p) end
		table.insert(leg1, hold)
		warn(string.format("[Trailer] WARNING leg1 pathfinding failed (%s) - using %d Anchors.Leg1Via way-points over the koi-pond bridge deck (no hull-wide way around it)", why, #via))
	end
	R.routes.leg1 = leg1
	-- leg 2: P_hold -> G -> deck tops -> Candy entrance -> P_wait
	local entrance = S.CandyEntrance
	local wait = groundPoint(S.PWait, S.PWait.Y)
	local stop = groundPoint(S.PStop, S.PStop.Y)
	A.PWait, A.PStop = {p = wait, live = true}, {p = stop, live = true}
	local deck = {}
	local bridges = findPath(S.Paths.Bridges)
	local lineDir = Math.flatUnit(entrance - Gg, a)
	local segLen = Math.flat(entrance - Gg):Dot(lineDir)
	if bridges then
		for _, d in ipairs(bridges:GetDescendants()) do
			-- critic fix: the deck is World2.Paths20261006.SakuraToCandy (visible "Deck" parts; its invisible "SideCollider" walls are
			-- 24 tall and must never become way-points); a flat invisible walkable part still counts
			if d:IsA("BasePart") and d.CanCollide and (d.Name == "Deck" or (d.Transparency >= 0.95 and d.Size.Y <= 2)) then
				local top = (d.CFrame * CFrame.new(0, d.Size.Y / 2, 0)).Position
				local rel = Math.flat(top - Gg)
				local along = rel:Dot(lineDir)
				local lat = (rel - lineDir * along).Magnitude
				if along > 2 and along < segLen - 2 and lat < 40 then table.insert(deck, {along = along, p = top}) end
			end
		end
	end
	table.sort(deck, function(x, y) return x.along < y.along end)
	local leg2 = {hold, Gg}
	for _, d in ipairs(deck) do
		if Math.flat(d.p - leg2[#leg2]).Magnitude >= 6 then table.insert(leg2, d.p) end
	end
	table.insert(leg2, entrance)
	table.insert(leg2, wait)
	R.routes.leg2 = leg2
	R.routes.leg3 = {wait, stop}
	R.routes.leg3back = {stop, wait}
	log("legs: G %s (%s) a=%s P_hold %s, deck tops %d, P_wait %s, P_stop %s", v3s(Gg), G.live and "live" or "SCOUT", v3s(a), v3s(hold), #deck, v3s(wait), v3s(stop))
end

local function buildPuppets()
	local C = R.C
	local stats = C.StatsFor(Shots.Profile.HeroC, {})
	for _, shot in ipairs(Shots.Shots) do
		local def = shot.puppet
		if def and not R.puppets[shot.id] then
			local obj, why = Puppets.New(def.name, Shots.Profile.HeroC, Refs.SeatWeld, Refs.ToCFrame)
			if not obj then
				log("puppet %s not built: %s", def.name, tostring(why))
			else
				local from, to = point(def.from), point(def.to)
				local fn, source = obj:Motion(def, {from = from, to = groundPoint(to, to.Y + 10), stats = {MaxSpeed = stats.MaxSpeed, Accel = stats.Accel},
					brakeFactor = C.Drive.BrakeFactor, brakeShare = Shots.Config.Puppet.BrakeShare, track = Refs.Tracks[def.track],
					kinematic = Shots.Config.Puppet.Kinematic, rp = Puppets.RayParams({}), axle = Shots.Config.Puppet.Axle})
				if not fn then
					obj:Destroy()
					log("puppet %s: %s - %s", def.name, tostring(source), def.optional and "camera only" or "egg-only push-in")
				else
					R.puppets[shot.id] = {obj = obj, fn = fn, source = source}
					log("puppet %s ready (%s motion, driver %s, seat weld %s)", def.name, source, obj.driver and "yes" or "MISSING",
						obj.seatWeldRecorded and "recorded" or "default")
				end
			end
		end
	end
	if not R.minis then
		local rec = fieldRecord(Shots.Anchors.CandyField)
		if rec then
			local m, why = Puppets.NewMinis(Shots.Profile.HeroC, 5, rec)
			R.minis = m
			if not m then log("puppet minis not built: %s", tostring(why)) end
		end
	end
end

local function warmUp()
	local W = Shots.Warm
	resolveAnchors()
	for _, pos in ipairs(W.World1Stream) do request("Stream", {pos = pos}) end
	sleep(1.0)
	resolveAnchors()
	for _, id in ipairs(W.World1Park) do
		local shot = shotById[id]
		local cam = shot and staticCam(shot)
		if cam then
			for _, u in ipairs({0, 1}) do
				local cf, fov = evalCam(cam, u, 0, true)
				park(cf, fov, Shots.Config.WarmPark)
				if id == "S03_Bay" and u == 0 then request("RepublishBay"); sleep(0.3) end
			end
		end
	end
	resolveAnchors()
	buildPuppets()
	for _, w in ipairs(W.World2Stream) do
		local pos = w.pos or point({at = w.at})
		request("Stream", {pos = pos})
		local ok = waitUntil(function() return partsNear(pos, w.radius) >= w.min end, W.PartsWait)
		log("warm stream %s parts=%d %s", v3s(pos), partsNear(pos, w.radius), ok and "ok" or "TIMEOUT")
		resolveAnchors()
	end
	computeLegs()
	for _, id in ipairs(W.World2Park) do
		local shot = shotById[id]
		local cam = shot and staticCam(shot, true)
		if cam then
			for _, u in ipairs({0, 1}) do
				local cf, fov = evalCam(cam, u, 0, true)
				park(cf, fov, Shots.Config.WarmPark)
			end
		end
	end
	R.camCache = {} -- anchors may still move; every shot re-prepares at its start
	request("Ready", {})
	log("warm-up done: G %s, H %s, PT %s, E %s, bay %s", R.anchors.G.live and "live" or "SCOUT", R.anchors.H.live and "live" or "SCOUT",
		R.anchors.PT.live and "live" or "SCOUT", R.anchors.E.live and "live" or "SCOUT", tostring(player:GetAttribute("GarageBay")))
end

--------------------------------------------------------------------------------------------------------------------------------
-- the AFK gate (section 6.1)
--------------------------------------------------------------------------------------------------------------------------------
local function afkRoute()
	local id, laneW = player:GetAttribute("AfkField"), player:GetAttribute("AfkLane")
	local key = tostring(id) .. ":" .. tostring(laneW)
	if R.afkKey == key then return R.afkRoute, R.afkInfo end
	local SF = require(RS:WaitForChild("SnowFields"))
	local f
	for _, x in ipairs(SF.Fields) do if x.Id == id then f = x end end
	if not f then return nil end
	local o, ts = SF.Origin(f), SF.TileSize
	local W, D, inset = f.Width * ts, f.Depth * ts, R.C.Afk.Inset
	local lane = math.max(3, laneW or 6)
	local alongX = W >= D
	local len, across = alongX and W or D, alongX and D or W
	local route, k, a = {}, 0, inset
	while a <= across - inset + 0.01 do -- copy of PlowDriveClient afkMove L213-236
		local p0, p1 = inset, len - inset
		if k % 2 == 1 then p0, p1 = p1, p0 end
		for _, p in ipairs({p0, p1}) do
			route[#route + 1] = alongX and Vector3.new(o.X + p, o.Y, o.Z + a) or Vector3.new(o.X + a, o.Y, o.Z + p)
		end
		a += lane
		k += 1
	end
	R.afkKey, R.afkRoute, R.afkInfo = key, route, {W = W, D = D, alongX = alongX, lane = lane}
	log("AFK route: field %s %.0fx%.0f studs, lanes along %s, lane %.1f, %d points", tostring(id), W, D, alongX and "X" or "Z", lane, #route)
	return route, R.afkInfo
end
local function gateCheck(tGate)
	local G = Shots.Config.Gate
	local hull = plowHull()
	if not hull then return false, "no seated plow" end
	if player:GetAttribute("AfkPlow") ~= true then return false, "AFK is off" end
	local route, info = afkRoute()
	if not route then return false, "no AFK route" end
	local pos = hull.Position
	local look = Math.flatUnit(hull.CFrame.LookVector)
	local t = os.clock()
	table.insert(R.yawHist, {t, Math.yawOf(look)})
	while #R.yawHist > 2 and t - R.yawHist[2][1] > G.YawWindow do table.remove(R.yawHist, 1) end
	local h0 = R.yawHist[1]
	local rate = (t - h0[1] >= G.YawWindow * 0.9) and math.abs(Math.wrap(Math.yawOf(look) - h0[2])) / (t - h0[1]) or nil
	local best, bestErr
	for i = 1, #route - 1, 2 do
		local p0, p1 = route[i], route[i + 1]
		local dirL = Math.flatUnit(p1 - p0)
		local rel = Math.flat(pos - p0)
		local lat = (rel - dirL * rel:Dot(dirL)).Magnitude
		if lat < info.lane * 0.5 + 1 then
			for _, e in ipairs({p0, p1}) do
				local to = Math.flat(e - pos)
				if to.Magnitude > 1 then
					local err = math.abs(Math.angleTo(look, to.Unit))
					if not bestErr or err < bestErr then best, bestErr = e, err end
				end
			end
		end
	end
	if not best then return false, "not on an AFK lane" end
	local dist = Math.flat(best - pos).Magnitude
	local speed = Math.flat(hull.AssemblyLinearVelocity).Magnitude
	local why = string.format("yawErr=%.1f rate=%s dist=%.1f speed=%.1f x=%.1f", math.deg(bestErr), rate and string.format("%.2f", rate) or "?", dist, speed, pos.X)
	if math.deg(bestErr) >= G.YawErrDeg then return false, "heading: " .. why end
	if not rate or rate >= G.YawRate then return false, "turning: " .. why end
	-- review fix: the lane must hold the pre-roll + shot 1 run AND shot 5's wide run (it continues from the 2.40 point)
	local need = math.max(G.MinDist, math.max(speed, G.PlanSpeed) * (Shots.Config.ArmLead + 2.45) + G.LaneNeed + G.LaneEndMargin + 4)
	if dist < need then return false, string.format("lane end too close (< %.0f): ", need) .. why end
	if speed < G.MinSpeed then return false, "slow: " .. why end
	if pos.X >= G.PreferMaxX and os.clock() - tGate < G.PreferFor then return false, "waiting for x < 45: " .. why end
	return true, why
end
local function gateSplit()
	local G = Shots.Config.Gate
	local hull = plowHull()
	if not hull then return false, "no seated plow" end
	local hold = anchor("PHold").p
	local d = Math.flat(hold - hull.Position).Magnitude
	local a = R.anchors.G and R.anchors.G.a or Vector3.xAxis
	local yawErr = math.deg(math.abs(Math.angleTo(Math.flatUnit(hull.CFrame.LookVector), a)))
	local why = string.format("dist=%.1f speed=%.2f yawErr=%.1f", d, math.abs(fwdSpeed(hull)), yawErr)
	if d > G.HoldRadius or math.abs(fwdSpeed(hull)) > G.HoldSpeed or yawErr > G.HoldYawDeg then return false, why end
	return true, why
end

--------------------------------------------------------------------------------------------------------------------------------
-- shots: needs, variants, per-shot logging
--------------------------------------------------------------------------------------------------------------------------------
local function bayPreviewIsSwapBlade()
	local id = Shots.Profile.SwapBlade
	local bay = R.bayModel
	local prev = bay and bay:FindFirstChild("BayPreview", true)
	local blade = prev and prev:FindFirstChild("Blade")
	if not blade or prev:FindFirstChild("Leaving_Blade") then return false end
	local def = R.C.Parts[id]
	local parts = RS:FindFirstChild("PlowParts")
	local tpl = def and parts and parts:FindFirstChild(def.Model)
	if not tpl then return (bay:GetAttribute("Build") or ""):sub(1, #id + 1) == id .. "|" end
	local function dims(x)
		local s = x:IsA("Model") and x:GetExtentsSize() or (x:IsA("BasePart") and x.Size or Vector3.zero)
		local t = {s.X, s.Y, s.Z}
		table.sort(t)
		return t
	end
	local a, b = dims(blade), dims(tpl)
	return math.abs(a[1] - b[1]) < 0.15 and math.abs(a[2] - b[2]) < 0.15 and math.abs(a[3] - b[3]) < 0.15
end
local function needOk(need, tauShot, deferredOk)
	if not need then return true end
	if need.parts then
		local p = need.parts.at and anchor(need.parts.at).p or need.parts.pos
		local n = partsNear(p, need.parts.radius)
		if n < need.parts.min then return false, string.format("parts %d < %d near %s", n, need.parts.min, v3s(p)) end
	end
	if need.bladeWide and not bayPreviewIsSwapBlade() then return false, "bay preview still shows the old blade" end
	if need.flag and R.flags[need.flag] ~= true then return false, "flag " .. need.flag .. " = " .. tostring(R.flags[need.flag]) end
	if need.plowAt and (deferredOk or tauShot >= need.plowAt.by) then
		local hull = plowHull()
		local p = anchor(need.plowAt.at).p
		local d = hull and Math.flat(hull.Position - p).Magnitude
		if hull and need.plowAt.to then
			-- review fix: the move may already have left 'at' (early departure), so the whole at -> to segment counts
			local q = anchor(need.plowAt.to).p
			local ab, ap = Math.flat(q - p), Math.flat(hull.Position - p)
			local k = ab.Magnitude > 1e-3 and math.clamp(ap:Dot(ab) / ab:Dot(ab), 0, 1) or 0
			d = (ap - ab * k).Magnitude
		end
		if not hull or d > need.plowAt.radius then return false, "plow not at " .. need.plowAt.at end
	end
	if need.minis then
		local rec = fieldRecord(player:GetAttribute("MiniField"))
		if not rec or rec.Style ~= need.minis.style or (player:GetAttribute("MiniCount") or 0) <= 0 then
			return false, "MiniField " .. tostring(player:GetAttribute("MiniField")) .. " is not " .. need.minis.style
		end
		-- review fix: the attribute leads the drawn fleet (server refresh every 4-5 s, MiniPlowClient sync every 1.5 s), so the
		-- real fleet must already be on that field
		local folder = workspace:FindFirstChild("MiniPlows")
		local m1 = folder and folder:FindFirstChild(player.Name .. "_Mini1")
		if not (m1 and m1:IsA("Model") and typeof(rec.Center) == "Vector3") then return false, "real minis not drawn yet" end
		local p = m1:GetPivot().Position
		local W, D = (rec.Width or 1) * 3, (rec.Depth or 1) * 3
		if math.abs(p.X - rec.Center.X) > W / 2 + 6 or math.abs(p.Z - rec.Center.Z) > D / 2 + 6 then
			return false, "real minis not on " .. tostring(player:GetAttribute("MiniField")) .. " yet"
		end
	end
	if need.field and not fieldRecord(need.field) then return false, "no field record " .. need.field end
	return true
end
local function chooseVariant(shot, tauShot)
	local ok, why = needOk(shot.need, tauShot, false)
	if ok then return {cam = shot.cam, puppet = shot.puppet ~= nil, name = "primary"} end
	for _, f in ipairs(shot.fallbacks or {}) do
		if not f.need or needOk(f.need, tauShot, true) then
			return {cam = f.sameCam and shot.cam or f.cam, puppet = f.sameCam and shot.puppet ~= nil or false, minis = f.minis, name = f.name, why = why}
		end
	end
	return {cam = shot.cam, puppet = false, name = "primary (no fallback fits)", why = why}
end

local function endShot()
	local cur = R.cur
	if not cur then return end
	R.cur = nil
	local st = cur.stats
	if st.bucketT >= Shots.Config.FpsBucket * 0.5 then
		local fps = st.bucketN / st.bucketT
		st.worst = st.worst and math.min(st.worst, fps) or fps
	end
	local y = st.yMin and string.format(" screenY=%.2f-%.2f", st.yMin, st.yMax) or ""
	log("SHOT %s pass=%s start=%+.3f frames=%d fps_avg=%.1f fps_worst=%.1f variant=%s%s plowSpeedMax=%.1f",
		cur.shot.id, cur.pass, cur.startErr, st.frames, st.frames / math.max(st.time, 1e-3), st.worst or 0, cur.variant.name, y, st.speedMax)
	table.insert(R.fps, st.worst or 0)
	local pup = R.puppets[cur.shot.id]
	if pup then pup.obj:Show(false) end
	if cur.variant.minis and R.minis then R.minis:Show(false) end
	for _, inst in ipairs(R.shotHide) do restoreProp(inst, "LocalTransparencyModifier") end
	R.shotHide = {}
	if R.pedLight then
		local pl = R.pedLight
		R.pedLight = nil
		restoreProp(pl, "Enabled")
	end
end
-- the PointLight PlowGarageClient puts on Pedestal_2's top part (setupBay L323; the top is found like its partOf, L61-66)
local function pedestalLight()
	local holder = R.bayModel and R.bayModel:FindFirstChild("Pedestal_2")
	if not holder then return nil end
	local top = holder:IsA("BasePart") and holder or holder:FindFirstChild("Top") or (holder:IsA("Model") and holder.PrimaryPart)
		or holder:FindFirstChildWhichIsA("BasePart", true)
	local light = top and top:FindFirstChildOfClass("PointLight")
	return light or holder:FindFirstChildWhichIsA("PointLight", true)
end
-- real minis are hidden while the puppet-minis fallback plays (a late MiniField flip must not add a second fleet)
local function hideRealMinis(cur)
	local folder = workspace:FindFirstChild("MiniPlows")
	if not folder then return end
	cur.miniSeen = cur.miniSeen or {}
	local prefix = player.Name .. "_Mini"
	for _, m in ipairs(folder:GetChildren()) do
		if m.Name:sub(1, #prefix) == prefix and not cur.miniSeen[m] then
			cur.miniSeen[m] = true
			if m:IsA("BasePart") then table.insert(R.shotHide, m) end
			for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then table.insert(R.shotHide, d) end end
		end
	end
end
local function pulseSnap()
	player:SetAttribute("LightingSnap", true)
	R.snapUntil = os.clock() + Shots.Config.SnapPulse
end
local function grade(g)
	g = g or {}
	local tw = TweenService:Create(R.grade, TweenInfo.new(Shots.Config.Grade.Tween), {
		Brightness = math.clamp(g.Brightness or 0, -0.05, 0.05), Contrast = math.clamp(g.Contrast or 0, -0.05, 0.05),
		Saturation = math.clamp(g.Saturation or 0, -0.08, 0.08)})
	tw:Play()
end
local function startShot(shot, pass, tauShot)
	endShot()
	resolveAnchors()
	local variant = chooseVariant(shot, tauShot)
	R.variants[shot.id] = variant
	prepCam(variant.cam)
	local cur = {shot = shot, pass = pass, variant = variant, startErr = tauShot - shot.start,
		snap = variant.cam.type == "follow" and R.follow.forShot ~= shot.id,
		stats = {frames = 0, time = 0, bucketN = 0, bucketT = 0, worst = nil, yMin = nil, yMax = nil, speedMax = 0}}
	R.follow.forShot = shot.id
	if shot.need and shot.need.plowAt and shot.need.plowAt.by > shot.start + 0.01 and variant.name == "primary" then
		cur.deferAt = shot.need.plowAt.by
	end
	R.cur = cur
	pulseSnap()
	grade(shot.grade)
	if shot.hideReal then
		local list = {}
		local m = plowModel()
		for _, root in ipairs({m, player.Character, workspace:FindFirstChild("FollowingPets")}) do
			if root then for _, d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then table.insert(list, d) end end end
		end
		R.shotHide = list
	end
	for _, path in ipairs(Shots.Hide.ShotGeometry[shot.id] or {}) do
		local inst = findPath(path:gsub("^Workspace%.", ""))
		if inst then
			if inst:IsA("BasePart") then table.insert(R.shotHide, inst) end
			for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then table.insert(R.shotHide, d) end end
		end
	end
	if shot.id == "S03_Bay" or shot.id == "S04_BayOrbit" then
		local pl = pedestalLight()
		if pl then setProp(pl, "Enabled", true); R.pedLight = pl else log("shot %s: pedestal 2 light not found", shot.id) end
	end
	if variant.minis then hideRealMinis(cur) end
	log("shot %s pass %s variant %s%s", shot.id, pass, variant.name, variant.why and (" (" .. variant.why .. ")") or "")
end
local function shotFrame(shot, pass, tauShot, tauAbs, dt)
	local key = shot.id .. pass
	if R.curKey ~= key then R.curKey = key; startShot(shot, pass, tauShot) end
	local cur = R.cur
	if cur.deferAt and tauShot >= cur.deferAt then
		cur.deferAt = nil
		local ok, why = needOk(shot.need, tauShot, true)
		if not ok then
			for _, f in ipairs(shot.fallbacks or {}) do if f.sameCam then cur.variant = {cam = shot.cam, puppet = shot.puppet ~= nil, name = f.name, why = why} break end end
			log("shot %s deferred check: %s -> %s", shot.id, why, cur.variant.name)
		end
	end
	local u = (tauShot - shot.start) / shot.dur
	local cf, fov = evalCam(cur.variant.cam, u, dt, cur.snap)
	cur.snap = false
	-- puppets / puppet minis (clock = trailer time of this shot's pass A slot)
	local pup = R.puppets[shot.id]
	if pup then
		local on = cur.variant.puppet == true
		pup.obj:Show(on)
		if on then
			local ok, rootCF = pcall(pup.fn, tauShot)
			if ok and rootCF then pup.obj:Place(rootCF) end
		end
	end
	if cur.variant.minis and R.minis then
		R.minis:Show(true)
		R.minis:Update(tauAbs)
	end
	if cur.variant.minis and R.frameNo % 10 == 0 then hideRealMinis(cur) end
	-- stats
	local st = cur.stats
	st.frames += 1
	st.time += dt
	st.bucketN += 1
	st.bucketT += dt
	if st.bucketT >= Shots.Config.FpsBucket then
		local fps = st.bucketN / st.bucketT
		st.worst = st.worst and math.min(st.worst, fps) or fps
		st.bucketN, st.bucketT = 0, 0
	end
	local hull = plowHull()
	if hull then st.speedMax = math.max(st.speedMax, Math.flat(hull.AssemblyLinearVelocity).Magnitude) end
	if shot.logY and cf then
		local subject
		if shot.subject == "puppet" and pup and cur.variant.puppet then subject = pup.obj.model:GetPivot().Position + Vector3.new(0, 2, 0)
		elseif shot.subject == "plow" and hull then subject = hull.Position + Vector3.new(0, 1.5, 0) end
		if subject then cur.subject = subject end
	end
	return cf, fov
end

--------------------------------------------------------------------------------------------------------------------------------
-- per-frame (TrailerCam, RenderPriority.Last)
--------------------------------------------------------------------------------------------------------------------------------
local function black(on)
	R.text:SetBlack(on)
	if on then R.text:Update(nil) end
end
local function runFrame(dt)
	local cfg = Shots.Config
	local t = serverNow() - R.rollA
	local tau = t + R.split.from
	if not R.markA and t >= 0 then
		R.markA = true
		log("TRAILER_ROLL_A unixms=%d server=%.3f split=%s", unixms(), serverNow(), R.splitName)
	end
	driverStep(tau, nil)
	local Sp, B = R.split, cfg.PassB
	local cf, fov
	if t < 0 or tau < Sp.from then
		black(true)
		return R.lastCF, R.lastFov
	elseif tau < Sp.to then
		local shot
		for _, s in ipairs(Shots.Shots) do if tau >= s.start and tau < s.start + s.dur then shot = s break end end
		if not shot then black(true) return R.lastCF, R.lastFov end
		black(false)
		cf, fov = shotFrame(shot, "A", tau, tau, dt)
		R.text:Update(tau)
	elseif Sp.passB and tau < B.rollB then
		if R.cur then endShot(); R.curKey = nil end
		black(true)
		return R.lastCF, R.lastFov
	elseif Sp.passB and tau < B.rollB + B.length then
		if not R.markB then
			R.markB = true
			log("TRAILER_ROLL_B unixms=%d server=%.3f", unixms(), serverNow())
		end
		black(false)
		cf, fov = shotFrame(shotById[B.shot], "B", tau - B.shift, tau, dt)
		R.text:Update(tau)
	else
		if R.cur then endShot(); R.curKey = nil end
		local endT = Sp.passB and (B.rollB + B.length) or Sp.to
		if tau < endT + cfg.EndBlack then
			black(true)
		elseif tau < endT + cfg.EndBlack + cfg.EndMagenta then
			black(true)
			R.text:SetSlate(true)
		else
			R.text:SetSlate(false)
			if not R.finished then
				R.finished = true
				local worst = math.huge
				for _, f in ipairs(R.fps) do if f > 0 then worst = math.min(worst, f) end end
				log("TRAILER_DONE unixms=%d server=%.3f worst_shot_fps=%.1f", unixms(), serverNow(), worst == math.huge and 0 or worst)
			end
		end
		return R.lastCF, R.lastFov
	end
	return cf, fov
end
local function gateFrame(dt)
	if R.splitName == "9-11" then
		driverStep(R.split.from - 1, R.preMove)
		local cam = shotById["S09_CandyGate"].cam
		if not R.camCache[cam] then prepCam(cam) end
		return evalCam(cam, 0, dt, false)
	end
	driverStep(-1, nil)
	local s1 = shotById["S01_StarterAfk"]
	if not R.camCache[s1.cam] then prepCam(s1.cam) end
	local snap = R.follow.forShot ~= s1.id
	R.follow.forShot = s1.id
	return evalCam(s1.cam, 0, dt, snap)
end
local function onFrame(dt)
	if not R or R.restored then return end
	R.frameNo += 1
	local okH, errH = pcall(hidePass)
	if not okH and not R.hideErr then R.hideErr = true; warn("[Trailer] hide pass: " .. tostring(errH)) end
	local cf, fov
	local ok, err = pcall(function()
		if R.phase == "run" then cf, fov = runFrame(dt)
		elseif R.phase == "gate" or R.phase == "armed" then cf, fov = gateFrame(dt)
		else cf, fov = R.parkCF, R.parkFov end
	end)
	if not ok then
		warn("[Trailer] frame error: " .. tostring(err))
		task.defer(Client.Abort, "frame error")
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then return end
	if cam.CameraType ~= Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Scriptable end
	if cf then cam.CFrame = cf; R.lastCF = cf end
	if fov then R.lastFov = fov end
	cam.FieldOfView = R.text:CorrectFov(R.lastFov or 70)
	-- subject screen-Y (fraction of the SafeFrame height) for the shot log
	local cur = R.cur
	if cur and cur.subject then
		local v, on = cam:WorldToViewportPoint(cur.subject)
		local y = on and R.text:SafeY(v.Y)
		if y then
			cur.stats.yMin = cur.stats.yMin and math.min(cur.stats.yMin, y) or y
			cur.stats.yMax = cur.stats.yMax and math.max(cur.stats.yMax, y) or y
		end
		cur.subject = nil
	end
end

--------------------------------------------------------------------------------------------------------------------------------
-- Lock / Restore
--------------------------------------------------------------------------------------------------------------------------------
local function newRun(mode, opts)
	local split = Shots.Config.Split[opts.split or ""] or Shots.Config.Split.full
	return {
		mode = mode, split = split, splitName = Shots.Config.Split[opts.split or ""] and opts.split or "full", runId = opts.run,
		-- strong tables on purpose (review fix): a weak Instance key can be dropped while the Instance still exists
		-- (MachineLocksClient L12), and a re-record would then save the hidden value; restore() empties them
		saved = {}, hooked = {}, conns = {},
		pgGuis = {}, worldGuis = {}, beams = {},
		humanoids = {}, hiddenModels = {}, paywallHidden = {},
		paywalls = {}, keep = {}, shotHide = {}, anchors = {}, routes = {}, flags = {}, puppets = {}, variants = {}, camCache = {},
		follow = {}, join = {}, yawHist = {}, fps = {}, frameNo = 0, lastMove = "unset",
		C = require(RS:WaitForChild("PlowConfig")),
	}
end
-- review fix: the PlayerModule may live in StarterPlayer, and the current one (Input Action System) has no GetControls
-- (PlowDriveClient L173-193); its InputContexts.CharacterContext is then switched off through setProp (restored once)
local function playerModule()
	local ps = player:FindFirstChild("PlayerScripts")
	local pm = (ps and ps:FindFirstChild("PlayerModule")) or game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
	return pm and pm:IsA("ModuleScript") and pm or nil
end
local function controlsModule(pm)
	if not pm then return nil end
	local ok, m = pcall(require, pm)
	if ok and type(m) == "table" and m.GetControls then
		local ok2, c = pcall(function() return m:GetControls() end)
		if ok2 then return c end
	end
	return nil
end
local function lockControls()
	local pm = playerModule()
	R.controls = controlsModule(pm)
	local how = {}
	if R.controls then pcall(function() R.controls:Disable() end); table.insert(how, "GetControls:Disable") end
	local ctx = pm and pm:FindFirstChild("InputContexts")
	local cc = ctx and ctx:FindFirstChild("CharacterContext")
	if cc and select(2, pcall(function() return cc:IsA("InputContext") end)) == true then setProp(cc, "Enabled", false); R.charContext = cc; table.insert(how, "CharacterContext off") end
	log("controls lock: %s", #how > 0 and table.concat(how, " + ") or "NONE FOUND (input during the take still moves the character)")
end
local function lock()
	local cam = workspace.CurrentCamera
	R.cam = {type = cam.CameraType, subject = cam.CameraSubject, fov = cam.FieldOfView, cf = cam.CFrame}
	R.parkCF, R.parkFov, R.lastCF, R.lastFov = cam.CFrame, cam.FieldOfView, cam.CFrame, cam.FieldOfView
	R.core = {}
	for _, t in ipairs(Enum.CoreGuiType:GetEnumItems()) do
		if t ~= Enum.CoreGuiType.All then
			local ok, v = pcall(function() return StarterGui:GetCoreGuiEnabled(t) end)
			if ok then R.core[t] = v end
		end
	end
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
	local run = R
	task.spawn(function()
		for _ = 1, 20 do
			if run.restored then return end
			if pcall(function() StarterGui:SetCore("TopbarEnabled", false) end) then run.topbarOff = true return end
			task.wait(0.25)
		end
	end)
	setProp(UIS, "MouseIconEnabled", false)
	for _, n in ipairs({"ChatWindowConfiguration", "ChatInputBarConfiguration", "BubbleChatConfiguration"}) do
		local c = TextChatService:FindFirstChild(n)
		if c then setProp(c, "Enabled", false) end
	end
	setProp(ProximityPromptService, "Enabled", false)
	lockControls()
	local pg = player:FindFirstChildOfClass("PlayerGui")
	local tut = pg and pg:FindFirstChild("PlowTutorial")
	local dbg = tut and tut:FindFirstChild("TutorialDebug")
	if dbg and dbg:IsA("BindableFunction") then pcall(function() dbg:Invoke("Stop") end) end
	R.suppress0 = player:GetAttribute("SuppressEvents")
	player:SetAttribute("SuppressEvents", true)
	R.snap0 = player:GetAttribute("LightingSnap")
	local g = Instance.new("ColorCorrectionEffect")
	g.Name = "TrailerGrade"
	g.Parent = cam
	R.grade = g
	Gui.Enabled = true
	R.text = Text.Mount(Gui, Shots, Math)
	R.text:SetLetterbox(true)
	scanAll()
	-- review fix: PlowDriveClient captures baseFov on Heartbeat and writes it back when the drift FX idles (L399-402, L577);
	-- Stepped runs before Heartbeat, so it always sees the player's own FOV. TrailerCam sets the shot FOV before rendering.
	table.insert(R.conns, RunService.Stepped:Connect(function()
		if run.restored then return end
		local c = workspace.CurrentCamera
		if c and run.cam then c.FieldOfView = run.cam.fov end
	end))
	RunService:BindToRenderStep("TrailerCam", Enum.RenderPriority.Last.Value, onFrame)
	R.bound = true
	log("lock: %d world GUIs, %d PlayerGui collectors held off", (function() local n = 0 for _ in pairs(R.worldGuis) do n += 1 end return n end)(),
		(function() local n = 0 for _ in pairs(R.pgGuis) do n += 1 end return n end)())
	local walls = {}
	for m in pairs(R.paywallHidden) do table.insert(walls, tostring(m:GetAttribute("Stage"))) end
	table.sort(walls)
	log("lock: locked paywall walls hidden (LTM 1): %s; HELP YARD signs hidden: %d", #walls > 0 and table.concat(walls, ", ") or "none", R.helpSigns or 0)
end
local function restore()
	if not R or R.restored then return end
	R.restored = true
	local report = {reason = R.abortReason or "done", mode = R.mode, split = R.splitName, restored = 0, failed = 0}
	if R.bound then pcall(function() RunService:UnbindFromRenderStep("TrailerCam") end) end
	for _, c in ipairs(R.conns) do pcall(function() c:Disconnect() end) end
	for _, c in pairs(R.hooked) do pcall(function() c:Disconnect() end) end
	pcall(function() player:SetAttribute("PlowTestMove", nil) end)
	R.lastMove = "unset"
	if R.cur then pcall(endShot) end
	for inst, rec in pairs(R.saved) do
		for prop, w in pairs(rec) do
			local ok = pcall(function() inst[prop] = restoreValue(inst, prop, w.v) end)
			if ok then report.restored += 1 else report.failed += 1 end
		end
	end
	if R.core then
		for t, v in pairs(R.core) do pcall(function() StarterGui:SetCoreGuiEnabled(t, v) end) end
	end
	if R.topbarOff then pcall(function() StarterGui:SetCore("TopbarEnabled", true) end) end
	if R.controls then pcall(function() R.controls:Enable() end) end
	if not R.refs then pcall(function() player:SetAttribute("SuppressEvents", R.suppress0) end) end
	pcall(function() player:SetAttribute("LightingSnap", R.snap0) end)
	for _, p in pairs(R.puppets) do pcall(function() p.obj:Destroy() end) end
	if R.minis then pcall(function() R.minis:Destroy() end) end
	pcall(Puppets.DestroyFolder)
	if R.grade then R.grade:Destroy() end
	if R.text then pcall(function() R.text:HideAll(); R.text:Destroy() end) end -- Destroy drops the AbsoluteSize connection
	local cam = workspace.CurrentCamera
	if cam and R.cam then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		pcall(function()
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = hum or R.cam.subject
		end)
		local fov = R.cam.fov
		RunService.RenderStepped:Once(function() pcall(function() cam.FieldOfView = fov end) end)
	end
	local music = SoundService:FindFirstChild("Music")
	report.camera = cam and cam.CameraType.Name or "?"
	report.prompts = ProximityPromptService.Enabled
	report.mouseIcon = UIS.MouseIconEnabled
	report.music = music and music:IsA("SoundGroup") and music.Volume or nil
	report.plowTestMove = tostring(player:GetAttribute("PlowTestMove"))
	report.afkPlow = tostring(player:GetAttribute("AfkPlow"))
	report.puppetsGone = workspace:FindFirstChild("TrailerPuppets") == nil
	report.controls = R.controls ~= nil
	report.unixms = unixms()
	report.charContext = R.charContext and tostring(R.charContext.Enabled) or nil
	local okJ, json = pcall(function() return HttpService:JSONEncode(report) end)
	log("restore report %s", okJ and json or "?")
	-- free the strong records (review fix: they are strong tables now)
	R.saved, R.hooked, R.pgGuis, R.worldGuis, R.beams, R.humanoids, R.hiddenModels = {}, {}, {}, {}, {}, {}, {}
	R.paywallHidden = {}
	R.shotHide, R.pedLight = {}, nil
	task.delay(0.5, function()
		local c = workspace.CurrentCamera
		if c and c.CameraType == Enum.CameraType.Scriptable then
			warn("[Trailer] camera still Scriptable after restore - forcing Custom")
			c.CameraType = Enum.CameraType.Custom
		end
	end)
end

function Client.Abort(reason)
	if not R or R.restored then return end
	R.aborted = true
	R.abortReason = tostring(reason)
	log("ABORT (%s) unixms=%d", tostring(reason), unixms())
	-- review fix: before ROLL the server run is still active (AFK held on, TrailerGo refused); tell it. request() refuses after ROLL.
	if not R.rollA and not R.refs then pcall(request, "Abort", {}) end
	restore()
	state = "aborted"
end

--------------------------------------------------------------------------------------------------------------------------------
-- the run
--------------------------------------------------------------------------------------------------------------------------------
function Client.Run(mode, opts)
	opts = opts or {}
	if R and not R.restored then error("a run is already active") end
	R = newRun(mode, opts)
	local cfg = Shots.Config
	state = "lock"
	log("run %s mode=%s split=%s rev=%s", tostring(opts.run), tostring(mode), R.splitName, Shots.Version)
	lock()
	-- 1 slate
	state = "slate"
	R.phase = "slate"
	R.text:SetSlate(true)
	log("SLATE_START unixms=%d", unixms())
	local t0 = os.clock()
	waitUntil(function() return player:GetAttribute("CropOK") == true or os.clock() - t0 >= cfg.SlateMax end)
	R.text:SetSlate(false)
	log("SLATE_END unixms=%d cropOK=%s %s", unixms(), tostring(player:GetAttribute("CropOK") == true), table.concat(R.text:CapReport(), "; "))
	-- 2 warm-up (black)
	state = "warm"
	R.phase = "warm"
	black(true)
	warmUp()
	-- 3 wait for the plow
	state = "gate"
	R.text:SetReady(mode == "rehearse")
	local tGate, lastLog = os.clock(), 0
	if R.splitName == "9-11" then
		for _, m in ipairs(Shots.PlowMoves) do if m.id == "toHold" then R.preMove = m end end
	end
	R.phase = "gate"
	local why = ""
	local armed = waitUntil(function()
		local ok, w = (R.splitName == "9-11" and gateSplit or gateCheck)(tGate)
		why = w or ""
		if os.clock() - lastLog >= cfg.Gate.Log then lastLog = os.clock(); log("gate: %s", why) end
		return ok
	end, cfg.GateTimeout)
	R.text:SetReady(false)
	if not armed then
		Client.Abort("gate timeout: " .. why)
		return
	end
	log("gate armed: %s", why)
	-- 4 arm (last client-to-server message)
	local before = player:GetAttribute("TrailerRollA")
	request("ArmRoll", {run = opts.run})
	state = "armed"
	R.phase = "armed"
	local got = waitUntil(function()
		local v = player:GetAttribute("TrailerRollA")
		return type(v) == "number" and v ~= before
	end, cfg.RollWait)
	if not got then
		Client.Abort("no TrailerRollA from the server")
		return
	end
	R.rollA = player:GetAttribute("TrailerRollA")
	R.preMove, R.move, R.moveIdx = nil, nil, nil
	if R.splitName == "9-11" then -- the plow already waits at P_hold: continue from "toHold" (its route is done)
		for i, m in ipairs(Shots.PlowMoves) do if m.id == "toHold" then R.moveIdx = i - 1 end end
	end
	-- 5-9 black, pass A, gap, pass B, end
	state = "running"
	R.phase = "run"
	waitUntil(function() return R.finished == true end, cfg.MaxTotal + 30)
	if not R.finished then
		Client.Abort("run did not finish in time")
		return
	end
	restore()
	state = "done"
end

--------------------------------------------------------------------------------------------------------------------------------
-- round 1 references (player attribute TrailerRefs; DESIGN 14.3)
--------------------------------------------------------------------------------------------------------------------------------
local function round3(x) return math.floor(x * 1000 + 0.5) / 1000 end
local function cfArray(cf) local t = {cf:GetComponents()}; for i, x in ipairs(t) do t[i] = round3(x) end return t end
local function rootOf(hull)
	local V = R.C.Vehicle
	return hull.CFrame * CFrame.new(0, -(V.HullClearance + V.HullSize.Y / 2), 0)
end
local function waitSeated(near, radius, timeout)
	local ok = waitUntil(function()
		local hull = plowHull()
		return hull ~= nil and (not near or Math.flat(hull.Position - near).Magnitude <= radius)
	end, timeout)
	return ok and plowHull() or nil
end
-- blocking drive along a path (refs only; same controller as the take); onStep(hull) is called every Heartbeat
local function driveRoute(path, opts, onStep)
	local ms = {path = path, idx = 1, stop = opts.stop ~= false, cruise = opts.cruise, reverse = opts.reverse}
	local t0 = os.clock()
	while os.clock() - t0 < (opts.timeout or 40) do
		if aborted() then error("aborted", 0) end
		local hull = plowHull()
		if hull then
			local arrived = routeStep(ms, hull)
			if onStep then onStep(hull) end
			if arrived then break end
		end
		RunService.Heartbeat:Wait()
	end
	sendMove(0, 0)
	return ms.arrived == true
end
local function recordTrack(name, def, kind)
	local C = R.C
	local stats = C.StatsFor(Shots.Profile.HeroC, {})
	resolveAnchors()
	local from, to = point(def.from), point(def.to)
	from, to = groundPoint(from, from.Y + 10), groundPoint(to, to.Y + 10)
	local dir = Math.flatUnit(to - from)
	local pre = groundPoint(from - dir * 25, from.Y)
	local hull = waitSeated(to, 400, 30)
	if not hull then log("REF %s: no seated plow near %s", name, v3s(to)) return end
	driveRoute({hull.Position, pre}, {stop = true, timeout = 40})
	sleep(0.8)
	local cruise
	if kind == "stop" then
		local b = stats.Accel * C.Drive.BrakeFactor * Shots.Config.Puppet.BrakeShare
		cruise = Math.cruiseThenBrake((to - from).Magnitude, def.stop - def.enter, b)
	else
		cruise = (to - from).Magnitude / math.max(def.exit - def.enter, 0.1)
	end
	local frames, cfs = {}, {}
	local hz, acc, anchorIdx = Shots.Config.Puppet.RecordHz, 0, nil
	local last = os.clock()
	local path = kind == "stop" and {pre, from, to} or {pre, from, to, to + dir * 20}
	driveRoute(path, {stop = true, cruise = cruise, timeout = 40}, function(h)
		local now = os.clock()
		acc += now - last
		last = now
		while acc >= 1 / hz do
			acc -= 1 / hz
			table.insert(cfs, rootOf(h))
			if kind == "pass" and not anchorIdx and (h.Position - to):Dot(dir) >= 0 then anchorIdx = #cfs end
		end
	end)
	-- review fix: a 'stop' track is anchored on the frame where the plow came to rest, not on the end of the hold padding below
	if kind == "stop" and #cfs > 0 then anchorIdx = #cfs end
	for _ = 1, math.floor(hz * 0.5) do
		local h = plowHull()
		if h then table.insert(cfs, rootOf(h)) end
		task.wait(1 / hz)
		if aborted() then error("aborted", 0) end
	end
	if #cfs < 2 then log("REF %s: nothing recorded", name) return end
	anchorIdx = anchorIdx or #cfs
	local anchorCF = cfs[anchorIdx]
	for _, cf in ipairs(cfs) do
		local rel = anchorCF:ToObjectSpace(cf)
		local look = Math.flatUnit(rel.LookVector)
		table.insert(frames, {round3(rel.X), round3(rel.Y), round3(rel.Z), round3(Math.yawOf(look))})
	end
	local stopErr = Math.flat(anchorCF.Position - to).Magnitude
	log("REF_TRACK %s %s", name, HttpService:JSONEncode({hz = hz, anchor = anchorIdx, frames = frames}))
	log("REF %s recorded %d frames, cruise %.1f, anchor error %.2f studs", name, #frames, cruise or -1, stopErr)
end
local function refsLeg(leg)
	if leg == "seat" then
		local hull = waitSeated(nil, nil, 20)
		if not hull then log("REF seat: no seated plow") return end
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		local seat = hum and hum.SeatPart
		local weld = seat and seat:FindFirstChild("SeatWeld")
		if weld and weld:IsA("JointInstance") then
			log("REF_SEATWELD %s", HttpService:JSONEncode({C0 = cfArray(weld.C0), C1 = cfArray(weld.C1)}))
		else
			log("REF seat: SeatWeld not found under %s", seat and seat:GetFullName() or "nil")
		end
		local SF = require(RS:WaitForChild("SnowFields"))
		for _, f in ipairs(SF.Fields) do
			if f.Style == "Starter" then log("REF starter field %s %dx%d tiles = %.0fx%.0f studs, AFK lanes along %s", f.Id, f.Width, f.Depth,
				f.Width * SF.TileSize, f.Depth * SF.TileSize, (f.Width >= f.Depth) and "X" or "Z") end
		end
		-- field drive numbers: 2 s full throttle, then brake
		local samples, t0 = {}, os.clock()
		local dir = Math.flatUnit(hull.CFrame.LookVector)
		while os.clock() - t0 < 2.0 do
			local h = plowHull()
			if not h then break end
			sendMove(0, -1)
			table.insert(samples, string.format("%.2f:%.1f", os.clock() - t0, fwdSpeed(h)))
			sleep(0.1) -- raises "aborted" at once after an abort (review fix)
		end
		local h = plowHull()
		local v0, p0 = h and fwdSpeed(h) or 0, h and h.Position or Vector3.zero
		local t1 = os.clock()
		while os.clock() - t1 < 3 do
			h = plowHull()
			if not h or math.abs(fwdSpeed(h)) < 0.3 then break end
			sendMove(0, 1)
			RunService.Heartbeat:Wait()
			if aborted() then error("aborted", 0) end
		end
		sendMove(0, 0)
		local brakeD = h and (h.Position - p0):Dot(dir) or -1
		log("REF_DRIVE field %s", HttpService:JSONEncode({MaxSpeed = hull:GetAttribute("MaxSpeed"), Accel = hull:GetAttribute("Accel"),
			TurnRate = hull:GetAttribute("TurnRate"), speed = samples, brakeFrom = round3(v0), brakeDist = round3(brakeD), brakeTime = round3(os.clock() - t1)}))
	elseif leg == "desert" then
		recordTrack("Desert", shotById["S06_DesertEgg"].puppet, "stop")
	elseif leg == "crystal" then
		recordTrack("Crystal", shotById["S07_Crystal"].puppet, "pass")
	elseif leg == "candy" then
		sleep(5)
		local rec = fieldRecord(player:GetAttribute("MiniField"))
		log("REF minis MiniField=%s style=%s MiniCount=%s MiniBuild=%s", tostring(player:GetAttribute("MiniField")), rec and tostring(rec.Style) or "?",
			tostring(player:GetAttribute("MiniCount")), tostring(player:GetAttribute("MiniBuild")))
		local cur = findPath(Shots.Anchors.Paths.Curtains)
		local names = {}
		if cur then for _, c in ipairs(cur:GetChildren()) do table.insert(names, c.Name) end end
		log("REF curtains: %s", table.concat(names, ", "))
		R.paywalls = {}
		for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d.Name == "StagePaywall_Model" then table.insert(R.paywalls, d) end end
		R.anchors.G = nil
		resolveAnchors()
		local wall = R.anchors.G and R.anchors.G.wall
		log("REF candy gate %s live=%s wall transparency=%s cancollide=%s", v3s(R.anchors.G.p), tostring(R.anchors.G.live),
			wall and string.format("%.2f", wall.Transparency) or "?", wall and tostring(wall.CanCollide) or "?")
	end
end
function Client.RunRefs(mode)
	if R and not R.restored then error("a run is already active") end
	R = newRun(mode, {})
	R.refs = true
	state = "refs"
	lockControls()
	log("REFS start (round 1 references)")
	local lastLeg
	while true do
		local ok = waitUntil(function()
			local l = player:GetAttribute("TrailerRefsLeg")
			if lastLeg == nil and l ~= "seat" then return false end -- review fix: a stale leg from an earlier refs run is ignored
			return l ~= nil and l ~= lastLeg
		end, 180)
		if not ok then Client.Abort("refs: no next leg from the server") return end
		local leg = player:GetAttribute("TrailerRefsLeg")
		lastLeg = leg
		log("REFS leg %s", tostring(leg))
		if leg == "done" then break end
		local okLeg, err = pcall(refsLeg, leg)
		if aborted() then return end
		if not okLeg then
			if tostring(err) == "aborted" then return end
			warn("[Trailer] refs leg " .. tostring(leg) .. ": " .. tostring(err))
		end
		request("RefsNext", {leg = leg})
	end
	restore()
	state = "done"
	log("REFS_DONE")
end

return Client
