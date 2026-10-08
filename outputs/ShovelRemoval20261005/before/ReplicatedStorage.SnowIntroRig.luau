-- SnowIntroRig: an anchored, joint-solved copy of the player's avatar for the arrival cinematic.
-- Supports R6 and R15 (Motor6D or AnimationConstraint). Poses are pure math (no physics, no animation
-- playback), so the cinematic can be scrubbed to any time and always restores cleanly.
local Rig={}
Rig.__index=Rig
local V,ZERO=Vector3.new,Vector3.zero
local rad=math.rad

local function eul(v)return CFrame.Angles(rad(v.X),rad(v.Y),rad(v.Z))end

-- CFrame that puts local point lp at world point wp, local axis la along world axis wa and
-- turns local direction lh as close as possible to world direction wh (fixes the roll).
local function place(lp,la,lh,wp,wa,wh)
 la=la.Unit
 local h=lh-la*lh:Dot(la)
 if h.Magnitude<1e-4 then h=la:Cross(V(1,0,0));if h.Magnitude<1e-4 then h=la:Cross(V(0,0,1))end end
 h=h.Unit
 wa=wa.Unit
 local g=wh-wa*wh:Dot(wa)
 if g.Magnitude<1e-4 then g=wa:Cross(V(1,0,0));if g.Magnitude<1e-4 then g=wa:Cross(V(0,0,1))end end
 g=g.Unit
 local L=CFrame.fromMatrix(ZERO,la,h,la:Cross(h))
 local W=CFrame.fromMatrix(ZERO,wa,g,wa:Cross(g))
 local R=W*L:Inverse()
 return CFrame.new(wp-R:VectorToWorldSpace(lp))*R
end
Rig.place=place

function Rig.new(char,parent)
 local was=char.Archivable;char.Archivable=true
 local ok,actor=pcall(function()return char:Clone()end)
 char.Archivable=was
 assert(ok and actor,"Avatar could not be cloned")
 actor.Name="IntroActor"
 for _,o in ipairs(actor:GetDescendants())do
  if o:IsA("LuaSourceContainer") or o:IsA("Animator") or o:IsA("Tool") or o:IsA("ForceField") or o:IsA("Sound")then o:Destroy()
  elseif o:IsA("BasePart")then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.LocalTransparencyModifier=0 end
 end
 local root=actor:FindFirstChild("HumanoidRootPart");assert(root,"Avatar root missing")
 local hum=actor:FindFirstChildOfClass("Humanoid");assert(hum,"Avatar humanoid missing")
 root.Anchored=true;root.Transparency=1;actor.PrimaryPart=root
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 hum.AutoRotate=false;hum.BreakJointsOnDeath=false;hum.RequiresNeck=false
 local rest,parts={},{}
 for _,o in ipairs(actor:GetDescendants())do
  if o:IsA("BasePart")then rest[o]=root.CFrame:ToObjectSpace(o.CFrame);parts[#parts+1]=o end
 end
 -- Collect every joint, then remove them: the clone is solved directly, never simulated.
 local links={}
 for _,o in ipairs(actor:GetDescendants())do
  local a,b,c0,c1
  if o:IsA("JointInstance")then a,b,c0,c1=o.Part0,o.Part1,o.C0,o.C1
  elseif o:IsA("AnimationConstraint") or o:IsA("RigidConstraint")then
   local at0,at1=o.Attachment0,o.Attachment1
   if at0 and at1 then a,b,c0,c1=at0.Parent,at1.Parent,at0.CFrame,at1.CFrame end
  elseif o:IsA("WeldConstraint")then
   if o.Part0 and o.Part1 and rest[o.Part0] and rest[o.Part1]then a,b,c0,c1=o.Part0,o.Part1,rest[o.Part0]:ToObjectSpace(rest[o.Part1]),CFrame.new()end
  end
  if a and b and a:IsA("BasePart") and b:IsA("BasePart")then links[#links+1]={name=(o.Name:gsub(" ","")),a=a,b=b,c0=c0,c1=c1}end
 end
 for _,o in ipairs(actor:GetDescendants())do
  if o:IsA("JointInstance") or o:IsA("Constraint") or o:IsA("WeldConstraint")then o:Destroy()end
 end
 -- Breadth-first order from the root so one pass solves the whole skeleton.
 local adj={}
 for _,l in ipairs(links)do
  adj[l.a]=adj[l.a] or {};adj[l.b]=adj[l.b] or {}
  table.insert(adj[l.a],{l=l,to=l.b,fwd=true});table.insert(adj[l.b],{l=l,to=l.a,fwd=false})
 end
 local order,seen,queue,qi={}, {[root]=true},{root},1
 while qi<=#queue do
  local p=queue[qi];qi+=1
  for _,e in ipairs(adj[p] or {})do
   if not seen[e.to]then seen[e.to]=true;order[#order+1]={l=e.l,from=p,to=e.to,fwd=e.fwd};queue[#queue+1]=e.to end
  end
 end
 local byName={}
 for _,l in ipairs(links)do if not byName[l.name]then byName[l.name]=l end end
 -- Arm chains: R15 shoulder/elbow/wrist (two-bone), R6 shoulder only (single bone).
 local arms={}
 for _,side in ipairs({"Right","Left"})do
  local sh=byName[side.."Shoulder"]
  if sh then
   local A={sh=sh}
   local el,wr=byName[side.."Elbow"],byName[side.."Wrist"]
   if el and wr then
    A.el,A.wr=el,wr
    A.uVec=el.c0.Position-sh.c1.Position;A.uLen=A.uVec.Magnitude
    A.lVec=wr.c0.Position-el.c1.Position;A.lLen=A.lVec.Magnitude
    A.hVec=ZERO-wr.c1.Position;A.hLen=A.hVec.Magnitude
    if A.hLen<.03 then A.hVec=V(0,-.1,0);A.hLen=.1 end
    A.reach=A.uLen+A.lLen+A.hLen
   else
    local palm=V(0,-sh.b.Size.Y*.35,0)
    A.pVec=palm-sh.c1.Position;A.pLen=A.pVec.Magnitude;A.reach=A.pLen
   end
   arms[side]=A
  end
 end
 local self=setmetatable({actor=actor,root=root,hum=hum,rest=rest,parts=parts,links=links,order=order,byName=byName,arms=arms,
  kind=hum.RigType==Enum.HumanoidRigType.R6 and "R6" or "R15"},Rig)
 local S=self:solve(CFrame.new(),nil)
 self.shoulderRest={}
 for side,A in pairs(arms)do self.shoulderRest[side]=(S[A.sh.a]*A.sh.c0).Position end
 local r=arms.Right and arms.Right.reach or 1.5
 local l=arms.Left and arms.Left.reach or 1.5
 self.armReach=math.min(r,l)
 actor.Parent=parent
 return self
end

-- Forward kinematics. rot[jointName]=Vector3 degrees applied about the parent part's axes;
-- off[jointName]=Vector3 studs added to the joint's parent-side offset (used for the neck shrug).
function Rig:solve(world,rot,off)
 local S={[self.root]=world}
 for _,e in ipairs(self.order)do
  local l=e.l
  local v=rot and rot[l.name] or ZERO
  local o=off and off[l.name]
  local T=CFrame.new(o and (l.c0.Position+o) or l.c0.Position)*eul(v)*l.c0.Rotation*l.c1:Inverse()
  if e.fwd then S[e.to]=S[e.from]*T else S[e.to]=S[e.from]*T:Inverse() end
 end
 return S
end

function Rig:shoulder(S,side)
 local A=self.arms[side]
 return A and (S[A.sh.a]*A.sh.c0).Position
end

-- Moves the arm so its palm reaches `target` (world). opts: weight (0..1 blend with FK), pole (world
-- direction the elbow points), forward (world torso forward, roll hint for R6). Returns the palm position.
function Rig:reach(S,side,target,opts)
 local A=self.arms[side];if not A then return nil end
 opts=opts or {}
 local w=opts.weight or 1
 if w<=.001 then return nil end
 local sh=A.sh
 local sp=(S[sh.a]*sh.c0).Position
 local fwd=opts.forward or V(0,0,-1)
 local to=target-sp
 if to.Magnitude<1e-3 then return nil end
 if A.el then
  local wristT=target-to.Unit*A.hLen
  local delta=wristT-sp
  local dir=delta.Magnitude>1e-3 and delta.Unit or to.Unit
  local d=math.clamp(delta.Magnitude,.05,A.uLen+A.lLen-.01)
  local along=(A.uLen^2-A.lLen^2+d^2)/(2*d)
  local rise=math.sqrt(math.max(0,A.uLen^2-along^2))
  local pole=opts.pole or V(0,-1,0)
  pole=pole-dir*pole:Dot(dir)
  if pole.Magnitude<1e-3 then pole=fwd-dir*fwd:Dot(dir)end
  if pole.Magnitude<1e-3 then pole=dir:Cross(V(1,0,0))end
  pole=pole.Unit
  local elbow=sp+dir*along+pole*rise
  local wrist=sp+dir*d
  local front=-pole
  local up=place(sh.c1.Position,A.uVec,V(0,0,-1),sp,elbow-sp,front)
  local lo=place(A.el.c1.Position,A.lVec,V(0,0,-1),elbow,wrist-elbow,front)
  local hdir=(wrist-elbow).Unit
  local ha=place(A.wr.c1.Position,A.hVec,V(0,0,-1),wrist,hdir,front)
  S[sh.b]=S[sh.b]:Lerp(up,w);S[A.el.b]=S[A.el.b]:Lerp(lo,w);S[A.wr.b]=S[A.wr.b]:Lerp(ha,w)
  return wrist+hdir*A.hLen
 end
 local dir=to.Unit
 S[sh.b]=S[sh.b]:Lerp(place(sh.c1.Position,A.pVec,V(0,0,-1),sp,dir,fwd),w)
 return sp+dir*A.pLen
end

function Rig:commit(S)
 local cfs={}
 local rootCF=S[self.root]
 for i,p in ipairs(self.parts)do cfs[i]=S[p] or (rootCF*self.rest[p])end
 workspace:BulkMoveTo(self.parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
end

function Rig:fade(x)
 for _,p in ipairs(self.parts)do if p~=self.root then p.LocalTransparencyModifier=x end end
end

function Rig:destroy()
 if self.actor then self.actor:Destroy()end
end

return Rig
