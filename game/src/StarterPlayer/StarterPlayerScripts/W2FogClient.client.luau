-- W2FogClient (2026-10-06, Claude; wiktor: "when unlocking the stages in world 2 fog should dissapear").
-- World 2's fog walls are the MistBank_<From>To<Stage> models in workspace.World2.CloudCurtains. Each one now fades out (2 s) for this
-- player when the stage behind it unlocks (player attribute Stage_<Stage>, set by StageService), and stays hidden when the player
-- joins or rejoins with that stage already open. Locked stages keep their fog. Visual only, per player; nothing on the server changes.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local FADE = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setup(bank)
	local stage = bank.Name:match("To(%u%l+)$")
	if not stage then return end
	local parts, emitters = {}, {}
	for _, d in ipairs(bank:GetDescendants()) do
		if d:IsA("BasePart") then parts[#parts + 1] = {d, d.Transparency}
		elseif d:IsA("ParticleEmitter") then emitters[#emitters + 1] = {d, d.Enabled} end
	end
	local shown = true
	local function apply(open, instant)
		if open == not shown then return end
		shown = not open
		for _, e in ipairs(emitters) do
			e[1].Enabled = (not open) and e[2]
			if open then e[1]:Clear() end
		end
		for _, p in ipairs(parts) do
			local goal = open and 1 or p[2]
			if instant then p[1].Transparency = goal else TweenService:Create(p[1], FADE, {Transparency = goal}):Play() end
		end
	end
	local attr = "Stage_" .. stage
	apply(player:GetAttribute(attr) == true, true)
	player:GetAttributeChangedSignal(attr):Connect(function() apply(player:GetAttribute(attr) == true, false) end)
end

local w2 = workspace:WaitForChild("World2", 60)
local curtains = w2 and w2:WaitForChild("CloudCurtains", 60)
if curtains then
	for _, bank in ipairs(curtains:GetChildren()) do task.spawn(setup, bank) end
	curtains.ChildAdded:Connect(function(bank) task.wait(); setup(bank) end) -- streamed in later
end
