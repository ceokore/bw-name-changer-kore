local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local tpwalking = false
local tpwalkSpeed = 4
local minimized = false

local gui = Instance.new("ScreenGui")
gui.Name = "KoreTpWalk"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0.16,0,0.16,0)
main.Position = UDim2.new(0.5,0,0.5,0)
main.AnchorPoint = Vector2.new(0.5,0.5)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(55,55,55)
stroke.Thickness = 1
stroke.Parent = main

local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 1.45
aspect.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-60,0,24)
title.Position = UDim2.new(0,8,0,4)
title.BackgroundTransparency = 1
title.Text = "TPWALK"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0,20,0,20)
minimize.Position = UDim2.new(1,-48,0,5)
minimize.BackgroundColor3 = Color3.fromRGB(40,40,40)
minimize.Text = "-"
minimize.Font = Enum.Font.GothamBold
minimize.TextScaled = true
minimize.TextColor3 = Color3.new(1,1,1)
minimize.Parent = main

Instance.new("UICorner", minimize).CornerRadius = UDim.new(0,6)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0,20,0,20)
close.Position = UDim2.new(1,-24,0,5)
close.BackgroundColor3 = Color3.fromRGB(170,50,50)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextScaled = true
close.TextColor3 = Color3.new(1,1,1)
close.Parent = main

Instance.new("UICorner", close).CornerRadius = UDim.new(0,6)

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-30)
content.Position = UDim2.new(0,0,0,30)
content.BackgroundTransparency = 1
content.Parent = main

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0.84,0,0.24,0)
toggle.Position = UDim2.new(0.08,0,0.06,0)
toggle.BackgroundColor3 = Color3.fromRGB(170,50,50)
toggle.Text = "DISABLED"
toggle.Font = Enum.Font.GothamBold
toggle.TextScaled = true
toggle.TextColor3 = Color3.new(1,1,1)
toggle.AutoButtonColor = false
toggle.Parent = content

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.84,0,0.20,0)
speedBox.Position = UDim2.new(0.08,0,0.38,0)
speedBox.BackgroundColor3 = Color3.fromRGB(28,28,28)
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.PlaceholderText = "Speed"
speedBox.Text = tostring(tpwalkSpeed)
speedBox.Font = Enum.Font.Gotham
speedBox.TextScaled = true
speedBox.ClearTextOnFocus = false
speedBox.Parent = content

Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0,8)

local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(1,0,0.16,0)
watermark.Position = UDim2.new(0,0,0.76,0)
watermark.BackgroundTransparency = 1
watermark.Text = "kore 🧠❌"
watermark.Font = Enum.Font.GothamSemibold
watermark.TextScaled = true
watermark.TextTransparency = 0.5
watermark.TextColor3 = Color3.new(1,1,1)
watermark.Parent = content

local function tweenColor(obj,color)
	TweenService:Create(
		obj,
		TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
		{BackgroundColor3 = color}
	):Play()
end

local connection

local function stopTpWalk()
	tpwalking = false

	if connection then
		connection:Disconnect()
		connection = nil
	end

	toggle.Text = "DISABLED"
	tweenColor(toggle,Color3.fromRGB(170,50,50))
end

local function startTpWalk()
	local speed = tonumber(speedBox.Text)

	if not speed or speed <= 0 then
		speedBox.Text = tostring(tpwalkSpeed)
		return
	end

	tpwalkSpeed = speed
	tpwalking = true

	toggle.Text = "ENABLED"
	tweenColor(toggle,Color3.fromRGB(50,170,70))

	connection = RunService.Heartbeat:Connect(function(delta)
		local char = player.Character
		if not char then return end

		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if not hum then return end

		if hum.MoveDirection.Magnitude > 0 then
			char:TranslateBy(hum.MoveDirection * tpwalkSpeed * delta * 10)
		end
	end)
end

toggle.MouseButton1Click:Connect(function()
	if tpwalking then
		stopTpWalk()
	else
		startTpWalk()
	end
end)

speedBox.FocusLost:Connect(function()
	local num = tonumber(speedBox.Text)

	if num and num > 0 then
		tpwalkSpeed = num
	else
		speedBox.Text = tostring(tpwalkSpeed)
	end
end)

player.CharacterAdded:Connect(function()
	stopTpWalk()
end)

local normalSize = UDim2.new(0.16,0,0.16,0)
local miniSize = UDim2.new(0.08,0,0.045,0)

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		content.Visible = false
		minimize.Text = "+"

		TweenService:Create(
			main,
			TweenInfo.new(0.25,Enum.EasingStyle.Quad),
			{Size = miniSize}
		):Play()
	else
		content.Visible = true
		minimize.Text = "-"

		TweenService:Create(
			main,
			TweenInfo.new(0.25,Enum.EasingStyle.Quad),
			{Size = normalSize}
		):Play()
	end
end)

close.MouseButton1Click:Connect(function()
	stopTpWalk()

	TweenService:Create(
		main,
		TweenInfo.new(0.2,Enum.EasingStyle.Quad),
		{
			Size = UDim2.new(0,0,0,0),
			BackgroundTransparency = 1
		}
	):Play()

	task.wait(0.2)
	gui:Destroy()
end)

main.Size = UDim2.new(0,0,0,0)

TweenService:Create(
	main,
	TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
	{Size = normalSize}
):Play()
