-- PlowSoundClient (2026-10-06, Claude; wiktor: "we need to add SFX game is quiet now, snow destroying sfx maybe some engine sound").
--   * Snow clearing: a crunch on every real payout from the server (SnowCollected - also during AFK auto-plow), throttled, louder and
--     deeper when more layers break at once (a big burst adds a soft whoosh).
--   * Other players' plows: the nearest few get a quiet engine loop with a short rolloff. Your own engine/skid live in PlowDriveClient.
-- Volumes and ids: PlowConfig C.Sound. Everything follows Settings > DriveSoundOn.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local C = require(RS:WaitForChild("PlowConfig"))
local S = C.Sound
local function soundOn() return player:GetAttribute("DriveSoundOn") ~= false end

-- crunch pool (2D, a few voices so overlapping payouts don't cut each other)
local pool, nextVoice = {}, 1
for i = 1, 4 do
	local s = Instance.new("Sound")
	s.Name = "SnowCrunch" .. i
	s.SoundId = S.CrunchIds[(i - 1) % #S.CrunchIds + 1]
	s.Parent = SoundService
	pool[i] = s
end
local big = Instance.new("Sound")
big.Name = "SnowWhoosh"; big.SoundId = S.CrunchBigId; big.Parent = SoundService

local lastCrunch, lastBig = 0, 0
RS:WaitForChild("SnowCollected").OnClientEvent:Connect(function(_, _, layers)
	if not soundOn() then return end
	local now = os.clock()
	if now - lastCrunch < S.CrunchGap then return end
	lastCrunch = now
	local amount = math.clamp((tonumber(layers) or 1) / 8, 0, 1) -- 1 layer = light, 8+ = full
	local s = pool[nextVoice]; nextVoice = nextVoice % #pool + 1
	s.SoundId = S.CrunchIds[math.random(1, #S.CrunchIds)]
	s.Volume = S.Crunch + (S.CrunchBig - S.Crunch) * amount
	s.PlaybackSpeed = (1.12 - 0.3 * amount) * (0.94 + math.random() * 0.12) -- more snow = deeper
	s.TimePosition = 0
	s:Play()
	if amount > 0.6 and now - lastBig > 0.6 then
		lastBig = now
		big.Volume = S.CrunchBig * 0.7 * amount
		big.PlaybackSpeed = 0.9 + math.random() * 0.15
		big.TimePosition = 0
		big:Play()
	end
end)

-- other players' engines: nearest S.OtherMax plows within S.OtherRange
local folder = workspace:WaitForChild("Snowplows")
local active = {} -- [hull] = sound
local engineId = (C.Drive.Drift and C.Drive.Drift.EngineSound) or "rbxassetid://71482635231754"
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then return end
	acc = 0
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local cand = {}
	if root and soundOn() then
		for _, m in ipairs(folder:GetChildren()) do
			local hull = m:IsA("Model") and m.PrimaryPart
			if hull and m.Name ~= "Snowplow_" .. player.UserId then
				local d = (hull.Position - root.Position).Magnitude
				if d < S.OtherRange then cand[#cand + 1] = {hull, d} end
			end
		end
		table.sort(cand, function(a, b) return a[2] < b[2] end)
	end
	local keep = {}
	for i = 1, math.min(#cand, S.OtherMax) do keep[cand[i][1]] = true end
	for hull, s in pairs(active) do
		if not keep[hull] or not hull.Parent then s:Destroy(); active[hull] = nil end
	end
	for hull in pairs(keep) do
		local s = active[hull]
		if not s then
			s = Instance.new("Sound")
			s.Name = "OtherEngine"; s.SoundId = engineId; s.Looped = true
			s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 8; s.RollOffMaxDistance = S.OtherRange
			s.Parent = hull; s:Play()
			active[hull] = s
		end
		local v = hull.AssemblyLinearVelocity.Magnitude
		local top = hull:GetAttribute("MaxSpeed") or 20
		s.Volume = S.OtherEngine * (v > 1 and 1 or 0.5)
		s.PlaybackSpeed = 0.85 + 0.45 * math.clamp(v / top, 0, 1)
	end
end)
