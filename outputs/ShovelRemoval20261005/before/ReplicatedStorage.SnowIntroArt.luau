-- Intro sprites and the actual starter shovel model. Historical scene builder remains unused.
local A={}
local V,C=Vector3.new,Color3.fromRGB
local WHITE,ICE,INK=C(251,254,255),C(147,225,255),C(29,73,101)
function A.part(parent,name,size,cf,color,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or WHITE
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Material=Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 if shape=="ball" then local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
 elseif shape=="cylinder" then p.Shape=Enum.PartType.Cylinder end
 p.Parent=parent;return p
end
function A.rod(parent,name,a,b,r,color)
 return A.part(parent,name,V((b-a).Magnitude,r*2,r*2),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),color,"cylinder")
end
-- Image assets (AssetType Image, not Decal wrappers). Verified to render with transparency on 2026-09-30.
A.Textures={SnowPuff="rbxassetid://106631447559245",Glint="rbxassetid://78959417544095",Snowflake="rbxassetid://95577984312503"}
-- Preloads every intro texture and returns {name=true|false}. Never blocks longer than `timeout` seconds;
-- a texture that fails to load simply leaves its sprites invisible, it can never break the cinematic.
function A.preload(timeout)
 local ready,list,byId={},{},{}
 for name,id in pairs(A.Textures)do
  local im=Instance.new("ImageLabel");im.Image=id;list[#list+1]=im;byId[id]=name;ready[name]=false
 end
 local done=false
 task.spawn(function()
  pcall(function()
   game:GetService("ContentProvider"):PreloadAsync(list,function(id,status)
    local name=byId[id];if name then ready[name]=(status==Enum.AssetFetchStatus.Success) end
   end)
  end)
  done=true
 end)
 local t0=os.clock()
 while not done and os.clock()-t0<(timeout or 3) do task.wait() end
 for _,im in ipairs(list)do im:Destroy()end
 for name,ok in pairs(ready)do if not ok then warn("[SnowIntro] texture not ready yet: "..name)end end
 return ready
end
function A.sprite(parent,name,texture,size)
 local anchor=A.part(parent,name,V(.05,.05,.05),CFrame.new(0,-1000,0),WHITE)
 anchor.Transparency=1
 local gui=Instance.new("BillboardGui");gui.Name="Sprite";gui.Size=UDim2.fromScale(size,size)
 gui.AlwaysOnTop=false;gui.LightInfluence=0;gui.MaxDistance=160;gui.Parent=anchor
 local image=Instance.new("ImageLabel");image.Name="Texture";image.Size=UDim2.fromScale(1,1)
 image.BackgroundTransparency=1;image.Image=texture or "";image.ImageTransparency=1;image.Parent=gui
 return {anchor=anchor,gui=gui,image=image}
end
function A.shovel(parent,name,scale)
 local template=game.ReplicatedStorage:WaitForChild("ShovelModels"):FindFirstChild(name or "Tin Shovel")
 assert(template and template:IsA("Model"),"Starter shovel model missing")
 local m=template:Clone();m.Name="HeroShovel";m:SetAttribute("ShovelName",template.Name)
 for _,p in ipairs(m:GetDescendants())do
  if p:IsA("LuaSourceContainer")then p:Destroy()
  elseif p:IsA("BasePart")then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  elseif p:IsA("ParticleEmitter") or p:IsA("Highlight")then p.Enabled=false end
 end
 m:PivotTo(CFrame.new())
 if scale and scale~=1 then m:ScaleTo(scale)end
 local anchor=m:FindFirstChild("Handle") or m:FindFirstChildWhichIsA("BasePart",true)
 local light=Instance.new("PointLight");light.Name="RevealLight";light.Color=ICE;light.Range=5;light.Brightness=0;light.Parent=anchor
 m.Parent=parent
 return m,light
end
function A.scene(parent,origin)
 local m=Instance.new("Model");m.Name="WinterSet"
 -- Snow around the landing and a small mound around the planted blade.
 A.part(m,"LandingSnow",V(8,1.8,6),CFrame.new(-4,.03,0),WHITE,"ball")
 A.part(m,"ShovelSnow",V(3,.65,2.5),CFrame.new(3,.02,-1.1),WHITE,"ball")
 -- Compact igloo in the background, with chunky snow bricks and an open dark doorway.
 local center=V(14,-.2,20)
 A.part(m,"IglooDome",V(15,13,15),CFrame.new(center),C(225,245,255),"ball")
 for row=0,3 do
  local y=1+row*1.35
  local radius=7.2*math.sqrt(1-(y/7.3)^2)
  local n=20-row*3
  for i=0,n-1 do
   local angle=(i+(row%2)*.5)*math.pi*2/n
   local pos=center+V(math.sin(angle)*radius,y,math.cos(angle)*radius)
   A.part(m,"SnowBrick",V(radius*math.pi*2/n*.92,1.16,.38),CFrame.new(pos)*CFrame.Angles(0,angle,0),row%2==0 and WHITE or C(214,237,251))
  end
 end
 A.part(m,"DoorwayShadow",V(3.2,4.3,.18),CFrame.new(center+V(0,1.5,-7.3)),C(43,99,138),"ball")
 for i=0,8 do
  local a=i*math.pi/8
  local pos=center+V(math.cos(a)*2,1+math.sin(a)*2.4,-7.6)
  A.part(m,"EntranceArch",V(1.03,1.1,1.6),CFrame.new(pos)*CFrame.Angles(0,0,a-math.pi/2),WHITE)
 end
 -- Frame the high sky with a few soft clouds. Existing world mountains stay visible below.
 for i=1,3 do
  for j=-1,1 do A.part(m,"Cloud",V(14,6,8),CFrame.new(-28+i*20+j*5,67+i*4,26+i*7),WHITE,"ball") end
 end
 m.WorldPivot=CFrame.new();m:PivotTo(origin);m.Parent=parent
 return m
end
return A
