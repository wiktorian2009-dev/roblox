-- ArenaDriveClient (2026-10-05, Claude): the ONE movement controller for your Snowplow Bumper Arena vehicle.
-- It combines driving input, BOOST / BRACE movement, server knockback (added on top of the drive velocity and decayed, so driving
-- never overwrites it), local separation from other vehicles (they never pass through each other while the server decides the hit),
-- ride height and upright stability. The normal PlowDriveClient only drives workspace.Snowplows.Snowplow_<id>, so the two never
-- touch the same vehicle. Abilities are predicted here and confirmed by the server (ArenaService owns the real windows and hits).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local A = require(RS:WaitForChild("ArenaConfig"))
local V, K = A.Vehicle, A.Knock
local remote = RS:WaitForChild("ArenaRemote")
local event = RS:WaitForChild("ArenaEvent")
local folder = workspace:WaitForChild("ArenaVehicles")
local now = function() return workspace:GetServerTimeNow() end

local Api = {} -- shared with ArenaHudClient through a BindableFunction (cooldowns, request abilities)
local knock, pendingKnock, lastCmd, lastSep = Vector3.zero, Vector3.zero, Vector3.zero, Vector3.zero
local myLife = 0
local local_ = {boostUntil = 0, boostReady = 0, braceUntil = 0, braceReady = 0}

-- input: the standard PlayerModule move vector (keyboard, thumbstick, gamepad), with a direct keyboard fallback
local controls
task.spawn(function()
	local t0 = os.clock()
	while not controls and os.clock() - t0 < 30 do
		local ps = player:FindFirstChild("PlayerScripts")
		local pm = (ps and ps:FindFirstChild("PlayerModule")) or game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
		if pm and pm:IsA("ModuleScript") then
			local ok, m = pcall(require, pm)
			if ok and type(m) == "table" and m.GetControls then controls = m:GetControls() end
		end
		if not controls then task.wait(0.5) end
	end
end)
local KEYS = {[Enum.KeyCode.W] = Vector3.new(0, 0, -1), [Enum.KeyCode.Up] = Vector3.new(0, 0, -1), [Enum.KeyCode.S] = Vector3.new(0, 0, 1), [Enum.KeyCode.Down] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0), [Enum.KeyCode.Left] = Vector3.new(-1, 0, 0), [Enum.KeyCode.D] = Vector3.new(1, 0, 0), [Enum.KeyCode.Right] = Vector3.new(1, 0, 0)}
local function moveVector()
	if RS:GetAttribute("PlowTestHooks") then
		local t = player:GetAttribute("PlowTestMove")
		if typeof(t) == "Vector3" then return t end
	end
	if controls then
		local ok, v = pcall(function() return controls:GetMoveVector() end)
		if ok and v and v.Magnitude > 0.01 then return v end
	end
	local v = Vector3.zero
	if not UIS:GetFocusedTextBox() then for key, dir in pairs(KEYS) do if UIS:IsKeyDown(key) then v += dir end end end
	for _, st in ipairs(UIS:GetGamepadState(Enum.UserInputType.Gamepad1)) do
		if st.KeyCode == Enum.KeyCode.Thumbstick1 and st.Position.Magnitude > 0.15 then v += Vector3.new(st.Position.X, 0, -st.Position.Y) end
	end
	return v.Magnitude > 1 and v.Unit or v
end

local function myModel() return folder:FindFirstChild("Arena_" .. player.UserId) end
local function seated(model)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return hum and hum.SeatPart and hum.SeatPart.Parent == model, hum
end
local function serverWindow(hull, key) return (hull and hull:GetAttribute(key)) or 0 end
local function boosting(hull) local t = now(); return t < local_.boostUntil or t < serverWindow(hull, "BoostUntil") end
local function bracing(hull) local t = now(); return t < local_.braceUntil or t < serverWindow(hull, "BraceUntil") end
local function shielded(hull) return now() < serverWindow(hull, "ShieldUntil") end

-- abilities: predicted locally, confirmed (or cancelled) by the server
local busy = {}
local function useAbility(kind)
	local model = myModel()
	local hull = model and model.PrimaryPart
	if not hull or not seated(model) then return false end
	local t = now()
	local readyKey, untilKey = kind == "Boost" and "boostReady" or "braceReady", kind == "Boost" and "boostUntil" or "braceUntil"
	if t < math.max(local_[readyKey], serverWindow(hull, kind == "Boost" and "BoostReady" or "BraceReady")) or busy[kind] then return false end
	local dur = kind == "Boost" and A.Boost.Duration or A.Brace.Duration
	local cd = kind == "Boost" and A.Boost.Cooldown or A.Brace.Cooldown
	local_[untilKey], local_[readyKey] = t + dur, t + cd
	busy[kind] = true
	task.spawn(function()
		local ok, res = pcall(function() return remote:InvokeServer(kind, hull:GetAttribute("Life")) end)
		busy[kind] = nil
		if not (ok and type(res) == "table" and res.ok) then
			local_[untilKey] = 0
			if ok and type(res) == "table" and res.ready then local_[readyKey] = res.ready else local_[readyKey] = 0 end
		else
			local_[untilKey], local_[readyKey] = res.untilT or local_[untilKey], res.ready or local_[readyKey]
		end
	end)
	return true
end
Api.Use = useAbility
Api.Cooldown = function(kind) -- seconds left, 0..cd ; and active?
	local model = myModel()
	local hull = model and model.PrimaryPart
	local t = now()
	local ready = math.max(kind == "Boost" and local_.boostReady or local_.braceReady, serverWindow(hull, kind == "Boost" and "BoostReady" or "BraceReady"))
	local active = kind == "Boost" and boosting(hull) or (kind == "Brace" and bracing(hull))
	return math.max(0, ready - t), active, hull ~= nil and (seated(model) and true or false)
end
local bf = Instance.new("BindableFunction"); bf.Name = "ArenaDriveApi"; bf.Parent = script
bf.OnInvoke = function(op, a) if op == "Use" then return useAbility(a) elseif op == "Cooldown" then return Api.Cooldown(a) end end

CAS:BindAction("ArenaBoost", function(_, state)
	if state == Enum.UserInputState.Begin and myModel() then useAbility("Boost") return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonX)
CAS:BindAction("ArenaBrace", function(_, state)
	if state == Enum.UserInputState.Begin and myModel() then useAbility("Brace") return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.Q, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL1)

event.OnClientEvent:Connect(function(kind, data)
	if kind == "Knock" and type(data) == "table" and typeof(data.v) == "Vector3" then
		local model = myModel()
		local hull = model and model.PrimaryPart
		if not hull or data.life ~= hull:GetAttribute("Life") then return end -- a knock for an earlier life is ignored
		local v = Vector3.new(data.v.X, 0, data.v.Z)
		if v.Magnitude > K.MaxVel then v = v.Unit * K.MaxVel end
		pendingKnock += v -- added in the next Heartbeat, after this frame's drive velocity has been read back
		if v.Magnitude > 4 and boosting(hull) then local_.boostUntil = 0 end -- an impact ends your own boost
	elseif kind == "Spawned" then
		knock, pendingKnock, lastCmd, lastSep = Vector3.zero, Vector3.zero, Vector3.zero, Vector3.zero
		local_.boostUntil, local_.braceUntil = 0, 0
	end
end)

-- local separation: push MY vehicle out of anything it overlaps (others do the same for theirs)
local function rectOverlap(ca, la, ra, wa, da, cb, lb, rb, wb, db)
	local best, bestN
	local d = cb - ca
	for _, ax in ipairs({la, ra, lb, rb}) do
		local pa = wa * math.abs(ra:Dot(ax)) + da * math.abs(la:Dot(ax))
		local pb = wb * math.abs(rb:Dot(ax)) + db * math.abs(lb:Dot(ax))
		local gap = math.abs(d:Dot(ax)) - (pa + pb)
		if not best or gap > best then best, bestN = gap, (d:Dot(ax) >= 0 and ax or -ax) end
	end
	return best, bestN
end
local function frame(h)
	local cf = h.CFrame
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	look = look.Magnitude > 0.05 and look.Unit or Vector3.new(0, 0, -1)
	return Vector3.new(h.Position.X, 0, h.Position.Z), look, Vector3.new(-look.Z, 0, look.X), h.Size.X / 2, h.Size.Z / 2
end

local rideParams = RaycastParams.new()
rideParams.FilterType = Enum.RaycastFilterType.Exclude
rideParams.RespectCanCollide = true
local sThrottle, sSteer, sYaw = 0, 0, 0
local function approach(cur, target, rate, dt) return cur + math.clamp(target - cur, -rate * dt, rate * dt) end
local jumpOff
RunService.Heartbeat:Connect(function(dt)
	local model = myModel()
	local hull = model and model.PrimaryPart
	local isSeated, hum = false, nil
	if hull then isSeated, hum = seated(model) end
	if not (hull and isSeated) then
		sThrottle, sSteer, sYaw = 0, 0, 0
		hum = hum or (player.Character and player.Character:FindFirstChildOfClass("Humanoid"))
		if jumpOff and hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end); jumpOff = nil end
		if not hull then knock, pendingKnock, lastCmd, lastSep = Vector3.zero, Vector3.zero, Vector3.zero, Vector3.zero end
		return
	end
	if not jumpOff then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end); jumpOff = true end -- no hopping out of an imminent knockout
	dt = math.min(dt, 1 / 20)
	local t = now()
	local mv = moveVector()
	local tIn, sIn = math.clamp(-mv.Z, -1, 1), math.clamp(mv.X, -1, 1)
	sThrottle = approach(sThrottle, tIn, (math.abs(tIn) < math.abs(sThrottle) or tIn * sThrottle < 0) and 7 or 4, dt)
	sSteer = approach(sSteer, sIn, (math.abs(sIn) < math.abs(sSteer) or sIn * sSteer < 0) and 9 or 6, dt)
	local cf = hull.CFrame
	local pos, look, right = frame(hull)
	local vel = hull.AssemblyLinearVelocity
	local planarVel = Vector3.new(vel.X, 0, vel.Z)
	-- a wall (or anything solid) absorbs velocity: the loss along the push comes out of the knockback first, so being shoved into a
	-- wall stops you there instead of turning the absorbed push into a rebound
	if knock.Magnitude > 0.1 then
		local kd = knock.Unit
		local lost = (lastCmd - planarVel):Dot(kd)
		if lost > 0 then knock -= kd * math.min(lost, knock.Magnitude) end
	end
	local drive = planarVel - knock - lastSep -- remove last frame's knockback + separation: only the drive part is steered
	local fwd, lat = drive:Dot(look), drive:Dot(right)
	local isBoost, isBrace = boosting(hull), bracing(hull)
	local top = V.MaxSpeed * (isBrace and A.Brace.SpeedMult or 1)
	local target = sThrottle * top * (sThrottle < 0 and V.Reverse or 1)
	local rate = ((target * fwd < 0) or math.abs(target) < math.abs(fwd)) and V.Brake or V.Accel
	if isBoost then target, rate = A.Boost.Speed, A.Boost.Accel end
	fwd += math.clamp(target - fwd, -rate * dt, rate * dt)
	lat *= math.max(0, 1 - V.LateralGrip * dt)
	-- knockback: decays on its own, independent of steering
	knock *= math.exp(-K.Decay * dt)
	if pendingKnock.Magnitude > 0 then knock += pendingKnock; pendingKnock = Vector3.zero end
	if knock.Magnitude > K.MaxVel then knock = knock.Unit * K.MaxVel end
	if knock.Magnitude < 0.05 then knock = Vector3.zero end
	-- separation from other vehicles / targets in my zone (ghosts while shielded)
	local sep = Vector3.zero
	if not shielded(hull) then
		local zone = hull:GetAttribute("Zone")
		for _, o in ipairs(folder:GetChildren()) do
			local oh = o ~= model and o.PrimaryPart
			if oh and oh.Name == "Hull" and oh:GetAttribute("Zone") == zone and not shielded(oh) then
				local cb, lb, rb, wb, db = frame(oh)
				if (cb - pos).Magnitude < 20 then
					local gap, n = rectOverlap(pos, look, right, V.Footprint.X / 2, V.Footprint.Z / 2, cb, lb, rb, wb, db)
					if gap < 0 then
						sep -= n * math.min(-gap, 3) * 14
						local into = (look * fwd + right * lat):Dot(n)
						if into > 0 then -- stop driving into them (the server decides how hard they get pushed)
							fwd -= look:Dot(n) * into; lat -= right:Dot(n) * into
						end
					end
				end
			end
		end
	end
	if sep.Magnitude > 18 then sep = sep.Unit * 18 end -- gentle: separation only stops overlap; the server's knockback does the pushing
	local planarV = look * fwd + right * lat + knock + sep
	lastCmd, lastSep = planarV, sep
	-- ride height on the flat arena floor
	rideParams.FilterDescendantsInstances = {folder, player.Character}
	local vy = vel.Y
	local hit = workspace:Raycast(hull.Position + Vector3.new(0, 1, 0), Vector3.new(0, -(V.Clearance + hull.Size.Y / 2 + 4), 0), rideParams)
	if hit then
		local want = hit.Position.Y + V.Clearance + hull.Size.Y / 2
		vy = math.clamp((want - hull.Position.Y) * V.RideStiffness, -40, 22)
	end
	hull.AssemblyLinearVelocity = Vector3.new(planarV.X, vy, planarV.Z)
	local speedFactor = math.clamp(math.abs(fwd) / (V.MaxSpeed * V.TurnSpeedFull), V.MinTurn, 1)
	local yaw = -sSteer * V.TurnRate * speedFactor * (fwd < -0.5 and -1 or 1)
	sYaw = approach(sYaw, yaw, 16, dt)
	hull.AssemblyAngularVelocity = Vector3.new(0, sYaw, 0) + cf.UpVector:Cross(Vector3.yAxis) * 8
end)
