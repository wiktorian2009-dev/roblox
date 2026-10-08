-- disarm_edit (2026-10-06, Claude): Studio EDIT snippet (MCP execute_luau): clears the trailer gate after a session (DESIGN 14.5).
-- Clears ServerStorage TrailerMode, TrailerToken, TrailerSplit, TrailerRefs and BalanceTestMode, and checks the Edit camera is not
-- left Scriptable (STATUS lesson 2026-10-06: a Scriptable Edit camera is set back to Fixed and reported). Prints what it did.
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

if RunService:IsRunning() then error("disarm_edit: run this in Edit after Play has stopped") end
local before = {}
for _, k in ipairs({"TrailerMode", "TrailerToken", "TrailerSplit", "TrailerRefs", "BalanceTestMode"}) do
	before[#before + 1] = k .. "=" .. tostring(SS:GetAttribute(k))
	SS:SetAttribute(k, nil)
end
local cam = workspace.CurrentCamera
local camNote = cam and cam.CameraType.Name or "?"
if cam and cam.CameraType == Enum.CameraType.Scriptable then
	cam.CameraType = Enum.CameraType.Fixed
	camNote = "was Scriptable -> set to Fixed"
end
local after = {}
for _, k in ipairs({"TrailerMode", "TrailerToken", "TrailerSplit", "TrailerRefs", "BalanceTestMode"}) do after[#after + 1] = k .. "=" .. tostring(SS:GetAttribute(k)) end
print("[Trailer disarm_edit] before: " .. table.concat(before, " ") .. "\n  after: " .. table.concat(after, " ") .. "\n  camera: " .. camNote)
