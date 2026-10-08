-- MachineLocksClient: Pet Fuser and Crafting Machine look deep black and say
-- LOCKED until you own their unlock upgrade (UnlockFuser / UnlockCraft attributes).
-- Visual only; MachineService refuses locked machines on the server.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local MACHINES = {
	{Model = "PetFuser", Attr = "UnlockFuser", Label = "PET FUSER"},
	{Model = "CraftingMachine", Attr = "UnlockCraft", Label = "CRAFTING"},
}
local BLACK = Color3.new(0, 0, 0)
-- "vanta black": black Neon ignores all lighting, so a locked machine is one flat silhouette (no shading, no edges)
local saved = {} -- strong table on purpose: weak Instance keys can be dropped while the part still exists
local function apply(model, label, locked)
	model:SetAttribute("LocalLocked", locked)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Transparency < 1 or (saved[d] and saved[d].T < 1) then
				if not saved[d] then saved[d] = {C = d.Color, M = d.Material, T = d.Transparency, R = d.Reflectance} end
				local s = saved[d]
				if locked then
					d.Color, d.Material, d.Transparency, d.Reflectance = BLACK, Enum.Material.Neon, 0, 0
				else
					d.Color, d.Material, d.Transparency, d.Reflectance = s.C, s.M, s.T, s.R
				end
			end
		elseif d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
			if saved[d] == nil then saved[d] = d.Enabled end
			d.Enabled = (not locked) and saved[d]
		elseif d:IsA("Decal") or d:IsA("Texture") then
			if saved[d] == nil then saved[d] = d.Transparency end
			d.Transparency = locked and 1 or saved[d]
		elseif d:IsA("SurfaceGui") then
			if saved[d] == nil then saved[d] = d.Enabled end
			d.Enabled = (not locked) and saved[d] -- no painted text on the silhouette
		elseif d:IsA("TextLabel") and d:FindFirstAncestorOfClass("BillboardGui") then
			if saved[d] == nil then saved[d] = d.Text end
			d.Text = locked and ("\u{1F512} " .. label) or saved[d] -- the floating sign still says what it is
		elseif d:IsA("ProximityPrompt") then
			if saved[d] == nil then saved[d] = d.ActionText end
			d.ActionText = locked and "Locked" or saved[d]
		end
	end
end
local function setup(def)
	local village = workspace:WaitForChild("FrostfallVillage", 60)
	local model = village and village:WaitForChild(def.Model, 60)
	if not model then return end
	local function refresh() apply(model, def.Label, (tonumber(player:GetAttribute(def.Attr)) or 0) < 1) end
	refresh()
	player:GetAttributeChangedSignal(def.Attr):Connect(refresh)
end
for _, def in ipairs(MACHINES) do task.spawn(setup, def) end
