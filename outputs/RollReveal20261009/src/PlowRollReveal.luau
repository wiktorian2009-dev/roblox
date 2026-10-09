-- PlowRollReveal (2026-10-09, Claude): the garage PART-ROLL reveal on a pedestal. Client only, presentation only.
-- The server picks the part, price, odds, pity and cooldown (PlowService actions.Roll); nothing here decides or grants anything.
-- Your own roll: ACTIVATION (0-0.3 s: cyan ring, snow dust, old part sinks, small camera push) -> BUILDUP (0.3-1.1 s: icy halo,
-- sparkles, frosted DECORATIVE previews that tick past quickly then ease; it keeps going until the server answers) -> REVEAL of the
-- real offered part (overshoot, short turn, one ring, a small burst, rarity accent) -> OFFER HANDOFF (camera back, the caller opens
-- the offer card). Ordinary ~2.1 s, Epic ~2.4 s, Legendary ~3 s (silhouette, short orbit, stars + aurora ribbons).
-- Previews are frosted ice silhouettes picked uniformly from your real offer pool, one per part slot in turn: they carry no rarity
-- colour and are never chosen to look like a near miss. Reduced motion (Settings) = no camera, no preview cycling, no overshoot.
-- Effects are pooled per pedestal (rig) and every connection / camera change is undone on finish, skip, abort, death or travel.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local C = require(RS:WaitForChild("PlowConfig"))
local Api = require(RS:WaitForChild("PlowClientApi"))
local TX = require(RS:WaitForChild("UniversalVFX")).Textures
local Audio = require(RS:WaitForChild("GameAudio"))
local Pass = require(RS:WaitForChild("PassConfig"))
local MPS = game:GetService("MarketplaceService")

local M = {}
local CYAN, ICE, NAVY = Color3.fromRGB(120, 225, 255), Color3.fromRGB(190, 235, 255), Color3.fromRGB(22, 32, 58)
local RCOL = {}
for i, r in ipairs(C.Rarities) do RCOL[i] = r.Color end
local MAX_RANK = #C.Rarities
local TICK_ID = "rbxassetid://12221976"
local HIT_ID = { -- one reveal accent per rarity (existing game audio, no new uploads)
	[1] = TICK_ID, [2] = TICK_ID, [3] = TICK_ID,
	[4] = Audio.Reveal and Audio.Reveal.Id, [5] = Audio.Steps and Audio.Steps.Epic and Audio.Steps.Epic.Id,
	[6] = Audio.Steps and Audio.Steps.Legendary and Audio.Steps.Legendary.Id,
}
local BURST = {6, 8, 12, 16, 22, 28} -- star particles at the reveal per rarity rank (capped)
local ACT, BUILD = 0.3, 1.1 -- activation end, earliest reveal
local SWAPS = {0.11, 0.13, 0.15, 0.18, 0.22} -- preview intervals: fast, then easing toward the reveal; 0.24 while still waiting
local WAIT_LIMIT = 8 -- no server answer by then: give the pedestal back

local function kp(t, v) return NumberSequenceKeypoint.new(t, v) end
local function clamp01(k) return math.clamp(k, 0, 1) end
local function ease(k) k = clamp01(k); return 1 - (1 - k) ^ 3 end
local function smooth(k) k = clamp01(k); return k * k * (3 - 2 * k) end
local function backOut(k) k = clamp01(k) - 1; local s = 1.9; return 1 + (s + 1) * k ^ 3 + s * k ^ 2 end
local function setLTM(m, v)
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = v end end
end
local function restyle(m, color, material, transparency)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Color, d.Material = color, material
			if transparency then d.Transparency = transparency end
			if d:IsA("MeshPart") then pcall(function() d.TextureID = "" end) end
		elseif d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Texture") then
			d:Destroy()
		end
	end
	return m
end
function M.ReducedMotion()
	return player:GetAttribute("ReducedMotion") == true or player:GetAttribute("TreasureReduced") == true
end
-- roll sounds follow the existing roll-sound switches (RNGGui RollTickOff / RollTickVolume) plus a player RollSoundOff attribute
local function soundVolume()
	local pg = player:FindFirstChild("PlayerGui")
	local rng = pg and pg:FindFirstChild("RNGGui")
	if player:GetAttribute("RollSoundOff") == true or (rng and rng:GetAttribute("RollTickOff") == true) then return 0 end
	return math.clamp(tonumber(rng and rng:GetAttribute("RollTickVolume")) or 1, 0, 2)
end

------------------------------------------------ Quick Rolls (2026-10-09): skipping is the perk of the Quick Rolls game pass once it has an id
-- Free while PassConfig.QuickRolls.Id is nil or sales are off, with reduced motion, and where paid random items are restricted (or
-- the policy is not known yet). Otherwise a click / tap / E during your reveal opens the pass's purchase prompt (once per roll and at
-- most every PROMPT_GAP seconds); the reveal keeps playing. Ownership comes only from the server (PassService -> Pass_QuickRolls).
local QR = Pass.QuickRolls
local PROMPT_GAP = 5
local lastPrompt = -math.huge
function M.SkipIsPaid() -- true = skipping needs the pass right now
	if not (QR and QR.Id and Pass.SalesEnabled == true) then return false end
	if M.ReducedMotion() then return false end
	if player:GetAttribute("PaidRandomRestricted") ~= false then return false end
	return player:GetAttribute("Pass_" .. QR.Key) ~= true
end
local function offerQuickRolls(a)
	if a.prompted or os.clock() - lastPrompt < PROMPT_GAP then return end
	a.prompted, lastPrompt = true, os.clock()
	pcall(function() MPS:PromptGamePassPurchase(player, QR.Id) end) -- PassService verifies and grants after the purchase
end
if QR then
	player:GetAttributeChangedSignal("Pass_" .. QR.Key):Connect(function()
		if player:GetAttribute("Pass_" .. QR.Key) == true and os.clock() - lastPrompt < 300 then
			Api.Toast("\u{26A1} Quick Rolls unlocked - click to skip roll reveals!", Color3.fromRGB(150, 255, 170))
		end
	end)
end

------------------------------------------------ models
local prepare -- (partId) -> model, offset, hover: the same fitting the pedestal display uses (set by Init)
function M.Init(opts) prepare = opts.prepare end

-- frosted decorative previews, cached and reused (only ever parented to one pedestal at a time)
local cache, order = {}, {}
local function frosted(id)
	local c = cache[id]
	if c and c.model then return c end
	local m, offset, hover = prepare(id)
	if not m then return nil end
	restyle(m, ICE, Enum.Material.Glass, 0.25) -- clear frosted ice (ForceField vanished in daylight)
	c = {model = m, offset = offset, hover = hover, id = id}
	cache[id] = c
	table.insert(order, id)
	if #order > 16 then
		for i, old in ipairs(order) do
			local o = cache[old]
			if o and o.model and o.model.Parent == nil and old ~= id then
				o.model:Destroy(); cache[old] = nil; table.remove(order, i); break
			end
		end
	end
	return c
end
local function pickPreviews(n)
	local S = Api.State
	local pool = {}
	local ok, list = pcall(C.OfferPool, S and S.Band or 1, S and S.Luck or 1)
	if ok and type(list) == "table" then for _, e in ipairs(list) do if C.Parts[e.Id] then table.insert(pool, e.Id) end end end
	if #pool == 0 then for id, def in pairs(C.Parts) do if def.Role ~= "P" and def.Role ~= "S" then table.insert(pool, id) end end end
	local bySlot = {}
	for _, id in ipairs(pool) do
		local s = C.Parts[id].Slot
		bySlot[s] = bySlot[s] or {}
		table.insert(bySlot[s], id)
	end
	local out, start = {}, math.random(#C.Slots)
	for i = 1, n do
		local l = bySlot[C.Slots[(start + i - 2) % #C.Slots + 1]]
		if l and #l > 0 then table.insert(out, l[math.random(#l)]) end
	end
	return out
end

------------------------------------------------ pooled effects rig (one per pedestal, built on first use)
local function flat(name, size, parent)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Transparency, p.Anchored = name, size, 1, true
	p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
	p.Parent = parent
	return p
end
local function decal(p, tex, face)
	local d = Instance.new("Decal")
	d.Face, d.Texture, d.Transparency = face or Enum.NormalId.Top, tex, 1
	d.Parent = p
	return d
end
local function emitter(att, props)
	local pe = Instance.new("ParticleEmitter")
	pe.Rate, pe.LightInfluence = 0, 0
	for k, v in pairs(props) do pe[k] = v end
	pe.Parent = att
	return pe
end
local function sound(parent)
	local s = Instance.new("Sound")
	s.RollOffMinDistance, s.RollOffMaxDistance = 10, 80
	s.Parent = parent
	return s
end
local function getRig(ped)
	local r = ped.rig
	if r and r.folder.Parent then return r end
	local f = Instance.new("Folder")
	f.Name = "RollRevealFX"
	f.Parent = ped.model
	r = {folder = f}
	r.base = flat("RingBase", Vector3.new(6.6, 0.05, 6.6), f)
	r.baseDecal = decal(r.base, TX.ring)
	r.halo = flat("Halo", Vector3.new(5.4, 0.05, 5.4), f)
	r.haloDecals = {decal(r.halo, TX["rune-circle"] or TX.ring), decal(r.halo, TX["rune-circle"] or TX.ring, Enum.NormalId.Bottom)}
	r.wave = flat("Wave", Vector3.new(3, 0.05, 3), f)
	r.waveDecal = decal(r.wave, TX.shockwave or TX.ring)
	r.light = Instance.new("PointLight")
	r.light.Range, r.light.Brightness, r.light.Shadows, r.light.Enabled = 13, 0, false, false
	r.light.Parent = r.base
	r.low = Instance.new("Attachment"); r.low.Parent = r.base
	r.mid = Instance.new("Attachment"); r.mid.Parent = r.base
	r.sky = Instance.new("Attachment"); r.sky.Parent = r.base
	r.dust = emitter(r.low, {Texture = TX.smoke, Color = ColorSequence.new(Color3.new(1, 1, 1)), Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(3, 6), SpreadAngle = Vector2.new(75, 75), Drag = 4, Acceleration = Vector3.new(0, 2, 0),
		Size = NumberSequence.new({kp(0, 0.7), kp(1, 2.1)}), Transparency = NumberSequence.new({kp(0, 0.3), kp(1, 1)}),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60)})
	r.sparkle = emitter(r.mid, {Texture = TX.star, Color = ColorSequence.new(ICE), LightEmission = 1, Lifetime = NumberRange.new(0.4, 0.8),
		Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180), Drag = 2, Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, Size = NumberSequence.new({kp(0, 0), kp(0.3, 0.45), kp(1, 0)})})
	r.burst = emitter(r.mid, {Texture = TX.star, LightEmission = 1, Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(180, 180), Drag = 5, Size = NumberSequence.new({kp(0, 0.75), kp(1, 0)}), Rotation = NumberRange.new(0, 360)})
	r.column = Instance.new("Beam") -- Epic + Legendary: a short rising light
	r.column.Attachment0, r.column.Attachment1, r.column.FaceCamera = r.low, r.sky, true
	r.column.Texture, r.column.LightEmission, r.column.LightInfluence, r.column.Enabled = TX.glow, 1, 0, false
	r.column.Parent = f
	-- Legendary: two aurora ribbons that curl around the part
	r.aur = {}
	for i = 1, 2 do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = r.base, r.base
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1, b.FaceCamera, b.Segments = a0, a1, true, 24
		b.Texture, b.TextureSpeed, b.TextureLength, b.LightEmission, b.LightInfluence = TX.streak or TX.glow, 1.2, 4, 1, 0
		b.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 255, 190)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 210, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 140, 255))})
		b.Width0, b.Width1, b.Enabled = 1.1, 0.4, false
		b.Parent = f
		r.aur[i] = {a0 = a0, a1 = a1, beam = b}
	end
	r.tick, r.build, r.hit = sound(r.base), sound(r.base), sound(r.base)
	r.tick.SoundId = TICK_ID
	r.build.SoundId, r.build.Looped = Audio.Start and Audio.Start.Id or "", false
	-- the pedestal's own icy ring mesh lights up (restored afterwards)
	local ring = ped.model:FindFirstChild("Ring")
	if ring and ring:IsA("BasePart") then r.ring, r.ringColor, r.ringMat = ring, ring.Color, ring.Material end
	ped.rig = r
	return r
end
local function rigOff(r)
	r.baseDecal.Transparency, r.waveDecal.Transparency = 1, 1
	for _, d in ipairs(r.haloDecals) do d.Transparency = 1 end
	r.light.Enabled, r.sparkle.Rate, r.column.Enabled = false, 0, false
	for _, a in ipairs(r.aur) do a.beam.Enabled = false end
	if r.build.IsPlaying then r.build:Stop() end
	if r.ring and r.ring.Parent then r.ring.Color, r.ring.Material = r.ringColor, r.ringMat end
end
local function playSound(s, id, vol, speed)
	local v = soundVolume()
	if v <= 0 or not id or id == "" then return end
	if s.SoundId ~= id then s.SoundId = id end
	s.Volume, s.PlaybackSpeed, s.TimePosition = vol * v, speed or 1, 0
	s:Play()
end

------------------------------------------------ camera (initiating player only; one animation owns it at a time)
local camOwner
local function camTake(a)
	if camOwner or a.reduced then return end
	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType == Enum.CameraType.Scriptable then return end -- someone else is directing the camera
	camOwner = a
	a.cam = {fov = cam.FieldOfView, type = cam.CameraType}
end
local function camRelease(a)
	if camOwner ~= a then return end
	camOwner = nil
	local cam = workspace.CurrentCamera
	if cam and a.cam then
		cam.FieldOfView = a.cam.fov
		if a.scripted then
			cam.CameraType = a.cam.type
			if a.from then cam.CFrame = a.from end
		end
	end
	a.scripted = false
end
local function camUpdate(a, t, focus)
	if camOwner ~= a then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local k -- 1 = fully pushed in
	if not a.tR then k = ease(t / 0.35) else k = 1 - smooth((t - a.tR - (a.prof.handoff - 0.6)) / 0.6) end
	cam.FieldOfView = a.cam.fov * (1 - 0.1 * clamp01(k))
	if a.prof and a.prof.orbit and a.tR then
		local u = (t - a.tR) / a.prof.orbit
		if u >= 0 and u < 1 then
			if not a.scripted then
				a.scripted, a.from = true, cam.CFrame
				cam.CameraType = Enum.CameraType.Scriptable
			end
			local v = a.from.Position - focus
			local flatV = Vector3.new(v.X, 0, v.Z)
			if flatV.Magnitude < 0.1 then flatV = Vector3.new(0, 0, 1) end
			local bell = math.sin(math.pi * clamp01(u))
			local r = flatV.Magnitude + (math.clamp(flatV.Magnitude, 8, 13) - flatV.Magnitude) * bell
			local dir = CFrame.Angles(0, math.rad(32) * smooth(u) * (a.orbitSign or 1), 0):VectorToWorldSpace(flatV.Unit)
			local pos = focus + dir * r + Vector3.new(0, v.Y + (3 - v.Y) * bell * 0.6, 0)
			local orbitCF = CFrame.lookAt(pos, focus)
			cam.CFrame = orbitCF:Lerp(a.from, smooth((u - 0.72) / 0.28))
		elseif u >= 1 and a.scripted then
			cam.CameraType = a.cam.type
			cam.CFrame = a.from
			a.scripted = false
		end
	end
end

------------------------------------------------ the animation
local running = {} -- [anim] = true (tap/click to skip)
local Anim = {}
Anim.__index = Anim

-- ped = the garage pedestal entry (top, model, key, display, ...). opts:
--   onSettle(model, offset, hover, angle, id)  the revealed model becomes the pedestal display
--   onRelease()                                 no result: the pedestal goes back to the normal display
--   onHandoff()                                 open the offer card (BUY / RESERVE)
--   speed                                       Studio test hook only: slow motion for screenshots (1 = normal)
function M.Begin(ped, opts)
	local a = setmetatable({ped = ped, opts = opts, t0 = os.clock(), reduced = M.ReducedMotion(), conns = {}, speed = opts.speed or 1}, Anim)
	a.rig = getRig(ped)
	a.keyNum = tonumber(ped.key) or 4
	a.old = ped.display
	if a.old then a.oldPivot = a.old:GetPivot() end
	a.previews = a.reduced and {} or pickPreviews(8)
	a.pi, a.nextSwap = 0, ACT
	a.hover = 3.6
	a.orbitSign = math.random() < 0.5 and -1 or 1
	camTake(a)
	local r = a.rig
	rigOff(r)
	r.light.Color, r.light.Enabled = CYAN, true
	r.baseDecal.Color3 = CYAN
	for _, d in ipairs(r.haloDecals) do d.Color3 = ICE end
	if r.ring then r.ring.Material, r.ring.Color = Enum.Material.Neon, CYAN end
	if not a.reduced then r.dust:Emit(12) end
	-- interruptions: travel, losing the bay, death, respawn, the bay model going away
	local function stop() a:Abort() end
	table.insert(a.conns, player:GetAttributeChangedSignal("InGarage"):Connect(function() if player:GetAttribute("InGarage") ~= true then stop() end end))
	table.insert(a.conns, player:GetAttributeChangedSignal("GarageBay"):Connect(stop))
	table.insert(a.conns, player.CharacterRemoving:Connect(stop))
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then table.insert(a.conns, hum.Died:Connect(stop)) end
	table.insert(a.conns, ped.top.AncestryChanged:Connect(function() if not ped.top:IsDescendantOf(workspace) then stop() end end))
	table.insert(a.conns, RunService.RenderStepped:Connect(function() a:Step() end))
	running[a] = true
	return a
end

-- the server answered: id = the offered part, rank = its rarity rank
function Anim:Resolve(id, rank)
	if self.dead or self.result then return end
	self.result = {id = id, rank = math.clamp(tonumber(rank) or 2, 1, MAX_RANK)}
	self.prof = self:Profile()
	if self.fast then self:Finish(true) end
end
function Anim:Profile()
	local rank = self.result.rank
	if self.reduced then return {reveal = 0.3, handoff = 0.45, done = 0.8} end
	if rank >= MAX_RANK then return {silhouette = 0.4, reveal = 0.5, handoff = 1.4, done = 1.9, orbit = 1.4, aurora = true, column = true} end
	if rank >= MAX_RANK - 1 then return {reveal = 0.5, handoff = 0.8, done = 1.3, column = true} end
	return {reveal = 0.5, handoff = 0.65, done = 1.05}
end
function Anim:Skip()
	if self.dead then return end
	self.fast = true
	if self.result then self:Finish(true) end
end
function Anim:TrySkip() -- a player's skip request (click / tap / E): free, or the Quick Rolls offer
	if self.dead then return end
	if M.SkipIsPaid() then offerQuickRolls(self); return end
	self:Skip()
end

local function placeModel(m, top, hover, offset, angle, y)
	m:PivotTo(top.CFrame * CFrame.new(0, hover + (y or 0), 0) * CFrame.Angles(0, angle, 0) * offset:Inverse())
end
function Anim:Now() return (os.clock() - self.t0) * self.speed end -- speed < 1 only from the Studio test hook
function Anim:Bob() return math.sin(os.clock() * 2 + self.keyNum) * 0.25 end -- same bob as the pedestal display

function Anim:Step()
	if self.dead then return end
	local t = self:Now()
	local ped, r = self.ped, self.rig
	local top = ped.top
	if not top.Parent then self:Abort(); return end
	local topCF = top.CFrame
	r.base.CFrame = topCF * CFrame.new(0, 0.16, 0)
	r.low.WorldPosition = topCF.Position + Vector3.new(0, 0.2, 0)
	r.mid.WorldPosition = topCF.Position + Vector3.new(0, self.hover, 0)
	r.sky.WorldPosition = topCF.Position + Vector3.new(0, 15, 0)
	local focus = r.mid.WorldPosition

	-- 1. activation: cyan ring in, old part sinks into the pedestal and fades
	local fadeOut = self.tR and clamp01((t - self.tR - (self.prof.done - 0.4)) / 0.4) or 0
	r.baseDecal.Transparency = 1 - (0.85 * ease(t / 0.25)) * (1 - fadeOut)
	r.base.Size = Vector3.new(6.4, 0.05, 6.4) * (1 + 0.025 * math.sin(t * 7))
	if not self.tR then r.light.Brightness = 1.4 * ease(t / 0.3) end
	if self.old then
		local k = ease(t / ACT)
		if self.old.Parent then
			self.old:PivotTo(self.oldPivot * CFrame.new(0, -2.2 * k, 0))
			setLTM(self.old, k)
		end
		if t >= ACT then self.old:Destroy(); self.old = nil end
	end

	-- 2. buildup: halo + sparkles + frosted previews until the result is in and t >= 1.1
	local haloIn = ease((t - ACT) / 0.2)
	local haloOut = self.tR and ease((t - self.tR) / 0.3) or 0
	for _, d in ipairs(r.haloDecals) do d.Transparency = 1 - 0.7 * haloIn * (1 - haloOut) end
	self.spin = (self.spin or 0) + (self.tR and 0.6 or 2.6) * math.min(t - (self.lastT or t), 0.1)
	self.lastT = t
	r.halo.CFrame = topCF * CFrame.new(0, self.hover - 0.6 + 0.3 * math.sin(t * 3), 0) * CFrame.Angles(0, self.spin * 2, 0) * CFrame.Angles(math.rad(12), 0, 0)
	r.halo.Size = Vector3.new(5.4, 0.05, 5.4) * (1 - 0.4 * haloOut)
	if not self.tR then
		r.sparkle.Rate = (t >= ACT and not self.reduced) and 10 or 0
		if t >= self.nextSwap and #self.previews > 0 then self:NextPreview(t) end
		if self.cur then
			local c = self.cur
			local punch = 0.35 * (1 - ease((t - self.curT) / 0.09))
			placeModel(c.model, top, c.hover, c.offset, t * 1.6, punch)
		end
		if self.result and t >= BUILD then self:StartReveal(t) end
		if not self.result and t > WAIT_LIMIT then self:Abort(); return end
	end

	-- 3. reveal + 4. handoff
	if self.tR then self:RevealStep(t, topCF) end
	camUpdate(self, t, focus)
end

function Anim:NextPreview(t)
	if self.cur and self.cur.model then self.cur.model.Parent = nil end
	self.pi += 1
	local id = self.previews[(self.pi - 1) % #self.previews + 1]
	local c = id and frosted(id)
	self.cur = c
	if c then
		c.model.Parent = self.rig.folder
		setLTM(c.model, 0)
	end
	self.curT = t
	local step = SWAPS[self.pi] or 0.24
	self.nextSwap = t + step
	playSound(self.rig.tick, TICK_ID, 0.28, 1.55 + math.min(self.pi, 6) * 0.08)
	if self.pi == 1 and not self.rig.build.IsPlaying then playSound(self.rig.build, Audio.Start and Audio.Start.Id, 0.22, 1.15) end
end

function Anim:StartReveal(t)
	if self.tR then return end
	self.tR = t
	local r, res = self.rig, self.result
	if self.cur and self.cur.model then self.cur.model.Parent = nil end
	self.cur = nil
	r.sparkle.Rate = 0
	if r.build.IsPlaying then r.build:Stop() end
	local m, offset, hover = prepare(res.id)
	if not m then self:Abort(); return end
	self.model, self.offset, self.hover = m, offset, hover
	m.Parent = r.folder
	self.baseAngle = self.spin * 2
	if self.prof.silhouette then
		local s = prepare(res.id)
		if s then
			restyle(s, NAVY, Enum.Material.SmoothPlastic)
			s.Parent = r.folder
			self.sil = s
			setLTM(m, 1)
		end
	end
	if not self.prof.silhouette then self:Hit() end
end

function Anim:Hit() -- the rarity moment: ring, burst, light, accent sound
	if self.hitDone then return end
	self.hitDone = true
	self.tHit = self:Now()
	local r, rank = self.rig, self.result.rank
	local col = RCOL[rank] or CYAN
	r.waveDecal.Color3 = col
	r.burst.Color = ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.35), col)
	r.burst:Emit(self.reduced and math.min(6, BURST[rank]) or BURST[rank])
	r.light.Color = col
	r.baseDecal.Color3 = CYAN:Lerp(col, 0.6)
	if r.ring then r.ring.Color = CYAN:Lerp(col, 0.6) end
	if self.prof.column then r.column.Enabled = true end
	if self.prof.aurora and not self.reduced then for _, a in ipairs(r.aur) do a.beam.Enabled = true end end
	if self.sil then setLTM(self.model, 0); self.sil:Destroy(); self.sil = nil end
	playSound(r.hit, HIT_ID[rank], rank >= 4 and 0.55 or 0.45, rank >= 4 and 1 or 1.35)
end

function Anim:RevealStep(t, topCF)
	local p, r = self.prof, self.rig
	local u = t - self.tR
	if p.silhouette and u >= p.silhouette then self:Hit() end
	local k = u / p.reveal
	local turn = self.reduced and 0 or -1.25 * (1 - ease(k)) -- a short readable turn that settles into the slow idle spin
	self.angle = self.baseAngle + 0.9 * u + turn
	local rise = self.reduced and 0 or (-0.8 + 0.8 * backOut(k))
	local y = rise + self:Bob() * ease(k)
	if self.model then placeModel(self.model, self.ped.top, self.hover, self.offset, self.angle, y) end
	if self.sil then placeModel(self.sil, self.ped.top, self.hover, self.offset, self.angle, y) end
	if self.hitDone then
		local h = t - self.tHit
		local w = ease(h / 0.6)
		r.wave.CFrame = topCF * CFrame.new(0, 0.2, 0)
		r.wave.Size = Vector3.new(3, 0.05, 3):Lerp(Vector3.new(12, 0.05, 12), w)
		r.waveDecal.Transparency = 0.25 + 0.75 * w
		r.light.Brightness = 1 + (self.result.rank >= 4 and 2.2 or 1.2) * (1 - ease(h / 0.7))
		if r.column.Enabled then
			local c = clamp01(h / 0.8)
			r.column.Width0, r.column.Width1 = 3.2 * (1 - c * 0.6), 0.6
			r.column.Transparency = NumberSequence.new({kp(0, 0.15 + 0.85 * c), kp(1, 1)})
			if c >= 1 then r.column.Enabled = false end
		end
		if r.aur[1].beam.Enabled then
			local c = clamp01(h / 1.3)
			for i, a in ipairs(r.aur) do
				local ang = h * 2.2 + i * math.pi
				local cen = topCF.Position + Vector3.new(0, self.hover, 0)
				a.a0.WorldPosition = cen + Vector3.new(math.cos(ang) * 3.4, -1.6 + c * 1.5, math.sin(ang) * 3.4)
				a.a1.WorldPosition = cen + Vector3.new(math.cos(ang + 2.2) * 3.4, 1.4 + c * 1.2, math.sin(ang + 2.2) * 3.4)
				a.beam.CurveSize0, a.beam.CurveSize1 = 2.5, -2.5
				a.beam.Transparency = NumberSequence.new({kp(0, 1), kp(0.3, 0.25 + 0.75 * c), kp(0.7, 0.25 + 0.75 * c), kp(1, 1)})
				if c >= 1 then a.beam.Enabled = false end
			end
			if h > 0.15 and not self.stars then self.stars = true; r.burst:Emit(10) end
		end
	end
	if u >= p.handoff then self:Handoff() end
	if u >= p.done then self:Finish(false) end
end

function Anim:Handoff()
	if self.handed then return end
	self.handed = true
	camRelease(self)
	if self.opts.onHandoff then task.spawn(self.opts.onHandoff) end
end

function Anim:Cleanup()
	self.dead = true
	running[self] = nil
	for _, c in ipairs(self.conns) do c:Disconnect() end
	table.clear(self.conns)
	camRelease(self)
	if self.cur and self.cur.model then self.cur.model.Parent = nil end
	self.cur = nil
	if self.old then self.old:Destroy(); self.old = nil end
	if self.sil then self.sil:Destroy(); self.sil = nil end
	if self.rig and self.rig.folder.Parent then rigOff(self.rig) end
end

-- normal end (or skip): the revealed part becomes the pedestal display; the card opens unless this was an interruption
function Anim:Finish(fast)
	if self.dead then return end
	if not self.result then self:Abort(); return end
	if not self.model then
		local m, offset, hover = prepare(self.result.id)
		self.model, self.offset, self.hover = m, offset, hover
		if m then m.Parent = self.rig.folder end
		self.angle = (self.spin or 0) * 2
	end
	if fast and self.sil then setLTM(self.model, 0) end
	local quiet = self.interrupted
	if not self.handed and not quiet then self:Handoff() end
	self:Cleanup()
	if self.model then
		setLTM(self.model, 0)
		local angle = self.angle or 0
		placeModel(self.model, self.ped.top, self.hover, self.offset, angle, self:Bob())
		self.opts.onSettle(self.model, self.offset, self.hover, angle, self.result.id)
	else
		self.opts.onRelease()
	end
end

-- interruption (travel, death, losing the bay, no server answer): no camera, no card; the saved offer is untouched
function Anim:Abort()
	if self.dead then return end
	self.interrupted = true
	if self.result and self.ped.top:IsDescendantOf(workspace) then self:Finish(true); return end
	if self.model then self.model:Destroy(); self.model = nil end
	self:Cleanup()
	self.opts.onRelease()
end
function Anim:Alive() return not self.dead end

------------------------------------------------ neighbours: a smaller reveal on their pedestal, no camera, no card
function M.Mini(ped, rank)
	local r = getRig(ped)
	local col = RCOL[math.clamp(tonumber(rank) or 2, 1, MAX_RANK)] or CYAN
	r.token = (r.token or 0) + 1
	local my = r.token
	local topCF = ped.top.CFrame
	r.wave.CFrame = topCF * CFrame.new(0, 0.2, 0)
	r.wave.Size = Vector3.new(3, 0.05, 3)
	r.waveDecal.Color3, r.waveDecal.Transparency = col, 0.3
	TweenService:Create(r.wave, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {Size = Vector3.new(9, 0.05, 9)}):Play()
	TweenService:Create(r.waveDecal, TweenInfo.new(0.6), {Transparency = 1}):Play()
	r.mid.WorldPosition = topCF.Position + Vector3.new(0, 3.6, 0)
	r.burst.Color = ColorSequence.new(col)
	r.burst:Emit(math.min(12, math.floor((BURST[tonumber(rank) or 2] or 8) * 0.5)))
	r.light.Color, r.light.Enabled, r.light.Brightness = col, true, 1.8
	TweenService:Create(r.light, TweenInfo.new(0.8), {Brightness = 0}):Play()
	task.delay(0.85, function() if r.token == my and r.folder.Parent then r.light.Enabled = false end end)
end

-- click / tap anywhere in the world skips your own running reveal to the same result (does not change roll speed or odds);
-- with the Quick Rolls pass active (see above) this is the pass perk and non-owners get its purchase prompt instead
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	local t = input.UserInputType
	if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
	for a in pairs(running) do if a.result then a:TrySkip() end end
end)

return M
