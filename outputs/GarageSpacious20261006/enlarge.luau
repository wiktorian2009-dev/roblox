-- enlarge.luau (Claude, 2026-10-06): makes the shared garage ~1.5x more spacious (Studio Edit, run once).
-- Horizontal scale K around PlowGarage.LobbyRoot: floors / walls / island / street tiles / turntables are STRETCHED (size + position),
-- props (pedestals, workbench, lamps, landmark, portals, trees ...) keep their size and only MOVE. Bay shells/colliders get KY height.
-- Same transform for ServerStorage.SharedGarageTemplates (overflow bays) and workspace.ArenaPortals.GarageArenaPortal.
-- Idempotent guard: PlowGarage:GetAttribute("SpaciousScale").
local K, KY = 1.5, 1.25
local g = workspace.PlowGarage
if g:GetAttribute("SpaciousScale") then return "already enlarged x" .. tostring(g:GetAttribute("SpaciousScale")) end
local O = g.LobbyRoot.CFrame -- world frame of the plaza centre
local MINSTRETCH = 10 -- parts at least this wide (X or Z) are structural and get stretched; smaller ones only move

local function snap(v) return Vector3.new(math.floor(v.X + 0.5), v.Y, math.floor(v.Z + 0.5)) end
-- move-only: a small part keeps its size; its position is scaled about F (rounded anchor so clustered sub-parts stay together)
local function movePart(p, F, ky)
	local L = F:ToObjectSpace(p.CFrame)
	local a = snap(L.Position)
	local d = Vector3.new(a.X * (K - 1), L.Y * ((ky or 1) - 1), a.Z * (K - 1))
	p.CFrame = F * (CFrame.new(d) * L)
end
local function stretchPart(p, F, ky)
	ky = ky or 1
	local L = F:ToObjectSpace(p.CFrame)
	local pos = L.Position
	local np = Vector3.new(pos.X * K, pos.Y * ky, pos.Z * K)
	local s = p.Size
	p.Size = Vector3.new(s.X * K, s.Y * ky, s.Z * K) -- yaw-only parts (0 / 90 / 180 deg): local X/Z are horizontal
	p.CFrame = F * (CFrame.new(np) * (L - pos))
end
local function structural(container, F, ky)
	for _, p in ipairs(container:GetDescendants()) do
		if p:IsA("BasePart") then
			if math.max(p.Size.X, p.Size.Z) >= MINSTRETCH then stretchPart(p, F, ky) else movePart(p, F, ky) end
		end
	end
end
local function moveModel(m, F, ky)
	local cf = m:IsA("BasePart") and m.CFrame or m:GetPivot()
	local L = F:ToObjectSpace(cf)
	local np = Vector3.new(L.X * K, L.Y * (ky or 1), L.Z * K)
	local new = F * (CFrame.new(np) * (L - L.Position))
	if m:IsA("BasePart") then m.CFrame = new else m:PivotTo(new) end
end
local function bay(m)
	local F = m:GetPivot()
	for _, c in ipairs(m:GetChildren()) do
		local n = c.Name
		if n == "Shell" or n == "Colliders" then structural(c, F, KY)
		elseif n == "Lift" then structural(c, F, 1)
		elseif n:match("^Pedestal_") or n == "Workbench" then moveModel(c, F, 1)
		elseif n == "BayRoot" then -- origin, unchanged
		elseif c:IsA("BasePart") or c:IsA("Model") then moveModel(c, F, KY) end -- Lamp1/2, SignPanel, OwnerAnchor
	end
end

local log = {}
-- bays: move each bay's pivot out, then rebuild its interior in its own frame
for _, m in ipairs(g.Bays:GetChildren()) do
	moveModel(m, O, 1)
	bay(m)
	table.insert(log, m.Name .. " -> " .. tostring(m:GetPivot().Position))
end
-- garage level
structural(g.Island, O, 1)
for _, p in ipairs(g.Colliders:GetChildren()) do
	if p.Name == "LandmarkCore" then moveModel(p, O, 1) else stretchPart(p, O, 1) end
end
for _, c in ipairs(g.Plaza:GetChildren()) do
	if c.Name:match("^Street") then structural(c, O, 1) else moveModel(c, O, 1) end -- Landmark, Portal: props
end
for _, c in ipairs(g.Props:GetChildren()) do moveModel(c, O, 1) end
for _, n in ipairs({"Arrival", "ReturnPad", "OverflowOrigin"}) do local c = g:FindFirstChild(n); if c then moveModel(c, O, 1) end end
local ap = workspace:FindFirstChild("ArenaPortals") and workspace.ArenaPortals:FindFirstChild("GarageArenaPortal")
if ap then moveModel(ap, O, 1); table.insert(log, "GarageArenaPortal -> " .. tostring(ap:GetPivot().Position)) end
-- overflow templates (cloned at runtime by PlowService.overflowBay; spacing comes from OverflowOrigin attributes)
local tpl = game.ServerStorage:FindFirstChild("SharedGarageTemplates")
if tpl then
	for _, c in ipairs(tpl:GetChildren()) do
		if c.Name == "Bay" then bay(c)
		elseif c:GetAttribute("OverflowPiece") then
			structural(c, c:GetPivot(), 1)
			local off = c:GetAttribute("Offset")
			if typeof(off) == "CFrame" then c:SetAttribute("Offset", CFrame.new(off.X * K, off.Y, off.Z * K) * (off - off.Position)) end
		end
	end
end
g.OverflowOrigin:SetAttribute("ColStep", 32 * K)
g.OverflowOrigin:SetAttribute("RowOffset", 30 * K)
g:SetAttribute("SpaciousScale", K)
return table.concat(log, "\n")
