-- TrailerText (2026-10-06, Claude): the director's 2D layer (DESIGN rev 2, section 9): SafeFrame (centred 16:9, 98% of the largest
-- fit, shrunk in 0.005 steps until it clears the Roblox menu button), four black letterbox frames, the magenta slate, full-screen
-- black, the small grey READY CHECK label and the text cards. TextScaled caps at 100 px, so every line is TextSize 100 scaled by a
-- UIScale (font size x SafeFrame height / 100, fitted to 0.9 of the SafeFrame width); pops multiply that scale.
-- No side effects at require time; Mount() builds the frames inside the director's ScreenGui.
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

local Text = {}
Text.__index = Text

local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)

local function frame(name, parent, color, z)
	local f = Instance.new("Frame")
	f.Name = name
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color or BLACK
	f.BackgroundTransparency = 0
	f.ZIndex = z or 1
	f.Visible = false
	f.Parent = parent
	return f
end

-- unscaled bounds of a 100 px line
local function bounds(text, font)
	local ok, v = pcall(function()
		local p = Instance.new("GetTextBoundsParams")
		p.Text = text
		p.Font = Font.fromEnum(font)
		p.Size = 100
		p.Width = 100000
		return TextService:GetTextBoundsAsync(p)
	end)
	if ok and typeof(v) == "Vector2" and v.X > 0 then return v end
	local ok2, v2 = pcall(function() return TextService:GetTextSize(text, 100, font, Vector2.new(100000, 1000)) end)
	if ok2 and typeof(v2) == "Vector2" and v2.X > 0 then return v2 end
	return Vector2.new(#text * 58, 120)
end

function Text.Mount(gui, Shots, Math)
	local self = setmetatable({gui = gui, Shots = Shots, Math = Math, cfg = Shots.Config.Text, lines = {}, conns = {}, rect = nil}, Text)
	local old = gui:FindFirstChild("TrailerRoot")
	if old then old:Destroy() end
	local root = Instance.new("Frame")
	root.Name = "TrailerRoot"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ZIndex = 1
	root.Parent = gui
	self.root = root
	self.safe = Instance.new("Frame")
	self.safe.Name = "SafeFrame"
	self.safe.BackgroundTransparency = 1
	self.safe.BorderSizePixel = 0
	self.safe.ZIndex = 30
	self.safe.Parent = root
	self.black = frame("Black", root, BLACK, 40)
	self.black.Size = UDim2.fromScale(1, 1)
	self.slate = frame("Slate", root, self.cfg.Magenta, 45)
	self.box = {}
	for _, n in ipairs({"Top", "Bottom", "Left", "Right"}) do self.box[n] = frame("Letterbox" .. n, root, BLACK, 50) end
	local ready = Instance.new("TextLabel")
	ready.Name = "ReadyCheck"
	ready.BackgroundTransparency = 1
	ready.Font = Enum.Font.GothamMedium
	ready.TextScaled = true
	ready.TextColor3 = Color3.fromRGB(150, 150, 150)
	ready.Text = "READY CHECK"
	ready.AnchorPoint = Vector2.new(0.5, 1)
	ready.ZIndex = 46
	ready.Visible = false
	ready.Parent = root
	self.ready = ready

	for _, card in ipairs(Shots.Cards) do
		local okFont, font = pcall(function() return Enum.Font[card.font] end)
		if not okFont or not font then font = Enum.Font.FredokaOne end
		for i, ln in ipairs(card.lines) do
			local holder = Instance.new("Frame")
			holder.Name = card.id .. "_" .. i
			holder.BackgroundTransparency = 1
			holder.BorderSizePixel = 0
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Position = UDim2.fromScale(0.5, ln.cy)
			holder.ZIndex = 31
			holder.Visible = false
			holder.Parent = self.safe
			local b = bounds(ln.text, font)
			holder.Size = UDim2.fromOffset(math.ceil(b.X) + 24, math.ceil(b.Y) + 12)
			local lbl = Instance.new("TextLabel")
			lbl.Name = "Line"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.TextScaled = false
			lbl.TextSize = 100
			lbl.Font = font
			lbl.Text = ln.text
			lbl.TextColor3 = WHITE
			lbl.ZIndex = 32
			lbl.Parent = holder
			local st = Instance.new("UIStroke")
			st.Color = self.cfg.Navy
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
			if not pcall(function() st.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize; st.Thickness = 0.06 end) then st.Thickness = 6 end
			st.Parent = lbl
			local sc = Instance.new("UIScale")
			sc.Parent = holder
			table.insert(self.lines, {card = card, ln = ln, holder = holder, label = lbl, stroke = st, scale = sc, b = b, base = 1,
				tIn = ln.tIn or card.tIn, tOut = card.tOut})
		end
	end
	table.insert(self.conns, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:Layout() end))
	self:Layout()
	return self
end

-- reserved top-left rect of the Roblox menu button
function Text:MenuRect()
	local ok, r = pcall(function() return GuiService.TopbarInset end)
	if ok and typeof(r) == "Rect" and r.Min.X > 0 and r.Max.Y > 0 then return Vector2.new(r.Min.X, r.Max.Y) end
	return self.cfg.MenuFallback
end

function Text:Layout()
	local abs = self.gui.AbsoluteSize
	local W, H = abs.X, abs.Y
	if W < 16 or H < 16 then return end
	local fit = math.min(W, H * 16 / 9)
	local menu = self:MenuRect()
	local share = self.cfg.SafeShare
	local sw, sh, x0, y0
	while true do
		sw = math.floor(share * fit + 0.5)
		sw -= sw % 16 -- whole 16:9 pixel steps, so the crop is exactly 16:9
		sh = sw * 9 / 16
		x0 = math.floor((W - sw) / 2)
		y0 = math.floor((H - sh) / 2)
		if x0 >= menu.X or y0 >= menu.Y or share <= self.cfg.MinShare then break end
		share -= self.cfg.ShareStep
	end
	self.rect = {x = x0, y = y0, w = sw, h = sh, W = W, H = H, share = share}
	self.safe.Position = UDim2.fromOffset(x0, y0)
	self.safe.Size = UDim2.fromOffset(sw, sh)
	self.slate.Position = UDim2.fromOffset(x0, y0)
	self.slate.Size = UDim2.fromOffset(sw, sh)
	self.box.Top.Position, self.box.Top.Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(W, y0)
	self.box.Bottom.Position, self.box.Bottom.Size = UDim2.fromOffset(0, y0 + sh), UDim2.fromOffset(W, H - y0 - sh)
	self.box.Left.Position, self.box.Left.Size = UDim2.fromOffset(0, y0), UDim2.fromOffset(x0, sh)
	self.box.Right.Position, self.box.Right.Size = UDim2.fromOffset(x0 + sw, y0), UDim2.fromOffset(W - x0 - sw, sh)
	self.ready.Position = UDim2.fromOffset(x0 + sw / 2, y0 + sh - sh * 0.02)
	self.ready.Size = UDim2.fromOffset(sw * 0.3, sh * 0.035)
	for _, L in ipairs(self.lines) do
		local s = L.card.size * sh / 100
		s = math.min(s, self.cfg.WidthFit * sw / (L.b.X + 24))
		L.base = s
	end
end

function Text:SetLetterbox(on) for _, f in pairs(self.box) do f.Visible = on end end
function Text:SetBlack(on) self.black.Visible = on end
function Text:SetSlate(on) self.slate.Visible = on end
function Text:SetReady(on) self.ready.Visible = on end

-- vertical FOV for the real camera so a key's FOV is the FOV of the 16:9 crop
function Text:CorrectFov(fov)
	local r = self.rect
	if not r or r.h <= 0 then return fov end
	local v = 2 * math.deg(math.atan(math.tan(math.rad(fov) / 2) * r.H / r.h))
	return math.clamp(v, 1, 120)
end

-- viewport Y (pixels) -> fraction of the SafeFrame height
function Text:SafeY(vy)
	local r = self.rect
	if not r or r.h <= 0 then return nil end
	return (vy - r.y) / r.h
end

function Text:HideCards()
	for _, L in ipairs(self.lines) do L.holder.Visible = false end
end

-- tau: trailer time (nil hides every card)
function Text:Update(tau)
	local Math = self.Math
	for _, L in ipairs(self.lines) do
		local show, alpha, pop = false, 1, 1
		if tau and tau >= L.tIn and tau < L.tOut then
			show = true
			local e = tau - L.tIn
			local kind = L.card.kind
			if kind == "callout" then
				if e < 0.15 then pop = 1.25 + (1 - 1.25) * Math.ease("BackOut", e / 0.15) end
				alpha = math.min(1, e / 0.1)
				if tau > L.tOut - 0.15 then alpha *= math.max(0, (L.tOut - tau) / 0.15) end
			elseif kind == "cardA" then
				if e < 0.35 then
					pop = 1.35 + (1 - 1.35) * Math.ease("BackOut", e / 0.35)
				else
					pop = 1 + 0.02 * (1 - math.cos(2 * math.pi * (e - 0.35) / 0.8))
				end
			else -- tagline
				if e < 0.2 then pop = 0.9 + 0.1 * Math.ease("OutCubic", e / 0.2) end
				alpha = math.min(1, e / 0.2)
			end
		end
		L.holder.Visible = show
		if show then
			-- review fix: a pop never grows a line past the SafeFrame width (PLAY NOW! is width-limited, its 1.35 pop clipped)
			if self.rect and L.base > 0 then pop = math.min(pop, self.rect.w / ((L.b.X + 24) * L.base)) end
			L.scale.Scale = L.base * pop
			L.label.TextTransparency = 1 - alpha
			L.stroke.Transparency = 1 - alpha
		end
	end
end

-- logged once per run (rehearse round 2: PLAY NOW! cap height >= 200 px in the 1080p output)
function Text:CapReport()
	local r = self.rect
	local out = {}
	if not r then return out end
	for _, L in ipairs(self.lines) do
		if L.card.capLog then
			local fontPx = 100 * L.base * 1080 / r.h
			table.insert(out, string.format("%s font=%.0fpx cap~%.0fpx box=%.0fx%.0fpx (output 1080p) safe=%dx%d at %d,%d",
				L.ln.text, fontPx, fontPx * 0.72, (L.b.X + 24) * L.base * 1920 / r.w, (L.b.Y + 12) * L.base * 1080 / r.h, r.w, r.h, r.x, r.y))
		end
	end
	return out
end

function Text:HideAll()
	self:HideCards()
	self:SetBlack(false)
	self:SetSlate(false)
	self:SetReady(false)
	self:SetLetterbox(false)
end

function Text:Destroy()
	for _, c in ipairs(self.conns) do c:Disconnect() end
	self.conns = {}
	if self.root then self.root:Destroy() end
end

return Text
