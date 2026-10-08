local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
-- Resolve only after startup has either finished the cinematic or safely failed.
player:SetAttribute("IntroReady",false)
local Intro
task.spawn(function()
 local ok,err=xpcall(function()
  Intro=require(RS:WaitForChild("SnowIntroController"))
  local char=player.Character or player.CharacterAdded:Wait()
  if not char:WaitForChild("HumanoidRootPart",15) then return end
  local deadline=os.clock()+5
  repeat task.wait(.1) until player:HasAppearanceLoaded() or os.clock()>deadline
  player:WaitForChild("leaderstats",10)
  task.wait(.35)
  -- The loading screen (ReplicatedFirst) covers the join; start the cinematic only once it says everything is
  -- loaded, so the fade reveals the very first frame instead of hiding it. 45 s cap: it can never hang.
  local limit=os.clock()+45
  while player:GetAttribute("LoadingScreenActive")==true and player:GetAttribute("LoadingReady")~=true and os.clock()<limit do task.wait(.1) end
  if player.Character==char then Intro.Play() end
 end,debug.traceback)
 player:SetAttribute("IntroReady",true)
 if not ok then warn("[SnowIntro startup] "..tostring(err)) end
end)
-- Studio convenience: I replays the intro without resetting progress.
if RunService:IsStudio() then
 game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
  if not processed and input.KeyCode==Enum.KeyCode.I and Intro and player:GetAttribute("IntroReady") and not player:GetAttribute("IntroPlaying") then
   task.spawn(Intro.Play,{Preview=true})
  end
 end)
end