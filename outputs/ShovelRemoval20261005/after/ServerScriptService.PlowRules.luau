-- PlowRules (2026-10-04, Claude): validates / repairs data.Plow when a profile loads (called from DataService.defaults).
-- Existing profiles keep everything they had; the starter loadout is added; unknown or tampered values are dropped.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("PlowConfig"))
local Rules = {}
local function cleanOffer(o)
	if type(o) ~= "table" or type(o.Part) ~= "string" or not C.Parts[o.Part] or type(o.Token) ~= "string" then return nil end
	local price = tonumber(o.Price)
	if not price or price ~= price or price < 0 then price = C.Parts[o.Part].Price end
	return {Part = o.Part, Token = o.Token, Price = price, Seq = tonumber(o.Seq) or 0}
end
function Rules.Apply(d)
	local p = type(d.Plow) == "table" and d.Plow or {}
	d.Plow = p
	local fresh = type(p.Build) ~= "table"
	local parts = {}
	if type(p.Parts) == "table" then
		for id, n in pairs(p.Parts) do
			if type(id) == "string" and C.Parts[id] and type(n) == "number" and n == n and n >= 1 then parts[id] = math.min(math.floor(n), C.Shop.MaxOwned) end
		end
	end
	for _, id in pairs(C.Starter) do if not parts[id] then parts[id] = 1 end end
	p.Parts = parts
	local build = {}
	if fresh then
		for slot, id in pairs(C.Starter) do build[slot] = id end
	else
		for _, slot in ipairs(C.Slots) do
			local id = p.Build[slot]
			if type(id) == "string" and C.Parts[id] and C.Parts[id].Slot == slot and parts[id] then build[slot] = id end
		end
	end
	p.Build = build
	local offers, src = {}, type(p.Offers) == "table" and p.Offers or {}
	for _, k in ipairs({"1", "2", "3"}) do offers[k] = cleanOffer(src[k]) end
	if not offers["1"] then offers["1"] = cleanOffer(p.Offer) end -- an old single offer moves to pedestal 1
	p.Offers, p.Offer = offers, nil
	p.Reserved = cleanOffer(p.Reserved)
	p.Seq = (type(p.Seq) == "number" and p.Seq == p.Seq) and math.floor(p.Seq) or 0
	p.Rolls = (type(p.Rolls) == "number" and p.Rolls == p.Rolls) and math.floor(p.Rolls) or 0
	p.TutorialDone = p.TutorialDone == true
	return d
end
return Rules

