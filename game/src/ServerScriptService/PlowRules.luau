-- PlowRules (2026-10-04, Claude): validates / repairs data.Plow when a profile loads (called from DataService.defaults).
-- Existing profiles keep everything they had; the starter loadout is added; unknown or tampered values are dropped.
-- 2026-10-05 (Claude): 90-part catalog keeps all old ids, so owned parts / builds / offers (with their stored price) / reservations carry
-- over unchanged. Every build slot is always filled (empty or invalid -> free starter part); p.Dry = bad-luck protection counter.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("PlowConfig"))
local Rules = {}
local function cleanOffer(o)
	if type(o) ~= "table" or type(o.Part) ~= "string" or not C.Parts[o.Part] or type(o.Token) ~= "string" then return nil end
	local price = tonumber(o.Price)
	if not price or price ~= price or price < 0 then price = C.Parts[o.Part].Price end
	-- 2026-10-06 (offer expiry): a saved pedestal offer keeps its remaining seconds (Left); an offer that was ticking when the player left
	-- (ExpiresAt) gets a fresh window when the timer next runs, so nothing expires while you are offline
	local left = tonumber(o.Left)
	if left and (left ~= left or left <= 0) then left = nil end
	if not left and o.ExpiresAt then left = C.Shop.OfferSeconds end
	return {Part = o.Part, Token = o.Token, Price = price, Seq = tonumber(o.Seq) or 0, Left = left and math.min(left, C.Shop.ProtectedOfferSeconds or 60) or nil, Protected = o.Protected == true or nil}
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
			if type(id) == "string" and C.Parts[id] and C.Parts[id].Slot == slot and parts[id] then build[slot] = id else build[slot] = C.Starter[slot] end
		end
	end
	p.Build = build
	local offers, src = {}, type(p.Offers) == "table" and p.Offers or {}
	for _, k in ipairs({"1", "2", "3"}) do offers[k] = cleanOffer(src[k]) end
	if not offers["1"] then offers["1"] = cleanOffer(p.Offer) end -- an old single offer moves to pedestal 1
	p.Offers, p.Offer = offers, nil
	p.Reserved = cleanOffer(p.Reserved)
	if p.Reserved then p.Reserved.Left, p.Reserved.Protected = nil, nil end -- the reserve shelf never expires
	p.Seq = (type(p.Seq) == "number" and p.Seq == p.Seq) and math.floor(p.Seq) or 0
	p.Rolls = (type(p.Rolls) == "number" and p.Rolls == p.Rolls) and math.floor(p.Rolls) or 0
	p.TutorialDone = p.TutorialDone == true
	p.Dry = (type(p.Dry) == "number" and p.Dry == p.Dry and p.Dry >= 0) and math.min(math.floor(p.Dry), 1000) or 0
	-- 2026-10-06 part levels (versioned + idempotent): levels 1..Max per part id (kept with the part even if a copy is re-bought);
	-- version 1 starts every owned part at level 1. Only runs on profiles that really loaded (DataService never builds failed loads).
	local maxL = (C.Levels and C.Levels.Max) or 10
	local lv = {}
	if type(p.Levels) == "table" then
		for id, L in pairs(p.Levels) do
			if type(id) == "string" and C.Parts[id] and type(L) == "number" and L == L then lv[id] = math.clamp(math.floor(L), 1, maxL) end
		end
	end
	if (tonumber(p.LevelsVersion) or 0) < 1 then
		for id in pairs(parts) do lv[id] = lv[id] or 1 end
		p.LevelsVersion = 1
	end
	p.Levels = lv
	return d
end
return Rules

