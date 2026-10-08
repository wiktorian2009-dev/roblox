-- MusicPlayer: shuffled playlist with crossfades, ducks during rare drops, on/off from Settings (saved).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local cfg = require(ReplicatedStorage:WaitForChild("MusicConfig"))
local setSetting = ReplicatedStorage:WaitForChild("SetSetting")
local player = Players.LocalPlayer

local group = Instance.new("SoundGroup")
group.Name = "Music"
group.Volume = cfg.Volume
group.Parent = SoundService

local function musicOn() return player:GetAttribute("MusicOn") ~= false end
local function targetVolume()
	if not musicOn() then return 0 end
	return player:GetAttribute("MusicDuck") and cfg.DuckVolume or cfg.Volume
end
local function applyVolume(t)
	TweenService:Create(group, TweenInfo.new(t or 0.6), {Volume = targetVolume()}):Play()
end
player:GetAttributeChangedSignal("MusicOn"):Connect(function() applyVolume(0.6) end)
player:GetAttributeChangedSignal("MusicDuck"):Connect(function() applyVolume(player:GetAttribute("MusicDuck") and 0.3 or 1.5) end)

-- playlist
local order = {}
local function reshuffle()
	order = table.clone(cfg.Tracks)
	if cfg.Shuffle then
		for i = #order, 2, -1 do
			local j = math.random(i)
			order[i], order[j] = order[j], order[i]
		end
	end
end
local index = 0
local function nextId()
	index += 1
	if index > #order then
		local last = order[#order]
		reshuffle()
		if #order > 1 and order[1] == last then order[1], order[2] = order[2], order[1] end
		index = 1
	end
	return order[index]
end

local function newSound(id)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 0
	s.SoundGroup = group
	s.Parent = SoundService
	return s
end

task.spawn(function()
	if #cfg.Tracks == 0 then return end
	reshuffle()
	applyVolume(0)
	local current
	while true do
		local s = newSound(nextId())
		local t0 = os.clock()
		while not s.IsLoaded and os.clock() - t0 < 10 do task.wait(0.2) end
		if not s.IsLoaded or s.TimeLength <= 0 then
			s:Destroy() -- broken / moderated track: skip it
			task.wait(1)
		else
			s:Play()
			TweenService:Create(s, TweenInfo.new(cfg.Crossfade), {Volume = 1}):Play()
			if current then
				local old = current
				TweenService:Create(old, TweenInfo.new(cfg.Crossfade), {Volume = 0}):Play()
				task.delay(cfg.Crossfade + 0.1, function() old:Destroy() end)
			end
			current = s
			-- wait until it's time to start the next track (overlapping by the crossfade)
			task.wait(math.max(1, s.TimeLength - cfg.Crossfade))
		end
	end
end)

-- Settings toggle (same look as the other switches)
task.spawn(function()
	local row = player:WaitForChild("PlayerGui"):WaitForChild("RNGGui"):WaitForChild("Panels"):WaitForChild("Settings")
		:WaitForChild("Inner"):WaitForChild("Content"):WaitForChild("MusicRow")
	local tog = row:WaitForChild("MusicToggle")
	local knob = tog:WaitForChild("Knob")
	local function draw(animate)
		local on = musicOn()
		local pos = on and UDim2.fromScale(0.54, 0.5) or UDim2.fromScale(0.06, 0.5)
		local col = on and Color3.fromRGB(80, 210, 110) or Color3.fromRGB(190, 196, 212)
		if animate then
			TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = pos}):Play()
			TweenService:Create(tog, TweenInfo.new(0.2), {BackgroundColor3 = col}):Play()
		else
			knob.Position = pos
			tog.BackgroundColor3 = col
		end
	end
	draw(false)
	player:GetAttributeChangedSignal("MusicOn"):Connect(function() draw(true) end)
	tog.Activated:Connect(function()
		local on = not musicOn()
		player:SetAttribute("MusicOn", on) -- instant locally
		setSetting:FireServer("MusicOn", on) -- saved
	end)
end)
