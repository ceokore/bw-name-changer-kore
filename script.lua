local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- EVENTS
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ColorRemote = Remotes:WaitForChild("UpdateRPColor")
local NameRemote = Remotes:WaitForChild("UpdateRPName")
local BioColorRemote = Remotes:WaitForChild("UpdateBioColor")

-- SETTINGS
local NameSpeed = 0.1
local BioUpdateFrequency = 0.1

-- Smooth fade speed (lower = slower)
local FadeSpeed = 0.15

-- VARIABLES
local lastNameUpdate = 0
local lastBioUpdate = 0
local charCount = 1
local Connection
local Word = ""

local FadeAlpha = 0
local FadeDirection = 1

local isBioColorRemoteFunction = BioColorRemote:IsA("RemoteFunction")

-- ===== GET DISPLAY NAME =====
local function GetDisplayName()
    if LocalPlayer and LocalPlayer:FindFirstChild("DisplayName") then
        return LocalPlayer.DisplayName
    end
    return LocalPlayer.Name
end

-- ===== GUI =====
local function CreateGUI()

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BWNameGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0,300,0,150)
    Frame.Position = UDim2.new(.5,-150,.5,-75)
    Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Frame.Parent = ScreenGui

    local NameBox = Instance.new("TextBox")
    NameBox.Size = UDim2.new(0,260,0,35)
    NameBox.Position = UDim2.new(0,20,0,20)
    NameBox.PlaceholderText = "Enter RP Name"
    NameBox.Text = GetDisplayName()
    NameBox.BackgroundColor3 = Color3.fromRGB(200,200,200)
    NameBox.TextColor3 = Color3.new(0,0,0)
    NameBox.Parent = Frame

    local ColorBox = Instance.new("Frame")
    ColorBox.Size = UDim2.new(0,260,0,30)
    ColorBox.Position = UDim2.new(0,20,0,70)
    ColorBox.BackgroundColor3 = Color3.new(0,0,0)
    ColorBox.Parent = Frame

    local Start = Instance.new("TextButton")
    Start.Size = UDim2.new(0,120,0,30)
    Start.Position = UDim2.new(0,20,0,110)
    Start.Text = "Start"
    Start.BackgroundColor3 = Color3.fromRGB(60,60,60)
    Start.TextColor3 = Color3.new(1,1,1)
    Start.Parent = Frame

    local Stop = Instance.new("TextButton")
    Stop.Size = UDim2.new(0,120,0,30)
    Stop.Position = UDim2.new(0,160,0,110)
    Stop.Text = "Stop"
    Stop.BackgroundColor3 = Color3.fromRGB(60,60,60)
    Stop.TextColor3 = Color3.new(1,1,1)
    Stop.Parent = Frame

    return ScreenGui, NameBox, ColorBox, Start, Stop
end

local ScreenGui, NameTextBox, NameColorBox, StartButton, StopButton = CreateGUI()

-- ===== SMOOTH BLACK/WHITE COLOR =====
local function GetSmoothBW(dt)

    FadeAlpha += dt * FadeSpeed * FadeDirection

    if FadeAlpha >= 1 then
        FadeAlpha = 1
        FadeDirection = -1
    elseif FadeAlpha <= 0 then
        FadeAlpha = 0
        FadeDirection = 1
    end

    return Color3.new(0,0,0):Lerp(Color3.new(1,1,1), FadeAlpha)
end

-- ===== START SYSTEM =====
local function Start()

    Word = NameTextBox.Text ~= "" and NameTextBox.Text or GetDisplayName()
    charCount = 1

    if Connection then
        Connection:Disconnect()
    end

    Connection = RunService.Heartbeat:Connect(function(dt)

        local NewColor = GetSmoothBW(dt)

        -- GUI preview
        if NameColorBox then
            NameColorBox.BackgroundColor3 = NewColor
        end

        -- RP color
        pcall(function()
            ColorRemote:FireServer(NewColor)
        end)

        -- BIO color
        lastBioUpdate += dt
        if lastBioUpdate >= BioUpdateFrequency then
            lastBioUpdate = 0

            pcall(function()
                if isBioColorRemoteFunction then
                    BioColorRemote:InvokeServer(NewColor)
                else
                    BioColorRemote:FireServer(NewColor)
                end
            end)
        end

        -- NAME typing
        lastNameUpdate += dt
        if lastNameUpdate >= NameSpeed then

            lastNameUpdate = 0

            local DisplayText = string.sub(Word,1,charCount)

            pcall(function()
                NameRemote:FireServer(DisplayText)
            end)

            charCount = (charCount >= #Word) and 1 or (charCount + 1)

        end

    end)

end

-- BUTTONS
StartButton.MouseButton1Click:Connect(Start)

StopButton.MouseButton1Click:Connect(function()
    if Connection then
        Connection:Disconnect()
    end
end)

-- AUTO START
Start()

print("⚫⚪ Smooth Black/White System Loaded")
