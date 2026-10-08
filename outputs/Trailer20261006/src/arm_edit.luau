-- arm_edit (2026-10-06, Claude): Studio EDIT snippet (MCP execute_luau): arms the trailer for the NEXT Play (DESIGN rev 2, 2.1).
-- Sets ServerStorage.BalanceTestMode = true (Studio temp profile, never saved), TrailerMode, TrailerToken (os.time() expiry) and the
-- optional TrailerSplit / TrailerRefs, then prints them. The game's modules read these at server start, so set them right before
-- F5 (with wiktor's consent) and clear them afterwards with disarm_edit.luau. Edit the four values below before running.
local MODE = "rehearse" -- "rehearse" or "take"
local MINUTES = 15      -- token lifetime (max 60)
local SPLIT = nil       -- nil, "1-8" or "9-11" (only if RAM forces a split take, section 12.7)
local REFS = false      -- true = round 1 reference run (TrailerRefs) instead of the trailer

local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

if RunService:IsRunning() then error("arm_edit: Edit only - the modules read these attributes at server start") end
if MODE ~= "rehearse" and MODE ~= "take" then error("arm_edit: MODE must be rehearse or take") end
if SPLIT ~= nil and SPLIT ~= "1-8" and SPLIT ~= "9-11" then error("arm_edit: SPLIT must be nil, 1-8 or 9-11") end
MINUTES = math.clamp(MINUTES, 1, 60)
local problems = {}
local kit = SS:FindFirstChild("TrailerKit")
if not kit then table.insert(problems, "ServerStorage.TrailerKit missing (install_edit + multi_edit first)") end
local boot = SSS:FindFirstChild("TrailerBootstrap")
if not boot then table.insert(problems, "ServerScriptService.TrailerBootstrap missing")
elseif not boot.Enabled then table.insert(problems, "TrailerBootstrap is disabled") end
for _, d in ipairs(kit and kit:GetDescendants() or {}) do
	if d:IsA("LuaSourceContainer") and d.Source:find("placeholder (install_edit", 1, true) then table.insert(problems, d:GetFullName() .. " still has the placeholder source") end
end
if SS:GetAttribute("DataLoadTest") == true then table.insert(problems, "DataLoadTest is set (fake store) - clear it first") end
if #problems > 0 then error("arm_edit refused:\n  " .. table.concat(problems, "\n  ")) end

SS:SetAttribute("BalanceTestMode", true)
SS:SetAttribute("TrailerMode", MODE)
SS:SetAttribute("TrailerToken", os.time() + MINUTES * 60)
SS:SetAttribute("TrailerSplit", SPLIT)
SS:SetAttribute("TrailerRefs", REFS == true or nil)
local cam = workspace.CurrentCamera
print(string.format("[Trailer arm_edit] BalanceTestMode=%s TrailerMode=%s TrailerToken=%s (expires in %d min, %s UTC) TrailerSplit=%s TrailerRefs=%s camera=%s",
	tostring(SS:GetAttribute("BalanceTestMode")), tostring(SS:GetAttribute("TrailerMode")), tostring(SS:GetAttribute("TrailerToken")), MINUTES,
	os.date("!%H:%M:%S", SS:GetAttribute("TrailerToken")), tostring(SS:GetAttribute("TrailerSplit")), tostring(SS:GetAttribute("TrailerRefs")),
	cam and cam.CameraType.Name or "?"))
