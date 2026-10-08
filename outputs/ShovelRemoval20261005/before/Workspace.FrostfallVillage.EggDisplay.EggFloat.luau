-- EggFloat (RunContext = Client): smooth idle float + sway, playful hop-wiggles with a sparkle burst,
-- the nearest egg lifts and turns toward the player, glow pulse, and "COMING SOON" labels that fade by distance.
-- Only the visual Shell moves; HatchAnchor (prompt / odds sign) stays still.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local display = script.Parent
local player = Players.LocalPlayer
local rng = Random.new()
local centre = display:GetPivot().Position

local list, known = {}, {}
local function add(model)
	if not model:IsA("Model") or known[model] then return end
	local shell, anchor = model:FindFirstChild("Shell"), model:FindFirstChild("HatchAnchor")
	if not (shell and anchor) then return end
	known[model] = true
	local label = anchor:FindFirstChild("ComingSoon")
	local text = label and label:FindFirstChildOfClass("TextLabel")
	local fx = model:FindFirstChild("FxVolume")
	local raysAtt = fx and fx:FindFirstChild("RaysAtt")
	table.insert(list, {
		shell = shell, anchor = anchor, base = shell.CFrame,
		phase = (model:GetAttribute("Order") or #list + 1) * 0.9,
		lift = 0, turn = 0, hop = -1, nextHop = os.clock() + rng:NextNumber(2.5, 8),
		light = anchor:FindFirstChild("EggGlow"), pad = model:FindFirstChild("GlowPad"),
		sparkle = (fx and fx:FindFirstChild("Sparkle")) or anchor:FindFirstChild("Sparkle"),
		rays = raysAtt and raysAtt:FindFirstChild("Rays"), raysOn = false,
		label = label, text = text, stroke = text and text:FindFirstChildOfClass("UIStroke"), labelAlpha = 0,
	})
end
for _, m in ipairs(display:GetChildren()) do add(m) end
display.DescendantAdded:Connect(function(d)
	if d.Parent and (d.Name == "Shell" or d.Name == "HatchAnchor") then task.defer(add, d.Parent) end
end)

local function ease(cur, target, speed, dt) return cur + (target - cur) * (1 - math.exp(-speed * dt)) end
local HOP_TIME, NEAR, LABEL_NEAR, RANGE = 0.9, 13, 22, 220
local parts, cframes = {}, {}

RunService.PreRender:Connect(function(dt)
	dt = math.min(dt, 0.1)
	local cam = workspace.CurrentCamera
	if not cam or (cam.CFrame.Position - centre).Magnitude > RANGE then return end
	local t = os.clock()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	local nearest, nd = nil, NEAR
	if hrp then
		for _, e in ipairs(list) do
			local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(e.anchor.Position.X, 0, e.anchor.Position.Z)).Magnitude
			if d < nd then nearest, nd = e, d end
		end
	end

	table.clear(parts); table.clear(cframes)
	for _, e in ipairs(list) do
		if e.shell.Parent then
			local p = t * 1.2 + e.phase
			local bob = (math.sin(p) * 0.5 + 0.5) * 0.38
			local lean = math.cos(p) * 0.035
			local sway = math.sin(t * 0.33 + e.phase) * 0.12

			local wantLift, wantTurn = 0, 0
			if e == nearest then
				wantLift = 0.55
				local rel = e.base:PointToObjectSpace(hrp.Position)
				wantTurn = math.clamp(math.atan2(-rel.X, -rel.Z), -0.6, 0.6)
			end
			e.lift = ease(e.lift, wantLift, 4, dt)
			e.turn = ease(e.turn, wantTurn, 3, dt)

			-- light beams rise behind the egg you are standing at
			local wantRays = e == nearest
			if e.rays and wantRays ~= e.raysOn then
				e.raysOn = wantRays
				e.rays.Rate = wantRays and 1.4 or 0
				if wantRays then e.rays:Emit(1) end
			end

			if e.hop < 0 and t >= e.nextHop then
				e.hop = 0
				e.nextHop = t + rng:NextNumber(6, 11)
				if e.sparkle then e.sparkle:Emit(8) end
			end
			local hopY, wig = 0, 0
			if e.hop >= 0 then
				e.hop += dt
				local k = e.hop / HOP_TIME
				if k >= 1 then
					e.hop = -1
				else
					hopY = math.sin(k * math.pi) ^ 1.5 * 0.6
					wig = math.sin(k * math.pi * 4) * 0.17 * (1 - k) ^ 2
				end
			end

			table.insert(parts, e.shell)
			table.insert(cframes, e.base * CFrame.new(0, bob + e.lift + hopY, 0) * CFrame.Angles(lean, sway + e.turn, wig))

			local glow = 0.5 + 0.5 * math.sin(p * 0.8)
			if e.light then e.light.Brightness = 0.7 + glow * 0.5 + e.lift * 0.8 end
			if e.pad then e.pad.Transparency = 0.72 - glow * 0.14 - e.lift * 0.15 end

			if e.label and e.text then
				local close = hrp and (hrp.Position - e.anchor.Position).Magnitude < LABEL_NEAR
				e.labelAlpha = ease(e.labelAlpha, close and 1 or 0, 6, dt)
				e.label.Enabled = e.labelAlpha > 0.02
				e.text.TextTransparency = 1 - e.labelAlpha
				if e.stroke then e.stroke.Transparency = 1 - e.labelAlpha end
			end
		end
	end
	if #parts > 0 then workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged) end
end)
