-- CleanControls: compact native controls for the HELP menu and AFK button.
-- Presentation only; each owning client keeps its state, layout and input callbacks.
local M = {}
local NAVY = Color3.fromRGB(20, 40, 75)
function M.Apply(object, panel, radius)
	object:SetAttribute("SnowUIDecor", true)
	object:SetAttribute("SnowArtSkinned", true)
	object.BorderSizePixel = 0
	object.BackgroundTransparency = 0
	local corner = object:FindFirstChildOfClass("UICorner")
	if not corner then corner = Instance.new("UICorner"); corner.Parent = object end
	corner.CornerRadius = radius or UDim.new(0, panel and 14 or 10)
	local border
	for _, child in ipairs(object:GetChildren()) do
		if child:IsA("UIStroke") and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then
			if not border then border = child else child.Enabled = false end
		end
	end
	if not border then border = Instance.new("UIStroke"); border.Parent = object end
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Color = panel and Color3.fromRGB(95, 155, 220) or NAVY
	border.Thickness, border.Enabled = 2, true
	local gradient = object:FindFirstChildOfClass("UIGradient")
	if not gradient then gradient = Instance.new("UIGradient"); gradient.Parent = object end
	gradient.Name = "ControlGloss"
	gradient.Rotation, gradient.Enabled = 90, true
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(195, 220, 245))
end
return M
