local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local aimLocking = false
local targetPlayer

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "AimLockGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,220,0,300)
frame.Position = UDim2.new(0,50,0,50)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Parent = gui

-- Title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30,0,25)
title.BackgroundColor3 = Color3.fromRGB(40,40,40)
title.Text = "AimLock Menu"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 14
title.Parent = frame

-- Minimize button
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0,25,0,25)
minimize.Position = UDim2.new(1,-25,0,0)
minimize.BackgroundColor3 = Color3.fromRGB(60,60,60)
minimize.TextColor3 = Color3.new(1,1,1)
minimize.Text = "-"
minimize.Parent = frame

-- Scrollable player list
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-10,1,-60)
scroll.Position = UDim2.new(0,5,0,30)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,2)
layout.Parent = scroll

-- Toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1,-10,0,25)
toggleButton.Position = UDim2.new(0,5,0,frame.Size.Y.Offset-25)
toggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.Text = "Start"
toggleButton.Parent = frame

-- DRAGGING
local dragging = false
local dragStart
local startPos
title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
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

-- Minimize
local minimized = false
minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	scroll.Visible = not minimized
end)

-- Create player buttons
local buttons = {}
local function updateCanvas()
	scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

local function createButton(plr)
	if plr == player then return end
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,0,0,25)
	btn.Text = plr.Name
	btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Parent = scroll

	btn.MouseButton1Click:Connect(function()
		targetPlayer = plr
	end)

	buttons[plr] = btn
	updateCanvas()
end

-- Populate existing players
for _,plr in pairs(Players:GetPlayers()) do
	createButton(plr)
end

-- Handle players joining/leaving
Players.PlayerAdded:Connect(function(plr)
	createButton(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
	if buttons[plr] then
		buttons[plr]:Destroy()
		buttons[plr] = nil
		updateCanvas()
	end
	if targetPlayer == plr then
		targetPlayer = nil
		aimLocking = false
		toggleButton.Text = "Start"
	end
end)

-- Aimlock logic
local connection
toggleButton.MouseButton1Click:Connect(function()
	if targetPlayer == nil then return end
	aimLocking = not aimLocking
	toggleButton.Text = aimLocking and "Stop" or "Start"

	if aimLocking and not connection then
		connection = RunService.RenderStepped:Connect(function()
			local char = targetPlayer.Character
			if not char or not char:FindFirstChild("HumanoidRootPart") then
				aimLocking = false
				toggleButton.Text = "Start"
				connection:Disconnect()
				connection = nil
				return
			end
			local targetPos = char.HumanoidRootPart.Position
			local cam = workspace.CurrentCamera
			cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
		end)
	elseif not aimLocking and connection then
		connection:Disconnect()
		connection = nil
	end
end)

-- Update canvas size if content changes
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
