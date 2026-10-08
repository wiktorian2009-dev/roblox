-- Wiggles the "30% OFF" badge on the Shop icon.
local RunService = game:GetService("RunService")
local badge = script.Parent:WaitForChild("LeftMenu"):WaitForChild("ShopButton"):WaitForChild("SaleBadge")
local scale = badge:WaitForChild("UIScale")
local b1, b2 = badge:WaitForChild("Burst1"), badge:WaitForChild("Burst2")
local pct = badge:WaitForChild("Percent")

local function updateText()
	pct.Text = tostring(badge:GetAttribute("Percent") or 30) .. "%"
end
badge:GetAttributeChangedSignal("Percent"):Connect(updateText)
updateText()

local t = 0
RunService.RenderStepped:Connect(function(dt)
	if not badge.Visible then return end
	t += dt
	local cycle = t % 3
	-- quick attention wiggle at the start of every 3 seconds, calm sway the rest of the time
	local wiggle = cycle < 0.7 and math.sin(cycle * 38) * 20 * (1 - cycle / 0.7) or 0
	badge.Rotation = -10 + math.sin(t * 2) * 4 + wiggle
	local pop = cycle < 0.18 and 0.15 * (1 - cycle / 0.18) or 0
	scale.Scale = 1 + math.sin(t * 4) * 0.04 + pop
	-- starburst slowly spins behind the text
	b1.Rotation = (t * 30) % 360
	b2.Rotation = (t * 30 + 45) % 360
end)
