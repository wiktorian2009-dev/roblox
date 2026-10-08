local RunService = game:GetService("RunService")
local model = script.Parent
local spiral = model:WaitForChild("SpiralVFX")
local core = model:WaitForChild("PortalCore")
local center = core:WaitForChild("Center")
local outerGlow = core:WaitForChild("OuterGlow")
local lightPart = model:WaitForChild("Lights"):WaitForChild("CoreLight")
local coreLight = lightPart:FindFirstChildOfClass("PointLight")
local fx = model:WaitForChild("ParticleEffects")
local floating = model:WaitForChild("IceCrystals"):WaitForChild("Floating")

local R = model:GetAttribute("WispRadius") or 19.6
local WZ = model:GetAttribute("WispZ") or 4.3

local hubs, shards, wisps = {}, {}, {}
for _, h in ipairs(spiral:GetChildren()) do
	if h:IsA("BasePart") then
		table.insert(hubs, {part = h, base = h.CFrame, speed = math.rad(h:GetAttribute("Speed") or -60)})
	end
end
for _, s in ipairs(floating:GetChildren()) do
	table.insert(shards, {m = s, base = s:GetPivot(), phase = s:GetAttribute("Phase") or 0})
end
for _, w in ipairs(fx:GetChildren()) do
	if w.Name == "OrbitWisp" then table.insert(wisps, {p = w, phase = w:GetAttribute("Phase") or 0}) end
end

local centerCF = center.CFrame
local baseGlowT = outerGlow.Transparency
local baseBright = coreLight and coreLight.Brightness or 2
local camera = workspace.CurrentCamera
local t = 0

RunService.RenderStepped:Connect(function(dt)
	t += dt
	-- skip the work when the player is far away
	if (camera.CFrame.Position - centerCF.Position).Magnitude > 600 then return end

	-- spiral layers: negative speed spins clockwise, which makes the arms read as pulling inward
	for _, h in ipairs(hubs) do
		h.part.CFrame = h.base * CFrame.Angles(0, 0, h.speed * t)
	end

	for _, s in ipairs(shards) do
		s.m:PivotTo(s.base * CFrame.new(0, math.sin(t * 1.3 + s.phase) * 0.9, 0) * CFrame.Angles(0, t * 0.6 + s.phase, 0))
	end

	for _, w in ipairs(wisps) do
		local a = math.rad(90) + math.rad(118) * math.sin(t * 0.55 + w.phase)
		w.p.CFrame = centerCF * CFrame.new(R * math.cos(a), R * math.sin(a), WZ)
	end

	local pulse = (math.sin(t * 2.2) + 1) / 2
	outerGlow.Transparency = baseGlowT + 0.12 * pulse
	if coreLight then coreLight.Brightness = baseBright + 0.6 * (1 - pulse) end
end)
