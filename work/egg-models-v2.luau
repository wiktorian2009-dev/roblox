-- Four collectible toy eggs. Shared by the world stands and hatch animation.
local M={}
local V,C=Vector3.new,Color3.fromRGB
local themes={
 SnowyEgg={C(219,243,255),C(72,181,241),C(255,255,255)},
 DesertEgg={C(255,211,130),C(214,143,61),C(57,199,190)},
 CursedEgg={C(55,36,87),C(144,78,213),C(235,117,255)},
 CrystalEgg={C(119,204,242),C(72,136,207),C(206,248,255)},
}
local function p(m,n,size,cf,col,shape,mat)
 local a=Instance.new("Part"); a.Name=n; a.Size=size; a.CFrame=cf; a.Color=col
 a.Shape=shape == Enum.PartType.Ball and Enum.PartType.Block or (shape or Enum.PartType.Block)
 if shape == Enum.PartType.Ball then local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=a end
 a.Material=mat or Enum.Material.SmoothPlastic
 a.Anchored=true; a.CanCollide=false; a.CanTouch=false; a.CanQuery=false; a.CastShadow=true
 a.TopSurface=Enum.SurfaceType.Smooth; a.BottomSurface=Enum.SurfaceType.Smooth; a.Parent=m
 return a
end
local function ball(m,n,size,pos,col) return p(m,n,size,CFrame.new(pos),col,Enum.PartType.Ball) end
local function line(m,n,a,b,r,col,mat)
 return p(m,n,V((b-a).Magnitude,r*2,r*2),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),col,Enum.PartType.Cylinder,mat)
end
local function gem(m,n,pos,size,col)
 return p(m,n,V(size*.7,size,size*.7),CFrame.new(pos)*CFrame.Angles(0,math.pi/4,math.pi/4),col)
end
function M.create(id)
 local t=themes[id] or themes.SnowyEgg
 local m=Instance.new("Model"); m.Name=id
 -- A single smooth shell keeps the surface clean at every viewing angle.
 ball(m,"Shell",V(4.25,5.4,4.25),V(0,0,0),t[1])
 -- A little collar makes each egg read as a collectible on its existing pedestal.
 p(m,"Collar",V(.25,3.55,3.55),CFrame.new(0,-2.28,0)*CFrame.Angles(0,0,math.pi/2),t[2],Enum.PartType.Cylinder)
 if id=="SnowyEgg" then
  -- Bold, readable six-armed snowflake emblem.
  ball(m,"FrostBadge",V(1.95,1.95,.18),V(0,.05,-2.04),t[2])
  local center=V(0,.05,-2.18)
  for i=0,5 do
   local a=i*math.pi/3; local dir=V(math.sin(a),math.cos(a),0)
   line(m,"Snowflake",center,center+dir*.75,.07,t[3])
   for s=-1,1,2 do
    local side=V(math.cos(a),-math.sin(a),0)*s
    line(m,"SnowflakeTip",center+dir*.48,center+dir*.33+side*.19,.045,t[3])
   end
  end
  for i=1,7 do
   local a=i*2.4
   local y=-.8+(i%3)*.9
   ball(m,"SnowSpot",V(.38,.38,.16),V(math.sin(a)*1.72,y,math.cos(a)*1.72),t[3])
  end
  gem(m,"IceCrown",V(0,2.82,0),.72,t[3])
 elseif id=="DesertEgg" then
  for i=0,11 do
   local a=i*math.pi/6
   gem(m,"TurquoiseBand",V(math.sin(a)*1.99,-.55,math.cos(a)*1.99),.39,t[3])
  end
  ball(m,"SunMedallion",V(1.22,1.22,.22),V(0,.62,-1.98),t[2])
  ball(m,"SunGem",V(.69,.69,.25),V(0,.62,-2.1),t[3])
  for i=0,7 do
   local a=i*math.pi/4
   line(m,"SunRay",V(math.sin(a)*.72,.62+math.cos(a)*.72,-2),V(math.sin(a)*.91,.62+math.cos(a)*.91,-1.95),.055,t[2])
  end
  p(m,"GoldCap",V(.3,1.18,1.18),CFrame.new(0,2.65,0)*CFrame.Angles(0,0,math.pi/2),t[2],Enum.PartType.Cylinder)
  gem(m,"TurquoiseCrown",V(0,2.99,0),.62,t[3])
 elseif id=="CursedEgg" then
  for s=-1,1,2 do
   line(m,"Horn",V(s*1.05,1.74,0),V(s*1.6,2.45,.1),.21,t[2])
   line(m,"HornTip",V(s*1.6,2.45,.1),V(s*1.47,2.99,.1),.11,t[3])
   local pts={V(s*.22,1.57,-1.65),V(s*.63,.87,-1.94),V(s*.34,.23,-2.12),V(s*.77,-.42,-2.04),V(s*.57,-1.25,-1.9)}
   for i=1,#pts-1 do line(m,"MagicSeam",pts[i],pts[i+1],.045,t[3],Enum.Material.Neon) end
  end
  gem(m,"VoidSeal",V(0,0,-2.16),.83,t[2])
  local core=gem(m,"SealCore",V(0,0,-2.48),.35,t[3]); core.Material=Enum.Material.Neon
  for i=0,4 do
   local a=i*math.pi*2/5
   gem(m,"OrbitShard",V(math.sin(a)*2.39,-1.24,math.cos(a)*2.39),.36,t[2])
  end
 elseif id=="CrystalEgg" then
  for i=0,7 do
   local a=i*math.pi/4
   gem(m,"CrystalFacet",V(math.sin(a)*1.84,-.46,math.cos(a)*1.84),.8,i%2==0 and t[3] or t[2])
  end
  for i=-1,1 do
   gem(m,"CrystalCrown",V(i*.64,2.48-math.abs(i)*.25,0),1.02-math.abs(i)*.2,t[3])
  end
  gem(m,"DiamondEmblem",V(0,.73,-1.98),1.02,t[2])
  gem(m,"DiamondHeart",V(0,.73,-2.36),.54,t[3])
  for s=-1,1,2 do line(m,"Glint",V(s*1.15,.82,-1.74),V(s*1.15,1.22,-1.6),.06,t[3]) end
 end
 local bounds=m:GetBoundingBox()
 for _,a in ipairs(m:GetChildren()) do if a:IsA("BasePart") then a.CFrame=bounds:ToObjectSpace(a.CFrame) end end
 -- Hidden center anchor gives every prompt a stable position independent of decoration.
 local anchor=p(m,"HatchAnchor",V(.2,.2,.2),CFrame.new(),t[1]); anchor.Transparency=1
 m.PrimaryPart=anchor; m.WorldPivot=CFrame.new()
 m:SetAttribute("ArtVersion",2)
 return m
end
return M
