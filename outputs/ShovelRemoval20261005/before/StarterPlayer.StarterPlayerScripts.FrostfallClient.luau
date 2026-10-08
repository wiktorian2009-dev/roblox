-- Light, local animation and interactions for Frostfall Village.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Prompts = game:GetService("ProximityPromptService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local village = workspace:WaitForChild("FrostfallVillage", 60)
if not village then return end
local gui = player:WaitForChild("PlayerGui"):WaitForChild("RNGGui")
local openMenu = gui:WaitForChild("VillageOpenMenu")
local center = village:GetAttribute("Origin")
local movers = {}
for _,item in ipairs(village:GetDescendants()) do
 local motion = item:GetAttribute("VillageMotion")
 if motion then table.insert(movers, {item=item, motion=motion, base=item:IsA("Model") and item:GetPivot() or item.CFrame, phase=item:GetAttribute("Phase") or 0}) end
end
local effects = Instance.new("Folder")
effects.Name = "FrostfallLocalEffects"
effects.Parent = workspace
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "FrostfallToast"
toastGui.ResetOnSpawn = false
toastGui.DisplayOrder = 25
toastGui.Parent = player.PlayerGui
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(.5,0)
toast.Position = UDim2.fromScale(.5,.13)
toast.Size = UDim2.new(.65,0,0,46)
toast.BackgroundTransparency = 1
toast.TextColor3 = Color3.fromRGB(245,252,255)
toast.TextStrokeColor3 = Color3.fromRGB(29,55,83)
toast.TextStrokeTransparency = .1
toast.Font = Enum.Font.FredokaOne
toast.TextScaled = true
toast.Visible = false
toast.Parent = toastGui
local textLimit = Instance.new("UITextSizeConstraint")
textLimit.MaxTextSize = 30
textLimit.Parent = toast
local generation = 0
local function message(text)
 generation += 1
 local token = generation
 toast.Text = text; toast.TextTransparency = 0; toast.TextStrokeTransparency = .1; toast.Visible = true
 task.delay(2.1,function()
  if generation ~= token then return end
  TweenService:Create(toast,TweenInfo.new(.4),{TextTransparency=1,TextStrokeTransparency=1}):Play()
  task.delay(.4,function() if generation==token then toast.Visible=false end end)
 end)
end
local random = Random.new()
local function snowBurst(position)
 for i=1,26 do
  local flake = Instance.new("Part")
  flake.Name="CelebrationSnow";flake.Shape=Enum.PartType.Ball
  local size=random:NextNumber(.18,.48);flake.Size=Vector3.one*size
  flake.Material=Enum.Material.Neon
  flake.Color=i%4==0 and Color3.fromRGB(255,205,92) or Color3.fromRGB(217,247,255)
  flake.Anchored=true;flake.CanCollide=false;flake.CanTouch=false;flake.CanQuery=false
  flake.Position=position;flake.Parent=effects
  local a=i*math.pi*2/26
  local reach=random:NextNumber(3,9)
  TweenService:Create(flake,TweenInfo.new(random:NextNumber(.8,1.5),Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=position+Vector3.new(math.cos(a)*reach,random:NextNumber(1,7),math.sin(a)*reach),Transparency=1,Size=Vector3.one*.06}):Play()
  Debris:AddItem(flake,1.6)
 end
end
local last = {}
local shakeUntil = 0
Prompts.PromptTriggered:Connect(function(prompt, who)
 if who ~= player or not prompt:IsDescendantOf(village) or player:GetAttribute("IntroActive") then return end
 local anchor=prompt.Parent
 local action=anchor:GetAttribute("VillageAction")
 if not action then return end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or (root.Position-anchor.Position).Magnitude>prompt.MaxActivationDistance+3 then return end
 if action=="Upgrades" or action=="Pets" or action=="Shop" or action=="Rebirth" then
  openMenu:Fire(action)
 elseif action=="Globe" or action=="Celebrate" then
  local now=os.clock()
  if now-(last[action] or -math.huge)<4 then return end
  last[action]=now
  if action=="Globe" then
   shakeUntil=now+2
   snowBurst(village.Snowglobe.GlassDome.Position)
   message("A little winter magic!")
  else
   snowBurst(anchor:GetAttribute("EffectPosition") or anchor.Position)
   message("Frost Hop complete! Nice jumping!")
  end
 end
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or (root.Position-center).Magnitude>180 then return end
 local t=os.clock()
 for _,v in ipairs(movers) do
  if v.item.Parent then
   if v.motion=="Spin" then
    v.item:PivotTo(v.base*CFrame.Angles(0,t*.3,0))
   elseif v.motion=="Snow" then
    local speed=t<shakeUntil and 8 or 1.4
    v.item.CFrame=v.base+Vector3.new(math.sin(t*speed+v.phase)*.35,math.sin(t*speed+v.phase)*.75,math.cos(t*speed+v.phase)*.35)
   elseif v.motion=="Smoke" then
    local rise=(t*.3+v.phase*.22)%1
    v.item.CFrame=v.base+Vector3.new(math.sin(t+v.phase)*.3,rise*1.7,0)
    v.item.Transparency=.5+rise*.5
   elseif v.motion=="Crystal" then
    v.item.CFrame=CFrame.new(v.base.Position+Vector3.new(0,math.sin(t*1.6)*.4,0))*CFrame.Angles(0,t*.5,0)*v.base.Rotation
   end
  end
 end
end)

