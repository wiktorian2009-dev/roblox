-- install_edit (2026-10-06, Claude): Studio EDIT snippet (MCP execute_luau) for the page-trailer kit (DESIGN rev 2, section 4.1).
-- Creates the CONTAINERS only (folder, ScreenGui with its properties, empty script objects with a placeholder comment); the
-- sources are pushed afterwards with multi_edit from outputs/Trailer20261006/src (MANIFEST.md). Existing kit containers are
-- cloned to *_Backup_<UTC stamp> first (the map is never touched). Refuses to run in Play. Prints everything it did.
-- Needs wiktor's consent for Studio writes (save point 56).
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local CHS = game:GetService("ChangeHistoryService")

if RunService:IsRunning() then error("install_edit: run this in Edit, not in Play") end
local camType = workspace.CurrentCamera and workspace.CurrentCamera.CameraType
local out = {}
local function say(s) table.insert(out, s) end
local PLACEHOLDER = "-- placeholder (install_edit 2026-10-06): source is pushed with multi_edit from outputs/Trailer20261006/src\n"

local recording = CHS:TryBeginRecording("TrailerKit install")
local ok, err = pcall(function()
	local stamp = os.date("!%Y%m%d_%H%M%S")
	local kit = SS:FindFirstChild("TrailerKit")
	if kit then
		local b = kit:Clone()
		b.Name = "TrailerKit_Backup_" .. stamp
		b.Parent = SS
		say("backup: ServerStorage." .. b.Name)
	end
	local boot = SSS:FindFirstChild("TrailerBootstrap")
	if boot then
		local b = boot:Clone()
		b.Name = "TrailerBootstrap_Backup_" .. stamp
		b.Enabled = false
		b.Parent = SS
		say("backup: ServerStorage." .. b.Name .. " (disabled)")
	end
	local function ensure(parent, class, name, props)
		local x = parent:FindFirstChild(name)
		if x and not x:IsA(class) then error(parent:GetFullName() .. "." .. name .. " exists but is a " .. x.ClassName) end
		local made = false
		if not x then
			x = Instance.new(class)
			x.Name = name
			if x:IsA("LuaSourceContainer") then pcall(function() x.Source = PLACEHOLDER end) end
			made = true
		end
		for k, v in pairs(props or {}) do x[k] = v end
		x.Parent = parent
		say((made and "created " or "kept    ") .. x:GetFullName() .. " (" .. class .. ")")
		return x
	end
	kit = ensure(SS, "Folder", "TrailerKit")
	ensure(kit, "ModuleScript", "TrailerServer")
	local gui = ensure(kit, "ScreenGui", "TrailerDirectorGui", {ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = true})
	if not pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end) then say("note: ScreenInsets not settable here") end
	ensure(gui, "LocalScript", "TrailerDirector")
	for _, n in ipairs({"TrailerClient", "TrailerText", "TrailerPuppets", "TrailerMath", "TrailerShots", "TrailerRefs"}) do
		ensure(gui, "ModuleScript", n)
	end
	ensure(SSS, "Script", "TrailerBootstrap") -- last: harmless placeholder until its source is pushed
end)
if recording then CHS:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel) end
if not ok then say("FAILED: " .. tostring(err)) end
local cam = workspace.CurrentCamera
say("camera: " .. tostring(cam and cam.CameraType.Name) .. (cam and cam.CameraType ~= camType and " (CHANGED!)" or " (unchanged)"))
say("attributes: BalanceTestMode=" .. tostring(SS:GetAttribute("BalanceTestMode")) .. " TrailerMode=" .. tostring(SS:GetAttribute("TrailerMode"))
	.. " TrailerToken=" .. tostring(SS:GetAttribute("TrailerToken")))
say("next: push the sources with multi_edit (MANIFEST.md), then run check_edit.luau")
print("[Trailer install_edit]\n" .. table.concat(out, "\n"))
