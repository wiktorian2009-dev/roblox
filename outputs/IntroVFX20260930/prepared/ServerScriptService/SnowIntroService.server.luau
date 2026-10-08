-- One intro per join. The server owns placement and always releases the character.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local SF=require(RS:WaitForChild("SnowFields"))
local remote=RS:WaitForChild("SnowIntroRequest")
local StarterShovelRules=require(script.Parent:WaitForChild("StarterShovelRules"))
local active,seen={},{}
local function finish(p,reason)
 local s=active[p]; if not s then return end
 active[p]=nil
 if s.root.Parent then
  s.root.Anchored=s.anchored
  s.root.AssemblyLinearVelocity=Vector3.zero
  s.root.AssemblyAngularVelocity=Vector3.zero
 end
 if s.hum.Parent then s.hum.AutoRotate=s.autoRotate end
 if s.died then s.died:Disconnect() end
 p:SetAttribute("IntroActive",false)
 p:SetAttribute("IntroFinished",reason or "complete")
end
remote.OnServerInvoke=function(p,action)
 if action=="Finish" then finish(p,"complete");return true end
 if action=="Skip" then finish(p,"skipped");return true end
 if action~="Begin" and action~="Preview" then return nil end
 if action=="Preview" and not RunService:IsStudio() then return nil end
 if active[p] or (seen[p] and action~="Preview") then return nil end
 local char=p.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 or root.Anchored then return nil end
 -- Prefer the main lobby's authored landing; retain the field fallback.
 local lobby=workspace:FindFirstChild("FrostfallVillage")
 local marker=lobby and lobby:FindFirstChild("IntroOrigin")
 local origin
 if marker and marker:IsA("CFrameValue") then
  origin=marker.Value
 else
 local field
 for _,f in ipairs(SF.Fields)do if f.Style=="Starter" then field=f;break end end
 if not field then return nil end
 local phase=RS.SnowStages.Starter:FindFirstChild("Phase3")
 local x=field.Center.X-field.Width*SF.TileSize/2-6
 local query=RaycastParams.new();query.FilterType=Enum.RaycastFilterType.Exclude;query.FilterDescendantsInstances={char};query.RespectCanCollide=true
 local hit=workspace:Raycast(Vector3.new(x,field.Center.Y+35,field.Center.Z),Vector3.new(0,-90,0),query)
 local surface=hit and hit.Position.Y or field.Center.Y
 origin=CFrame.new(x,surface,field.Center.Z)*CFrame.Angles(0,-math.pi/2,0)
 end
 local foot=char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg")
 local height=foot and root.Position.Y-(foot.Position.Y-foot.Size.Y/2) or hum.HipHeight+root.Size.Y/2
 height=math.clamp(height,2,5)
 local final=origin*CFrame.new(3,height,0)
 local s={root=root,hum=hum,anchored=root.Anchored,autoRotate=hum.AutoRotate}
 active[p]=s;seen[p]=true
 p:SetAttribute("IntroActive",true);p:SetAttribute("IntroFinished",nil)
 root.Anchored=true;hum.AutoRotate=false
 root.CFrame=final;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 s.died=hum.Died:Connect(function()finish(p,"interrupted")end)
 task.delay(action=="Preview" and 60 or 15,function()if active[p]==s then finish(p,"timeout")end end)
 return {Origin=origin,Height=height,Final=final,Duration=7,StarterShovel=StarterShovelRules.Name}
end
Players.PlayerRemoving:Connect(function(p)finish(p,"left");seen[p]=nil end)
Players.PlayerAdded:Connect(function(p)
 p.CharacterRemoving:Connect(function()finish(p,"respawn")end)
end)
