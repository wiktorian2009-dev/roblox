-- Idempotent starter grant. Only server-loaded profiles can receive it.
local Config=require(game.ReplicatedStorage:WaitForChild("RNGConfig"))
local common
for _,item in ipairs(Config.Items)do
 if not common or item.Chance<common.Chance then common=item end
end
assert(common,"RNGConfig needs a starter shovel")
local Rules={Name=common.Name}
function Rules.Apply(d)
 if d.StarterShovelGranted==true then return false end
 local current=tonumber(d.Counts[Rules.Name]) or 0
 local added=current<1
 if added then d.Counts[Rules.Name]=1 end
 -- Never replace a returning player's equipment.
 if #d.Equipped==0 then table.insert(d.Equipped,Rules.Name) end
 d.StarterShovelGranted=true
 return added
end
return Rules

