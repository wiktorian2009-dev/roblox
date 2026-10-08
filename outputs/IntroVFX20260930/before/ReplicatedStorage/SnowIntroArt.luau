-- Local cinematic props. No external models or uploaded animation assets required.
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
function A.shovel(parent)
 local m=Instance.new("Model");m.Name="HeroShovel"
 A.rod(m,"WoodenShaft",V(0,-1.35,0),V(0,1.18,0),.115,C(167,112,64))
 A.rod(m,"WoodHighlight",V(-.06,-1.22,-.095),V(-.06,1.1,-.095),.018,C(233,181,112))
 A.part(m,"Blade",V(1.38,1.32,.24),CFrame.new(0,-1.83,0),C(102,190,224),"ball")
 A.part(m,"BladeCenter",V(.94,.94,.16),CFrame.new(0,-1.71,-.12),C(184,238,255),"ball")
 A.rod(m,"ScoopLip",V(-.5,-2.25,-.05),V(.5,-2.25,-.05),.065,ICE)
 A.rod(m,"Socket",V(0,-1.45,0),V(0,-1.08,0),.18,INK)
 -- Open D grip with a curved top and a straight wooden crossbar.
 for i=0,9 do
  local a,b=math.pi*i/10,math.pi*(i+1)/10
  A.rod(m,"DGrip",V(math.cos(a)*.5,1.45+math.sin(a)*.5,0),V(math.cos(b)*.5,1.45+math.sin(b)*.5,0),.075,INK)
 end
 A.rod(m,"GripBase",V(-.5,1.45,0),V(.5,1.45,0),.085,C(186,130,75))
 for s=-1,1,2 do A.rod(m,"GripFork",V(0,1.1,0),V(s*.5,1.45,0),.065,INK) end
 local h=Instance.new("Highlight");h.FillTransparency=1;h.OutlineColor=INK;h.OutlineTransparency=.45;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=m
 local light=Instance.new("PointLight");light.Name="RevealLight";light.Color=ICE;light.Range=8;light.Brightness=0;light.Parent=m.Blade
 m.WorldPivot=CFrame.new();m.Parent=parent
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
