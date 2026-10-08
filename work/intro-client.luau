-- Seven-second, time-based cinematic. Camera/controls are restored on every exit path.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local Lighting=game:GetService("Lighting")
local Art=require(RS:WaitForChild("SnowIntroArt"))
local Request=RS:WaitForChild("SnowIntroRequest")
local player=Players.LocalPlayer
local M={}
local V,C=Vector3.new,Color3.fromRGB
local WHITE,ICE=C(252,255,255),C(147,226,255)
local rad=math.rad
local function ease(t) t=math.clamp(t,0,1);return t*t*(3-2*t)end
local function mix(a,b,t)return a+(b-a)*math.clamp(t,0,1)end
local function angles(x,y,z)return CFrame.Angles(rad(x or 0),rad(y or 0),rad(z or 0))end
local function mk(class,props,parent)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
local function cf(pos,target)return CFrame.lookAt(pos,target)end
local function pose(t)
 local p={x=-4,y=0,yaw=0,roll=0,pitch=0,rs=V(0,0,0),ls=V(0,0,0),rh=V(0,0,0),lh=V(0,0,0),neck=V(0,0,0),re=0,le=0,rk=0,lk=0}
 if t<2 then
  local u=t/2
  p.y=48*(1-u*u)
  p.roll=math.sin(t*8)*14*(1-u)+math.sin(u*math.pi*2)*30
  p.yaw=math.sin(u*math.pi)*105
  p.pitch=math.sin(t*5)*13
  p.rs=V(110+math.sin(t*17)*24,0,-35)
  p.ls=V(115-math.sin(t*19)*25,0,35)
  p.rh=V(math.sin(t*18)*25,0,-15);p.lh=V(-math.sin(t*18)*25,0,15)
 elseif t<2.3 then
  local u=ease((t-2)/.3);p.y=mix(0,-1.8,u);p.pitch=18*u
  p.rs=V(-25,0,-38);p.ls=V(-25,0,38);p.rh=V(-25,0,0);p.lh=p.rh
 elseif t<2.7 then
  local u=ease((t-2.3)/.4);p.y=mix(-1.8,.18,u);p.pitch=mix(18,-8,u)
  p.rs=V(10,0,-25);p.ls=V(10,0,25);p.neck=V(-12,math.sin(t*19)*22,0)
 elseif t<3.25 then
  p.y=math.sin((t-2.7)*math.pi/.55)*.12;p.roll=math.sin(t*29)*6*(1-(t-2.7)/.55)
  p.rs=V(10,0,-25);p.ls=V(10,0,25);p.neck=V(-5,math.sin((t-2.7)*10)*28,0)
 elseif t<4.5 then
  local u=ease((t-3.25)/.4);p.neck=V(-8,-38*u,-10*u)
  p.rs=V(15,0,-16);p.ls=V(15,0,16);p.pitch=-5*u
 elseif t<5.12 then
  local u=ease((t-4.5)/.62);p.x=mix(-4,3,u);p.y=math.abs(math.sin((t-4.5)*20))*.3
  p.yaw=-90*(1-ease((u-.7)/.3));p.pitch=10
  p.rs=V(math.sin(t*21)*42,0,-7);p.ls=V(-math.sin(t*21)*42,0,7)
  p.rh=V(-math.sin(t*21)*35,0,0);p.lh=V(math.sin(t*21)*35,0,0)
  p.rk=math.max(0,math.sin(t*21))*35;p.lk=math.max(0,-math.sin(t*21))*35
 elseif t<5.48 then
  local u=ease((t-5.12)/.36);p.x=3;p.y=-.42*math.sin(u*math.pi);p.pitch=18*math.sin(u*math.pi)
  p.rs=V(mix(70,155,u),-15,-18);p.ls=V(mix(65,145,u),18,18)
  p.re=-18;p.le=-25;p.neck=V(-18,0,0)
 elseif t<6 then
  local u=ease((t-5.48)/.3);p.x=3;p.y=math.sin(u*math.pi)*.18
  p.rs=V(155,0,-18);p.ls=V(mix(145,20,u),0,24);p.neck=V(-20,0,-5)
 elseif t<6.55 then
  local u=ease((t-6)/.55);p.x=3;p.rs=V(mix(155,60,u),0,-28)
  p.ls=V(10,0,30);p.roll=-4*math.sin(u*math.pi);p.neck=V(-7,0,0)
 else
  local u=ease((t-6.55)/.45);p.x=3;p.rs=V(mix(60,0,u),0,mix(-28,0,u));p.ls=V(0,0,mix(30,0,u))
 end
 return p
end
local function cameraAt(t,h)
 local pos,target,fov
 if t<2 then
  local u=ease(t/2);local y=48*(1-(t/2)^2)+h
  pos=V(mix(14,10,u),y+mix(9,5,u),mix(-30,-18,u));target=V(-4,y+1,0);fov=mix(65,54,u)
 elseif t<3.25 then
  local u=ease((t-2)/1.25);pos=V(mix(9,5,u),mix(7,5.3,u),-16);target=V(-3,h-.25,0);fov=54
 elseif t<3.75 then
  local u=ease((t-3.25)/.5);pos=V(5,5.3,-16):Lerp(V(6,4.5,-8),u);target=V(-3,h-.25,0):Lerp(V(3,2.5,-1.1),u);fov=mix(54,39,u)
 elseif t<4.25 then
  local u=ease((t-3.75)/.5);pos=V(6,4.5,-8);target=V(3,2.5,-1.1);fov=mix(39,36,u)
 elseif t<4.5 then
  local u=ease((t-4.25)/.25);pos=V(6,4.5,-8):Lerp(V(-.6,h+1.8,-7),u);target=V(3,2.5,-1.1):Lerp(V(-4,h+1.1,0),u);fov=mix(36,46,u)
 elseif t<5.15 then
  local u=ease((t-4.5)/.65);pos=V(-.6,h+1.8,-7):Lerp(V(12,6,-16),u);target=V(-4,h+1.1,0):Lerp(V(3,h,0),u);fov=mix(46,56,u)
 elseif t<6.1 then
  local u=ease((t-5.15)/.95);pos=V(12,6,-16):Lerp(V(8,3.8,-12),u);target=V(3,h+1,0);fov=mix(56,50,u)
 else
  local u=ease((t-6.1)/.9)
  local a=mix(math.atan2(-12,5),math.pi*.5,u)
  local dist=mix(13,17,u)
  pos=V(3+math.cos(a)*dist,mix(4,11,u),math.sin(a)*dist)
  target=V(3,h+.5,-1);fov=mix(50,70,u)
 end
 if t>=2 and t<2.24 then
  local power=(1-(t-2)/.24)*.25
  pos+=V(math.sin(t*133),math.cos(t*111),0)*power
 end
 return cf(pos,target),fov
end
local function makeActor(char,parent)
 local was=char.Archivable;char.Archivable=true
 local ok,actor=pcall(function()return char:Clone()end);char.Archivable=was
 assert(ok and actor,"Avatar could not be cloned")
 actor.Name="IntroActor"
 for _,o in ipairs(actor:GetDescendants())do
  if o:IsA("LuaSourceContainer") or o:IsA("Animator") or o:IsA("Tool") or o:IsA("ForceField") then o:Destroy()
  elseif o:IsA("BasePart")then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.LocalTransparencyModifier=0
  elseif o:IsA("Sound")then o:Destroy()end
 end
 local root=actor:FindFirstChild("HumanoidRootPart");assert(root,"Avatar root missing")
 root.Anchored=true;root.Transparency=1;actor.PrimaryPart=root
 local hum=actor:FindFirstChildOfClass("Humanoid");hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.AutoRotate=false;hum.BreakJointsOnDeath=false
 -- Solve the visual rig directly, supporting both Motor6D and AnimationConstraint avatars.
 -- Anchored clone parts make the animation independent of physics and frame order.
 local links,rest={},{}
 for _,o in ipairs(actor:GetDescendants())do
  if o:IsA("BasePart")then rest[o]=root.CFrame:ToObjectSpace(o.CFrame) end
  local a,b,c0,c1
  if o:IsA("JointInstance")then a,b,c0,c1=o.Part0,o.Part1,o.C0,o.C1
  elseif o:IsA("AnimationConstraint") or o:IsA("RigidConstraint")then
   local at0,at1=o.Attachment0,o.Attachment1
   if at0 and at1 then a,b,c0,c1=at0.Parent,at1.Parent,at0.CFrame,at1.CFrame end
  end
  if a and b and a:IsA("BasePart") and b:IsA("BasePart")then
   links[#links+1]={name=o.Name:gsub(" ",""),a=a,b=b,c0=c0,c1=c1}
  end
 end
 for _,o in ipairs(actor:GetDescendants())do if o:IsA("JointInstance") or o:IsA("Constraint")then o:Destroy()end end
 local function apply(p,world,handTargets)
  local rotations={RightShoulder=p.rs,LeftShoulder=p.ls,RightHip=p.rh,LeftHip=p.lh,Neck=p.neck,
   RightElbow=V(p.re,0,0),LeftElbow=V(p.le,0,0),RightKnee=V(p.rk,0,0),LeftKnee=V(p.lk,0,0)}
  local solved={[root]=world}
  for _=1,12 do
   local changed=false
   for _,j in ipairs(links)do
    local v=rotations[j.name] or Vector3.zero
    local transform=CFrame.new(j.c0.Position)*angles(v.X,v.Y,v.Z)*j.c0.Rotation*j.c1:Inverse()
    if solved[j.a] and not solved[j.b]then solved[j.b]=solved[j.a]*transform;changed=true
    elseif solved[j.b] and not solved[j.a]then solved[j.a]=solved[j.b]*transform:Inverse();changed=true end
   end
   if not changed then break end
  end
  if handTargets then
   local byName={};for _,j in ipairs(links)do byName[j.name]=j end
   for side,target in pairs(handTargets)do
    local shoulder,elbow,wrist=byName[side.."Shoulder"],byName[side.."Elbow"],byName[side.."Wrist"]
    if shoulder and elbow and wrist then
     local start=(solved[shoulder.a]*shoulder.c0).Position
     local wristTarget=target+world:VectorToWorldSpace(wrist.c1.Position)
     local upperLength=(elbow.c0.Position-shoulder.c1.Position).Magnitude
     local lowerLength=(wrist.c0.Position-elbow.c1.Position).Magnitude
     local delta=wristTarget-start;local dir=delta.Unit
     local distance=math.clamp(delta.Magnitude,.05,upperLength+lowerLength-.015)
     local along=(upperLength^2-lowerLength^2+distance^2)/(2*distance)
     local bend=world.LookVector-dir*world.LookVector:Dot(dir)
     if bend.Magnitude<.01 then bend=world.RightVector end
     local joint=start+dir*along+bend.Unit*math.sqrt(math.max(0,upperLength^2-along^2))
     local endpoint=start+dir*distance
     solved[shoulder.b]=CFrame.lookAt(start,joint)*angles(90,0,0)*CFrame.new(-shoulder.c1.Position)
     solved[elbow.b]=CFrame.lookAt(joint,endpoint)*angles(90,0,0)*CFrame.new(-elbow.c1.Position)
     solved[wrist.b]=CFrame.new(endpoint-world:VectorToWorldSpace(wrist.c1.Position))*world.Rotation
    end
   end
  end
  for part,offset in pairs(rest)do part.CFrame=solved[part] or world*offset end
 end
 actor.Parent=parent
 local head=actor:FindFirstChild("Head")
 local gasp
 if head then
  gasp=mk("SurfaceGui",{Name="ExcitedFace",Face=Enum.NormalId.Front,CanvasSize=Vector2.new(256,256),LightInfluence=0,Enabled=false},head)
  local face=mk("Frame",{Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundColor3=head.Color},gasp)
  for _,x in ipairs({.29,.71})do
   local eye=mk("Frame",{Position=UDim2.fromScale(x-.105,.24),Size=UDim2.fromScale(.21,.3),BackgroundColor3=Color3.fromRGB(22,42,66),BorderSizePixel=0},face)
   mk("UICorner",{CornerRadius=UDim.new(1,0)},eye)
   local shine=mk("Frame",{Position=UDim2.fromScale(.14,.12),Size=UDim2.fromScale(.34,.28),BackgroundColor3=WHITE,BorderSizePixel=0},eye);mk("UICorner",{CornerRadius=UDim.new(1,0)},shine)
  end
  local mouth=mk("Frame",{Position=UDim2.fromScale(.4,.66),Size=UDim2.fromScale(.2,.2),BackgroundColor3=Color3.fromRGB(47,58,77),BorderSizePixel=0},face);mk("UICorner",{CornerRadius=UDim.new(1,0)},mouth)
 end
 return actor,apply,gasp
end
function M.Play(options)
 options=options or {}
 if player:GetAttribute("IntroPlaying") then return false end
 local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health<=0 then return false end
 local camera=workspace.CurrentCamera
 local controls
  pcall(function()local pm=player.PlayerScripts:FindFirstChild("PlayerModule");if pm then controls=require(pm):GetControls()end end)
 local old={cameraType=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,cf=camera.CFrame}
 local controlsWereEnabled=controls and controls.controlsEnabled~=false
 local savedGui,hidden,skyParents,savedEffects={},{},{},{}
 local connections={}
 local folder,gui,grade,introSky
 local cancelled,cleaned,engaged=false,false,false
 local function restore()
  if cleaned then return end;cleaned=true
  if not engaged then return end
  RunService:UnbindFromRenderStep("SnowArrivalIntro")
  CAS:UnbindAction("SnowArrivalLock")
  for _,c in ipairs(connections)do c:Disconnect()end
  for part,value in pairs(hidden)do if part.Parent then part.LocalTransparencyModifier=value end end
  for sg,value in pairs(savedGui)do if sg.Parent then sg.Enabled=value end end
  for effect,value in pairs(savedEffects)do if effect.Parent then effect.Enabled=value end end
  if introSky then introSky:Destroy()end
  for sky,parent in pairs(skyParents)do sky.Parent=parent end
  if folder then folder:Destroy()end;if gui then gui:Destroy()end;if grade then grade:Destroy()end
  camera.FieldOfView=old.fov
  local live=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  camera.CameraSubject=live or old.subject;camera.CameraType=Enum.CameraType.Custom
  if controls and controlsWereEnabled then controls:Enable()end
  player:SetAttribute("IntroPlaying",false)
  task.spawn(function()pcall(function()Request:InvokeServer(cancelled and "Skip" or "Finish")end)end)
 end
 local ok,err=xpcall(function()
  local data=Request:InvokeServer(options.Preview and "Preview" or "Begin")
  if not data then return end
  engaged=true
  player:SetAttribute("IntroPlaying",true)
  if controls then controls:Disable()end
  CAS:BindActionAtPriority("SnowArrivalLock",function()return Enum.ContextActionResult.Sink end,false,3000,unpack(Enum.PlayerActions:GetEnumItems()))
  folder=mk("Folder",{Name="SnowArrivalCinematic"},workspace)
  folder:SetAttribute("Duration",7)
  gui=mk("ScreenGui",{Name="SnowArrivalGui",DisplayOrder=1000,IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player.PlayerGui)
  local veil=mk("Frame",{Name="HandoffGlow",Size=UDim2.fromScale(1,1),BackgroundColor3=WHITE,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1},gui)
  local skip=mk("TextButton",{Name="Skip",Text="SKIP  ›",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=WHITE,BackgroundColor3=C(22,53,76),BackgroundTransparency=.3,BorderSizePixel=0,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-24,1,-24),Size=UDim2.fromOffset(118,44),ZIndex=3},gui)
  mk("UICorner",{CornerRadius=UDim.new(0,16)},skip)
  connections[#connections+1]=skip.Activated:Connect(function()cancelled=true end)
  connections[#connections+1]=Input.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.ButtonB then cancelled=true end end)
  connections[#connections+1]=hum.Died:Connect(function()cancelled=true end)
  connections[#connections+1]=player.CharacterRemoving:Connect(function()cancelled=true end)
  local function hideGui(sg)if sg:IsA("ScreenGui") and sg~=gui then savedGui[sg]=sg.Enabled;sg.Enabled=false end end
  for _,sg in ipairs(player.PlayerGui:GetChildren())do hideGui(sg)end
  connections[#connections+1]=player.PlayerGui.ChildAdded:Connect(hideGui)
  for _,p in ipairs(char:GetDescendants())do if p:IsA("BasePart")then hidden[p]=p.LocalTransparencyModifier end end
  local actor,apply,gasp=makeActor(char,folder)
  Art.scene(folder,data.Origin)
  for _,sky in ipairs(Lighting:GetChildren())do if sky:IsA("Sky") or sky:IsA("Atmosphere")then skyParents[sky]=Lighting;sky.Parent=folder end end
  introSky=mk("Sky",{Name="ArrivalBlueSky",StarCount=0},Lighting)
  for _,container in ipairs({Lighting,camera})do for _,effect in ipairs(container:GetChildren())do
   if effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect")then savedEffects[effect]=effect.Enabled;effect.Enabled=false end
  end end
  local shovel,light=Art.shovel(folder)
  grade=mk("ColorCorrectionEffect",{Name="ArrivalColor",Brightness=.025,Contrast=.04,Saturation=.09,TintColor=C(241,250,255)},Lighting)
  local fx={}
  for i=1,30 do fx[i]=Art.part(folder,"SnowPoof",V(1,1,1),CFrame.new(0,-1000,0),i%3==0 and ICE or WHITE,"ball")end
  local flakes={}
  for i=1,38 do
   flakes[i]=Art.part(folder,"Snowflake",V(.07,.07,.07),CFrame.new(),WHITE,"ball")
  end
  local glints={}
  for i=1,12 do
   local model=mk("Model",{Name="Glint"},folder)
   Art.part(model,"Vertical",V(.055,.48,.055),CFrame.new(),WHITE)
   Art.part(model,"Horizontal",V(.29,.055,.055),CFrame.new(),ICE)
   model.WorldPivot=CFrame.new();glints[i]=model
  end
  local trails={}
  for s=-1,1,2 do trails[#trails+1]=Art.part(folder,"Whoosh",V(.075,5,.075),CFrame.new(),ICE,"ball")end
  local start=os.clock()
  local frameCount=0
  local hold=RunService:IsStudio() and tonumber(options.HoldAt)
  local function render()
   local elapsed=os.clock()-start
   local t=hold or math.min(elapsed,7)
   local p=pose(t)
   folder:SetAttribute("Time",t)
   folder:SetAttribute("Beat",t<2 and "fall" or t<3.25 and "landing" or t<4.5 and "discovery" or t<5.48 and "grab" or t<6 and "hero" or "handoff")
   if gasp then gasp.Enabled=t>=3.6 and t<4.85 end
   local shovelCF=CFrame.new(3,2,-1.1)*angles(0,0,-7)
   if t>=5.12 then
    local u=ease((t-5.12)/.36)
    shovelCF=shovelCF:Lerp(CFrame.new(4.1,data.Height+2.4,-.6)*angles(0,0,-20),u)
    if t>=6 then
     local twirl=ease((t-6)/.55)
     shovelCF=CFrame.new(4.1,mix(data.Height+2.4,data.Height+.1,twirl),-.6)*angles(0,0,-20-360*twirl)
    end
   end
   local shovelWorld=data.Origin*shovelCF
   local targets
   if t>=5.12 and t<5.33 then targets={Right=shovelWorld:PointToWorldSpace(V(0,.55,0)),Left=shovelWorld:PointToWorldSpace(V(0,-.2,0))}end
   apply(p,data.Origin*CFrame.new(p.x,data.Height+p.y,0)*angles(p.pitch,p.yaw,p.roll),targets)
   if t>=5.3 then
    local hand=actor:FindFirstChild("RightHand") or actor:FindFirstChild("Right Arm")
    if hand then
     local twirl=t>=6 and ease((t-6)/.55) or 0
     local liftTurn=180*ease((t-5.3)/.25)
     local held=CFrame.new(hand.Position)*data.Origin.Rotation*angles(0,0,-20+liftTurn-360*twirl)*CFrame.new(0,-.8,0)
     shovelWorld=shovelWorld:Lerp(held,ease((t-5.3)/.18))
    end
   end
   shovel:PivotTo(shovelWorld)
   light.Brightness=t>=5.38 and t<6.7 and 1.6 or .1
   for _,o in ipairs(shovel:GetDescendants())do if o:IsA("BasePart")then o.Transparency=t>6.7 and ease((t-6.7)/.3) or 0 end end
   for i,cloud in ipairs(fx)do
    local age=t-2
    local rise=t-5.4
    local isSprinkle=i>20 and rise>=0
    if (age>=0 and age<1.25) or (isSprinkle and rise<.85)then
     local a=i*2.399963
     local life=isSprinkle and rise or age
     local radius=isSprinkle and (life*2) or (1+life*(4+i%4))
     local center=isSprinkle and V(4.1,data.Height+2,-.6) or V(-4,0,0)
     local y=isSprinkle and (-life*life*5) or (.35+life*4-life*life*3)
     cloud.CFrame=data.Origin*CFrame.new(center+V(math.cos(a)*radius,y,math.sin(a)*radius*.7))
     local size=isSprinkle and .12 or (.9+(i%4)*.25+life*.8)
     cloud.Size=V(size,size*(isSprinkle and 1 or .75),size)
     cloud.Transparency=isSprinkle and life/.85 or math.clamp((life-.35)/.9,0,1)
    else cloud.Transparency=1 end
   end
   for i,f in ipairs(flakes)do
    local x=((i*13.37)%38)-19
    local y=14-((t*1.5+i*2.93)%16)
    local z=((i*7.13)%30)-13
    f.CFrame=data.Origin*CFrame.new(x+math.sin(t+i)*.3,y,z)
   end
   for i,g in ipairs(glints)do
    local active=t>=3 and t<6.75
    local strength=t>=5.38 and 1 or .45
    local a=t*2+i*math.pi/6
    local center=data.Origin:PointToObjectSpace(shovelWorld.Position)
    local radius=(1.05+i%3*.28)*strength
    g:PivotTo(data.Origin*CFrame.new(center+V(math.cos(a)*radius,math.sin(a*1.2)*1.7,math.sin(a)*.55))*angles(0,0,t*70+i*30))
    for _,o in ipairs(g:GetChildren())do if o:IsA("BasePart")then o.Transparency=active and (.15+.55*(.5+.5*math.sin(t*10+i))) or 1 end end
   end
   for i,trail in ipairs(trails)do
    trail.CFrame=data.Origin*CFrame.new(p.x+(i==1 and -1.8 or 1.8),data.Height+p.y+4,.6)
    trail.Transparency=t<1.95 and .35 or 1
   end
   local shot,fov=cameraAt(t,data.Height)
   camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=data.Origin*shot;camera.FieldOfView=fov
   for part in pairs(hidden)do if part.Parent then part.LocalTransparencyModifier=1 end end
   -- A short, soft sparkle dissolve hides the prop-to-gameplay handoff.
   veil.BackgroundTransparency=t>6.88 and 1-.25*ease((t-6.88)/.12) or 1
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
  repeat RunService.Heartbeat:Wait() until cancelled or not char.Parent or player.Character~=char or (os.clock()-start>1 and player:GetAttribute("IntroActive")~=true) or os.clock()-start>=(hold and 45 or 7)
  player:SetAttribute("IntroLastFrames",frameCount)
  player:SetAttribute("IntroLastSeconds",os.clock()-start)
  if renderError then error(renderError)end
 end,debug.traceback)
 restore()
 if not ok then warn("[SnowIntro] "..tostring(err))end
 return ok
end
return M
