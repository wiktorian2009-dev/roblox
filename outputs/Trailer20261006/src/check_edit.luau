-- check_edit (2026-10-06, Claude): Studio EDIT snippet (MCP execute_luau): compile / data check of the installed kit (DESIGN 14.2).
-- Read-only: requires every kit module (none has top-level side effects), runs TrailerMath.SelfTest() and TrailerShots.ValidateShots(),
-- checks the ScreenGui properties, that no placeholder sources are left, the guard state and that the Edit camera type is unchanged.
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

if RunService:IsRunning() then error("check_edit: Edit only") end
local cam = workspace.CurrentCamera
local camType = cam and cam.CameraType
local out, bad = {}, 0
local function line(ok, s) if not ok then bad += 1 end table.insert(out, (ok and "ok   " or "FAIL ") .. s) end

local kit = SS:FindFirstChild("TrailerKit")
line(kit ~= nil, "ServerStorage.TrailerKit")
local boot = SSS:FindFirstChild("TrailerBootstrap")
line(boot ~= nil and boot:IsA("Script") and boot.Enabled, "ServerScriptService.TrailerBootstrap (Script, enabled)")
local gui = kit and kit:FindFirstChild("TrailerDirectorGui")
line(gui ~= nil and gui:IsA("ScreenGui") and gui.ResetOnSpawn == false and gui.IgnoreGuiInset == true and gui.DisplayOrder == 1000,
	"TrailerDirectorGui (ScreenGui, ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=1000)")
if gui then
	local okI, ins = pcall(function() return gui.ScreenInsets end)
	line(not okI or ins == Enum.ScreenInsets.None, "TrailerDirectorGui.ScreenInsets = None")
end
for _, root in ipairs({kit, boot}) do
	if root then
		local list = root:GetDescendants()
		if root:IsA("LuaSourceContainer") then table.insert(list, root) end
		for _, d in ipairs(list) do
			if d:IsA("LuaSourceContainer") then line(not d.Source:find("placeholder (install_edit", 1, true), d:GetFullName() .. " has its source") end
		end
	end
end
local mods = {}
local function req(parent, name)
	local m = parent and parent:FindFirstChild(name)
	if not m then line(false, "require " .. name .. ": missing") return nil end
	local ok, res = pcall(require, m)
	line(ok, "require " .. name .. (ok and "" or (": " .. tostring(res))))
	if ok then mods[name] = res end
	return ok and res or nil
end
req(kit, "TrailerServer")
for _, n in ipairs({"TrailerMath", "TrailerShots", "TrailerText", "TrailerPuppets", "TrailerRefs", "TrailerClient"}) do req(gui, n) end
if mods.TrailerMath then
	local ok, errs = mods.TrailerMath.SelfTest()
	line(ok, "TrailerMath.SelfTest()" .. (ok and "" or (": " .. table.concat(errs, "; "))))
end
if mods.TrailerShots then
	local ok, errs = mods.TrailerShots.ValidateShots()
	line(ok, "TrailerShots.ValidateShots() rev " .. tostring(mods.TrailerShots.Version) .. (ok and "" or (": " .. table.concat(errs, "; "))))
end
if mods.TrailerServer then
	local g, why = mods.TrailerServer.Guard()
	table.insert(out, "info guard in Edit: " .. tostring(g) .. " (" .. tostring(why) .. ")")
end
line(cam ~= nil and cam.CameraType == camType and cam.CameraType ~= Enum.CameraType.Scriptable, "Edit camera type unchanged (" .. tostring(cam and cam.CameraType.Name) .. ")")
print("[Trailer check_edit] " .. (bad == 0 and "ALL OK" or (bad .. " problem(s)")) .. "\n" .. table.concat(out, "\n"))
