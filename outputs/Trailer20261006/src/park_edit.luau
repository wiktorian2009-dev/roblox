-- park_edit (2026-10-06, Claude): Studio EDIT snippet (MCP execute_luau): parks the trailer kit after the take (DESIGN 14.5, brief 7).
-- Moves ServerStorage.TrailerKit and a DISABLED ServerScriptService.TrailerBootstrap into ServerStorage.TrailerKit_Parked (an older
-- parked copy is renamed with a UTC stamp, never deleted), clears the trailer attributes (TrailerMode / TrailerToken / TrailerSplit /
-- TrailerRefs, and BalanceTestMode as well, so a skipped disarm_edit cannot leave it in a saved place) and prints the result.
-- Nothing in the parked folder can run.
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local CHS = game:GetService("ChangeHistoryService")

if RunService:IsRunning() then error("park_edit: Edit only") end
local out = {}
local recording = CHS:TryBeginRecording("TrailerKit park")
local ok, err = pcall(function()
	local stamp = os.date("!%Y%m%d_%H%M%S")
	local parked = SS:FindFirstChild("TrailerKit_Parked")
	if not parked then
		parked = Instance.new("Folder")
		parked.Name = "TrailerKit_Parked"
		parked.Parent = SS
		table.insert(out, "created ServerStorage.TrailerKit_Parked")
	end
	local kit = SS:FindFirstChild("TrailerKit")
	if kit then
		local old = parked:FindFirstChild("TrailerKit")
		if old then old.Name = "TrailerKit_" .. stamp; table.insert(out, "renamed the older parked kit to " .. old.Name) end
		kit.Parent = parked
		table.insert(out, "moved TrailerKit -> " .. kit:GetFullName())
	else
		table.insert(out, "no ServerStorage.TrailerKit to park")
	end
	local boot = SSS:FindFirstChild("TrailerBootstrap")
	if boot then
		boot.Enabled = false
		local old = parked:FindFirstChild("TrailerBootstrap")
		if old then old.Name = "TrailerBootstrap_" .. stamp end
		boot.Parent = parked
		table.insert(out, "moved TrailerBootstrap -> " .. boot:GetFullName() .. " (Enabled=false)")
	else
		table.insert(out, "no ServerScriptService.TrailerBootstrap to park")
	end
	-- BalanceTestMode is cleared here too (review fix): this snippet precedes save point 56, and the attribute is never saved.
	for _, k in ipairs({"TrailerMode", "TrailerToken", "TrailerSplit", "TrailerRefs", "BalanceTestMode"}) do SS:SetAttribute(k, nil) end
	table.insert(out, "cleared TrailerMode / TrailerToken / TrailerSplit / TrailerRefs / BalanceTestMode")
	if SS:GetAttribute("BalanceTestMode") ~= nil then error("BalanceTestMode is still set after the clear: do NOT save the place") end
end)
if recording then CHS:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel) end
if not ok then table.insert(out, "FAILED: " .. tostring(err)) end
local cam = workspace.CurrentCamera
table.insert(out, "camera: " .. (cam and cam.CameraType.Name or "?"))
print("[Trailer park_edit]\n" .. table.concat(out, "\n"))
