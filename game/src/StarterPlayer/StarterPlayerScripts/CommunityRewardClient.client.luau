-- CommunityRewardClient (2026-10-13, Claude): the FREE PET pill under the REWARDS / SPIN buttons and the small SUPPORTER GIFT card.
-- * Card: the prize (Frosty Pal + Snow + 2x Snow), step 1 "like the game" (a reminder only - Roblox can't tell a game who liked
--   it, so it never gates anything), step 2 JOIN (GroupService:PromptJoinAsync, then the server re-checks), CLAIM.
-- * The server decides everything (CommunityRewardService); this script only shows state and asks. After a claim the usual
--   hatch reveal plays (PetClient) and the pill goes away for good (attribute CommunityGiftClaimed).
-- * Hidden until the plow tutorial is done, so new players are not distracted during it.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GroupService = game:GetService("GroupService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local CFG = require(RS:WaitForChild("CommunityRewardConfig"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local PetModels = require(RS:WaitForChild("PetModels"))
local A = require(RS:WaitForChild("ActivityConfig"))
local Art = require(RS:WaitForChild("SnowArt"))
local remote = RS:WaitForChild("CommunityRewardRemote", 60)
if not remote then return end
local pg = player:WaitForChild("PlayerGui")
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)
local GOLD, ICE, GREEN, GREY, BLUE, PURPLE = Color3.fromRGB(255, 220, 90), Color3.fromRGB(190, 225, 255), Color3.fromRGB(70, 200, 105),
	Color3.fromRGB(130, 140, 165), Color3.fromRGB(70, 150, 245), Color3.fromRGB(160, 110, 255)
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
local PET = PetConfig.PetByName[CFG.Pet]
if not PET then return end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function label(parent, text, props)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = text, TextColor3 = WHITE, ZIndex = 5}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	mk("UIStroke", {Thickness = 2, Color = NAVY}, l)
	return l
end
local function button(parent, text, color, props)
	local b = mk("TextButton", {Text = "", AutoButtonColor = true, BackgroundColor3 = color, Selectable = true, ZIndex = 5}, parent)
	for k, v in pairs(props or {}) do b[k] = v end
	mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, b)
	local l = label(b, text, {Name = "Label", Size = UDim2.fromScale(0.86, 0.66), Position = UDim2.fromScale(0.07, 0.17), ZIndex = 6})
	Art.SkinButton(b)
	return b, l
end
local spinners = {}
local function petView(parent, props)
	local vp = mk("ViewportFrame", {BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 215), LightColor = WHITE, LightDirection = Vector3.new(-0.4, -1, -0.6), ZIndex = 5}, parent)
	for k, v in pairs(props or {}) do vp[k] = v end
	local model = PetModels.create(PET.Name)
	model:PivotTo(CFrame.new())
	model.Parent = vp
	local _, size = model:GetBoundingBox()
	local cam = mk("Camera", {FieldOfView = 34}, vp)
	cam.CFrame = CFrame.lookAt(Vector3.new(0, size.Y * 0.15, -math.max(size.X, size.Y, size.Z) * 1.6), Vector3.new())
	vp.CurrentCamera = cam
	table.insert(spinners, {vp = vp, model = model})
	return vp
end

--------------------------------------------------
-- pill (below the REWARDS / SPIN buttons on the right)
--------------------------------------------------
local hud = mk("ScreenGui", {Name = "CommunityGiftHud", ResetOnSpawn = false, DisplayOrder = 99, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, pg)
local pill = button(hud, CFG.PillText, PURPLE, {Name = "GiftPill", AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(150, 46)})
pill.Label.Position, pill.Label.Size = UDim2.fromScale(0.33, 0.16), UDim2.fromScale(0.62, 0.68)
petView(pill, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(-0.08, 0.42), Size = UDim2.fromScale(1.3, 1.3), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 7})
local dot = label(pill, "!", {Name = "Dot", BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(240, 60, 90), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.97, 0.1), Size = UDim2.fromScale(0.42, 0.42), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 8})
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
local pillScale = mk("UIScale", {}, pill)
TweenService:Create(pillScale, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.06}):Play()

local function placePill()
	local rnggui = pg:FindFirstChild("RNGGui")
	local rm = rnggui and rnggui:FindFirstChild("RightMenu")
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local h = math.clamp(math.floor(vp.Y * 0.05), 44, 58)
	pill.Size = UDim2.fromOffset(math.floor(h * 3.3), h)
	if rm and rm.AbsoluteSize.Y > 0 then
		-- AbsolutePosition is measured below the top bar; this ScreenGui ignores the inset, so add it back
		local inset = game:GetService("GuiService"):GetGuiInset().Y
		-- under the lowest thing in the right menu (the SPIN button's label hangs below its cell)
		local bottom = rm.AbsolutePosition.Y + rm.AbsoluteSize.Y
		for _, d in ipairs(rm:GetDescendants()) do
			if d:IsA("GuiObject") and d.Visible and d.AbsoluteSize.Y > 0 then bottom = math.max(bottom, d.AbsolutePosition.Y + d.AbsoluteSize.Y) end
		end
		pill.Position = UDim2.fromOffset(rm.AbsolutePosition.X + rm.AbsoluteSize.X, bottom + inset + math.floor(h * 0.3))
	else
		pill.Position = UDim2.new(0.988, 0, 0.66, 0)
	end
end

--------------------------------------------------
-- card
--------------------------------------------------
local sg = mk("ScreenGui", {Name = "CommunityGiftGui", ResetOnSpawn = false, DisplayOrder = 103, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)
local card = mk("Frame", {Name = "GiftCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.44, 0.56),
	BackgroundColor3 = Color3.fromRGB(40, 80, 160), Visible = false, Active = true, ZIndex = 2}, sg)
mk("UICorner", {CornerRadius = UDim.new(0.05, 0)}, card)
mk("UISizeConstraint", {MinSize = Vector2.new(330, 300), MaxSize = Vector2.new(720, 520)}, card)
Art.SkinPanel(card, "dark")
label(card, CFG.Title, {Position = UDim2.fromScale(0.05, 0.05), Size = UDim2.fromScale(0.72, 0.1), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD})
local close = mk("TextButton", {Name = "Close", Text = "X", BackgroundColor3 = Color3.fromRGB(235, 80, 90), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.97, 0.03),
	Size = UDim2.fromScale(0.1, 0.12), SizeConstraint = Enum.SizeConstraint.RelativeYY, Selectable = true, ZIndex = 6}, card)
Art.SkinClose(close)
mk("UISizeConstraint", {MinSize = touch and Vector2.new(44, 44) or Vector2.zero}, close)

-- prize: the pet on the left, the list on the right
local rarityCol = PetConfig.Rarities and PetConfig.Rarities[PET.Rarity] or GOLD
local petBox = mk("Frame", {BackgroundColor3 = rarityCol:Lerp(NAVY, 0.55), BackgroundTransparency = 0.15, Position = UDim2.fromScale(0.05, 0.17), Size = UDim2.fromScale(0.3, 0.38), ZIndex = 3}, card)
mk("UICorner", {CornerRadius = UDim.new(0.1, 0)}, petBox)
mk("UIStroke", {Thickness = 2.5, Color = rarityCol}, petBox)
petView(petBox, {Position = UDim2.fromScale(0.05, 0.02), Size = UDim2.fromScale(0.9, 0.72)})
label(petBox, PET.Name, {Position = UDim2.fromScale(0.05, 0.72), Size = UDim2.fromScale(0.9, 0.15), TextColor3 = rarityCol})
label(petBox, "EXCLUSIVE", {Position = UDim2.fromScale(0.15, 0.86), Size = UDim2.fromScale(0.7, 0.1), TextColor3 = ICE})
local boost = A.Boosts[CFG.Boost]
local lines = {
	"\u{1F43E} " .. PET.Name .. " - only from this gift",
	"\u{2744}\u{FE0F} A big pile of Snow",
	boost and ("\u{26A1} " .. boost.Name .. " for " .. math.floor(CFG.BoostSeconds / 60) .. " minutes") or nil,
}
for i, t in ipairs(lines) do
	local l = label(card, t, {Position = UDim2.fromScale(0.39, 0.19 + (i - 1) * 0.13), Size = UDim2.fromScale(0.57, 0.1), TextXAlignment = Enum.TextXAlignment.Left})
	mk("UITextSizeConstraint", {MaxTextSize = 30}, l) -- the three lines keep one size instead of each filling its own box
end

-- steps
local function stepRow(y, num, title, sub, wide)
	local row = mk("Frame", {Name = "Step" .. num, BackgroundColor3 = NAVY, BackgroundTransparency = 0.35, Position = UDim2.fromScale(0.05, y), Size = UDim2.fromScale(0.9, 0.12), ZIndex = 3}, card)
	mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, row)
	label(row, num, {Position = UDim2.fromScale(0.015, 0.12), Size = UDim2.fromScale(0.07, 0.76), TextColor3 = GOLD})
	label(row, title, {Position = UDim2.fromScale(0.1, 0.06), Size = UDim2.fromScale(0.55, 0.5), TextXAlignment = Enum.TextXAlignment.Left})
	label(row, sub, {Position = UDim2.fromScale(0.1, 0.56), Size = UDim2.fromScale(wide and 0.86 or 0.6, 0.38), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ICE})
	return row
end
stepRow(0.625, "1", "Like the game \u{1F44D}", CFG.LikeText, true)
local joinRow = stepRow(0.765, "2", CFG.JoinText, "Get group news and updates")
local joinBtn = button(joinRow, "JOIN", BLUE, {Name = "Join", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.985, 0.5), Size = UDim2.fromScale(0.25, 0.8)})
local claimBtn, claimLabel = button(card, "CLAIM", GREY, {Name = "Claim", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.905), Size = UDim2.fromScale(0.36, 0.1)})
mk("UISizeConstraint", {MinSize = touch and Vector2.new(0, 44) or Vector2.zero}, claimBtn)
local msg = label(card, "", {Name = "Message", Position = UDim2.fromScale(0.05, 0.565), Size = UDim2.fromScale(0.9, 0.0), TextColor3 = GOLD})

--------------------------------------------------
-- state
--------------------------------------------------
local member, claimed, busy = false, player:GetAttribute("CommunityGiftClaimed") == true, false
local function setMsg(t, col)
	msg.Text, msg.TextColor3 = t or "", col or GOLD
	msg.Size = UDim2.fromScale(0.9, (t and t ~= "") and 0.05 or 0)
end
local function render()
	joinBtn.Label.Text = member and "JOINED \u{2713}" or "JOIN"
	joinBtn.BackgroundColor3 = member and GREEN or BLUE
	claimBtn.BackgroundColor3 = member and GREEN or GREY
	claimLabel.Text = member and "CLAIM!" or "JOIN FIRST"
end
local function apply(res)
	if type(res) ~= "table" or not res.ok then return end
	member = res.member == true
	if res.claimed then claimed = true end
	render()
end
local function refreshHud()
	local show = not claimed and RS:GetAttribute("CommunityGroupId") ~= nil and player:GetAttribute("PlowTutorialDone") == true
		and player:GetAttribute("IntroActive") ~= true
	hud.Enabled = show
	if show then placePill() end
	if claimed then card.Visible = false end
end

local function open()
	card.Visible = true
	setMsg("")
	render()
	task.spawn(function() apply(remote:InvokeServer("Check")) end)
end
local function shut() card.Visible = false end
pill.Activated:Connect(function() if card.Visible then shut() else open() end end)
close.Activated:Connect(shut)

joinBtn.Activated:Connect(function()
	if busy then return end
	if member then return end
	busy = true
	local gid = RS:GetAttribute("CommunityGroupId")
	local ok = gid and pcall(function() GroupService:PromptJoinAsync(gid) end)
	if not ok then setMsg("Open the game page and tap the group name to join!", ICE) end
	task.wait(0.5)
	apply(remote:InvokeServer("Check"))
	if member then setMsg("Thanks for joining! Tap CLAIM \u{1F381}", GREEN) end
	busy = false
end)
claimBtn.Activated:Connect(function()
	if busy then return end
	busy = true
	if not member then apply(remote:InvokeServer("Check")) end
	if not member then
		setMsg("Join the group first, then tap CLAIM!", GOLD)
	else
		claimLabel.Text = "..."
		local res = remote:InvokeServer("Claim")
		if type(res) == "table" and res.ok then
			claimed = true
			shut()
			refreshHud()
		else
			setMsg(type(res) == "table" and res.msg or "Try again in a moment.", GOLD)
			if type(res) == "table" and res.claimed then claimed = true; refreshHud() end
			render()
		end
	end
	busy = false
end)

player:GetAttributeChangedSignal("CommunityGiftClaimed"):Connect(function()
	if player:GetAttribute("CommunityGiftClaimed") == true then claimed = true end
	refreshHud()
end)
player:GetAttributeChangedSignal("PlowTutorialDone"):Connect(refreshHud)
player:GetAttributeChangedSignal("IntroActive"):Connect(refreshHud)
RS:GetAttributeChangedSignal("CommunityGroupId"):Connect(refreshHud)
task.spawn(function()
	local cam = workspace.CurrentCamera
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() if hud.Enabled then placePill() end end) end
	local rnggui = pg:WaitForChild("RNGGui", 30)
	local rm = rnggui and rnggui:WaitForChild("RightMenu", 30)
	if rm then
		rm:GetPropertyChangedSignal("AbsolutePosition"):Connect(function() if hud.Enabled then placePill() end end)
		rm:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if hud.Enabled then placePill() end end)
	end
	refreshHud()
end)
task.spawn(function() apply(remote:InvokeServer("State")); refreshHud() end)

-- slow spin for the pet previews that are on screen
RunService.RenderStepped:Connect(function(dt)
	for _, s in ipairs(spinners) do
		local gui = s.vp:FindFirstAncestorOfClass("ScreenGui")
		if gui and gui.Enabled and s.vp.Visible and (s.vp:IsDescendantOf(hud) or card.Visible) then s.model:PivotTo(s.model:GetPivot() * CFrame.Angles(0, dt * 0.9, 0)) end
	end
end)
