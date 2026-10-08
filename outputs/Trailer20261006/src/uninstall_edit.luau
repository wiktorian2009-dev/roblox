-- uninstall_edit (2026-10-06, Claude): Studio EDIT snippet (MCP execute_luau): removes the trailer kit from the place.
-- Destroys ServerStorage.TrailerKit and ServerScriptService.TrailerBootstrap and clears the trailer attributes. The parked copy
-- (ServerStorage.TrailerKit_Parked) and the install backups (*_Backup_*) are kept unless the flags below are set to true.
-- Undoable through ChangeHistoryService. Run only with wiktor's consent; prints what it removed.
local REMOVE_PARKED = false
local REMOVE_BACKUPS = false

local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local CHS = game:GetService("ChangeHistoryService")

if RunService:IsRunning() then error("uninstall_edit: Edit only") end
local out = {}
local recording = CHS:TryBeginRecording("TrailerKit uninstall")
local ok, err = pcall(function()
	local function kill(inst)
		if inst then table.insert(out, "removed " .. inst:GetFullName()); inst:Destroy() end
	end
	kill(SS:FindFirstChild("TrailerKit"))
	kill(SSS:FindFirstChild("TrailerBootstrap"))
	if REMOVE_PARKED then kill(SS:FindFirstChild("TrailerKit_Parked")) end
	if REMOVE_BACKUPS then
		for _, c in ipairs(SS:GetChildren()) do
			if c.Name:match("^TrailerKit_Backup_") or c.Name:match("^TrailerBootstrap_Backup_") then kill(c) end
		end
	end
	for _, k in ipairs({"TrailerMode", "TrailerToken", "TrailerSplit", "TrailerRefs", "BalanceTestMode"}) do SS:SetAttribute(k, nil) end
	table.insert(out, "cleared TrailerMode / TrailerToken / TrailerSplit / TrailerRefs / BalanceTestMode")
end)
if recording then CHS:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel) end
if not ok then table.insert(out, "FAILED: " .. tostring(err)) end
local kept = {}
for _, c in ipairs(SS:GetChildren()) do if c.Name:match("^Trailer") then table.insert(kept, c.Name) end end
table.insert(out, "still in ServerStorage: " .. (#kept > 0 and table.concat(kept, ", ") or "nothing"))
print("[Trailer uninstall_edit]\n" .. table.concat(out, "\n"))
