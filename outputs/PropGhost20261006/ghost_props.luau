-- ghost_props.luau (2026-10-06, Claude) - run in Edit only after wiktor's line. Every decorative prop fully inside a snow field
-- (its centre inside the field box) gets CanCollide + CanQuery off so the plow (and its suspension raycasts) drive through.
-- CanTouch, prompts and scripts are untouched. Kept solid: names with Wall/Gate/Paywall/Fence, W1Edges, Help Yards, garage,
-- arena, travel, floors (top within 0.8 of the field floor), anything reaching the field border.
-- Undo: ServerStorage.PropGhostBackup_20261006 has one ObjectValue per part with attributes OldCollide / OldQuery.
local zones = workspace.SnowFieldZones
local Z = {}
for _, z in ipairs(zones:GetChildren()) do if z:IsA("BasePart") then
	local hx, hz = z.Size.X / 2, z.Size.Z / 2
	if math.abs(math.floor(z.Orientation.Y + 0.5)) % 180 == 90 then hx, hz = hz, hx end
	Z[#Z + 1] = {x = z.Position.X, z = z.Position.Z, hx = hx, hz = hz, y = z.Position.Y - z.Size.Y / 2, st = z:GetAttribute("Stage") or "Starter"}
end end
local skipRoots = {workspace.W1Edges, workspace.ContractYards, workspace:FindFirstChild("SnowplowArena"), workspace:FindFirstChild("PlowGarage"),
	workspace:FindFirstChild("ArenaPortals"), workspace:FindFirstChild("TravelPad"), workspace:FindFirstChild("TravelPoints"), workspace:FindFirstChild("Snowplows"), zones}
local function skipped(p)
	for _, r in ipairs(skipRoots) do if r and p:IsDescendantOf(r) then return true end end
	local m = p:FindFirstAncestorOfClass("Model")
	for _, n in ipairs({"Wall", "Gate", "Paywall", "Fence", "Barrier"}) do if p.Name:find(n) or (m and m.Name:find(n)) then return true end end
	return false
end
local SS = game.ServerStorage
local bk = SS:FindFirstChild("PropGhostBackup_20261006") or Instance.new("Folder"); bk.Name = "PropGhostBackup_20261006"; bk.Parent = SS
local by, n = {}, 0
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("BasePart") and p.CanCollide and not skipped(p) then
		for _, z in ipairs(Z) do
			local ex, ez = p.Size.X / 2, p.Size.Z / 2 -- approx footprint (axis-aligned)
			local dx, dz = math.abs(p.Position.X - z.x), math.abs(p.Position.Z - z.z)
			-- centre inside the field and smaller than the field (props like the Starter igloo stick out past the box edge); boundary
			-- walls are excluded by name above, floors by the height test below
			if dx < z.hx and dz < z.hz and ex < z.hx * 0.6 and ez < z.hz * 0.6 then
				local bot, top = p.Position.Y - p.Size.Y / 2, p.Position.Y + p.Size.Y / 2
				if top > z.y + 0.8 and bot < z.y + 25 then
					local ov = Instance.new("ObjectValue"); ov.Name = p.Name; ov.Value = p
					ov:SetAttribute("OldCollide", p.CanCollide); ov:SetAttribute("OldQuery", p.CanQuery); ov:SetAttribute("Stage", z.st); ov.Parent = bk
					p.CanCollide = false; p.CanQuery = false
					by[z.st] = (by[z.st] or 0) + 1; n += 1
				end
				break
			end
		end
	end
end
local s = {}; for k, v in pairs(by) do s[#s + 1] = k .. "=" .. v end
return "ghosted " .. n .. ": " .. table.concat(s, " ")
-- UNDO: for _, ov in ipairs(game.ServerStorage.PropGhostBackup_20261006:GetChildren()) do if ov.Value then ov.Value.CanCollide = ov:GetAttribute("OldCollide"); ov.Value.CanQuery = ov:GetAttribute("OldQuery") end end
