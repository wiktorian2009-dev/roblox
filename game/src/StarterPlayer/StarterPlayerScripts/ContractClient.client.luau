-- ContractClient (2026-10-05, Claude): draws the NPC clearing contracts ("Help Yards"); ContractService (server) decides everything.
-- HELP REQUEST announcement (HELP OUT / LATER), a small available-job pill, the objective tracker (sub-objectives, progress, time, reward,
-- cancel), a waypoint to the NPC, outlines + labels on the marked work areas (owner only), and the scene reactions every player sees
-- (lamps, shutters, crates rising, bus / van arriving, pump spinning) driven by the scene's public attributes.
-- Suppressed (popup + pill hidden) while LocalPlayer attribute SuppressEvents == true (the tutorial sets it during essential steps),
-- during the intro / first tutorial, in the garage and during the Frost King announcement/fight. Mute keeps the pill, hides the popup.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local CFG = require(RS:WaitForChild("ContractConfig"))
local Format = require(RS:WaitForChild("NumberFormat"))
local okUI, UI = pcall(function() return require(RS:WaitForChild("SnowUI", 10)) end)
local Art = require(RS:WaitForChild("FeatureUIArt"))
local event = RS:WaitForChild("ContractEvent")
local request = RS:WaitForChild("ContractRequest")
local function now() return workspace:GetServerTimeNow() end

local FONT = Enum.Font.FredokaOne
local WHITE, NAVY = Color3.new(1, 1, 1), Color3.fromRGB(20, 40, 85)
local ICE, GREEN, GREY, GOLD = Color3.fromRGB(150, 225, 255), Color3.fromRGB(80, 210, 110), Color3.fromRGB(150, 160, 185), Color3.fromRGB(255, 220, 110)
local PEND = Color3.fromRGB(255, 205, 70)
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
local function fmtTime(s) s = math.max(0, math.floor(s + 0.5)); return ("%d:%02d"):format(s // 60, s % 60) end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function label(parent, text, props)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = text, TextColor3 = WHITE, ZIndex = 6}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	mk("UIStroke", {Thickness = 2.2, Color = NAVY}, l)
	return l
end
local function panel(parent, props)
	local f = mk("Frame", {BackgroundColor3 = Color3.fromRGB(34, 91, 153), BorderSizePixel = 0, Visible = false}, parent)
	for k, v in pairs(props) do f[k] = v end
	mk("UICorner", {CornerRadius = UDim.new(0.12, 0)}, f)
	mk("UIStroke", {Thickness = 3, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, f)
	if okUI then pcall(UI.Skin, f, "card") end
	Art.Skin(f)
	return f
end
local function button(parent, text, color, props)
	local b = mk("TextButton", {AutoButtonColor = true, BackgroundColor3 = color, Text = "", ZIndex = 7, BorderSizePixel = 0}, parent)
	for k, v in pairs(props or {}) do b[k] = v end
	mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, b)
	mk("UIStroke", {Thickness = 2.5, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
	local l = label(b, text, {Name = "Text", Size = UDim2.fromScale(0.9, 0.7), Position = UDim2.fromScale(0.05, 0.15), ZIndex = 8})
	b:SetAttribute("SnowUIDecor", true)
	Art.Skin(b)
	return b, l
end
local function portraitOf(img, userId, icon)
	img.Image = ""
	local ic = img:FindFirstChild("Icon")
	if ic then ic.Text = icon or "\u{2744}"; ic.Visible = true end
	if userId and userId > 0 then
		task.spawn(function()
			local ok, url = pcall(function() return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
			if ok and url then img.Image = url; if ic then ic.Visible = false end end
		end)
	end
end
local function portrait(parent, props)
	local f = mk("ImageLabel", {BackgroundColor3 = Color3.fromRGB(120, 180, 240), BorderSizePixel = 0, ZIndex = 7, ScaleType = Enum.ScaleType.Crop}, parent)
	for k, v in pairs(props) do f[k] = v end
	mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
	mk("UIStroke", {Thickness = 2.5, Color = NAVY}, f)
	mk("UIAspectRatioConstraint", {AspectRatio = 1}, f)
	label(f, "\u{2744}", {Name = "Icon", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), ZIndex = 8})
	return f
end

--------------------------------------------------
-- GUI
--------------------------------------------------
local gui = mk("ScreenGui", {Name = "ContractGui", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 55, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
-- announcement
local ann = panel(gui, {Name = "Announce", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(touch and 0.9 or 0.44, touch and 0.36 or 0.3)})
mk("UISizeConstraint", {MaxSize = Vector2.new(620, 300)}, ann)
local annScale = mk("UIScale", {Scale = 1}, ann)
local annTitle = label(ann, "HELP REQUEST!", {Position = UDim2.fromScale(0.26, 0.04), Size = UDim2.fromScale(0.7, 0.2), TextXAlignment = Enum.TextXAlignment.Left})
mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, ICE)}, annTitle)
local annPortrait = portrait(ann, {Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.2, 0.5)})
local annWho = label(ann, "", {Position = UDim2.fromScale(0.26, 0.25), Size = UDim2.fromScale(0.7, 0.14), TextXAlignment = Enum.TextXAlignment.Left})
local annJob = label(ann, "", {Position = UDim2.fromScale(0.26, 0.4), Size = UDim2.fromScale(0.7, 0.13), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD})
local annInfo = label(ann, "", {Position = UDim2.fromScale(0.04, 0.56), Size = UDim2.fromScale(0.92, 0.11), TextColor3 = Color3.fromRGB(225, 240, 255)})
local annReward = label(ann, "", {Position = UDim2.fromScale(0.04, 0.66), Size = UDim2.fromScale(0.92, 0.1), TextColor3 = GOLD})
local helpBtn, helpText = button(ann, "HELP OUT", GREEN, {Position = UDim2.fromScale(0.1, 0.79), Size = UDim2.fromScale(0.44, 0.17)})
local laterBtn = button(ann, "LATER", GREY, {Position = UDim2.fromScale(0.6, 0.79), Size = UDim2.fromScale(0.3, 0.17)})
Art.Icon(ann, "contracts", UDim2.fromScale(0.018, 0.805), UDim2.fromScale(0.068, 0.15), "FeatureContractIcon")
-- available-job pill
local pill = panel(gui, {Name = "Pill", AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromScale(0.012, touch and 0.62 or 0.76), Size = UDim2.fromScale(touch and 0.42 or 0.2, touch and 0.075 or 0.062)})
local pillBtn = mk("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(0.78, 1), ZIndex = 9}, pill)
Art.Icon(pill, "contracts", UDim2.fromScale(0.022, 0.14), UDim2.fromScale(0.115, 0.72), "FeatureContractIcon")
local pillText = label(pill, "", {Position = UDim2.fromScale(0.15, 0.14), Size = UDim2.fromScale(0.62, 0.72), TextXAlignment = Enum.TextXAlignment.Left})
local muteBtn, muteText = button(pill, "\u{1F514}", Color3.fromRGB(120, 180, 255), {Position = UDim2.fromScale(0.8, 0.14), Size = UDim2.fromScale(0.17, 0.72)})
-- tracker
local tracker = panel(gui, {Name = "Tracker", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(touch and 0.8 or 0.925, touch and 0.16 or 0.27), Size = UDim2.fromScale(touch and 0.42 or 0.21, touch and 0.36 or 0.33)})
mk("UISizeConstraint", {MaxSize = Vector2.new(360, 340)}, tracker)
local trPortrait = portrait(tracker, {Position = UDim2.fromScale(0.04, 0.03), Size = UDim2.fromScale(0.16, 0.16)})
local trName = label(tracker, "", {Position = UDim2.fromScale(0.23, 0.03), Size = UDim2.fromScale(0.74, 0.09), TextXAlignment = Enum.TextXAlignment.Left})
local trWho = label(tracker, "", {Position = UDim2.fromScale(0.23, 0.12), Size = UDim2.fromScale(0.74, 0.07), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ICE})
local rowsFrame = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.22), Size = UDim2.fromScale(0.9, 0.46), ZIndex = 6}, tracker)
mk("UIListLayout", {Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder}, rowsFrame)
local barBack = mk("Frame", {Position = UDim2.fromScale(0.05, 0.7), Size = UDim2.fromScale(0.9, 0.07), BackgroundColor3 = Color3.fromRGB(25, 40, 80), BorderSizePixel = 0, ZIndex = 6}, tracker)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, barBack)
local barFill = mk("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = GREEN, BorderSizePixel = 0, ZIndex = 7}, barBack)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, barFill)
local barText = label(barBack, "", {Size = UDim2.fromScale(1, 1), ZIndex = 8})
local trTime = label(tracker, "", {Position = UDim2.fromScale(0.05, 0.79), Size = UDim2.fromScale(0.42, 0.08), TextXAlignment = Enum.TextXAlignment.Left})
local trReward = label(tracker, "", {Position = UDim2.fromScale(0.47, 0.79), Size = UDim2.fromScale(0.48, 0.08), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = GOLD})
local cancelBtn, cancelText = button(tracker, "CANCEL", Color3.fromRGB(235, 95, 105), {Position = UDim2.fromScale(0.3, 0.89), Size = UDim2.fromScale(0.4, 0.09)})
-- toast
local toast = panel(gui, {Name = "Toast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromScale(touch and 0.86 or 0.4, 0.09)})
local toastText = label(toast, "", {Position = UDim2.fromScale(0.04, 0.12), Size = UDim2.fromScale(0.92, 0.76)})
local toastToken = 0
local function showToast(text, color, secs)
	toastToken += 1
	local my = toastToken
	toastText.Text = text; toastText.TextColor3 = color or WHITE
	toast.Visible = true
	task.delay(secs or 3.5, function() if toastToken == my then toast.Visible = false end end)
end
local function sound(id, vol)
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol or 0.4; s.Parent = gui; s:Play()
	s.Ended:Connect(function() s:Destroy() end)
	task.delay(6, function() if s.Parent then s:Destroy() end end)
end

--------------------------------------------------
-- state
--------------------------------------------------
local offer, job = nil, nil
local popupOpen, dismissed = false, {}
local muted = false
local cancelArmed = 0
local function suppressed()
	if player:GetAttribute("SuppressEvents") == true or player:GetAttribute("IntroActive") == true then return true end
	if player:GetAttribute("PlowTutorialDone") ~= true or player:GetAttribute("InGarage") == true then return true end
	local fk = player.PlayerGui:FindFirstChild("FrostKingGui")
	if fk and ((fk:FindFirstChild("Announce") and fk.Announce.Visible) or (fk:FindFirstChild("BossBar") and fk.BossBar.Visible)) then return true end
	return false
end
local function call(action, id, value)
	local ok, res = pcall(function() return request:InvokeServer(action, id, value) end)
	if not ok or type(res) ~= "table" then return {ok = false, msg = "Connection problem - try again."} end
	return res
end

-- world guidance (owner only)
local fx = mk("Folder", {Name = "ContractClientFX"}, workspace)
local outline = {} -- [group] = {parts, label}
local wp = {}
local function clearGuidance()
	fx:ClearAllChildren()
	outline, wp = {}, {}
end
local function edge(parent, a, b, color)
	local mid, len = (a + b) / 2, (b - a).Magnitude
	return mk("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = color,
		Transparency = 0.15, Size = Vector3.new(0.35, 0.25, len + 0.35), CFrame = CFrame.lookAt(mid, b)}, parent)
end
local function buildGuidance(j)
	clearGuidance()
	for _, z in ipairs(j.Zones or {}) do
		local c, hw, hd = z.Center + Vector3.new(0, 2.6, 0), z.W / 2, z.D / 2
		local p = {c + Vector3.new(-hw, 0, -hd), c + Vector3.new(hw, 0, -hd), c + Vector3.new(hw, 0, hd), c + Vector3.new(-hw, 0, hd)}
		local o = outline[z.Group] or {parts = {}}
		outline[z.Group] = o
		for k = 1, 4 do table.insert(o.parts, edge(fx, p[k], p[k % 4 + 1], PEND)) end
		if not o.label then
			local anchor = mk("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new(c + Vector3.new(0, 3, 0))}, fx)
			local bb = mk("BillboardGui", {Size = UDim2.fromOffset(170, 44), AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 140, Adornee = anchor}, anchor)
			o.label = label(bb, "", {Size = UDim2.fromScale(1, 1)})
		end
	end
	-- waypoint: a marker over the NPC and a soft beam from you to it
	local tp = mk("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new(j.Waypoint + Vector3.new(0, 11, 0))}, fx)
	local bb = mk("BillboardGui", {Size = UDim2.fromOffset(150, 60), AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 2000, Adornee = tp}, tp)
	wp.text = label(bb, "", {Size = UDim2.fromScale(1, 1), TextColor3 = GOLD})
	wp.part = tp
	wp.a1 = mk("Attachment", {}, tp)
end
local function refreshLabels(j)
	for _, g in ipairs(j.Groups or {}) do
		local o = outline[g.Key]
		if o then
			local need = math.max(1, math.ceil(g.Total * CFG.Job.Tolerance))
			local pct = math.clamp(math.floor(g.Cleared / need * 100 + 0.5), 0, 100)
			o.label.Text = g.Done and ("\u{2714} " .. g.Label) or (g.Label .. "  " .. pct .. "%")
			o.label.TextColor3 = g.Done and GREEN or WHITE
			for _, p in ipairs(o.parts) do p.Color = g.Done and GREEN or PEND end
		end
	end
end

-- tracker
local rowLabels = {}
local function buildTracker(j)
	for _, r in ipairs(rowLabels) do r:Destroy() end
	rowLabels = {}
	for i, g in ipairs(j.Groups) do
		local r = label(rowsFrame, "", {Size = UDim2.fromScale(1, math.min(0.18, 0.9 / #j.Groups)), LayoutOrder = i, TextXAlignment = Enum.TextXAlignment.Left})
		rowLabels[i] = r
	end
	trName.Text = (j.Icon or "") .. " " .. j.Name
	trWho.Text = j.NpcName .. (j.IsFriend and "  (NPC helper)" or "")
	trReward.Text = "\u{2744} +" .. Format.Abbreviate(j.Reward) .. " bonus"
	portraitOf(trPortrait, j.NpcUserId, j.Icon)
end
local function refreshTracker(j)
	local need, have = 0, 0
	for i, g in ipairs(j.Groups) do
		local n = math.max(1, math.ceil(g.Total * CFG.Job.Tolerance))
		need += n; have += math.min(n, g.Cleared)
		local r = rowLabels[i]
		if r then
			r.Text = (g.Done and "\u{2714} " or "\u{25CB} ") .. g.Label .. (g.Done and "" or ("  " .. math.floor(math.min(1, g.Cleared / n) * 100) .. "%"))
			r.TextColor3 = g.Done and GREEN or WHITE
		end
	end
	local f = need > 0 and have / need or 0
	barFill.Size = UDim2.fromScale(math.clamp(f, 0, 1), 1)
	barText.Text = math.floor(f * 100) .. "%"
	refreshLabels(j)
end

local function showOffer(o, force)
	offer = o
	dismissed[o.Id] = dismissed[o.Id] or false
	annWho.Text = o.NpcName .. " needs help!"
	annJob.Text = (o.Icon or "") .. " " .. o.Name
	annInfo.Text = "Estimated time: 1\u{2013}3 minutes  \u{2022}  " .. o.StageName
	annReward.Text = "Reward: \u{2744} +" .. Format.Abbreviate(o.Reward) .. " bonus + the Snow you clear"
	portraitOf(annPortrait, o.NpcUserId, o.Icon)
	if (force or (not muted and not dismissed[o.Id])) and not suppressed() and not job then
		popupOpen = true
		ann.Visible = true
		annScale.Scale = 0.85
		TweenService:Create(annScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
		if not force then sound("rbxassetid://12221976", 0.3) end
		local id = o.Id
		task.delay(25, function() if offer and offer.Id == id and popupOpen then popupOpen = false; ann.Visible = false; dismissed[id] = true end end)
	end
end
local function startJob(j)
	job, offer = j, nil
	ann.Visible, popupOpen = false, false
	buildTracker(j)
	buildGuidance(j)
	refreshTracker(j)
	tracker.Visible = true
end
local function endJob()
	job = nil
	tracker.Visible = false
	clearGuidance()
end

helpBtn.Activated:Connect(function()
	if not offer then return end
	local id = offer.Id
	helpText.Text = "..."
	local res = call("Accept", id)
	helpText.Text = "HELP OUT"
	if res.ok and res.job then
		startJob(res.job)
		showToast("Follow the marker to " .. res.job.NpcName .. "!", GOLD)
	else
		showToast(res.msg or "Couldn't accept that job.", Color3.fromRGB(255, 160, 160))
		if offer and offer.Id == id then ann.Visible, popupOpen = false, false end
	end
end)
laterBtn.Activated:Connect(function()
	if offer then dismissed[offer.Id] = true end
	ann.Visible, popupOpen = false, false
end)
pillBtn.Activated:Connect(function() if offer then showOffer(offer, true) end end)
muteBtn.Activated:Connect(function()
	local res = call("Mute", nil, not muted)
	if res.ok then muted = res.muted == true end
	muteText.Text = muted and "\u{1F515}" or "\u{1F514}"
	showToast(muted and "Help requests muted - the pill still shows new jobs." or "Help request pop-ups are on.", ICE, 2.5)
end)
cancelBtn.Activated:Connect(function()
	if not job then return end
	if os.clock() > cancelArmed then cancelArmed = os.clock() + 3; cancelText.Text = "SURE?"; return end
	cancelArmed = 0; cancelText.Text = "CANCEL"
	local res = call("Cancel", job.Id)
	if res.ok then endJob() end
end)

local REASONS = {Expired = "The help request expired.", TimeUp = "Out of time - the job was cancelled.", Abandoned = "You left the yard - the job was cancelled.",
	StageLocked = "That stage is locked now - the job was cancelled.", Cancelled = "Job cancelled.", Declined = nil, Finished = nil, Left = nil}
event.OnClientEvent:Connect(function(kind, a, b, c, d, e)
	if kind == "Offer" then
		showOffer(a)
	elseif kind == "Accepted" then
		if not job or job.Id ~= a.Id then startJob(a) end
	elseif kind == "Progress" then
		if job and job.Id == a then job.Groups = b; refreshTracker(job) end
	elseif kind == "GroupDone" then
		if job and job.Id == a then
			for _, g in ipairs(job.Groups) do if g.Key == b then g.Done = true; g.Cleared = math.max(g.Cleared, math.ceil(g.Total * CFG.Job.Tolerance)); showToast("\u{2714} " .. g.Label .. " cleared!", GREEN, 2) end end
			refreshTracker(job)
			sound("rbxassetid://12221976", 0.25)
		end
	elseif kind == "Completed" then
		if job and job.Id == a then
			for _, g in ipairs(job.Groups) do g.Done = true end
			refreshTracker(job)
			showToast(("%s: \"%s\"  \u{2744} +%s bonus!"):format(d or "Helper", c or "Thank you!", Format.Abbreviate(b or 0)), GOLD, 5)
			sound("rbxassetid://125078105193243", 0.5)
			cancelBtn.Visible = false
			task.delay(4, function() if job and job.Id == a then endJob(); cancelBtn.Visible = true end end)
		end
	elseif kind == "Ended" then
		if offer and offer.Id == a then offer = nil; ann.Visible, popupOpen = false, false end
		if job and job.Id == a then endJob(); cancelBtn.Visible = true end
		if REASONS[b] then showToast(REASONS[b], ICE, 3.5) end
	end
end)

-- per-frame UI: pill timer, tracker timer, waypoint, suppression
RunService.RenderStepped:Connect(function()
	local t = now()
	local sup = suppressed()
	local hideAll = player:GetAttribute("SuppressEvents") == true
	if offer and offer.Expires and t > offer.Expires then offer = nil end
	pill.Visible = offer ~= nil and job == nil and not popupOpen and not hideAll and not (player:GetAttribute("PlowTutorialDone") ~= true)
	if offer then pillText.Text = "HELP REQUEST  " .. fmtTime(offer.Expires - t) end
	if sup and popupOpen then ann.Visible, popupOpen = false, false end
	if job then
		tracker.Visible = not hideAll
		trTime.Text = "\u{23F1} " .. fmtTime((job.Deadline or t) - t)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if wp.part and hrp then
			local d = (hrp.Position - wp.part.Position).Magnitude
			wp.text.Text = d > 30 and ("\u{2B07} " .. job.NpcName .. "  " .. math.floor(d) .. "m") or ""
			if d > 45 and not wp.beam then
				local a0 = mk("Attachment", {Name = "ContractBeamA0"}, hrp)
				wp.a0 = a0
				wp.beam = mk("Beam", {Attachment0 = a0, Attachment1 = wp.a1, Width0 = 0.5, Width1 = 0.5, FaceCamera = true, LightEmission = 1, Transparency = NumberSequence.new(0.35),
					Color = ColorSequence.new(GOLD, GREEN), TextureSpeed = 1.2, Segments = 20, CurveSize0 = 6}, fx)
			elseif (d <= 45 or not hrp:IsDescendantOf(workspace)) and wp.beam then
				wp.beam:Destroy(); wp.beam = nil
				if wp.a0 then wp.a0:Destroy(); wp.a0 = nil end
			elseif wp.beam and wp.a0 and wp.a0.Parent ~= hrp then
				wp.beam:Destroy(); wp.beam = nil; wp.a0:Destroy(); wp.a0 = nil
			end
		end
	end
end)

--------------------------------------------------
-- scene reactions (everyone sees them; driven by the scene's public attributes)
--------------------------------------------------
local scenes = {}
local function vec(s) local x, y, z = tostring(s or ""):match("([-%d%.]+),([-%d%.]+),([-%d%.]+)"); return Vector3.new(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0) end
local function setLamps(m, on)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("LampPart") then
			local c = d:GetAttribute("OnColor")
			if on then d.Material = Enum.Material.Neon; if c then d.Color = c end end
			local pl = d:FindFirstChildOfClass("PointLight"); if pl then pl.Enabled = on end
		end
	end
end
local function setHidden(m, hidden)
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = hidden and 1 or 0 end end
end
local function tweenPivot(m, from, to, secs, fade)
	task.spawn(function()
		local t0 = os.clock()
		while m.Parent do
			local k = math.clamp((os.clock() - t0) / secs, 0, 1)
			local e = 1 - (1 - k) ^ 3
			m:PivotTo(from:Lerp(to, e))
			if fade then for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = math.max(0, 1 - k * 3) end end end
			if k >= 1 then break end
			RunService.RenderStepped:Wait()
		end
	end)
end
local function setupScene(sc)
	if scenes[sc] then return end
	local e = {items = {}, done = {}, completed = false}
	scenes[sc] = e
	local origin = sc:FindFirstChild("Origin")
	local props = sc:WaitForChild("Props", 10)
	if not props then return end
	for _, m in ipairs(props:GetChildren()) do
		local it = {m = m, base = m:GetPivot()}
		table.insert(e.items, it)
		if m:GetAttribute("ArriveOnComplete") or m:GetAttribute("ShowOnGroup") then setHidden(m, true) end
		if m:GetAttribute("RiseWithGroup") then m:PivotTo(it.base + Vector3.new(0, m:GetAttribute("RiseFrom") or -3, 0)) end
	end
	local paint = sc:FindFirstChild("Surfaces")
	local function apply()
		for _, it in ipairs(e.items) do
			local m = it.m
			local g = m:GetAttribute("LightOnGroup")
			if g and sc:GetAttribute("Done_" .. g) and not it.lit then it.lit = true; setLamps(m, true) end
			if m:GetAttribute("LightOnComplete") and sc:GetAttribute("Completed") and not it.lit then it.lit = true; setLamps(m, true) end
			local sg = m:GetAttribute("SlideOnGroup")
			if sg and sc:GetAttribute("Done_" .. sg) and not it.slid then it.slid = true; tweenPivot(m, it.base, it.base + Vector3.new(0, m:GetAttribute("SlideY") or 3, 0), 1.2) end
			local show = m:GetAttribute("ShowOnGroup")
			if show and sc:GetAttribute("Done_" .. show) and not it.shown then it.shown = true; setHidden(m, false) end
			local rg = m:GetAttribute("RiseWithGroup")
			if rg then
				local f = sc:GetAttribute("G_" .. rg) or 0
				local target = it.base + Vector3.new(0, (m:GetAttribute("RiseFrom") or -3) * (1 - f), 0)
				if (m:GetPivot().Position - target.Position).Magnitude > 0.05 then tweenPivot(m, m:GetPivot(), target, 0.5) end
			end
			local rot = m:GetAttribute("RotateOnGroup")
			if rot and sc:GetAttribute("Done_" .. rot) and not it.rotated then
				it.rotated = true
				local ax = m:GetAttribute("RotateAxis") == "X" and Vector3.xAxis or (m:GetAttribute("RotateAxis") == "Y" and Vector3.yAxis or Vector3.zAxis)
				tweenPivot(m, it.base, it.base * CFrame.fromAxisAngle(ax, math.rad(m:GetAttribute("RotateDeg") or 80)), 1.0)
			end
			if sc:GetAttribute("Completed") then
				if m:GetAttribute("RemoveOnComplete") and not it.removed then it.removed = true; tweenPivot(m, it.base, it.base - Vector3.new(0, 6, 0), 1.5) end
				if m:GetAttribute("ArriveOnComplete") and not it.arrived then
					it.arrived = true
					local from = (origin and origin.CFrame or CFrame.new()):VectorToWorldSpace(vec(m:GetAttribute("ArriveFrom")))
					tweenPivot(m, it.base + from, it.base, 3.2, true)
				end
				if m:GetAttribute("SpinOnComplete") and not it.spinning then it.spinning = true end
				if m:GetAttribute("WaterOnComplete") and not it.water then
					it.water = true
					local spout = m:FindFirstChild("Spout") or m:FindFirstChildWhichIsA("BasePart")
					if spout then
						local att = mk("Attachment", {}, spout)
						mk("ParticleEmitter", {Rate = 40, Lifetime = NumberRange.new(0.6, 0.9), Speed = NumberRange.new(4, 6), SpreadAngle = Vector2.new(12, 12),
							Acceleration = Vector3.new(0, -30, 0), Color = ColorSequence.new(Color3.fromRGB(120, 200, 255)), LightEmission = 0.4,
							Size = NumberSequence.new(0.35, 0.1), Transparency = NumberSequence.new(0.2, 0.8)}, att)
					end
				end
			end
		end
		if paint then
			for _, p in ipairs(paint:GetChildren()) do
				local g = p:GetAttribute("GlowOnGroup")
				if g and sc:GetAttribute("Done_" .. g) and p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Neon; p.Color = p:GetAttribute("OnColor") or p.Color end
			end
		end
	end
	sc.AttributeChanged:Connect(apply)
	apply()
end
local function watchYard(y)
	local s = y:WaitForChild("Scene", 20)
	if not s then return end
	s.ChildAdded:Connect(function(c) if c:IsA("Model") and c.Name:sub(1, 6) == "Scene_" then task.spawn(setupScene, c) end end)
	s.ChildRemoved:Connect(function(c) scenes[c] = nil end)
	for _, c in ipairs(s:GetChildren()) do if c:IsA("Model") and c.Name:sub(1, 6) == "Scene_" then task.spawn(setupScene, c) end end
end
task.spawn(function()
	local yf = workspace:WaitForChild("ContractYards", 60)
	if not yf then return end
	yf.ChildAdded:Connect(watchYard)
	for _, y in ipairs(yf:GetChildren()) do task.spawn(watchYard, y) end
end)
RunService.Heartbeat:Connect(function(dt)
	for sc, e in pairs(scenes) do
		for _, it in ipairs(e.items) do
			if it.spinning and it.m.Parent then
				local ax = it.m:GetAttribute("SpinAxis") == "X" and Vector3.xAxis or Vector3.yAxis
				it.m:PivotTo(it.m:GetPivot() * CFrame.fromAxisAngle(ax, dt * 2.4))
			end
		end
	end
end)

-- reconnect / respawn: rebuild from the server state
task.spawn(function()
	for _ = 1, 10 do
		local res = call("Sync")
		if res.ok then
			muted = res.muted == true
			muteText.Text = muted and "\u{1F515}" or "\u{1F514}"
			if res.job then startJob(res.job) elseif res.offer then offer = res.offer; dismissed[res.offer.Id] = true end
			return
		end
		task.wait(2)
	end
end)
