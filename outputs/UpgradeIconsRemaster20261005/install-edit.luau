-- Execute with the Studio MCP in EDIT only. Re-reads live source and aborts on changed anchors.
assert(game.PlaceId == 94130990350526, "Wrong place")
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before installing permanent upgrade art")
local RS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")
local SS = game:GetService("ServerStorage")
local gui = assert(SG:FindFirstChild("RNGGui"), "RNGGui missing")
local client = assert(gui:FindFirstChild("UpgradeTreeClient"), "UpgradeTreeClient missing")
local bar = assert(gui:FindFirstChild("BottomBar"), "BottomBar missing")
local button = assert(bar:FindFirstChild("UpgradesButton"), "UpgradesButton missing")
local icon = assert(button:FindFirstChild("Icon"), "Main upgrade icon missing")
local previous = client.Source
assert(not string.find(previous, 'WaitForChild("UpgradeIconArt")', 1, true), "UpgradeIconArt already referenced; inspect current install before rerunning")
local patches = {
	{[====[local U = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))]====], [====[local U = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
local IconArt = require(ReplicatedStorage:WaitForChild("UpgradeIconArt"))]====]},
	{[====[local function newTile(id, pos, n, parent)]====], [====[local function newTile(id, pos, n, parent)
	local mappedIcon = IconArt.Resolve(n)]====]},
	{[====[Image = (n and n.Icon) or ""]====], [====[Image = mappedIcon or (n and n.Icon) or ""]====]},
	{[====[if n and n.IconTint then]====], [====[if n and n.IconTint and not mappedIcon then]====]},
	{[====[if n and n.IconRainbow then]====], [====[if n and n.IconRainbow and not mappedIcon then]====]},
	{[====[local hasIcon = (n.Icon or "") ~= ""]====], [====[local hasIcon = (t.icon.Image or "") ~= ""]====]},
}
local changed = previous
for _, patch in ipairs(patches) do
	local startAt, endAt = string.find(changed, patch[1], 1, true)
	assert(startAt, "Patch anchor missing; live source changed: " .. patch[1])
	assert(not string.find(changed, patch[1], endAt + 1, true), "Patch anchor ambiguous: " .. patch[1])
	changed = string.sub(changed, 1, startAt - 1) .. patch[2] .. string.sub(changed, endAt + 1)
end
local artSource = [====[-- Generated transparent upgrade artwork, 2026-10-05.
-- Presentation only: UpgradeConfig continues to own effects, costs, IDs and layout.
local Art = {}
Art.Assets = {
	["blade-width"] = "rbxassetid://91899109454902",
	["blade-width-elite"] = "rbxassetid://86317744514702",
	["clearing-power"] = "rbxassetid://137843092410698",
	["clearing-power-elite"] = "rbxassetid://85709873651022",
	["clearing-speed"] = "rbxassetid://105444832567503",
	["cosmic-offer-luck"] = "rbxassetid://136567550154586",
	["crafting-machine"] = "rbxassetid://136771842476154",
	["egg-discount"] = "rbxassetid://93951851073860",
	["friend-boost"] = "rbxassetid://131132644122801",
	["golden-offer-luck"] = "rbxassetid://130134071535759",
	["offer-cooldown"] = "rbxassetid://107696629451710",
	["offer-luck"] = "rbxassetid://129904870972215",
	["pet-boost"] = "rbxassetid://122642278926582",
	["pet-fuser"] = "rbxassetid://99278963740109",
	["pet-slots"] = "rbxassetid://109116345936565",
	["rainbow-offer-luck"] = "rbxassetid://87488080436539",
	["snow-rewards"] = "rbxassetid://87202382278082",
	["snow-rewards-elite"] = "rbxassetid://118168675188658",
	["upgrades-menu"] = "rbxassetid://106414155892974",
	["walk-speed"] = "rbxassetid://73644820523941",
}
Art.ByUpgrade = {
	["M_Center"] = "rbxassetid://73644820523941",
	["M_Egg1"] = "rbxassetid://93951851073860",
	["M_Egg2"] = "rbxassetid://93951851073860",
	["M_Egg3"] = "rbxassetid://93951851073860",
	["M_Egg4"] = "rbxassetid://93951851073860",
	["M_Equip1"] = "rbxassetid://109116345936565",
	["M_Equip2"] = "rbxassetid://109116345936565",
	["M_Expansion1"] = "rbxassetid://122642278926582",
	["M_Expansion10"] = "rbxassetid://122642278926582",
	["M_Expansion11"] = "rbxassetid://73644820523941",
	["M_Expansion12"] = "rbxassetid://93951851073860",
	["M_Expansion13"] = "rbxassetid://122642278926582",
	["M_Expansion14"] = "rbxassetid://73644820523941",
	["M_Expansion15"] = "rbxassetid://93951851073860",
	["M_Expansion16"] = "rbxassetid://122642278926582",
	["M_Expansion17"] = "rbxassetid://73644820523941",
	["M_Expansion18"] = "rbxassetid://131132644122801",
	["M_Expansion19"] = "rbxassetid://122642278926582",
	["M_Expansion2"] = "rbxassetid://99278963740109",
	["M_Expansion20"] = "rbxassetid://73644820523941",
	["M_Expansion21"] = "rbxassetid://122642278926582",
	["M_Expansion3"] = "rbxassetid://93951851073860",
	["M_Expansion4"] = "rbxassetid://122642278926582",
	["M_Expansion5"] = "rbxassetid://136771842476154",
	["M_Expansion6"] = "rbxassetid://93951851073860",
	["M_Expansion7"] = "rbxassetid://122642278926582",
	["M_Expansion8"] = "rbxassetid://73644820523941",
	["M_Expansion9"] = "rbxassetid://131132644122801",
	["M_Feast"] = "rbxassetid://122642278926582",
	["M_Friend1"] = "rbxassetid://131132644122801",
	["M_Friend2"] = "rbxassetid://131132644122801",
	["M_Pet1"] = "rbxassetid://87202382278082",
	["M_PortalBoots"] = "rbxassetid://73644820523941",
	["M_Sprint"] = "rbxassetid://73644820523941",
	["M_Squad"] = "rbxassetid://131132644122801",
	["M_Walk1"] = "rbxassetid://73644820523941",
	["M_Walk2"] = "rbxassetid://73644820523941",
	["R_Dice1"] = "rbxassetid://107696629451710",
	["R_Dice2"] = "rbxassetid://107696629451710",
	["R_Dice3"] = "rbxassetid://107696629451710",
	["R_Dice4"] = "rbxassetid://87202382278082",
	["R_Dice5"] = "rbxassetid://87202382278082",
	["R_Gold1"] = "rbxassetid://130134071535759",
	["R_Gold2"] = "rbxassetid://130134071535759",
	["R_Gold3"] = "rbxassetid://130134071535759",
	["R_Gold4"] = "rbxassetid://130134071535759",
	["R_Gold5"] = "rbxassetid://130134071535759",
	["R_Gold6"] = "rbxassetid://130134071535759",
	["R_Hyper"] = "rbxassetid://107696629451710",
	["R_Luck1"] = "rbxassetid://129904870972215",
	["R_Luck10"] = "rbxassetid://129904870972215",
	["R_Luck11"] = "rbxassetid://129904870972215",
	["R_Luck12"] = "rbxassetid://129904870972215",
	["R_Luck13"] = "rbxassetid://129904870972215",
	["R_Luck14"] = "rbxassetid://129904870972215",
	["R_Luck15"] = "rbxassetid://129904870972215",
	["R_Luck16"] = "rbxassetid://129904870972215",
	["R_Luck17"] = "rbxassetid://129904870972215",
	["R_Luck18"] = "rbxassetid://129904870972215",
	["R_Luck19"] = "rbxassetid://129904870972215",
	["R_Luck2"] = "rbxassetid://129904870972215",
	["R_Luck20"] = "rbxassetid://136567550154586",
	["R_Luck21"] = "rbxassetid://136567550154586",
	["R_Luck22"] = "rbxassetid://136567550154586",
	["R_Luck3"] = "rbxassetid://129904870972215",
	["R_Luck4"] = "rbxassetid://129904870972215",
	["R_Luck5"] = "rbxassetid://129904870972215",
	["R_Luck6"] = "rbxassetid://129904870972215",
	["R_Luck7"] = "rbxassetid://129904870972215",
	["R_Luck8"] = "rbxassetid://129904870972215",
	["R_Luck9"] = "rbxassetid://129904870972215",
	["R_Rain1"] = "rbxassetid://87488080436539",
	["R_Rain2"] = "rbxassetid://87488080436539",
	["R_Rain3"] = "rbxassetid://87488080436539",
	["R_Rain4"] = "rbxassetid://87488080436539",
	["R_Rain5"] = "rbxassetid://87488080436539",
	["R_Rain6"] = "rbxassetid://87488080436539",
	["R_Triple"] = "rbxassetid://87202382278082",
	["S_Avalanche"] = "rbxassetid://118168675188658",
	["S_Blizzard"] = "rbxassetid://118168675188658",
	["S_Center"] = "rbxassetid://87202382278082",
	["S_Crush"] = "rbxassetid://85709873651022",
	["S_Deep"] = "rbxassetid://87202382278082",
	["S_Fresh"] = "rbxassetid://87202382278082",
	["S_FrostCore"] = "rbxassetid://118168675188658",
	["S_Gain1"] = "rbxassetid://87202382278082",
	["S_Gain2"] = "rbxassetid://87202382278082",
	["S_Gain3"] = "rbxassetid://87202382278082",
	["S_Glacial"] = "rbxassetid://85709873651022",
	["S_Glacier"] = "rbxassetid://118168675188658",
	["S_Heavy"] = "rbxassetid://137843092410698",
	["S_Meteor"] = "rbxassetid://85709873651022",
	["S_Quick"] = "rbxassetid://105444832567503",
	["S_Rush"] = "rbxassetid://87202382278082",
	["S_Sharp"] = "rbxassetid://137843092410698",
	["S_Size1"] = "rbxassetid://91899109454902",
	["S_Size10"] = "rbxassetid://86317744514702",
	["S_Size2"] = "rbxassetid://91899109454902",
	["S_Size3"] = "rbxassetid://91899109454902",
	["S_Size4"] = "rbxassetid://91899109454902",
	["S_Size5"] = "rbxassetid://91899109454902",
	["S_Size6"] = "rbxassetid://86317744514702",
	["S_Size7"] = "rbxassetid://86317744514702",
	["S_Size8"] = "rbxassetid://86317744514702",
	["S_Size9"] = "rbxassetid://86317744514702",
	["S_Storm"] = "rbxassetid://87202382278082",
	["S_Swing"] = "rbxassetid://137843092410698",
	["S_Third"] = "rbxassetid://87202382278082",
	["S_Titan"] = "rbxassetid://85709873651022",
	["S_Turbo"] = "rbxassetid://105444832567503",
	["W2_BlockBuster"] = "rbxassetid://85709873651022",
	["W2_BlossomBreeze"] = "rbxassetid://118168675188658",
	["W2_CandyCrush"] = "rbxassetid://85709873651022",
	["W2_CloudBurst"] = "rbxassetid://118168675188658",
	["W2_CoralCrusher"] = "rbxassetid://85709873651022",
	["W2_CosmicLuck"] = "rbxassetid://136567550154586",
	["W2_GalaxyReach"] = "rbxassetid://86317744514702",
	["W2_GearGrinder"] = "rbxassetid://85709873651022",
	["W2_GiantToys"] = "rbxassetid://86317744514702",
	["W2_KoiCompanions"] = "rbxassetid://86317744514702",
	["W2_KoiFortune"] = "rbxassetid://136567550154586",
	["W2_LuckyClockwork"] = "rbxassetid://136567550154586",
	["W2_LuckyLollipop"] = "rbxassetid://136567550154586",
	["W2_LuckyToyDice"] = "rbxassetid://136567550154586",
	["W2_MeteorStrike"] = "rbxassetid://85709873651022",
	["W2_PearlLuck"] = "rbxassetid://136567550154586",
	["W2_PetalStrike"] = "rbxassetid://85709873651022",
	["W2_RainbowLuck"] = "rbxassetid://87488080436539",
	["W2_SkyReach"] = "rbxassetid://86317744514702",
	["W2_SpringReach"] = "rbxassetid://86317744514702",
	["W2_StarBurst"] = "rbxassetid://118168675188658",
	["W2_SugarRush"] = "rbxassetid://118168675188658",
	["W2_SweetFriends"] = "rbxassetid://86317744514702",
	["W2_ThunderStrike"] = "rbxassetid://85709873651022",
	["W2_TickTockSnow"] = "rbxassetid://118168675188658",
	["W2_TidalReach"] = "rbxassetid://86317744514702",
	["W2_TideSurge"] = "rbxassetid://118168675188658",
	["W2_ToyChest"] = "rbxassetid://118168675188658",
}
Art.ByEffect = {
	["EggDiscount"] = "rbxassetid://93951851073860",
	["FriendBoost"] = "rbxassetid://131132644122801",
	["LuckMult"] = "rbxassetid://129904870972215",
	["PetBoostMult"] = "rbxassetid://122642278926582",
	["PetSlots"] = "rbxassetid://109116345936565",
	["PowerMult"] = "rbxassetid://137843092410698",
	["RollCooldownMult"] = "rbxassetid://107696629451710",
	["SizeMult"] = "rbxassetid://91899109454902",
	["SnowMult"] = "rbxassetid://87202382278082",
	["SpinMult"] = "rbxassetid://105444832567503",
	["UnlockCraft"] = "rbxassetid://136771842476154",
	["UnlockFuser"] = "rbxassetid://99278963740109",
	["WalkSpeed"] = "rbxassetid://73644820523941",
}

function Art.Resolve(node)
	if type(node) ~= "table" then return nil end
	local explicit = Art.ByUpgrade[node.Id]
	if explicit then return explicit end
	local effect = node.Effect
	return type(effect) == "table" and Art.ByEffect[effect[1]] or nil
end

return Art
]====]
local existing = RS:FindFirstChild("UpgradeIconArt")
assert(not existing or existing:IsA("ModuleScript"), "UpgradeIconArt name occupied")
assert(not SS:FindFirstChild("UpgradeIconRemasterBackup_20261005"), "Backup already exists; inspect recovery state before rerunning")
local backup = Instance.new("Folder")
backup.Name = "UpgradeIconRemasterBackup_20261005"
client:Clone().Parent = backup
icon:Clone().Parent = backup
if existing then existing:Clone().Parent = backup end
backup:SetAttribute("OriginalIconImage", icon.Image)
backup:SetAttribute("HadArtModule", existing ~= nil)
backup:SetAttribute("InstalledUTC", DateTime.now():ToIsoDate())
backup.Parent = SS
local oldModuleSource = existing and existing.Source
local art = existing or Instance.new("ModuleScript")
local oldMainImage = icon.Image
local ok, err = pcall(function()
	art.Name = "UpgradeIconArt"
	art.Source = artSource
	art.Parent = RS
	client.Source = changed
	icon.Image = "rbxassetid://106414155892974"
end)
if not ok then
	client.Source = previous
	icon.Image = oldMainImage
	if existing then existing.Source = oldModuleSource else art:Destroy() end
	backup:SetAttribute("InstallFailed", tostring(err))
	error("Install failed and rolled back: " .. tostring(err))
end
backup:SetAttribute("Installed", true)
return game:GetService("HttpService"):JSONEncode({installed=true,knownUpgradeIds=138,artAssets=20,configChanged=false,layoutChanged=false,backup=backup:GetFullName()})

