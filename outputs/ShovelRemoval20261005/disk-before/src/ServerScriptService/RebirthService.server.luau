local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local D = require(script.Parent:WaitForChild("DataService"))
local Rules = require(script.Parent:WaitForChild("RebirthRules"))
local R = require(RS:WaitForChild("RebirthConfig"))
local StageConfig = require(RS:WaitForChild("StageConfig"))
local U = require(RS:WaitForChild("UpgradeConfig"))
local request = RS:WaitForChild("RequestRebirth")
local refreshed = RS:WaitForChild("DataRefresh")
local cooldown = {}

local function publish(player, d)
 local snow, luck = R.Multipliers(d.Rebirths)
 player:SetAttribute("Rebirths", R.Count(d.Rebirths))
 player:SetAttribute("RebirthSnowMult", snow)
 player:SetAttribute("RebirthLuckMult", luck)
 D.SetStat(player, "Rebirths", R.Count(d.Rebirths))
end
D.OnLoaded(publish)
Players.PlayerRemoving:Connect(function(p) cooldown[p] = nil end)

request.OnServerInvoke = function(player, expected)
 local now = os.clock()
 if cooldown[player] and now - cooldown[player] < 1 then return false, "Please wait a moment." end
 cooldown[player] = now
 local d = D.Get(player)
 local char = player.Character
 local root = char and char:FindFirstChild("HumanoidRootPart")
 local hum = char and char:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health <= 0 then return false, "Wait until your character has respawned." end
 local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
 if not spawn then return false, "The spawn point is unavailable. Please try again." end
 local ok, result = Rules.Apply(d, expected)
 if not ok then return false, result end

 -- Reset replicated gameplay state immediately, before any further collection ticks.
 local stats = U.Calculate(d.Upgrades, player:GetAttribute("FriendsHere") or 0)
 local snow, luck = R.Multipliers(d.Rebirths)
 stats.SnowMult *= snow
 stats.LuckMult *= luck
 for k, v in pairs(stats) do player:SetAttribute(k, v) end
 for id in pairs(U.ById) do player:SetAttribute("Up_" .. id, d.Upgrades[id] == true) end -- 2026-10-03 (Claude): upgrades are kept on rebirth
 for _, s in ipairs(StageConfig.Order) do player:SetAttribute("Stage_" .. s.Id, s.Id == "Starter") end
 player:SetAttribute("EquippedShovels", table.concat(d.Equipped, ","))
 player:SetAttribute("EquippedPets", table.concat(d.EquippedPets, ","))
 hum.WalkSpeed = stats.WalkSpeed
 D.SetStat(player, "Snow", 0)
 publish(player, d)
 -- 2026-10-04 (Claude): a rebirth always brings you back to World 1. Reset the World attribute (otherwise every respawn sends you to
 -- the now-locked World 2 plaza) and load the spawn area first, like the World 2 portal does (StreamingEnabled is on).
 player:SetAttribute("World", 1)
 pcall(function() player:RequestStreamAroundAsync(spawn.Position, 8) end)
 root.AssemblyLinearVelocity = Vector3.zero
 char:PivotTo(spawn.CFrame + Vector3.new(0, spawn.Size.Y / 2 + 4, 0))
 SS.AdminHooks.ReapplyUpgrades:Fire(player)
 SS.AdminHooks.ReapplyStages:Fire(player)
 refreshed:FireClient(player)
 task.spawn(D.Save, player)
 return true, "Rebirth complete! Your permanent bonuses are active."
end
