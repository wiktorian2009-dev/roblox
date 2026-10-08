-- travel_points.luau (2026-10-05, Claude): rebuilds workspace.TravelPoints (run in Studio Edit via execute_luau / command bar).
-- One invisible, non-colliding, anchored 4x1x4 part per destination id, facing the stage's snow field.
-- World 1 stages: a flat (normal > 0.95), dry ground point 10-18 studs outside one of the stage's SnowFieldZones boxes, with a clear
-- 9x6x14 box (room for any plow), nearest the stage's StagePaywall_Model (so it is inside the unlocked area, right behind the gate).
-- World 2 stages: same search, nearest the previous stage's fields (the side the bridge arrives from).
-- Fixed markers: Lobby = FrostfallVillage.MainArrival, Starter = FrostfallVillage.FieldArrival, Portal = WorldTravel.World1Arrival,
-- Sakura = WorldTravel.World2Arrival. Attribute World = 1 / 2.
local S = require(game.ReplicatedStorage.StageConfig)
local zones = workspace.SnowFieldZones
local byStage = {}
for _, z in ipairs(zones:GetChildren()) do local st = z:GetAttribute("Stage"); if st and z.Name ~= "FrostfallSnowYard" then byStage[st] = byStage[st] or {}; table.insert(byStage[st], z) end end
local entrance = {}
for _, d in ipairs(workspace:GetChildren()) do if d.Name == "StagePaywall_Model" and d:GetAttribute("Stage") then entrance[d:GetAttribute("Stage")] = d:GetPivot().Position end end
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {zones}; rp.RespectCanCollide = true
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {zones}
local function center(list) local s = Vector3.zero; for _, z in ipairs(list) do s += z.Position end return s / #list end
local pts, prevCenter = {}, nil
for _, st in ipairs(S.Order) do
	local list = byStage[st.Id]
	if list and st.Id ~= "Starter" then
		local ref = entrance[st.Id] or prevCenter or center(list)
		local best, bestD
		for _, z in ipairs(list) do
			local hx, hz = z.Size.X / 2, z.Size.Z / 2
			for _, off in ipairs({10, 14, 18}) do
				for t = -0.8, 0.8, 0.2 do
					for _, side in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
						local p = side[1] ~= 0 and z.Position + Vector3.new(side[1] * (hx + off), 0, t * hz) or z.Position + Vector3.new(t * hx, 0, side[2] * (hz + off))
						local hit = workspace:Raycast(p + Vector3.new(0, 40, 0), Vector3.new(0, -90, 0), rp)
						if hit and hit.Normal.Y > 0.95 and math.abs(hit.Position.Y - z.Position.Y) < 6 and hit.Material ~= Enum.Material.Water then
							local look = Vector3.new(z.Position.X - hit.Position.X, 0, z.Position.Z - hit.Position.Z).Unit
							local cf = CFrame.lookAt(hit.Position, hit.Position + look)
							local clear = true
							for _, part in ipairs(workspace:GetPartBoundsInBox(cf * CFrame.new(0, 3.4, -3), Vector3.new(9, 6, 14), op)) do if part.CanCollide then clear = false break end end
							if clear then
								local dist = (Vector3.new(hit.Position.X, 0, hit.Position.Z) - Vector3.new(ref.X, 0, ref.Z)).Magnitude
								if not bestD or dist < bestD then best, bestD = cf, dist end
							end
						end
					end
				end
			end
		end
		pts[st.Id] = best
		prevCenter = center(list)
	end
end
local old = workspace:FindFirstChild("TravelPoints"); if old then old:Destroy() end
local f = Instance.new("Folder"); f.Name = "TravelPoints"
local function add(id, cf, world)
	local p = Instance.new("Part")
	p.Name = id; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Transparency = 1
	p.Size = Vector3.new(4, 1, 4); p.CFrame = cf + Vector3.new(0, 0.5, 0)
	p:SetAttribute("World", world)
	p.Parent = f
end
local fv, wt = workspace.FrostfallVillage, workspace.WorldTravel
local main = fv.MainArrival.Value
add("Lobby", CFrame.lookAt(main.Position, main.Position + Vector3.new(1, 0, 0)), 1)
local fa = fv.FieldArrival.Value
add("Starter", CFrame.lookAt(fa.Position - Vector3.new(0, 3, 0), Vector3.new(35, fa.Position.Y - 3, -282)), 1)
for _, id in ipairs({"Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero"}) do add(id, pts[id], 1) end
local w1 = wt.World1Arrival.Position - Vector3.new(0, 2, 0)
add("Portal", CFrame.lookAt(w1, w1 + Vector3.new(1, 0, 0)), 1)
local w2 = wt.World2Arrival.Position - Vector3.new(0, 2, 0)
add("Sakura", CFrame.lookAt(w2, w2 + Vector3.new(1, 0, 0)), 2)
for _, id in ipairs({"Candy", "Atlantis", "Toybox", "Clockwork", "Cloud", "Cosmic"}) do add(id, pts[id], 2) end
f.Parent = workspace
