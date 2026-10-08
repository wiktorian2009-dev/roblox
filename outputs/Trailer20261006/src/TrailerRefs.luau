-- TrailerRefs (2026-10-06, Claude): DATA recorded in rehearsal round 1 (DESIGN rev 2, sections 7.2, 7.3, 14.3).
-- Filled by Claude from the Output lines the refs run prints:
--   [Trailer] REF_SEATWELD {"C0":[12 numbers],"C1":[12 numbers]}   -> SeatWeld below
--   [Trailer] REF_TRACK <name> {"hz":30,"anchor":n,"frames":[[dx,dy,dz,dyaw],...]} -> Tracks[<name>]
-- Frames are the ground-level plow root relative to the anchor pose (the stop pose for "stop" tracks, the pose passing the end
-- point for "pass" tracks), sampled at hz. Empty tables = not recorded yet: puppets then use the kinematic profile.
-- No side effects; CFrames are stored as 12-number arrays (CFrame:GetComponents order) so the module stays plain data.
local Refs = {}

Refs.SeatWeld = nil -- {C0 = {12 numbers}, C1 = {12 numbers}}

Refs.Tracks = {
	-- Desert = {hz = 30, anchor = <frame index of the stop pose>, frames = {{dx, dy, dz, dyaw}, ...}},
	-- Crystal = {hz = 30, anchor = <frame index passing the end point>, frames = {...}},
}

Refs.Measured = {
	-- filled from REF_DRIVE lines: {field = {top = , accel = , brake = }, road = {...}}
}

function Refs.ToCFrame(arr)
	if type(arr) ~= "table" or #arr ~= 12 then return nil end
	for _, x in ipairs(arr) do if type(x) ~= "number" or x ~= x then return nil end end
	return CFrame.new(table.unpack(arr))
end

return Refs
