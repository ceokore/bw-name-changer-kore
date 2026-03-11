local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

-- REMOTES
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ColorRemote = Remotes:WaitForChild("UpdateRPColor")
local NameRemote = Remotes:WaitForChild("UpdateRPName")
local BioColorRemote = Remotes:WaitForChild("UpdateBioColor")

local isBioFunction = BioColorRemote:IsA("RemoteFunction")

-- SETTINGS
local ShakeSpeed = 0.04
local BioUpdateFrequency = 0.08
local FadeSpeed = 3

-- VARIABLES
local Word = Player.DisplayName or Player.Name
local lastShake = 0
local lastBioUpdate = 0
local Connection

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0,280,0,130)
Frame.Position = UDim2.new(.5,-140,.5,-65)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.Parent = ScreenGui

local NameBox = Instance.new("TextBox")
NameBox.Size = UDim2.new(0,240,0,35)
NameBox.Position = UDim2.new(0,20,0,15)
NameBox.PlaceholderText = "Enter RP Name"
NameBox.Text = Word
NameBox.BackgroundColor3 = Color3.fromRGB(220,220,220)
NameBox.TextColor3 = Color3.new(0,0,0)
NameBox.Parent = Frame

local Start = Instance.new("TextButton")
Start.Size = UDim2.new(0,240,0,35)
Start.Position = UDim2.new(0,20,0,70)
Start.Text = "Start"
Start.BackgroundColor3 = Color3.fromRGB(60,60,60)
Start.TextColor3 = Color3.new(1,1,1)
Start.Parent = Frame

-- COLOR LOOP
local time = 0

local function GetColor(dt)
	time += dt * FadeSpeed
	local alpha = (math.sin(time) + 1) / 2

	return Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(255,60,160), alpha)
end

-- JITTER TEXT
local function JitterText(text)

	local result = ""

	for i = 1,#text do
		local char = text:sub(i,i)

		if math.random() < 0.5 then
			char = string.upper(char)
		else
			char = string.lower(char)
		end

		result ..= char
	end

	return result
end

-- START
local function StartSystem()

	Word = NameBox.Text ~= "" and NameBox.Text or Word
	ScreenGui:Destroy()

	Connection = RunService.Heartbeat:Connect(function(dt)

		local NewColor = GetColor(dt)

		pcall(function()
			ColorRemote:FireServer(NewColor)
		end)

		lastBioUpdate += dt
		if lastBioUpdate >= BioUpdateFrequency then
			lastBioUpdate = 0

			pcall(function()
				if isBioFunction then
					BioColorRemote:InvokeServer(NewColor)
				else
					BioColorRemote:FireServer(NewColor)
				end
			end)
		end

		lastShake += dt
		if lastShake >= ShakeSpeed then
			lastShake = 0

			local jitter = JitterText(Word)

			pcall(function()
				NameRemote:FireServer(jitter)
			end)
		end

	end)
end

Start.MouseButton1Click:Connect(StartSystem)
