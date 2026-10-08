-- Six-panel storyboard arrival cinematic (7.9 s): 1 fall, 2 snow landing, 3 shovel discovery, 4 grab,
-- 5 victory, 6 shovel close-up, then a smooth return to the gameplay camera.
-- The avatar (R6 or R15) and the Tin Shovel are the real assets. Every frame is a pure function of time,
-- so Studio can scrub it:  Intro.Play({Preview=true,HoldAt=3.2})  then set the player attribute IntroHoldAt
-- (set IntroHoldEnd to finish). Camera, controls, GUI and character visibility are restored on every exit
-- path (finish, skip, respawn, error). The server still owns placement and the one-time Tin Shovel grant.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local Lighting=game:GetService("Lighting")
local Art=require(RS:WaitForChild("SnowIntroArt"))
local Rig=require(RS:WaitForChild("SnowIntroRig"))
local Request=RS:WaitForChild("SnowIntroRequest")
local player=Players.LocalPlayer
local M={}
local V,C=Vector3.new,Color3.fromRGB
local WHITE=C(252,255,255)
local rad=math.rad

local DURATION=7.9
M.Duration=DURATION
local SCALE=1.5            -- hero scale of the real Tin Shovel model (constant in every shot)
local T_IMPACT=1.5         -- avatar hits the snow
local T_POP=5.22           -- shovel leaves the snow
local T_OUT=7.15           -- shovel released, arms lower, camera heads back to gameplay
-- Stage space: origin on the snow at the intro marker; +X = camera right, +Z = towards the camera
-- (west, so the village stays behind the action), -Z = towards the village.
local LAND=V(-3.2,0,0)
local SHOVEL_AT=V(5,0,-.4)
local BURY=.85
local YT0,YB0=.35,-.15     -- hand grips on the planted shovel (model units along the shaft)
local YT1,YB1=.7,-.7       -- hand grips for the overhead hold

local function ease(t)t=math.clamp(t,0,1);return t*t*(3-2*t)end
local function mix(a,b,t)return a+(b-a)*t end
local function span(t,a,b)return math.clamp((t-a)/(b-a),0,1)end
local function smooth(t,a,b)return ease(span(t,a,b))end
local function bump(t,a,b)return math.sin(span(t,a,b)*math.pi)end
local function mk(class,props,parent)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
-- Smooth (Catmull-Rom) interpolation through {time,value} keys.
local function curve(k,t)
 local n=#k
 if t<=k[1][1]then return k[1][2]end
 if t>=k[n][1]then return k[n][2]end
 local i=1
 while k[i+1][1]<t do i+=1 end
 local a,b=k[i],k[i+1]
 local p,q=k[i-1] or a,k[i+2] or b
 local dt=b[1]-a[1]
 local u=(t-a[1])/dt
 local m0=(b[2]-p[2])/(b[1]-p[1])*dt
 local m1=(q[2]-a[2])/(q[1]-a[1])*dt
 local u2,u3=u*u,u*u*u
 return (2*u3-3*u2+1)*a[2]+(u3-2*u2+u)*m0+(-2*u3+3*u2)*b[2]+(u3-u2)*m1
end

-- Body keys (degrees, studs). yaw 180 faces the camera, 270 faces +X (the shovel), 360/0 faces the village.
-- pitch < 0 leans forward / face-down, > 0 leans back. dy is root height relative to standing.
local K={
 x={{0,-3.4},{1.5,-3.2},{4.2,-3.2},{4.32,-2.7},{4.45,-.9},{4.58,2},{4.7,3.6},{4.82,4.05},{5.12,3.9},{5.22,3.8},{5.32,3.35},{5.5,3},{7.9,3}},
 z={{0,0},{4.2,0},{4.75,-.35},{5.2,-.35},{5.6,0},{7.9,0}},
 yaw={{0,180},{.55,192},{1,222},{1.3,252},{1.5,270},{2.05,270},{2.3,250},{2.6,215},{2.9,192},{3.2,185},{3.9,180},{4.05,185},{4.2,232},{4.35,268},{5.3,272},{5.5,245},{5.75,208},{5.95,182},{7.1,180},{7.3,230},{7.55,330},{7.75,362},{7.9,360}},
 pitch={{0,22},{.5,8},{.95,-25},{1.25,-68},{1.5,-92},{2,-89},{2.3,-58},{2.6,-24},{2.85,-14},{3.2,-12},{3.85,-12},{4.02,6},{4.2,-6},{4.35,-14},{4.62,-12},{4.75,6},{4.95,8},{5.12,16},{5.25,28},{5.5,10},{5.8,3},{6,6},{7,6},{7.25,0},{7.9,0}},
 roll={{0,-8},{.35,12},{.75,-15},{1.15,7},{1.5,0},{7.9,0}},
 dy={{1.5,-2.5},{1.62,-2.95},{1.85,-2.72},{2.5,-2.6},{3.85,-2.6},{4,-2.2},{4.12,-.7},{4.2,.3},{4.32,.05},{4.8,0},{4.95,-.42},{5.15,-.32},{5.26,.08},{5.5,0},{5.7,.05},{5.9,.42},{6.08,.02},{6.45,.2},{6.7,.02},{7.15,0},{7.35,.5},{7.6,.05},{7.9,0}},
 Rr={{0,165},{.7,150},{1.2,172},{1.5,170},{1.9,165},{2.05,60},{2.4,35},{2.6,110},{3.3,110},{3.7,60},{3.85,22},{4.02,170},{4.2,172},{4.36,30},{4.72,60},{7.1,170},{7.4,90},{7.7,12},{7.9,8}},
 Rs={{0,45},{.7,30},{1.2,12},{1.5,8},{1.9,10},{2.05,35},{2.4,30},{2.6,50},{3.3,50},{3.7,25},{4,35},{4.3,20},{7.1,8},{7.9,6}},
 Re={{0,30},{1.2,15},{1.5,15},{2.5,10},{2.7,105},{3.3,108},{3.7,15},{3.9,10},{4.05,20},{4.36,55},{4.72,55},{7.1,10},{7.9,8}},
 Lr={{0,150},{.7,168},{1.2,172},{1.5,170},{1.9,166},{2.05,58},{2.45,32},{3.85,32},{4.02,172},{4.2,172},{4.36,30},{4.72,60},{7.1,170},{7.4,90},{7.7,12},{7.9,8}},
 Ls={{0,48},{.7,38},{1.2,12},{1.5,8},{1.9,10},{2.05,34},{2.45,40},{3.85,36},{4,38},{4.3,20},{7.1,8},{7.9,6}},
 Le={{0,40},{1.2,15},{2.5,10},{3.9,10},{4.05,20},{4.36,55},{7.1,10},{7.9,8}},
 Nx={{0,-12},{1,-15},{1.5,-8},{1.7,40},{2,42},{2.4,10},{2.7,-4},{3.75,-4},{3.9,-6},{4.2,4},{4.4,-2},{5.2,-16},{5.4,10},{5.9,24},{6.3,22},{7,16},{7.3,0},{7.9,0}},
 Ny={{0,0},{3.72,-12},{3.9,66},{3.98,8},{4.06,68},{4.2,55},{4.35,5},{4.6,0},{7.9,0}},
 Nz={{0,0},{2.85,12},{3.6,12},{3.75,0},{7.9,0}},
 Wx={{0,0},{4.9,-8},{5.12,-2},{5.25,16},{5.5,6},{5.9,10},{7,8},{7.3,0},{7.9,0}},
 -- shovel angle in the camera plane (deg, CCW seen from the camera): planted -> carried -> horizontal, grip end to the left
 th={{T_POP,-4},{5.3,6},{5.45,22},{5.62,55},{5.85,92},{5.98,90},{6.1,90},{6.4,90},{6.8,90},{7.5,90}},
 yT={{T_POP,YT0},{5.35,.25},{5.85,YT1},{7.5,YT1}},
 yB={{T_POP,YB0},{5.35,YB0},{5.85,YB1},{7.5,YB1}},
}

-- Timed glints on the shovel: {start, duration, local position (model units), size}
local GLINTS={
 {3.10,.32,V(.25,-1.85,.2),1.3},{3.30,.32,V(-.3,-1.5,.2),1.1},{3.50,.34,V(0,1.85,.25),1.5},
 {6.62,.4,V(.5,-2.1,.25),1.4},{6.74,.4,V(0,1.85,.3),1.5},{6.86,.36,V(-.35,-1.6,.3),1.2},
 {7.2,.3,V(0,.3,.3),1.2},{7.29,.3,V(.3,-.4,.3),1},
}
-- Small snow puffs at the mound: {start, duration, offset from the mound}
local MOUND_PUFFS={{5.02,.5,V(-1,.4,.5)},{5.08,.5,V(1.1,.4,.7)},{T_POP,.7,V(-.6,.6,.8)},{T_POP+.03,.7,V(.9,.6,.5)}}

local function newScene(c)
 local G,H,lift,rig,folder,ready=c.G,c.H,c.lift,c.rig,c.folder,c.ready
 local rs=math.clamp(rig.armReach/1.767,.6,1.4)
 local isR6=rig.kind=="R6"
 local function W(p)return G:PointToWorldSpace(p)end
 local function WV(v)return G:VectorToWorldSpace(v)end
 local stats={errR=0,errL=0,tilt=0}

 ---------------------------------------------------------------- body pose
 local function pose(t)
  local p={x=curve(K.x,t),z=curve(K.z,t),yaw=curve(K.yaw,t),pitch=curve(K.pitch,t),roll=curve(K.roll,t)}
  local dy
  if t<T_IMPACT then local u=t/T_IMPACT;dy=-2.5+43.5*(1-u*u) else dy=curve(K.dy,t) end
  local runE=smooth(t,4.24,4.34)*(1-smooth(t,4.6,4.78))
  dy+=math.abs(math.sin((t-4.2)*23))*.26*runE
  dy+=lift*smooth(t,7.45,DURATION)
  p.dy=dy
  p.roll+=math.sin(t*52)*2.2*smooth(t,4.95,5.02)*(1-smooth(t,5.16,5.22))   -- trembling under the strain
  return p
 end
 local function yawFrame(P)return CFrame.new(P.x,H+P.dy,P.z)*CFrame.Angles(0,rad(P.yaw),0)end
 local function joints(t)
  local rr,rsp,re=curve(K.Rr,t),curve(K.Rs,t),curve(K.Re,t)
  local lr,ls,le=curve(K.Lr,t),curve(K.Ls,t),curve(K.Le,t)
  local nx,ny,nz=curve(K.Nx,t),curve(K.Ny,t),curve(K.Nz,t)
  local base=-12*(1-smooth(t,3.9,4.3))
  local hr,hl,kr,kl,zr=base,base-3,0,0,7
  if t<T_IMPACT then   -- funny flailing fall that settles into a dive
   local f=1-smooth(t,1,1.45)
   local s=math.sin(t*12)
   rr+=math.sin(t*14)*24*f;lr+=math.sin(t*14+2.4)*24*f
   rsp+=math.sin(t*11+1)*13*f;ls+=math.sin(t*11+3)*13*f
   hr=(-8+s*36)*f+base*(1-f);hl=(14-s*36)*f+(base-3)*(1-f)
   kr=-(18+math.max(0,s)*40)*f;kl=-(18+math.max(0,-s)*40)*f
   zr=mix(7,15,f)
   ny+=math.sin(t*7)*22*f;nx+=math.sin(t*9)*10*f
  end
  local shake=smooth(t,2.2,2.35)*(1-smooth(t,2.7,3))   -- confused head shake
  ny+=math.sin((t-2.25)*15)*40*shake;nz+=math.sin((t-2.25)*7.5)*10*shake
  local tuck=bump(t,3.98,4.28)                        -- excited hop out of the snow
  hr+=45*tuck;hl+=45*tuck;kr-=70*tuck;kl-=70*tuck
  local runE=smooth(t,4.24,4.34)*(1-smooth(t,4.6,4.78))
  if runE>0 then
   local ph=(t-4.2)*23;local s=math.sin(ph)
   rr+=s*50*runE;lr-=s*50*runE
   hr+=55*s*runE;hl-=55*s*runE
   kr-=(30+30*math.sin(ph+1))*runE;kl-=(30-30*math.sin(ph+1))*runE
  end
  local cr=smooth(t,4.78,4.95)*(1-smooth(t,5.2,5.3))  -- crouch before the pull
  local lk=isR6 and .3 or 1
  hr+=28*cr*lk;hl+=24*cr*lk;kr-=55*cr;kl-=48*cr;zr+=6*cr
  local J={RightShoulder=V(rr,0,rsp),LeftShoulder=V(lr,0,-ls),RightElbow=V(re,0,0),LeftElbow=V(le,0,0),
   RightHip=V(hr,0,zr),LeftHip=V(hl,0,-zr),RightKnee=V(kr,0,0),LeftKnee=V(kl,0,0),
   Neck=V(nx,ny,nz),Waist=V(curve(K.Wx,t),0,0)}
  local hold=smooth(t,5.55,5.95)*(1-smooth(t,7.05,7.3))  -- shoulders rise, head tucks in under the raised shovel
  return J,{Neck=V(0,-.2*hold,0)}
 end

 ---------------------------------------------------------------- shovel + hands
 local shovel=Art.shovel(folder,c.shovelName,SCALE)
 local PIV_Y=2.54*SCALE-BURY
 local planted=CFrame.new(SHOVEL_AT.X,PIV_Y,SHOVEL_AT.Z)
 -- After the pop the hands carry the shovel: hand-centre offset in the avatar's yaw frame, keyed for continuity.
 -- After the pop the hands carry the shovel: hand-centre offsets relative to the shoulders, keyed for continuity.
 -- Skeleton at time t (stage space): pose, yaw frame, solved FK, and the midpoint between the two shoulder joints.
 -- Hand targets are authored relative to the real shoulders, so they are always within reach of the arms.
 local function skeleton(t)
  local P=pose(t);local J,OFF=joints(t)
  local Fr=yawFrame(P)
  local S=rig:solve(G*(Fr*CFrame.Angles(rad(P.pitch),0,0)*CFrame.Angles(0,0,rad(P.roll))),J,OFF)
  local mid=G:PointToObjectSpace((rig:shoulder(S,"Right")+rig:shoulder(S,"Left"))/2)
  return P,Fr,S,mid
 end
 local _,Fp,_,mid0=skeleton(T_POP)
 local plantedMid=planted*CFrame.Angles(0,0,rad(-4))*V(0,(YT0+YB0)/2*SCALE,0)
 local off0=Fp:VectorToObjectSpace(plantedMid-mid0)
 local ox,oy,oz={{T_POP,off0.X},{5.34,0},{5.5,0},{7.5,0}},{{T_POP,off0.Y}},{{T_POP,off0.Z}}
 for _,k in ipairs({{5.29,.75,-.9},{5.36,.7,-.95},{5.6,1.05,-.85},{5.85,1.5,-.7},{7.5,1.5,-.7}})do
  oy[#oy+1]={k[1],k[2]*rs};oz[#oz+1]={k[1],k[3]*rs}
 end
 local function shovelState(t,Fr,mid)
  if t<T_POP then
   local tilt=-4
   if t>=4.95 then tilt+=math.sin(t*50)*1.4*smooth(t,4.95,5.05)*(1-smooth(t,5.15,5.22))end
   local cf=planted*CFrame.Angles(0,0,rad(tilt))
   return cf,cf*V(0,YT0*SCALE,0),cf*V(0,YB0*SCALE,0),SCALE
  end
  local th=rad(curve(K.th,t))
  local yT,yB=curve(K.yT,t),curve(K.yB,t)
  local sc=math.max(SCALE*(1-smooth(t,T_OUT+.08,T_OUT+.4)),.03)
  local ctr=mid+Fr:VectorToWorldSpace(V(curve(ox,t),curve(oy,t),curve(oz,t)))
  local a=V(-math.sin(th),math.cos(th),0)
  local piv=ctr-a*((yT+yB)/2*sc)
  local cf=CFrame.fromMatrix(piv,a:Cross(V(0,0,1)),a,V(0,0,1))
  local half=(yT-yB)*sc/2
  return cf,ctr+a*half,ctr-a*half,sc
 end
 -- snow that falls off the blade as the shovel comes out
 local spray={}
 for i=1,12 do
  local ts=T_POP+.02+i*.03
  local cf=shovelState(ts,select(2,skeleton(ts)),select(4,skeleton(ts)))
  local a=i*2.399
  spray[i]={ts=ts,p=cf*V(math.cos(a)*.5,-1.55*SCALE,math.sin(a)*.2),vx=math.cos(a)*(.7+.5*((i*7)%5)/4),vy=.9+((i*3)%4)*.4,vz=math.sin(a)*.6,size=.35+((i*11)%5)*.07}
 end

 ---------------------------------------------------------------- props + sprites
 local props=mk("Folder",{Name="Props"},folder)
 local function blob(name,pos,size,color)return Art.part(props,name,size,CFrame.new(W(pos))*G.Rotation,color or WHITE,"ball")end
 local mound={}
 for _,m in ipairs({{V(SHOVEL_AT.X,0,SHOVEL_AT.Z),V(4.2,.9,3.6)},{V(SHOVEL_AT.X-1.35,.05,SHOVEL_AT.Z+.7),V(1.7,.8,1.5)},
  {V(SHOVEL_AT.X+1.25,.03,SHOVEL_AT.Z+.8),V(1.5,.7,1.4)},{V(SHOVEL_AT.X+.2,.08,SHOVEL_AT.Z-1.15),V(1.6,.85,1.3)},{V(SHOVEL_AT.X,.2,SHOVEL_AT.Z),V(2.3,.7,2.1)}})do
  mound[#mound+1]={p=blob("Mound",m[1],m[2]),pos=m[1],size=m[2]}
 end
 local nest={}
 for i=1,8 do
  local a=(i-1)*math.pi/4+.3;local r=1.55+((i*5)%3)*.18
  local pos=LAND+V(math.cos(a)*r*1.25,.1,math.sin(a)*r*.85)
  local size=V(1.7+((i*3)%3)*.25,.95,1.5+((i*7)%3)*.2)
  nest[i]={p=blob("Nest",pos,size,i%2==0 and WHITE or C(228,242,253)),pos=pos,size=size}
 end
 local streaks={}
 for i=1,26 do
  local x=LAND.X+((i*7.3)%15)-7.5;local z=((i*5.1)%17)-4
  if math.abs(x-LAND.X)<2.2 and z<3 then z+=6 end
  local base=V(x,6+((i*3.7)%38),z)
  local p=Art.part(props,"Streak",V(.07,3.4+((i*2)%3),.07),CFrame.new(W(base))*G.Rotation,WHITE)
  p.Material=Enum.Material.Neon;p.Transparency=.35
  streaks[i]=p
 end
 local clouds={}
 for _,cc in ipairs({{-9,34,-8},{7,25.5,3},{-2,15.5,-12},{10,41,-2}})do
  for j=1,4 do
   local o=V((j-2.5)*3.1,(j%2)*1.1,((j*1.7)%2-1)*1.3)
   clouds[#clouds+1]=blob("Cloud",V(cc[1],cc[2],cc[3])+o,V(6.4-j*.5,3-(j%2)*.5,4.6))
  end
 end
 local skyGone=false
 local tex=Art.Textures
 local function pool(n,name,key,size)local l={};for i=1,n do l[i]=Art.sprite(folder,name,ready[key] and tex[key] or nil,size)end;return l end
 local puffs=pool(10,"LandingPowder","SnowPuff",3)
 local flakes=pool(14,"SoftSnow","Snowflake",.3)
 local glints=pool(5,"ShovelGlint","Glint",1.6)
 local spray1=pool(6,"BladeSpray","Snowflake",.4)
 local spray2=pool(6,"BladePuff","SnowPuff",.8)
 local moundPuffs=pool(4,"MoundPuff","SnowPuff",2)
 local function show(s,pos,size,opacity,rot)
  s.anchor.CFrame=CFrame.new(pos)
  s.gui.Size=UDim2.fromScale(size,size)
  s.image.ImageTransparency=1-math.clamp(opacity,0,1)
  if rot then s.image.Rotation=rot end
 end
 local function hide(s)s.image.ImageTransparency=1 end

 ---------------------------------------------------------------- camera
 local gameFocus=V(3,H+lift+c.focusOff.Y,0)
 local gp=rad(c.gpitch)
 local gamePos=gameFocus+V(0,c.zoom*math.sin(gp),c.zoom*math.cos(gp))
 local function closeUp(t)
  local u=ease(span(t,6.2,6.62));local d=span(t,6.62,T_OUT)
  local p0=V(3+math.sin(rad(20))*8,1.6,math.cos(rad(20))*8)
  local p1=V(3,3.7,5.4):Lerp(V(3.05,3.8,5.1),d)
  return p0:Lerp(p1,u),V(3,4.1,0):Lerp(V(3,5,.2),u),mix(54,52,u)
 end
 local function shot(t)
  if t<T_IMPACT then                                   -- 1 FALLING: wide sky shot that drops with the avatar
   local u=t/T_IMPACT;local e=ease(u);local ay=H+pose(t).dy
   return V(mix(1,-2.6,e),ay+mix(5.5,2.2,e),mix(19,9.5,e)),V(-3.3,ay+mix(-7,-.8,e),0),mix(70,60,e),rad(3)*math.sin(u*math.pi)
  elseif t<3 then                                      -- 2 SNOW LANDING: low ground-level shot
   local e=ease(span(t,T_IMPACT,3))
   return V(mix(-1.6,-2.4,e),mix(.6,1,e),mix(5.8,5,e)),V(-3.1,mix(.4,1.6,smooth(t,2,2.7)),0),mix(50,46,e)
  elseif t<3.75 then                                   -- 3a SHOVEL DISCOVERY: push toward the planted shovel
   local u=ease(span(t,3,3.75))
   return V(mix(6.2,6,u),mix(1.4,2,u),mix(11.5,8.6,u)),V(mix(5,5.1,u),mix(2.6,3.2,u),SHOVEL_AT.Z),mix(46,40,u)
  elseif t<4.2 then                                    -- 3b the avatar notices it
   local u=ease(span(t,3.75,4.2))
   return V(mix(-.4,-1.2,u),mix(2.3,2.6,u),mix(8.6,7.8,u)),V(-3.3,mix(2,3.4,smooth(t,4,4.2)),0),mix(44,42,u)
  elseif t<5.35 then                                   -- 4 GRAB: follow the run, frame hands and shovel
   local g=ease(span(t,4.5,4.9))
   return V(mix(3,6.4,g),mix(2.2,2.6,g),mix(9.5,8.2,g)),V(mix(1,4.6,g),mix(2.4,3.1,g),mix(0,-.3,g)),mix(46,42,g)
  elseif t<6.2 then                                    -- 5 VICTORY: low hero angle, short arc
   local u=ease(span(t,5.35,6.2));local a=rad(mix(-24,20,u));local R=mix(8.6,8,u)
   return V(3+math.sin(a)*R,mix(.9,1.6,u),math.cos(a)*R),V(3,mix(2.6,4.1,u),0),mix(56,54,u)
  elseif t<T_OUT then                                  -- 6 SHOVEL CLOSE-UP
   return closeUp(t)
  end
  local u=ease(span(t,T_OUT,DURATION))                 -- smooth return to the gameplay camera
  local p,tg,f=closeUp(T_OUT)
  return p:Lerp(gamePos,u),tg:Lerp(gameFocus,u),mix(f,c.oldFov,u)
 end
 local function shake(t)
  local a=0
  if t>=T_IMPACT and t<T_IMPACT+.24 then a+=(1-(t-T_IMPACT)/.24)*.13 end
  if t>=T_POP and t<T_POP+.16 then a+=(1-(t-T_POP)/.16)*.06 end
  return a>0 and V(math.sin(t*75),math.cos(t*67),0)*a or V()
 end

 ---------------------------------------------------------------- frame
 local lastScale,lastMound,lastNest=SCALE,-1,-1
 local function render(t)
  local P,Fr,S,mid=skeleton(t)
  -- shovel, then both hands reach the two grip points on it
  local scf,Ht,Hb,sc=shovelState(t,Fr,mid)
  local w=smooth(t,4.55,4.78)*(1-smooth(t,T_OUT,T_OUT+.3))
  if w>.001 then
   local fwd=WV(Fr.LookVector)
   local pr=rig:reach(S,"Right",W(Ht),{weight=w,pole=WV(Fr:VectorToWorldSpace(V(.7,-.6,.4))),forward=fwd})
   local pl=rig:reach(S,"Left",W(Hb),{weight=w,pole=WV(Fr:VectorToWorldSpace(V(-.7,-.6,.4))),forward=fwd})
   stats.errR=pr and (pr-W(Ht)).Magnitude or 0
   stats.errL=pl and (pl-W(Hb)).Magnitude or 0
  else stats.errR,stats.errL=0,0 end
  rig:commit(S)
  shovel:PivotTo(G*scf)
  if math.abs(sc-lastScale)>.004 then shovel:ScaleTo(sc);lastScale=sc end
  stats.tilt=math.deg(math.asin(math.clamp(scf.UpVector.Y,-1,1)))
  -- fall props
  local fallVis=t<T_IMPACT+.05
  if fallVis then
   for _,s in ipairs(streaks)do s.Transparency=.35+.65*smooth(t,1.2,1.5)end
  elseif not skyGone then
   skyGone=true
   for _,s in ipairs(streaks)do s.Transparency=1 end
   for _,cl in ipairs(clouds)do cl.Transparency=1 end
  end
  -- landing nest pops up on impact, sinks away once the avatar hops out
  local grow=span(t,T_IMPACT,T_IMPACT+.26)
  local nk=(1+2.7*(grow-1)^3+1.7*(grow-1)^2)*(1-smooth(t,3.98,4.28))
  if t<T_IMPACT then nk=0 end
  if math.abs(nk-lastNest)>.004 then
   lastNest=nk
   for _,n in ipairs(nest)do
    local k=math.max(nk,.001)
    n.p.Size=n.size*k;n.p.CFrame=CFrame.new(W(n.pos-V(0,(1-k)*.3,0)))*G.Rotation
   end
  end
  -- mound slumps when the shovel comes out, then melts away before the handoff
  local mk_=(1-.42*smooth(t,T_POP,T_POP+.15))*(1-smooth(t,7,7.6))
  if math.abs(mk_-lastMound)>.004 then
   lastMound=mk_
   for _,m in ipairs(mound)do
    local k=math.max(mk_,.001)
    m.p.Size=V(m.size.X,m.size.Y*k,m.size.Z);m.p.CFrame=CFrame.new(W(m.pos-V(0,(1-k)*m.size.Y*.5,0)))*G.Rotation
   end
  end
  -- landing powder: a short soft puff that covers the avatar for a moment
  for i,s in ipairs(puffs)do
   local age=(t-T_IMPACT-(i%3)*.035)/.95
   if age>=0 and age<1 then
    local a=(i-1)*math.pi*2/#puffs+.4;local front=i<=3
    local dir=front and V(math.cos(a)*.55,0,math.abs(math.sin(a))*.9+.6) or V(math.cos(a),0,math.sin(a)*.7)
    local pos=LAND+V(0,.5,.3)+dir*((front and .6 or .8)+3*age^.6)+V(0,.3+1.7*age-.8*age*age,0)
    show(s,W(pos),(front and 4.4 or 3.2)+age*(front and 4.4 or 3),.85*math.sin(math.pi*age)^.6,i*43+age*30)
   else hide(s)end
  end
  for i,s in ipairs(flakes)do   -- a few soft flakes drifting through the whole scene
   show(s,W(V(((i*13.37)%26)-12+math.sin(t+i)*.2,11-((t*.7+i*2.93)%13),((i*7.13)%20)-6)),.3,.55,t*12+i*37)
  end
  for k,ev in ipairs(GLINTS)do
   local s=glints[(k-1)%#glints+1];local age=(t-ev[1])/ev[2]
   if age>=0 and age<1 then
    local sn=math.sin(math.pi*age)
    show(s,W(scf*(ev[3]*sc)),ev[4]*4.5*(.5+.5*sn),sn^1.5,30*age)
   elseif t<ev[1] or t>ev[1]+ev[2] then hide(s)end
  end
  for i,sp in ipairs(spray)do
   local s=i<=6 and spray1[i] or spray2[i-6]
   local age=t-sp.ts
   if age>=0 and age<.85 then
    show(s,W(sp.p+V(sp.vx*age,sp.vy*age-3.6*age*age,sp.vz*age)),sp.size*(1+.4*age),.8*(1-age/.85)^.8,i*57+age*90)
   else hide(s)end
  end
  for i,ev in ipairs(MOUND_PUFFS)do
   local s=moundPuffs[i];local age=(t-ev[1])/ev[2]
   if age>=0 and age<1 then
    show(s,W(SHOVEL_AT+ev[3]*(1+age*.6)+V(0,age*.9,0)),1.6+age*2.4,.6*math.sin(math.pi*age),i*70+age*20)
   else hide(s)end
  end
  -- camera
  local pos,tg,fov,roll=shot(t)
  pos+=shake(t)
  pos=V(pos.X,math.max(pos.Y,.5),pos.Z)
  return G*CFrame.lookAt(pos,tg)*CFrame.Angles(0,0,roll or 0),fov,W(tg),stats
 end
 return {render=render}
end

function M.Play(options)
 options=options or {}
 if player:GetAttribute("IntroPlaying") or M.busy then return false end
 local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health<=0 then return false end
 M.busy=true
 local camera=workspace.CurrentCamera
 local controls
 pcall(function()local pm=player.PlayerScripts:FindFirstChild("PlayerModule");if pm then controls=require(pm):GetControls()end end)
 local old={cameraType=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,cf=camera.CFrame,focus=camera.Focus}
 -- What the normal gameplay camera looks like, so the cinematic can end exactly on it.
 local rootBefore=char:FindFirstChild("HumanoidRootPart")
 local focusOff=rootBefore and (old.focus.Position-rootBefore.Position) or V(0,1.5,0)
 if focusOff.Magnitude>5 or focusOff.Magnitude<.3 then focusOff=V(0,1.5,0)end
 local zoom=(old.cf.Position-old.focus.Position).Magnitude
 if zoom<6 or zoom>40 then zoom=12.5 end
 local gpitch=-math.deg(math.asin(math.clamp(old.cf.LookVector.Y,-1,1)))
 if gpitch<6 or gpitch>40 then gpitch=17 end
 local controlsWereEnabled=controls and controls.controlsEnabled~=false
 local savedGui,hidden,savedEffects={},{},{}
 local connections={}
 local folder,gui,grade
 local cancelled,cleaned,engaged=false,false,false
 local function restore()
  if cleaned then return end;cleaned=true
  M.busy=false
  if not engaged then return end
  RunService:UnbindFromRenderStep("SnowArrivalIntro")
  CAS:UnbindAction("SnowArrivalLock")
  for _,cn in ipairs(connections)do cn:Disconnect()end
  for part,value in pairs(hidden)do if part.Parent then part.LocalTransparencyModifier=value end end
  for sg,value in pairs(savedGui)do if sg.Parent then sg.Enabled=value end end
  for effect,value in pairs(savedEffects)do if effect.Parent then effect.Enabled=value end end
  if folder then folder:Destroy()end;if gui then gui:Destroy()end;if grade then grade:Destroy()end
  camera.FieldOfView=old.fov
  local live=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  camera.CameraSubject=live or old.subject;camera.CameraType=Enum.CameraType.Custom
  if controls and controlsWereEnabled then controls:Enable()end
  player:SetAttribute("IntroPlaying",false)
  task.spawn(function()pcall(function()Request:InvokeServer(cancelled and "Skip" or "Finish")end)end)
 end
 local ok,err=xpcall(function()
  local ready=Art.preload(2.5)
  if player.Character~=char or hum.Health<=0 then return end
  local data=Request:InvokeServer(options.Preview and "Preview" or "Begin")
  if not data then return end
  engaged=true
  player:SetAttribute("IntroPlaying",true)
  if controls then controls:Disable()end
  CAS:BindActionAtPriority("SnowArrivalLock",function()return Enum.ContextActionResult.Sink end,false,3000,unpack(Enum.PlayerActions:GetEnumItems()))
  folder=mk("Folder",{Name="SnowArrivalCinematic"},workspace)
  folder:SetAttribute("Duration",DURATION)
  gui=mk("ScreenGui",{Name="SnowArrivalGui",DisplayOrder=1000,IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player.PlayerGui)
  local skip=mk("TextButton",{Name="Skip",Text="SKIP  ›",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=WHITE,BackgroundColor3=C(22,53,76),BackgroundTransparency=.3,BorderSizePixel=0,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-24,1,-24),Size=UDim2.fromOffset(118,44),ZIndex=3},gui)
  mk("UICorner",{CornerRadius=UDim.new(0,16)},skip)
  connections[#connections+1]=skip.Activated:Connect(function()cancelled=true end)
  connections[#connections+1]=Input.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.ButtonB then cancelled=true end end)
  connections[#connections+1]=hum.Died:Connect(function()cancelled=true end)
  connections[#connections+1]=player.CharacterRemoving:Connect(function()cancelled=true end)
  local function hideGui(sg)if sg:IsA("ScreenGui") and sg~=gui and not sg:GetAttribute("KeepDuringIntro") then savedGui[sg]=sg.Enabled;sg.Enabled=false end end
  for _,sg in ipairs(player.PlayerGui:GetChildren())do hideGui(sg)end
  connections[#connections+1]=player.PlayerGui.ChildAdded:Connect(hideGui)
  for _,p in ipairs(char:GetDescendants())do if p:IsA("BasePart")then hidden[p]=p.LocalTransparencyModifier end end
  for _,container in ipairs({Lighting,camera})do for _,effect in ipairs(container:GetChildren())do
   if effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect")then savedEffects[effect]=effect.Enabled;effect.Enabled=false end
  end end
  grade=mk("ColorCorrectionEffect",{Name="ArrivalColor",Brightness=.025,Contrast=.04,Saturation=.09,TintColor=C(241,250,255)},Lighting)
  -- Real ground under the intro marker (the marker floats slightly above the snow).
  local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={char,folder}
  local hit=workspace:Raycast(data.Origin.Position+V(0,12,0),V(0,-40,0),rp)
  local groundY=hit and hit.Position.Y or data.Origin.Position.Y-.22
  local G=CFrame.new(data.Origin.Position.X,groundY,data.Origin.Position.Z)*data.Origin.Rotation
  local rig=Rig.new(char,folder)
  local scene=newScene({G=G,H=data.Height,lift=data.Origin.Position.Y-groundY,rig=rig,folder=folder,ready=ready,shovelName=data.StarterShovel,
   oldFov=old.fov,zoom=zoom,gpitch=gpitch,focusOff=focusOff})
  local start=os.clock()
  local frameCount=0
  local hold=RunService:IsStudio() and options.HoldAt~=nil
  local function render()
   local t=hold and (player:GetAttribute("IntroHoldAt") or options.HoldAt) or math.min(os.clock()-start,DURATION)
   t=math.clamp(t,0,DURATION)
   local cf,fov,focus,stats=scene.render(t)
   camera.CameraType=Enum.CameraType.Scriptable
   camera.CFrame=cf;camera.FieldOfView=fov;camera.Focus=CFrame.new(focus)
   for part in pairs(hidden)do if part.Parent then part.LocalTransparencyModifier=1 end end
   -- Match the real character before restoring the normal camera; no flash, no pop.
   local dissolve=ease((t-7.55)/.35)
   for part,value in pairs(hidden)do if part.Parent then part.LocalTransparencyModifier=mix(1,value,dissolve) end end
   rig:fade(dissolve)
   folder:SetAttribute("Time",t)
   folder:SetAttribute("HandErrR",stats.errR);folder:SetAttribute("HandErrL",stats.errL);folder:SetAttribute("ShaftTilt",stats.tilt)
   frameCount+=1
  end
  camera.CameraType=Enum.CameraType.Scriptable
  render()
  local renderError
  RunService:BindToRenderStep("SnowArrivalIntro",Enum.RenderPriority.Camera.Value+3,function()
   if renderError then return end
   local rendered,message=pcall(render)
   if not rendered then renderError=message;cancelled=true end
  end)
  repeat RunService.Heartbeat:Wait()
  until cancelled or not char.Parent or player.Character~=char
   or (hold and (player:GetAttribute("IntroHoldEnd") or os.clock()-start>1800))
   or (not hold and (os.clock()-start>=DURATION or (os.clock()-start>1 and player:GetAttribute("IntroActive")~=true)))
  player:SetAttribute("IntroLastFrames",frameCount)
  player:SetAttribute("IntroLastSeconds",os.clock()-start)
  if renderError then error(renderError)end
 end,debug.traceback)
 restore()
 if not ok then warn("[SnowIntro] "..tostring(err))end
 return ok
end
return M
