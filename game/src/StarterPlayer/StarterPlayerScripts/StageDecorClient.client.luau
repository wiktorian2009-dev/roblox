-- Quiet local scenic movement. Only animate nearby streamed scenery, at most 25 updates/sec.
-- StageDecorMotion kinds: (default) vertical bob, "Water" sliding streak, "Sway" gentle tilt about the pivot (plants),
-- "Orbit" circle around the start point (birds; MotionRadius), "Roll" roll back and forth along local X (tumbleweeds; MotionRadius).
local RunService=game:GetService("RunService")
-- 2026-10-02 (Claude): also animates World 2 scenery (Workspace.World2). Extra kind "Spin": turns about MotionAxis X/Y/Z at MotionSpeed rad/s.
local roots={}
do local r=workspace:WaitForChild("StageDecor20260930",30);if r then table.insert(roots,r)end
 local w2=workspace:FindFirstChild("World2")or workspace:WaitForChild("World2",10);if w2 then table.insert(roots,w2)end
 -- 2026-10-05 (Claude): World 1 remaster scenery (Workspace.W1Remaster) uses the same motion kinds
 local w1=workspace:FindFirstChild("W1Remaster")or workspace:WaitForChild("W1Remaster",10);if w1 then table.insert(roots,w1)end end
if #roots==0 then return end
local function inRoots(o)for _,r in ipairs(roots)do if o:IsDescendantOf(r)then return true end end return false end
local entries={};local registered=setmetatable({},{__mode="k"});local particles={}
local function register(o)
 if o:IsA("ParticleEmitter")then particles[o]=true end
 local kind=o:GetAttribute("StageDecorMotion")
 if not kind or registered[o]or not(o:IsA("BasePart")or o:IsA("Model"))then return end
 registered[o]=true
 local cf=o:IsA("Model")and o:GetPivot()or o.CFrame
 table.insert(entries,{object=o,base=cf,kind=kind,amount=o:GetAttribute("MotionAmount")or .3,
  speed=o:GetAttribute("MotionSpeed")or .8,phase=o:GetAttribute("MotionPhase")or 0,radius=o:GetAttribute("MotionRadius")or 20})
 script:SetAttribute("AnimatedCount",#entries)
end
for _,r in ipairs(roots)do for _,o in r:GetDescendants()do register(o)end;r.DescendantAdded:Connect(register)end
local elapsed,nextFrame,particleTick=0,0,0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;nextFrame+=dt;particleTick+=dt
 if nextFrame<.04 then return end;nextFrame=0
 local camera=workspace.CurrentCamera;if not camera then return end
 local view=camera.CFrame.Position
 for i=#entries,1,-1 do
  local e=entries[i];local o=e.object
  if not inRoots(o)then table.remove(entries,i);registered[o]=nil
  elseif(view-e.base.Position).Magnitude<((e.kind=="Orbit"or e.kind=="Loop")and 200+e.radius or 200)then
   local cf;local t=elapsed*e.speed+e.phase
   if e.kind=="Water"then cf=CFrame.new(0,(((e.phase-elapsed*e.speed/e.amount)%1)-.5)*e.amount,0)*e.base
   elseif e.kind=="Sway"then cf=e.base*CFrame.Angles(math.sin(t)*e.amount,0,math.sin(t*.73+1.3)*e.amount*.6)
   elseif e.kind=="Orbit"then
    local p=e.base.Position+Vector3.new(math.cos(t)*e.radius,math.sin(t*2.3)*e.amount,math.sin(t)*e.radius)
    cf=CFrame.lookAt(p,p+Vector3.new(-math.sin(t),0,math.cos(t)))*CFrame.Angles(0,0,-.3)
   elseif e.kind=="Roll"then
    local x=math.sin(t)*e.radius
    cf=e.base*CFrame.new(x,math.abs(math.sin(t*5))*e.amount,0)*CFrame.Angles(0,0,-x/1.3)
   elseif e.kind=="Loop"then -- 2026-10-03 (Claude): level circle, no banking (toy train); centre = LoopCenter attribute or the start point
    local c=o:GetAttribute("LoopCenter")or e.base.Position
    local p=Vector3.new(c.X+math.cos(t)*e.radius,e.base.Position.Y,c.Z+math.sin(t)*e.radius)
    cf=CFrame.lookAt(p,p+Vector3.new(-math.sin(t),0,math.cos(t)))
   elseif e.kind=="Spin"then
    local ax=o:GetAttribute("MotionAxis")or"Y";local a=elapsed*e.speed+e.phase
    cf=e.base*(ax=="X"and CFrame.Angles(a,0,0)or ax=="Z"and CFrame.Angles(0,0,a)or CFrame.Angles(0,a,0))
   else cf=CFrame.new(0,math.sin(t)*e.amount,0)*e.base end
   if o:IsA("Model")then o:PivotTo(cf)else o.CFrame=cf end
  end
 end
 if particleTick>.4 then
  particleTick=0
  for e in particles do
   if not inRoots(e)then particles[e]=nil
   else local a=e.Parent;local part=a and a.Parent
    if part and part:IsA("BasePart")then e.Enabled=(view-part.Position).Magnitude<160 end
   end
  end
 end
end)
