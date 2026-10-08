-- TrailerServer (2026-10-06, Claude): server half of the page-trailer director (DESIGN rev 2, sections 2, 3, 4.2, 14.3).
-- Studio only, BalanceTestMode temp profile only. Guard = IsStudio + TrailerMode ("rehearse"/"take") + a TrailerToken (os.time
-- expiry, at most 1 h ahead) + BalanceTestMode == true, checked again here after TrailerBootstrap, before every pre-ROLL request
-- and before Prepare. Prepare sets up the Studio temp profile through the game's own test hooks (PlowTestHook, GarageTestHook,
-- TravelTestHook, ActivityTestHook, AdminHooks) and PlowRegistry; travel only goes through TravelService / PlowRegistry and no
-- seated character is ever pivoted. After ROLL the server runs its own clock (workspace:GetServerTimeNow) and never waits for the
-- client. AFK is held on (re-asserted 0.25 s after a drop, max 6 per 10 s) until 2.45 s. Cleanup is idempotent (done, abort,
-- death, leaving, cap). Nothing is saved: DataService has no store in BalanceTestMode (DataService L15).
-- Remote protocol (pre-ROLL only): TrailerRemote:FireServer("Req", reqId, action, args); actions Stream {pos}, RepublishBay, Ready,
-- ArmRoll (once per run), RefsNext {leg} (refs mode), Abort (client abort before ROLL -> cleanup). Server -> client: player
-- attributes only.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Server = {}
Server.GuiName = "TrailerDirectorGui"
local MODES = {rehearse = true, take = true}
local SPLITS = {["1-8"] = true, ["9-11"] = true}

local started = false
local kit, Shots, G
local runs = {} -- [player] = run
local remote

local function log(fmt, ...) print("[Trailer] " .. string.format(fmt, ...)) end
local function finite(x) return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge end

function Server.Guard()
	if not RunService:IsStudio() then return false, "not Studio" end
	local mode = SS:GetAttribute("TrailerMode")
	if not MODES[mode] then return false, "TrailerMode is not rehearse/take" end
	local token, now = SS:GetAttribute("TrailerToken"), os.time()
	if type(token) ~= "number" or token < now or token > now + 3600 then return false, "TrailerToken missing or expired" end
	if SS:GetAttribute("BalanceTestMode") ~= true then return false, "BalanceTestMode is not true" end
	return true, mode
end

--------------------------------------------------------------------------------------------------------------------------------
-- game modules and Studio test hooks (they exist only when BalanceTestMode was set before Play)
--------------------------------------------------------------------------------------------------------------------------------
local function loadGame()
	if G then return G end
	local g = {}
	g.DataService = require(SSS:WaitForChild("DataService"))
	g.Registry = require(SSS:WaitForChild("PlowRegistry"))
	g.ContractRegistry = require(SSS:WaitForChild("ContractRegistry"))
	g.C = require(RS:WaitForChild("PlowConfig"))
	g.StageConfig = require(RS:WaitForChild("StageConfig"))
	g.SF = require(RS:WaitForChild("SnowFields"))
	g.PlowHook = SS:WaitForChild("PlowTestHook", 20)
	g.GarageHook = SS:WaitForChild("GarageTestHook", 20)
	g.TravelHook = SS:WaitForChild("TravelTestHook", 20)
	g.ActivityHook = SS:WaitForChild("ActivityTestHook", 20)
	local hooks = SS:WaitForChild("AdminHooks", 20)
	g.ReapplyStages = hooks and hooks:FindFirstChild("ReapplyStages")
	g.ReapplyUpgrades = hooks and hooks:FindFirstChild("ReapplyUpgrades")
	g.DataRefresh = RS:WaitForChild("DataRefresh", 20)
	for _, k in ipairs({"PlowHook", "GarageHook", "TravelHook", "ActivityHook", "ReapplyStages", "ReapplyUpgrades", "DataRefresh"}) do
		if not g[k] then error("missing " .. k .. " (was BalanceTestMode true before Play?)") end
	end
	G = g
	return g
end

--------------------------------------------------------------------------------------------------------------------------------
-- AFK (AfkService L31-72 copied: same checks, same attribute order)
--------------------------------------------------------------------------------------------------------------------------------
local function fieldAt(player, pos, margin)
	local SF = G.SF
	for _, f in ipairs(SF.Fields) do
		if not f.Style or f.Style == "Starter" or player:GetAttribute("Stage_" .. f.Style) == true then
			local o = SF.Origin(f)
			local lx, lz = pos.X - o.X, pos.Z - o.Z
			local w, d = f.Width * SF.TileSize, f.Depth * SF.TileSize
			if lx > -margin and lz > -margin and lx < w + margin and lz < d + margin and math.abs(pos.Y - o.Y) < 14 then return f end
		end
	end
	return nil
end
local function afkBlocker(player)
	if player:GetAttribute("IntroActive") == true or player:GetAttribute("PlowTutorialDone") ~= true then return "tutorial" end
	if player:GetAttribute("InGarage") == true then return "garage" end
	if player:GetAttribute("InArenaIsland") == true then return "arena" end
	local f = G.ContractRegistry.Fields and G.ContractRegistry.Fields[player]
	if f ~= nil and next(f) ~= nil then return "help job" end
	local v = G.Registry.Active[player]
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not v or not v.hull or not v.hull.Parent or not v.seat or not hum or hum.Health <= 0 or hum.SeatPart ~= v.seat then return "not seated" end
	if not (v.stats and v.stats.HasBlade) then return "no blade" end
	local field = fieldAt(player, v.hull.Position, 0)
	if not field then return "not on a field" end
	return nil, field, v
end
local function afkOn(player)
	local why, f, v = afkBlocker(player)
	if why then return false, why end
	player:SetAttribute("AfkField", f.Id)
	player:SetAttribute("AfkLane", math.max(3, (v.stats.BladeWidth or 6) * G.C.Afk.LaneShare))
	player:SetAttribute("AfkPlow", true)
	return true, f.Id
end
local function afkOff(player) -- AfkService setOff (L55-59) without the client toast
	player:SetAttribute("AfkPlow", nil)
	player:SetAttribute("AfkField", nil)
	player:SetAttribute("AfkLane", nil)
end
local function holdLoop(run)
	local p, tries, lastWhy = run.player, {}, nil
	while run.active and run.hold do
		task.wait(0.25)
		if not (run.active and run.hold) then break end
		if p:GetAttribute("AfkPlow") == true then
			run.dropAt = nil
		else
			run.dropAt = run.dropAt or os.clock()
			if os.clock() - run.dropAt >= 0.25 then
				local now = os.clock()
				while tries[1] and now - tries[1] > 10 do table.remove(tries, 1) end
				if #tries < 6 then
					table.insert(tries, now)
					local ok, why = afkOn(p)
					if ok then run.dropAt = nil; log("AFK hold: re-asserted on %s", tostring(why))
					elseif why ~= lastWhy then log("AFK hold: cannot re-assert (%s)", tostring(why)) end
					lastWhy = not ok and why or nil
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------------------------------------------------------
local function profile(run)
	local d = G.DataService.Get(run.player)
	if not d or not d.Plow then error("profile not loaded") end
	return d
end
local function streamAround(run, pos)
	task.spawn(function()
		local ok, err = pcall(function() run.player:RequestStreamAroundAsync(pos, 10) end)
		if not ok then log("stream %s failed: %s", tostring(pos), tostring(err)) end
	end)
end
local function gatePos()
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and d.Name == "StagePaywall_Model" and d:GetAttribute("Stage") == "Candy" then
			local wall = d:FindFirstChild("Stage paywall")
			if wall and wall:IsA("BasePart") then return wall.Position end
		end
	end
	return nil
end
local function seated(player, timeout)
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		local v = G.Registry.Active[player]
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if v and hum and hum.SeatPart == v.seat then return true end
		task.wait(0.1)
	end
	return false
end
-- retryFor (Prepare only, review fix): a quick re-run can hit TravelService's cooldown / busy guard (L88-90); wait and retry
local function travel(run, dest, retryFor)
	local t0 = os.clock()
	local r = G.TravelHook:Invoke(run.player, dest, true)
	while retryFor and run.active and type(r) == "table" and not r.ok and (r.msg == "One moment..." or r.msg == "Already travelling...")
		and os.clock() - t0 < retryFor do
		task.wait(0.5)
		r = G.TravelHook:Invoke(run.player, dest, true)
	end
	if not (type(r) == "table" and r.ok) then error("travel " .. dest .. ": " .. tostring(type(r) == "table" and r.msg or r)) end
	return r
end
local function spawnPlow(run)
	if G.Registry.Active[run.player] then return true end
	local r = G.Registry.Spawn(run.player)
	if not (type(r) == "table" and r.ok) then error("spawn: " .. tostring(type(r) == "table" and r.msg or r)) end
	return true
end
local function nearPoint(player, name, radius)
	local tp = workspace:FindFirstChild("TravelPoints")
	local pt = tp and tp:FindFirstChild(name)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return pt and hrp and (pt.Position - hrp.Position).Magnitude <= radius or false
end
-- standing (unseated) character only: turn in place so PlowService's findSpawn (10 studs ahead) lands on the Starter field
local function faceStarterField(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.SeatPart then return end
	local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	if look.Magnitude < 1e-3 then return end
	local ahead = hrp.Position + look.Unit * G.C.Vehicle.SpawnAhead
	if fieldAt(player, Vector3.new(ahead.X, ahead.Y - 2.8, ahead.Z), -2) then return end
	for _, f in ipairs(G.SF.Fields) do
		if f.Style == "Starter" then
			local c = Vector3.new(f.Center.X, hrp.Position.Y, f.Center.Z)
			if (c - hrp.Position).Magnitude < 200 then
				char:PivotTo(CFrame.lookAt(hrp.Position, c))
				log("prep: turned the standing character toward the %s field before spawning", f.Id)
				return
			end
		end
	end
end
local function split(run) return Shots.Config.Split[run.splitName or ""] or Shots.Config.Split.full end

--------------------------------------------------------------------------------------------------------------------------------
-- Prepare (section 3)
--------------------------------------------------------------------------------------------------------------------------------
-- review fix: a step never runs once cleanup() has run (TrailerAbort / death / leaving can land while Prepare yields)
local function live(run) if not run.active then error("run cleaned up", 0) end end
local function step(run, n, name, fn)
	local ok, err = pcall(function()
		live(run)
		fn()
	end)
	log("prep %02d %-12s %s%s", n, name, ok and "ok" or "FAIL", ok and "" or (": " .. tostring(err)))
	return ok
end
local function prepare(run)
	local p = run.player
	local okG, why = Server.Guard()
	if not okG then error("guard: " .. why) end
	if p:GetAttribute("BalanceTestSession") ~= true then error("not a BalanceTestMode session (BalanceTestSession ~= true)") end
	local Profile = Shots.Profile
	local C = G.C
	local is911 = run.splitName == "9-11"
	local d = profile(run)
	if G.Registry.Active[p] then pcall(G.Registry.Park, p, "trailer") end
	afkOff(p)
	step(run, 1, "tutorial", function()
		local r1 = G.PlowHook:Invoke(p, "TutorialProgress", "Main", "Done", {Status = "done"})
		task.wait(0.06) -- PlowService rate limit (L740)
		local r2 = G.PlowHook:Invoke(p, "TutorialProgress", "Garage", "Done", {Status = "done"})
		if not (type(r1) == "table" and r1.ok and type(r2) == "table" and r2.ok) then error("TutorialProgress refused") end
	end)
	step(run, 2, "stages", function()
		for _, id in ipairs(Profile.OpenStages) do d.Stages[id] = true end
		d.Stages.Candy = nil -- Candy opens on camera at 18.10
		G.ReapplyStages:Fire(p)
	end)
	step(run, 3, "snow", function()
		d.Snow = G.StageConfig.ById.Candy.Cost + 1 -- direct write: AddSnow would raise SnowEarned (quests)
		G.DataService.SetStat(p, "Snow", d.Snow)
	end)
	step(run, 4, "machines", function()
		for _, id in ipairs(Profile.Upgrades) do d.Upgrades[id] = true end
		G.ReapplyUpgrades:Fire(p)
	end)
	step(run, 5, "pets", function()
		d.Pets = type(d.Pets) == "table" and d.Pets or {}
		d.PetIndex = type(d.PetIndex) == "table" and d.PetIndex or {}
		local eq = {}
		for _, n in ipairs(Profile.Pets) do
			d.Pets[n] = math.max(1, tonumber(d.Pets[n]) or 0)
			d.PetIndex[n] = true
			table.insert(eq, n)
		end
		d.EquippedPets = eq
		p:SetAttribute("EquippedPets", table.concat(eq, ","))
		G.DataRefresh:FireClient(p)
	end)
	step(run, 6, "parts", function()
		local pl = d.Plow
		pl.Levels = type(pl.Levels) == "table" and pl.Levels or {}
		local ids = {Profile.SwapBlade}
		for _, id in pairs(Profile.HeroC) do table.insert(ids, id) end
		for _, id in ipairs(ids) do
			if not C.Parts[id] or C.Parts[id].Role == "P" then error("bad part " .. id) end
			pl.Parts[id] = math.max(1, tonumber(pl.Parts[id]) or 0)
			pl.Levels[id] = pl.Levels[id] or 1
		end
		local build = is911 and Profile.HeroC or C.Starter
		pl.Build = {Blade = build.Blade, Engine = build.Engine, Gear = build.Gear, Body = build.Body}
	end)
	step(run, 7, "offer", function()
		local pl, o = d.Plow, Profile.Offer
		pl.Seq = (tonumber(pl.Seq) or 0) + 1
		pl.Offers = {[o.slot] = {Part = o.part, Token = HttpService:GenerateGUID(false), Price = o.price, Seq = pl.Seq, Left = o.left}}
		pl.Reserved = nil
	end)
	step(run, 8, "bay", function()
		local idx = G.GarageHook:Invoke("assign", p, d)
		if not idx then error("no free bay") end
		G.GarageHook:Invoke("publish", p, d)
		run.bay = idx
	end)
	step(run, 9, "minis", function()
		d.MiniPlows = {Level = Profile.MiniLevel, V = 1}
	end)
	step(run, 10, "avatar", function()
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if not hum then error("no humanoid") end
		hum:ApplyDescription(Instance.new("HumanoidDescription"))
		local rt = RS:FindFirstChild("TrailerRuntime")
		if rt and not rt:FindFirstChild("DriverRig") then
			local rig = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
			rig.Name = "DriverRig"
			for _, x in ipairs(rig:GetDescendants()) do if x:IsA("LuaSourceContainer") then x:Destroy() end end
			rig.Parent = rt
		end
	end)
	step(run, 11, "no events", function()
		local ev = Profile.BlockEvent
		if G.ActivityHook:Invoke("Event", nil, ev[1], ev[2]) ~= true then error("ActivityTestHook refused " .. ev[1]) end
	end)
	local okSeat = step(run, 12, "seat + AFK", function()
		local dest = is911 and "Sakura" or "Starter"
		travel(run, dest, 8)
		live(run)
		task.wait(0.4)
		live(run)
		if not G.Registry.Active[p] then
			if not is911 then faceStarterField(p) end
			spawnPlow(run)
		end
		if not seated(p, 3) then error("plow not seated") end
		live(run)
		if not is911 then
			local t0, ok, w = os.clock(), false, nil
			repeat
				live(run)
				ok, w = afkOn(p)
				if not ok then task.wait(0.25) end
			until ok or os.clock() - t0 > 4
			if not ok then error("AFK refused: " .. tostring(w)) end
			run.hold = w
			task.spawn(holdLoop, run)
		end
	end)
	step(run, 13, "done", function()
		p:SetAttribute("TrailerPrepared", okSeat)
	end)
	return okSeat
end

--------------------------------------------------------------------------------------------------------------------------------
-- cleanup (idempotent)
--------------------------------------------------------------------------------------------------------------------------------
local function cleanup(run, why)
	if run.cleaned then return end
	run.cleaned = true
	run.active = false
	run.hold = nil
	local p = run.player
	pcall(afkOff, p)
	if run.state ~= "done" then
		run.state = "aborted"
		pcall(function() p:SetAttribute("TrailerState", "aborted") end)
		-- review fix: a stale leg would end the next refs run at once; a finished refs run keeps "done" so the client sees it
		pcall(function() p:SetAttribute("TrailerRefsLeg", nil) end)
	end
	if G and G.ActivityHook then pcall(function() G.ActivityHook:Invoke("EndEvent") end) end
	log("server cleanup (%s) state=%s", tostring(why), tostring(run.state))
end

--------------------------------------------------------------------------------------------------------------------------------
-- schedule after ROLL (section 2.5): own clock, every step in its own pcall'd thread
--------------------------------------------------------------------------------------------------------------------------------
local actions = {}
function actions.Stream(run, e) streamAround(run, e.pos) end
function actions.StreamGate(run)
	local pos = gatePos()
	if not pos then error("Candy paywall not found") end
	streamAround(run, pos)
end
function actions.AfkOff(run)
	run.hold = nil
	afkOff(run.player)
end
function actions.SwapBlade(run)
	local d = profile(run)
	d.Plow.Build.Blade = Shots.Profile.SwapBlade
	G.Registry.Park(run.player, "trailer")
end
function actions.Spawn(run)
	run.spawn = "pending"
	local ok, err = pcall(spawnPlow, run)
	run.spawn = ok and "ok" or "fail"
	if not ok then error(err) end
end
function actions.SpawnRetry(run)
	if G.Registry.Active[run.player] or run.spawn == "pending" then return end
	actions.Spawn(run)
end
function actions.PublishBay(run)
	G.GarageHook:Invoke("publish", run.player, profile(run))
end
function actions.HeroBuild(run)
	local d = profile(run)
	for slot, id in pairs(Shots.Profile.HeroC) do d.Plow.Build[slot] = id end
end
function actions.Travel(run, e)
	run.travel = "pending"
	local ok, err = pcall(travel, run, e.dest)
	run.travel = ok and "ok" or "fail"
	if not ok then error(err) end
end
function actions.TravelRetry(run, e)
	if run.travel == "pending" or nearPoint(run.player, e.dest, 160) then return end
	actions.Travel(run, e)
end
function actions.UnlockCandy(run) -- StageService UnlockStage steps (L36-39) on the server
	local d = profile(run)
	local cost = G.StageConfig.ById.Candy.Cost
	if (tonumber(d.Snow) or 0) >= cost then G.DataService.AddSnow(run.player, -cost) end
	d.Stages.Candy = true
	G.ReapplyStages:Fire(run.player)
end
function actions.Done(run)
	run.state = "done"
	run.hold = nil
	run.player:SetAttribute("TrailerState", "done")
	afkOff(run.player)
end
function actions.EndTest(run)
	local ok, err = pcall(function() game:GetService("StudioTestService"):EndTest("done") end)
	if not ok then error("StudioTestService:EndTest not available (" .. tostring(err) .. ") - stop Play from the MCP or Shift+F5") end
end
function actions.Cap(run) cleanup(run, "cap") end

local function schedule(run)
	local sp = split(run)
	local list = {}
	for _, e in ipairs(Shots.Server) do
		local partOk = sp.from == 0 and sp.to >= 29.5 or (sp.to <= 18.0 and e.part == "A") or (sp.from >= 18.0 and e.part == "B")
		if partOk and e.t >= sp.from then table.insert(list, e) end
	end
	local endT = sp.passB and (Shots.Config.PassB.rollB + Shots.Config.PassB.length) or sp.to
	local tail = Shots.ServerTail
	table.insert(list, {t = endT + tail.Done, action = "Done"})
	table.insert(list, {t = endT + tail.EndTest, action = "EndTest"})
	table.insert(list, {t = endT + tail.Cap, action = "Cap"})
	table.sort(list, function(a, b) return a.t < b.t end)
	return list, sp
end
local function runSchedule(run)
	local list, sp = schedule(run)
	local p = run.player
	local i = 1
	while run.active and i <= #list do
		local tau = workspace:GetServerTimeNow() - run.rollA + sp.from
		while i <= #list and list[i].t <= tau do
			local e = list[i]
			i += 1
			task.spawn(function()
				local ok, err = pcall(actions[e.action], run, e)
				log("t=%.2f %s%s %s%s", e.t, e.action, e.dest and (" " .. e.dest) or (e.pos and string.format(" (%.0f, %.0f, %.0f)", e.pos.X, e.pos.Y, e.pos.Z) or ""),
					ok and "ok" or "fail", ok and "" or (": " .. tostring(err)))
			end)
		end
		if p:GetAttribute("TrailerAbort") == true then cleanup(run, "TrailerAbort") break end
		task.wait(0.02)
	end
end

--------------------------------------------------------------------------------------------------------------------------------
-- round 1 references (TrailerRefs): the server moves the real hero C plow, the client records
--------------------------------------------------------------------------------------------------------------------------------
local refsLegs = {}
function refsLegs.seat(run)
	run.hold = nil -- the refs run drives with PlowTestMove; AFK must stay off
	afkOff(run.player)
	actions.HeroBuild(run)
	G.Registry.Park(run.player, "trailer")
	task.wait(0.3)
	spawnPlow(run)
	if not seated(run.player, 3) then error("not seated") end
end
function refsLegs.desert(run) travel(run, "Desert") end
function refsLegs.crystal(run) travel(run, "Crystal") end
function refsLegs.candy(run)
	travel(run, "Sakura")
	actions.UnlockCandy(run)
end
local function runRefs(run)
	local p = run.player
	for _, leg in ipairs({"seat", "desert", "crystal", "candy", "done"}) do
		if not run.active then return end
		if refsLegs[leg] then
			local ok, err = pcall(refsLegs[leg], run)
			log("refs leg %s %s", leg, ok and "ok" or ("FAIL: " .. tostring(err)))
		end
		run.refsWaiting = leg
		p:SetAttribute("TrailerRefsLeg", leg)
		if leg == "done" then break end
		local t0 = os.clock()
		while run.active and run.refsDone ~= leg and os.clock() - t0 < 150 do task.wait(0.2) end
		task.wait(3) -- TravelService cooldown (2.5 s)
	end
	run.state = "done"
	p:SetAttribute("TrailerState", "done")
	cleanup(run, "refs done")
end

--------------------------------------------------------------------------------------------------------------------------------
-- requests (pre-ROLL only)
--------------------------------------------------------------------------------------------------------------------------------
local function republishBay(run)
	local d = profile(run)
	local pl = d.Plow
	local o = pl.Offers and pl.Offers[Shots.Profile.Offer.slot]
	if not o then return end
	-- a same-value publish fires no attribute change, so the pedestal is emptied for a moment and filled again
	pl.Offers[Shots.Profile.Offer.slot] = nil
	G.GarageHook:Invoke("publish", run.player, d)
	task.wait(0.15)
	pl.Offers[Shots.Profile.Offer.slot] = o
	G.GarageHook:Invoke("publish", run.player, d)
end
local function arm(run)
	if run.rollA then log("ArmRoll ignored: already armed") return end
	if run.state ~= "ready" then log("ArmRoll ignored: state %s", tostring(run.state)) return end
	local cfg = Shots.Config
	local sp = split(run)
	local p = run.player
	run.rollA = workspace:GetServerTimeNow() + cfg.ArmLead
	run.state = "rolling"
	p:SetAttribute("TrailerRollB", sp.passB and (run.rollA + cfg.PassB.rollB - sp.from) or nil)
	p:SetAttribute("TrailerRollA", run.rollA)
	p:SetAttribute("TrailerState", "rolling")
	log("TRAILER_ROLL_A server=%.3f unixms=%d (ROLL in %.2f s) split=%s", run.rollA,
		DateTime.now().UnixTimestampMillis + math.floor(cfg.ArmLead * 1000), cfg.ArmLead, run.splitName or "full")
	task.spawn(runSchedule, run)
end
local function onRequest(p, kind, reqId, action, args)
	local run = runs[p]
	if not run or not run.active then return end
	if kind ~= "Req" or type(reqId) ~= "number" or type(action) ~= "string" or #action > 24 then return end
	if args ~= nil and type(args) ~= "table" then return end
	local ok, why = Server.Guard()
	if not ok then log("request %s refused: %s", action, why) return end
	local pg = p:FindFirstChildOfClass("PlayerGui")
	if not (pg and pg:FindFirstChild(Server.GuiName)) then return end
	local now = os.clock()
	run.reqT = run.reqT or {}
	while run.reqT[1] and now - run.reqT[1] > 1 do table.remove(run.reqT, 1) end
	if #run.reqT >= 20 then return end
	table.insert(run.reqT, now)
	if run.rollA then log("BUG: request after ROLL (%s) refused", action) return end
	if action == "Stream" then
		local pos = args and args.pos
		if typeof(pos) ~= "Vector3" or not (finite(pos.X) and finite(pos.Y) and finite(pos.Z)) then return end
		if math.abs(pos.X) >= 10000 or math.abs(pos.Y) >= 10000 or math.abs(pos.Z) >= 10000 then return end
		streamAround(run, pos)
	elseif action == "RepublishBay" then
		task.spawn(function()
			local okR, err = pcall(republishBay, run)
			log("req %d RepublishBay %s", reqId, okR and "ok" or ("fail: " .. tostring(err)))
		end)
	elseif action == "Ready" then
		log("req %d client warm-up done", reqId)
	elseif action == "ArmRoll" then
		if run.refs then return end
		arm(run)
	elseif action == "RefsNext" then
		if run.refs and args and args.leg == run.refsWaiting then run.refsDone = args.leg end
	elseif action == "Abort" then
		-- review fix: the client aborted before ROLL (gate timeout, no TrailerRollA, F8, error); run.rollA is nil here (checked above)
		if run.refs then return end
		log("req %d client abort before ROLL", reqId)
		cleanup(run, "client abort")
	end
end

--------------------------------------------------------------------------------------------------------------------------------
-- per-player start
--------------------------------------------------------------------------------------------------------------------------------
local watched = {}
local begin
local function watchPlayer(p)
	if watched[p] then return end
	watched[p] = true
	local function onChar(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then hum.Died:Connect(function() local run = runs[p]; if run and run.active then cleanup(run, "died") end end) end
	end
	p.CharacterAdded:Connect(onChar)
	if p.Character then task.spawn(onChar, p.Character) end
	p:GetAttributeChangedSignal("TrailerAbort"):Connect(function()
		local run = runs[p]
		if p:GetAttribute("TrailerAbort") == true and run and run.active then cleanup(run, "TrailerAbort") end
	end)
	p:GetAttributeChangedSignal("TrailerGo"):Connect(function()
		if p:GetAttribute("TrailerGo") ~= true then return end
		local run = runs[p]
		if run and run.state ~= "done" and run.state ~= "aborted" and run.state ~= "idle" then log("TrailerGo ignored: state %s", tostring(run.state)) return end
		if run and run.preparing then
			p:SetAttribute("TrailerGo", nil)
			log("TrailerGo ignored: the aborted run's Prepare is still unwinding - set TrailerGo again in a few seconds")
			return
		end
		p:SetAttribute("TrailerGo", nil)
		p:SetAttribute("TrailerAbort", nil)
		if run then cleanup(run, "re-run") end
		task.spawn(begin, p, SS:GetAttribute("TrailerMode"))
	end)
end
function begin(p, mode)
	for other, r in pairs(runs) do
		if other ~= p and r.active then warn("[Trailer] " .. other.Name .. " is already the trailer player - ignoring " .. p.Name) return end
	end
	local ok, why = Server.Guard()
	if not ok then warn("[Trailer] inert: " .. why) return end
	local splitName = SS:GetAttribute("TrailerSplit")
	if not SPLITS[splitName] then splitName = nil end
	local refs = SS:GetAttribute("TrailerRefs") == true or p:GetAttribute("TrailerRefs") == true
	local prev = runs[p]
	local run = {player = p, mode = mode, active = true, state = "preparing", splitName = splitName, refs = refs,
		n = (prev and prev.n or 0) + 1}
	runs[p] = run
	watchPlayer(p)
	p:SetAttribute("TrailerState", "preparing")
	-- the player's profile (BalanceTestSession, DataService L133) and character
	local t0 = os.clock()
	while run.active and (not G.DataService.Get(p) or p:GetAttribute("BalanceTestSession") == nil or not p.Character) and os.clock() - t0 < 60 do task.wait(0.2) end
	if not run.active then return end
	if p:GetAttribute("BalanceTestSession") ~= true then
		warn("[Trailer] refused: " .. p.Name .. " is not on a BalanceTestMode temp profile")
		cleanup(run, "no temp profile")
		return
	end
	run.preparing = true
	local okP, res = pcall(prepare, run)
	run.preparing = nil
	if run.cleaned then
		-- review fix: cleanup ran while Prepare yielded; a step already in flight may have re-applied AFK or the event block
		run.hold = nil
		pcall(afkOff, p)
		if G and G.ActivityHook then pcall(function() G.ActivityHook:Invoke("EndEvent") end) end
		log("prepare stopped: the run was cleaned up while preparing (AFK and the event block undone again)")
		return
	end
	if not okP or res ~= true then
		warn("[Trailer] prepare failed: " .. tostring(res))
		cleanup(run, "prepare failed")
		return
	end
	if not run.active then return end
	-- the director gui (TrailerDirectorGui: ResetOnSpawn false, IgnoreGuiInset true, ScreenInsets None, DisplayOrder 1000)
	local pg = p:WaitForChild("PlayerGui", 10)
	if pg and not pg:FindFirstChild(Server.GuiName) then
		local g = kit:FindFirstChild(Server.GuiName):Clone()
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		pcall(function() g.ScreenInsets = Enum.ScreenInsets.None end)
		g.DisplayOrder = 1000
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		g.Parent = pg
	end
	p:SetAttribute("TrailerSplit", splitName)
	p:SetAttribute("TrailerRefs", refs or nil)
	p:SetAttribute("TrailerAuto", mode)
	run.state = "ready"
	p:SetAttribute("TrailerState", "ready")
	p:SetAttribute("TrailerRefsLeg", nil) -- review fix: never hand a new run the previous run's last leg
	p:SetAttribute("TrailerRun", run.n)
	log("ready: run %d for %s (mode %s, split %s%s)", run.n, p.Name, mode, splitName or "full", refs and ", REFS" or "")
	if refs then
		run.state = "refs"
		task.spawn(runRefs, run)
	end
end

--------------------------------------------------------------------------------------------------------------------------------
-- entry (TrailerBootstrap)
--------------------------------------------------------------------------------------------------------------------------------
function Server.Start(kitFolder, mode)
	local ok, why = Server.Guard()
	if not ok then warn("[Trailer] TrailerServer inert: " .. why) return false end
	if mode ~= SS:GetAttribute("TrailerMode") then warn("[Trailer] mode mismatch - inert") return false end
	if typeof(kitFolder) ~= "Instance" or kitFolder ~= script.Parent or kitFolder.Parent ~= SS then
		warn("[Trailer] Start called with a foreign kit - inert")
		return false
	end
	if started then return true end
	started = true
	kit = kitFolder
	local gui = kit:FindFirstChild(Server.GuiName)
	if not (gui and gui:IsA("ScreenGui")) then error(Server.GuiName .. " missing in TrailerKit") end
	Shots = require(gui:WaitForChild("TrailerShots"))
	loadGame()
	remote = RS:FindFirstChild("TrailerRemote")
	if not (remote and remote:IsA("RemoteEvent")) then
		remote = Instance.new("RemoteEvent")
		remote.Name = "TrailerRemote"
		remote.Parent = RS
	end
	local rt = RS:FindFirstChild("TrailerRuntime")
	if not rt then
		rt = Instance.new("Folder")
		rt.Name = "TrailerRuntime"
		rt.Parent = RS
	end
	remote.OnServerEvent:Connect(onRequest)
	Players.PlayerAdded:Connect(function(p) task.spawn(begin, p, mode) end)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(begin, p, mode) end
	Players.PlayerRemoving:Connect(function(p)
		local run = runs[p]
		if run then cleanup(run, "left"); runs[p] = nil end
		watched[p] = nil
	end)
	log("TrailerServer started: mode %s, token valid %d s, split %s, rev %s", mode, SS:GetAttribute("TrailerToken") - os.time(),
		tostring(SS:GetAttribute("TrailerSplit") or "full"), Shots.Version)
	return true
end

return Server
