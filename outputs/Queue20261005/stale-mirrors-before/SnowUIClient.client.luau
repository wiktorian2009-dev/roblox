-- Client-only snowy skin and branded prompts. Existing services own all actions.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local PromptService=game:GetService("ProximityPromptService")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local UI=require(RS:WaitForChild("SnowUI"))
local pg=Players.LocalPlayer:WaitForChild("PlayerGui")
UI.Attach(pg)
UI.Attach(workspace)
local function make(class,props,parent)
	local o=Instance.new(class) for k,v in pairs(props) do o[k]=v end o.Parent=parent return o
end
local function label(parent,text,pos,size,color)
	local t=make("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.FredokaOne,Text=text,TextScaled=true,
		TextColor3=color or Color3.new(1,1,1),Position=pos,Size=size,ZIndex=3},parent)
	make("UIStroke",{Color=Color3.fromRGB(17,49,83),Thickness=1.5},t) return t
end
local views={}
local function customPrompt(o)
	if o:IsA("ProximityPrompt") and (o.Style==Enum.ProximityPromptStyle.Default or o:GetAttribute("SnowUIOwnPrompt")) then
		o:SetAttribute("SnowUIOwnPrompt",true) o.Style=Enum.ProximityPromptStyle.Custom
	end
end
PromptService.PromptShown:Connect(function(prompt,inputType)
	if not prompt:GetAttribute("SnowUIOwnPrompt") or views[prompt] then return end
	local parent=prompt.Parent
	local part=parent and (parent:IsA("BasePart") and parent or parent:IsA("Attachment") and parent.Parent
		or parent:IsA("Model") and (parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart",true)))
	if not part then return end
	local gui=make("BillboardGui",{Name="SnowPrompt",Adornee=part,AlwaysOnTop=true,LightInfluence=0,Active=true,
		Size=UDim2.fromOffset(248,80),StudsOffsetWorldSpace=Vector3.new(0,2.2,0),MaxDistance=prompt.MaxActivationDistance+4},pg)
	local body=make("Frame",{Name="Body",BackgroundColor3=Color3.fromRGB(20,84,146),BackgroundTransparency=0.08,
		Size=UDim2.fromScale(1,1),BorderSizePixel=0,ZIndex=1},gui)
	make("UICorner",{CornerRadius=UDim.new(0,14)},body) UI.Skin(body,"card")
	local key=make("Frame",{BackgroundColor3=Color3.fromRGB(220,249,255),Position=UDim2.fromScale(0.055,0.22),
		Size=UDim2.fromScale(0.17,0.53),BorderSizePixel=0,ZIndex=2},body)
	make("UICorner",{CornerRadius=UDim.new(0,8)},key)
	local word=inputType==Enum.ProximityPromptInputType.Touch and "TAP"
		or inputType==Enum.ProximityPromptInputType.Gamepad and prompt.GamepadKeyCode.Name or prompt.KeyboardKeyCode.Name
	label(key,word,UDim2.fromScale(0.06,0.1),UDim2.fromScale(0.88,0.8),Color3.fromRGB(21,60,99))
	local title=label(body,prompt.ActionText,UDim2.fromScale(0.27,0.12),UDim2.fromScale(0.68,0.42))
	local sub=label(body,prompt.ObjectText,UDim2.fromScale(0.27,0.55),UDim2.fromScale(0.68,0.26),Color3.fromRGB(173,233,255))
	local track=make("Frame",{BackgroundColor3=Color3.fromRGB(10,42,85),BorderSizePixel=0,Position=UDim2.fromScale(0.27,0.87),
		Size=UDim2.fromScale(0.66,0.055),ZIndex=3,Visible=prompt.HoldDuration>0},body)
	local fill=make("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(120,245,255),BorderSizePixel=0,ZIndex=4},track)
	local hit=make("TextButton",{Name="Hit",Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Active=true,Selectable=false,ZIndex=8},body)
	local connections,held,activeInput,tween={},false,nil,nil
	local function release(input)
		if held and (not input or input==activeInput) then
			held=false activeInput=nil if prompt.Parent then prompt:InputHoldEnd() end
		end
	end
	table.insert(connections,hit.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
			if not held then held,activeInput=true,input prompt:InputHoldBegin() end
		end
	end))
	table.insert(connections,UIS.InputEnded:Connect(release))
	table.insert(connections,prompt:GetPropertyChangedSignal("ActionText"):Connect(function() title.Text=prompt.ActionText end))
	table.insert(connections,prompt:GetPropertyChangedSignal("ObjectText"):Connect(function() sub.Text=prompt.ObjectText end))
	table.insert(connections,prompt.PromptButtonHoldBegan:Connect(function()
		if tween then tween:Cancel() end fill.Size=UDim2.fromScale(0,1)
		tween=TweenService:Create(fill,TweenInfo.new(prompt.HoldDuration,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(1,1)}) tween:Play()
	end))
	table.insert(connections,prompt.PromptButtonHoldEnded:Connect(function()
		if tween then tween:Cancel() end fill.Size=UDim2.fromScale(0,1)
	end))
	views[prompt]=function()
		release() if tween then tween:Cancel() end for _,c in ipairs(connections) do c:Disconnect() end gui:Destroy()
	end
end)
PromptService.PromptHidden:Connect(function(prompt)
	local cleanup=views[prompt] if cleanup then views[prompt]=nil cleanup() end
end)
for _,o in ipairs(workspace:GetDescendants()) do customPrompt(o) end
workspace.DescendantAdded:Connect(customPrompt)
