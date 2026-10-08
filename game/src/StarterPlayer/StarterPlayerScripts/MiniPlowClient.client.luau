-- MiniPlowClient (2026-10-06, Claude): the MINI PLOWS button + panel (left of UPGRADES, same look as AFK) and the little plows themselves.
-- The server (MiniPlowService) owns levels, prices and every Snow payout; this only asks to buy and draws.
-- Drawing: each mini is a scaled copy of the owner's equipped plow (PlowAssembly), anchored, no collisions / queries / shadows,
-- moved (PivotTo) along a closed lawnmower loop over the owner's best field (MiniField). Own minis first, then the nearest other
-- players' within C.Minis.ShowRange, at most C.Minis.MaxShown in total (phones).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local C = require(RS:WaitForChild("PlowConfig"))
local SF = require(RS:WaitForChild("SnowFields"))
local Assembly = require(RS:WaitForChild("PlowAssembly"))
local SnowArt = require(RS:WaitForChild("SnowArt"))
local CleanControls = require(RS:WaitForChild("CleanControls"))
local NF = require(RS:WaitForChild("NumberFormat"))
local UILayout = require(RS:WaitForChild("UILayout"))
local Api = require(RS:WaitForChild("PlowClientApi"))
local remote = RS:WaitForChild("MiniPlowRemote")
local M = C.Minis
local FONT = Enum.Font.FredokaOne

---------------------------------------------------------------------------------------------------------------------------------
-- UI
---------------------------------------------------------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "MiniPlowGui"; gui.ResetOnSpawn = false; gui.DisplayOrder = 6; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local rng = pg:WaitForChild("RNGGui", 30)
gui.IgnoreGuiInset = rng and rng.IgnoreGuiInset or false
gui.Parent = pg

local function label(parent, text, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Font = FONT; t.TextScaled = true; t.Text = text; t.TextColor3 = Color3.new(1, 1, 1)
	local s = Instance.new("UIStroke"); s.Thickness = 1.5; s.Color = Color3.fromRGB(20, 40, 70); s.Parent = t
	for k, v in pairs(props or {}) do t[k] = v end
	t.Parent = parent
	return t
end

local btn = Instance.new("TextButton")
btn.Name = "MiniPlowButton"; btn.Text = ""; btn.AutoButtonColor = true
btn:SetAttribute("SnowUIDecor", true)
btn.BackgroundColor3 = Color3.fromRGB(245, 160, 60)
btn.Size = UDim2.fromOffset(96, 52); btn.AnchorPoint = Vector2.new(1, 0.5)
btn.Position = UDim2.new(0.5, -70, 1, -60)
btn.Parent = gui
CleanControls.Apply(btn)
local bTitle = label(btn, "MINIS", {Name = "Label", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(0.8, 0.46), ZIndex = 3})
local bSub = label(btn, "AUTO SNOW", {Name = "Sub", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromScale(0.82, 0.26), ZIndex = 3})

local upgrades, panel
local function place()
	upgrades = upgrades or pg:FindFirstChild("UpgradesButton", true)
	if upgrades and upgrades:IsA("GuiObject") then
		-- AbsolutePosition is screen space; this ScreenGui's own origin can differ (top-bar / safe-area insets), so subtract it
		local ap, as = upgrades.AbsolutePosition - gui.AbsolutePosition, upgrades.AbsoluteSize
		local h = math.clamp(as.Y * 0.62, 40, 64)
		btn.Size = UDim2.fromOffset(math.floor(h * 1.85), math.floor(h))
		btn.Position = UDim2.fromOffset(ap.X - math.max(8, as.X * 0.08), ap.Y + as.Y / 2)
	end
end
-- shown only while the bottom bar (UPGRADES) is shown: the arena island hides that bar, and MINIS hides with it
local function showButton()
	local bar = upgrades and upgrades.Parent
	local on = upgrades ~= nil and upgrades.Visible and not (bar and bar:IsA("GuiObject") and not bar.Visible) and player:GetAttribute("InArenaIsland") ~= true
	btn.Visible = on
	if not on and panel then panel.Visible = false end
end
local barConn
local function watchBar()
	if barConn then barConn:Disconnect(); barConn = nil end
	local bar = upgrades and upgrades.Parent
	if bar and bar:IsA("GuiObject") then barConn = bar:GetPropertyChangedSignal("Visible"):Connect(showButton) end
	showButton()
end
task.spawn(function()
	for _ = 1, 60 do place(); if upgrades then break end; task.wait(0.5) end
	if upgrades then
		upgrades:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
		upgrades:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
		upgrades:GetPropertyChangedSignal("Visible"):Connect(showButton)
		upgrades.AncestryChanged:Connect(function() watchBar(); place() end)
		watchBar()
	end
end)
gui:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
player:GetAttributeChangedSignal("InArenaIsland"):Connect(showButton)

panel = Instance.new("Frame")
panel.Name = "MiniPlowPanel"; panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(360, 250); panel.BackgroundColor3 = Color3.fromRGB(28, 48, 84); panel.Visible = false; panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
local sizeC = Instance.new("UISizeConstraint"); sizeC.Parent = panel
local scale = Instance.new("UIScale"); scale.Parent = panel
pcall(SnowArt.SkinPanel, panel, "dark")
label(panel, "MINI PLOWS", {Name = "Title", Position = UDim2.fromScale(0.08, 0.05), Size = UDim2.fromScale(0.72, 0.15), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3})
local info = label(panel, "", {Name = "Info", Position = UDim2.fromScale(0.08, 0.22), Size = UDim2.fromScale(0.84, 0.2), TextColor3 = Color3.fromRGB(205, 228, 255), TextWrapped = true, ZIndex = 3})
local now = label(panel, "", {Name = "Now", Position = UDim2.fromScale(0.08, 0.44), Size = UDim2.fromScale(0.84, 0.12), ZIndex = 3})
local nextL = label(panel, "", {Name = "Next", Position = UDim2.fromScale(0.08, 0.57), Size = UDim2.fromScale(0.84, 0.1), TextColor3 = Color3.fromRGB(255, 226, 150), ZIndex = 3})
local buy = Instance.new("TextButton")
buy.Name = "BuyButton"; buy.Text = ""; buy.AutoButtonColor = true; buy.BackgroundColor3 = Color3.fromRGB(70, 200, 105)
buy.AnchorPoint = Vector2.new(0.5, 0); buy.Position = UDim2.fromScale(0.5, 0.71); buy.Size = UDim2.fromScale(0.6, 0.2); buy.ZIndex = 3; buy.Parent = panel
CleanControls.Apply(buy)
local buyL = label(buy, "", {Position = UDim2.fromScale(0.06, 0.14), Size = UDim2.fromScale(0.88, 0.72), ZIndex = 4})
local close = Instance.new("TextButton")
close.Name = "Close"; close.Text = "X"; close.Font = FONT; close.TextScaled = true; close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(225, 80, 80); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.fromScale(0.96, 0.04)
close.Size = UDim2.fromScale(0.1, 0.14); close.ZIndex = 4; close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0.3, 0)
pcall(SnowArt.SkinClose, close)
local toast = label(panel, "", {Name = "Toast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 1.03), Size = UDim2.fromScale(0.9, 0.11), Visible = false, ZIndex = 3})

local function fit()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min(vs.X / 420, vs.Y / 330), 0.6, 1.3)
end

local function snow(n) return NF.Abbreviate(math.floor(n + 0.5)) end
local function refresh()
	local L = player:GetAttribute("MiniLevel") or 0
	local cur, nxt = M.Levels[L], M.Levels[L + 1]
	bSub.Text = L > 0 and ("LV " .. L .. " / " .. #M.Levels) or "AUTO SNOW"
	info.Text = "Little copies of your plow clear your best field for you while you play. Each earns a share of what your plow clears there."
	if cur then
		local rate = player:GetAttribute("MiniRate") or 0
		now.Text = string.format("Lv %d: %d mini%s, %d%% each  =  +%s Snow/s", L, cur.Count, cur.Count == 1 and "" or "s", math.floor(cur.Share * 100 + 0.5), snow(rate))
	else
		now.Text = "No mini plows yet"
	end
	if nxt then
		local what = {}
		if not cur or nxt.Count > cur.Count then table.insert(what, "+1 mini") end
		if cur and nxt.Share > cur.Share then table.insert(what, string.format("%d%% each", math.floor(nxt.Share * 100 + 0.5))) end
		if not cur then what = {"1 mini, " .. math.floor(nxt.Share * 100 + 0.5) .. "% of your plow"} end
		nextL.Text = "Next: " .. table.concat(what, ", ")
		buyL.Text = (cur and "UPGRADE  " or "BUY  ") .. "\u{2744} " .. NF.Abbreviate(nxt.Cost)
		local ls = player:FindFirstChild("leaderstats"); local s = ls and ls:FindFirstChild("Snow")
		local ok = s and s.Value >= nxt.Cost
		buy.BackgroundColor3 = ok and Color3.fromRGB(70, 200, 105) or Color3.fromRGB(200, 80, 80)
		buy.Visible = true
	else
		nextL.Text = "All levels bought!"
		buy.Visible = false
	end
end
local toastId = 0
local function say(t)
	toastId += 1; local my = toastId
	toast.Text = t; toast.Visible = true
	task.delay(2.5, function() if my == toastId then toast.Visible = false end end)
end
-- one menu at a time (UILayout contract): opening MINI PLOWS closes whatever else is open. Every Api.CloseX is a no-op until its client
-- script overrides it, and the "CloseAll" event is ignored by RNGClient until its Studio patch learns it (UpgradeTreeClient closes on any name but "Upgrades").
local function closeOtherMenus()
	local tut = pg:FindFirstChild("PlowTutorial")
	local help = tut and tut:FindFirstChild("HelpMenu")
	if help and help:IsA("GuiObject") then help.Visible = false end
	local rngGui = pg:FindFirstChild("RNGGui")
	local village = rngGui and rngGui:FindFirstChild("VillageOpenMenu")
	if village and village:IsA("BindableEvent") then village:Fire("CloseAll") end
	if Api.CloseBuild then pcall(Api.CloseBuild) end     -- garage / equip window
	if Api.CloseCard then pcall(Api.CloseCard) end       -- offer card
	if Api.CloseInspect then pcall(Api.CloseInspect) end -- inspect panel of another player's car
	local egg = pg:FindFirstChild("VerityEggGui")
	local eggScreen = egg and egg:FindFirstChild("EggScreen")
	if eggScreen and eggScreen:IsA("GuiObject") then eggScreen.Visible = false end
end
local prevKey = nil -- last menu seen open by the poll below (MINI PLOWS itself not counted)
btn.Activated:Connect(function()
	if panel.Visible then panel.Visible = false; return end
	closeOtherMenus()
	fit(); refresh()
	panel.Visible = true
	prevKey = UILayout.openMenu(pg, {MiniPlow = true}) -- the poll below only reacts to a menu that opens AFTER this
end)
close.Activated:Connect(function() panel.Visible = false end)
-- MINI PLOWS closes by itself when another menu (RNG panel / Travel, UPGRADES, garage window, offer card, inspect, egg screen, HELP menu) opens
task.spawn(function()
	while true do
		task.wait(0.25)
		local key = UILayout.openMenu(pg, {MiniPlow = true})
		if key ~= nil and key ~= prevKey and panel.Visible then panel.Visible = false end
		prevKey = key
	end
end)
local busy = false
buy.Activated:Connect(function()
	if busy then return end
	busy = true
	local ok, res, msg = pcall(function() return remote:InvokeServer("Buy") end)
	busy = false
	if ok and res == true then say("Mini plows: level " .. tostring(msg) .. "!") else say(type(msg) == "string" and msg or "Try again") end
	refresh()
end)
for _, a in ipairs({"MiniLevel", "MiniRate"}) do player:GetAttributeChangedSignal(a):Connect(function() if panel.Visible or a == "MiniLevel" then refresh() end end) end
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 60)
	local s = ls and ls:WaitForChild("Snow", 30)
	if s then s.Changed:Connect(function() if panel.Visible then refresh() end end) end
end)
refresh()

---------------------------------------------------------------------------------------------------------------------------------
-- the little plows
---------------------------------------------------------------------------------------------------------------------------------
local folder = Instance.new("Folder"); folder.Name = "MiniPlows"; folder.Parent = workspace
local templates = {} -- build string -> scaled template model
local fleets = {}    -- player -> {build=, field=, count=, models={}}

local function template(build)
	local t = templates[build]
	if t then return t end
	local n = 0
	for _ in pairs(templates) do n += 1 end
	if n >= 8 then -- keep memory flat: drop unused cached builds (live fleets keep their own clones)
		for k, m in pairs(templates) do m:Destroy(); templates[k] = nil end
	end
	local ids = string.split(build, ",")
	local ok, m = pcall(Assembly.Build, {Blade = ids[1], Engine = ids[2], Gear = ids[3], Body = ids[4]})
	if not ok or not m then return nil end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BaseScript") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("Seat") or d:IsA("VehicleSeat") or d:IsA("Sound")
			or d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Constraint") or d:IsA("JointInstance") then
			if d:IsA("Seat") or d:IsA("VehicleSeat") then d.Transparency = 1; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.Anchored = true else d:Destroy() end
		elseif d:IsA("BasePart") then
			d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.CastShadow = false; d.Massless = true
		end
	end
	if not m.PrimaryPart then m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart", true) end
	pcall(function() m:ScaleTo(M.Scale) end)
	-- a small snow spray at the blade
	local cf, size = m:GetBoundingBox()
	local att = Instance.new("Attachment")
	att.Name = "Spray"; att.Parent = m.PrimaryPart
	att.WorldPosition = cf.Position + cf.LookVector * (size.Z / 2) - Vector3.new(0, size.Y / 2 - 0.2, 0)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(240, 250, 255))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.1)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(0.35, 0.6); pe.Rate = 10; pe.Speed = NumberRange.new(3, 5); pe.SpreadAngle = Vector2.new(35, 20)
	pe.LockedToPart = false; pe.Parent = att
	m.Name = "MiniTemplate"
	templates[build] = m
	return m
end

local function clear(f)
	for _, m in ipairs(f.models) do m:Destroy() end
	f.models = {}
end
local function fieldById(id)
	for _, f in ipairs(SF.Fields or {}) do if f.Id == id then return f end end
	return nil
end
local tops = {}
local function snowTop(f)
	-- top of a full snow tile = field ground + the stage's Floor + Phase3 heights (ReplicatedStorage.SnowStages, as SnowFieldClient builds it)
	local style = f.Style or "Starter"
	local h = tops[style]
	if not h then
		local stages = RS:FindFirstChild("SnowStages")
		local s = stages and (stages:FindFirstChild(style) or stages:FindFirstChild("Starter"))
		local floor, p3 = s and s:FindFirstChild("Floor"), s and s:FindFirstChild("Phase3")
		h = (floor and not f.NoFloor and floor.Size.Y or 0) + (p3 and p3.Size.Y or 1.6)
		tops[style] = h
	end
	return SF.Origin(f).Y + h
end

-- who gets drawn: own minis first, then other players' by distance, up to MaxShown
local function wanted()
	local list, root = {}, player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local function add(p)
		local n, fid, b = p:GetAttribute("MiniCount"), p:GetAttribute("MiniField"), p:GetAttribute("MiniBuild")
		if type(n) ~= "number" or n <= 0 or type(fid) ~= "string" or type(b) ~= "string" then return end
		local f = fieldById(fid)
		if not f then return end
		local d = 0
		if p ~= player then
			if not root then return end
			d = (SF.Origin(f) - root.Position).Magnitude
			if d > M.ShowRange then return end
		end
		table.insert(list, {p = p, n = math.min(n, 5), f = f, b = b, d = d})
	end
	add(player)
	for _, p in ipairs(Players:GetPlayers()) do if p ~= player then add(p) end end
	table.sort(list, function(a, b) return a.d < b.d end)
	local left, out = M.MaxShown, {}
	for _, e in ipairs(list) do
		if left <= 0 then break end
		e.n = math.min(e.n, left); left -= e.n
		out[e.p] = e
	end
	return out
end

local function sync()
	local want = wanted()
	for p, f in pairs(fleets) do
		local w = want[p]
		if not w or w.b ~= f.build or w.f ~= f.field or w.n ~= #f.models then clear(f); fleets[p] = nil end
	end
	for p, w in pairs(want) do
		if not fleets[p] then
			local t = template(w.b)
			if t then
				local f = {build = w.b, field = w.f, models = {}, t0 = os.clock() + math.random() * 5}
				for i = 1, w.n do local m = t:Clone(); m.Name = p.Name .. "_Mini" .. i; m.Parent = folder; f.models[i] = m end
				fleets[p] = f
			end
		end
	end
end

-- A CLOSED lawnmower loop per field (review fix 2026-10-06: the old ping-pong teleported at the wrap): drive along x on lanes
-- 0, 2, 4 ... down the field, then on the odd lanes back up, joined by half-circle turns at the ends, back to lane 0 seamlessly.
-- An even lane count keeps the driving direction alternating all the way round.
local routes = {}
local function route(fd)
	local r = routes[fd]
	if r then return r end
	local ts, inset = SF.TileSize, 3
	local W, D = fd.Width * ts, fd.Depth * ts
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
	r = {legs = legs, total = math.max(total, 1), x0 = x0, x1 = x1, o = SF.Origin(fd), y = snowTop(fd) + M.Hover}
	routes[fd] = r
	return r
end
local function pose(f, i, n, t)
	local r = route(f.field)
	local s = (t * M.Speed + (i - 1) / n * r.total) % r.total
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
	-- the plow's front is its LookVector (-Z: the blade attaches at z = -4.3 on the chassis)
	return CFrame.lookAt(p, p + Vector3.new(hx, 0, hz))
end

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for _, f in pairs(fleets) do
		local n = #f.models
		for i, m in ipairs(f.models) do
			if m.PrimaryPart then
				local ok, cf = pcall(pose, f, i, n, t - f.t0)
				if ok then m:PivotTo(cf) end
			end
		end
	end
end)

task.spawn(function()
	while true do
		pcall(sync)
		task.wait(1.5)
	end
end)
Players.PlayerRemoving:Connect(function(p) local f = fleets[p]; if f then clear(f); fleets[p] = nil end end)
