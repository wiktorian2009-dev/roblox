local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local R = require(RS:WaitForChild("RebirthConfig"))
local Stages = require(RS:WaitForChild("StageConfig"))
local Format = require(RS:WaitForChild("NumberFormat"))
local request = RS:WaitForChild("RequestRebirth")
local gui = script.Parent
local panel = gui:WaitForChild("Panels"):WaitForChild("Rebirth")
local content = panel:WaitForChild("Inner"):WaitForChild("Content")
local aspect = panel:FindFirstChildOfClass("UIAspectRatioConstraint")
if aspect then aspect:Destroy() end
panel.Size = UDim2.fromScale(0.88, 0.82)
panel.BackgroundTransparency = 0
panel.BackgroundColor3 = Color3.fromRGB(230, 240, 255)
panel.BorderSizePixel = 0
panel:WaitForChild("Background").Visible = false
panel:WaitForChild("UICorner").CornerRadius = UDim.new(0, 24)
local outline = Instance.new("UIStroke")
outline.Name = "RebirthOutline"
outline.Color = Color3.fromRGB(80, 55, 130)
outline.Thickness = 5
outline.Parent = panel
panel.Banner.AnchorPoint = Vector2.new(0.5, 0)
panel.Banner.Position = UDim2.fromScale(0.5, 0.035)
panel.Banner.Size = UDim2.fromScale(0.6, 0.11)
panel.Close.AnchorPoint = Vector2.new(1, 0)
panel.Close.Position = UDim2.fromScale(0.98, 0.02)
panel.Close.Size = UDim2.fromScale(0.075, 0.09)
panel.Close.Text = "×"
panel.Close.Font = Enum.Font.FredokaOne
panel.Close.TextScaled = true
panel.Close.TextColor3 = Color3.new(1, 1, 1)
panel.Close.BackgroundTransparency = 0
panel.Close.BackgroundColor3 = Color3.fromRGB(215, 65, 95)
local closeSize = Instance.new("UISizeConstraint")
closeSize.MinSize = Vector2.new(44, 44)
closeSize.Parent = panel.Close
for _, image in ipairs(panel.Close:GetChildren()) do if image:IsA("ImageLabel") then image.Visible = false end end
local max = Instance.new("UISizeConstraint")
max.MaxSize = Vector2.new(760, 670)
max.Parent = panel
panel.Inner.Position = UDim2.fromScale(0.065, 0.18)
panel.Inner.Size = UDim2.fromScale(0.87, 0.76)
for _, c in ipairs(content:GetChildren()) do c:Destroy() end
content.CanvasSize = UDim2.new()
content.AutomaticCanvasSize = Enum.AutomaticSize.None
content.ScrollingEnabled = false
content.ScrollBarThickness = 0

local WHITE = Color3.fromRGB(250, 250, 255)
local NAVY = Color3.fromRGB(31, 35, 76)
local function make(class, props, parent)
 local o = Instance.new(class)
 for k,v in pairs(props) do o[k] = v end
 o.Parent = parent
 return o
end
local function rounded(o)
 make("UICorner", {CornerRadius = UDim.new(0.16, 0)}, o)
end
local function label(name, value, x, y, w, h, color, parent)
 local o = make("TextLabel", {Name=name, Text=value, Font=Enum.Font.FredokaOne, TextColor3=color or NAVY,
  BackgroundTransparency=1, TextScaled=true, TextWrapped=true, Position=UDim2.fromScale(x,y), Size=UDim2.fromScale(w,h)}, parent or content)
 make("UITextSizeConstraint", {MaxTextSize=27, MinTextSize=9}, o)
 return o
end
local countLabel = label("Count", "REBIRTH 0", 0, 0, 1, 0.08)
local subtitle = label("Subtitle", "A fresh start. Permanent rewards.", 0, 0.085, 1, 0.055)
local function bonusCard(name, heading, x, color)
 local f=make("Frame", {Name=name, BackgroundColor3=color, BorderSizePixel=0, Position=UDim2.fromScale(x,0.16),Size=UDim2.fromScale(0.48,0.19)},content)
 rounded(f)
 label("Heading",heading,0.04,0.1,0.92,0.3,WHITE,f)
 return label("Value","x1 → x1.5",0.04,0.46,0.92,0.4,WHITE,f)
end
local snowBonus=bonusCard("SnowBonus","SNOW INCOME",0,Color3.fromRGB(40,135,215))
local luckBonus=bonusCard("LuckBonus","ROLL LUCK",0.52,Color3.fromRGB(135,75,210))
local requirement=label("Requirement","",0.02,0.375,0.96,0.07)
local price=label("Price","",0.02,0.45,0.96,0.06)
local track=make("Frame",{Name="Progress",Position=UDim2.fromScale(0.05,0.525),Size=UDim2.fromScale(0.9,0.018),BackgroundColor3=Color3.fromRGB(185,200,225),BorderSizePixel=0},content)
rounded(track)
local fill=make("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(85,205,135),BorderSizePixel=0},track)
rounded(fill)
local keep=label("Keep","KEEP: all shovels, pets, discoveries and settings",0.03,0.565,0.94,0.085,Color3.fromRGB(30,115,65))
local reset=label("Reset","RESET: all Snow, unlocked stages and upgrades",0.03,0.66,0.94,0.085,Color3.fromRGB(170,45,65))
local function button(name, text, x, w, color)
 local b=make("TextButton",{Name=name,Text=text,Font=Enum.Font.FredokaOne,TextColor3=WHITE,TextScaled=true,TextWrapped=true,
  AutoButtonColor=true,Position=UDim2.fromScale(x,0.775),Size=UDim2.fromScale(w,0.13),BackgroundColor3=color,BorderSizePixel=0},content)
 rounded(b)
 make("UITextSizeConstraint",{MaxTextSize=27,MinTextSize=10},b)
 make("UIStroke",{Thickness=2,Color=NAVY,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b)
 return b
end
local buy=button("RebirthButton","REBIRTH",0.08,0.84,Color3.fromRGB(135,70,210))
local cancel=button("CancelRebirth","CANCEL",0.04,0.3,Color3.fromRGB(105,120,150))
cancel.Visible=false
local status=label("Status","",0.02,0.925,0.96,0.065)
local confirming, expected, busy = false, nil, false
local feedback = ""
local function mult(n) return ("x%.2f"):format(n):gsub("0+$",""):gsub("%.$","") end
local function snow()
 local ls=player:FindFirstChild("leaderstats")
 return ls and ls:FindFirstChild("Snow") and ls.Snow.Value or 0
end
local function refresh()
 local raw=player:GetAttribute("Rebirths")
 local count=R.Count(raw)
 local req=R.Requirement(count)
 local a,b=R.Multipliers(count)
 local na,nb=R.Multipliers(req and req.Level or count)
 snowBonus.Text=mult(a).." → "..mult(na)
 luckBonus.Text=mult(b).." → "..mult(nb)
 countLabel.Text="REBIRTH "..count.." / "..R.MaxRebirths
 local ready=raw~=nil and req and player:GetAttribute("Stage_"..req.Stage)==true and snow()>=req.Cost
 requirement.Text=req and ((player:GetAttribute("Stage_"..req.Stage)==true and "✓ " or "Unlock ")..Stages.ById[req.Stage].Name) or "All rebirth milestones complete!"
 price.Text=req and ("Snow: "..Format.Abbreviate(snow()).." / "..Format.Abbreviate(req.Cost)) or "Enjoy your permanent bonuses!"
 fill.Size=UDim2.fromScale(req and math.clamp(snow()/req.Cost,0,1) or 1,1)
 if confirming and (expected~=count or not ready) then confirming=false end
 cancel.Visible=confirming
 buy.Position=UDim2.fromScale(confirming and 0.38 or 0.08,0.775)
 buy.Size=UDim2.fromScale(confirming and 0.58 or 0.84,0.13)
 buy.Text=busy and "REBIRTHING..." or confirming and "CONFIRM RESET" or not req and "MAX REBIRTH" or ready and "REBIRTH!" or "NOT READY YET"
 buy.BackgroundColor3=ready and (confirming and Color3.fromRGB(205,65,95) or Color3.fromRGB(135,70,210)) or Color3.fromRGB(125,135,155)
 buy.Active=ready==true and not busy
 buy.AutoButtonColor=ready==true and not busy
 subtitle.Text=confirming and "Ready to reset and grow stronger?" or "A fresh start. Permanent rewards."
 status.Text=feedback~="" and feedback or confirming and "Extra equip slots reset too. Your items stay in inventory." or "Bonuses multiply with upgrades and other boosts."
end
buy.Activated:Connect(function()
 if busy then return end
 local count=R.Count(player:GetAttribute("Rebirths"))
 local req=R.Requirement(count)
 if not req or player:GetAttribute("Stage_"..req.Stage)~=true or snow()<req.Cost then return end
 if not confirming then confirming=true expected=count feedback="" refresh() return end
 busy=true refresh()
 local ok,success,message=pcall(function() return request:InvokeServer(expected) end)
 busy=false confirming=false
 feedback=ok and tostring(message or "Please try again.") or "Connection problem. Please try again."
 if ok and success then
  feedback="REBIRTH COMPLETE! Your permanent boosts are active."
  local scale=panel:FindFirstChildOfClass("UIScale")
  if scale then scale.Scale=0.94 TweenService:Create(scale,TweenInfo.new(0.35,Enum.EasingStyle.Back),{Scale=1}):Play() end
 end
 refresh()
end)
cancel.Activated:Connect(function() confirming=false feedback="" refresh() end)
panel:GetPropertyChangedSignal("Visible"):Connect(function()
 gui:SetAttribute("RebirthMenuOpen",panel.Visible)
 confirming=false feedback=""
 if panel.Visible then refresh() end
end)
player:GetAttributeChangedSignal("Rebirths"):Connect(refresh)
for _,s in ipairs(Stages.Order) do player:GetAttributeChangedSignal("Stage_"..s.Id):Connect(function() if panel.Visible then refresh() end end) end
task.spawn(function() player:WaitForChild("leaderstats"):WaitForChild("Snow").Changed:Connect(function() if panel.Visible then refresh() end end) end)
gui:SetAttribute("RebirthMenuOpen",panel.Visible)
refresh()
