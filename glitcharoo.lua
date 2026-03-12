local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local selectedPlayer = nil
local following = false

-------------------------------------------------
-- CHARACTER SETUP (RAGDOLL BYPASS)
-------------------------------------------------

local humanoid
local root

local function setupCharacter(char)

	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")

	-- disable ragdoll states
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)

end

setupCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(setupCharacter)

-------------------------------------------------
-- GUI
-------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "GlitchFollower"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,240,0,320)
frame.Position = UDim2.new(0,50,0.5,-160)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Parent = gui

Instance.new("UICorner",frame).CornerRadius = UDim.new(0,10)

local stroke = Instance.new("UIStroke",frame)
stroke.Color = Color3.fromRGB(80,80,80)
stroke.Thickness = 2

-------------------------------------------------
-- TITLE BAR
-------------------------------------------------

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,35)
titleBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
titleBar.Parent = frame

Instance.new("UICorner",titleBar).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,1,0)
title.BackgroundTransparency = 1
title.Text = "kore's glicharooski"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.Parent = titleBar

-------------------------------------------------
-- DRAGGING
-------------------------------------------------

local dragging
local dragStart
local startPos

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then

		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)

	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-------------------------------------------------
-- PLAYER LIST
-------------------------------------------------

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-10,1,-90)
scroll.Position = UDim2.new(0,5,0,40)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,5)
layout.Parent = scroll

-------------------------------------------------
-- START BUTTON
-------------------------------------------------

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(1,-10,0,35)
startButton.Position = UDim2.new(0,5,1,-40)
startButton.BackgroundColor3 = Color3.fromRGB(45,45,45)
startButton.Text = "START"
startButton.Font = Enum.Font.GothamBold
startButton.TextColor3 = Color3.new(1,1,1)
startButton.TextSize = 14
startButton.Parent = frame

Instance.new("UICorner",startButton).CornerRadius = UDim.new(0,8)

-------------------------------------------------
-- PLAYER LIST FUNCTION
-------------------------------------------------

local function refresh()

	for _,v in pairs(scroll:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	for _,plr in pairs(Players:GetPlayers()) do

		if plr ~= player then

			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1,0,0,30)
			button.BackgroundColor3 = Color3.fromRGB(40,40,40)
			button.Text = plr.Name
			button.Font = Enum.Font.Gotham
			button.TextColor3 = Color3.new(1,1,1)
			button.TextSize = 13
			button.Parent = scroll

			Instance.new("UICorner",button).CornerRadius = UDim.new(0,6)

			button.MouseButton1Click:Connect(function()

				selectedPlayer = plr

				for _,b in pairs(scroll:GetChildren()) do
					if b:IsA("TextButton") then
						b.BackgroundColor3 = Color3.fromRGB(40,40,40)
					end
				end

				button.BackgroundColor3 = Color3.fromRGB(90,90,90)

			end)

		end

	end

	task.wait()
	scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)

end

refresh()

Players.PlayerAdded:Connect(refresh)
Players.PlayerRemoving:Connect(refresh)

-------------------------------------------------
-- BUTTON
-------------------------------------------------

startButton.MouseButton1Click:Connect(function()

	if not selectedPlayer then return end

	following = not following

	startButton.Text = following and "STOP" or "START"

end)

-------------------------------------------------
-- KEY STOP
-------------------------------------------------

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.J then
		following = false
		startButton.Text = "START"
	end
end)

-------------------------------------------------
-- ULTRA GLITCH FOLLOW
-------------------------------------------------

RunService.RenderStepped:Connect(function()

	if not following then return end
	if not selectedPlayer then return end

	local myChar = player.Character
	local targetChar = selectedPlayer.Character

	if not myChar or not targetChar then return end

	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")

	if not myRoot or not targetRoot then return end

	-- prevent fall detection
	myRoot.AssemblyLinearVelocity = Vector3.zero
	myRoot.AssemblyAngularVelocity = Vector3.zero

	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end

	-- CRAZY TELEPORTS
	for i = 1,8 do

		local radius = math.random(2,10)

		local offset = Vector3.new(
			math.random(-radius,radius),
			math.random(-2,2),
			math.random(-radius,radius)
		)

		local spin = CFrame.Angles(
			math.rad(math.random(-360,360)),
			math.rad(math.random(-360,360)),
			math.rad(math.random(-360,360))
		)

		myRoot.CFrame = targetRoot.CFrame * CFrame.new(offset) * spin

	end

end)
