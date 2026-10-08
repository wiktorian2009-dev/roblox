-- PetFollow: every player's equipped pets hop along behind them (built & animated locally).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetModels = require(ReplicatedStorage:WaitForChild("PetModels"))

local BEHIND = 7.5        -- distance behind the player (outside the shovel spinner)
local SPACING = 3.4       -- side-by-side spacing
local VIEW_DISTANCE = 200

local folder = Instance.new("Folder")
folder.Name = "FollowingPets"
folder.Parent = workspace

local rigs = {}
local function clear(player)
	local r = rigs[player]
	if r then for _, p in ipairs(r) do p.model:Destroy() end end
	rigs[player] = nil
end
local function build(player)
	clear(player)
	local r = {}
	for name in (player:GetAttribute("EquippedPets") or ""):gmatch("[^,]+") do
		local m = PetModels.create(name)
		local _, size = m:GetBoundingBox()
		m.Parent = folder
		table.insert(r, {model = m, half = size.Y / 2, cf = nil})
	end
	rigs[player] = r
end
local function track(player)
	player:GetAttributeChangedSignal("EquippedPets"):Connect(function() build(player) end)
	build(player)
end
Players.PlayerAdded:Connect(track)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(track, p) end
Players.PlayerRemoving:Connect(clear)

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local camPos = workspace.CurrentCamera.CFrame.Position
	for player, r in pairs(rigs) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local visible = hrp and (hrp.Position - camPos).Magnitude < VIEW_DISTANCE and not (player == Players.LocalPlayer and player:GetAttribute("IntroPlaying"))
		local moving = hum and hum.MoveDirection.Magnitude > 0.1
		local n = #r
		for i, p in ipairs(r) do
			if not visible then
				p.model.Parent = nil
				p.cf = nil
			else
				if p.model.Parent ~= folder then p.model.Parent = folder end
				local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
				local right = Vector3.new(-look.Z, 0, look.X)
				local side = (i - (n + 1) / 2) * SPACING
				local target = hrp.Position - look * (BEHIND + math.abs(side) * 0.3) + right * side
				-- stand on the ground
				params.FilterDescendantsInstances = {char, folder}
				local hit = workspace:Raycast(target + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), params)
				local groundY = hit and hit.Position.Y or (hrp.Position.Y - 3)
				local hop = moving and math.abs(math.sin(t * 9 + i)) * 0.9 or math.sin(t * 2 + i) * 0.15
				local pos = Vector3.new(target.X, groundY + p.half + hop, target.Z)
				local goal = CFrame.lookAt(pos, pos + look)
				p.cf = p.cf and p.cf:Lerp(goal, 1 - math.exp(-dt * 10)) or goal
				p.model:PivotTo(p.cf)
			end
		end
	end
end)
