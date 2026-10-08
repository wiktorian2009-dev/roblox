-- BiomeLighting (client, ReplicatedFirst) - lighting pass 2026-10-01.
-- Gives every area its own lighting and blends smoothly when walking, teleporting or respawning.
-- Edit values and zones in the Profiles module under this script.
-- Cutscene-safe: holds the current area while IntroPlaying is set, and never touches camera effects
-- (RareDropBlur) or other ColorCorrections (the intro's ArrivalColor). Writes Lighting only while blending.
-- Pre-overhaul backup: ServerStorage.LightingBackup_20261001.
-- Studio-only test hooks (LocalPlayer or Workspace attributes): LightingSnap=true finishes blends instantly;
-- LightingProbe="camera" follows the camera instead of the character.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Config = require(script:WaitForChild("Profiles"))
local player = Players.LocalPlayer
local IS_STUDIO = RunService:IsStudio()
local function studioHook(name) -- Studio-only test hooks; never read in live servers
	return IS_STUDIO and (player:GetAttribute(name) or workspace:GetAttribute(name)) or nil
end

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local LIGHTING_KEYS = {
	"Brightness", "ExposureCompensation", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom",
	"EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ShadowSoftness",
}
local GROUP_KEYS = {
	Atmosphere = {"Density", "Offset", "Color", "Decay", "Glare", "Haze"},
	Bloom = {"Intensity", "Size", "Threshold"},
	SunRays = {"Intensity", "Spread"},
	Grade = {"Brightness", "Contrast", "Saturation", "TintColor"},
}

local fx = {L = Lighting}
local function pick(name, class)
	local named = Lighting:FindFirstChild(name)
	if named and named:IsA(class) then
		return named
	end
	return Lighting:FindFirstChildOfClass(class)
end
local function resolve()
	fx.Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	fx.Bloom = pick("Bloom", "BloomEffect")
	fx.SunRays = pick("SunRays", "SunRaysEffect")
	local grade = Lighting:FindFirstChild("BiomeGrade")
	if not (grade and grade:IsA("ColorCorrectionEffect")) then
		grade = Instance.new("ColorCorrectionEffect")
		grade.Name = "BiomeGrade"
		grade.Parent = Lighting
	end
	fx.Grade = grade
end
Lighting:WaitForChild("BiomeGrade", 5)
resolve()

local function flatten(profile)
	local flat = {}
	for _, key in ipairs(LIGHTING_KEYS) do
		if profile[key] ~= nil then
			flat["L." .. key] = profile[key]
		end
	end
	for group, keys in pairs(GROUP_KEYS) do
		local values = profile[group]
		if values then
			for _, key in ipairs(keys) do
				if values[key] ~= nil then
					flat[group .. "." .. key] = values[key]
				end
			end
		end
	end
	return flat
end

local profiles = {}
for name, profile in pairs(Config.Profiles) do
	profiles[name] = flatten(profile)
end

local splitCache = {}
local function split(key)
	local cached = splitCache[key]
	if not cached then
		local group, prop = string.match(key, "^(%w+)%.(.+)$")
		cached = {group, prop}
		splitCache[key] = cached
	end
	return cached[1], cached[2]
end

local function write(values)
	for key, value in pairs(values) do
		local group, prop = split(key)
		local inst = fx[group]
		if inst and inst.Parent then
			inst[prop] = value
		end
	end
end

local function lerp(a, b, t)
	if type(a) == "number" then
		return a + (b - a) * t
	end
	return a:Lerp(b, t)
end

local function zoneAt(pos)
	local x, z = pos.X, pos.Z
	for _, zone in ipairs(Config.Zones) do
		if zone.Radius then
			local dx, dz = x - zone.Center.X, z - zone.Center.Y
			if dx * dx + dz * dz <= zone.Radius * zone.Radius then
				return zone.Name
			end
		elseif x >= zone.Min.X and x < zone.Max.X and z >= zone.Min.Y and z < zone.Max.Y then
			return zone.Name
		end
	end
	return nil
end

local function probe()
	local camera = workspace.CurrentCamera
	if camera and (camera.CameraType == Enum.CameraType.Scriptable
		or studioHook("LightingProbe") == "camera") then
		return camera.CFrame.Position
	end
	local character = player.Character
	local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
	if root then
		return root.Position
	end
	return camera and camera.Focus.Position
end

local current, from = {}, {}
local targetZone = Config.Default
local blendStart, blendDuration = 0, 0
local settled = true
local candidate, candidateSince = nil, 0
local lastProbe
local forceJump = false

local function startBlend(zone, duration)
	targetZone = zone
	for key in pairs(profiles[zone]) do
		from[key] = current[key]
	end
	blendStart, blendDuration = os.clock(), duration
	settled = false
	player:SetAttribute("LightingZone", zone)
end

-- On join, snap straight to the area the player starts in (no blend from the defaults).
do
	local pos = probe()
	local zone = pos and zoneAt(pos)
	targetZone = (zone and profiles[zone]) and zone or Config.Default
	for key, value in pairs(profiles[targetZone]) do
		current[key] = value
	end
	write(current)
	player:SetAttribute("LightingZone", targetZone)
end

player.CharacterAdded:Connect(function()
	forceJump = true
end)
Lighting.ChildAdded:Connect(function(child)
	if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("SunRaysEffect") then
		task.defer(resolve)
	end
end)

RunService.PreRender:Connect(function()
	local pos = probe()
	if pos and not player:GetAttribute("IntroPlaying") then
		local jumped = forceJump or (lastProbe ~= nil and (pos - lastProbe).Magnitude > Config.JumpDistance)
		forceJump = false
		local zone = zoneAt(pos)
		if zone and profiles[zone] and zone ~= targetZone then
			if zone ~= candidate then
				candidate, candidateSince = zone, os.clock()
			end
			if jumped or os.clock() - candidateSince >= Config.Dwell then
				candidate = nil
				startBlend(zone, if jumped then Config.JumpBlend else Config.WalkBlend)
			end
		elseif zone == targetZone then
			candidate = nil
		end
	end
	if pos then
		lastProbe = pos
	end
	if settled then
		return
	end
	local k = 1
	if blendDuration > 0 and not studioHook("LightingSnap") then
		k = math.clamp((os.clock() - blendStart) / blendDuration, 0, 1)
	end
	local eased = k * k * (3 - 2 * k)
	for key, value in pairs(profiles[targetZone]) do
		local start = from[key]
		current[key] = if start ~= nil then lerp(start, value, eased) else value
	end
	write(current)
	if k >= 1 then
		settled = true
	end
end)
