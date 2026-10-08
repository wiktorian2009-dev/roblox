local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Intro=require(RS:WaitForChild("SnowIntroController"))
task.spawn(function()
 local char=player.Character or player.CharacterAdded:Wait()
 if not char:WaitForChild("HumanoidRootPart",15) then return end
 local deadline=os.clock()+5
 repeat task.wait(.1) until player:HasAppearanceLoaded() or os.clock()>deadline
 player:WaitForChild("leaderstats",10)
 task.wait(.35)
 if player.Character==char then Intro.Play() end
end)
-- Studio convenience: I replays the intro without resetting progress.
if RunService:IsStudio() then
 game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
  if not processed and input.KeyCode==Enum.KeyCode.I and not player:GetAttribute("IntroPlaying") then
   task.spawn(Intro.Play,{Preview=true})
  end
 end)
end
