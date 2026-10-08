-- Pure server-side transaction rules; no yields occur between validation and reset.
local RS = game:GetService("ReplicatedStorage")
local R = require(RS:WaitForChild("RebirthConfig"))
local Shovels = require(RS:WaitForChild("RNGConfig"))
local Pets = require(RS:WaitForChild("PetConfig"))
local Stages = require(RS:WaitForChild("StageConfig"))
local Upgrades = require(RS:WaitForChild("UpgradeConfig"))
local Rules = {}

function Rules.Check(d, expected)
 if not d then return false, "Your progress is still loading." end
 if type(expected) ~= "number" or expected ~= R.Count(d.Rebirths) then
  return false, "Your rebirth changed. Check the rewards and try again."
 end
 local req = R.Requirement(d.Rebirths)
 if not req then return false, "You reached the maximum rebirth level!" end
 -- 2026-10-04 (Claude): no stage requirement any more - a rebirth only needs the Snow cost (RebirthConfig.Milestones[].Cost)
 if type(d.Snow) ~= "number" or d.Snow ~= d.Snow or d.Snow == math.huge or d.Snow < req.Cost then
  return false, "You need more Snow to rebirth."
 end
 return true, req
end

local function equippedAfterReset(list, owned, byName, slots, score)
 local clean, used = {}, {}
 for _, name in ipairs(list or {}) do
  if byName[name] and (used[name] or 0) < (owned[name] or 0) then
   used[name] = (used[name] or 0) + 1
   table.insert(clean, name)
  end
 end
 table.sort(clean, function(a, b) return score(byName[a]) > score(byName[b]) end)
 while #clean > slots do table.remove(clean) end
 return clean
end

function Rules.Apply(d, expected)
 local ok, req = Rules.Check(d, expected)
 if not ok then return false, req end
 -- 2026-10-03 (Claude): upgrades are KEPT on rebirth (user request), so the equip slots they give stay too.
 -- Compute the new equipped sets before changing the profile.
 local kept = Upgrades.Calculate(d.Upgrades or {}, 0)
 local equipped = equippedAfterReset(d.Equipped, d.Counts, Shovels.ByName, kept.ShovelSlots or Upgrades.Base.ShovelSlots, function(x) return x.Chance end)
 local pets = equippedAfterReset(d.EquippedPets, d.Pets, Pets.PetByName, kept.PetSlots or Upgrades.Base.PetSlots, function(x) return x.Boost end)
 d.Rebirths = req.Level
 d.Snow = 0
 d.Stages = {}
 -- d.Upgrades is kept (2026-10-03; it used to be reset here)
 d.Equipped = equipped
 d.EquippedPets = pets
 -- Upgrades, Counts, Pets, PetIndex, Settings, TotalRolls and base luck are preserved.
 return true, req
end
return Rules
