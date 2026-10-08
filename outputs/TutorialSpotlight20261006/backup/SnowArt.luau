-- SnowArt (2026-10-06, Claude): image-based snowy cartoon GUI art (buttons, panels, tabs, close button, icons) for the script-built
-- screens. Art is rendered PNGs (outputs/UIArt20261006: ui_art.py -> png/, uploaded as decals; IMAGE_PROMPTS.md describes each piece
-- so an image AI can replace it later - swap the ids below and keep the slice rects). Visuals only: scripts still own state and input.
--   SnowArt.SkinButton(btn [, color])  -> 9-slice button art behind the label (colour follows btn.BackgroundColor3 unless given)
--   SnowArt.SkinPanel(frame [, "dark"|"light"]) -> 9-slice snowy window art
--   SnowArt.Icon(parent, name, props)  -> ImageLabel with an icon (star, shield, flame, pin, house, garage, wrench, reroll, coin, brush, leave, help, wheel)
local A = {}
A.Images = {
	btn_green = "rbxassetid://94892815637081", btn_blue = "rbxassetid://112618455083901", btn_orange = "rbxassetid://94232937682078",
	btn_red = "rbxassetid://99558074245417", btn_grey = "rbxassetid://75472726775409", btn_gold = "rbxassetid://70390012429355",
	btn_purple = "rbxassetid://71835108700364",
	tab_on = "rbxassetid://73047967766895", tab_off = "rbxassetid://113947108636589",
	panel = "rbxassetid://81373680073984", panel_dark = "rbxassetid://100340980893081", close = "rbxassetid://85270495579334",
	icon_star = "rbxassetid://86854252432001", icon_shield = "rbxassetid://82444243436979", icon_flame = "rbxassetid://115306732012649",
	icon_pin = "rbxassetid://80789072145484", icon_house = "rbxassetid://136098691498187", icon_garage = "rbxassetid://130551373703418",
	icon_wrench = "rbxassetid://126491591611874", icon_reroll = "rbxassetid://133745249066902", icon_coin = "rbxassetid://112674393150144",
	icon_brush = "rbxassetid://72552424279480", icon_leave = "rbxassetid://111719374695689", icon_help = "rbxassetid://78213789412189",
	icon_wheel = "rbxassetid://126114488819426",
}
-- source sizes and 9-slice centres (pixels of the uploaded image)
local BTN = {w = 512, h = 192, slice = Rect.new(70, 70, 442, 150)}
local TAB = {w = 384, h = 160, slice = Rect.new(60, 50, 324, 120)}
local PANEL = {w = 1024, h = 1024, slice = Rect.new(160, 200, 864, 864)}
local PALETTE = {
	green = Color3.fromRGB(70, 200, 105), blue = Color3.fromRGB(70, 150, 245), orange = Color3.fromRGB(250, 150, 50),
	red = Color3.fromRGB(240, 60, 90), grey = Color3.fromRGB(130, 140, 165), gold = Color3.fromRGB(255, 200, 60), purple = Color3.fromRGB(160, 110, 255),
}
function A.Nearest(c)
	local best, bd = "blue", math.huge
	for name, p in pairs(PALETTE) do
		local d = (c.R - p.R) ^ 2 + (c.G - p.G) ^ 2 + (c.B - p.B) ^ 2
		if d < bd then best, bd = name, d end
	end
	return best
end
local function quiet(o)
	for _, c in ipairs(o:GetChildren()) do
		if c:IsA("UIStroke") and c.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then c.Enabled = false
		elseif c:IsA("UIGradient") then c.Enabled = false end
	end
end
local function skinLayer(o, name)
	local art = o:FindFirstChild(name)
	if not art then
		art = Instance.new("ImageLabel")
		art.Name = name
		art.BackgroundTransparency, art.Active, art.Selectable = 1, false, false
		art.AnchorPoint, art.Position, art.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1)
		art.ScaleType = Enum.ScaleType.Slice
		art:SetAttribute("SnowUIDecor", true)
		art.Parent = o
	end
	art.ZIndex = 0 -- below every sibling (ScreenGuis use Sibling z-order: children always draw over their parent)
	return art
end
-- keep the slice margins proportional to the widget's height (a 40 px button gets 40/192 of the source margins)
local function fit(o, art, src, k)
	local function upd()
		local h = math.max(1, o.AbsoluteSize.Y)
		art.SliceScale = math.clamp(h / src.h * (k or 1), 0.05, 2)
	end
	upd()
	o:GetPropertyChangedSignal("AbsoluteSize"):Connect(upd)
end
function A.SkinButton(btn, color, opts)
	if not btn or btn:GetAttribute("SnowArtSkinned") then return end
	btn:SetAttribute("SnowArtSkinned", true)
	local art = skinLayer(btn, "SnowArtSkin")
	local tab = opts and opts.tab
	local src = tab and TAB or BTN
	art.SliceCenter = src.slice
	local function pick()
		local name = color or A.Nearest(btn.BackgroundColor3)
		art.Image = tab and (A.Images[tab] or A.Images.tab_on) or (A.Images["btn_" .. name] or A.Images.btn_blue)
	end
	pick()
	if not color then btn:GetPropertyChangedSignal("BackgroundColor3"):Connect(pick) end
	btn.BackgroundTransparency = 1
	quiet(btn)
	fit(btn, art, src, 1.25)
	return art
end
function A.SetTab(btn, on)
	local art = btn and btn:FindFirstChild("SnowArtSkin")
	if art then art.Image = on and A.Images.tab_on or A.Images.tab_off end
end
function A.SkinPanel(frame, kind)
	if not frame or frame:GetAttribute("SnowArtSkinned") then return end
	frame:SetAttribute("SnowArtSkinned", true)
	local art = skinLayer(frame, "SnowArtPanel")
	art.Image = kind == "light" and A.Images.panel or A.Images.panel_dark
	art.SliceCenter = PANEL.slice
	-- the art's snow cap sits slightly above the frame: grow the art a little upward so the window keeps its size
	art.Size = UDim2.new(1, 8, 1, 14); art.Position = UDim2.new(0.5, 0, 0.5, -5)
	frame.BackgroundTransparency = 1
	quiet(frame)
	local function upd() art.SliceScale = math.clamp(math.min(frame.AbsoluteSize.X, frame.AbsoluteSize.Y) / PANEL.h * 0.62, 0.12, 0.8) end
	upd(); frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(upd)
	return art
end
function A.SkinClose(btn)
	if not btn or btn:GetAttribute("SnowArtSkinned") then return end
	btn:SetAttribute("SnowArtSkinned", true)
	local art = skinLayer(btn, "SnowArtSkin")
	art.ScaleType = Enum.ScaleType.Fit
	art.Image = A.Images.close
	art.Size = UDim2.fromScale(1.25, 1.25)
	btn.BackgroundTransparency = 1
	quiet(btn)
	for _, c in ipairs(btn:GetChildren()) do if c:IsA("TextLabel") then c.Visible = false end end
	if btn:IsA("TextButton") then btn.TextTransparency = 1 end
	return art
end
function A.Icon(parent, name, props)
	local img = Instance.new("ImageLabel")
	img.Name = "SnowArtIcon"
	img.BackgroundTransparency, img.Active, img.Selectable = 1, false, false
	img.ScaleType = Enum.ScaleType.Fit
	img.Image = A.Images["icon_" .. name] or ""
	img:SetAttribute("SnowUIDecor", true)
	for k, v in pairs(props or {}) do img[k] = v end
	img.ZIndex = 3
	img.Parent = parent
	return img
end
-- small helper for text buttons: icon on the left, label shifted right
function A.IconButton(btn, name)
	local label = btn:FindFirstChild("Label")
	-- square icon, as tall as the button body, on the left; the label takes the rest
	A.Icon(btn, name, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.04, 0, 0.56, 0), Size = UDim2.fromScale(0.78, 0.78), SizeConstraint = Enum.SizeConstraint.RelativeYY})
	if label then label.Position = UDim2.new(0.3, 0, label.Position.Y.Scale, 0); label.Size = UDim2.new(0.66, 0, label.Size.Y.Scale, 0) end
end
return A
