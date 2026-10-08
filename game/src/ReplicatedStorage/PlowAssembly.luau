-- PlowAssembly (2026-10-04, Claude): builds the VISUAL snowplow from the Blender templates in ReplicatedStorage.PlowParts.
-- The server wraps the result with a hull + seat (PlowService); clients use it for the shop / garage 3D previews.
-- 2026-10-05 (task 7): PlowParts.Chassis is the invariant frame (Root, seat, steering wheel, attach points); the visible shell is the BODY part,
-- mounted at the chassis root (Attach_Body, default identity). No body id = the free starter body, so old 3-part builds still look complete.
local RS = game:GetService("ReplicatedStorage")
local C = require(script.Parent:WaitForChild("PlowConfig"))
local A = {}
function A.Build(build)
	local T = RS:WaitForChild("PlowParts")
	local chassis = T:WaitForChild("Chassis"):Clone()
	local rootCF = chassis.PrimaryPart.CFrame
	for _, slot in ipairs(C.Slots) do
		local def = C.Parts[build[slot] or ""] or (slot == "Body" and C.Parts[C.Starter.Body or ""]) or nil
		local tpl = def and T:FindFirstChild(def.Model)
		local attach = chassis:GetAttribute("Attach_" .. slot) or (slot == "Body" and CFrame.new() or nil)
		if tpl and attach then
			local m = tpl:Clone()
			m.Name = slot
			m:PivotTo(rootCF * attach)
			m.Parent = chassis
		end
	end
	return chassis
end
function A.PartModel(partId)
	local def = C.Parts[partId]
	local tpl = def and RS:WaitForChild("PlowParts"):FindFirstChild(def.Model)
	return tpl and tpl:Clone() or nil
end
return A
