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
local TypeSpeed = 0.16        -- slower typing for dreamy effect
local BioUpdateFrequency = 0.08
local FadeSpeed = 2            -- smooth fade

-- VARIABLES
local Word = Player.DisplayName or Player.Name
local charIndex = 1
local typingForward = true
local lastTypeUpdate = 0
local lastBioUpdate = 0
local time = 0
local Connection

-- ===== GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GalaxyNameChanger"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0,280,0,130)
Frame.Position = UDim2.new(.5,-140,.5,-65)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local NameBox = Instance.new("TextBox")
NameBox.Size = UDim2.new(0,240,0,35)
NameBox.Position = UDim2.new(0,20,0,15)
NameBox.PlaceholderText = "Enter RP Name"
NameBox.Text = Word
NameBox.BackgroundColor3 = Color3.fromRGB(220,220,220)
NameBox.TextColor3 = Color3.new(0,0,0)
NameBox.ClearTextOnFocus = false
NameBox.Parent = Frame

local Start = Instance.new("TextButton")
Start.Size = UDim2.new(0,240,0,35)
Start.Position = UDim2.new(0,20,0,70)
Start.Text = "Start"
Start.BackgroundColor3 = Color3.fromRGB(60,60,60)
Start.TextColor3 = Color3.new(1,1,1)
Start.Parent = Frame

-- ===== GALAXY COLOR FUNCTIONS =====
local GalaxyColors = {
	Color3.fromRGB(120,0,180),   -- Lighter Purple
	Color3.fromRGB(0,0,120),     -- Slightly lighter Blue
	Color3.fromRGB(255,130,200)  -- Lighter Pink
}

local function GetGalaxyColor(dt)
	time += dt * FadeSpeed
	local alpha = (math.sin(time) + 1) / 2

	-- Smooth cycle through all 3 colors
	if alpha < 0.33 then
		return GalaxyColors[1]:Lerp(GalaxyColors[2], alpha / 0.33)
	elseif alpha < 0.66 then
		return GalaxyColors[2]:Lerp(GalaxyColors[3], (alpha - 0.33) / 0.33)
	else
		return GalaxyColors[3]:Lerp(GalaxyColors[1], (alpha - 0.66) / 0.34)
	end
end

local function InvertColor(color)
	return Color3.new(1 - color.R, 1 - color.G, 1 - color.B)
end

-- ===== START SYSTEM =====
local function StartSystem()
	Word = NameBox.Text ~= "" and NameBox.Text or Word
	charIndex = 1
	typingForward = true

	-- Close GUI
	ScreenGui:Destroy()

	Connection = RunService.Heartbeat:Connect(function(dt)
		local NewColor = GetGalaxyColor(dt)
		local StrokeColor = InvertColor(NewColor)

		-- SEND COLOR + STROKE
		pcall(function()
			ColorRemote:FireServer(NewColor, StrokeColor)
		end)

		-- BIO COLOR
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

		-- COSMIC TYPING
		lastTypeUpdate += dt
		if lastTypeUpdate >= TypeSpeed then
			lastTypeUpdate = 0

			local text = string.sub(Word,1,charIndex)
			pcall(function()
				NameRemote:FireServer(text)
			end)

			-- Update index for typewriter
			if typingForward then
				charIndex += 1
				if charIndex > #Word then
					typingForward = false
					charIndex = #Word
				end
			else
				charIndex -= 1
				if charIndex < 1 then
					typingForward = true
					charIndex = 1
				end
			end
		end
	end)
end

Start.MouseButton1Click:Connect(StartSystem)
--it should work 2.0
