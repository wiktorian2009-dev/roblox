-- studio_import_and_place.luau (Studio, Edit) - how the Snowplow Bumper Arena art was imported and placed (2026-10-05).
-- 1) insert the 3 packs (insert_asset) into ServerStorage.ArenaImports as AR_Arena / AR_Island / AR_Props
--    (asset ids: AR_Arena 100827441085085, AR_Island 136915797198812, AR_Props 94020218596030 - see manifest.json)
-- 2) run PART A (post-process into ServerStorage.ArenaBuilt), 3) run build_colliders.luau, 4) run PART B (placement).

-- ===================== PART A: post-process =====================
local AT = {ArenaFloor={0,0,0}, WallRing={0,0,0}, ExitGates={0,0,0}, Stands={0,0,0}, Jumbotron={0,0,0}, LightTowers={0,0,0}, Island={0,0,0}, PracticeRing={0,0,0},
	Target={24,0,0}, Bumper={48,0,0}, Portal={72,0,0}, Trophy={96,0,0}, Lamp={120,0,0}, Banner={144,0,0}, SnowBank={168,0,0}}
local MATS = {SP="SmoothPlastic",NE="Neon",GL="Glass",ME="Metal",FO="Foil",WO="Wood",IC="Ice",SA="Sand",GR="Grass",CO="Concrete",PL="Plastic",MA="Marble",SL="Slate",FA="Fabric",PE="Pebble",BR="Brick",CB="Cobblestone",GN="Granite",WP="WoodPlanks",SN="Snow",LI="Limestone",SS="Sandstone",RO="Rock"}
local function postProcess()
	local imp = game.ServerStorage.ArenaImports
	local out = game.ServerStorage:FindFirstChild("ArenaBuilt") or Instance.new("Folder"); out.Name = "ArenaBuilt"; out.Parent = game.ServerStorage
	local made = 0
	for _, pn in ipairs({"AR_Arena", "AR_Island", "AR_Props"}) do
		local pk = imp[pn]
		for _, d in ipairs(pk:GetDescendants()) do if d:IsA("PackageLink") then d:Destroy() end end
		local ref = pk:FindFirstChild("Ref__Origin__FF00FFNE", true)
		local pcf = ref.CFrame
		local groups = {}
		for _, d in ipairs(pk:GetDescendants()) do
			if d:IsA("BasePart") and d ~= ref then
				local mdl, part, code = d.Name:match("^(.-)__(.-)__(.+)$")
				if mdl and AT[mdl] then groups[mdl] = groups[mdl] or {}; table.insert(groups[mdl], {d, part, code}) end
			end
		end
		for mdl, list in pairs(groups) do
			local at = AT[mdl]
			local o = out:FindFirstChild("AR_" .. mdl); if o then o:Destroy() end
			local m = Instance.new("Model"); m.Name = "AR_" .. mdl
			local root = Instance.new("Part"); root.Name = "Root"; root.Size = Vector3.new(0.2, 0.2, 0.2); root.Transparency = 1
			root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
			root.CFrame = pcf * CFrame.new(-at[1], at[3], at[2]); root.Parent = m
			for _, e in ipairs(list) do
				local d, part, code = e[1], e[2], e[3]
				local hex, mat, tr = code:sub(1, 6), code:sub(7, 8), code:match("T(%d+)$")
				d.Color = Color3.fromHex(hex); d.Material = Enum.Material[MATS[mat] or "SmoothPlastic"]
				d.Transparency = tr and tonumber(tr) / 100 or 0
				d.Name = part; d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false
				d.Parent = m
			end
			m.PrimaryPart = root
			m:PivotTo(CFrame.new(0, -2000, made * 400))
			m.Parent = out
			made += 1
		end
	end
	return made
end

-- ===================== PART B: placement (art, portals, signs, lights, decor) =====================
-- Visual art is non-colliding; collision is the simple geometry from build_colliders.luau (made invisible except walkway/plaza/ramp).
-- Exact code that was run is kept in the session transcript; summary of what it does:
--   * Art: AR_ArenaFloor, AR_WallRing, AR_ExitGates, AR_Stands, AR_Jumbotron, AR_LightTowers, AR_Island at ArenaConfig.Center;
--     AR_PracticeRing at ArenaConfig.Practice.Center (all keep the Root's import rotation).
--   * Colliders: Transparency 1, except Walkway / PlazaFloor / StandsRamp (Slate, light snow colour).
--   * Portals (AR_Portal + ProximityPrompt "ArenaPrompt" with attribute ArenaPortal): workspace.ArenaPortals.LobbyArenaPortal at
--     (-152, 0.2, -258) yaw 0, workspace.ArenaPortals.GarageArenaPortal at (72, 700, -280) yaw 90 (garage plaza east end),
--     SnowplowArena.Decor.ReturnPortal at (-40, 700, -74) yaw 180 (ArenaPortal = "Return"). PortalPad parts are invisible prompt anchors.
--   * Signs (thin parts + SurfaceGui, Front face): 4x "EXIT" inside + "KNOCKOUT ZONE" outside each gate, PRACTICE RING sign,
--     4 jumbotron screens (attribute ArenaScreen; ArenaHudClient writes timer / leader), trophy plaque, portal boards, entrance sign
--     (Decor.EntranceSign at the ramp foot, z = 34).
--   * Lights: 4 SpotLights (Lights.Flood) on the light towers aimed at the floor; PointLights in the walkway lamps and portal swirls.
--   * Decor: AR_Trophy (-16,700,-50), 8 AR_Lamp along the walkway (x = -40 +- 9.5, z = -30..30), 4 AR_Banner at the plaza corners,
--     6 AR_SnowBank around the plaza and the walkway.
return postProcess
