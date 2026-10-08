-- TrailerBootstrap (2026-10-06, Claude): Studio-only entry for the page-trailer director (DESIGN rev 2, section 2.2).
-- Inert unless ALL of: RunService:IsStudio(), ServerStorage.TrailerMode is "rehearse" or "take", ServerStorage.TrailerToken is an
-- os.time() expiry no more than 1 h ahead and not past, and ServerStorage.BalanceTestMode == true (Studio temp profile, never
-- saved). Live servers stay inert even if the place is saved with the attributes. TrailerServer checks the same guard again.
local RunService = game:GetService("RunService")
local SS = game:GetService("ServerStorage")

if not RunService:IsStudio() then return end
local mode = SS:GetAttribute("TrailerMode")
if mode ~= "rehearse" and mode ~= "take" then return end
local token, now = SS:GetAttribute("TrailerToken"), os.time()
if type(token) ~= "number" or token < now or token > now + 3600 then warn("[Trailer] token missing/expired - inert") return end
if SS:GetAttribute("BalanceTestMode") ~= true then warn("[Trailer] needs BalanceTestMode=true - inert") return end
local kit = SS:FindFirstChild("TrailerKit")
if not kit then warn("[Trailer] TrailerKit missing") return end
local serverModule = kit:FindFirstChild("TrailerServer")
if not (serverModule and serverModule:IsA("ModuleScript")) then warn("[Trailer] TrailerKit.TrailerServer missing") return end
local ok, err = pcall(function() require(serverModule).Start(kit, mode) end)
if not ok then warn("[Trailer] start failed: " .. tostring(err)) end
