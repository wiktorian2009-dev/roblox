-- PlowAssembly (2026-10-04, Claude): builds the VISUAL snowplow from the Blender templates in ReplicatedStorage.PlowParts.
-- The server wraps the result with a hull + seat (PlowService); clients use it for the shop / garage 3D previews.
local RS = game:GetService("ReplicatedStorage")
local C = require(script.Parent:WaitForChild("PlowConfig"))
local A = {}
function A.Build(build)
	local T = RS:WaitForChild("PlowParts")
	local chassis = T:WaitForChild("Chassis"):Clone()
	local rootCF = chassis.PrimaryPart.CFrame
	for _, slot in ipairs(C.Slots) do
		local def = C.Parts[build[slot] or ""]
		local tpl = def and T:FindFirstChild(def.Model)
		local attach = chassis:GetAttribute("Attach_" .. slot)
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
