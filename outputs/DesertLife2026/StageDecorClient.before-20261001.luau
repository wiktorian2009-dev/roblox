-- Quiet local scenic movement. Only animate nearby streamed scenery, at most 25 updates/sec.
local RunService=game:GetService("RunService")
local root=workspace:WaitForChild("StageDecor20260930",30)
if not root then return end
local entries={};local registered=setmetatable({},{__mode="k"});local particles={}
local function register(o)
 if o:IsA("ParticleEmitter")then particles[o]=true end
 local kind=o:GetAttribute("StageDecorMotion")
 if not kind or registered[o]or not(o:IsA("BasePart")or o:IsA("Model"))then return end
 registered[o]=true
 local cf=o:IsA("Model")and o:GetPivot()or o.CFrame
 table.insert(entries,{object=o,base=cf,kind=kind,amount=o:GetAttribute("MotionAmount")or .3,
  speed=o:GetAttribute("MotionSpeed")or .8,phase=o:GetAttribute("MotionPhase")or 0})
 script:SetAttribute("AnimatedCount",#entries)
end
for _,o in root:GetDescendants()do register(o)end
root.DescendantAdded:Connect(register)
local elapsed,nextFrame,particleTick=0,0,0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;nextFrame+=dt;particleTick+=dt
 if nextFrame<.04 then return end;nextFrame=0
 local camera=workspace.CurrentCamera;if not camera then return end
 local view=camera.CFrame.Position
 for i=#entries,1,-1 do
  local e=entries[i];local o=e.object
  if not o:IsDescendantOf(root)then table.remove(entries,i);registered[o]=nil
  elseif(view-e.base.Position).Magnitude<200 then
   local delta
   if e.kind=="Water"then delta=(((e.phase-elapsed*e.speed/e.amount)%1)-.5)*e.amount
   else delta=math.sin(elapsed*e.speed+e.phase)*e.amount end
   local cf=CFrame.new(0,delta,0)*e.base
   if o:IsA("Model")then o:PivotTo(cf)else o.CFrame=cf end
  end
 end
 if particleTick>.4 then
  particleTick=0
  for e in particles do
   if not e:IsDescendantOf(root)then particles[e]=nil
   else local a=e.Parent;local part=a and a.Parent
    if part and part:IsA("BasePart")then e.Enabled=(view-part.Position).Magnitude<160 end
   end
  end
 end
end)
