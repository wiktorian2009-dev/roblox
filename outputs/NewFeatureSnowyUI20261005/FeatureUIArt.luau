-- New feature GUI artwork, 2026-10-05. Presentation only; native buttons keep their actions and semantic fill colors.
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Art = {}
Art.Assets = {
	["hud-frame"] = "rbxassetid://98043688858057",
	["teleport"] = "rbxassetid://100711932796017",
	["contracts"] = "rbxassetid://137445702736979",
	["snow-pass"] = "rbxassetid://118980978543857",
	["drift"] = "rbxassetid://101962507757419",
	["spin"] = "rbxassetid://75831282782683",
	["aurora-wheels"] = "rbxassetid://106686963600706",
	["starter-pack"] = "rbxassetid://109621099381649",
	["exit"] = "rbxassetid://93108001168663",
	["recover"] = "rbxassetid://74283059200242",
}
local ready, pending = {}, {}
local function afterLoad(id, fn)
	if ready[id] then fn() return end
	pending[id] = pending[id] or {}
	table.insert(pending[id], fn)
end
local bound = setmetatable({}, {__mode = "k"})
function Art.Icon(parent, key, position, size, name)
	local image = Instance.new("ImageLabel")
	image.Name = name or "FeatureIcon"
	image:SetAttribute("SnowUIDecor", true)
	image.BackgroundTransparency = 1
	image.Active, image.Selectable = false, false
	image.Position, image.Size = position, size
	image.Image = Art.Assets[key] or ""
	image.ScaleType = Enum.ScaleType.Fit
	image.ZIndex = parent:IsA("GuiObject") and parent.ZIndex + 2 or 2
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio, aspect.AspectType = 1, Enum.AspectType.FitWithinMaxSize
	aspect.Parent = image
	image.Parent = parent
	return image
end
function Art.Skin(object)
	if bound[object] then return bound[object] end
	object:SetAttribute("SnowUIDecor", true)
	object.BorderSizePixel = 0
	if not object:FindFirstChildOfClass("UIGradient") then
		local gradient = Instance.new("UIGradient")
		gradient.Name, gradient.Rotation = "FeatureWinterGloss", 90
		gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 215, 245))
		gradient.Parent = object
	end
	local corner = object:FindFirstChildOfClass("UICorner")
	if not corner then corner = Instance.new("UICorner"); corner.Parent = object end
	local rim = Instance.new("ImageLabel")
	rim.Name = "FeatureWinterRim"
	rim:SetAttribute("SnowUIDecor", true)
	rim.BackgroundTransparency = 1
	rim.Active, rim.Selectable = false, false
	rim.Image = Art.Assets["hud-frame"]
	rim.ScaleType = Enum.ScaleType.Slice
rim.ImageRectOffset = Vector2.new(0, 78)
	rim.ImageRectSize = Vector2.new(1024, 386)
	rim.SliceCenter = Rect.new(240, 90, 784, 306)
	rim.AnchorPoint = Vector2.new(0.5, 0.5)
	rim.Position = UDim2.fromScale(0.5, 0.5)
	rim.Size = UDim2.fromScale(1, 1)
	rim.ZIndex = object.ZIndex + 1
	rim.Parent = object
	bound[object] = rim
	local function fit()
		if not object.Parent then return end
		local size = object.AbsoluteSize
		local scale = math.clamp(math.min(0.18, size.Y / 180, size.X / 320), 0.07, 0.18)
rim.SliceScale = scale
		rim.Size = UDim2.new(1, 0, 1, 25 * scale)
		rim.Position = UDim2.new(0.5, 0, 0.5, -7.5 * scale)
		corner.CornerRadius = UDim.new(0, 70 * scale)
	end
	object:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	afterLoad(rim.Image, function()
		if not object.Parent then return end
		-- A single outline: do not draw native border strokes underneath the generated rim.
		for _, child in ipairs(object:GetChildren()) do
			if child:IsA("UIStroke") and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then child.Enabled = false end
		end
	end)
	return rim
end
if RunService:IsClient() then
	task.spawn(function()
		for _, id in pairs(Art.Assets) do
			local label = Instance.new("ImageLabel"); label.Image = id
			local success = false
			pcall(function() ContentProvider:PreloadAsync({label}, function(_, status) if status == Enum.AssetFetchStatus.Success then success = true end end) end)
			label:Destroy()
			ready[id] = success
			if success then for _, fn in ipairs(pending[id] or {}) do fn() end end
			pending[id] = nil
		end
	end)
end
return Art

