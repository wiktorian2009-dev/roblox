-- Snowy art skin. Visuals only; the existing scripts still own state and actions.
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local M = {}
M.Assets = {
	panel = "rbxassetid://73131475669125", card = "rbxassetid://108488334852650", button = "rbxassetid://100281398843170", hex = "rbxassetid://92134257087385",
	damage = "rbxassetid://78096846367053", rewards = "rbxassetid://77298391197868", achievement = "rbxassetid://89448212190860", loading = "rbxassetid://114230466916343",
	snow = "rbxassetid://83244601927288", luck = "rbxassetid://74613534440214",
	quests = "rbxassetid://104333252369153", codes = "rbxassetid://116424506095790",
}
-- Roblox's uploaded texture is 1024px; source PNGs are preserved at 1254px.
M.Slice = Rect.new(237, 237, 787, 787)
local loaded, waiting = {}, {}
local bound = setmetatable({}, {__mode="k"})
local function whenReady(id, fn)
	if not RunService:IsRunning() or loaded[id] == true or ContentProvider:GetAssetFetchStatus(id)==Enum.AssetFetchStatus.Success then fn() return end
	if loaded[id] == false then return end
	waiting[id] = waiting[id] or {}
	table.insert(waiting[id], fn)
end
if RunService:IsClient() then
	for _, id in pairs(M.Assets) do
		if not waiting[id] then
			waiting[id] = {}
			task.spawn(function()
				local success = false
				local ok = pcall(function()
					ContentProvider:PreloadAsync({id}, function(_, status) success = status == Enum.AssetFetchStatus.Success end)
				end)
				loaded[id] = ok and success
				if loaded[id] then for _, fn in ipairs(waiting[id]) do fn() end end
				waiting[id] = nil
			end)
		end
	end
end

-- 2026-10-03 (Claude): frosty window/card art is slightly see-through (button art stays solid).
M.SkinTransparency = 0.12

-- Art is below content. Layout containers are deliberately excluded.
function M.Skin(o, kind)
	if not o:IsA("GuiObject") or bound[o] then return end
	if o:FindFirstChildOfClass("UIListLayout") or o:FindFirstChildOfClass("UIGridLayout") then return end
	bound[o] = true
	if kind ~= "panel" then
		-- 2026-10-04 (Claude, user: "all of the that are round have that stupid borders"): buttons, banners, badges, pills and cards no
		-- longer get the pale frosty rim (it doubled their own outline and swallowed small widgets). They keep their own colour and get
		-- one clean navy outline if they have none. Window frames keep their art (their Background images are not drawn by this function).
		local isText = o:IsA("TextButton") or o:IsA("TextBox") or o:IsA("TextLabel")
		local hasBorder = false
		for _, c in ipairs(o:GetChildren()) do
			if c:IsA("UIStroke") and (not isText or c.ApplyStrokeMode == Enum.ApplyStrokeMode.Border) then hasBorder = true break end
		end
		if not hasBorder then
			local s = Instance.new("UIStroke")
			s.Name = "SnowOutline"
			s.Thickness = kind == "button" and 3 or 2.5
			s.Color = Color3.fromRGB(20, 40, 85)
			s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			s.Parent = o
		end
		return
	end
	local art = o:FindFirstChild("SnowArt") or Instance.new("ImageLabel")
	art.Name = "SnowArt"
	art:SetAttribute("SnowUIDecor", true)
	art.BackgroundTransparency = 1
	art.Active, art.Selectable = false, false
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.Position = UDim2.fromScale(0.5, 0.5)
	art.Size = UDim2.fromScale(1, 1)
	art.ZIndex = math.max(0, o.ZIndex - 1)
	art.ScaleType = Enum.ScaleType.Slice
	art.SliceCenter = M.Slice
	art.SliceScale = kind == "panel" and 0.2 or 0.055
	art.Visible = true -- transparent unloaded art leaves the native card readable
	art.ImageTransparency = kind == "button" and 0 or M.SkinTransparency
	local function selectImage()
		local id = kind == "panel" and M.Assets.panel or M.Assets.card
		if kind == "button" then
			local c = o.BackgroundColor3
			local semantic = o.Text~="" or c.R > c.B * 1.2 or c.G > c.B * 1.15 or o:FindFirstChildOfClass("UIGradient")
			id = semantic and M.Assets.card or M.Assets.button
		end
		art.Image, art.Visible = id, true
		art.ImageRectOffset, art.ImageRectSize = Vector2.zero, Vector2.zero
		art.SliceCenter = M.Slice
		if id == M.Assets.button then
			-- Keep native alpha; sample the tight button rectangle without resampling the PNG.
			art.ImageRectOffset, art.ImageRectSize = Vector2.new(0, 343), Vector2.new(1024, 343)
			art.SliceCenter, art.SliceScale = Rect.new(204, 102, 820, 241), 0.07
		end
		whenReady(id, function() if art.Parent and art.Image == id then art.Visible = true end end)
	end
	art.Parent = o
	selectImage()
	if kind == "button" then o:GetPropertyChangedSignal("BackgroundColor3"):Connect(selectImage) end
	return art
end

function M.Icon(parent, id, pos, size, name)
	local img = Instance.new("ImageLabel")
	img.Name = name or "SnowSymbol"
	img:SetAttribute("SnowUIDecor", true)
	img.BackgroundTransparency = 1
	img.Active, img.Selectable = false, false
	img.Image, img.ScaleType = id, Enum.ScaleType.Fit
	img.Position, img.Size = pos, size
	img.ZIndex = parent:IsA("GuiObject") and parent.ZIndex + 1 or 1
	img.Parent = parent
	return img
end

function M.Hex(holder, rects)
	local img=M.Icon(holder,M.Assets.hex,UDim2.fromScale(0,0),UDim2.fromScale(1,1),"SnowHex")
	img.ZIndex=holder.ZIndex img.ScaleType=Enum.ScaleType.Stretch
	img.ImageRectOffset=Vector2.new(124,50) img.ImageRectSize=Vector2.new(1006,1154)
	img.Visible=false
	local function sync()
		img.ImageColor3=rects[1].BackgroundColor3:Lerp(Color3.new(1,1,1),0.12)
		img.ImageTransparency=rects[1].BackgroundTransparency
	end
	sync()
	rects[1]:GetPropertyChangedSignal("BackgroundColor3"):Connect(sync)
	rects[1]:GetPropertyChangedSignal("BackgroundTransparency"):Connect(sync)
	whenReady(M.Assets.hex,function()
		if holder.Parent then
			img.Visible=true for _,r in ipairs(rects) do r.Visible=false end
		end
	end)
	return img
end

local accepted = {RNGGui=true, Tutorial=true, SnowArrivalGui=true, DiceBannerGui=true, TreasureToastGui=true, World2Toast=true, StageToast=true, FrostfallToast=true}
local seen = setmetatable({}, {__mode = "k"})
local function rootOf(o)
	local root = o:FindFirstAncestorWhichIsA("ScreenGui")
	if root and accepted[root.Name] then return root end
	local bb = o:FindFirstAncestorWhichIsA("BillboardGui")
	if bb and (bb.Name:sub(1,8)=="PetSign_" or bb.Name=="SnowPrompt") then return bb end
	local surface = o:FindFirstAncestorWhichIsA("SurfaceGui")
	local zones = workspace:FindFirstChild("SnowFieldZones")
	if surface and not (zones and surface:IsDescendantOf(zones)) then return surface end
end
local function apply(o)
	if not o or not o.Parent or o:GetAttribute("SnowUIDecor") or seen[o] or not o:IsA("GuiObject") then return end
	local root = rootOf(o)
	if not root then return end
	if o:IsA("ScrollingFrame") then
		o.ScrollBarImageColor3 = Color3.fromRGB(124,224,255)
		o.ScrollBarThickness = math.min(o.ScrollBarThickness,7)
		seen[o] = true return
	end
	if o:IsA("ImageLabel") and o.Name=="Background" and o.Parent.Parent and o.Parent.Parent.Name=="Panels" then
		seen[o] = true
		whenReady(M.Assets.panel,function()
			if o.Parent then o.Image=M.Assets.panel o.ScaleType=Enum.ScaleType.Slice o.SliceCenter=M.Slice o.SliceScale=0.2 end
		end)
		return
	end
	if o.Name=="Shadow" or o.Name=="Glow" or o.Name=="Aura" or o.Name=="Fill" or o.Name=="Shine" then return end
	if root:IsA("SurfaceGui") and o.Parent==root and o.BackgroundTransparency<0.9 then
		if not o:FindFirstChildOfClass("UICorner") then
			local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0.1,0) c.Parent=o
		end
		seen[o]=true M.Skin(o,"card") return
	end
	if o:IsA("Frame") or o:IsA("TextButton") or o:IsA("TextBox") then
		if o.BackgroundTransparency>=0.9 or not o:FindFirstChildOfClass("UICorner") then return end
		-- A sibling border follows the automatic-size box without influencing its measurement.
		if o.AutomaticSize~=Enum.AutomaticSize.None then
			if root.Name=="Tutorial" then
				o.BackgroundColor3=Color3.fromRGB(18,73,122)
				seen[o]=true
				-- 2026-10-04 (Claude): one clean icy outline instead of the frosty sibling border image
				if not o:FindFirstChildOfClass("UIStroke") then
					local s=Instance.new("UIStroke") s.Thickness=3 s.Color=Color3.fromRGB(150,215,255) s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=o
				end
			end
			return
		end
		local content=o:IsA("TextButton") or o:IsA("TextBox")
		for _,c in ipairs(o:GetChildren()) do
			if c:IsA("TextLabel") or c:IsA("ViewportFrame") or c:IsA("ImageLabel") or c:IsA("TextButton") then content=true break end
		end
		if not content then return end
		seen[o]=true
		M.Skin(o,o:IsA("TextButton") and "button" or "card")
	end
end
function M.Attach(container)
	for _,o in ipairs(container:GetDescendants()) do apply(o) end
	return container.DescendantAdded:Connect(function(o)
		task.defer(function()
			if o:IsA("UICorner") or o:IsA("TextLabel") or o:IsA("ViewportFrame") then apply(o.Parent) end
			apply(o)
		end)
	end)
end
function M.StyleTree(container)
	for _,o in ipairs(container:GetDescendants()) do apply(o) end
end
function M.SnowBackground(parent)
	local img=M.Icon(parent,M.Assets.loading,UDim2.fromScale(0,0),UDim2.fromScale(1,1),"SnowBackdrop")
	img.ZIndex=0 img.ScaleType=Enum.ScaleType.Crop
	img.ImageColor3=Color3.fromRGB(100,140,185) img.ImageTransparency=0.52
	return img
end
return M