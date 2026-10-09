-- UILayout (2026-10-08, Claude): shared layout constants and tiny read-only helpers for the code-built screens.
-- Pure helpers: no requires, no yields, nothing is created or connected here. Every lookup is nil-safe
-- (FindFirstChild), so a screen that has not been built yet simply counts as "closed".
-- The static RNGGui rects (SnowCounter, LeftMenu, RightMenu, BottomBar / UPGRADES, SettingsCorner) are not in the repo:
-- never place anything on them; read them live only.
--
-- openMenu keys, in the order they are tested (pass a set such as {HelpMenu = true} as `ignore` to skip some):
--   Panels       any visible child of PlayerGui.RNGGui.Panels (Shop / Pets / Rewards / Travel / Settings ...)
--   UpgradeTree  PlayerGui.UpgradeTreeGui.Enabled (the UPGRADES screen)
--   GarageWindow PlayerGui.PlowShopGui.GarageWindow
--   OfferCard    PlayerGui.PlowShopGui.OfferCard
--   Inspect      PlayerGui.GarageInspectGui.Inspect
--   EggScreen    PlayerGui.VerityEggGui.EggScreen
--   MiniPlow     PlayerGui.MiniPlowGui.MiniPlowPanel
--   HelpMenu     PlayerGui.PlowTutorial.HelpMenu
local UserInputService = game:GetService("UserInputService")

local UILayout = {}

UILayout.MIN_TOUCH = 44       -- smallest comfortable touch target (px)
UILayout.MIN_TOUCH_DENSE = 40 -- smallest touch target where a row is dense (HELP / AFK pills, short phones)
UILayout.GAP = 8              -- gap between neighbouring controls
UILayout.MARGIN = 16          -- keep-clear distance from the screen edge for stacked HUD
UILayout.MIN_TEXT = 12        -- smallest text size
UILayout.MIN_TEXT_DENSE = 11  -- smallest text size in dense rows
UILayout.COL_EDGE = 8         -- touch action column: distance from the right edge
UILayout.COL_BTN_H = 44       -- touch action column: height of one button
UILayout.COL_GAP = 6          -- touch action column: gap between buttons
UILayout.COL_H = 144          -- touch action column: full height (3 buttons + 2 gaps)

-- viewport of the current camera; a safe default before the camera exists
local function viewport()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize
	if vp and vp.X > 0 and vp.Y > 0 then return vp end
	return Vector2.new(1920, 1080)
end

-- true when `obj` and every ancestor up to (not including) the PlayerGui is actually shown
local function shown(obj, pg)
	local o = obj
	while o and o ~= pg do
		if o:IsA("GuiObject") and not o.Visible then return false end
		if o:IsA("ScreenGui") and not o.Enabled then return false end
		o = o.Parent
	end
	return true
end

-- single-frame menus tested by openMenu after Panels / UpgradeTree: {key, ScreenGui name, frame name}
local WINDOWS = {
	{"GarageWindow", "PlowShopGui", "GarageWindow"},
	{"OfferCard", "PlowShopGui", "OfferCard"},
	{"Inspect", "GarageInspectGui", "Inspect"},
	{"EggScreen", "VerityEggGui", "EggScreen"},
	{"MiniPlow", "MiniPlowGui", "MiniPlowPanel"},
	{"HelpMenu", "PlowTutorial", "HelpMenu"},
}

-- phone / tablet without a keyboard
function UILayout.isTouch()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- small screen: phone landscape or a short window. vp = Vector2 viewport (defaults to the camera's).
function UILayout.isSmall(vp)
	vp = vp or viewport()
	return vp.X < 1000 or vp.Y < 560
end

-- width of the touch action column (DRIFT / DRIVE or EXIT / RECOVER) for a screen width W
function UILayout.touchColW(W)
	return math.max(130, math.floor(0.17 * W))
end

-- left edge of the touch action column for a screen width W; nothing else may use x >= this value on touch
function UILayout.touchColLeft(W)
	return W - UILayout.COL_EDGE - UILayout.touchColW(W)
end

-- position (relative to `gui`'s top-left) and size of `obj`: AbsolutePosition is screen space, but a ScreenGui's own
-- origin can differ (top-bar / safe-area insets). Returns Vector2 pos, Vector2 size.
function UILayout.rectIn(obj, gui)
	if not obj then return Vector2.zero, Vector2.zero end
	local origin = gui and gui.AbsolutePosition or Vector2.zero
	return obj.AbsolutePosition - origin, obj.AbsoluteSize
end

-- left, top of the Roblox jump button in `gui` space. Reads PlayerGui.TouchGui's JumpButton when it is showing;
-- otherwise the Roblox defaults: min(W, H) <= 500 -> (W-115, H-90), else (W-190, H-210).
function UILayout.jumpLeftTop(pg, gui)
	local touchGui = pg and pg:FindFirstChild("TouchGui")
	local jump = touchGui and touchGui:FindFirstChild("JumpButton", true)
	if jump and jump:IsA("GuiObject") and jump.Visible and jump.AbsoluteSize.X > 0
		and not (touchGui:IsA("ScreenGui") and not touchGui.Enabled) then
		local pos = UILayout.rectIn(jump, gui)
		return pos.X, pos.Y
	end
	local size = gui and gui.AbsoluteSize
	if not (size and size.X > 0 and size.Y > 0) then size = viewport() end
	local W, H = size.X, size.Y
	if math.min(W, H) <= 500 then return W - 115, H - 90 end
	return W - 190, H - 210
end

-- name of the first open menu, or nil. `ignore` = optional set of keys (see the header) that are not tested.
-- State-based (reads Visible / Enabled), so it is safe to call every frame.
function UILayout.openMenu(pg, ignore)
	if not pg then return nil end
	ignore = ignore or {}
	if not ignore.Panels then
		local rng = pg:FindFirstChild("RNGGui")
		local panels = rng and rng:FindFirstChild("Panels")
		if panels then
			for _, p in ipairs(panels:GetChildren()) do
				if p:IsA("GuiObject") and shown(p, pg) then return "Panels" end
			end
		end
	end
	if not ignore.UpgradeTree then
		local tree = pg:FindFirstChild("UpgradeTreeGui")
		if tree and tree:IsA("ScreenGui") and tree.Enabled then return "UpgradeTree" end
	end
	for _, w in ipairs(WINDOWS) do
		if not ignore[w[1]] then
			local gui = pg:FindFirstChild(w[2])
			local obj = gui and gui:FindFirstChild(w[3])
			if obj and obj:IsA("GuiObject") and shown(obj, pg) then return w[1] end
		end
	end
	return nil
end

return UILayout
