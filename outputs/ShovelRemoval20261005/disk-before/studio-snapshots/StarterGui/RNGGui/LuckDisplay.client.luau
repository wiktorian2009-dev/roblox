-- LuckDisplay: bottom-left stat icons (clover = total luck, sword = damage multiplier) + info on hover / tap.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local player = Players.LocalPlayer

local row = script.Parent:WaitForChild("StatIcons")
local luck = row:WaitForChild("Luck")
local dmg = row:WaitForChild("Damage")
local box = row:WaitForChild("Info")
local boxText = box:WaitForChild("Text")

-- phones: the movement stick lives bottom-left, so sit just under the menu instead
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	row.AnchorPoint = Vector2.new(0, 0)
	row.Position = UDim2.new(0, 16, 0.64, 0)
end

-- 1.35x / 12.4x / 777x / 1.3Kx / 25Mx
local function fmt(v)
	local t
	if v >= 1000 then t = NumberFormat.Abbreviate(v)
	elseif v >= 100 then t = tostring(math.floor(v))
	elseif v >= 10 then t = (string.format("%.1f", math.floor(v * 10) / 10):gsub("%.0$", ""))
	else t = (string.format("%.2f", math.floor(v * 100) / 100):gsub("%.?0+$", "")) end
	return t .. "x"
end

local function pop(f)
	local s = f:FindFirstChildOfClass("UIScale")
	s.Scale = 1.2
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
end

local showing = nil
local lastLuck, lastDmg
local function update()
	local total = player:GetAttribute("TotalLuck") or 1
	local power = player:GetAttribute("PowerMult") or 1
	luck.Value.Text = fmt(total)
	dmg.Value.Text = fmt(power)
	if lastLuck and total > lastLuck then pop(luck) end
	if lastDmg and power > lastDmg then pop(dmg) end
	lastLuck, lastDmg = total, power
	if showing == "Luck" then
		local friends = player:GetAttribute("FriendsHere") or 0
		local base = player:GetAttribute("LuckBase") or 1
		local rebirth = player:GetAttribute("RebirthLuckMult") or 1
		local friendMult = 1 + (player:GetAttribute("FriendBoost") or 0) * math.clamp(friends, 0, 3)
		local upgradePct = math.max(0, (player:GetAttribute("LuckMult") or 1) / (rebirth * friendMult) - 1)
		local lines = {'<font color="#8CFF96">LUCK ' .. fmt(total) .. '</font>', "Upgrades +" .. math.floor(upgradePct * 100 + 0.5) .. "%"}
		if rebirth > 1 then table.insert(lines, "Rebirths " .. fmt(rebirth)) end
		if friendMult > 1 then table.insert(lines, "Friends +" .. math.floor((friendMult - 1) * 100 + 0.5) .. "%") end
		if base ~= 1 then table.insert(lines, "Bonus " .. fmt(base)) end
		boxText.Text = table.concat(lines, "\n")
	elseif showing == "Damage" then
		boxText.Text = '<font color="#FF8C8C">DAMAGE ' .. fmt(power) .. '</font>\nFrom upgrade tiles.\nBetter shovels hit\nharder too!'
	end
end
for _, a in ipairs({"TotalLuck", "LuckMult", "LuckBase", "FriendsHere", "FriendBoost", "RebirthLuckMult", "PowerMult"}) do
	player:GetAttributeChangedSignal(a):Connect(update)
end

local function hook(f)
	local hit = f:WaitForChild("Hit")
	hit.MouseEnter:Connect(function() showing = f.Name; box.Visible = true; update() end)
	hit.MouseLeave:Connect(function() if showing == f.Name then showing = nil; box.Visible = false end end)
	hit.Activated:Connect(function()
		if showing == f.Name and box.Visible then showing = nil; box.Visible = false
		else showing = f.Name; box.Visible = true; update() end
	end)
end
hook(luck)
hook(dmg)
update()
