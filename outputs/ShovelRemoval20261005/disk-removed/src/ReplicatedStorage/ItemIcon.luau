-- Builds the visual for an item: its image if it has one, otherwise a drawn cartoon shovel.
local ItemIcon = {}
local OUTLINE = Color3.fromRGB(15, 15, 20)
local WHITE = Color3.new(1, 1, 1)

function ItemIcon.create(item)
	if item.ImageId and item.ImageId ~= "" then
		local img = Instance.new("ImageLabel")
		img.Name = "Icon"
		img.BackgroundTransparency = 1
		img.Image = item.ImageId
		img.ScaleType = Enum.ScaleType.Fit
		img.Size = UDim2.fromScale(1, 1)
		return img
	end

	local root = Instance.new("Frame")
	root.Name = "Icon"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(1, 1)
	local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 1; a.Parent = root

	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.AnchorPoint = Vector2.new(0.5, 0.5)
	body.Position = UDim2.fromScale(0.5, 0.5)
	body.Size = UDim2.fromScale(1, 1)
	body.Rotation = 35
	body.Parent = root

	local function part(name, pos, size, color, rad)
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = pos
		f.Size = size
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(rad, 0); c.Parent = f
		local s = Instance.new("UIStroke"); s.Thickness = 2.5; s.Color = OUTLINE
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = f
		f.Parent = body
		return f
	end

	local wood = Color3.fromRGB(150, 95, 55)
	part("Shaft", UDim2.fromScale(0.5, 0.38), UDim2.fromScale(0.09, 0.52), wood, 0.5)
	part("Grip", UDim2.fromScale(0.5, 0.1), UDim2.fromScale(0.3, 0.1), wood, 0.5)
	local tint = item.Tint or Color3.fromRGB(180, 185, 195)
	local blade = part("Blade", UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.38, 0.38), WHITE, 0.3)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(tint:Lerp(WHITE, 0.45), tint)
	g.Rotation = 90
	g.Parent = blade
	return root
end

return ItemIcon
