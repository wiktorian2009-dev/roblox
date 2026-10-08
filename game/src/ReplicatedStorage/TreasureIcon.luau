-- TreasureIcon (2026-10-01, Claude): draws a treasure's picture for every GUI and the in-world reveal.
-- Uses the item's PNG (TreasureConfig.Images) when set; otherwise an emoji placeholder on a soft bubble.
-- Create(item, {Silhouette = bool, ZIndex = n}) -> Frame filling its parent (put it in a sized, square holder).
-- Silhouette: PNGs are tinted dark (true silhouette); placeholders become a dark "?" bubble.
local M = {}
local SIL = Color3.fromRGB(30, 36, 60)

function M.Create(item, opts)
	opts = opts or {}
	local z = opts.ZIndex or 1
	local f = Instance.new("Frame")
	f.Name = "TreasureIcon"
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 1)
	f.ZIndex = z
	if item.Image and item.Image ~= "" then
		local img = Instance.new("ImageLabel")
		img.Name = "Image"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.ScaleType = Enum.ScaleType.Fit
		img.Image = item.Image
		img.ZIndex = z
		if opts.Silhouette then img.ImageColor3 = SIL end
		img.Parent = f
	else
		local bubble = Instance.new("Frame")
		bubble.Name = "Placeholder"
		bubble.AnchorPoint = Vector2.new(0.5, 0.5)
		bubble.Position = UDim2.fromScale(0.5, 0.5)
		bubble.Size = UDim2.fromScale(0.86, 0.86)
		bubble.BackgroundColor3 = opts.Silhouette and SIL or Color3.new(1, 1, 1)
		bubble.BackgroundTransparency = opts.Silhouette and 0.15 or 0.35
		bubble.ZIndex = z
		local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = bubble
		Instance.new("UIAspectRatioConstraint").Parent = bubble
		bubble.Parent = f
		local t = Instance.new("TextLabel")
		t.Name = "Emoji"
		t.BackgroundTransparency = 1
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = UDim2.fromScale(0.5, 0.52)
		t.Size = UDim2.fromScale(0.8, 0.8)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = opts.Silhouette and "?" or (item.Emoji or "✨")
		t.TextColor3 = Color3.new(1, 1, 1)
		t.ZIndex = z + 1
		t.Parent = bubble
	end
	return f
end

return M
