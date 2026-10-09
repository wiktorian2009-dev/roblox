-- PopupStack (2026-10-06, Claude): wiktor - "if 3 messages on screen pop up like rebirth, snow king, and help friend one should go down
-- and the older one down". One shared column for the short top-of-screen messages: the NEWEST is on top, older ones are pushed down,
-- nothing overlaps. Each popup keeps its own look, animation and lifetime (its own script still shows / hides it); this script only
-- moves it while it is up and gives it its original position back when it goes. The popup scripts themselves are not edited.
--   * HELP REQUEST and the Frost King announcement keep their buttons clickable and are never hidden by the stack.
--   * Cap: at most MAX popups or 70% of the screen height; when it is full the OLDEST plain toast fades out first.
--   * While the tutorial card is up, the column starts below it (the tutorial's own spotlight / card are never covered).
--   * 2026-10-08 UI audit: also starts below the touch Frost King "Me" card (top-centre) while it is up; the free-spin WheelToast is stacked too.
--   * 2026-10-08 follow-up: also starts below the Frost King boss bar while it is up.
-- Not stacked (they live elsewhere on purpose): the right-edge treasure toast, the arena banner, the Frost King battle text in the
-- middle, the tutorial's own flash text and toasts inside open panels.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

local MAX, GAP, TOP, MAXH = 4, 8, 0.11, 0.7
-- {ScreenGui name, child path (nil = first TextLabel child), sticky (has buttons, never auto-hidden)}
local WATCH = {
	{"ContractGui", "Announce", true},       -- HELP REQUEST (HELP OUT / LATER)
	{"FrostKingGui", "Announce", true},      -- THE FROST KING HAS APPEARED! (JOIN / LATER)
	{"ContractGui", "Toast"},
	{"RNGGui", "ActivityToast"},             -- rewards / quests / achievements / events
	{"RNGGui", "WheelToast"},                -- free spin earned (WheelClient label; faded-out label = hidden)
	{"RNGGui", "Toast"},                     -- eggs: not enough Snow
	{"PlowShopGui", "Toast"},                -- garage offers, offer ran out
	{"TreasureToastGui", "Announce"},        -- mythic treasure nearby
	{"FrostfallToast"}, {"World2Toast"}, {"StageToast"},
}

local entries = {} -- [GuiObject] = {orig = UDim2, since = time, sticky = bool}
local function find(w)
	local g = pg:FindFirstChild(w[1])
	if not g then return nil end
	if w[2] then return g:FindFirstChild(w[2]) end
	return g:FindFirstChildWhichIsA("TextLabel")
end
local function scaleOf(o)
	local s = o:FindFirstChildOfClass("UIScale")
	return s and math.max(s.Scale, 0.05) or 1
end
local function enabledChain(o)
	local c = o
	while c and not c:IsA("LayerCollector") do
		if c:IsA("GuiObject") and not c.Visible then return false end
		c = c.Parent
	end
	return c ~= nil and c.Enabled
end
local function shown(o)
	if not enabledChain(o) then return false end
	if o:IsA("TextLabel") and o.BackgroundTransparency >= 0.99 and o.TextTransparency >= 0.9 then return false end -- faded-out label
	return o.AbsoluteSize.Y > 2
end
local function fadeOut(o)
	if o:IsA("TextLabel") and o.BackgroundTransparency >= 0.99 then
		TweenService:Create(o, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		local st = o:FindFirstChildOfClass("UIStroke")
		if st then TweenService:Create(st, TweenInfo.new(0.3), {Transparency = 1}):Play() end
	else
		o.Visible = false
	end
end

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local insetY = GuiService:GetGuiInset().Y
	-- gather what is up right now
	local list = {}
	for _, w in ipairs(WATCH) do
		local o = find(w)
		if o and o:IsA("GuiObject") then
			local e = entries[o]
			if shown(o) then
				if not e then e = {orig = o.Position, since = os.clock(), sticky = w[3] == true}; entries[o] = e end
				table.insert(list, o)
			elseif e then
				o.Position = e.orig; entries[o] = nil
			end
		end
	end
	if #list == 0 then return end
	table.sort(list, function(a, b) return entries[a].since > entries[b].since end) -- newest first
	-- the column starts at TOP of the screen, or below the tutorial card while it is up (AbsolutePosition: inset-relative coordinates)
	local y = vp.Y * TOP - insetY
	local tut = pg:FindFirstChild("PlowTutorial")
	local card = tut and tut:FindFirstChild("Card")
	if card and card.Visible and card.AbsolutePosition.Y < vp.Y * 0.4 then y = math.max(y, card.AbsolutePosition.Y + card.AbsoluteSize.Y + 18) end
	-- touch Frost King "Me" HP card (top-centre, under the boss bar): the column starts below it. Desktop "Me" is bottom-right, so no effect there.
	local fk = pg:FindFirstChild("FrostKingGui")
	local me = fk and fk:FindFirstChild("Me")
	if me and me:IsA("GuiObject") and enabledChain(me) and me.AbsolutePosition.Y < vp.Y * 0.5 then
		y = math.max(y, me.AbsolutePosition.Y + me.AbsoluteSize.Y + 8)
	end
	-- Frost King boss bar (top-centre, >= 56 px high on touch): the column starts below it while it is up
	local bossBar = fk and fk:FindFirstChild("BossBar")
	if bossBar and bossBar:IsA("GuiObject") and enabledChain(bossBar) and bossBar.AbsolutePosition.Y < vp.Y * 0.3 then
		y = math.max(y, bossBar.AbsolutePosition.Y + bossBar.AbsoluteSize.Y + 8)
	end
	local limit = vp.Y * MAXH - insetY
	local n = 0
	for _, o in ipairs(list) do
		local e = entries[o]
		local h = o.AbsoluteSize.Y / scaleOf(o) -- the popup's own pop-in scale doesn't shake the column
		n += 1
		if (n > MAX or y + h > limit) and not e.sticky then
			fadeOut(o); o.Position = e.orig; entries[o] = nil
		else
			local parentY = o.Parent:IsA("GuiObject") and o.Parent.AbsolutePosition.Y or (o.Parent:IsA("LayerCollector") and o.Parent.AbsolutePosition.Y or 0)
			o.Position = UDim2.new(e.orig.X.Scale, e.orig.X.Offset, 0, y - parentY + o.AnchorPoint.Y * h)
			y += h + GAP
		end
	end
end)
