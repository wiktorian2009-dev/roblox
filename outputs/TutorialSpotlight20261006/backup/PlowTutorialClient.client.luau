-- PlowTutorialClient v2 (2026-10-05, Claude): the new-player tutorial, rebuilt around confirmed gameplay state.
-- MAIN lesson:   purpose -> DRIVE -> drive into the highlighted snow -> "Earn Snow: X / Y" (Y = price of a real starting upgrade, read
--                from UpgradeConfig) -> tap UPGRADES -> buy that upgrade (advances only when the server sets Up_<id>) -> close -> try it.
-- GARAGE lesson: GARAGE -> your own bay -> your pedestal (E = roll) -> "an OFFER is a part for sale" -> open the card -> BUY (affordable) or
--                RESERVE (too expensive: the lesson pauses and resumes once you can afford it) -> EQUIP at the workbench -> portal -> DRIVE.
-- One short instruction + one target at a time. Targets are resolved live every frame (UI: AbsolutePosition/Size, visibility chain,
-- ScreenGui offsets/insets; world: own garage objects only, with an off-screen edge arrow). Hints after ~10 s without progress; HELP repeats
-- the step; SKIP skips the remaining lessons. Progress / timings: PlowService "TutorialProgress" (Tutorial v2 checkpoint, onboarding funnel).
-- While an essential step shows, LocalPlayer.SuppressEvents = true (contract + Frost King announcements wait). Replay: the HELP pill.
-- Studio debug (BalanceTestMode sessions only): PlayerGui.PlowTutorial.TutorialDebug:Invoke("State" | "Start", lesson, stepId | "Stop").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local C = require(RS:WaitForChild("PlowConfig"))
if C.Mode ~= "Snowplow" then return end
local U = require(RS:WaitForChild("UpgradeConfig"))
local Api = require(RS:WaitForChild("PlowClientApi"))
local SF = require(RS:WaitForChild("SnowFields"))
local Format = require(RS:WaitForChild("NumberFormat"))
local remote = RS:WaitForChild("PlowRemote")
local event = RS:WaitForChild("PlowEvent")
local collected = RS:WaitForChild("SnowCollected")
local pg = player:WaitForChild("PlayerGui")

local FONT, WHITE, NAVY = Enum.Font.FredokaOne, Color3.new(1, 1, 1), Color3.fromRGB(20, 40, 85)
local GOLD, GREEN, ICE = Color3.fromRGB(255, 220, 90), Color3.fromRGB(110, 235, 140), Color3.fromRGB(150, 225, 255)
local HINT_AFTER = 10
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function snow()
	local ls = player:FindFirstChild("leaderstats")
	local s = ls and ls:FindFirstChild("Snow")
	return s and s.Value or 0
end
local function hrp() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function call(action, ...)
	local args = table.pack(...)
	local ok, res = pcall(function() return remote:InvokeServer(action, table.unpack(args, 1, args.n)) end)
	return ok and type(res) == "table" and res or {ok = false}
end

--------------------------------------------------
-- input wording
--------------------------------------------------
local function inputKind()
	local t = UIS:GetLastInputType()
	if t.Name:find("Gamepad") then return "pad" end
	if t == Enum.UserInputType.Touch then return "touch" end
	if UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled then return "touch" end
	return "kb"
end
local function pick(kb, touch, pad) local k = inputKind(); return k == "touch" and touch or (k == "pad" and pad or kb) end

--------------------------------------------------
-- GUI: instruction card (top, moves to the bottom if it would cover the target), pointer layer, HELP pill
--------------------------------------------------
local sg = mk("ScreenGui", {Name = "PlowTutorial", ResetOnSpawn = false, DisplayOrder = 200, IgnoreGuiInset = true, Enabled = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)
local card = mk("Frame", {Name = "Card", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.025), Size = UDim2.fromScale(0.5, 0.16),
	BackgroundColor3 = Color3.fromRGB(18, 73, 122), BackgroundTransparency = 0.08, Visible = false, ZIndex = 10}, sg)
card:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.16, 0)}, card)
mk("UIStroke", {Thickness = 3, Color = Color3.fromRGB(150, 215, 255), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, card)
mk("UISizeConstraint", {MinSize = Vector2.new(300, 92), MaxSize = Vector2.new(760, 178)}, card)
local cardScale = mk("UIScale", {Scale = 1}, card)
local stepL = mk("TextLabel", {Name = "Step", BackgroundTransparency = 1, Position = UDim2.fromScale(0.04, 0.05), Size = UDim2.fromScale(0.6, 0.17), Font = FONT, TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ICE, Text = "", ZIndex = 11}, card)
local mainL = mk("TextLabel", {Name = "Text", BackgroundTransparency = 1, Position = UDim2.fromScale(0.04, 0.22), Size = UDim2.fromScale(0.92, 0.42), Font = FONT, TextScaled = true,
	TextWrapped = true, TextColor3 = WHITE, Text = "", ZIndex = 11}, card)
mk("UIStroke", {Thickness = 2, Color = NAVY}, mainL)
local progL = mk("TextLabel", {Name = "Progress", BackgroundTransparency = 1, Position = UDim2.fromScale(0.04, 0.64), Size = UDim2.fromScale(0.92, 0.17), Font = FONT, TextScaled = true,
	TextColor3 = GOLD, Text = "", ZIndex = 11}, card)
mk("UIStroke", {Thickness = 2, Color = NAVY}, progL)
local hintL = mk("TextLabel", {Name = "Hint", BackgroundTransparency = 1, Position = UDim2.fromScale(0.04, 0.81), Size = UDim2.fromScale(0.92, 0.16), Font = FONT, TextScaled = true,
	TextColor3 = Color3.fromRGB(255, 240, 190), Text = "", ZIndex = 11}, card)
mk("UIStroke", {Thickness = 1.6, Color = NAVY}, hintL)
local function smallButton(parent, text, color, pos, size)
	local b = mk("TextButton", {Text = "", AutoButtonColor = true, BackgroundColor3 = color, Position = pos, Size = size, ZIndex = 12}, parent)
	b:SetAttribute("SnowUIDecor", true)
	mk("UICorner", {CornerRadius = UDim.new(1, 0)}, b)
	mk("UIStroke", {Thickness = 2.5, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
	local l = mk("TextLabel", {Name = "Label", BackgroundTransparency = 1, Size = UDim2.fromScale(0.86, 0.72), Position = UDim2.fromScale(0.07, 0.14), Font = FONT, TextScaled = true,
		TextColor3 = NAVY, Text = text, ZIndex = 13}, b)
	return b, l
end
local helpB = smallButton(card, "? HELP", Color3.fromRGB(255, 225, 120), UDim2.fromScale(0.66, 0.04), UDim2.fromScale(0.15, 0.17))
local skipB, skipText = smallButton(card, "SKIP", WHITE, UDim2.fromScale(0.82, 0.04), UDim2.fromScale(0.14, 0.17))
local nextB, nextText = smallButton(card, "OK!", GREEN, UDim2.fromScale(0.38, 0.66), UDim2.fromScale(0.24, 0.26))
nextB.Visible = false

-- pointer layer (never interactive: plain Frames / labels with Active = false so clicks reach the real buttons)
local layer = mk("Frame", {Name = "Pointer", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Active = false, ZIndex = 20}, sg)
local ring = mk("Frame", {Name = "Outline", BackgroundTransparency = 1, Visible = false, Active = false, ZIndex = 21}, layer)
local ringCorner = mk("UICorner", {CornerRadius = UDim.new(0, 14)}, ring)
local ringStroke = mk("UIStroke", {Thickness = 5, Color = GOLD, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, ring)
local ring2 = mk("Frame", {Name = "Outline2", BackgroundTransparency = 1, Visible = false, Active = false, ZIndex = 20}, layer)
mk("UICorner", {CornerRadius = UDim.new(0, 18)}, ring2)
local ring2Stroke = mk("UIStroke", {Thickness = 3, Color = WHITE, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, ring2)
-- arrow built from UI geometry (points DOWN at Rotation 0): shaft + diamond head, each with a navy backing
local function arrowShape(parent, name)
	local a = mk("Frame", {Name = name, BackgroundTransparency = 1, Size = UDim2.fromOffset(70, 92), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Active = false, ZIndex = 22}, parent)
	local function piece(size, pos, rot, color, z)
		local f = mk("Frame", {Size = size, Position = pos, AnchorPoint = Vector2.new(0.5, 0.5), Rotation = rot, BackgroundColor3 = color, BorderSizePixel = 0, Active = false, ZIndex = z}, a)
		mk("UICorner", {CornerRadius = UDim.new(0, 6)}, f)
		return f
	end
	piece(UDim2.fromOffset(28, 52), UDim2.fromOffset(35, 30), 0, NAVY, 22)
	piece(UDim2.fromOffset(52, 52), UDim2.fromOffset(35, 60), 45, NAVY, 22)
	piece(UDim2.fromOffset(18, 46), UDim2.fromOffset(35, 30), 0, GOLD, 23)
	piece(UDim2.fromOffset(40, 40), UDim2.fromOffset(35, 60), 45, GOLD, 23)
	piece(UDim2.fromOffset(70, 30), UDim2.fromOffset(35, 44), 0, Color3.new(0, 0, 0), 21).BackgroundTransparency = 1
	return a
end
local arrow = arrowShape(layer, "Arrow")
local edgeArrow = arrowShape(layer, "EdgeArrow")
local tag = mk("TextLabel", {Name = "Tag", BackgroundTransparency = 1, Size = UDim2.fromOffset(240, 40), AnchorPoint = Vector2.new(0.5, 0.5), Font = FONT, TextScaled = true,
	TextColor3 = GOLD, Text = "", Visible = false, Active = false, ZIndex = 24}, layer)
mk("UIStroke", {Thickness = 3, Color = NAVY}, tag)
local flash = mk("TextLabel", {Name = "Flash", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.6, 0.1),
	Font = FONT, TextScaled = true, TextColor3 = GREEN, Text = "", Visible = false, ZIndex = 30}, sg)
mk("UIStroke", {Thickness = 3, Color = NAVY}, flash)

-- HELP pill (always available while not in a lesson): replay the tutorial or the garage lesson
local helpPill = mk("TextButton", {Name = "HelpPill", Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(255, 225, 120), AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromScale(0.012, 0.835), Size = UDim2.fromScale(0.09, 0.045), Visible = false, ZIndex = 5}, sg)
helpPill:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, helpPill)
mk("UIStroke", {Thickness = 2.5, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, helpPill)
mk("UISizeConstraint", {MinSize = Vector2.new(92, 32)}, helpPill)
mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(0.86, 0.7), Position = UDim2.fromScale(0.07, 0.15), Font = FONT, TextScaled = true, TextColor3 = NAVY, Text = "? HELP", ZIndex = 6}, helpPill)
local helpMenu = mk("Frame", {Name = "HelpMenu", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0.012, 0.83), Size = UDim2.fromScale(0.22, 0.2), BackgroundColor3 = Color3.fromRGB(18, 73, 122),
	Visible = false, ZIndex = 40}, sg)
helpMenu:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.12, 0)}, helpMenu)
mk("UIStroke", {Thickness = 3, Color = Color3.fromRGB(150, 215, 255), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, helpMenu)
mk("UISizeConstraint", {MinSize = Vector2.new(230, 150)}, helpMenu)
local replayMainB = smallButton(helpMenu, "REPLAY TUTORIAL", GREEN, UDim2.fromScale(0.06, 0.08), UDim2.fromScale(0.88, 0.26))
local replayGarageB = smallButton(helpMenu, "GARAGE LESSON", ICE, UDim2.fromScale(0.06, 0.38), UDim2.fromScale(0.88, 0.26))
local closeMenuB = smallButton(helpMenu, "CLOSE", WHITE, UDim2.fromScale(0.3, 0.7), UDim2.fromScale(0.4, 0.22))
for _, b in ipairs({replayMainB, replayGarageB, closeMenuB}) do b.ZIndex = 41; b.Label.ZIndex = 42 end

--------------------------------------------------
-- target resolution
--------------------------------------------------
local function guiShown(o)
	local cur = o
	while cur do
		if cur:IsA("GuiObject") and not cur.Visible then return false end
		if cur:IsA("LayerCollector") then return cur.Enabled end
		cur = cur.Parent
	end
	return false
end
-- rect of a live GuiObject in this overlay's own coordinates. AbsolutePosition is one global space for every ScreenGui (it already
-- includes their IgnoreGuiInset / ScreenInsets / UIScale), so only this overlay's own origin is subtracted.
local function screenRect(o)
	return o.AbsolutePosition - sg.AbsolutePosition, o.AbsoluteSize
end
local function viewport() return sg.AbsoluteSize.X > 10 and sg.AbsoluteSize or workspace.CurrentCamera.ViewportSize end

local cur = {target = nil, missingSince = nil}
local worldFx = mk("Folder", {Name = "TutorialWorldFX"}, workspace)
local marker, markerLabel, beam, beamA0, beamA1, highlight, fieldEdges = nil, nil, nil, nil, nil, nil, {}
local function clearWorld()
	worldFx:ClearAllChildren()
	marker, markerLabel, beam, beamA1, highlight, fieldEdges = nil, nil, nil, nil, nil, {}
	if beamA0 then beamA0:Destroy(); beamA0 = nil end
end
local function worldPoint(t)
	local o = t.get and t.get()
	if typeof(o) == "Vector3" then return o end
	if typeof(o) == "Instance" then
		if o:IsA("BasePart") then return o.Position + Vector3.new(0, o.Size.Y / 2, 0), o end
		if o:IsA("Model") then local cf, size = o:GetBoundingBox(); return cf.Position + Vector3.new(0, size.Y / 2, 0), o end
	end
	return nil
end
local function ensureMarker(pos, label)
	if not marker then
		marker = mk("Part", {Name = "TutorialMarker", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2)}, worldFx)
		local bb = mk("BillboardGui", {Size = UDim2.fromOffset(150, 150), StudsOffsetWorldSpace = Vector3.new(0, 4, 0), AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 3000}, marker)
		local a = arrowShape(bb, "WorldArrow"); a.Visible = true; a.Position = UDim2.fromScale(0.5, 0.62)
		markerLabel = mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.28), Font = FONT, TextScaled = true, TextColor3 = GOLD, Text = ""}, bb)
		mk("UIStroke", {Thickness = 3, Color = NAVY}, markerLabel)
		beamA1 = mk("Attachment", {Position = Vector3.new(0, 1, 0)}, marker)
	end
	marker.CFrame = CFrame.new(pos + Vector3.new(0, 1.2 + math.abs(math.sin(os.clock() * 3)) * 1.2, 0))
	local r = hrp()
	if markerLabel then
		local d = r and (r.Position - pos).Magnitude or 0
		markerLabel.Text = label .. (d > 12 and ("  " .. math.floor(d) .. "m") or "")
	end
	-- short directional trail from you towards the target
	if r and (not beamA0 or beamA0.Parent ~= r) then
		if beamA0 then beamA0:Destroy() end
		beamA0 = mk("Attachment", {Name = "TutorialBeamA0"}, r)
		beam = mk("Beam", {Attachment0 = beamA0, Attachment1 = beamA1, Width0 = 0.7, Width1 = 0.35, FaceCamera = true, LightEmission = 1, Segments = 18, CurveSize0 = 3,
			Color = ColorSequence.new(GOLD, GREEN), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.6)})}, worldFx)
	end
end
local function setHighlight(model)
	if highlight and highlight.Adornee == model then return end
	if highlight then highlight:Destroy(); highlight = nil end
	if model then highlight = mk("Highlight", {Adornee = model, FillColor = GOLD, FillTransparency = 0.75, OutlineColor = GOLD, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.Occluded}, worldFx) end
end
local function outlineField(f)
	local ts = SF.TileSize
	local o = SF.Origin(f)
	local y = f.Center.Y + 3
	local p = {Vector3.new(o.X, y, o.Z), Vector3.new(o.X + f.Width * ts, y, o.Z), Vector3.new(o.X + f.Width * ts, y, o.Z + f.Depth * ts), Vector3.new(o.X, y, o.Z + f.Depth * ts)}
	for k = 1, 4 do
		local a, b = p[k], p[k % 4 + 1]
		table.insert(fieldEdges, mk("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = GOLD,
			Size = Vector3.new(0.5, 0.35, (b - a).Magnitude + 0.5), CFrame = CFrame.lookAt((a + b) / 2, b)}, worldFx))
	end
end

-- per frame: draw the current target
local function placeArrowNear(pos, size, label)
	local vp = viewport()
	local center = pos + size / 2
	local spaceAbove, spaceBelow = pos.Y, vp.Y - (pos.Y + size.Y)
	local spaceLeft, spaceRight = pos.X, vp.X - (pos.X + size.X)
	local bob = math.abs(math.sin(os.clock() * 5)) * 12
	local apos, rot, tpos
	-- buttons in the side columns: point from the open side so the arrow never covers the neighbouring buttons
	local edge = center.X < vp.X * 0.16 and "right" or (center.X > vp.X * 0.84 and spaceAbove < 160 and "left" or nil)
	if edge == "right" then
		apos, rot = Vector2.new(pos.X + size.X + 54, center.Y), 90
		tpos = Vector2.new(pos.X + size.X + 168, center.Y)
		apos = apos + Vector2.new(bob, 0); tpos = tpos + Vector2.new(bob, 0)
	elseif edge == "left" then
		apos, rot = Vector2.new(pos.X - 54 - bob, center.Y), -90
		tpos = Vector2.new(pos.X - 168 - bob, center.Y)
	elseif spaceAbove >= 120 or (spaceAbove >= spaceBelow and spaceAbove >= 70) then
		apos, rot = Vector2.new(center.X, pos.Y - 54 - bob), 0
		tpos = Vector2.new(center.X, pos.Y - 112 - bob)
	elseif spaceBelow >= 120 then
		apos, rot = Vector2.new(center.X, pos.Y + size.Y + 54 + bob), 180
		tpos = Vector2.new(center.X, pos.Y + size.Y + 112 + bob)
	elseif spaceLeft >= spaceRight then
		apos, rot = Vector2.new(pos.X - 54 - bob, center.Y), -90
		tpos = Vector2.new(pos.X - 150 - bob, center.Y)
	else
		apos, rot = Vector2.new(pos.X + size.X + 54 + bob, center.Y), 90
		tpos = Vector2.new(pos.X + size.X + 150 + bob, center.Y)
	end
	local function clampV(v, m) return Vector2.new(math.clamp(v.X, m, vp.X - m), math.clamp(v.Y, m, vp.Y - m)) end
	apos, tpos = clampV(apos, 40), clampV(tpos, 30)
	arrow.Position, arrow.Rotation, arrow.Visible = UDim2.fromOffset(apos.X, apos.Y), rot, true
	tag.Position, tag.Text, tag.Visible = UDim2.fromOffset(tpos.X, tpos.Y), label or "", (label or "") ~= ""
end
local function hidePointer()
	arrow.Visible, ring.Visible, ring2.Visible, tag.Visible, edgeArrow.Visible = false, false, false, false, false
end
local cardAtBottom = false
RunService.RenderStepped:Connect(function()
	local t = cur.target
	if not t or not card.Visible then hidePointer(); if marker then clearWorld() end return end
	if t.kind == "ui" then
		if marker then clearWorld() end
		local o = t.get and t.get()
		if o and o.Parent and guiShown(o) and o.AbsoluteSize.X > 2 then
			cur.missingSince = nil
			if t.ensure then t.ensure(o) end
			local pos, size = screenRect(o)
			local pulse = 0.5 + 0.5 * math.sin(os.clock() * 6)
			local pad = 6 + pulse * 4
			ring.Position, ring.Size, ring.Visible = UDim2.fromOffset(pos.X - pad, pos.Y - pad), UDim2.fromOffset(size.X + pad * 2, size.Y + pad * 2), true
			ring2.Position, ring2.Size, ring2.Visible = UDim2.fromOffset(pos.X - pad - 7, pos.Y - pad - 7), UDim2.fromOffset(size.X + pad * 2 + 14, size.Y + pad * 2 + 14), true
			ringStroke.Thickness = 4 + pulse * 3
			ring2Stroke.Transparency = 0.2 + pulse * 0.5
			ringCorner.CornerRadius = UDim.new(0, math.min(size.X, size.Y) * 0.3)
			placeArrowNear(pos, size, t.label)
			edgeArrow.Visible = false
			-- keep the instruction card off the target: move it to the lower middle if the target sits under its top slot
			local vp, csize = viewport(), card.AbsoluteSize
			local topX0, topY1 = (vp.X - csize.X) / 2, vp.Y * 0.025 + csize.Y + 130
			local overlapTop = pos.X < topX0 + csize.X and pos.X + size.X > topX0 and pos.Y < topY1
			if overlapTop ~= cardAtBottom then
				cardAtBottom = overlapTop
				card.Position = cardAtBottom and UDim2.fromScale(0.5, 0.6) or UDim2.fromScale(0.5, 0.025)
			end
		else
			hidePointer()
			cur.missingSince = cur.missingSince or os.clock()
		end
	elseif t.kind == "world" then
		hidePointer()
		local p, model = worldPoint(t)
		if not p then cur.missingSince = cur.missingSince or os.clock(); return end
		cur.missingSince = nil
		ensureMarker(p, t.label or "")
		if t.highlight then setHighlight(t.highlightModel and t.highlightModel() or model) end
		-- off-screen / behind the camera: an arrow on the screen edge pointing the way
		local cam = workspace.CurrentCamera
		local sp, onScreen = cam:WorldToViewportPoint(p)
		local vp = viewport()
		if not onScreen or sp.Z < 0 or sp.X < 0 or sp.X > vp.X or sp.Y < 0 or sp.Y > vp.Y then
			local rel = cam.CFrame:PointToObjectSpace(p)
			local dir = Vector2.new(rel.X, -rel.Y)
			if rel.Z > 0 then dir = -dir end
			if dir.Magnitude < 1e-3 then dir = Vector2.new(0, 1) end
			dir = dir.Unit
			local c = vp / 2
			local k = math.min((vp.X / 2 - 70) / math.max(1e-3, math.abs(dir.X)), (vp.Y / 2 - 70) / math.max(1e-3, math.abs(dir.Y)))
			local at = c + dir * k
			local cp, cs = screenRect(card) -- never on top of the lesson card (targets behind the camera point up, where the card sits)
			if card.Visible and at.X > cp.X - 60 and at.X < cp.X + cs.X + 60 and at.Y < cp.Y + cs.Y + 60 then at = Vector2.new(at.X, cp.Y + cs.Y + 60) end
			edgeArrow.Position = UDim2.fromOffset(at.X, at.Y)
			edgeArrow.Rotation = math.deg(math.atan2(dir.Y, dir.X)) - 90
			edgeArrow.Visible = true
			tag.Position, tag.Text, tag.Visible = UDim2.fromOffset(math.clamp(at.X - dir.X * 90, 120, vp.X - 120), math.clamp(at.Y - dir.Y * 90, 30, vp.Y - 30)), t.label or "", true
		end
	end
end)

--------------------------------------------------
-- live game state helpers
--------------------------------------------------
local collects = 0
collected.OnClientEvent:Connect(function() collects += 1 end) -- fired by SnowFieldService only when the blade really clears layers
local function owned(id) return player:GetAttribute("Up_" .. id) == true end
local function ownedSet() local s = {} for id in pairs(U.ById) do if owned(id) then s[id] = true end end return s end
local function stagesSet()
	local s = {Starter = true}
	for _, st in ipairs(require(RS:WaitForChild("StageConfig")).Order) do if st.Id ~= "Starter" then s[st.Id] = player:GetAttribute("Stage_" .. st.Id) == true end end
	return s
end
-- the cheapest Snow (or clearing) upgrade you could buy right now: the lesson goal. Never hard-coded: read from UpgradeConfig.
local function goalUpgrade()
	local own, stages = ownedSet(), stagesSet()
	local best
	for _, tree in ipairs(U.Trees) do
		if tree.Id == "Snow" then
			for _, n in ipairs(tree.Nodes) do
				if not own[n.Id] then
					local front = n.Center
					if not front then for _, nb in ipairs(U.Neighbours(n)) do if own[nb.Id] then front = true; break end end end
					if front and U.LockReason(n, own, stages) == nil and (not best or U.CostOf(n) < U.CostOf(best)) then best = n end
				end
			end
		end
	end
	return best
end
local function upgradeGui() return pg:FindFirstChild("UpgradeTreeGui") end
local function upgradesOpen() local g = upgradeGui(); return g ~= nil and g.Enabled end
local function myBay()
	local i = player:GetAttribute("GarageBay")
	local g = workspace:FindFirstChild("PlowGarage")
	local bays = g and g:FindFirstChild("Bays")
	if not (i and bays) then return nil end
	for _, m in ipairs(bays:GetChildren()) do if m:GetAttribute("BayIndex") == i then return m end end
end
local function topOf(m, name)
	local o = m and m:FindFirstChild(name)
	if not o then return nil end
	if o:IsA("BasePart") then return o end
	return o:FindFirstChild("Top") or o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart", true)
end
local function nearestStarterField()
	local r = hrp()
	local best, bd
	for _, f in ipairs(SF.Fields) do
		if (f.Style or "Starter") == "Starter" and not f.OwnerUserId then
			local o = SF.Origin(f)
			local c = Vector3.new(o.X + f.Width * SF.TileSize / 2, f.Center.Y, o.Z + f.Depth * SF.TileSize / 2)
			local d = r and (r.Position - c).Magnitude or 0
			if not bd or d < bd then best, bd = f, d end
		end
	end
	return best
end
local function nearestPointOnField(f)
	local r = hrp()
	local o = SF.Origin(f)
	local ts = SF.TileSize
	if not r then return f.Center end
	return Vector3.new(math.clamp(r.Position.X, o.X + 3, o.X + f.Width * ts - 3), f.Center.Y, math.clamp(r.Position.Z, o.Z + 3, o.Z + f.Depth * ts - 3))
end
local function state() return Api.State end
local function offerKeys()
	local s, out = state(), {}
	for _, k in ipairs({"1", "2", "3"}) do if s and s.Offers and s.Offers[k] then table.insert(out, k) end end
	return out
end
local function partCount(id) local s = state(); return s and s.Parts and s.Parts[id] or 0 end
local function shopGui() return pg:FindFirstChild("PlowShopGui") end
local function cardButton(name) local g = shopGui(); local c = g and g:FindFirstChild("OfferCard"); return c and c:FindFirstChild(name, true) end

--------------------------------------------------
-- lessons (steps advance only from confirmed state; "back" rules recover when the player undoes something)
--------------------------------------------------
local ctx = {}
local MAIN, GARAGE = {}, {}
local flashText
-- driving but not moving (against a wall / prop): tell the player how to get free
local function stuckHint()
	local r = hrp()
	if player:GetAttribute("PlowDriving") ~= true or not r then return nil end
	if r.AssemblyLinearVelocity.Magnitude > 2.5 then return nil end
	return pick("Stuck? Back up with S, then steer around with A / D.", "Stuck? Pull the thumbstick back, then steer around.", "Stuck? Pull the stick back, then steer around.")
end
local function S(list, step) step.index = #list + 1; table.insert(list, step); list[step.id] = step; return step end

S(MAIN, {id = "Intro", essential = true, title = "WELCOME!",
	text = function() return "Drive through snow to earn Snow.\nUse it to improve your plow!" end, okButton = true,
	done = function() return ctx.ok end})
S(MAIN, {id = "Drive", essential = true, title = "STEP 1: GET IN",
	text = function() return "Your starter plow is ready!\n" .. pick("Press F or click DRIVE to hop in.", "Tap DRIVE to hop in.", "Press Y (or select DRIVE) to hop in.") end,
	hint = function() return player:GetAttribute("InGarage") and "You're in the garage - tap LOBBY first." or "Tap the green DRIVE button on the right." end,
	target = {kind = "ui", label = "DRIVE", get = function()
		if player:GetAttribute("InGarage") then return pg:FindFirstChild("Garage", true) end
		local g = pg:FindFirstChild("PlowDriveGui"); return g and g:FindFirstChild("Drive") end},
	done = function() return player:GetAttribute("PlowDriving") == true end})
S(MAIN, {id = "Field", essential = true, title = "STEP 2: DRIVE TO THE SNOW",
	enter = function() ctx.collects0 = collects; ctx.field = nearestStarterField(); clearWorld(); if ctx.field then outlineField(ctx.field) end end,
	text = function() return "Drive into the highlighted snow.\nYour blade clears it automatically!" end,
	progress = function() return pick("W A S D to drive", "Use the thumbstick to drive", "Left stick to drive") end,
	hint = function() return stuckHint() or "Move your plow into the highlighted snow - follow the glowing trail." end,
	target = {kind = "world", label = "SNOW", get = function() return ctx.field and nearestPointOnField(ctx.field) end},
	back = function() if player:GetAttribute("PlowDriving") ~= true then return "Drive" end end,
	done = function() return collects > ctx.collects0 end})
S(MAIN, {id = "Earn", essential = true, title = "STEP 3: EARN SNOW",
	enter = function() ctx.goal = goalUpgrade(); ctx.collects1 = collects end,
	text = function() return ctx.goal and ("Keep clearing! Earn enough for your first upgrade: " .. ctx.goal.Name .. ".") or "Keep clearing snow!" end,
	progress = function() return ctx.goal and ("Earn Snow:  " .. Format.Abbreviate(math.min(snow(), U.CostOf(ctx.goal))) .. " / " .. Format.Abbreviate(U.CostOf(ctx.goal))) or "" end,
	hint = function() return stuckHint() or "Drive back and forth through the snow - every layer you clear pays Snow." end,
	target = {kind = "world", label = "SNOW", get = function() local f = ctx.field or nearestStarterField(); return f and nearestPointOnField(f) end},
	back = function() if player:GetAttribute("PlowDriving") ~= true and snow() < (ctx.goal and U.CostOf(ctx.goal) or 0) then return "Drive" end end,
	-- genuine clearing (at least a few payouts from the blade), not just a Snow increase from somewhere else
	done = function() return ctx.goal == nil or (snow() >= U.CostOf(ctx.goal) and collects - ctx.collects0 >= 3) end})
S(MAIN, {id = "OpenUpgrades", essential = true, title = "STEP 4: OPEN UPGRADES",
	enter = function() if not ctx.goal then ctx.goal = goalUpgrade() end end,
	text = function() return "You have enough Snow!\nTap UPGRADES at the bottom of your screen." end,
	hint = "The UPGRADES button is at the bottom, in the middle.",
	target = {kind = "ui", label = "UPGRADES", get = function() return pg:FindFirstChild("UpgradesButton", true) end},
	back = function() if ctx.goal and snow() < U.CostOf(ctx.goal) and not owned(ctx.goal.Id) then return "Earn" end end,
	done = function() return upgradesOpen() or (ctx.goal and owned(ctx.goal.Id)) end})
S(MAIN, {id = "Buy", essential = true, title = "STEP 5: BUY AN UPGRADE",
	text = function() return ctx.goal and ("Tap the green " .. ctx.goal.Name:upper() .. " hexagon to buy it:\n" .. (ctx.goal.Text or "") .. " forever!") or "Tap a green hexagon to buy it." end,
	hint = "Green hexagons are upgrades you can afford. Tap the one with the arrow.",
	target = {kind = "ui", label = "BUY", get = function()
		local g = upgradeGui(); local board = g and g:FindFirstChild("MainBoard", true)
		return board and ctx.goal and board:FindFirstChild(ctx.goal.Id) end,
		-- scroll the board so the hexagon is fully on screen before pointing at it
		ensure = function(o)
			local board = o.Parent
			local pos, size = screenRect(o)
			local vp = viewport()
			local dx = (pos.X < 40 and 40 - pos.X) or (pos.X + size.X > vp.X - 40 and vp.X - 40 - pos.X - size.X) or 0
			local dy = (pos.Y < 140 and 140 - pos.Y) or (pos.Y + size.Y > vp.Y - 120 and vp.Y - 120 - pos.Y - size.Y) or 0
			if dx ~= 0 or dy ~= 0 then board.Position = board.Position + UDim2.fromOffset(dx, dy) end
		end},
	back = function()
		if ctx.goal and owned(ctx.goal.Id) then return nil end
		if not upgradesOpen() then return "OpenUpgrades" end
		if ctx.goal and snow() < U.CostOf(ctx.goal) then return "Earn" end
	end,
	done = function() return ctx.goal == nil or owned(ctx.goal.Id) end}) -- Up_<id> is set by UpgradeService on the server
S(MAIN, {id = "Close", essential = true, title = "BOUGHT!",
	enter = function() flashText("\u{2714} " .. (ctx.goal and ctx.goal.Name or "Upgrade") .. " bought!") end,
	text = function() return (ctx.goal and ctx.goal.Text or "Your plow earns more") .. "! Tap X to close the menu." end,
	hint = "The red X is in the top-right corner of the upgrade screen.",
	target = {kind = "ui", label = "CLOSE", get = function() local g = upgradeGui(); return g and g:FindFirstChild("Close", true) end},
	done = function() return not upgradesOpen() end})
S(MAIN, {id = "Try", essential = true, title = "STEP 6: TRY IT",
	enter = function() ctx.collects2 = collects end,
	text = function() return "Clear more snow - you earn more now!" end,
	hint = function() return player:GetAttribute("PlowDriving") and "Drive into the snow again." or "Tap DRIVE, then drive into the snow." end,
	target = {kind = "world", label = "SNOW", get = function() local f = ctx.field or nearestStarterField(); return f and nearestPointOnField(f) end},
	done = function() return collects - ctx.collects2 >= 3 end})
S(MAIN, {id = "Done", essential = false, title = "GREAT JOB!",
	enter = function() ctx.okAt = os.clock() + 6 end,
	text = function()
		local n = goalUpgrade()
		return "You've got it! Clear snow, earn Snow, upgrade.\nNext goal: " .. (n and (n.Name .. " (\u{2744} " .. Format.Abbreviate(U.CostOf(n)) .. ")") or "unlock the next area!")
	end, okButton = true,
	done = function() return ctx.ok or os.clock() > (ctx.okAt or 0) end})

-- GARAGE lesson
S(GARAGE, {id = "Intro", essential = false, title = "NEW: THE GARAGE",
	text = function() return "Get better plow parts in the GARAGE!\nRolling shows a part for sale - you choose to buy it." end, okButton = true,
	done = function() return ctx.ok end})
S(GARAGE, {id = "Open", essential = true, title = "GARAGE 1: GO THERE",
	text = function() return "Tap GARAGE on the left to visit your garage." end,
	hint = "The GARAGE button is on the left side of your screen.",
	target = {kind = "ui", label = "GARAGE", get = function() return pg:FindFirstChild("Garage", true) end},
	done = function() return player:GetAttribute("InGarage") == true and player:GetAttribute("GarageBay") ~= nil end})
S(GARAGE, {id = "Bay", essential = true, title = "GARAGE 2: YOUR BAY",
	text = function() return "Follow the marker to YOUR bay (Bay " .. tostring(player:GetAttribute("GarageBay") or "?") .. ")." end,
	hint = function()
		local r, mine = hrp(), myBay()
		local g = workspace:FindFirstChild("PlowGarage")
		if r and g and g:FindFirstChild("Bays") then
			for _, m in ipairs(g.Bays:GetChildren()) do
				if m ~= mine and (m:GetPivot().Position - r.Position).Magnitude < 22 then return "This is another player's bay. Follow the marker to yours." end
			end
		end
		return "Walk towards the glowing marker - it's your bay."
	end,
	target = {kind = "world", label = "YOUR BAY", highlight = false, get = function() local b = myBay(); return b and topOf(b, "Lift") end},
	back = function() if player:GetAttribute("InGarage") ~= true then return "Open" end end,
	done = function() local b, r = myBay(), hrp(); return b and r and (b:GetPivot().Position - r.Position).Magnitude < 22 end}) -- bays are 1.5x larger since 2026-10-06
S(GARAGE, {id = "Roll", essential = true, title = "GARAGE 3: ROLL",
	text = function() return "Walk up to a pedestal and " .. pick("press E", "tap the E button", "press X") .. " to ROLL a part." end,
	hint = "Stand next to the glowing pedestal until the prompt appears.",
	target = {kind = "world", label = "ROLL HERE", highlight = true, get = function()
		local b = myBay(); if not b then return nil end
		for _, k in ipairs({"1", "2", "3"}) do local s = state(); if not (s and s.Offers and s.Offers[k]) then return topOf(b, "Pedestal_" .. k) end end
		return topOf(b, "Pedestal_1") end,
		highlightModel = function() local b = myBay(); if not b then return nil end
			for _, k in ipairs({"1", "2", "3"}) do local s = state(); if not (s and s.Offers and s.Offers[k]) then return b:FindFirstChild("Pedestal_" .. k) end end end},
	back = function() if player:GetAttribute("InGarage") ~= true then return "Open" end end,
	done = function() return #offerKeys() > 0 end})
S(GARAGE, {id = "Card", essential = true, title = "GARAGE 4: IT'S FOR SALE",
	enter = function() local k = offerKeys(); ctx.offerKey = k[1] end,
	text = function()
		if ctx.offerKey == "Reserved" then return "You can afford your RESERVED part now!\n" .. pick("Press E", "Tap E", "Press X") .. " at your reserved shelf to open its card." end
		return "Rolling shows a part FOR SALE - you don't own it yet.\n" .. pick("Press E", "Tap E", "Press X") .. " at that pedestal again to open its card."
	end,
	hint = "Stand at the pedestal with the floating part and use its prompt.",
	target = {kind = "world", label = "OPEN CARD", highlight = true, get = function() local b = myBay(); return b and ctx.offerKey and topOf(b, "Pedestal_" .. ctx.offerKey) end,
		highlightModel = function() local b = myBay(); return b and ctx.offerKey and b:FindFirstChild("Pedestal_" .. ctx.offerKey) end},
	back = function()
		if player:GetAttribute("InGarage") ~= true then return "Open" end
		local s = state()
		if ctx.offerKey == "Reserved" then
			if not (s and s.Reserved) then return "Roll" end
			return nil
		end
		if #offerKeys() == 0 then return "Roll" end
		if ctx.offerKey and not (s and s.Offers and s.Offers[ctx.offerKey]) then ctx.offerKey = offerKeys()[1] end
	end,
	done = function() return Api.CardTarget() ~= nil end})
S(GARAGE, {id = "Decide", essential = true, title = "GARAGE 5: BUY OR RESERVE",
	enter = function()
		local key = Api.CardTarget()
		local s = state()
		local o = s and s.Offers and key and s.Offers[key] or (s and key == "Reserved" and s.Reserved)
		ctx.offer = o and {Part = o.Part, Price = o.Price, Token = o.Token, Key = key} or nil
		ctx.partsBefore = ctx.offer and partCount(ctx.offer.Part) or 0
	end,
	text = function()
		local o = ctx.offer
		local price = o and Format.Abbreviate(o.Price) or "?"
		if o and snow() >= o.Price then return "The card shows the PRICE: \u{2744} " .. price .. ".\nBUY adds it to your collection!" end
		return "Price: \u{2744} " .. price .. " - too much for now?\nRESERVE saves the offer while you earn more Snow."
	end,
	hint = function() return ctx.offer and snow() >= ctx.offer.Price and "Tap the green BUY button on the card." or "Tap the blue RESERVE button on the card." end,
	target = {kind = "ui", label = "", get = function()
		local o = ctx.offer
		if o and snow() >= o.Price then cur.target.label = "BUY"; return cardButton("BuyButton") end
		cur.target.label = "RESERVE"; return cardButton("ReserveButton") end},
	back = function()
		if player:GetAttribute("InGarage") ~= true then return "Open" end
		if Api.CardTarget() == nil and not ctx.bought and not ctx.reserved then return "Card" end
	end,
	done = function()
		local o, s = ctx.offer, state()
		if not o then return true end
		if partCount(o.Part) > ctx.partsBefore then ctx.bought = o.Part; return true end
		if s and s.Reserved and s.Reserved.Token == o.Token and o.Key ~= "Reserved" then ctx.reserved = o; return true end
		-- rerolled from the open card (REROLL / R): follow the new offer so the price, text and BUY/RESERVE pointer stay right
		local key = Api.CardTarget()
		local now = s and key and (key == "Reserved" and s.Reserved or (s.Offers and s.Offers[key]))
		if now and now.Token ~= o.Token then
			ctx.offer = {Part = now.Part, Price = now.Price, Token = now.Token, Key = key}
			ctx.partsBefore = partCount(now.Part)
		end
		return false
	end})
S(GARAGE, {id = "Equip", essential = true, title = "GARAGE 6: EQUIP IT",
	enter = function() if not ctx.bought then ctx.skipTo = ctx.reserved and "Reserved" or "Return" end end,
	text = function()
		local def = ctx.bought and C.Parts[ctx.bought]
		local g = shopGui(); local w = g and g:FindFirstChild("GarageWindow")
		if w and w.Visible then return "Tap EQUIP next to " .. (def and def.Name or "your new part") .. "." end
		return "BUY adds it to your collection - now EQUIP it!\nWalk to the WORKBENCH and " .. pick("press E", "tap E", "press X") .. "."
	end,
	hint = function()
		local g = shopGui(); local w = g and g:FindFirstChild("GarageWindow")
		if w and w.Visible then return "Tap the blue EQUIP button in the list." end
		return "The workbench is the long table inside your bay."
	end,
	target = {kind = "ui", label = "EQUIP", get = function()
		local g = shopGui(); local w = g and g:FindFirstChild("GarageWindow")
		if w and w.Visible then cur.target.kind = "ui"; cur.target.label = "EQUIP"; return w:FindFirstChild("Equip_" .. tostring(ctx.bought), true) end
		cur.target.kind = "world"; cur.target.label = "WORKBENCH"; return nil end,
		worldGet = function() local b = myBay(); return b and topOf(b, "Workbench") end},
	back = function() if player:GetAttribute("InGarage") ~= true then return "Open" end end,
	done = function() local s = state(); local def = ctx.bought and C.Parts[ctx.bought]; return not def or (s and s.Build and s.Build[def.Slot] == ctx.bought) end})
S(GARAGE, {id = "Reserved", essential = false, title = "RESERVED!",
	enter = function() if ctx.reserved then ctx.paused = true else ctx.skipTo = "Return" end end,
	text = function() local o = ctx.reserved; return "RESERVE saved it on your reserved shelf.\nEarn \u{2744} " .. Format.Abbreviate(math.max(0, (o and o.Price or 0) - snow())) .. " more Snow, then come back to BUY it." end,
	okButton = true, done = function() return ctx.ok end})
S(GARAGE, {id = "Return", essential = true, title = "GARAGE 7: BACK TO THE SNOW",
	text = function() return "Walk onto the RETURN portal (" .. pick("press E", "tap E", "press X") .. ") - or tap LOBBY." end,
	hint = "The return portal glows at the end of the plaza.",
	target = {kind = "world", label = "RETURN", highlight = false, get = function() local g = workspace:FindFirstChild("PlowGarage"); return g and topOf(g, "ReturnPad") end},
	done = function() return player:GetAttribute("InGarage") ~= true end})
S(GARAGE, {id = "Drive", essential = true, title = "GARAGE 8: TRY IT",
	text = function() return pick("Press F or click DRIVE", "Tap DRIVE", "Press Y") .. " and try your plow!" end,
	target = {kind = "ui", label = "DRIVE", get = function() local g = pg:FindFirstChild("PlowDriveGui"); return g and g:FindFirstChild("Drive") end},
	done = function() return player:GetAttribute("PlowDriving") == true end})
S(GARAGE, {id = "Done", essential = false, title = "GARAGE LESSON DONE!",
	enter = function() ctx.okAt = os.clock() + 6 end,
	text = function() return "Blades, engines, wheels and BODIES: roll, buy, reserve and equip any time.\nBetter parts clear snow faster - bodies add a little Snow per tile!" end, okButton = true, -- task 7
	done = function() return ctx.ok or os.clock() > (ctx.okAt or 0) end})

--------------------------------------------------
-- runner
--------------------------------------------------
local run = {lesson = nil, step = nil, gen = 0, t0 = 0, hints = 0, startedAt = 0}
local timings = {}
flashText = function(t)
	flash.Text, flash.Visible = t, true
	flash.TextTransparency = 0
	task.delay(1.6, function() if flash.Text == t then flash.Visible = false end end)
end
-- progress reports go out one at a time (PlowService rate-limits each player's requests) and are retried until accepted
local outbox, sending = {}, false
local function report(lessonName, stepId, status, secs, hints, index)
	table.insert(outbox, {lessonName, stepId, {Status = status, Secs = secs, Hints = hints, Index = index}})
	if sending then return end
	sending = true
	task.spawn(function()
		while #outbox > 0 do
			local m = outbox[1]
			local tries = 0
			repeat
				task.wait(0.15)
				tries += 1
			until call("TutorialProgress", m[1], m[2], m[3]).ok or tries >= 8
			table.remove(outbox, 1)
		end
		sending = false
	end)
end
local function suppress(on)
	if not on and player:GetAttribute("InArenaIsland") == true then return end -- the Bumper Arena keeps events quiet while you're there
	player:SetAttribute("SuppressEvents", on and true or nil)
end
local function stopLesson()
	run.gen += 1
	run.lesson, run.step = nil, nil
	cur.target = nil
	card.Visible = false
	nextB.Visible = false
	clearWorld()
	suppress(false)
end
local function showStep(step)
	stepL.Text = step.title or ""
	mainL.Text = step.text()
	progL.Text = step.progress and step.progress() or ""
	hintL.Text = ""
	nextB.Visible = step.okButton == true
	progL.Visible = not nextB.Visible
	cardScale.Scale = 0.86
	TweenService:Create(cardScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
	local t = step.target
	if t then
		cur.target = {kind = t.kind, label = t.label, get = t.get, ensure = t.ensure, highlight = t.highlight, highlightModel = t.highlightModel}
		if t.worldGet then
			-- a step that switches between a world target and a UI target (workbench -> EQUIP button)
			local uiGet = t.get
			cur.target.get = function()
				local o = uiGet()
				if cur.target.kind == "world" then return t.worldGet() end
				return o
			end
		end
	else
		cur.target = nil
	end
	cur.missingSince = nil
	card.Visible = true
end
local function runLesson(list, lessonName, startId)
	stopLesson()
	run.gen += 1
	local gen = run.gen
	run.lesson = lessonName
	ctx = {}
	run.startedAt = os.clock()
	local i = startId and list[startId] and list[startId].index or 1
	task.spawn(function()
		while gen == run.gen and i <= #list do
			local step = list[i]
			run.step = step
			ctx.ok = false
			if step.enter then step.enter() end
			if ctx.skipTo then local to = ctx.skipTo; ctx.skipTo = nil; i = list[to].index; continue end
			suppress(step.essential)
			showStep(step)
			run.t0, run.hints = os.clock(), 0
			local lastHint, lastText, lastCollects = os.clock(), nil, collects
			local moved
			while gen == run.gen do
				if step.done() then break end
				local back = step.back and step.back()
				if back and list[back] then moved = back; break end
				-- live text (input changes, counters) + a specific hint after ~10 s without progress + waiting messages
				local txt = step.text()
				if txt ~= lastText then mainL.Text = txt; lastText = txt end
				progL.Text = step.progress and step.progress() or ""
				if collects ~= lastCollects then lastCollects = collects; lastHint = os.clock() end -- real clearing counts as progress
				local missing = cur.missingSince and os.clock() - cur.missingSince > 2.5
				if missing then
					hintL.Text = "Waiting for " .. (cur.target and cur.target.label ~= "" and cur.target.label or "the next button") .. " to appear..."
				elseif step.hint and os.clock() - lastHint > HINT_AFTER then
					hintL.Text = "\u{1F4A1} " .. (type(step.hint) == "function" and step.hint() or step.hint)
					run.hints += 1
					lastHint = os.clock()
				end
				task.wait(0.15)
			end
			if gen ~= run.gen then return end
			local secs = os.clock() - run.t0
			table.insert(timings, {lesson = lessonName, step = step.id, secs = math.floor(secs * 10) / 10, hints = run.hints})
			if moved then
				report(lessonName, step.id .. "_back", nil, secs, run.hints, nil)
				i = list[moved].index
			else
				report(lessonName, step.id, nil, secs, run.hints, step.index + (lessonName == "Garage" and 20 or 0))
				if step.id ~= "Intro" and step.id ~= "Done" and step.essential then flashText("\u{2714} Nice!") end
				i += 1
				if ctx.paused then break end
			end
		end
		if gen ~= run.gen then return end
		local status = ctx.paused and "reserved" or "done"
		report(lessonName, "Finish", status, os.clock() - run.startedAt, nil, nil)
		if lessonName == "Garage" and ctx.paused then ctx.resumePrice = ctx.reserved and ctx.reserved.Price end
		local resume = ctx.resumePrice
		stopLesson()
		helpPill.Visible = true
		if lessonName == "Main" then
			task.wait(2)
			if run.lesson == nil then runLesson(GARAGE, "Garage") end
		elseif resume then
			-- resume the purchase lesson once the reserved part is affordable (tracked separately: reserving is not buying)
			task.spawn(function()
				local myGen = run.gen
				while run.gen == myGen and run.lesson == nil do
					local s = state()
					if not (s and s.Reserved) then return end
					if snow() >= (s.Reserved.Price or math.huge) then
						flashText("You can afford your reserved part!")
						runLesson(GARAGE, "Garage", "Open")
						return
					end
					task.wait(1)
				end
			end)
		end
	end)
end
-- resuming from the reserved shelf: the Card step targets the reserved shelf when the reserve exists and the offers are empty
GARAGE.Card.enter = function()
	local k = offerKeys()
	local s = state()
	if s and s.Reserved and s.Reserved.Price and snow() >= s.Reserved.Price then ctx.offerKey = "Reserved" else ctx.offerKey = k[1] end
end
GARAGE.Roll.done = function() local s = state(); return #offerKeys() > 0 or (s and s.Reserved and snow() >= (s.Reserved.Price or math.huge)) end

nextB.Activated:Connect(function() ctx.ok = true end)
helpB.Activated:Connect(function()
	local step = run.step
	if not step then return end
	showStep(step) -- repeat the instruction and restore its guidance
	hintL.Text = step.hint and ("\u{1F4A1} " .. (type(step.hint) == "function" and step.hint() or step.hint)) or ""
end)
local skipArmed = 0
skipB.Activated:Connect(function()
	if os.clock() > skipArmed then
		skipArmed = os.clock() + 3; skipText.Text = "SURE?"
		task.delay(3.05, function() if os.clock() > skipArmed then skipText.Text = "SKIP" end end)
		return
	end
	skipArmed = 0; skipText.Text = "SKIP"
	local lesson = run.lesson
	stopLesson()
	-- SKIP = skip the remaining lessons (both); replay any time with ? HELP
	if lesson == "Main" then report("Main", "Skip", "skipped", nil, nil, nil) end
	report("Garage", "Skip", "skipped", nil, nil, nil)
	helpPill.Visible = true
end)
helpPill.Activated:Connect(function() helpMenu.Visible = not helpMenu.Visible end)
closeMenuB.Activated:Connect(function() helpMenu.Visible = false end)
replayMainB.Activated:Connect(function() helpMenu.Visible = false; report("Main", "Replay", "replay", nil, nil, nil); runLesson(MAIN, "Main") end)
replayGarageB.Activated:Connect(function() helpMenu.Visible = false; report("Garage", "Replay", "replay", nil, nil, nil); runLesson(GARAGE, "Garage") end)

--------------------------------------------------
-- start: new players get the full introduction; earlier tutorial players get a short contextual upgrade hint
--------------------------------------------------
local function legacyHint()
	local g = goalUpgrade()
	if not g or next(ownedSet()) ~= nil then return end
	local step = {id = "LegacyUpgrade", essential = false, title = "TIP",
		text = function() return "Spend your Snow on UPGRADES to earn even more!" end,
		target = {kind = "ui", label = "UPGRADES", get = function() return pg:FindFirstChild("UpgradesButton", true) end}}
	run.gen += 1
	local gen = run.gen
	showStep(step)
	task.spawn(function()
		local t0 = os.clock()
		while gen == run.gen and not upgradesOpen() and os.clock() - t0 < 25 do task.wait(0.2) end
		if gen == run.gen then cur.target = nil; card.Visible = false end
	end)
end
local function start()
	if not (function()
		local t0 = os.clock()
		while os.clock() - t0 < 90 do
			if player.Character and player:FindFirstChild("leaderstats") and player:GetAttribute("LoadingReady") == true
				and player:GetAttribute("LoadingScreenActive") ~= true and player:GetAttribute("IntroActive") ~= true then return true end
			task.wait(0.25)
		end
	end)() then return end
	local r
	for _ = 1, 20 do
		local res = call("State")
		if res.state then r = res.state break end
		task.wait(0.5)
	end
	if not r then return end
	local tut = type(r.Tutorial) == "table" and r.Tutorial or {}
	helpPill.Visible = true
	if not r.TutorialDone then
		runLesson(MAIN, "Main")
	elseif not tut.Main then
		report("Main", "Legacy", "legacy", nil, nil, nil)
		legacyHint()
	elseif tut.Main ~= "skipped" and tut.Garage == nil then
		runLesson(GARAGE, "Garage")
	elseif tut.Garage == "reserved" then
		local s = state()
		if s and s.Reserved then
			task.spawn(function()
				while run.lesson == nil do
					local st = state()
					if not (st and st.Reserved) then return end
					if snow() >= (st.Reserved.Price or math.huge) then runLesson(GARAGE, "Garage", "Open") return end
					task.wait(1)
				end
			end)
		end
	end
end
-- 2026-10-05 (arena): the lesson pauses on the Bumper Arena island and resumes at the same step when you leave
local pausedLesson
player:GetAttributeChangedSignal("InArenaIsland"):Connect(function()
	if player:GetAttribute("InArenaIsland") == true then
		if run.lesson and run.step then pausedLesson = {name = run.lesson, step = run.step.id}; stopLesson() end
		helpPill.Visible = false; helpMenu.Visible = false
	else
		helpPill.Visible = true
		local pl = pausedLesson
		pausedLesson = nil
		if pl then task.delay(1, function() if not run.lesson then runLesson(pl.name == "Garage" and GARAGE or MAIN, pl.name, pl.step) end end) end
	end
end)
event.OnClientEvent:Connect(function(kind)
	if kind ~= "TutorialReset" then return end -- admin "restart tutorial"
	stopLesson()
	task.defer(runLesson, MAIN, "Main")
end)
UIS.LastInputTypeChanged:Connect(function() if run.step then mainL.Text = run.step.text() end end)
task.spawn(start)

-- Studio-only debug controls (isolated BalanceTestMode sessions): restart / inspect a step without touching real progress
if RunService:IsStudio() then
	local dbg = mk("BindableFunction", {Name = "TutorialDebug"}, sg)
	dbg.OnInvoke = function(op, lesson, stepId)
		if op == "State" then
			return {lesson = run.lesson, step = run.step and run.step.id, timings = timings, target = cur.target and cur.target.label, missing = cur.missingSince ~= nil,
				card = card.Visible and mainL.Text or nil, hint = hintL.Text, suppress = player:GetAttribute("SuppressEvents")}
		elseif op == "Start" then
			if player:GetAttribute("BalanceTestSession") ~= true then return "BalanceTestMode only" end
			runLesson(lesson == "Garage" and GARAGE or MAIN, lesson == "Garage" and "Garage" or "Main", stepId)
			return "started"
		elseif op == "Boot" then -- re-run the join-time decision (new / legacy / garage / reserved) against the current server record
			if player:GetAttribute("BalanceTestSession") ~= true then return "BalanceTestMode only" end
			stopLesson(); task.spawn(start)
			return "booted"
		elseif op == "Stop" then stopLesson(); return "stopped" end
	end
end
