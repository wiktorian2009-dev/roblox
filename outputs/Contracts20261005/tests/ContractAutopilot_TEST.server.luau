-- TEST ONLY (isolated Studio Play, BalanceTestMode): drives the player's REAL snowplow along lawnmower lanes over a contract's zones.
-- Clearing, payouts, stage locks and speed checks are the real SnowFieldService code; only the steering is simulated
-- (straight lanes at 92% top speed x PlowingSpeedFactor, a fixed turn time per lane). Also logs every DataService.AddSnow amount.
-- Usage in Play: clone into ServerScriptService, then ServerStorage.ContractAutopilotHook:Invoke(player, {stage=, type=, from=, turn=}).
-- Removed from the place after testing (2026-10-05); kept here for future tuning runs.
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS.PlowConfig)
local CFG = require(RS.ContractConfig)
local Reg = require(game.ServerScriptService.PlowRegistry)
local CReg = require(game.ServerScriptService.ContractRegistry)
local DS = require(game.ServerScriptService.DataService)
local log = {}
local orig = DS.AddSnow
DS.AddSnow = function(p, a) log[p] = log[p] or {}; table.insert(log[p], a); return orig(p, a) end
local hook = SS:FindFirstChild("ContractAutopilotHook") or Instance.new("BindableFunction"); hook.Name = "ContractAutopilotHook"; hook.Parent = SS
local CT = SS:WaitForChild("ContractTestHook")
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function rectFor(player, center)
	for _, e in pairs(CReg.Fields[player] or {}) do
		if (flat(e.def.Center) - flat(center)).Magnitude < 0.5 then return e end
	end
end
local function cleared(e)
	if not e then return 1 end
	local n, z = 0, 0
	for _, p in ipairs(e.s.phases) do n += 1; if p == 0 then z += 1 end end
	return z / math.max(1, n)
end
hook.OnInvoke = function(player, opts)
	opts = opts or {}
	if opts.log then local l = log[player] or {}; log[player] = {}; return l end
	local v = Reg.Active[player]
	if not v then return {err = "no plow"} end
	local hull = v.hull
	local st = v.stats
	local off = C.Vehicle.BladeOffset
	local ycf = workspace.ContractYards["Yard_" .. opts.stage].Anchor.CFrame
	local hy = ycf.Y + C.Vehicle.HullClearance + C.Vehicle.HullSize.Y / 2
	local eff = st.BladeWidth + 1.8
	local spacing = math.max(3, eff * 0.8)
	local vmax = st.MaxSpeed * 0.92
	local plowV = vmax * (C.Drive.PlowingSpeedFactor or 0.6)
	local turnT = opts.turn or 2.0
	hull.Anchored = true
	local cur = flat(hull.Position)
	local t0 = os.clock()
	local driven, turns, passes = 0, 0, 0
	local function place(p, dir) local h = Vector3.new(p.X, hy, p.Z) - dir * off; hull.CFrame = CFrame.lookAt(h, h + dir) end
	local function go(a, b, speed)
		local d = flat(b - a)
		local L = d.Magnitude
		if L < 0.1 then return end
		local dir = d.Unit
		local t, T = 0, L / speed
		while t < T do t += task.wait(); place(a:Lerp(b, math.min(1, t / T)), dir) end
		driven += L
	end
	local function active() local i = CT:Invoke("Info", player); return not i.none and i.status == "active" end
	if opts.from then
		local gate = flat(ycf:PointToWorldSpace(Vector3.new(0, 0, -36)))
		go(flat(opts.from), gate, vmax); cur = gate
	end
	local tArrive = os.clock() - t0
	local t = CFG.ById[opts.type]
	for _, z in ipairs(t.Zones) do
		local c, w, d = CFG.ZoneWorld(ycf, z.Rect, 3)
		local e = rectFor(player, c)
		for round = 1, 5 do
			if not active() or cleared(e) >= 0.97 then break end
			local W, D = w * 3, d * 3
			local alongX = W >= D
			local across = alongX and D or W
			local n = math.max(1, math.ceil((across - eff * 0.2) / spacing))
			for k = 0, n - 1 do
				local o = (n == 1) and 0 or (-across / 2 + eff / 2 * 0.9 + k * (across - eff * 0.9) / (n - 1))
				local a, b
				if alongX then a, b = Vector3.new(c.X - W / 2 - 1, 0, c.Z + o), Vector3.new(c.X + W / 2 + 1, 0, c.Z + o)
				else a, b = Vector3.new(c.X + o, 0, c.Z - D / 2 - 1), Vector3.new(c.X + o, 0, c.Z + D / 2 + 1) end
				if (flat(cur) - b).Magnitude < (flat(cur) - a).Magnitude then a, b = b, a end
				go(cur, a, vmax * 0.6); task.wait(turnT); turns += 1
				go(a, b, plowV); cur = b; passes += 1
			end
		end
	end
	hull.Anchored = false
	pcall(function() hull:SetNetworkOwner(player) end)
	local fin = CT:Invoke("Info", player)
	return {secs = os.clock() - t0, arrive = tArrive, driven = driven, turns = turns, passes = passes, eff = eff, plowV = plowV, vmax = vmax,
		status = fin.none and "ended" or fin.status}
end
