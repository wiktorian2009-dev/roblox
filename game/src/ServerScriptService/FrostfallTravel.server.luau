-- Shortcuts between the main Frostfall lobby and its connected snow field.
local Players = game:GetService("Players")
local Prompts = game:GetService("ProximityPromptService")
local village = workspace:WaitForChild("FrostfallVillage")
local cooldown = {}
local targets = {Village = village.Arrival.Value, Main = village.MainArrival.Value, Field = village.FieldArrival.Value}

Prompts.PromptTriggered:Connect(function(prompt, player)
 if prompt.Name ~= "VillagePrompt" then return end
 if not prompt:IsDescendantOf(village) then return end
 local anchor = prompt.Parent
 local target = targets[anchor:GetAttribute("VillageTravel")]
 if not target or not anchor:IsA("BasePart") then return end
 local character = player.Character
 local root = character and character:FindFirstChild("HumanoidRootPart")
 local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
 if not root or not humanoid or humanoid.Health <= 0 or player:GetAttribute("IntroActive") then return end
 if (root.Position - anchor.Position).Magnitude > prompt.MaxActivationDistance + 3 then return end
 local now = os.clock()
 if now - (cooldown[player] or -math.huge) < 1.5 then return end
 cooldown[player] = now
 -- Request the destination before moving, with a bounded streaming wait.
 pcall(function() player:RequestStreamAroundAsync(target.Position, 2) end)
 if player.Character ~= character or humanoid.Health <= 0 then return end
 character:PivotTo(target)
 root.AssemblyLinearVelocity = Vector3.zero
 root.AssemblyAngularVelocity = Vector3.zero
end)
Players.PlayerRemoving:Connect(function(player) cooldown[player] = nil end)

